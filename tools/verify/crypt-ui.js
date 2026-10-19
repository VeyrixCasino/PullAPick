// THE CANDY CRYPT'S SCREENS, AND THE TWO EVENT THEMES (owner, 2026-10-19;
// wiki/open-questions.md §0e). The client half of the Crypt redesign; the
// server half is tools/verify/crypt.js.
//
// Two halves, like crypt.js. The STATIC half reads the wiring (comments
// stripped). The LUAU half runs the real pure modules -- MineTheme,
// MineEventTabs, MineCryptView.openState, MineEventNotice.shouldShow --
// against the real MineConfig and MineCryptRules on a small Roblox stub, then
// MOUNTS the Events tab, the pop-up and the pouch on a GUI stand-in and
// presses their buttons.
//
//   1  every crypt* verb the client screens own (read off MineCrypt's VERBS)
//      and buyTrickOrTreat is sent by some UI, with the payload the verb reads;
//      every push the Crypt fires is handled. The crypt* actions are routed
//      by prefix, so orphan-verbs.js cannot see them: this is the check that can.
//   2  the Events tab shows the Crypt while Event Horizon is open too, and
//      opens on the event you stand in, else the Crypt
//   3  the Crypt's card reads crypt.owned / hallowOwned (never bigbangOwned)
//      and its claim button never says "Event Horizon"; "Owned — enter from
//      Planets"; the (i) is the event's own notice
//   4  the pouch's SELL UP TO and candy sale are wired end to end, the pouch
//      can be opened at all, and a locked candy ore is never sent
//   5  the first-entry pop-up shows once and sends cryptNoticeSeen
//   6  the two palettes carry every lifted role, read, and resolve event items
//   7  the Crypt card's price is the snapshot's; the wallet shows candy in the
//      Crypt only; the Crypt's screens never say "Event Horizon"
//
// SCOPE (owner, 2026-10-19, later the same day): the Crypt's TOOLS and CHARMS
// API and the Trick-or-Treat LOOT are being redone, so their screens are not
// built: cryptEquip, cryptMerge and cryptCraftCharm need no UI here (DESCOPED
// below), cryptMerged needs no handler, and the case's odds sheet and result
// reveal are a named placeholder (MineCryptView.mountCaseOdds).
//
// Run against another checkout to prove it bites:
//   node tools/verify/crypt-ui.js --root <path to a checkout>
//
//   node tools/verify/crypt-ui.js
"use strict";
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const argRoot = (() => {
  const i = process.argv.indexOf("--root");
  return i > 0 && process.argv[i + 1] ? path.resolve(process.argv[i + 1]) : null;
})();
const ROOT = argRoot || path.resolve(__dirname, "../..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const exists = (p) => fs.existsSync(path.join(ROOT, p));
const raw = (p) => (exists(p) ? Luau.readSrc(path.join(ROOT, p)) : "");
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
const read = (p) => code(raw(p));

let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};
// The body of `function <head>(...)` up to its closing `end` at the same indent.
const fnBody = (src, head) => {
  const i = src.indexOf(head);
  if (i < 0) return "";
  const lineStart = src.lastIndexOf("\n", i) + 1;
  const indent = src.slice(lineStart, i).match(/^\s*/)[0];
  const end = src.indexOf("\n" + indent + "end", i);
  return src.slice(i, end < 0 ? undefined : end + indent.length + 4);
};

console.log("crypt-ui: the Candy Crypt's screens, the Events tab and the event themes"
  + (argRoot ? `   (root ${argRoot})` : ""));

const CLIENT = read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");
const CRYPT_SV = read("src/ServerScriptService/Mine/MineCrypt.luau");
const EVENTS = read(SH + "MineEventsView/init.luau");
const CVIEW = read(SH + "MineCryptView.luau");
const NOTICE = read(SH + "MineEventNotice.luau");
const TABS = read(SH + "MineEventTabs.luau");
const POUCH = read(SH + "MineOrePouchView.luau");
const SHOP = read(SH + "MineShopView.luau");
const HUB = read(SH + "MineForgeHub.luau");
const THEME = read(SH + "MineTheme.luau");
const KIT = read(SH + "MineUI.luau");

for (const f of ["MineCryptView.luau", "MineEventNotice.luau", "MineEventTabs.luau"]) {
  check(exists(SH + f), `${f} exists`);
}

// The client's own code: everything a player's machine runs.
const clientFiles = [];
(function walk(d) {
  const abs = path.join(ROOT, d);
  if (!fs.existsSync(abs)) return;
  for (const e of fs.readdirSync(abs, { withFileTypes: true })) {
    const rel = path.join(d, e.name);
    if (e.isDirectory()) {
      if (!/ServerScriptService|ServerStorage/.test(rel)) walk(rel);
    } else if (e.name.endsWith(".luau")) {
      clientFiles.push(rel);
    }
  }
})("src");
const ALL_CLIENT = clientFiles.map((f) => read(f)).join("\n");
const sends = (verb) => new RegExp(`FireServer\\(\\s*"${verb}"`).test(ALL_CLIENT);

