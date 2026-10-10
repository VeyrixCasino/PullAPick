#!/usr/bin/env node
// Repairs PetModelFactory.ANIMALS so no two pets render as the same model.
//
// Two defects, both pure data:
//   (c) 69 Event Horizon animals have no ANIMALS row at all, so build() gets
//       skin = nil, resolveSpecies(nil) returns "fox", and all 69 come out as
//       the identical default fox.
//   (b) Animals of one species share a tint byte-for-byte -- 11 dog breeds all
//       sit on (156,112,72), so a Pomeranian and a Terrier are pixel-identical.
//
// Run with --check to verify without writing (used by the pre-commit gate).

const fs = require("fs");
const path = require("path");

const FILE = path.join(__dirname, "..", "..", "src", "ReplicatedStorage", "Mine", "Shared", "PetModelFactory.luau");
const ROSTER_FILE = path.join(__dirname, "..", "..", "src", "ReplicatedStorage", "Mine", "Shared", "MinePetRoster.luau");

// ---------------------------------------------------------------------------
// Roster reassignments. 26 pets in 12 groups pointed at ONE animal, so each
// group rendered as a single pet -- correct factory behaviour, wrong content.
// One pet per group keeps the original animal; the rest get their own.
//
// None of these rows is `tierVia = "animal"`, so changing the animal cannot
// move a tier. Checked before writing; the assertion at the bottom re-checks.
// ---------------------------------------------------------------------------
const ROSTER = {
  "Velvet": "Fruit Bat",            // Vesper keeps "Bat" -- a vesper IS a bat
  "Churro": "Chinchilla",           // Caper keeps "Capybara"; "Guinea Pig" is Squeaky's
  "Sunny": "Duckling",              // Nugget keeps "Chick"
  "Pecan": "Dormouse",              // Chippy keeps "Chipmunk"
  "Skipper": "Porpoise",            // Ripple keeps "Dolphin"
  "Twix": "Stoat",                  // Snickers keeps "Ferret"
  "Sproing": "Tree Frog",           // Pickles keeps "Frog"
  "Mochi": "Marshmallow Bear",      // Bamboo keeps "Panda"
  "Wobble": "Emperor Penguin",      // Pippa keeps "Penguin"
  "Roxy": "Fennec Fox",             // Cherry keeps "Red Panda"
  "Pecan Puff": "Flying Squirrel",  // Acorn keeps "Squirrel"
  "Button": "Harvest Mouse",        // Pipsqueak keeps "Mouse"
  "Cheddar": "Gerbil",
  "Tinker": "Clockwork Mouse",

  // Seven more the geometry audit hid: it labelled each identical group with a
  // single cause, so these pairs were filed under "different animals, same
  // tint" and their shared animal never showed. The roster check below is what
  // actually finds them, which is why it is an assertion and not a report.
  "Brisket": "Boxer",               // Boomer keeps "Bulldog"
  "Fawncy": "Doe",                  // Clover keeps "Deer"
  "Fennel": "Angora Rabbit",        // Binky keeps "Bunny" -- a binky is a rabbit hop
  "Pebble": "Cottontail",
  "Marble": "Tabby Cat",            // Munchkin keeps "Kitten" -- it is a cat breed
  "Oatmeal": "Merino Sheep",        // Cloudy keeps "Sheep"
  "Rumblebee": "Carpenter Bee",     // Honey keeps "Bee"
  "Squish": "Jellyfish",            // Bloop keeps "Blobfish" -- a bloop IS a blobfish
};

