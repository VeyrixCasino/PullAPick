#!/usr/bin/env node
// ZONE PET POTS: 70 pets in each of the 10 regular zones.
//
// Owner, 2026-10-10:
//   "make more like 70 per zone"
//   "+5% per zone" (each zone's pot is 5% better than the zone before it)
//   "Mythic, Divine and Exotic pets get a different buff set in each zone"
//   "the zone ones do not need to be themed"
//   "lets not overuse the holiday ones"
//
// Every existing regular pet (the roster minus the 73 Event Horizon pets) is
// dealt into a zone, and new pets fill each zone up to its quota. Nothing is
// renamed: pet names are save data. Event Horizon (bigbang) keeps its own 73.
//
// KITS follow the ladder the owner approved on 2026-10-05 (docs/PROPOSAL.md
// §0 line 3): at Normal / power level 1 a pet's PRIMARY stat is worth the
// tier's number of points (Common 34 .. Exotic 150) and its secondary half of
// that, times 1.05 per zone. Points are MineStats weights (points per +1%),
// so a Luck pet and a Mine Speed pet of one tier are worth the same. A kit is
// stored before RARITY_MULT, which cardPower applies at runtime.
//
// Writes:
//   src/ReplicatedStorage/Mine/Shared/MineZonePets.luau   the data the game reads
//   docs/ZONE-PETS.md                                      the names sheet
//
//   node tools/gen/zone-pets.js           write both
//   node tools/gen/zone-pets.js --check   exit 1 if either file is stale
"use strict";
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const SHARED = "src/ReplicatedStorage/Mine/Shared/";
const OUT_LUAU = SHARED + "MineZonePets.luau";
const OUT_MD = "docs/ZONE-PETS.md";
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");

const TIERS = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic"];
const TOP = new Set(["Mythic", "Divine", "Exotic"]);

// Per zone, 70 in all. Mythic / Divine / Exotic are sized so no existing pet
// has to change tier: the roster already holds 18 / 24 / 26 of them.
const QUOTA = { Common: 25, Uncommon: 15, Rare: 10, Epic: 7, Legendary: 5, Mythic: 2, Divine: 3, Exotic: 3 };

// docs/PROPOSAL.md §0 line 3, approved 2026-10-05.
const LADDER = { Common: 34, Uncommon: 39, Rare: 46, Epic: 55, Legendary: 68, Mythic: 89, Divine: 116, Exotic: 150 };
const ZONE_STEP = 1.05;
const SECONDARY = 0.5; // C..L: secondary = half the primary (PROPOSAL §A)
const TOP_SHARES = [1, 0.35, 0.15]; // M/D/X: same 1.5x total, spread over the zone's three buffs

// Each zone's Mythic / Divine / Exotic buff set. A later zone does not make an
// earlier zone's top pets useless, because they do a different job.
const ZONES = [
  { id: "meadow", adj: "Bloom", buff: "Harvest", stats: ["oreHaul", "fossilFind", "coinBonus"], desc: "more ore per block, better ore finds, more coins" },
  { id: "sunscar", adj: "Sunscorch", buff: "Blaze", stats: ["mineSpeed", "swingRate", "dirtBreak"], desc: "raw damage and swing speed" },
  { id: "mistreef", adj: "Tidal", buff: "Tide", stats: ["tidalWave", "pulverize", "scrap"], desc: "tidal waves across your layer, stardust from rubble and chests" },
  { id: "arcwork", adj: "Voltaic", buff: "Volt", stats: ["zap", "swingRate", "ricochet"], desc: "chain lightning and bouncing hits" },
  { id: "bloodmoon", adj: "Crimson", buff: "Fortune", stats: ["luck", "chestLuck", "packLuck"], desc: "luck, better chests, better packs" },
  { id: "eclipse", adj: "Umbral", buff: "Shadow", stats: ["earthquake", "blastChance", "dirtBreak"], desc: "quakes and blasts that clear rock" },
  { id: "riftmarch", adj: "Riftborn", buff: "Quake", stats: ["earthquake", "ricochet", "mineSpeed"], desc: "quakes, ricochets and heavy hits" },
  { id: "starfall", adj: "Starfallen", buff: "Prospect", stats: ["gemFind", "rareOre", "oreLuck"], desc: "gems, rarer ore, more ore cases" },
  { id: "mythral", adj: "Mythril", buff: "Treasure", stats: ["luckyFind", "packLuck", "chestLuck"], desc: "lucky blocks, packs and chests" },
  { id: "primordium", adj: "Primeval", buff: "Primal", stats: ["mineSpeed", "oreHaul", "rareOre"], desc: "damage, ore haul and rare ore" },
];