// ------------------------------------------------------------- 1. the verbs --
console.log("\n 1. every Crypt verb the screens own is sent by some UI; every push is handled");
// The tools, merge and charm-crafting screens wait for the Crypt's next API
// (owner, 2026-10-19): these verbs may be removed, so no UI is required for them.
const DESCOPED_VERBS = new Set(["cryptEquip", "cryptMerge", "cryptCraftCharm"]);
const DESCOPED_PUSHES = new Set(["cryptMerged"]);
const verbs = [...new Set([...CRYPT_SV.matchAll(/function VERBS\.(crypt[A-Za-z]+)\s*\(/g)].map((m) => m[1]))];
check(verbs.length >= 2, "the Crypt's verbs were read off MineCrypt.VERBS", verbs.join(", "));
const owned = verbs.filter((v) => !DESCOPED_VERBS.has(v));
check(owned.includes("cryptSellCandyOres") && owned.includes("cryptNoticeSeen"),
  "...including the two these screens own", owned.join(", "));
for (const v of [...owned, "buyTrickOrTreat"]) {
  check(sends(v), `${v} is sent by the client`);
}
check(/FireServer\("cryptSellCandyOres", \{ oreIds = oreIds, confirm = confirm and true or nil \}\)/.test(CLIENT),
  "the candy sale sends cryptSellCandyOres { oreIds, confirm }");
check(/FireServer\("cryptNoticeSeen", \{ zoneId = zoneId \}\)/.test(CLIENT), "\"Got it\" sends cryptNoticeSeen { zoneId }");
// Every hop between the button and the remote, so none is a dead end.
check(/MouseButton1Click:Connect\(function\(\)[\s\S]{0,320}opts\.onTrickOrTreat\(/.test(CVIEW)
  && /onTrickOrTreat = function\(\)\s*\n\s*if opts\.onTrickOrTreat then\s*\n\s*opts\.onTrickOrTreat\(/.test(EVENTS)
  && /onTrickOrTreat = function\(\)\s*\n\s*net:FireServer\("buyTrickOrTreat"\)/.test(CLIENT),
  "Trick-or-Treat's OPEN reaches the remote: MineCryptView -> MineEventsView -> MineClient buyTrickOrTreat");
const pushes = [...new Set([...CRYPT_SV.matchAll(/fire\(plr, "([A-Za-z]+)"/g)].map((m) => m[1]))]
  .filter((p) => !DESCOPED_PUSHES.has(p));
check(pushes.length >= 5, "the Crypt's pushes were read off MineCrypt", pushes.join(", "));
for (const p of pushes) {
  check(new RegExp(`action == "${p}"`).test(CLIENT), `the client handles the ${p} push`);
}
check(/action == "eventNotice"[\s\S]{0,200}ClientFns\.eventNotice\.show/.test(CLIENT), "...eventNotice opens the pop-up");
check(/action == "cryptSellCandyConfirm"[\s\S]{0,240}shopCtl\.showCandyConfirm/.test(CLIENT)
  && /function view\.showCandyConfirm\(info\)[\s\S]{0,120}pouchCtl\.showCandyConfirm/.test(SHOP),
  "...cryptSellCandyConfirm reaches the pouch's dialog");
check(/action == "trickOrTreatOpened"[\s\S]{0,400}eventsCtl\.onCaseOpened/.test(CLIENT)
  && /function view\.onCaseOpened\(payload\)[\s\S]{0,200}cryptCtl\.onCaseOpened/.test(EVENTS)
  && /function ctl\.onCaseOpened\(\)\s*\n\s*busyUntil = 0/.test(CVIEW),
  "...trickOrTreatOpened lets OPEN be pressed again (the result reveal waits for the new loot API)");

// --------------------------------------------------------- 2/3. the tab --
console.log("\n 2-3. the Events tab: both events, each its own claim");
check(/Tabs\.shown\(C, state\)/.test(EVENTS) && /Tabs\.defaultId\(list, state\)/.test(EVENTS)
  && /Tabs\.claim\(ev, state, row\.open\)/.test(EVENTS),
  "MineEventsView draws what MineEventTabs decides (which events, which first, each claim)");
check(!/bigbangOwned/.test(EVENTS) && !/bigbangOwned/.test(TABS) && !/bigbangOwned/.test(CVIEW),
  "no Events or Crypt screen reads bigbangOwned directly (each event's own flag, through MineEventTabs)");
check(!/Claim Event Horizon/.test(EVENTS + TABS + CVIEW) && !/enter from Zones/.test(EVENTS + TABS),
  "no fixed \"Claim Event Horizon\" and no \"enter from Zones\" left: the claim text is the event's own");
check(/M\.CLAIMED_TEXT = "Owned — enter from Planets"/.test(TABS), "owned reads \"Owned — enter from Planets\"");
check(/opts\.onClaim\(c\.zoneId\)/.test(EVENTS) && /onClaim = function\(zoneId\)\s*\n\s*net:FireServer\("buyZone", zoneId\)/.test(CLIENT),
  "a card's claim sends buyZone with ITS zone");
check(/eventsCtl = \(function\(\)[\s\S]{0,1600}local okE, ctl = pcall\(function\(\)\s*\n\s*return require\(shared:WaitForChild\("MineEventsView"\)\)\.mount\(gui, opts\)/.test(CLIENT),
  "the Events tab mounts through pcall: a screen that throws costs its tab, never the whole client");
check(/Tabs\.notice\(c\.ev, rules\(\)\)/.test(EVENTS), "each card's (i) shows its event's notice (MineEventTabs.notice)");

// ------------------------------------------------------------- 4. the pouch --
console.log("\n 4. the pouch: SELL UP TO and candy for candy");
check(/local order = Pouch\.SELL_UP_TO\b/.test(POUCH) && /Pouch\.SELL_UP_TO_LABEL\[upTo\]/.test(POUCH),
  "the picker is MineOrePouch.SELL_UP_TO, captioned by SELL_UP_TO_LABEL");
check(/opts\.onSellAll\(false, upToNow\(snap\(\)\)\)/.test(POUCH) && /opts\.onSellAll\(true, info\.upTo or upToNow\(nil\)\)/.test(POUCH),
  "SELL ALL asks with the ceiling, and confirms with the ceiling the server priced");
check(/local u = ui\.upTo or \(s and s\.sellUpTo\) or "Everything"/.test(POUCH),
  "the remembered ceiling (snapshot sellUpTo) is the default; a pick made on screen wins until sent");
check(/onSellAll = function\(confirm, upTo\)\s*\n\s*if opts\.onSellAllOres then\s*\n\s*opts\.onSellAllOres\(confirm, upTo\)/.test(SHOP)
  && /FireServer\("sellAllOres", \{ confirm = confirm and true or nil, upTo = upTo \}\)/.test(CLIENT),
  "...and the shop and the client pass it to sellAllOres { upTo }");
check(/sellUpTo = state\.sellUpTo/.test(SHOP) && /snapshot\.settings\.oreSellUpTo/.test(SHOP),
  "the shop hands the pouch the server's remembered setting (settings.oreSellUpTo)");
check(/Pouch\.sellAllPlan\(ores, locks, upTo\)/.test(POUCH), "the SELL ALL preview uses the ceiling (MineOrePouch.sellAllPlan)");
check(/Pouch\.rows\(ores, locks, \{ includeCandy = true/.test(POUCH) && /if r\.candy then/.test(POUCH),
  "candy ores are shown, from MineOrePouch.rows(..., { includeCandy = true })");
check(/if ui\.ticked\[r\.id\] and not r\.locked and r\.n > 0 then/.test(POUCH)
  && /if row\.locked then\s*\n\s*return/.test(POUCH) && /if r\.locked then[\s\S]{0,120}ui\.ticked\[r\.id\] = nil/.test(POUCH),
  "a LOCKED candy ore cannot be ticked and is never sent, so never sold");
check(/opts\.onSellCandy\(ids, false\)/.test(POUCH) && /opts\.onSellCandy\(c\.ids, true\)/.test(POUCH)
  && /function ctl\.showCandyConfirm\(info\)/.test(POUCH),
  "SELL TICKED asks, the server's figures show, and YES resends the same ores with confirm");
check(/onSellCandy = function\(oreIds, confirm\)\s*\n\s*if opts\.onSellCandyOres then\s*\n\s*opts\.onSellCandyOres\(oreIds, confirm\)/.test(SHOP),
  "...the shop forwards the candy sale");
{
  // The shop hands the pouch a hand-built subset: a field the pouch reads and
  // the shop leaves out is nil with no error (forge-snap.js, for the pouch).
  const render = fnBody(POUCH, "function render()");
  const reads = new Set([...render.matchAll(/\bs\.([A-Za-z_]\w*)/g)].map((m) => m[1]));
  const anchor = SHOP.indexOf("pcall(PouchView.mount");
  const gs = anchor < 0 ? -1 : SHOP.indexOf("getSnap = function()", anchor);
  const gsBody = gs < 0 ? "" : SHOP.slice(SHOP.indexOf("\n", gs), SHOP.indexOf("\n\t\t\tend,", gs));
  const passed = new Set([...gsBody.matchAll(/^\s*([A-Za-z_]\w*)\s*=/gm)].map((m) => m[1]));
  const missing = [...reads].filter((k) => !passed.has(k));
  check(reads.size >= 5 && missing.length === 0, `every field the pouch reads is passed to it (${reads.size} read)`,
    missing.length ? "missing: " + missing.join(", ") : "");
}
check(/and id ~= "pouch" then/.test(SHOP) && /if tab == "pouch" and shopCtl\.setTab then\s*\n\s*shopCtl\.setTab\("pouch"\)/.test(CLIENT)
  && /opts\.onShop\("pouch"\)/.test(HUB),
  "the pouch can be opened: the Forge hub's SELL ORE reaches it through routePanel(\"shop\", \"pouch\")");

// ------------------------------------------------------------ 5. the pop-up --
console.log("\n 5. the first-entry pop-up: once, and it sends cryptNoticeSeen");
const show = fnBody(NOTICE, "function ctl.show(payload)");
check(/if zid == "" or ctl\.shown\[zid\] then\s*\n\s*return false/.test(show)
  && show.indexOf("ctl.shown[zid] = true") > 0 && show.indexOf("ctl.shown[zid] = true") < show.indexOf("veil.Visible = true"),
  "show() is once a session per event, recorded before it shows");
check(/got\.MouseButton1Click:Connect\(function\(\)[\s\S]{0,200}opts\.onSeen\(zid\)/.test(NOTICE)
  && !/veil\.MouseButton1Click/.test(NOTICE),
  "only \"Got it\" closes it, and it reports the zone (a stray tap cannot dismiss it unread)");
check(/ClientFns\.eventNotice\.onSnapshot/.test(CLIENT) && /N\.shouldShow\(snap, zid, ctl\.shown\)/.test(NOTICE),
  "the snapshot fallback asks shouldShow with the same session record");

// ------------------------------------------------------------ 6/7. the look --
console.log("\n 6-7. the themes, the kit helper, and what the Crypt says");
check(/MineTheme\.EVENT_THEMES = \{/.test(THEME) && /function MineTheme\.eventTheme\(key\)/.test(THEME)
  && /function MineTheme\.eventKeyOf\(x\)/.test(THEME), "MineTheme has the two event palettes and the helpers");
check(/function MineUI\.eventMark\(inst, key, opts\)/.test(KIT) && /function MineUI\.applyTheme\(root, theme\)/.test(KIT)
  && /function MineUI\.themeButton\(/.test(KIT), "MineUI builds with them (themeButton, applyTheme, eventMark)");
check(/ClientFns\.UI\.eventMark, f, eventKey/.test(fnBody(CLIENT, "\npaintCard = function(parent, card, w)"))
  && /local eventKey = T\.eventKeyOf\(\{ cardKey = card\.cardKey, setId = card\.setId \}\)/.test(CLIENT),
  "an event pet's card wears its event's mark (paintCard, by MineTheme.eventKeyOf)");
for (const [name, src] of [["MineCryptView", CVIEW], ["MineEventsView", EVENTS], ["MineEventNotice", NOTICE]]) {
  check(src.length > 0 && !/UI\.pop\(/.test(src) && !/"UIScale"/.test(src),
    `${name} puts no text on a scale animation (no pop, no UIScale)`);
}
check(/function ClientFns\.paintCandyPill\(\)[\s\S]{0,300}local on = snap\.zoneId == "hallow"/.test(CLIENT)
  && /local function refreshHud\(\)\s*\n\s*if not snap then\s*\n\s*return\s*\n\s*end\s*\n\s*pcall\(ClientFns\.paintCandyPill\)/.test(CLIENT),
  "the wallet shows candy while you stand in the Crypt, and only there");
check(/if \(tonumber\(payload\.candy\) or 0\) > 0 then[\s\S]{0,400}"\+" \.\. ClientFns\.commas\(payload\.candy\) \.\. " candy"/.test(CLIENT),
  "a Crypt chest's popup shows the candy it paid (chestOpened kind \"crypt\")");
check(!/Event Horizon/.test(CVIEW + NOTICE), "nothing on the Crypt's card or pop-up says \"Event Horizon\"");
check(!/\b2500\b|\b2,500\b/.test(CVIEW) && /cr\.casePrice/.test(CVIEW),
  "the case's price comes from the snapshot (crypt.casePrice), not typed in");
check(/function CryptView\.mountCaseOdds\(/.test(CVIEW) && /Name = "OddsSlot"/.test(CVIEW)
  && /CryptView\.mountCaseOdds\(oddsSlot, opts\)/.test(CVIEW),
  "the odds sheet's place is kept and named (MineCryptView.mountCaseOdds, the hidden \"OddsSlot\")");

// --------------------------------------------------------- the luau half --
if (!Luau.ready) {
  console.log("  " + Luau.missing("luau") + "; skipping the luau half");
  console.log(fail === 0 ? ">>> crypt-ui OK (static only)" : `>>> crypt-ui: ${fail} FAILED`);
  process.exit(fail === 0 ? 0 : 1);
}

const MODULES = ["MineConfig", "MineDepth", "MineBags", "MineBagNames", "MineShopEconomy", "MineLaunch", "MineTools",
  "MineOreTools", "MineBreaking", "MineStats", "MineTemper", "MineCharms", "MineOrePouch", "MineCandyTools",
  "MineTrickOrTreat", "MineCryptRules", "MineTheme", "MineUI", "MineAbbrev", "MineEventTabs", "MineCryptView",
  "MineEventNotice", "MineOrePouchView", "MineEventsView/init"];
const factories = MODULES.map((file) => {
  const name = file.replace(/\/init$/, "");
  const src = raw(SH + file + ".luau");
  if (!src) return `FACTORY[${JSON.stringify(name)}] = nil\n`;
  return `FACTORY[${JSON.stringify(name)}] = function()\n\tlocal script = { Name = ${JSON.stringify(name)}, Parent = SHARED }\n`
    + src + "\nend\n";
}).join("\n");

const prelude = `
Vector3 = { new = function(x, y, z) return { X = x or 0, Y = y or 0, Z = z or 0 } end }
Vector2 = { new = function(x, y) return { X = x or 0, Y = y or 0 } end }
local function c3(r, g, b) return { R = r or 0, G = g or 0, B = b or 0, Lerp = function(self) return self end } end
Color3 = {
	fromRGB = function(r, g, b) return c3((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end,
	new = function(r, g, b) return c3(r, g, b) end,
	fromHSV = function(h, s, v) return c3(v, v, v) end,
	fromHex = function() return c3(1, 1, 1) end,
}
local any = setmetatable({}, { __index = function() return function() return {} end end })
CFrame = any
NumberRange = any
NumberSequence = any
NumberSequenceKeypoint = any
ColorSequence = any
ColorSequenceKeypoint = any
TweenInfo = any
UDim = { new = function(s, o) return { Scale = s or 0, Offset = o or 0 } end }
UDim2 = {
	new = function(xs, xo, ys, yo) return { X = UDim.new(xs, xo), Y = UDim.new(ys, yo) } end,
	fromOffset = function(x, y) return { X = UDim.new(0, x), Y = UDim.new(0, y) } end,
	fromScale = function(x, y) return { X = UDim.new(x, 0), Y = UDim.new(y, 0) } end,
}

-- ------------------------------------------------- a GUI object stand-in --
-- Enough of Roblox's instance model to MOUNT the new screens and press their
-- buttons: properties with defaults, children, attributes, and signals.
local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({ fns = {} }, Signal) end
function Signal:Connect(fn)
	table.insert(self.fns, fn)
	local sig = self
	return { Disconnect = function()
		for i, f in ipairs(sig.fns) do
			if f == fn then table.remove(sig.fns, i) break end
		end
	end }
end
function Signal:Fire(...)
	for _, fn in ipairs(table.clone(self.fns)) do fn(...) end
end
local ISA = {
	Frame = { GuiObject = true }, TextLabel = { GuiObject = true }, ImageLabel = { GuiObject = true },
	TextButton = { GuiObject = true, GuiButton = true }, ImageButton = { GuiObject = true, GuiButton = true },
	ScrollingFrame = { GuiObject = true }, TextBox = { GuiObject = true }, ViewportFrame = { GuiObject = true },
	UIListLayout = { UIGridStyleLayout = true, UILayout = true }, UIGridLayout = { UIGridStyleLayout = true, UILayout = true },
	NumberValue = { ValueBase = true }, ScreenGui = { LayerCollector = true },
}
local DEFAULTS = {
	Visible = true, ZIndex = 1, BackgroundTransparency = 0, Text = "", TextSize = 14, LayoutOrder = 0,
	Rotation = 0, TextTransparency = 0, ImageTransparency = 0, Image = "", Thickness = 1, Transparency = 0,
	Scale = 1, Value = 0, Enabled = true, DisplayOrder = 0, BorderSizePixel = 1, TextWrapped = false,
	TextScaled = false, ClipsDescendants = false, AutoButtonColor = true,
}
local SIGNALS = { MouseButton1Click = true, MouseButton1Down = true, MouseButton1Up = true, MouseEnter = true,
	MouseLeave = true, Activated = true, Changed = true, DescendantAdded = true }
local Inst = {}
local function isa(self, c)
	local k = rawget(self, "_c")
	return c == "Instance" or c == k or (ISA[k] ~= nil and ISA[k][c] == true)
end
local methods = {
	IsA = isa,
	GetChildren = function(self) return table.clone(rawget(self, "_kids")) end,
	GetDescendants = function(self)
		local out = {}
		local function walk(n)
			for _, ch in ipairs(rawget(n, "_kids")) do
				table.insert(out, ch)
				walk(ch)
			end
		end
		walk(self)
		return out
	end,
	FindFirstChild = function(self, name)
		for _, ch in ipairs(rawget(self, "_kids")) do
			if rawget(ch, "_p").Name == name then return ch end
		end
		return nil
	end,
	FindFirstChildOfClass = function(self, c)
		for _, ch in ipairs(rawget(self, "_kids")) do
			if rawget(ch, "_c") == c then return ch end
		end
		return nil
	end,
	FindFirstChildWhichIsA = function(self, c)
		for _, ch in ipairs(rawget(self, "_kids")) do
			if isa(ch, c) then return ch end
		end
		return nil
	end,
	SetAttribute = function(self, k, v) rawget(self, "_a")[k] = v end,
	GetAttribute = function(self, k) return rawget(self, "_a")[k] end,
	GetPropertyChangedSignal = function(self, prop)
		local s = rawget(self, "_ps")
		s[prop] = s[prop] or Signal.new()
		return s[prop]
	end,
	Destroy = function(self) self.Parent = nil end,
	ClearAllChildren = function(self)
		for _, ch in ipairs(table.clone(rawget(self, "_kids"))) do ch.Parent = nil end
	end,
}
local META = {}
META.__index = function(self, k)
	if methods[k] then return methods[k] end
	if SIGNALS[k] then
		local s = rawget(self, "_ps")
		s["@" .. k] = s["@" .. k] or Signal.new()
		return s["@" .. k]
	end
	local p = rawget(self, "_p")
	if k == "ClassName" then return rawget(self, "_c") end
	if p[k] ~= nil then return p[k] end
	if k == "AbsoluteSize" then return Vector2.new(400, 300) end
	if k == "Active" then return isa(self, "GuiButton") end
	return DEFAULTS[k]
end
META.__newindex = function(self, k, v)
	local p = rawget(self, "_p")
	if k == "Parent" then
		local old = p.Parent
		if old then
			local kids = rawget(old, "_kids")
			for i, ch in ipairs(kids) do
				if ch == self then table.remove(kids, i) break end
			end
		end
		p.Parent = v
		if v then table.insert(rawget(v, "_kids"), self) end
		return
	end
	local was = p[k]
	p[k] = v
	if was ~= v then
		local s = rawget(self, "_ps")
		if s[k] then s[k]:Fire() end
		if s["@Changed"] then s["@Changed"]:Fire(k) end
	end
end
Instance = { new = function(class, parent)
	local o = setmetatable({ _c = class, _p = { Name = class }, _kids = {}, _a = {}, _ps = {} }, META)
	if parent then o.Parent = parent end
	return o
end }
local function descendants(root) return root:GetDescendants() end
local function textOf(inst)
	local t = rawget(inst, "_p").Text
	return type(t) == "string" and t or ""
end
-- The button whose own text, or its own caption label (a direct child, the
-- way MineUI.button builds one), says exactly \`text\`.
local function buttonSaying(root, text)
	for _, d in ipairs(descendants(root)) do
		if d:IsA("GuiButton") then
			if textOf(d) == text then return d end
			for _, l in ipairs(d:GetChildren()) do
				if l:IsA("TextLabel") and textOf(l) == text then return d end
			end
		end
	end
	return nil
end
local function labelSaying(root, text)
	for _, d in ipairs(descendants(root)) do
		if textOf(d) == text then return d end
	end
	return nil
end
local function click(btn)
	if btn then btn.MouseButton1Click:Fire() end
end
local TweenService = { Create = function(_, inst, _, props)
	return { Play = function() for k, v in pairs(props) do inst[k] = v end end, Cancel = function() end, Completed = Signal.new() }
end }
local RunServiceMock = { IsStudio = function() return false end, IsServer = function() return false end,
	IsClient = function() return true end, Heartbeat = Signal.new(), RenderStepped = Signal.new() }

local enumCache = {}
Enum = setmetatable({}, { __index = function(_, k)
	local t = enumCache[k]
	if not t then
		t = setmetatable({}, { __index = function(_, k2) return { Name = k2, EnumType = k } end })
		enumCache[k] = t
	end
	return t
end })
Random = {}
Random.__index = Random
function Random.new(seed) return setmetatable({ s = ((seed or 4242) % 2147483646) + 1 }, Random) end
function Random:NextNumber(a, b)
	self.s = (self.s * 48271) % 2147483647
	local u = self.s / 2147483647
	if a and b then return a + (b - a) * u end
	return u
end
function Random:NextInteger(a, b) return a + math.floor(self:NextNumber() * (b - a + 1)) end
warn = function() end
task = { wait = function() end, spawn = function() end, delay = function() end, defer = function() end }
typeof = typeof or function(v) return type(v) end
local FACTORY, LOADED = {}, {}
local function inst(name)
	return { Name = name, WaitForChild = function(_, n) return inst(n) end, FindFirstChild = function(_, n)
		if FACTORY[n] then return inst(n) end
		return nil
	end, Clone = function(self) return inst(self.Name) end, Destroy = function() end }
end
SHARED = inst("Shared")
local MINE = { Name = "Mine", WaitForChild = function() return SHARED end, FindFirstChild = function() return SHARED end }
local RS = { Name = "ReplicatedStorage", WaitForChild = function() return MINE end, FindFirstChild = function() return MINE end }
local SERVICES = {
	ReplicatedStorage = RS,
	RunService = RunServiceMock,
	TweenService = TweenService,
}
game = { GetService = function(_, n) return SERVICES[n] or any end }
workspace = { FindFirstChild = function() return nil end, GetServerTimeNow = function() return os.time() end }
function require(t)
	local n = type(t) == "table" and t.Name or tostring(t)
	if LOADED[n] ~= nil then return LOADED[n] end
	local f = FACTORY[n]
	if not f then error("no module " .. tostring(n)) end
	local m = f()
	LOADED[n] = m
	return m
end
FACTORY.MinePackConfig = function()
	return { PACK_BY_ID = { halloween_2026 = { id = "halloween_2026", name = "Halloween 2026 Pack", setKey = "halloween_2026" } } }
end
FACTORY.MineGear = function() return {} end
FACTORY.MineIcons = function() return {} end
FACTORY.MineLuckyOddsView = function() return {} end
FACTORY.MineOreIcons = function() return { icon = function() return "" end } end
`;

const body = `
local fails = 0
local function check(cond, name, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. tostring(detail)) or ""))
	if not cond then fails += 1 end
end
local function try(name, fn)
	local ok, err = pcall(fn)
	if not ok then check(false, name .. " (threw)", err) end
end

print("")
print(" luau: the pure modules, run")

try("MineEventTabs", function()
	local C = require("MineConfig")
	local Tabs = require("MineEventTabs")
	local R = require("MineCryptRules")
	local crypt, horizon
	for _, ev in ipairs(C.EVENTS) do
		if ev.zoneId == "hallow" then crypt = ev end
		if ev.zoneId == "bigbang" then horizon = ev end
	end
	check(crypt ~= nil and horizon ~= nil, "MineConfig.EVENTS lists both events")
	local both = { zoneId = "meadow", limitedOpen = { bigbang = true, hallow = true },
		bigbangOwned = true, crypt = { owned = false, window = { open = true, ended = false } } }
	local list = Tabs.shown(C, both)
	local ids = {}
	for _, row in ipairs(list) do ids[row.ev.zoneId] = true end
	check(ids.hallow and ids.bigbang, "the Crypt shows while Event Horizon is open too", #list .. " shown")
	check(Tabs.defaultId(list, both) == crypt.id, "standing elsewhere, the tab opens on the Crypt")
	local inEh = table.clone(both)
	inEh.zoneId = "bigbang"
	check(Tabs.defaultId(list, inEh) == horizon.id, "standing in Event Horizon, it opens on Event Horizon")
	local text, claims = Tabs.claim(crypt, both, true)
	check(claims and text:find("Candy Crypt", 1, true) and not text:find("Horizon", 1, true),
		"the Crypt's claim is its own while Event Horizon is owned", text)
	check(Tabs.owned(crypt, { bigbangOwned = true }) == false, "bigbangOwned never claims the Crypt")
	check(Tabs.owned(crypt, { hallowOwned = true }) == true and Tabs.owned(crypt, { crypt = { owned = true } }) == true,
		"the Crypt reads crypt.owned, else hallowOwned")
	local owned = Tabs.claim(crypt, { crypt = { owned = true } }, true)
	check(owned == "Owned — enter from Planets", "owned: \\"Owned — enter from Planets\\"", owned)
	local ehText, ehClaims = Tabs.claim(horizon, { bigbangOwned = false }, true)
	check(ehClaims and ehText:find("Event Horizon", 1, true), "Event Horizon's claim is its own", ehText)
	check(Tabs.claim(horizon, { bigbangOwned = true, hallowOwned = false }, true) == "Owned — enter from Planets",
		"...and reads bigbangOwned")
	local onlyEh = { limitedOpen = { bigbang = true, hallow = false }, crypt = { owned = false, window = { open = false, ended = false } } }
	check(#Tabs.shown(C, onlyEh) == 1, "before the Crypt opens, only Event Horizon shows")
	-- After the Crypt ends its card would carry the tools' main-world switch;
	-- that waits for the Crypt's new tools API (scope, 2026-10-19), so for
	-- now a closed event is simply not shown.
	local after = { limitedOpen = { bigbang = true, hallow = false }, crypt = { owned = true, window = { open = false, ended = true } } }
	local afterIds = {}
	for _, row in ipairs(Tabs.shown(C, after)) do afterIds[row.ev.zoneId] = true end
	check(afterIds.bigbang and not afterIds.hallow, "once the Crypt has closed, only the open event shows")
	check(Tabs.notice(crypt, R).text == R.NOTICE.text, "the Crypt's (i) is its first-entry notice")
	check(Tabs.notice(horizon, R).text ~= R.NOTICE.text, "Event Horizon's (i) is not the Crypt's notice (its tools do not leave)")
	local line = Tabs.cryptWindowLine({ crypt = { window = { opensAt = 100, closesAt = 100 + 3 * 86400 + 3600, open = true } } }, 100)
	check(line == "Closes in 3d 1h", "the window line counts to the close", line)
end)

try("MineEventNotice.shouldShow", function()
	local N = require("MineEventNotice")
	local snap = { zoneId = "hallow", crypt = { zoneId = "hallow", noticeSeen = {} } }
	check(N.shouldShow(snap, "hallow", {}) == true, "the pop-up shows in the Crypt while unseen")
	check(N.shouldShow({ zoneId = "hallow", crypt = { zoneId = "hallow", noticeSeen = { hallow = true } } }, "hallow", {}) == false,
		"...never once the server marks it seen")
	check(N.shouldShow(snap, "hallow", { hallow = true }) == false, "...and never twice in a session")
	check(N.shouldShow(snap, "bigbang", {}) == false and N.shouldShow(snap, "meadow", {}) == false,
		"...and only for an event that has one")
end)

try("MineTheme", function()
	local T = require("MineTheme")
	local roles = { "SHELL", "SHELL_HI", "FACE", "FACE_DIM", "ON_FACE", "ON_FACE_MUTED", "ACCENT", "EDGE",
		"INK", "TEXT", "MUTED", "GLOW", "OUTLINE" }
	local function lum(c)
		local function ch(x) return (x <= 0.03928) and (x / 12.92) or (((x + 0.055) / 1.055) ^ 2.4) end
		return 0.2126 * ch(c.R) + 0.7152 * ch(c.G) + 0.0722 * ch(c.B)
	end
	local function contrast(a, b)
		local la, lb = lum(a), lum(b)
		return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
	end
	for _, name in ipairs({ "halloween", "universe" }) do
		local th = T.EVENT_THEMES[name]
		local missing = {}
		for _, r in ipairs(roles) do
			if not (th and th[r] and th[r].R) then table.insert(missing, r) end
		end
		check(#missing == 0 and th.CANDY.primary and th.CANDY.secondary and th.CANDY.go and th.CANDY.danger,
			name .. " carries every lifted role and the button jobs", table.concat(missing, ","))
		local a, b = contrast(th.TEXT, th.SHELL), contrast(th.ON_FACE, th.FACE)
		check(a >= 7 and b >= 7, name .. ": type reads on its shell and its face (contrast >= 7:1)",
			string.format("%.1f, %.1f", a, b))
	end
	check(T.eventTheme("hallow").NAME == "halloween" and T.eventTheme("candy_crypt").NAME == "halloween"
		and T.eventTheme("bigbang").NAME == "universe" and T.eventTheme("event_horizon").NAME == "universe"
		and T.eventTheme("meadow") == nil and T.themeFor("meadow") == T.LIFTED,
		"eventTheme takes a zone or event id; the main world keeps the lifted look")
	local cases = {
		{ { cardKey = "bigbang:Cosmo" }, "universe" }, { { cardKey = "halloween_2026:Bat" }, "halloween" },
		{ { cardKey = "meadow:Breezy" }, nil }, { "candy_corn_pickaxe", "halloween" }, { "candy_jawbreaker_explosive", "halloween" },
		{ "candy_floss", nil }, { "bigbang_pack_rare", "universe" }, { "eh_shallow_pick", "universe" },
		{ { candy = true, id = "candy_corn" }, "halloween" }, { "hallow_kernel", "halloween" }, { { eventOnly = true }, "universe" },
		{ "halloween_2026", "halloween" }, { "meadow_pack_rare", nil }, { { setId = "genesis_spark" }, "universe" },
	}
	local wrong = {}
	for _, c in ipairs(cases) do
		if T.eventKeyOf(c[1]) ~= c[2] then
			table.insert(wrong, (type(c[1]) == "table" and (c[1].cardKey or c[1].id or c[1].setId or "?") or c[1]))
		end
	end
	check(#wrong == 0, "eventKeyOf names each event's items (pets, packs, tools, charms, candy ores) and nothing else",
		table.concat(wrong, ", "))
end)

try("MineCryptView.openState", function()
	local V = require("MineCryptView")
	local open = { open = true, ended = false }
	local text, job = V.openState({ owned = true, candy = 3000, casePrice = 2500, window = open })
	check(job == "primary" and text == "OPEN  \u{00B7}  2,500 🍬", "claimed, open, enough candy: OPEN at the snapshot's price", text)
	text, job = V.openState({ owned = true, candy = 100, casePrice = 2500, window = open })
	check(job == "off" and text == "NEED 2,400 MORE 🍬", "short of the price: greyed, saying how much more", text)
	text, job = V.openState({ owned = false, candy = 9999, casePrice = 2500, window = open })
	check(job == "off", "not claimed: greyed", text)
	text, job = V.openState({ owned = true, candy = 9999, casePrice = 2500, window = { open = false, ended = true } })
	check(job == "off" and text:find("CLOSED", 1, true) ~= nil, "closed: greyed", text)
	text, job = V.openState({ owned = true, candy = 9999, casePrice = 2500, window = { open = false, ended = false } })
	check(job == "off" and text:find("SOON", 1, true) ~= nil, "not open yet: greyed", text)
	check(V.openState(nil) ~= nil, "a snapshot without a crypt block does not throw")
	check(V.mountCaseOdds(nil, {}) == nil, "the odds sheet is a named placeholder that builds nothing yet")
end)

-- ------------------------------------------------- mounted, and pressed --
print("")
print(" luau: the screens mounted on a GUI stand-in, and their buttons pressed")

local C = require("MineConfig")
local R = require("MineCryptRules")
local opensAt = select(1, C.limitedWindow("hallow")) or os.time()
local NOW = opensAt + 86400
local profile = {
	hallowOwned = true, candy = 3000,
	cryptTools = { ["candy_corn_pickaxe|Normal"] = 4, ["candy_toffee_drill|Golden"] = 1 },
	cryptToolEquipped = "candy_toffee_drill|Golden",
	ores = { candy_corn = 30, gumdrop = 5, [C.ORES[1].id] = 40, [C.ORES[30].id] = 3 },
	oreLocks = { gumdrop = true },
	charms = {}, settings = { oreSellUpTo = "Rare" }, eventNoticeSeen = {},
}
local function snapFor(zoneId)
	return {
		zoneId = zoneId, limitedOpen = { bigbang = true, hallow = true }, bigbangOwned = false,
		hallowOwned = true, crypt = R.stateFor(profile, NOW), ores = profile.ores, oreLocks = profile.oreLocks,
		settings = profile.settings,
	}
end

try("the Events tab", function()
	local calls = {}
	local function log(name) return function(...) table.insert(calls, { name, ... }) end end
	local gui = Instance.new("ScreenGui")
	local EV = require("MineEventsView")
	local view = EV.mount(gui, {
		config = C, onClaim = log("claim"), onPlanets = log("planets"), onTrickOrTreat = log("tot"),
	})
	view.setState(snapFor("meadow"))
	view.open()
	local root = view.root
	check(root.Visible == true, "it opens")
	local cryptCard = view.cards.hallow and view.cards.hallow.card
	local ehCard = view.cards.bigbang and view.cards.bigbang.card
	check(cryptCard and cryptCard.Visible and not ehCard.Visible, "standing in the meadow it opens on the Crypt's card")
	check(buttonSaying(root, "🎃 Candy Crypt") ~= nil and buttonSaying(root, "🌌 Event Horizon") ~= nil,
		"both events have a pill")
	check(labelSaying(cryptCard, "Owned — enter from Planets") ~= nil, "the Crypt reads its own claim (owned) though Event Horizon is not")
	click(buttonSaying(cryptCard, "Owned — enter from Planets"))
	check(#calls > 0 and calls[#calls][1] == "planets", "...and that button opens Planets")
	click(buttonSaying(root, "🌌 Event Horizon"))
	check(ehCard.Visible and not cryptCard.Visible, "the Event Horizon pill switches cards")
	local ehClaim = buttonSaying(ehCard, "Claim Event Horizon  \u{00B7}  FREE")
	check(ehClaim ~= nil, "Event Horizon (not claimed) offers its own claim")
	click(ehClaim)
	check(calls[#calls][1] == "claim" and calls[#calls][2] == "bigbang", "...which claims bigbang", tostring(calls[#calls][2]))
	click(buttonSaying(root, "🎃 Candy Crypt"))
	check(labelSaying(cryptCard, "3,000") ~= nil, "the Crypt's card shows your candy (3,000)")
	local open = nil
	for _, d in ipairs(cryptCard:GetDescendants()) do
		if d.Name == "Open" and d:IsA("GuiButton") then open = d end
	end
	check(open ~= nil and buttonSaying(cryptCard, "OPEN  \u{00B7}  2,500 🍬") == open,
		"Trick-or-Treat's OPEN shows the snapshot's price")
	click(open)
	check(calls[#calls][1] == "tot", "OPEN buys a Trick-or-Treat case with 3,000 candy")
	local before = #calls
	click(open)
	check(#calls == before, "...a double tap buys one case, not two")
	view.onCaseOpened({ kind = "hat", name = "Hat" })
	click(open)
	check(#calls == before + 1 and calls[#calls][1] == "tot", "...and the server's answer lets OPEN be pressed again")
	local poor = snapFor("meadow")
	poor.crypt.candy = 100
	view.setState(poor)
	local short = nil
	for _, d in ipairs(cryptCard:GetDescendants()) do
		if d:IsA("TextLabel") and string.find(d.Text, "NEED 2,400 MORE", 1, true) then short = d.Parent end
	end
	check(short ~= nil and short.Active == false, "OPEN greys out, saying how much more, when you cannot afford it")
	local info = view.cards.hallow.info
	click(info)
	check(labelSaying(root, R.NOTICE.text) ~= nil, "the (i) shows the Crypt's notice")

	-- After the Crypt closes: only the open event shows (an after-event card
	-- waits for the Crypt's new tools API, scope 2026-10-19).
	local _, closesAt = C.limitedWindow("hallow")
	local over = snapFor("meadow")
	over.limitedOpen = { bigbang = true, hallow = false }
	over.crypt = R.stateFor(profile, (closesAt or NOW) + 60)
	view.setState(over)
	view.open()
	check(ehCard.Visible and not cryptCard.Visible, "after the Crypt closes, the tab opens on the open event")
	check(buttonSaying(root, "🎃 Candy Crypt") == nil and buttonSaying(root, "🌌 Event Horizon") ~= nil,
		"...and only the open event has a pill")

	-- Event Horizon's pass, with a real-shaped payload.
	local withPass = snapFor("bigbang")
	withPass.eventPass = {
		name = "Event Horizon Pass", blurb = "b", xp = 50, tierIndex = 2,
		tier = { name = "Tier 2", tip = "tip", xp = 40 }, nextTier = { xp = 90 },
		quest = { text = "Reach layer 30", progress = 3, goal = 30, xp = 20 }, questTotal = 10,
		tiers = { { name = "T1", xp = 0, tip = "a" }, { name = "T2", xp = 40, tip = "b" }, { name = "T3", xp = 90, tip = "c" } },
	}
	view.setState(withPass)
	view.open()
	check(ehCard.Visible, "standing in Event Horizon, the tab opens on Event Horizon")
	click(buttonSaying(ehCard, "EVENT PASS"))
	check(labelSaying(root, "50 / 90 XP") ~= nil and labelSaying(root, "Reach layer 30") ~= nil, "the Event Pass opens on its tier and quest")
	view.close()
	check(root.Visible == false, "it closes")
end)

try("the first-entry pop-up", function()
	local seen = {}
	local gui = Instance.new("ScreenGui")
	local N = require("MineEventNotice")
	local ctl = N.mount(gui, { onSeen = function(z) table.insert(seen, z) end })
	local snap = snapFor("hallow")
	ctl.onSnapshot(snap)
	check(ctl.isOpen() and labelSaying(gui, R.NOTICE.text) ~= nil, "standing in the Crypt, unseen: it shows the notice")
	check(ctl.show({ zoneId = "hallow", title = "x", text = "y" }) == false, "...the server's push cannot stack a second")
	click(buttonSaying(gui, "Got it"))
	check(not ctl.isOpen() and seen[1] == "hallow" and #seen == 1, "\\"Got it\\" closes it and reports hallow once")
	ctl.onSnapshot(snap)
	check(not ctl.isOpen(), "it does not come back this session")
end)

try("the ore pouch", function()
	local calls = {}
	local gui = Instance.new("Frame")
	local PV = require("MineOrePouchView")
	local Pouch = require("MineOrePouch")
	local state = { ores = profile.ores, oreLocks = profile.oreLocks, orePouch = { cap = 2000, held = 78, name = "Canvas Pouch" },
		orePouchTier = 1, gems = 0, sellUpTo = "Rare" }
	local ctl = PV.mount(gui, {
		getSnap = function() return state end,
		onSellAll = function(confirm, upTo) table.insert(calls, { "sellAll", confirm, upTo }) end,
		onSellCandy = function(ids, confirm) table.insert(calls, { "candy", ids, confirm }) end,
		onToggleLock = function(id) table.insert(calls, { "lock", id }) end,
	})
	ctl.refresh()
	local chip = nil
	for _, d in ipairs(gui:GetDescendants()) do
		if d.Name == "SellUpTo" then chip = d end
	end
	local function chipSays()
		for _, l in ipairs(chip and chip:GetChildren() or {}) do
			if l:IsA("TextLabel") and string.find(l.Text, "▶", 1, true) then return l.Text end
		end
		return ""
	end
	check(chipSays() == "+RARE  ▶", "SELL UP TO opens on the remembered ceiling (Rare)", chipSays())
	click(buttonSaying(gui, "SELL ALL"))
	check(calls[#calls][1] == "sellAll" and calls[#calls][2] == false and calls[#calls][3] == "Rare",
		"SELL ALL asks with the remembered ceiling (Rare)", tostring(calls[#calls][3]))
	local seen, order = {}, {}
	for _ = 1, #Pouch.SELL_UP_TO do
		click(chip)
		local t = chipSays()
		if not seen[t] then seen[t] = true table.insert(order, t) end
	end
	check(#order == 6 and chipSays() == "+RARE  ▶", "tapping it walks all six ceilings and comes back round",
		table.concat(order, ", "))
	click(chip)
	click(buttonSaying(gui, "SELL ALL"))
	check(calls[#calls][3] == "Epic", "a new pick is sent with the ask", tostring(calls[#calls][3]))
	ctl.showConfirm({ units = 43, gems = 120, rows = 2, upTo = "Epic", candyUnits = 35, locked = 1 })
	click(buttonSaying(gui, "SELL IT ALL"))
	check(calls[#calls][2] == true and calls[#calls][3] == "Epic", "YES confirms with the ceiling the server priced")
	check(labelSaying(gui, "Candy Corn") ~= nil and labelSaying(gui, "Gumdrop") ~= nil, "candy ores are in the pouch, in their own section")
	local function tickOf(name)
		local l = labelSaying(gui, name)
		return l and l.Parent:FindFirstChild("Tick")
	end
	click(tickOf("Gumdrop"))
	click(tickOf("Candy Corn"))
	local sell = nil
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("TextLabel") and string.find(d.Text, "SELL 1 TICKED", 1, true) then sell = d.Parent end
	end
	check(sell ~= nil, "the locked Gumdrop cannot be ticked: one ore ticked")
	click(sell)
	local ask = calls[#calls]
	check(ask[1] == "candy" and ask[3] == false and #ask[2] == 1 and ask[2][1] == "candy_corn",
		"SELL TICKED asks about Candy Corn only (never the locked one)")
	ctl.showCandyConfirm({ units = 30, candy = 45, rows = { { id = "candy_corn", name = "Candy Corn", n = 30, candy = 45 } }, lockedSkipped = 0 })
	check(labelSaying(gui, "SELL CANDY ORE FOR CANDY?") ~= nil, "the server's figures open the candy dialog")
	click(buttonSaying(gui, "SELL FOR CANDY"))
	local yes = calls[#calls]
	check(yes[1] == "candy" and yes[3] == true and yes[2][1] == "candy_corn", "YES sells the same ores, with confirm")
end)

print("RESULT " .. fails)
`;

const script = path.join(os.tmpdir(), `mfc-crypt-ui-${process.pid}.luau`);
fs.writeFileSync(script, prelude + "\n" + factories + "\n" + body);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [script], { encoding: "utf8", maxBuffer: 1 << 24 });
} catch (e) {
  out = (e.stdout || "").toString();
  process.stderr.write((e.stderr || "").toString().split("\n").slice(0, 6).join("\n") + "\n");
  console.log("  FAIL  the luau half did not run to the end");
  fail++;
} finally {
  try { fs.unlinkSync(script); } catch (e) { /* gone already */ }
}
process.stdout.write(out.split("\n").filter((l) => !/^RESULT /.test(l)).join("\n") + "\n");
const m = out.match(/^RESULT (\d+)/m);
if (!m) {
  console.log("  FAIL  the luau half printed no RESULT line");
  fail++;
} else {
  fail += Number(m[1]);
}
console.log(fail === 0 ? ">>> crypt-ui OK" : `>>> crypt-ui: ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
