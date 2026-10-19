// The Forge hub (MineForgeHub): wiring and honesty checks.
//
//   1. it opens from the Forge dock button and hides the dock like the Blacksmith
//   2. every action is a real server verb, and every verb it sends exists
//   3. it reads the real rules (prices, enchants), not numbers of its own
//   4. destructive actions ask twice; actions lock against double taps
//   5. the demo Forges are gone
//
//   node tools/verify/forge-hub.js
"use strict";
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");
const exists = (p) => fs.existsSync(path.join(ROOT, p));
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

const hub = read("src/ReplicatedStorage/Mine/Shared/MineForgeHub.luau");
const hubClient = read("src/StarterPlayer/StarterPlayerScripts/MineForgeHub.client.luau");
const client = read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");
const server = read("src/ServerScriptService/Mine/MineServer.server.luau");
const ench = read("src/ServerScriptService/Mine/MineEnchantService.luau");

// 1
check(/Name = "ForgeHub"/.test(hub) && /WaitForChild\("MineUI"/.test(hubClient), "the hub is a frame named ForgeHub inside the main HUD");
check(/HUD_HIDERS = \{[^}]*ForgeHub = true/.test(client), "MineClient's HUD hiders hide the dock and wallet while it is open (owner: \"AS PER USUAL\")");
check((client.match(/\t\tForgeHub = true,/g) || []).length === 2, "...and the quest panel retracts under it (QUEST_HIDERS and QUEST_WATCH)");
check(/dockBtn\("", "Forge", function\(\)[\s\S]{0,1400}FindFirstChild\("ForgeHubOpen"\)[\s\S]{0,200}hubOpen:Fire\(\)/.test(client), "the Forge (anvil) dock button opens the hub");
check(/Name = "ForgeHubOpen"/.test(hubClient), "the hub client makes the event the dock button fires");

// 2
const verbs = [...new Set([...hub.matchAll(/act\("([a-zA-Z]+)"/g)].map((m) => m[1]))];
const serverVerb = (v) => new RegExp(`action == "${v}"`).test(server) || (v.startsWith("ench") && new RegExp(`function V\\.${v}\\(`).test(ench));
const missing = verbs.filter((v) => !serverVerb(v));
check(verbs.length >= 8 && missing.length === 0, `every action is a real verb (${verbs.join(", ")})${missing.length ? " MISSING: " + missing.join(", ") : ""}`);
check(/action == "snapNow"/.test(server) && /FireServer\("snapNow"\)/.test(hubClient), "opening asks the server for fresh numbers");

// 3
check(/C\.toolCraftCost\(/.test(hub) && /C\.toolUpgradeCost\(/.test(hub) && /C\.toolRecycle\(/.test(hub), "prices come from MineConfig, never the panel's own maths");
check(/E\.compatible\(/.test(hub) && /E\.describe\(/.test(hub) && /E\.slotUnlocked\(/.test(hub), "enchant cards read MineEnchants (compatibility, effect text, slot locks)");
check(/COMING SOON/.test(hub) && /def\.live/.test(hub), "not-yet-live enchants say COMING SOON instead of pretending");

// 4
check(/TAP AGAIN TO SCRAP/.test(hub) && /state\.uConfirm == o\.uid/.test(hub), "scrapping asks twice and says what comes back");
check(/busyUntil = os\.clock\(\) \+ 2/.test(hub) && /busyUntil = 0/.test(hub), "every action locks until the next snapshot (or 2 s): no double sends");
check(/Craftable first, best first/.test(hub), "recipes sort craftable first, best first (owner)");

// 5
check(!exists("src/ReplicatedStorage/Mine/Shared/MineForgeDemo.luau") && !exists("src/StarterPlayer/StarterPlayerScripts/MineForgeDemo.client.luau"),
  "the two demo Forges are gone (the owner picked A)");
// The Blacksmith counter (owner, 2026-10-12: "the Blacksmith counter should open the Forge hub").
check(/if \(name == "shop" and tab == nil\) or name == "forge" then[\s\S]{0,300}hubOpen:Fire\(\(name == "forge" and tab == "enchant"\) and "enchant" or "counter"\)/.test(client),
  "every plain \"shop\" (the counters, the Blacksmith buttons) opens the Forge hub");
check(/if \(tab == "pickaxe" or tab == "backpack"\) and shopCtl\.setTab then/.test(client) && /opts\.onShop\("backpack"\)/.test(hub) && /opts\.onShop\("pickaxe"\)/.test(hub)
  && /ev:Fire\("shop", tab\)/.test(hubClient) && /openPanelEv\.Name = "OpenPanel"/.test(client),
  "the hub's BAGS and COIN SHOP buttons still reach the old shop's two shelves");
check(/\[3\] = \{ text = "[^"]*BUY A BIGGER PICK!?\.?", panel = "shop", tab = "pickaxe"/.test(server)
  && /net:FireClient\(plr, "openPanel", "shop", onPickStep and "pickaxe" or nil\)/.test(server),
  "the tutorial's buy-a-pick step still lands on the coin pickaxes, at the counter too");
check(/if tab == "counter" then\s*\n\s*if hub\.isOpen\(\) then\s*\n\s*return/.test(hubClient), "walking up to a counter only opens the hub, never closes it");

console.log("");
console.log(fail > 0 ? `>>> forge-hub: ${fail} FAILED` : ">>> forge-hub: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
