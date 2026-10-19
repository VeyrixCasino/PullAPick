// THE TUTORIAL'S STEP 3 IS "FORGE YOUR FIRST TOOL" (owner, 2026-10-19, launch audit M1),
// and the Blacksmith's first visit hands the pickaxe over without the Forge (S19).
//
// Step 3 was "BUY A BIGGER PICK" on the coin pickaxe shelf, and every BUY there is
// refused (pickaxes are in MineConfig.FORGE_ONLY_FAMILIES), so the 5th step of the
// tutorial could not be done. This pins the replacement:
//   * the step opens the Forge on CRAFTING and grants ore, not coins;
//   * the grant is exactly one Stone Pickaxe, priced by the Forge's own function
//     (run here in luau against the real MineConfig: 270 Stone on 2026-10-19);
//   * the first craft clears it, and only a craft does;
//   * a forged tool (or a graduated starter) counts as done, so nobody is stuck;
//   * the counter no longer opens the coin shelf, and the free-pick visit opens nothing;
//   * quest rung 3 matches, counted absolutely.
//
//   node tools/verify/tutorial-forge.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => Luau.readSrc(path.join(ROOT, p));
// Comments out first: a check that reads prose passes on the explanation.
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }

const svRaw = read("src/ServerScriptService/Mine/MineServer.server.luau");
const sv = code(svRaw);
const shopBuy = code(read(SH + "MineShopBuy.luau"));
const cl = code(read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));
const hubClient = code(read("src/StarterPlayer/StarterPlayerScripts/MineForgeHub.client.luau"));
const quests = code(read(SH + "MineQuests.luau"));
const cfg = read(SH + "MineConfig.luau");

// 1. The step itself.
const step3 = (sv.match(/\[3\] = \{[^\n]*\}/) || [""])[0];
check(/text = "FORGE your first tool/.test(step3), `step 3 reads "FORGE your first tool" (${step3.slice(0, 60)}...)`);
check(/panel = "forge", tab = "craft"/.test(step3), "...and opens the Forge on CRAFTING");
check(/grantCraft = \{ oreId = "stone", familyId = "pickaxe" \}/.test(step3) && !/grantCoins/.test(step3),
  "...and grants Stone for a Stone Pickaxe, not coins");
check(!/nextPick|BUY A BIGGER PICK/.test(sv), "the coin top-up (\"nextPick\") and the old line are gone");

// 2. The grant, priced by the Forge's own function, topped up once.
const grant = (sv.match(/local function introGrant\(plr, p\)[\s\S]*?\nend\n/) || [""])[0];
check(/C\.toolCraftCost\(oreDef\.tier, OreTools\.typeMult\(fam, oreDef\.tier\), fam\)/.test(grant),
  "the grant is priced by C.toolCraftCost with the Forge's typeMult, never a number of its own");
check(/if need > have then\s*\n\s*p\.ores\[oreDef\.id\] = need/.test(grant) && /p\.oresSeen\[oreDef\.id\] = true/.test(grant),
  "...topped up (never added) and marked seen, so the recipe shows");
check(/not p\.introGrants\[key \.\. "craft"\][\s\S]{0,80}p\.introGrants\[key \.\. "craft"\] = true/.test(grant)
  && /not introSatisfied\(p, step\)/.test(grant), "...once (its own spent mark), and not for anyone who already forged");
const forgeHub = read(SH + "MineForgeHub.luau");
check(/C\.toolCraftCost\(def\.tier, OreTools\.typeMult\(fam, def\.tier\), fam\)/.test(forgeHub),
  "the Forge hub quotes with the same expression");

// The number, from the real config (craftcost.js slices the same functions).
const grab = (re, what) => { const m = cfg.match(re); if (!m) { check(false, "could not find " + what); return ""; } return m[0]; };
const num = (k) => Number((cfg.match(new RegExp(`MineConfig\\.${k}\\s*=\\s*([\\d.]+)`)) || [])[1]);
const oreRows = (cfg.match(/MineConfig\.ORES = \{([\s\S]*?)\n\}/) || ["", ""])[1].split("\n").filter((l) => /\{\s*id = "/.test(l));
const stoneTier = Number(((oreRows.find((l) => /id = "stone"/.test(l)) || "").match(/tier = (\d+)/) || [])[1]);
const steps = ((read(SH + "MineOreTools.luau").match(/pickaxe = \{ ([\d, ]+) \}/) || [])[1] || "").split(",").map(Number);
const typeMult = steps.findIndex((upTo) => stoneTier <= upTo) + 1;
const harness = `
local MineConfig = { ORE_COUNT = ${oreRows.length}, CRAFT_BLOCKS = ${num("CRAFT_BLOCKS")},
	CRAFT_BAND_EASE = ${num("CRAFT_BAND_EASE")}, CRAFT_DEPTH_SLOPE = ${num("CRAFT_DEPTH_SLOPE")} }
${grab(/MineConfig\.ORE_YIELD_BANDS = \{[\s\S]*?\n\}/, "ORE_YIELD_BANDS")}
${grab(/MineConfig\.ORE_BAND_ORDER = \{[^\n]*\}/, "ORE_BAND_ORDER")}
${grab(/function MineConfig\.oreYieldFor\(tier\)[\s\S]*?\nend\n/, "oreYieldFor")}
${grab(/function MineConfig\.oreBandForTier\(tier\)[\s\S]*?\nend\n/, "oreBandForTier")}
${grab(/function MineConfig\.craftBlocks\(tier\)[\s\S]*?\nend\n/, "craftBlocks")}
${grab(/function MineConfig\.oreYieldMid\(tier\)[\s\S]*?\nend\n/, "oreYieldMid")}
${grab(/MineConfig\.FAMILY_CRAFT_COST = \{[\s\S]*?\n\}/, "FAMILY_CRAFT_COST")}
${grab(/function MineConfig\.toolCraftCost\(tier, typeMult[^)]*\)[\s\S]*?\nend\n/, "toolCraftCost")}
print("COST|" .. tostring(MineConfig.toolCraftCost(${stoneTier || 1}, ${typeMult || 1}, "pickaxe")))
`;
const script = path.join(ROOT, ".luau-bin/tutorial-forge-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" }); }
catch (e) { process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || ""); fail++; }
const cost = Number(((out.match(/COST\|(\d+)/) || [])[1]));
check(stoneTier === 1 && typeMult === 1, `Stone is ore tier ${stoneTier}, a tier-1 pickaxe's typeMult is ${typeMult}`);
check(cost === 270, `one Stone Pickaxe costs ${cost} Stone, the grant the owner was quoted (270)`);