// EVENT HORIZON (bigbang) is zone 11: its 73 pets keep their own roster and
// their hand-authored stat MIX, but sit on the same ladder as everyone else at
// x1.05^10. Before 2026-10-10 they spent MineEHPets.BUDGET (Common 25 ..
// Exotic 380) before RARITY_MULT, so an Event Horizon Exotic was worth ~4.5x a
// top zone Exotic. The mixes below are frozen from the kits live then
// (MinePetBoosts.PET_BOOSTS.EH). Retired and rune-only stats are dropped and the
// rest rescaled, so each pet keeps its character and loses only the excess.
const EVENT_ZONE = { id: "bigbang", index: 11 };
const EH_MIX = {
  "Accretia": { blastRadius: 0.2063, mineSpeed: 0.88, swingRate: 0.4518 },
  "Albert Minestein": { gemFind: 1.1875, luck: 0.9501 },
  "Ashorbit": { mineSpeed: 0.372, dirtBreak: 0.228 },
  "Bagtide": { backpack: 0.81, coinBonus: 0.36, luck: 0.1035 },
  "Bangcub": { blastRadius: 0.1425, mineSpeed: 0.608, swingRate: 0.3121 },
  "Barybub": { backpack: 0.225, coinBonus: 0.1, luck: 0.0288 },
  "Bloomstar": { blastChance: 0.1938, backpack: 0.95 },
  "Boltseed": { zap: 0.1488, swingRate: 0.1629 },
  "Bubbleorb": { backpack: 0.432, coinBonus: 0.192, luck: 0.0552 },
  "Chillaxis": { swingRate: 0.5536, dirtBreak: 0.475 },
  "Chillbit": { swingRate: 0.2126, dirtBreak: 0.1824 },
  "Cloverbit": { blastChance: 0.0744, backpack: 0.3648 },
  "Coinbang": { gemFind: 0.2533, coinBonus: 0.3989, backpack: 0.95 },
  "Coinseed": { coinBonus: 0.465, backpack: 0.456 },
  "Cosmo": { backpack: 2.128, luck: 0.532, chestLuck: 0.4836, coinBonus: 0.76 },
  "Craterjaw": { dirtBreak: 0.855, mineSpeed: 0.608, blastChance: 0.1093 },
  "Crateroo": { dirtBreak: 0.30, mineSpeed: 0.21, backpack: 0.18 },
  "Crystalith": { gemFind: 0.7734, luck: 0.4401, chestLuck: 0.2875 },
  "Dirtmoon": { dirtBreak: 0.372, mineSpeed: 0.228 },
  "Diskflare": { blastRadius: 0.1292, mineSpeed: 0.475 },
  "Duskchip": { luck: 0.186, chestLuck: 0.1036 },
  "Dustmite": { blastChance: 0.0388, backpack: 0.19 },
  "Dustnip": { dirtBreak: 0.2976, mineSpeed: 0.1824 },
  "Dustwell": { dirtBreak: 0.558, mineSpeed: 0.342 },
  "Echoflare": { gemFind: 0.3378, luck: 0.2185 },
  "Echopea": { luck: 0.114 },
  "Emberbit": { mineSpeed: 0.312, dirtBreak: 0.204, swingRate: 0.06 },
  "Eventide": { luck: 0.4275, chestLuck: 0.2764, backpack: 0.874 },
  "Faultstar": { dirtBreak: 0.775, mineSpeed: 0.475 },
  "Frosthole": { swingRate: 0.6107, dirtBreak: 0.608, mineSpeed: 0.437 },
  "Gemnova": { gemFind: 0.5344, luck: 0.304, backpack: 0.874 },
  "Glimore": { gemFind: 0.3488, luck: 0.171 },
  "Gloomouse": { luck: 0.1488, chestLuck: 0.0829 },
  "Glowpuff": { luck: 0.0475 },
  "Gravpaw": { dirtBreak: 1.2375, mineSpeed: 0.88, backpack: 1.265 },
  "Icering": { swingRate: 0.3986, dirtBreak: 0.342 },
  "Kelporb": { backpack: 0.744, coinBonus: 0.285 },
  "Leafnova": { blastChance: 0.1395, backpack: 0.684 },
  "Matter+": { luck: 0.3801, gemFind: 0.475, chestLuck: 0.3109, backpack: 1.368, coinBonus: 0.665, walkSpeed: 1.9 },
  "Matter-": { blastRadius: 0.114, mineSpeed: 0.76, dirtBreak: 0.76, swingRate: 0.4343, coinBonus: 0.5699 },
  "Moonshear": { backpack: 1.71, coinBonus: 0.76, luck: 0.2185 },
  "Nebulisk": { gemFind: 0.4889, luck: 0.3163 },
  "Nightbag": { luck: 0.186, backpack: 0.456 },
  "Oreproto": { coinBonus: 1.0688, backpack: 1.216, luck: 0.2185 },
  "Paralite": { blastChance: 0.0855 },
  "Peeporbit": { coinBonus: 0.2282 },
  "Petalstar": { blastChance: 0.093, backpack: 0.456 },
  "Photonna": { blastChance: 0.2239, gemFind: 0.19, luck: 0.3163, backpack: 1.76 },
  "Prismoon": { gemFind: 0.4844, luck: 0.2376 },
  "Puddleorb": { backpack: 0.54, coinBonus: 0.24, luck: 0.069 },
  "Pulsarina": { zap: 0.342, swingRate: 0.4343 },
  "Quasarin": { zap: 0.495, swingRate: 0.6286 },
  "Relativox": { swingRate: 0.8839, dirtBreak: 0.88, mineSpeed: 0.6325 },
  "Shadechip": { luck: 0.279, chestLuck: 0.1555 },
  "Shardlet": { gemFind: 0.2325, luck: 0.114 },
  "Shimmerbit": { gemFind: 0.186, luck: 0.0912 },
  "Singuluna": { luck: 0.6188, chestLuck: 0.4, gemFind: 0.3953 },
  "Smeltbit": { coinBonus: 0.6975, backpack: 0.684 },
  "Snowaxis": { swingRate: 0.2657, dirtBreak: 0.228 },
  "Softphoton": { swingRate: 0.1107, dirtBreak: 0.095 },
  "Sparkitten": { mineSpeed: 0.2976, dirtBreak: 0.1824 },
  "Sparkorbit": { zap: 0.225, swingRate: 0.2857 },
  "Sparkwisp": { mineSpeed: 0.558, dirtBreak: 0.342 },
  "Speck": { dirtBreak: 0.155, mineSpeed: 0.095 },
  "Starloom": { blastChance: 0.2138, backpack: 1.216, coinBonus: 0.5463 },
  "Tidewell": { backpack: 1.125, coinBonus: 0.5, luck: 0.1438 },
  "Tinyclink": { gemFind: 0.1014, coinBonus: 0.1438, backpack: 0.3648 },
  "Tinyspark": { zap: 0.062, swingRate: 0.0679 },
  "Vantail": { luck: 0.3876, chestLuck: 0.2159 },
  "Warpup": { gemFind: 0.2222, luck: 0.1438 },
  "Zipmite": { zap: 0.1488 },
  "Zippup": { zap: 0.119, swingRate: 0.1303 },
  "Zipquark": { zap: 0.2232, swingRate: 0.2443 },
};

// HOLIDAY PETS ARE NOT IN THE GAME (owner, 2026-10-10: "make sure NO holiday
// ones are in the game.. only allow it from {Holiday} {year} Pack"). Any pet on
// a holiday body, plus these holiday-themed ones on ordinary bodies, stays out
// of every zone pot and every random pet roll. They keep a kit (zone-1 ladder)
// so a copy someone already owns still pays. Their only future source is a
// holiday pack, e.g. "Halloween 2026 Pack".
const HOLIDAY_SPECIES = { pumpkin: "halloween", ghost: "halloween", spider: "halloween", skelehound: "halloween", reaper: "halloween",
  reindeer: "christmas", snowman: "christmas", gingerbread: "christmas", giftbox: "christmas" };
const HOLIDAY_NAMED = { Jolly: "christmas", Tinsel: "christmas", Tinseltoe: "christmas" };

