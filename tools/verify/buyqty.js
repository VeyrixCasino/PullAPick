// The typed quantity box, the cart and the server must agree on one ceiling.
//
// Owner, 2026-10-03: "a custom amoujt of packs to buy (the player can write the
// number themselves [default 1])".
//
// The pipeline already carried a qty end to end -- cart line -> buyCart -> grant
// -- and the only thing missing was the player being able to type it. But the
// view capped a line at 25, the server clamped at 25, and the new box allowed
// 100. A box that accepts 60 above a server that silently clamps to 25 is a box
// that lies, which is the failure the pack tile's own comment warns about.
//
//   node tools/verify/buyqty.js
const fs = require("fs");
const path = require("path");
const ROOT = path.resolve(__dirname, "../..");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

const server = read("src/ServerScriptService/Mine/MineServer.server.luau");
const view = read("src/ReplicatedStorage/Mine/Shared/MineInventoryView.luau");

const n = (src, k) => Number((src.match(new RegExp(`${k}\\s*=\\s*(\\d+)`)) || [])[1]);
const cartMax = n(server, "CART_MAX_QTY");
const buyMax = n(server, "BUY_QTY_MAX");
const viewMax = n(view, "local CART_QTY_MAX");

check(cartMax > 0 && buyMax > 0 && viewMax > 0,
  `all three ceilings exist (cart ${cartMax}, buy ${buyMax}, view ${viewMax})`);
check(cartMax === viewMax,
  `the view's box and the server's cart agree (${viewMax} vs ${cartMax})`);
check(buyMax === cartMax,
  `buyScroll's ceiling matches the cart's (${buyMax} vs ${cartMax})`);
check(cartMax >= 50, `the ceiling is worth typing into (${cartMax})`);

// The box itself.
check(/local q = mk\("TextBox"/.test(view), "the quantity is a TextBox, not a read-only label");
check(/ClearTextOnFocus = false/.test(view),
  "...that does not wipe itself on focus, so 12 can be edited to 15");
check(/q\.FocusLost:Connect/.test(view), "...and commits on focus lost");
check(/if not want then\s*\n\s*q\.Text = tostring\(line\.qty\)/.test(view),
  "...snapping back to the real quantity on unparseable input, not to 1");
check(/math\.clamp\(math\.floor\(want\), 1, CART_QTY_MAX\)/.test(view),
  "...clamped client-side too, so the box cannot show a number the server will refuse");

// Default 1, as asked.
check(/qty = qty or 1/.test(view), "a line defaults to 1");
const scroll = (server.match(/function Verbs\.buyScroll[\s\S]*?\n^end$/m) || [""])[0];
check(/tonumber\(payload and payload\.qty\) or 1/.test(scroll),
  "buyScroll defaults to 1 when no quantity is sent");
check(/qty = math\.min\(qty, math\.floor\(have \/ unit\)\)/.test(scroll),
  "...and pays out what the wallet covers rather than refusing the whole request");

console.log("");
console.log(fail > 0 ? `>>> buyqty: ${fail} FAILED` : ">>> buyqty: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