// 3. The first craft clears it, and nothing else does.
const craft = (sv.match(/function Verbs\.craftOreTool[\s\S]*?\nend\n/) || [""])[0];
check(/introAdvance\(plr, p, 3\)/.test(craft), "Verbs.craftOreTool advances step 3");
const step3Calls = (sv.match(/introAdvance\(plr, p, 3\)/g) || []).length + (shopBuy.match(/introAdvance\(plr, p, 3\)/g) || []).length;
check(step3Calls === 1, `...and it is the only thing that does: no coin purchase clears it (${step3Calls} call site)`);

// 4. Done already counts: a forged tool, or the starter graduated.
const sat = (sv.match(/local function introSatisfied\(p, step\)[\s\S]*?\n\telseif step == 6/) || [""])[0];
check(/for _, t in ipairs\(p\.oreTools or \{\}\)/.test(sat) && /C\.isCoinTool\(t\)/.test(sat) && /return ownsBetterPickaxe\(p\)/.test(sat),
  "introSatisfied(3): any forged tool (not the free Wooden Pickaxe), or a graduated starter");
check(/if p and step == 3 and introSatisfied\(p, 3\) then/.test(sv) && /\(step == 3 and introSatisfied\(p, 3\)\)/.test(sv),
  "...and a player already done sees CLAIM instead of the Forge (introSend, introAck)");
check(/function Verbs\._graduateTutorialPick\(plr, p\)/.test(sv) && /p\.tools\.pickaxe = tier/.test(sv),
  "the Wooden Pickaxe still graduates (and ownsBetterPickaxe reads p.tools.pickaxe)");

// 5. The ladder still reaches every step after it.
const order = ((sv.match(/order = \{ ([\d, ]+) \}/) || [])[1] || "").split(",").map((s) => Number(s.trim()));
const stepsBlock = (sv.match(/steps = \{([\s\S]*?)\n\t\},\n/) || ["", ""])[1];
const defined = new Set([...stepsBlock.matchAll(/\[(\d+)\] = \{/g)].map((m) => Number(m[1])));
check(order.length >= 10 && order.includes(3) && order.every((n) => defined.has(n)),
  `every step in Intro.order is defined, 3 included (${order.join(", ")})`);
check(order.indexOf(3) >= 0 && order.indexOf(3) < order.length - 1, "...and 3 is not the last, so the steps after it are reached");

// 6. The counter: the Forge on every step, nothing on the free-pick visit.
const counter = (sv.match(/elseif machine == "shop" then[\s\S]*?elseif machine == "open"/) || [""])[0];
check(counter.length > 0 && !/onPickStep|"pickaxe"/.test(counter), "the counter no longer opens the coin pickaxe shelf on step 3");
check(/local firstVisit = Verbs\.grantFirstPick\(plr, profiles\[plr\.UserId\]\)/.test(counter)
  && /if not firstVisit then\s*\n\s*net:FireClient\(plr, "openPanel", "shop"\)/.test(counter),
  "the visit that hands over the free pickaxe does not pop the Forge (S19)");
// (Raw source here: the toast's own " -- FREE" would read as a comment.)
check(/return true\s*\nend\s*\n/.test((svRaw.match(/function Verbs\.grantFirstPick[\s\S]*?\nend\n/) || [""])[0])
  && /net:FireClient\(plr, "toast", \(\(row and row\.name\) or "Pickaxe"\) \.\. " -- FREE/.test(svRaw),
  "...grantFirstPick still says so in a toast and returns true when it granted");

// 7. The client opens CRAFTING.
check(/hubOpen:Fire\(\(name == "forge" and \(tab == "enchant" or tab == "craft"\)\) and tab or "counter"\)/.test(cl),
  "routePanel(\"forge\", \"craft\") asks the hub for CRAFTING");
check(/elseif tab == "craft" then[\s\S]{0,120}hub\.open\("craft"\)/.test(hubClient), "...and the hub opens on it");

// 8. Quest rung 3 matches, counted absolutely.
const pick2 = (quests.match(/\{ id = "pick2",[^\n]*\}/) || [""])[0];
check(/stat = "oretools", goal = 1,\s+absolute = true, text = "Forge your first tool"/.test(pick2), "quest rung 3 is \"Forge your first tool\" (stat oretools)");
check((sv.match(/q\.stat == "picktier" or q\.absolute/g) || []).length === 2,
  "...and both the tracker and the claim count it absolutely (a tool forged first still counts)");

console.log("");
console.log(fail > 0 ? `>>> tutorial-forge: ${fail} FAILED` : ">>> tutorial-forge: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