// ---------------------------------------------------------------------------
// (b) Re-tints. Each colliding group keeps its canonical animal on the original
// colour and moves the rest off it. Values are chosen to read as the creature:
// a Pomeranian is ginger fluff, a Japanese Spitz is white, an Elf Dog is green.
// ---------------------------------------------------------------------------
const TINT = {
  // hound: 11 breeds were all (156,112,72). Bulldog keeps it.
  "Dog": [190, 150, 105],
  "Elf Dog": [96, 160, 104],
  "Fancy Poodle": [246, 240, 232],
  "Japanese Spitz": [250, 250, 248],
  "Pomeranian": [240, 166, 86],
  "Poodle": [214, 198, 176],
  "Teacup Poodle": [236, 214, 226],
  "Terrier": [170, 140, 96],
  "Tumbleweed Pup": [196, 170, 112],
  "Wild Dog": [138, 96, 58],
  "Patchwork Dog": [198, 160, 110],
  "Tiny Dalmatian": [232, 236, 242],
  "Planet Pup": [96, 84, 170],
  "Rock Star Dog": [48, 44, 60],

  "Ewok-like Bear": [120, 86, 58],
  "Thorn Bear": [92, 70, 52],
  "Snow Monster": [222, 234, 246],

  "Roly-Poly Bug": [128, 118, 140],
  "Bumblebee": [240, 180, 40],

  "Shadow Panther": [78, 66, 110],
  "Sun Lion": [250, 170, 60],

  "Pirate Parrot": [214, 86, 74],
  "Lemon Bird": [236, 240, 96],
  "Yellow Chick": [252, 190, 80],
  "Green Parrot": [70, 170, 86],

  "Lop Bunny": [206, 186, 166],
  "Rabbit": [186, 166, 150],
  "Snow Bunny": [230, 240, 250],

  "Kitten": [232, 196, 156],
  "Mermaid Cat": [120, 206, 196],
  "White Cat": [252, 252, 250],
  "Orange Cat": [236, 128, 48],
  "Coal Cat": [62, 58, 64],

  "Sloth": [142, 130, 110],

  "Mini Dragon": [176, 140, 236],
  "Sea Dragon": [72, 164, 196],
  "Firework Dragon": [250, 80, 120],
  "Lunar Dragon": [108, 116, 180],

  "Koi Fish": [250, 180, 90],
  "Pufferfish": [226, 206, 120],
  "Seahorse": [128, 196, 210],

  "Sparkle Fox": [250, 196, 120],
  "Spirit Wolf": [196, 214, 246],
  "Brick Golem": [168, 96, 74],

  "Phoenix": [250, 120, 48],
  "Wind Hawk": [196, 208, 220],
  "Raven": [58, 54, 74],

  "Party Pony": [250, 170, 210],
  "Ribbon Unicorn": [236, 200, 240],

  "Desert Lizard": [206, 176, 110],
  "Quiet Owl": [148, 128, 112],

  "Baby Elephant": [170, 174, 186],
  "Baby Hippo": [160, 146, 170],
  "Circus Elephant": [186, 150, 196],

  "Sheepdog": [196, 186, 170],

  // sprite: Alien / Fairy / Gremlin were one lavender. All three are headline
  // Exotic pets, so they get properly different silhouettes of colour.
  "Alien": [150, 230, 170],
  "Fairy": [250, 196, 236],
  "Gremlin": [160, 140, 96],

  "Fawn": [206, 166, 118],
  "Flower Deer": [226, 176, 186],
  "Holiday Reindeer": [150, 106, 72],
  "Reindeer": [136, 100, 70],

  "Racing Turtle": [86, 150, 200],
  "Northern Lights Wolf": [110, 220, 190],
};

// Props that carry identity where colour alone cannot.
const ADD_DETAIL = {
  "Dalmatian": ["spots"],
  "Tiny Dalmatian": ["spots"],
  "Golden Tiger": ["stripes"],
  "Pirate Parrot": ["pirate"],
};

