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
// Launch audit S9/S10: the craft quote and the SCRAP quote go through the same
// MineOreTools functions the server's verbs charge and pay with (see
// forge-cards.js and recycle-quote.js), and the panel calls MineConfig's craft
// and recycle maths directly nowhere -- that is how the two sides drifted.
const hubCode = hub.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");
check(/OreTools\.craftCost\(/.test(hubCode) && /C\.toolUpgradeCost\(/.test(hubCode) && /OreTools\.recycleRefund\(o\.tool\)/.test(hubCode)
  && !/C\.toolCraftCost\(|C\.toolRecycle\(/.test(hubCode),
  "prices come from the server's own rules (MineOreTools / MineConfig), never the panel's own maths");
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
// ONE FORGE (launch audit S13; owner, 2026-10-19): the old shop shows only Bags,
// its Crafting / Loadout / Upgrades tabs open this hub, and COIN SHOP is gone
// (it opened a pickaxe shelf where every BUY is refused).
check(/if \(tab == "pickaxe" or tab == "backpack"\) and shopCtl\.setTab then/.test(client) && /opts\.onShop\("backpack"\)/.test(hubCode)
  && /ev:Fire\("shop", tab\)/.test(hubClient) && /openPanelEv\.Name = "OpenPanel"/.test(client),
  "the hub's BAGS button still reaches the old shop's Bags shelf");
// The tool shelf's one live job was Event Horizon's own tools (space coins):
// that door stays, renamed, and only while the player stands in the event.
check(!/COIN SHOP"/.test(hubCode) && /"🚀 EVENT TOOLS"/.test(hubCode)
  && /_eventToolsBtn\.Visible = snap\.zoneId == "bigbang"/.test(hubCode)
  && (hubCode.match(/opts\.onShop\("pickaxe"\)/g) || []).length === 1,
  "the hub's COIN SHOP button is gone (S13); the tool-shelf door shows only in Event Horizon");
{
  const shop = read("src/ReplicatedStorage/Mine/Shared/MineShopView.luau");
  const tabs = (/local TABS = \{([\s\S]*?)\n\}/.exec(shop) || ["", ""])[1].split("\n").filter((l) => /id = "/.test(l));
  check(tabs.length === 4 && /id = "backpack"/.test(tabs[0]),
    "the old shop opens on Bags, its first tab (S13)");
  check(/local FORGE_TABS = \{ bench = "craft", loadout = "loadout", upgrades = "upgrades" \}/.test(shop)
    && /local activeTab = "backpack"/.test(shop),
    "...and its Crafting / Loadout / Upgrades tabs map to the hub's three tabs");
  check(/FORGE_TABS\[id\] and opts\.onOpenForge and opts\.onOpenForge\(FORGE_TABS\[id\]\)/.test(shop)
    && /function view\.setTab\(id\)\s*\n\s*id = forgeRoute\(id\)/.test(shop)
    && /local routed = forgeRoute\(tab or activeTab\)/.test(shop),
    "...and both setTab and open send those tabs to the hub, every other shelf to Bags");
  check(/not \(EVENT_TABS\[id\] and state\.zoneId == "bigbang"\)/.test(shop) && /Horizon\.shopRows\(activeTab\)/.test(shop),
    "...except the Event Horizon tool shelf, while standing in the event");
  check(/onOpenForge = function\(tab\)[\s\S]{0,300}FindFirstChild\("ForgeHubOpen"\)[\s\S]{0,120}hubOpen:Fire\(tab\)/.test(client),
    "MineClient hands the shop a door to the hub (onOpenForge fires ForgeHubOpen)");
}
check(/\[3\] = \{ text = "Coins burning a hole\? BUY A BIGGER PICK\.", panel = "shop", tab = "pickaxe"/.test(server)
  && /net:FireClient\(plr, "openPanel", "shop", onPickStep and "pickaxe" or nil\)/.test(server),
  "the tutorial's buy-a-pick step still lands on the coin pickaxes, at the counter too");
check(/if tab == "counter" then\s*\n\s*if hub\.isOpen\(\) then\s*\n\s*return/.test(hubClient), "walking up to a counter only opens the hub, never closes it");

console.log("");
console.log(fail > 0 ? `>>> forge-hub: ${fail} FAILED` : ">>> forge-hub: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