// Common to Legendary: a role from the body. "Birds find things, diggers dig,
// heavies hit hard." Each role has a few stat pairs; a pet's name picks one.
// Pairs marked rarePlus only go to Rare and better (PROPOSAL §B: blast is a
// mid-tier identity, never a Common's).
const ROLES = {
  Striker: { desc: "hits harder and swings faster", species: ["fox", "cat", "wolf", "bigcat", "hound"],
    pairs: [["mineSpeed", "swingRate"], ["swingRate", "mineSpeed"], ["mineSpeed", "dirtBreak"]] },
  Bruiser: { desc: "heavy hits that clear dirt fast", species: ["bear", "golem", "turtle", "beetle", "crab", "stag"],
    pairs: [["mineSpeed", "dirtBreak"], ["dirtBreak", "mineSpeed"], ["dirtBreak", "oreHaul"]], rarePlus: [["mineSpeed", "blastChance"]] },
  Digger: { desc: "digs deep and hauls more ore", species: ["mouse", "critter", "bunny", "toad"],
    pairs: [["dirtBreak", "oreHaul"], ["oreHaul", "dirtBreak"], ["fossilFind", "dirtBreak"]] },
  Seeker: { desc: "sniffs out luck, chests and packs", species: ["hawk", "owl", "bird", "duck", "penguin", "moth"],
    pairs: [["luck", "chestLuck"], ["chestLuck", "luck"], ["packLuck", "luck"]] },
  Prospector: { desc: "finds gems and rarer ore", species: ["lizard", "serpent", "spider"],
    pairs: [["gemFind", "rareOre"], ["rareOre", "gemFind"], ["oreLuck", "gemFind"]] },
  Tidecaller: { desc: "turns rubble into stardust", species: ["fish", "dolphin", "ray", "slime", "otter"],
    pairs: [["pulverize", "scrap"], ["scrap", "pulverize"], ["gemFind", "pulverize"]], rarePlus: [["tidalWave", "pulverize"]] },
  Trader: { desc: "earns more coins and ore", species: ["pig", "sheep", "horse"],
    pairs: [["coinBonus", "oreHaul"], ["coinBonus", "luckyFind"], ["oreHaul", "coinBonus"]] },
  Mystic: { desc: "sparks, quakes and ricochets", species: ["sprite", "ghost", "drake", "wyrm"],
    pairs: [["zap", "ricochet"], ["ricochet", "zap"], ["earthquake", "zap"]], rarePlus: [["blastChance", "zap"]] },
};
const ROLE_OF = {};
for (const [role, r] of Object.entries(ROLES)) for (const s of r.species) ROLE_OF[s] = role;

// Stats a pet may never carry: retired (pay nothing), rune-only (MineCards.addStat
// drops them), procPower (PROPOSAL §0 line 7).
const BANNED = new Set(["backpack", "walkSpeed", "echo", "autoMine", "blastRadius", "reach", "coolant", "shortFuse", "procPower"]);

// New pets use everyday bodies only. Holiday bodies stay rare (owner:
// "lets not overuse the holiday ones"); matterbox is Event Horizon's.
const NEW_SPECIES = ["fox", "hound", "otter", "stag", "drake", "wyrm", "serpent", "toad", "crab", "beetle", "moth", "hawk", "owl", "ray",
  "golem", "sprite", "cat", "bunny", "bear", "wolf", "bigcat", "mouse", "bird", "duck", "horse", "pig", "sheep", "turtle", "fish",
  "dolphin", "lizard", "slime", "critter", "penguin"];

const LABEL = { fox: "Fox", hound: "Pup", otter: "Otter", stag: "Deer", drake: "Drake", wyrm: "Wyrm", serpent: "Serpent", toad: "Toad",
  crab: "Crab", beetle: "Beetle", moth: "Moth", hawk: "Hawk", owl: "Owl", ray: "Ray", golem: "Golem", sprite: "Sprite", cat: "Cat",
  bunny: "Bunny", bear: "Bear", wolf: "Wolf", bigcat: "Wildcat", mouse: "Mouse", bird: "Bird", duck: "Duck", horse: "Pony", pig: "Piglet",
  sheep: "Lamb", turtle: "Turtle", fish: "Fish", dolphin: "Dolphin", lizard: "Lizard", slime: "Slime", critter: "Critter", penguin: "Penguin" };

// Patterns only where the roster already uses them, so the prop is known to sit
// on that body (the DETAILS builders assume the standard envelope).
const PATTERNS = { stripes: ["horse", "bigcat"], spots: ["hound", "bigcat", "beetle"], bands: ["beetle"], scales: ["drake", "serpent", "lizard"] };
// Legendary pets shine; the word says so, and varies so 31 of them do not all
// start the same way.
const LEGEND_WORD = ["Radiant", "Gleaming", "Shining", "Lustrous", "Majestic", "Noble", "Regal", "Dazzling"];
const PATTERN_WORD = { stripes: "Striped", spots: "Spotted", bands: "Banded", scales: "Scaled" };

const PALETTE = [
  ["Mint", 152, 230, 190], ["Coral", 255, 127, 110], ["Lavender", 190, 160, 235], ["Peach", 255, 190, 150], ["Teal", 40, 170, 170],
  ["Plum", 130, 60, 120], ["Lemon", 250, 235, 110], ["Cocoa", 120, 80, 55], ["Ash", 150, 150, 155], ["Slate", 90, 105, 125],
  ["Ruby", 200, 30, 60], ["Jade", 40, 160, 100], ["Amber", 240, 160, 40], ["Indigo", 75, 60, 170], ["Rose", 240, 130, 160],
  ["Sky", 130, 195, 250], ["Moss", 110, 140, 60], ["Rust", 180, 80, 40], ["Ivory", 245, 240, 220], ["Cobalt", 40, 80, 200],
  ["Berry", 170, 40, 110], ["Sage", 160, 180, 140], ["Honey", 235, 180, 70], ["Frost", 210, 235, 250], ["Ink", 35, 35, 60],
  ["Cherry", 220, 40, 50], ["Lime", 170, 230, 60], ["Tangerine", 255, 140, 30], ["Orchid", 215, 120, 215], ["Denim", 80, 110, 160],
  ["Mocha", 150, 110, 85], ["Pearl", 235, 230, 240], ["Charcoal", 60, 60, 65], ["Saffron", 245, 190, 20], ["Seafoam", 120, 220, 200],
  ["Blush", 250, 200, 205], ["Cinnamon", 190, 100, 60], ["Periwinkle", 160, 170, 250], ["Pistachio", 190, 220, 140], ["Bubblegum", 255, 150, 200],
  ["Lagoon", 30, 140, 190], ["Glacier", 170, 220, 235], ["Marigold", 250, 170, 30], ["Maroon", 120, 25, 40], ["Olive", 130, 130, 50],
  ["Aqua", 60, 220, 230], ["Fuchsia", 230, 40, 170], ["Caramel", 200, 140, 70], ["Storm", 100, 110, 130], ["Butter", 250, 230, 150],
  ["Poppy", 240, 70, 50], ["Thistle", 210, 180, 220], ["Navy", 30, 45, 100], ["Sand", 220, 200, 150], ["Copper", 190, 110, 60],
  ["Bronze", 165, 120, 50], ["Silver", 195, 200, 210], ["Gold", 240, 200, 60], ["Lilac", 200, 170, 230], ["Emerald", 20, 180, 100],
  ["Sapphire", 30, 90, 190], ["Crimson", 180, 20, 40], ["Mustard", 215, 180, 40], ["Clay", 190, 120, 90], ["Fern", 80, 150, 80],
  ["Iris", 110, 90, 200], ["Cream", 250, 240, 210], ["Smoke", 120, 120, 130], ["Raspberry", 210, 40, 90], ["Cyan", 0, 200, 230],
];