// ---------------------------------------------------------------------------
// (c) The 69 missing Event Horizon animals. Species comes from the head noun of
// the animal name; every one is a body that already exists and already renders.
// Tints are cosmic but distinct, and `glow` suits the zone's whole roster.
// ---------------------------------------------------------------------------
const NEW = [
  ["Accretion Fox",       "fox",      [38, 30, 54],    [255, 186, 90]],
  ["Ash Orbit Lizard",    "lizard",   [128, 122, 118],  null],
  ["Bag Tide Seal",       "otter",    [96, 142, 170],   null],
  ["Big Bang Cub",        "bear",     [60, 44, 92],    [255, 140, 220]],
  ["Bubble Tadpole",      "toad",     [120, 200, 206],  null],
  ["Starflower Deer",     "stag",     [214, 170, 230], [255, 220, 150]],
  ["Bolt Seed Mouse",     "mouse",    [226, 206, 96],  [255, 240, 120]],
  ["Bubble Orb Axolotl",  "toad",     [240, 170, 206],  null],
  ["Axis Penguin",        "penguin",  [70, 96, 150],   [150, 220, 255]],
  ["Chill Bit Penguin",   "penguin",  [160, 196, 220],  null],
  ["Clover Bit Lamb",     "sheep",    [176, 214, 150],  null],
  ["Bang Coin Crab",      "crab",     [230, 178, 70],  [255, 230, 140]],
  ["Coin Seed Chick",     "bird",     [244, 210, 110],  null],
  ["Crater Drake",        "drake",    [110, 102, 96],  [255, 130, 70]],
  ["Crater Roo",          "critter",  [166, 142, 118],  null],
  ["Proto Crystal Drake", "drake",    [150, 226, 240], [190, 240, 255]],
  ["Moon Dirt Pig",       "pig",      [150, 140, 126],  null],
  ["Disk Flare Lizard",   "lizard",   [240, 140, 60],  [255, 190, 90]],
  ["Dusk Chip Crow",      "bird",     [74, 68, 96],     null],
  ["Cosmic Dustmite",     "beetle",   [140, 128, 150],  null],
  ["Dust Nip Hamster",    "mouse",    [196, 174, 146],  null],
  ["Dust Well Mole",      "critter",  [116, 100, 92],   null],
  ["Echo Flare Pup",      "hound",    [230, 150, 110], [255, 190, 140]],
  ["Echo Pea Owl",        "owl",      [140, 180, 130],  null],
  ["Ember Bit Chick",     "bird",     [250, 160, 90],  [255, 150, 60]],
  ["Eventide Owl",        "owl",      [86, 80, 130],   [160, 150, 255]],
  ["Star Armadillo",      "critter",  [190, 180, 206], [220, 220, 255]],
  ["Black Ice Fox",       "fox",      [70, 92, 110],   [150, 220, 255]],
  ["Nova Gem Cat",        "cat",      [230, 110, 170], [255, 170, 220]],
  ["Glim Ore Bunny",      "bunny",    [206, 196, 150], [255, 240, 170]],
  ["Gloom Mouse",         "mouse",    [96, 92, 110],    null],
  ["Glowpuff Cloud Pup",  "hound",    [236, 240, 250], [200, 230, 255]],
  ["Gravity Bear",        "bear",     [44, 40, 70],    [120, 110, 255]],
  ["Ice Ring Cat",        "cat",      [176, 220, 240], [190, 240, 255]],
  ["Kelp Orb Otter",      "otter",    [96, 146, 110],   null],
  ["Nova Leaf Turtle",    "turtle",   [120, 190, 130], [190, 255, 170]],
  ["Moon Sheep",          "sheep",    [220, 224, 240], [210, 220, 255]],
  ["Nebula Serpent",      "serpent",  [130, 90, 190],  [200, 140, 255]],
  ["Night Bag Bat",       "moth",     [80, 70, 110],    null],
  ["Proto Ore Beetle",    "beetle",   [160, 140, 100], [255, 210, 120]],
  ["Parallax Lite Pup",   "hound",    [170, 190, 210], [210, 230, 255]],
  ["Orbit Peep Chick",    "bird",     [250, 230, 150],  null],
  ["Star Petal Bunny",    "bunny",    [246, 190, 210], [255, 220, 240]],
  ["Photon Bunny",        "bunny",    [252, 248, 220], [255, 255, 200]],
  ["Moon Prism Cat",      "cat",      [200, 190, 240], [220, 210, 255]],
  ["Orb Puddle Frog",     "toad",     [110, 170, 160],  null],
  ["Pulsar Finch",        "bird",     [240, 240, 250], [180, 200, 255]],
  ["Quasar Hawk",         "hawk",     [90, 130, 220],  [160, 200, 255]],
  ["Relativity Wolf",     "wolf",     [100, 110, 140], [170, 190, 255]],
  ["Shade Chip Bat",      "moth",     [60, 56, 72],     null],
  ["Shardlet Crab",       "crab",     [180, 200, 220],  null],
  ["Shimmer Bit Gecko",   "lizard",   [150, 220, 190],  null],
  ["Singularity Cat",     "cat",      [26, 24, 36],    [140, 90, 255]],
  ["Smelt Bit Mouse",     "mouse",    [200, 130, 80],  [255, 160, 80]],
  ["Snow Axis Fox",       "fox",      [236, 244, 252],  null],
  ["Photon Kitten",       "cat",      [250, 244, 206], [255, 250, 190]],
  ["Spark Kitten",        "cat",      [246, 206, 110], [255, 220, 120]],
  ["Orbit Spark Mouse",   "mouse",    [236, 196, 120], [255, 220, 140]],
  ["Spark Wisp Fox",      "fox",      [250, 180, 100], [255, 200, 120]],
  ["Speck Mouse",         "mouse",    [170, 160, 150],  null],
  ["Starloom Lamb",       "sheep",    [240, 226, 250], [230, 210, 255]],
  ["Gravity Otter",       "otter",    [70, 100, 130],  [130, 170, 255]],
  ["Tiny Clink Mouse",    "mouse",    [150, 156, 166],  null],
  ["Tinyspark Beetle",    "beetle",   [230, 190, 80],  [255, 215, 110]],
  ["Vanta Squirrel",      "critter",  [40, 38, 50],    [110, 90, 180]],
  ["Warp Puppy",          "hound",    [130, 150, 230], [180, 200, 255]],
  ["Zip Mite",            "beetle",   [200, 210, 120],  null],
  ["Zip Puppy",           "hound",    [210, 190, 130],  null],
  ["Quark Ferret",        "critter",  [196, 170, 200], [220, 190, 255]],

  // Bodies for the 14 pets reassigned in ROSTER above. Every species here
  // already exists; these are new skins, not new chassis.
  ["Fruit Bat",           "moth",     [168, 110, 78],   null],
  ["Chinchilla",          "critter",  [158, 152, 166],  null],
  ["Duckling",            "duck",     [250, 226, 140],  null],
  ["Dormouse",            "mouse",    [214, 166, 112],  null],
  ["Porpoise",            "dolphin",  [150, 166, 180],  null],
  ["Stoat",               "critter",  [242, 236, 222],  null],
  ["Tree Frog",           "toad",     [96, 210, 120],   null],
  ["Marshmallow Bear",    "bear",     [250, 242, 232],  null],
  ["Emperor Penguin",     "penguin",  [40, 44, 60],     null],
  ["Fennec Fox",          "fox",      [238, 214, 172],  null],
  ["Flying Squirrel",     "critter",  [170, 176, 190],  null],
  ["Gerbil",              "mouse",    [230, 186, 130],  null],
  ["Harvest Mouse",       "mouse",    [206, 184, 146],  null],
  ["Clockwork Mouse",     "mouse",    [190, 160, 96],   null, ["robot"]],
  ["Boxer",               "hound",    [182, 122, 70],   null],
  ["Doe",                 "stag",     [186, 146, 102],  null],
  ["Angora Rabbit",       "bunny",    [246, 240, 228],  null],
  ["Cottontail",          "bunny",    [166, 150, 134],  null],
  ["Tabby Cat",           "cat",      [168, 142, 104],  null],
  ["Merino Sheep",        "sheep",    [226, 214, 192],  null],
  ["Carpenter Bee",       "beetle",   [62, 58, 86],     null, ["bands", "bugwings"]],
  ["Jellyfish",           "slime",    [200, 180, 240],  null],
];

