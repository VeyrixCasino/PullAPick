// TOOLS ARE FORGED, NOT BOUGHT -- and every forged pickaxe has its own skin.
//
// Owner, 2026-10-05: "i think its time to get rid of all coin bought tools.
// apply the skins to each tool".
//
// Two claims that are easy to half-do and hard to notice:
//
//   1. A tab removed from the shop rail is a CLIENT drawing. If the server verbs
//      still sell tools, a modified client buys them anyway and the coin ladder
//      is quietly still in the game. So the guard is asserted on the server, at
//      every door -- surface and depth -- not on the rail.
//   2. 82 ore tiers need 82 DISTINCT asset ids. A copy-paste or a bad merge that
//      points two tiers at one image gives two ores the same pickaxe, which
//      looks like a coincidence rather than a bug and survives review.
//
// Run: node tools/verify/oreskins.js
const path = require("path");
const { readSrc } = require("./_luau.js");
const ROOT = path.join(__dirname, "..", "..");
const ICONS = readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineIcons.luau"));
const SRV = readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));
const SHOP = readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineShopView.luau"));
const CFG = readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"));
const HOTBAR = readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineHotbar.luau"));
const FORGE = readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineForge.luau"));

let fails = 0, checks = 0;
const ok = (c, msg, detail) => {
  checks++;
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("oreskins: no tool is sold for coins, and every ore tier has its own pickaxe");

// ------------------------------------------------------------ the skins --
const tableOf = (name) => {
  const b = new RegExp("MineIcons\\." + name + " = \\{([\\s\\S]*?)\\n\\}").exec(ICONS);
  const m = new Map();
  if (b) for (const e of b[1].matchAll(/\[(\d+)\]\s*=\s*"rbxassetid:\/\/(\d+)"/g)) m.set(+e[1], e[2]);
  return b ? m : null;
};
const byTier = tableOf("ORE_PICK");
ok(!!byTier, "MineIcons.ORE_PICK exists");

// The roster length comes from the config, not from a number restated here.
const oreStart = CFG.split(/\r?\n/).findIndex((l) => l.startsWith("MineConfig.ORES = {"));
const lines = CFG.split(/\r?\n/);
let oreCount = 0;
for (let i = oreStart + 1; i < lines.length; i++) {
  if (lines[i] === "}") break;
  if (/id\s*=\s*"[^"]+".*tier\s*=\s*\d+/.test(lines[i])) oreCount++;
}
ok(oreCount > 0, "read the ore roster from MineConfig", oreCount + " ores");
ok(byTier.size === oreCount, "every ore tier has a skin",
  `${byTier.size} skins for ${oreCount} ores`);

let gaps = [];
for (let t = 1; t <= oreCount; t++) if (!byTier.has(t)) gaps.push(t);
ok(gaps.length === 0, "no tier is missing a skin", gaps.length ? "missing " + gaps.join(",") : "1.." + oreCount);

const ids = [...byTier.values()];
const dupes = ids.filter((v, i) => ids.indexOf(v) !== i);
ok(dupes.length === 0, "no two ores share a pickaxe",
  dupes.length ? [...new Set(dupes)].join(", ") : ids.length + " distinct asset ids");

//[[ Drills and explosives get the same treatment, and the same scrutiny: a
// family whose table is short or has a repeat is a family where some ores
// silently share a picture, which reads as a coincidence rather than a bug. ]]
for (const name of ["ORE_DRILL", "ORE_BOMB"]) {
  const t = tableOf(name);
  ok(!!t, `MineIcons.${name} exists`);
  if (!t) continue;
  ok(t.size === oreCount, `${name} covers every ore tier`, `${t.size} of ${oreCount}`);
  const v = [...t.values()];
  const d = v.filter((x, i) => v.indexOf(x) !== i);
  ok(d.length === 0, `${name} has no two ores sharing a skin`,
    d.length ? [...new Set(d)].join(", ") : v.length + " distinct");
  // And no family may share art with another family.
  const shared = v.filter((x) => ids.includes(x));
  ok(shared.length === 0, `${name} shares no asset with ORE_PICK`,
    shared.length ? shared.length + " shared ids" : "disjoint");
}

for (const n of ["ADMIN_PICK", "ADMIN_DRILL", "ADMIN_BOMB"]) {
  ok(new RegExp("MineIcons\\." + n + ' = "rbxassetid://\\d+"').test(ICONS),
    `${n} is set`, "the last icon of each sheet is the admin tool");
}

ok(/MineIcons\.ORE_PICK_STARTER = "rbxassetid:\/\/\d+"/.test(ICONS),
  "the given wooden pickaxe has its own skin too");
const starter = /MineIcons\.ORE_PICK_STARTER = "rbxassetid:\/\/(\d+)"/.exec(ICONS);
ok(starter && !ids.includes(starter[1]),
  "the starter skin is not also an ore's skin",
  starter ? starter[1] : "none");

// ---------------------------------------------------- one lookup, used --
ok(/function MineIcons\.forTool\(/.test(ICONS), "MineIcons.forTool is the single lookup");

//[[ All three forged families have their own art now. This check used to assert
// the OPPOSITE -- "only skins the pickaxe family" -- which was right while every
// render was a pickaxe and dressing a drill in one would have been a lie about
// what you are holding. The owner supplied drill and explosive sheets, so the
// rule inverted: each family uses its own table, and a family with NO table
// falls back to its flat family icon rather than borrowing another's art. ]]
const fn = /function MineIcons\.forTool\(([\s\S]*?)\nend/.exec(ICONS);
ok(fn && /ORE_SKINS\[fam\]/.test(fn[1]),
  "forTool picks the skin table by family",
  "so a family without art cannot borrow another family's");
ok(fn && /MineIcons\.IMAGES\[fam\]/.test(fn[1]),
  "forTool falls back to the flat family icon when a family has no skins");
for (const [fam, tbl] of [["pickaxe", "ORE_PICK"], ["drill", "ORE_DRILL"], ["explosive", "ORE_BOMB"]]) {
  const b = /MineIcons\.ORE_SKINS = \{([\s\S]*?)\n\}/.exec(ICONS);
  ok(b && new RegExp(fam + "\\s*=\\s*MineIcons\\." + tbl).test(b[1]),
    `${fam} maps to ${tbl}`);
}

ok(/Icons\.forTool\(/.test(HOTBAR), "the hotbar draws through forTool");
ok(/Icons\.forTool\(/.test(FORGE), "the Forge hero draws through forTool");
ok(!/IMG\[fam\]\s*or\s*IMG\.pickaxe/.test(HOTBAR + FORGE),
  "no draw site still falls back to the one generic pickaxe");

// -------------------------------------------------- nothing sells tools --
ok(/MineConfig\.FORGE_ONLY_FAMILIES = \{/.test(CFG),
  "MineConfig names the forge-only families");
const famBlock = /MineConfig\.FORGE_ONLY_FAMILIES = \{([^}]*)\}/.exec(CFG);
for (const fam of ["pickaxe", "drill", "explosive"]) {
  ok(famBlock && new RegExp(fam + "\\s*=\\s*true").test(famBlock[1]),
    `${fam} is refused`);
}

//[[ The guard must NOT be a top-level local in MineServer. It was, briefly, and
// that one register broke the entire server: the script is at Luau's 200-local
// ceiling, so it failed to compile, MineNet was never created, and every client
// hung on WaitForChild("MineNet") with no other symptom in the log. ]]
ok(!/^local TOOL_FAMILIES_NOT_FOR_SALE/m.test(SRV),
  "the family list is not a top-level local in MineServer",
  "that script is at the 200-register ceiling");
// Both doors. The depth desks sell off the same ladders, so guarding only the
// surface would leave every outpost below 500m still selling pickaxes.
const body = (name) => {
  const i = SRV.indexOf("local function " + name + "(");
  if (i < 0) return "";
  const j = SRV.indexOf("\nend", i);
  return SRV.slice(i, j);
};
for (const verb of ["buyTool", "buyDepthTool"]) {
  const b = body(verb);
  ok(b.length > 0, verb + " is findable");
  ok(/FORGE_ONLY_FAMILIES/.test(b), verb + " consults C.FORGE_ONLY_FAMILIES");
}

// And the rail agrees with the rule.
const tabs = /local TABS = \{([\s\S]*?)\n\}/.exec(SHOP);
ok(!!tabs, "the shop TABS list is findable");
for (const id of ["pickaxe", "drill", "explosive"]) {
  ok(tabs && !new RegExp(`id = "${id}"`).test(tabs[1]),
    `the ${id} tab is gone from the shop rail`);
}
for (const id of ["bench", "pouch", "backpack"]) {
  ok(tabs && new RegExp(`id = "${id}"`).test(tabs[1]),
    `${id} still sells`, id === "backpack" ? "capacity, not a tool" : "");
}

// --------------------------------------------- the roster is NOT deleted --
// MineOreTools.frames filters Tools.TOOLS on price > 0 to pick a forged tool's
// frame. Deleting the priced rows with the tabs would blank every silhouette.
const TOOLS = readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineTools.luau"));
const priced = [...TOOLS.matchAll(/price\s*=\s*(\d+)/g)].filter((m) => +m[1] > 0).length;
ok(priced > 20, "the MineTools roster still carries priced rungs",
  priced + " priced rows -- MineOreTools.frames() needs these for forged frames");

console.log(fails === 0
  ? `>>> oreskins OK (${checks} checks)`
  : `>>> ${fails} FAILED of ${checks}`);
process.exit(fails === 0 ? 0 : 1);