// Candidate names, in no order; collisions with the roster are skipped.
const NAMES = `Almond Apricot Bagel Banana Beignet Bonbon Brownie Bun Butterscotch Cannoli Cashew Chestnut Chickpea Chili Choco Cider
Clementine Cobbler Cookie Crepe Croissant Cupcake Custard Dumpling Eclair Edamame Fig Fondue Fritter Gelato Ginger Gnocchi Granola Guava
Hazel Hummus Jam Jelly Kale Kumquat Latte Licorice Macaron Mango Marzipan Melon Mousse Nacho Nectar Nutmeg Pancake Papaya Parfait Peanut
Pepper Pesto Popcorn Pretzel Quiche Radish Raisin Ravioli Scone Sesame Sherbet Shortcake Sorbet Souffle Strudel Sundae Taco Tamale Tapioca
Tart Tempura Toast Tortilla Udon Wasabi Yam Yogurt Ziti Alder Aspen Birch Bluebell Briar Brook Bud Burrow Canyon Cedar Cliff Cove Creek
Daisy Dell Dewdrop Elm Fjord Glade Glen Heather Hollow Ivy Juniper Kelp Larch Laurel Leaf Lichen Lily Linden Marsh Mesa Nettle Oak Pansy
Petal Pine Pinecone Poplar Rain Reed River Rowan Rush Sequoia Shale Sorrel Spruce Stone Sumac Thorn Thyme Tulip Twig Violet Willow Wren
Yarrow Yew Zinnia Blaze Breeze Cirrus Cyclone Dawn Dew Flare Fog Gale Gust Hail Misty Monsoon Nimbus Sleet Snowflake Squall Stratus
Sunbeam Sundown Thunder Twilight Typhoon Updraft Whirl Windy Astra Astro Celeste Halley Lumen Lunar Meteor Nebula Neutron Orion Photon
Plasma Pulsar Quark Saturn Sirius Solstice Starburst Stardust Sunspot Titan Vega Zenith Agate Beryl Calcite Citrine Diamond Garnet
Granite Graphite Jasper Jet Mica Nickel Obsidian Onyx Peridot Pewter Spinel Tin Tourmaline Zircon Bean Bingo Bitsy Blip Bobble Boing
Bounce Buddy Bumble Buzz Chirp Chuckles Cuddles Dibble Dimple Dinky Dizzy Doodlebug Dribble Fluff Fluffy Flutter Gizmo Giggles Goober
Hiccup Hopper Jiggle Jingle Kazoo Kipper Lulu Marbles Mimi Mittens Mumble Nibbler Niblet Nimble Nippy Noodles Nubbin Nuzzle Oodles
Peaches Pebbles Piper Pitter Plink Plop Plucky Pockets Pom Poppet Popsicle Pounce Puddles Purrcy Rascal Ripples Scamper Scoot Scrappy
Scruffy Skippy Sniffles Snowball Snuggles Sparky Speckles Spud Squirt Sunshine Tickles Tiddly Tippy Tiptoe Toots Trinket Tuffy
Tumbleweed Tweak Twiggy Waddles Wiggles Wobbles Wuzzy Yappy Yoyo Zippy Zoom Aether Arcana Cerulean Chimera Crescent Dynamo Enigma
Fathom Gossamer Helix Lumina Mirage Monarch Obelisk Oracle Paragon Phantom Phoenix Radiance Relic Rune Seraph Solace Spire Talisman
Tempest Valor Verdant Kestrel Sparrow Robin Finch Lark Puffin Pelican Heron Jay Magpie Starling Swift Plover Bramblebee Clover Bloom
Pip Pudge Chubbs Biscotti Waffle Crumpet Muesli Pudding Puff Ruffle Taffle Tumble Wink Blink Glint Gleam Shine Sparkle Twinkletoes
Cocoapuff Honeydew Huckleberry Gooseberry Elderberry Blackberry Mulberry Lingonberry Cloudberry Boysenberry Persimmon Lychee Pomelo
Kiwano Starfruit Tamarind Quince Damson Nectarine Satsuma Yuzu Calamansi Pumpernickel Brioche Focaccia Ciabatta Baguette Muffintop
Snickerdoodle Biscuitbun Butterbean Jellyroll Sugarplum Lemondrop Gumball Jawbreaker Taffytail Fudgeball
Bonfire Campfire Lantern Candle Wick Ember-Glow Hearth Kindle Spark-Plug Flicker Glimmerwick Beacon Lighthouse Harbor Anchor Paddle
Compass Lookout Trailblazer Ranger Scout-Star Rambler Wanderer Drifter Nomad Voyager Pathfinder Pilgrim Rover Ramble Saunter
Trundle Waddle Scurry Skitter Flitter Hopscotch Leapfrog Cartwheel Somersault Pinwheel Yo-Yo Kite Marble-Run Domino Checkers Jigsaw
Puzzle Riddle Rhyme Jingle-Bell Melody Harmony Tempo Rhythm Banjo Ukulele Piccolo Fiddle Cello Tuba Bongo-Beat Maraca Tambourine
Cymbal Chime Bell Whistle Trumpet Bugle Hum Purr Chatter Babble Murmurs Whisper Giggle Snicker Chortle Guffaw Yodel Warble Trill
Tinkle Jangle Clink Plunk Thrum Strum Twang Boom Bang Pop Fizzbang Kaboom Crackle Snap Crunch Munch Nibble Slurp`
  .split(/\s+/).filter(Boolean).filter((n) => !/-/.test(n));

// ---- deterministic helpers -------------------------------------------------
function fnv(s) {
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 0x01000193) >>> 0; }
  return h >>> 0;
}
function shuffled(list, seed) {
  const out = list.slice();
  let x = fnv(seed) || 1;
  for (let i = out.length - 1; i > 0; i--) {
    x ^= x << 13; x >>>= 0; x ^= x >>> 17; x ^= x << 5; x >>>= 0;
    const j = x % (i + 1);
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}
const dist = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]);
const round4 = (v) => Math.round(v * 10000) / 10000;
const lighten = (rgb, t) => rgb.map((c) => Math.round(c + (255 - c) * t));