// ---------------------------------------------------------------------------

const check = process.argv.includes("--check");
let src = fs.readFileSync(FILE, "utf8");
const nl = src.includes("\r\n") ? "\r\n" : "\n";
const fail = [];

// Locate the ANIMALS table so every edit is scoped to it -- never the whole file.
const openIdx = src.indexOf("PetModelFactory.ANIMALS = {");
if (openIdx < 0) {
  console.error("FAIL  cannot find PetModelFactory.ANIMALS");
  process.exit(1);
}
const closeIdx = src.indexOf(`${nl}}${nl}`, openIdx);
if (closeIdx < 0) {
  console.error("FAIL  cannot find the end of the ANIMALS table");
  process.exit(1);
}
let table = src.slice(openIdx, closeIdx);
const rgb = (a) => `Color3.fromRGB(${a[0]}, ${a[1]}, ${a[2]})`;

// --- apply (b) re-tints -----------------------------------------------------
let retinted = 0;
for (const [animal, col] of Object.entries(TINT)) {
  const re = new RegExp(
    `(\\t\\["${animal.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}"\\] = \\{[^\\n]*?tint = )Color3\\.fromRGB\\(\\s*\\d+,\\s*\\d+,\\s*\\d+\\s*\\)`
  );
  const hits = table.match(new RegExp(re.source, "g"));
  if (!hits) { fail.push(`no tint found for ["${animal}"]`); continue; }
  if (hits.length > 1) { fail.push(`["${animal}"] matched ${hits.length} times`); continue; }
  table = table.replace(re, `$1${rgb(col)}`);
  retinted++;
}

