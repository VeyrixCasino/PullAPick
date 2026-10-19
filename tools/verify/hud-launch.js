// HUD FIXES FROM THE LAUNCH AUDIT (owner's picks, 2026-10-19). Static: these are
// wiring and layout facts that need no Roblox to read.
//
//   S17  the skill tree has a red X that closes it without travelling
//   S18  close-everything also closes Skins, Trade, Fishing and the Forge hub,
//        so Inventory / Pass / Jobs never open underneath one of them
//   S20  the day-4 pack is given regardless: no LIKE, an optional real Favorite
//   S21  the coin pill shows one currency, the zone's
//   S22  Settings' code result has its own line, clear of FRIENDS
//   S23  a snapshot neither rebuilds the open Planets map nor the daily week
//   S26  button sounds are bound once, on the main HUD, and throttled
//
//   node tools/verify/hud-launch.js
"use strict";
const path = require("path");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

const cl = code(read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));

// S17
const skill = code(read(SH + "MineSkillView.luau"));
const closeClick = (skill.match(/closeBtn\.MouseButton1Click:Connect\(function\(\)([\s\S]*?)\n\tend\)/) || ["", ""])[1];
check(/local closeBtn = corner\(mk\("TextButton", \{[\s\S]{0,300}Text = "X"[\s\S]{0,200}\}, top\)/.test(skill),
  "S17 the skill tree's top bar has an X");
check(/UI\.candy\(closeBtn, "red"/.test(skill), "...red candy, like every other window's close");
check(/root\.Visible = false/.test(closeClick) && !/onAscend|onGoClouds|FireServer/.test(closeClick),
  "...that only hides the wheel: no ascend, no trip to the Clouds, no server call");

// S18
const hide = (cl.match(/local function hidePanels\(\)[\s\S]*?\nend\n/) || [""])[0];
check(hide.length > 100, "found hidePanels");
check(/skinsCtl\.close\(\)/.test(hide), "S18 close-everything closes Skins");
check(/ClientFns\.tradeCtl\.close\(\)/.test(hide), "...the trade picker and window");
check(/ClientFns\.fishingCtl\.close\(\)/.test(hide), "...fishing");
check(/FindFirstChild\("ForgeHubOpen"\)[\s\S]{0,60}hubEv:Fire\("close"\)/.test(hide), "...and the Forge hub, through its event");
const trade = code(read(SH + "MineTradeView.luau"));
check(/function ctl\.close\(\)\s*\n\s*picker\.Visible = false\s*\n\s*if win\.Visible then\s*\n\s*cancel\(\)/.test(trade),
  "...the trade view can close: the picker hides, a live trade cancels the way its own X does");
const hubClient = code(read("src/StarterPlayer/StarterPlayerScripts/MineForgeHub.client.luau"));
check(/if tab == "close" then\s*\n\s*if hub\.isOpen\(\) then\s*\n\s*hub\.close\(\)\s*\n\s*end\s*\n\s*return/.test(hubClient),
  "...the hub's \"close\" only ever closes");
check(/local hubFrame = gui:FindFirstChild\("ForgeHub"\)\s*\n\s*if not \(hubFrame and hubFrame\.Visible\) then\s*\n\s*hidePanels\(\)\s*\n\s*end\s*\n\s*hubOpen:Fire\(\)/.test(cl),
  "...and the anvil button still toggles the hub shut (it skips close-everything when the hub is open)");
for (const [name, opener] of [["Inventory", /invCtl\.open\("inventory", "tools"\)/], ["Pass", /invCtl\.open\("pass", "pass"\)/], ["Jobs", /depthHud\.contractor\.open\(\)/]]) {
  const dock = (cl.match(new RegExp(`dockBtn\\([^,]+, "${name}", function\\(\\)[\\s\\S]*?\\nend\\)`)) || [""])[0];
  check(/hidePanels\(\)/.test(dock) && opener.test(dock) && dock.indexOf("hidePanels()") < dock.search(opener),
    `...so ${name} closes everything (Skins included) before it opens`);
}

// S20
const surprise = (cl.match(/local dailySurprise = \{\}[\s\S]*?dailySurprise\.claimBtn\.MouseButton1Click:Connect\(dailySurprise\.claim\)/) || [""])[0];
check(surprise.length > 500, "found the day-4 surprise popup");
check(!/likeBtn|"LIKE"|OpenBrowserWindow/.test(surprise), "S20 no LIKE button (no API can open a like)");
check(/pcall\(function\(\)\s*\n\s*AvatarEditorService:PromptSetFavorite\(game\.PlaceId, Enum\.AvatarItemType\.Asset, true\)/.test(surprise),
  "...Favorite is Roblox's real prompt, in a pcall");
const claimFn = (surprise.match(/function dailySurprise\.claim\(\)[\s\S]*?\nend\n/) || [""])[0];
check(claimFn.length > 0 && !/favorit|liked/i.test(claimFn) && /FireServer\("claimDailySurprise"\)/.test(claimFn),
  "...and CLAIM is gated on nothing");
check(/dailySurprise\.close\.MouseButton1Click:Connect\(function\(\)\s*\n\s*dailySurprise\.claim\(\)/.test(surprise),
  "...closing the popup claims too: the pack is given regardless");
const svCode = code(read("src/ServerScriptService/Mine/MineServer.server.luau"));
const svClaim = (svCode.match(/function Verbs\.claimDailySurprise\(plr\)[\s\S]*?\nend\n/) || [""])[0];
check(svClaim.length > 100 && !/favorit|like/i.test(svClaim), "...and the server's claim checks only the day");

// S21
const hud = (cl.match(/local function refreshHud\(\)[\s\S]*?\nend\n/) || [""])[0];
const coinLines = hud.split("\n").filter((l) => /coinsL\.Text =/.test(l));
check(coinLines.length === 2 && coinLines.every((l) => !/\|/.test(l)) && /snap\.zoneId == "bigbang"/.test(hud),
  "S21 the coin pill shows one currency: space coins in Event Horizon, coins everywhere else");

// S22
const settings = (cl.match(/function ClientFns\.settings\(\)[\s\S]*?\nend\n/) || [""])[0];
const H = +((settings.match(/local W, H = 440, (\d+)/) || [])[1] || 0);
const status = settings.match(/local codeStatus = label\("", \d+, MUTED, (\d+), (\d+)\)/);
const friendsY = +((settings.match(/label\("FRIENDS", \d+, MUTED, (\d+)/) || [])[1] || 0);
check(status && friendsY > 0 && +status[1] + +status[2] <= friendsY,
  `S22 the code result (y ${status && status[1]}, ${status && status[2]} tall) ends above FRIENDS (y ${friendsY})`);
const ys = [...settings.matchAll(/Position = UDim2\.fromOffset\(22, (\d+)\), Size = UDim2\.new\(1, -44, 0, 40\)/g)].map((m) => +m[1]);
const notifyY = Math.max(...ys.slice(0, -1));
const starterY = ys[ys.length - 1];
check(ys.length >= 3 && starterY + 40 <= H && notifyY + 40 <= H - 52,
  `...and every button still fits the panel (last button ends at ${starterY + 40} of ${H}; without the bundle row ${notifyY + 40} of ${H - 52})`);

// S23
const zones = (cl.match(/refreshZones = function\(live\)[\s\S]*?\nend\n/) || [""])[0];
check(/if live and ClientFns\.mapKey == key then\s*\n\s*return/.test(zones), "S23 a snapshot leaves the open Planets map alone unless its planets changed");
check(/selectedZoneId = ClientFns\.mapSel or snap\.zoneId/.test(zones) && /onSelect = function\(zoneId\)\s*\n\s*ClientFns\.mapSel = zoneId/.test(zones),
  "...and a rebuild keeps the planet you picked");
check(/if zoneP and zoneP\.Visible then refreshZones\(true\) end/.test(cl), "...the snapshot path is the `live` one");
check(/if opts\.onSelect then opts\.onSelect\(zone\.id\) end/.test(code(read(SH + "MineZoneMapView.luau"))), "...and the map reports every pick");
const cal = (cl.match(/function ClientFns\.paintDailyCalendar\(state\)[\s\S]*?\nend\n/) || [""])[0];
check(/local same = dailyHud\.calKey == calKey/.test(cal) && /for _, c in ipairs\(same and \{\} or dailyHud\.cal:GetChildren\(\)\)/.test(cal)
  && /for _, d in ipairs\(same and \{\} or cal\) do/.test(cal), "...and the daily card rebuilds its week only when the week changed");

// S26
const audio = code(read(SH + "MineAudio.luau"));
const binds = (cl.match(/Audio\.bindUiClicks/g) || []).length;
check(binds === 1 && /pcall\(Audio\.bindUiClicks, gui\)/.test(cl), `S26 button sounds are bound once, on the main HUD ScreenGui (${binds} call)`);
check(/if not root or root:GetAttribute\("UiClicksBound"\) then\s*\n\s*return/.test(audio) && /root:SetAttribute\("UiClicksBound", true\)/.test(audio),
  "...and binding the same root twice is a no-op");
const cd = (audio.match(/local CD = \{([\s\S]*?)\n\}/) || ["", ""])[1];
const cdOf = (k) => Number((cd.match(new RegExp(`\\b${k} = ([\\d.]+)`)) || [])[1]);
check(cdOf("click") > 0 && cdOf("deny") > 0 && /if lastAt\[name\] and \(now - lastAt\[name\]\) < waitFor then/.test(audio),
  `...and throttled: click ${cdOf("click")} s, deny ${cdOf("deny")} s between plays`);
check(/MineAudio\.play\("click"\)/.test(audio) && /if b\.Active or b:GetAttribute\("NoClickSfx"\) then/.test(audio) && /MineAudio\.play\("deny"\)/.test(audio),
  "...a click on a press, the knock only on a greyed (inactive) button");

console.log("");
console.log(fail > 0 ? `>>> hud-launch: ${fail} FAILED` : ">>> hud-launch: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
