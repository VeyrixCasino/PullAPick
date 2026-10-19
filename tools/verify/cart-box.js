// A BUILD-A-BOX LINE GRANTS EVERY BOX IT CHARGES FOR.
//
// The cart's quantity buttons work on a Build-a-Box line too, and buyCart
// charged MinePackConfig.boxPrice x qty for it -- then put ONE box in the bag
// whatever the qty (found 2026-10-19). It grants qty boxes now.
//
// buyCart and cartPrice are sliced out of MineServer and RUN, on the real
// MinePackConfig and MineCases (prices, the credit shelf, the box price, the
// bag rows), with the rest of the server stubbed.
//
// Fails on 3863d14 (a box line of 3 charges for 3 and grants 10 packs).
//
//   node tools/verify/cart-box.js
"use strict";
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");
const Shared = require("./_shared");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => Luau.readSrc(path.join(ROOT, p));
let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};
const between = (s, a, b, from) => {
  const i = s.indexOf(a, from || 0);
  const j = i < 0 ? -1 : s.indexOf(b, i + a.length);
  return (i < 0 || j < 0) ? "" : s.slice(i, j + b.length);
};
console.log("cart-box: a Build-a-Box line of N grants N boxes");

const SRV = read("src/ServerScriptService/Mine/MineServer.server.luau");
const cartPrice = between(SRV, "local function cartPrice(line)", "\nend\n");
const buyCart = between(SRV, "local function buyCart(plr, payload)", "\nend\n");
check(cartPrice.length > 500 && buyCart.length > 2000, "found cartPrice and buyCart in MineServer");

if (!Luau.ready) {
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}
const test = Shared.prelude(ROOT, ["MineCases", "MinePackConfig", "MineSetPets", "MineSetPacks", "MinePackArt",
  "MineZonePacks", "Mine1PacksData", "Mine1ChestsData"], ["SetPets"]) + `
setmetatable(SHARED, { __index = function(t, k) return t.FindFirstChild(t, k) end })
local shared = SHARED
local Packs = require(SHARED:FindFirstChild("MinePackConfig"))
local Cases = require(SHARED:FindFirstChild("MineCases"))
local Cards = { SETS = { dragons_dawn = {} } }
local C = { vipPrice = function(n) return n end }
local Const = { CART_MAX_LINES = 20, CART_MAX_QTY = 100 }
local Dig = { cartPaid = {} }
local fired = {}
local net = { FireClient = function(_, plr, action, payload) table.insert(fired, { action = action, payload = payload }) end }
local profiles = {}
local function isVip() return false end
local function hasVipPass() return false end
local function markDirty() end
local function snap() end
${cartPrice}
${buyCart}
local shelf = Cases.creditShelf()
local box = {}
for i = 1, 10 do box[i] = shelf[((i - 1) % #shelf) + 1] end
local function run(lines)
	local plr = { UserId = 1 }
	profiles[1] = { credits = 1e9, packs = {} }
	fired = {}
	buyCart(plr, { lines = lines })
	local p = profiles[1]
	local result = fired[#fired] and fired[#fired].payload or {}
	local paid = 0
	for _, row in ipairs(p.packs) do if row.paid then paid += 1 end end
	return 1e9 - p.credits, #p.packs, result, paid
end
local unit = Packs.boxPrice(box)
local spent3, n3, r3, paid3 = run({ { kind = "box", id = "custom", qty = 3, packs = box } })
local spent1, n1 = run({ { kind = "box", id = "custom", qty = 1, packs = box } })
local wild = 0
for _, id in ipairs(box) do local d = Cases.get(id) if d and d.caseType == "wild" then wild += 1 end end
print("BOX3 " .. spent3 .. " " .. Packs.creditPrice(unit * 3, false) .. " " .. n3 .. " " .. tostring(r3.ok) .. " " .. tostring(r3.items and r3.items[1] and r3.items[1].qty))
print("BOX1 " .. spent1 .. " " .. Packs.creditPrice(unit, false) .. " " .. n1)
print("PAID " .. paid3 .. " " .. (wild * 3))
local spentP, nP = run({ { kind = "pack", id = shelf[1], qty = 2 } })
print("PACK " .. nP .. " " .. spentP .. " " .. Packs.creditPrice(Packs.priceOf(shelf[1]) * 2, false))
`;
const tmp = path.join(os.tmpdir(), "mfc-cart-box-" + process.pid + ".luau");
fs.writeFileSync(tmp, test);
let out = "";
try { out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8", maxBuffer: 1 << 26 }); } catch (e) {
  out = String(e.stdout || "") + String(e.stderr || "");
  console.log(out.split("\n").slice(-6).map((l) => "        " + l).join("\n"));
}
fs.unlinkSync(tmp);
out = out.replace(/\t/g, " ");
const lineOf = (k) => { const m = out.match(new RegExp("^" + k + " (.*)$", "m")); return m ? m[1] : ""; };
const b3 = lineOf("BOX3").split(" ");
check(b3.length === 5 && b3[0] === b3[1] && +b3[0] > 0, "a box line of 3 charges three boxes, once", lineOf("BOX3"));
check(b3[2] === "30" && b3[3] === "true" && b3[4] === "30", "...and puts all three boxes (30 packs) in the bag, and says so", lineOf("BOX3"));
const b1 = lineOf("BOX1").split(" ");
check(b1[0] === b1[1] && b1[2] === "10", "a box line of 1 is one box, as before", lineOf("BOX1"));
const pd = lineOf("PAID").split(" ");
check(pd.length === 2 && pd[0] === pd[1], "every wild case in those boxes is a paid case (it can roll the SSS set)", lineOf("PAID"));
const pk = lineOf("PACK").split(" ");
check(pk[0] === "2" && pk[1] === pk[2], "a pack line is unchanged: qty 2 pays for 2 and grants 2", lineOf("PACK"));

console.log(fail === 0 ? ">>> cart-box OK" : `>>> ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