// --- apply detail additions -------------------------------------------------
let detailed = 0;
for (const [animal, props] of Object.entries(ADD_DETAIL)) {
  const esc = animal.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const lineRe = new RegExp(`\\t\\["${esc}"\\] = \\{([^\\n]*?)\\},`);
  const m = table.match(lineRe);
  if (!m) { fail.push(`no row for ["${animal}"] (detail)`); continue; }
  if (/detail = /.test(m[1])) continue; // already has props; leave it alone
  const list = props.map((p) => `"${p}"`).join(", ");
  table = table.replace(lineRe, `\t["${animal}"] = {${m[1].replace(/\s+$/, "")}, detail = { ${list} } },`);
  detailed++;
}

// --- append (c) the missing rows --------------------------------------------
const existing = new Set();
for (const m of table.matchAll(/\t\["([^"]+)"\] = \{/g)) existing.add(m[1]);

const added = [];
for (const [animal, species, tint, glow, detail] of NEW) {
  if (existing.has(animal)) continue; // idempotent: never double-add
  let row = `\t["${animal}"] = { species = "${species}", tint = ${rgb(tint)}`;
  if (glow) row += `, glow = ${rgb(glow)}`;
  if (detail) row += `, detail = { ${detail.map((d) => `"${d}"`).join(", ")} }`;
  row += ` },`;
  added.push(row);
}
if (added.length) {
  table = table.replace(/\s*$/, "") + nl +
    `${nl}\t-- Event Horizon. Added by tools/verify/petskins.js: without a row here` +
    `${nl}\t-- build() gets no skin and every one of these renders as the default fox.` +
    `${nl}` + added.join(nl);
}

// --- verify no (species,tint) pair is shared --------------------------------
const seen = new Map();
const dupes = [];
for (const line of table.split(nl)) {
  const m = line.match(/\t\["([^"]+)"\] = \{\s*species = "([^"]+)",\s*tint = Color3\.fromRGB\(\s*(\d+),\s*(\d+),\s*(\d+)\s*\)/);
  if (!m) continue;
  const key = `${m[2]}|${m[3]},${m[4]},${m[5]}`;
  if (seen.has(key)) dupes.push(`${key}  ${seen.get(key)} == ${m[1]}`);
  else seen.set(key, m[1]);
}

// --- reassign the duplicate-animal roster rows ------------------------------
let roster = fs.readFileSync(ROSTER_FILE, "utf8");
const rnl = roster.includes("\r\n") ? "\r\n" : "\n";
let moved = 0;
for (const [pet, animal] of Object.entries(ROSTER)) {
  const esc = pet.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const re = new RegExp(`(\\{ name = "${esc}", hex3 = "[^"]+", animal = ")([^"]+)(")`);
  const m = roster.match(re);
  if (!m) { fail.push(`no roster row for "${pet}"`); continue; }
  if (m[2] === animal) continue; // already reassigned
  // Changing the animal must not move the tier.
  const row = roster.slice(roster.indexOf(m[0]), roster.indexOf(m[0]) + 220);
  if (/tierVia = "animal"/.test(row.split(rnl)[0])) {
    fail.push(`"${pet}" is tierVia="animal" -- reassigning would change its tier`);
    continue;
  }
  roster = roster.replace(re, `$1${animal}$3`);
  moved++;
}

// Every roster animal must be unique, or two pets are the same pet again.
const byAnimal = new Map();
const shared = [];
for (const m of roster.matchAll(/\{ name = "([^"]+)", hex3 = "[^"]+", animal = "([^"]+)"/g)) {
  if (byAnimal.has(m[2])) { byAnimal.get(m[2]).push(m[1]); shared.push(m[2]); }
  else byAnimal.set(m[2], [m[1]]);
}
const sharedGroups = [...new Set(shared)].map((a) => `${a} -> ${byAnimal.get(a).join(", ")}`);

// Every roster animal must have a skin, or it renders as the fallback fox.
const skins = new Set();
for (const m of table.matchAll(/\t\["([^"]+)"\] = \{/g)) skins.add(m[1]);
const skinless = [...byAnimal.keys()].filter((a) => !skins.has(a));

console.log(`retinted ${retinted}/${Object.keys(TINT).length}  details +${detailed}  new rows +${added.length}`);
console.log(`roster reassigned: ${moved}/${Object.keys(ROSTER).length}`);
console.log(`distinct (species,tint) pairs: ${seen.size}`);
console.log(`roster animals: ${byAnimal.size}  sharing an animal: ${sharedGroups.length}  without a skin: ${skinless.length}`);

if (sharedGroups.length) {
  console.log(`\n${sharedGroups.length} animal(s) used by more than one pet:`);
  for (const g of sharedGroups) console.log(`  ${g}`);
}
if (skinless.length) {
  console.log(`\n${skinless.length} roster animal(s) with no ANIMALS row (these render as a fox):`);
  for (const a of skinless) console.log(`  ${a}`);
}

if (dupes.length) {
  console.log(`\n${dupes.length} animals still share a body+colour:`);
  for (const d of dupes) console.log(`  ${d}`);
}
if (fail.length) {
  console.log(`\n${fail.length} edit(s) did not apply:`);
  for (const f of fail) console.log(`  FAIL  ${f}`);
}

if (fail.length || dupes.length || sharedGroups.length || skinless.length) process.exit(1);
if (check) { console.log("\nOK (check only, nothing written)"); process.exit(0); }

fs.writeFileSync(FILE, src.slice(0, openIdx) + table + src.slice(closeIdx), "utf8");
console.log(`\nwrote ${path.relative(process.cwd(), FILE)}`);
if (moved) {
  fs.writeFileSync(ROSTER_FILE, roster, "utf8");
  console.log(`wrote ${path.relative(process.cwd(), ROSTER_FILE)}`);
}
