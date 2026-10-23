// THE DISCORD LINK TELLS THE TRUTH AND PAYS ONCE (launch audit S38, owner 2026-10-19).
//
// The owner runs the bot: `!link` in Discord, the bot writes the code into the
// pending store through Open Cloud, the player types it here; the bot reads the
// claims store. What was wrong:
//   * any 4-12 letters got "Code accepted!" and a claim-store write;
//   * the verb's cooldown read a nil global, so every redeem threw first;
//   * a link finished on the Discord side never paid its 5,000 gems;
//   * the Account tab promised "player markets and remote trading".
//
// Runs the REAL MineDiscordLink.redeem against a stubbed DataStore, and the REAL
// Verbs.payDiscordBonus / discordLink / discordJoinBonus sliced out of MineServer,
// in luau.
//
//   node tools/verify/discord-link.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }

const svRaw = read("src/ServerScriptService/Mine/MineServer.server.luau");
const slice = (re, what) => {
  const m = svRaw.match(re);
  if (!m) { check(false, "found " + what + " in MineServer"); return "-- missing " + what; }
  return m[0];
};
const gems = Number((svRaw.match(/Verbs\.DISCORD_LINK_GEMS = (\d+)/) || [])[1]);

const harness = `
-- ---------------------------------------------------------------- redeem --
local stores = {}
local writes = {}
local function store(name)
	stores[name] = stores[name] or {}
	local data = stores[name]
	return {
		GetAsync = function(_, k) return data[k] end,
		SetAsync = function(_, k, v) data[k] = v; table.insert(writes, name .. ":" .. k) end,
		RemoveAsync = function(_, k) data[k] = nil; table.insert(writes, name .. ":-" .. k) end,
	}
end
local game = {
	PlaceId = 1, JobId = "job",
	GetService = function(_, s)
		if s == "DataStoreService" then return { GetDataStore = function(_, n) return store(n) end } end
		if s == "RunService" then return { IsStudio = function() return false end } end
	end,
}
local DateTime = { now = function() return { UnixTimestampMillis = 1000000 } end }
local function typeof(_) return "Instance" end
local task = { spawn = function(f, ...) f(...) end }
local Link = (function()
${read(SH + "MineDiscordLink.luau")}
end)()
local plr = { UserId = 42, IsA = function(_, c) return c == "Player" end }
local function countWrites(prefix)
	local n = 0
	for _, w in ipairs(writes) do if string.sub(w, 1, #prefix) == prefix then n += 1 end end
	return n
end
local function case(tag, codeIn)
	writes = {}
	local ok, msg, id = Link.redeem(plr, codeIn)
	print(tag .. "|" .. tostring(ok) .. "|" .. tostring(msg) .. "|" .. tostring(id) .. "|" .. #writes
		.. "|" .. countWrites("Mine_v1_discord_claims") .. "|" .. table.concat(writes, ","))
end
case("MISS", "abcd")
case("SHORT", "ab")
store("Mine_v1_discord_pending"):SetAsync("OLD123", { discordId = 7, expiresAt = 5 })
case("EXPIRED", "old123")
store("Mine_v1_discord_pending"):SetAsync("GAMECODE", { fromGame = true })
case("FROMGAME", "gamecode")
store("Mine_v1_discord_pending"):SetAsync("WXYZ12", { discordId = 123456, discordTag = "miner", expiresAt = 99999999 })
case("HIT", " wxyz 12 ")
local claim = stores["Mine_v1_discord_claims"] and stores["Mine_v1_discord_claims"]["WXYZ12"]
local links = stores["Mine_v1_discord_links"] or {}
print("AFTER|" .. tostring(stores["Mine_v1_discord_pending"]["WXYZ12"] == nil) .. "|"
	.. tostring(links["d_123456"] ~= nil and links["r_42"] ~= nil) .. "|"
	.. tostring(claim and claim.robloxUserId) .. "|" .. tostring(claim and claim.discordId) .. "|" .. tostring(claim and claim.linked))
print("NOTVALID|" .. tostring(Link.NOT_VALID))

-- ------------------------------------------------- the server's three verbs --
do
	local fakeNow = 0
	local os = { clock = function() return fakeNow end, time = function() return 0 end }
	local task = { wait = function(s) fakeNow += (s or 0.03) end, spawn = function(f, ...) f(...) end }
	local profiles = {}
	local saves, toasts = 0, {}
	local function save() saves += 1 end
	local function snap() end
	local function markDirty() end
	local net = { FireClient = function(_, _, action, payload)
		if action == "toast" then table.insert(toasts, tostring(payload)) end
	end }
	local redeemOk = false
	local DiscordLink = { redeem = function() if redeemOk then return true, "Linked to Discord!", "999" end
		return false, "That code isn't valid." end }
	local Verbs = {}
	Verbs.DISCORD_LINK_GEMS = ${gems || 0}
	Verbs.discordLinkCooldown = {}
	Verbs.discordLinkMisses = {}
	${slice(/function Verbs\.payDiscordBonus\(plr, p\)[\s\S]*?\nend\n/, "Verbs.payDiscordBonus")}
	${slice(/function Verbs\.discordLink\(plr, payload\)[\s\S]*?\nend\n/, "Verbs.discordLink")}
	${slice(/function Verbs\.discordJoinBonus\(plr\)[\s\S]*?\nend\n/, "Verbs.discordJoinBonus")}
	local function mkPlr(uid, policy)
		return { UserId = uid, Parent = true, IsA = function() return true end,
			GetAttribute = function(_, k) if k == "PolicyDiscord" then return policy end end }
	end
	-- Linked from Discord while away: pays once, on join, where policy allows.
	profiles[1] = { discordLinked = true, discordBonusClaimed = false, gems = 10 }
	Verbs.discordJoinBonus(mkPlr(1, true))
	local g1 = profiles[1].gems
	Verbs.discordJoinBonus(mkPlr(1, true))
	print("JOIN|" .. g1 .. "|" .. profiles[1].gems .. "|" .. tostring(profiles[1].discordBonusClaimed) .. "|" .. saves)
	profiles[2] = { discordLinked = true, discordBonusClaimed = false, gems = 10 }
	Verbs.discordJoinBonus(mkPlr(2, false))
	profiles[3] = { discordLinked = false, gems = 10 }
	Verbs.discordJoinBonus(mkPlr(3, true))
	profiles[4] = { discordLinked = true, discordBonusClaimed = false, gems = 10, _ephemeral = true }
	Verbs.discordJoinBonus(mkPlr(4, true))
	print("JOINNO|" .. profiles[2].gems .. "|" .. profiles[3].gems .. "|" .. profiles[4].gems .. "|" .. fakeNow)
	-- The verb: a link pays once; a repeat link pays nothing more.
	profiles[5] = { gems = 0 }
	redeemOk = true
	toasts = {}
	fakeNow = 1000
	Verbs.discordLink(mkPlr(5, true), { code = "WXYZ12" })
	local afterFirst = profiles[5].gems
	fakeNow = 1010
	Verbs.discordLink(mkPlr(5, true), { code = "WXYZ12" })
	print("VERB|" .. afterFirst .. "|" .. profiles[5].gems .. "|" .. tostring(profiles[5].discordLinked) .. "|" .. tostring(toasts[1]))
	-- Misses back off: 2 s, then 4, 8 ... capped at 60.
	redeemOk = false
	profiles[6] = { gems = 0 }
	local p6 = mkPlr(6, true)
	local gaps = {}
	fakeNow = 2000
	for i = 1, 8 do
		toasts = {}
		Verbs.discordLink(p6, { code = "NOPE1" })
		table.insert(gaps, string.format("%.0f", Verbs.discordLinkCooldown[6] - fakeNow))
		fakeNow = Verbs.discordLinkCooldown[6] + 0.01
	end
	toasts = {}
	Verbs.discordLink(p6, { code = "NOPE1" })
	Verbs.discordLink(p6, { code = "NOPE1" })
	print("BACKOFF|" .. table.concat(gaps, ",") .. "|" .. tostring(toasts[#toasts]))
end
`;
const script = path.join(ROOT, ".luau-bin/discord-link-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" }); }
catch (e) { process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || ""); fail++; }
const lines = out.split(/\r?\n/);
const get = (tag) => (lines.find((l) => l.startsWith(tag + "|")) || "").split("|").slice(1);