// ---- read the game ---------------------------------------------------------
function readGame() {
  const roster = [];
  const rsrc = read(SHARED + "MinePetRoster.luau");
  for (const m of rsrc.matchAll(/\{ name = "([^"]+)", hex3 = "([0-9a-f]{3})", animal = "([^"]+)", tier = "(\w+)"/g)) {
    roster.push({ name: m[1], hex3: m[2], animal: m[3], tier: m[4] });
  }
  const eh = read(SHARED + "MineEHPets.luau");
  const ehBlock = eh.slice(eh.indexOf("ROSTER = {"), eh.indexOf("function MineEventHorizonPets.mergeIntoRoster"));
  const ehNames = new Set([...ehBlock.matchAll(/name = "([^"]+)"/g)].map((m) => m[1]));
  const ehTier = Object.fromEntries([...ehBlock.matchAll(/name = "([^"]+)"[^\n]*?tier = "(\w+)"/g)].map((m) => [m[1], m[2]]));
  const ehAnimals = new Set([...ehBlock.matchAll(/animal = "([^"]+)"/g)].map((m) => m[1]));

  const pmf = read(SHARED + "PetModelFactory.luau");
  const aBlock = pmf.slice(pmf.indexOf("PetModelFactory.ANIMALS = {"), pmf.indexOf("PetModelFactory.DETAILS = {}"));
  const animals = {};
  for (const m of aBlock.matchAll(/\n\t\["([^"]+)"\] = \{ species = "(\w+)", tint = Color3\.fromRGB\((\d+), (\d+), (\d+)\)/g)) {
    animals[m[1]] = { species: m[2], rgb: [+m[3], +m[4], +m[5]] };
  }

  const stats = {};
  for (const m of read(SHARED + "MineStats.luau").matchAll(/\n\t(\w+)\s*= \{ label = "([^"]+)",\s*weight = ([\d.]+)/g)) {
    stats[m[1]] = { label: m[2], weight: +m[3] };
  }

  const cfg = read(SHARED + "MineConfig.luau");
  const rm = cfg.slice(cfg.indexOf("MineConfig.RARITY_MULT = {"));
  const rarityMult = {};
  for (const t of TIERS) rarityMult[t] = +rm.match(new RegExp("\\b" + t + " = ([\\d.]+)"))[1];
  for (const z of ZONES) if (!cfg.includes(`id = "${z.id}"`)) throw new Error("zone id not in MineConfig.ZONES: " + z.id);

  return { roster, ehNames, ehTier, ehAnimals, animals, stats, rarityMult };
}

// ---- build -----------------------------------------------------------------
function build() {
  const G = readGame();
  const zoneIndex = Object.fromEntries(ZONES.map((z, i) => [z.id, i + 1]));
  const nonEH = G.roster.filter((r) => !G.ehNames.has(r.name));
  for (const r of nonEH) {
    if (!G.animals[r.animal]) throw new Error("roster animal with no ANIMALS row: " + r.animal);
    r.species = G.animals[r.animal].species;
  }
  const holidayOf = (r) => HOLIDAY_NAMED[r.name] || HOLIDAY_SPECIES[r.species] || null;
  const holiday = nonEH.filter((r) => holidayOf(r)).map((r) => ({ name: r.name, tier: r.tier, species: r.species, holiday: holidayOf(r) }));
  const regular = nonEH.filter((r) => !holidayOf(r));

  // 1. Deal the existing pets: per tier, sorted by body then name, round robin,
  //    starting one zone later per tier so zone 1 does not get every spare.
  const pets = [];
  const count = {}; // zone -> tier -> n
  for (const z of ZONES) count[z.id] = Object.fromEntries(TIERS.map((t) => [t, 0]));
  TIERS.forEach((tier, ti) => {
    const rows = regular.filter((r) => r.tier === tier).sort((a, b) => (a.species + a.name).localeCompare(b.species + b.name));
    if (rows.length > QUOTA[tier] * ZONES.length) throw new Error(`${rows.length} existing ${tier} pets exceed ${QUOTA[tier]} x ${ZONES.length}`);
    rows.forEach((r, i) => {
      const z = ZONES[(i + ti) % ZONES.length].id;
      count[z][tier]++;
      pets.push({ name: r.name, hex3: r.hex3, animal: r.animal, tier, zone: z, species: r.species, isNew: false });
    });
  });

  // 2. New pets fill each zone to its quota.
  const usedNames = new Set([...G.roster.map((r) => r.name), ...G.ehNames]);
  const usedAnimals = new Set([...Object.keys(G.animals), ...G.ehAnimals]);
  const tintsBy = {}; // species -> [rgb]
  for (const a of Object.values(G.animals)) (tintsBy[a.species] = tintsBy[a.species] || []).push(a.rgb);
  const speciesCount = Object.fromEntries(NEW_SPECIES.map((s) => [s, 0]));
  for (const r of regular) if (r.species in speciesCount) speciesCount[r.species]++;
  const zoneSpecies = {};
  for (const z of ZONES) zoneSpecies[z.id] = {};
  for (const p of pets) zoneSpecies[p.zone][p.species] = (zoneSpecies[p.zone][p.species] || 0) + 1;

  // A name too close to one in use reads as a typo of it ("Murmurs" beside
  // "Murmur"), so compare on lower case with a trailing s dropped.
  const nameKey = (n) => n.toLowerCase().replace(/s$/, "");
  const usedKeys = new Set([...usedNames].map(nameKey));
  const names = shuffled([...new Set(NAMES)].filter((n) => {
    const k = nameKey(n);
    if (usedKeys.has(k)) return false;
    usedKeys.add(k);
    return true;
  }), "zone-pet-names");
  let nameAt = 0;
  let hex = Math.max(...G.roster.map((r) => parseInt(r.hex3, 16)));
  const newAnimals = {};

  const slots = [];
  for (const tier of TIERS) for (const z of ZONES) for (let k = count[z.id][tier]; k < QUOTA[tier]; k++) slots.push({ zone: z.id, tier, k });

  slots.forEach((slot, si) => {
    const zone = ZONES[zoneIndex[slot.zone] - 1];
    // Body: fewest pets overall, then fewest in this zone.
    const species = NEW_SPECIES.slice().sort((a, b) =>
      (speciesCount[a] + 4 * (zoneSpecies[slot.zone][a] || 0)) - (speciesCount[b] + 4 * (zoneSpecies[slot.zone][b] || 0))
      || fnv(a + si) - fnv(b + si))[0];
    speciesCount[species]++;
    zoneSpecies[slot.zone][species] = (zoneSpecies[slot.zone][species] || 0) + 1;

    // Colour: the first palette colour far enough from every tint this body
    // already wears, so two pets on one body never look alike.
    const taken = tintsBy[species] || (tintsBy[species] = []);
    const order = shuffled(PALETTE, slot.zone + slot.tier + si);
    let pick = null;
    for (const minDist of [60, 50, 40, 30]) {
      pick = order.find((c) => taken.every((t) => dist(t, c.slice(1)) >= minDist));
      if (pick) break;
    }
    if (!pick) throw new Error("no free colour for " + species);
    const rgb = pick.slice(1);
    taken.push(rgb);

    const skin = { species, rgb };
    const label = LABEL[species];
    let animal;
    const patterns = Object.keys(PATTERNS).filter((p) => PATTERNS[p].includes(species));
    const wantPattern = patterns.length > 0 && (
      (slot.tier === "Uncommon" && si % 3 === 0) || (slot.tier === "Rare" && si % 2 === 0) || (slot.tier === "Epic" && si % 2 === 1));
    if (TOP.has(slot.tier)) {
      const kind = { Mythic: "Crystal", Divine: "Spirit", Exotic: "Prism" }[slot.tier];
      animal = `${zone.adj} ${kind} ${label}`;
      skin.glow = lighten(rgb, 0.45);
      if (slot.tier === "Mythic") { skin.material = "Glass"; skin.reflect = 0.25; }
      if (slot.tier === "Divine") { skin.transparency = 0.2; }
      if (slot.tier === "Exotic") { skin.chroma = true; }
    } else if (slot.tier === "Legendary") {
      animal = `${LEGEND_WORD[si % LEGEND_WORD.length]} ${pick[0]} ${label}`;
      skin.glow = lighten(rgb, 0.5);
      skin.reflect = 0.2;
    } else {
      animal = `${pick[0]} ${label}`;
      if (wantPattern) {
        const pat = patterns[si % patterns.length];
        skin.detail = [pat];
        animal = `${PATTERN_WORD[pat]} ${animal}`;
      }
      if (slot.tier === "Epic" && !wantPattern) {
        skin.glow = lighten(rgb, 0.4);
        animal = `Glowing ${animal}`;
      }
    }
    if (usedAnimals.has(animal)) animal = `${animal} ${zone.adj}`;
    if (usedAnimals.has(animal)) throw new Error("animal collision: " + animal);
    usedAnimals.add(animal);
    newAnimals[animal] = skin;

    const name = names[nameAt++];
    if (!name) throw new Error("ran out of names");
    usedNames.add(name);
    hex++;
    count[slot.zone][slot.tier]++;
    pets.push({ name, hex3: hex.toString(16).padStart(3, "0"), animal, tier: slot.tier, zone: slot.zone, species, isNew: true });
  });

  // 3. Kits for every zone pet.
  const kits = {};
  const roles = {};
  const topIndex = {};
  const order = pets.slice().sort((a, b) => zoneIndex[a.zone] - zoneIndex[b.zone] || TIERS.indexOf(a.tier) - TIERS.indexOf(b.tier) || a.name.localeCompare(b.name));
  for (const p of order) {
    const zone = ZONES[zoneIndex[p.zone] - 1];
    const mult = Math.pow(ZONE_STEP, zoneIndex[p.zone] - 1);
    const P = (LADDER[p.tier] / G.rarityMult[p.tier]) * mult; // primary points before RARITY_MULT
    const kit = {};
    let shares, statsUsed;
    if (TOP.has(p.tier)) {
      const k = (topIndex[p.zone] = (topIndex[p.zone] || 0) + 1) - 1;
      statsUsed = zone.stats.slice(k % 3).concat(zone.stats.slice(0, k % 3));
      shares = TOP_SHARES;
      roles[p.name] = zone.buff;
    } else {
      const role = ROLE_OF[p.species] || "Striker";
      const r = ROLES[role];
      const pool = r.pairs.concat(p.tier !== "Common" && p.tier !== "Uncommon" && r.rarePlus ? r.rarePlus : []);
      statsUsed = pool[fnv(p.name) % pool.length];
      shares = [1, SECONDARY];
      roles[p.name] = role;
    }
    statsUsed.forEach((stat, i) => {
      if (BANNED.has(stat)) throw new Error("banned stat " + stat);
      const w = G.stats[stat] && G.stats[stat].weight;
      if (!w) throw new Error("no MineStats weight for " + stat);
      kit[stat] = round4((P * shares[i]) / w / 100);
    });
    kits[p.name] = kit;
  }

  // 4. Event Horizon: zone 11, authored mixes rescaled onto the ladder.
  const ehPets = [];
  const ehMult = Math.pow(ZONE_STEP, EVENT_ZONE.index - 1);
  for (const name of [...G.ehNames].sort()) {
    const tier = G.ehTier[name];
    if (!tier) throw new Error("Event Horizon pet with no tier: " + name);
    const mix = EH_MIX[name];
    if (!mix) throw new Error("Event Horizon pet with no frozen mix: " + name);
    const pts = {};
    for (const [stat, v] of Object.entries(mix)) {
      if (BANNED.has(stat) || !(v > 0)) continue;
      pts[stat] = v * 100 * G.stats[stat].weight;
    }
    if (Object.keys(pts).length === 0) { pts.mineSpeed = 2; pts.swingRate = 1; } // a mix of only dead stats
    const have = Object.values(pts).reduce((a, b) => a + b, 0);
    const want = (1.5 * LADDER[tier] * ehMult) / G.rarityMult[tier];
    const kit = {};
    for (const [stat, p] of Object.entries(pts)) kit[stat] = round4((p * want) / have / G.stats[stat].weight / 100);
    kits[name] = kit;
    roles[name] = "Event Horizon";
    ehPets.push({ name, tier, zone: EVENT_ZONE.id });
  }

  // 5. Holiday pets: out of every pot, but owned copies keep paying (zone-1 ladder).
  for (const h of holiday) {
    const role = ROLE_OF[h.species] || "Mystic";
    const r = ROLES[role];
    const pair = r.pairs[fnv(h.name) % r.pairs.length];
    const P = LADDER[h.tier] / G.rarityMult[h.tier];
    const kit = {};
    pair.forEach((stat, i) => { kit[stat] = round4((P * (i === 0 ? 1 : SECONDARY)) / G.stats[stat].weight / 100); });
    kits[h.name] = kit;
    roles[h.name] = role;
  }

  return { G, pets, ehPets, holiday, newAnimals, kits, roles, zoneIndex };
}

// ---- render ----------------------------------------------------------------
const lq = (s) => '"' + s.replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
const rgbLua = (c) => `Color3.fromRGB(${c[0]}, ${c[1]}, ${c[2]})`;
const sortPets = (zoneIndex) => (a, b) => zoneIndex[a.zone] - zoneIndex[b.zone] || TIERS.indexOf(a.tier) - TIERS.indexOf(b.tier) || a.name.localeCompare(b.name);

function kitLua(kit) {
  return "{ " + Object.entries(kit).map(([s, v]) => `${s} = ${v}`).join(", ") + " }";
}

function renderLuau(B) {
  const L = [];
  L.push("--[[");
  L.push("\tMineZonePets -- every regular zone's own pot of 70 pets.");
  L.push("");
  L.push("\tGENERATED by tools/gen/zone-pets.js. Edit the generator and re-run it;");
  L.push("\ttools/verify/zone-pets.js fails when this file is stale.");
  L.push("");
  L.push("\tOwner, 2026-10-10: 70 pets per zone, each zone 5% better than the one");
  L.push("\tbefore, and each zone's Mythic, Divine and Exotic pets carry that zone's");
  L.push("\town buff set, so a new zone never makes the last one's pets useless.");
  L.push("\tEvent Horizon's 73 are zone 11: the same ladder, their own authored mix.");
  L.push("");
  L.push("\tTHIS IS THE ONLY PET KIT TABLE. The old X / Y bags and a second, stale");
  L.push("\tEvent Horizon copy were deleted on 2026-10-10.");
  L.push("");
  L.push("\tWhat reads this:");
  L.push("\t  MinePetRoster   merges PETS into the roster and stamps every pet's zone");
  L.push("\t  MinePetBoosts   KITS become PET_BOOSTS.Z, the only kit bag");
  L.push("\t  PetModelFactory ANIMALS adds the new pets' skins (never overwrites one)");
  L.push("");
  L.push("\tKITS are stored before RARITY_MULT, like every other kit. At Normal and");
  L.push("\tpower level 1 a pet's primary is worth LADDER[tier] x 1.05^(zone-1)");
  L.push("\tpoints (MineStats weights) and its secondary half that; a Mythic,");
  L.push("\tDivine or Exotic spreads the same total over its zone's three buffs.");
  L.push("\tNames are save data: never rename a row here without an alias.");
  L.push("]]");
  L.push("local M = {}");
  L.push("");
  L.push("M.ZONE_ORDER = { " + ZONES.map((z) => lq(z.id)).join(", ") + " }");
  L.push(`-- Event Horizon's own pets, on the ladder as zone ${EVENT_ZONE.index}.`);
  L.push(`M.EVENT_ZONE = ${lq(EVENT_ZONE.id)}`);
  L.push(`M.ZONE_STEP = ${ZONE_STEP}`);
  L.push("M.QUOTA = { " + TIERS.map((t) => `${t} = ${QUOTA[t]}`).join(", ") + " }");
  L.push("M.LADDER = { " + TIERS.map((t) => `${t} = ${LADDER[t]}`).join(", ") + " }");
  L.push("");
  L.push("-- Each zone's Mythic / Divine / Exotic buff set.");
  L.push("M.ZONE_BUFFS = {");
  for (const z of ZONES) L.push(`\t${z.id} = { name = ${lq(z.buff)}, stats = { ${z.stats.map(lq).join(", ")} }, desc = ${lq(z.desc)} },`);
  L.push("}");
  L.push("");
  L.push("-- Common to Legendary: the job a pet's body suggests.");
  L.push("M.ROLES = {");
  for (const [role, r] of Object.entries(ROLES)) L.push(`\t${role} = { desc = ${lq(r.desc)} },`);
  L.push("}");
  L.push("");
  const ps = B.pets.slice().sort(sortPets(B.zoneIndex));
  L.push("-- Existing pets: name -> zone. Their rows stay in MinePetRoster / MineEHPets.");
  L.push("M.ZONE_OF = {");
  for (const p of ps.filter((p) => !p.isNew)) L.push(`\t[${lq(p.name)}] = ${lq(p.zone)},`);
  for (const p of B.ehPets) L.push(`\t[${lq(p.name)}] = ${lq(p.zone)},`);
  L.push("}");
  L.push("");
  L.push("-- Holiday pets: in NO zone pot and NO random roll. Only a holiday pack");
  L.push("-- (\"{Holiday} {year} Pack\", owner 2026-10-10) may hand one out.");
  L.push("M.HOLIDAY = {");
  for (const h of B.holiday) L.push(`\t[${lq(h.name)}] = ${lq(h.holiday)},`);
  L.push("}");
  L.push("");
  L.push("-- New zone pets.");
  L.push("M.PETS = {");
  for (const p of ps.filter((p) => p.isNew)) {
    L.push(`\t{ name = ${lq(p.name)}, hex3 = ${lq(p.hex3)}, animal = ${lq(p.animal)}, tier = ${lq(p.tier)}, zone = ${lq(p.zone)} },`);
  }
  L.push("}");
  L.push("");
  L.push("-- The new pets' skins, in PetModelFactory.ANIMALS's own shape.");
  L.push("M.ANIMALS = {");
  for (const p of ps.filter((p) => p.isNew)) {
    const s = B.newAnimals[p.animal];
    const parts = [`species = ${lq(s.species)}`, `tint = ${rgbLua(s.rgb)}`];
    if (s.glow) parts.push(`glow = ${rgbLua(s.glow)}`);
    if (s.material) parts.push(`material = Enum.Material.${s.material}`);
    if (s.reflect) parts.push(`reflect = ${s.reflect}`);
    if (s.transparency) parts.push(`transparency = ${s.transparency}`);
    if (s.chroma) parts.push("chroma = true");
    if (s.detail) parts.push(`detail = { ${s.detail.map(lq).join(", ")} }`);
    L.push(`\t[${lq(p.animal)}] = { ${parts.join(", ")} },`);
  }
  L.push("}");
  L.push("");
  L.push("-- Every named pet's kit (PET_BOOSTS.Z), and the role or buff set behind it.");
  L.push("M.KITS = {");
  for (const p of ps.concat(B.ehPets, B.holiday)) L.push(`\t[${lq(p.name)}] = ${kitLua(B.kits[p.name])},`);
  L.push("}");
  L.push("M.ROLE = {");
  for (const p of ps.concat(B.ehPets, B.holiday)) L.push(`\t[${lq(p.name)}] = ${lq(B.roles[p.name])},`);
  L.push("}");
  L.push("");
  L.push("local ZONE_INDEX = {}");
  L.push("for i, id in ipairs(M.ZONE_ORDER) do");
  L.push("\tZONE_INDEX[id] = i");
  L.push("end");
  L.push(`ZONE_INDEX[M.EVENT_ZONE] = ${EVENT_ZONE.index}`);
  L.push("for _, row in ipairs(M.PETS) do");
  L.push("\tM.ZONE_OF[row.name] = M.ZONE_OF[row.name] or row.zone");
  L.push("end");
  L.push("");
  L.push("-- The zone a pet's pot belongs to (bigbang for Event Horizon), or nil.");
  L.push("function M.zoneOf(name)");
  L.push("\treturn M.ZONE_OF[name]");
  L.push("end");
  L.push("");
  L.push("-- 1 for meadow .. 10 for primordium, 11 for Event Horizon.");
  L.push("function M.zoneIndex(zoneId)");
  L.push("\treturn ZONE_INDEX[zoneId]");
  L.push("end");
  L.push("");
  L.push("-- The power step a zone's pets carry over meadow's: 1.05 per zone.");
  L.push("function M.zoneMult(zoneId)");
  L.push("\tlocal i = ZONE_INDEX[zoneId]");
  L.push("\treturn i and M.ZONE_STEP ^ (i - 1) or 1");
  L.push("end");
  L.push("");
  L.push("return M");
  return L.join("\n") + "\n";
}

function renderMd(B) {
  const G = B.G;
  const fmt = (kit, tier) => Object.entries(kit).map(([s, v]) => {
    const pct = v * 100 * G.rarityMult[tier];
    return `+${pct >= 10 ? pct.toFixed(0) : pct.toFixed(1)}% ${G.stats[s].label}`;
  }).join(", ");
  const L = [];
  L.push("# Zone pets: the names sheet");
  L.push("");
  L.push("GENERATED by `tools/gen/zone-pets.js`; do not edit by hand. The data the game");
  L.push("reads is `src/ReplicatedStorage/Mine/Shared/MineZonePets.luau`.");
  L.push("");
  L.push("Owner, 2026-10-10: 70 pets per zone, +5% per zone, and each zone's Mythic,");
  L.push("Divine and Exotic carry that zone's own buff set. Event Horizon keeps its 73.");
  L.push("");
  L.push("**Read me:**");
  L.push("- **Boosts** are shown at Normal, power level 1, after rarity. Golden, Shiny and power levels add on top.");
  L.push("- **New** pets are marked ★. Existing pets keep their names and looks, and get a zone and a new kit.");
  L.push("- **Kits follow the approved ladder** (`docs/PROPOSAL.md` §0 line 3): the primary stat is worth");
  L.push("  Common 34 … Exotic 150 points, and the secondary half that, times 1.05 per zone.");
  L.push("");
  L.push("| zone | step | Mythic / Divine / Exotic buff set |");
  L.push("|---|---|---|");
  for (const z of ZONES) L.push(`| ${z.id} | ×${Math.pow(ZONE_STEP, B.zoneIndex[z.id] - 1).toFixed(2)} | **${z.buff}**: ${z.desc} |`);
  L.push("");
  L.push("| role (Common–Legendary) | bodies | job |");
  L.push("|---|---|---|");
  for (const [role, r] of Object.entries(ROLES)) L.push(`| ${role} | ${r.species.map((s) => LABEL[s] || s).join(", ")} | ${r.desc} |`);
  const ps = B.pets.slice().sort(sortPets(B.zoneIndex));
  for (const z of ZONES) {
    const rows = ps.filter((p) => p.zone === z.id);
    L.push("");
    L.push(`## ${z.id[0].toUpperCase() + z.id.slice(1)} (zone ${B.zoneIndex[z.id]}, ${rows.length} pets, ${rows.filter((p) => p.isNew).length} new)`);
    L.push("");
    L.push("| tier | name | looks like | role | boost |");
    L.push("|---|---|---|---|---|");
    for (const p of rows) L.push(`| ${p.tier} | ${p.isNew ? "★ " : ""}${p.name} | ${p.animal} | ${B.roles[p.name]} | ${fmt(B.kits[p.name], p.tier)} |`);
  }
  L.push("");
  L.push(`## Event Horizon (zone ${EVENT_ZONE.index}, ${B.ehPets.length} pets, ×${Math.pow(ZONE_STEP, EVENT_ZONE.index - 1).toFixed(2)})`);
  L.push("");
  L.push("Their own roster and hand-authored stat mix, rescaled onto the ladder; retired stats dropped.");
  L.push("");
  L.push("| tier | name | boost |");
  L.push("|---|---|---|");
  const ehSorted = B.ehPets.slice().sort((a, b) => TIERS.indexOf(a.tier) - TIERS.indexOf(b.tier) || a.name.localeCompare(b.name));
  for (const p of ehSorted) L.push(`| ${p.tier} | ${p.name} | ${fmt(B.kits[p.name], p.tier)} |`);
  L.push("");
  L.push(`## Holiday pets (${B.holiday.length}): not in the game`);
  L.push("");
  L.push("Owner, 2026-10-10: *\"make sure NO holiday ones are in the game.. only allow it from {Holiday} {year} Pack\"*.");
  L.push("They are in no zone pot and no random roll, and keep a zone-1 kit so an owned copy still pays.");
  L.push("");
  L.push("| holiday | tier | name |");
  L.push("|---|---|---|");
  for (const h of B.holiday) L.push(`| ${h.holiday} | ${h.tier} | ${h.name} |`);
  return L.join("\n") + "\n";
}

function main() {
  const B = build();
  const luau = renderLuau(B);
  const md = renderMd(B);
  const check = process.argv.includes("--check");
  const files = [[OUT_LUAU, luau], [OUT_MD, md]];
  let stale = 0;
  for (const [rel, text] of files) {
    const abs = path.join(ROOT, rel);
    const have = fs.existsSync(abs) ? fs.readFileSync(abs, "utf8").replace(/\r\n/g, "\n") : null;
    if (check) {
      if (have !== text) { console.log("STALE  " + rel); stale++; }
    } else {
      fs.writeFileSync(abs, text);
      console.log("wrote  " + rel);
    }
  }
  const newCount = B.pets.filter((p) => p.isNew).length;
  console.log(`${B.pets.length} zone pets (${newCount} new, ${B.pets.length - newCount} existing) in ${ZONES.length} zones`);
  if (check && stale) process.exit(1);
}

module.exports = { build, renderLuau, renderMd, EVENT_ZONE, ZONES, QUOTA, LADDER, ZONE_STEP, TIERS, ROLES, BANNED, OUT_LUAU, OUT_MD };
if (require.main === module) main();