// 1. redeem.
const notValid = get("NOTVALID")[0] || "";
check(/isn't valid/.test(notValid) && /!link/.test(notValid) && /Discord/.test(notValid), `a dud code is told so, and to type !link in the Discord ("${notValid}")`);
const miss = get("MISS");
check(miss[0] === "false" && miss[1] === notValid, `a code not in pending is refused, not "Code accepted!" (${miss[1]})`);
check(miss[3] === "0" && miss[4] === "0", `...and costs no DataStore write (${miss[3]} writes)`);
const short = get("SHORT");
check(short[0] === "false" && short[3] === "0", "a code of the wrong length is refused with no write");
const expired = get("EXPIRED");
check(expired[0] === "false" && /expired/i.test(expired[1]) && expired[4] === "0", "an expired code is refused, removed from pending, and writes no claim");
const fromGame = get("FROMGAME");
check(fromGame[0] === "false" && /!link GAMECODE/.test(fromGame[1]) && fromGame[3] === "0", "a game-made code points at Discord");
const hit = get("HIT");
check(hit[0] === "true" && hit[2] === "123456", `a real code links (${hit[1]}, id ${hit[2]})`);
check(hit[4] === "1", `...and writes exactly one claim, the one the bot reads to say "Linked" (${hit[5]})`);
const after = get("AFTER");
check(after[0] === "true" && after[1] === "true", "...the pending code is used up and both link rows are saved");
check(after[2] === "42" && after[3] === "123456" && after[4] === "true", "...and the claim names the Roblox user and the Discord id");

// 2. The server: one bonus, from either side.
const join = get("JOIN");
check(+join[0] === 10 + gems && +join[1] === 10 + gems && join[2] === "true" && +join[3] >= 1,
  `a link finished in Discord while away pays ${gems} gems on join, once, and saves (${join.join(", ")})`);
const joinNo = get("JOINNO");
check(+joinNo[0] === 10 && +joinNo[1] === 10 && +joinNo[2] === 10,
  "...not where Roblox's policy hides Discord, not without a link, never into an unsaved profile");
check(+joinNo[3] <= 31, `...and it waits at most 30 s for the policy answer (${joinNo[3]} s simulated)`);
const verb = get("VERB");
check(+verb[0] === gems && +verb[1] === gems && verb[2] === "true" && new RegExp(`\\+${gems} gems`).test(verb[3] || ""),
  `linking here pays ${gems} once; a second link pays nothing (${verb[0]} then ${verb[1]}; "${verb[3]}")`);
const back = get("BACKOFF");
check(back[0] === "2,4,8,16,32,60,60,60", `misses back off 2, 4, 8 ... 60 s (${back[0]})`);
check(/^Try again in \d+ s$/.test(back[1] || ""), `...and a try inside the wait is refused before any DataStore read ("${back[1]}")`);

// 3. Static: no nil global, the join path is wired, and the tab tells the truth.
const sv = code(svRaw);
check(!/(^|[^.\w])discordLinkCooldown\b/m.test(sv), "nothing reads the bare `discordLinkCooldown` global any more");
const hook = (sv.match(/function Verbs\.hookPlayer\(plr\)[\s\S]*?\nend\n/) || [""])[0];
check(/pcall\(Verbs\.discordJoinBonus, plr\)/.test(hook), "hookPlayer runs the join bonus");
check((sv.match(/if Verbs\.payDiscordBonus\(plr, p\) then/g) || []).length === 2, "...and both paths pay through Verbs.payDiscordBonus");
const inv = code(read(SH + "MineInventoryView.luau"));
const account = (inv.match(/local function renderAccount\(\)[\s\S]*?\n\tend\n/) || [""])[0];
check(account.length > 200 && !/market|remote trading/i.test(account), "the Account tab promises no player markets or remote trading");
check(/discord\.gg\/Ab5ZpVdRvp/.test(account) && !/OpenBrowserWindow|https?:\/\//.test(account),
  "...and shows the invite discord.gg/Ab5ZpVdRvp as plain text, nothing clickable");

console.log("");
console.log(fail > 0 ? `>>> discord-link: ${fail} FAILED` : ">>> discord-link: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
