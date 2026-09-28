// Block-balance check for a Luau chunk.
//
// Scans character by character rather than pattern-matching, so comments,
// strings and long-bracket blocks are skipped properly and keywords inside
// them never count.
const fs = require("fs");
const src = fs.readFileSync(process.argv[2], "utf8");
const BS = String.fromCharCode(92);

let out = "";
let i = 0;
const n = src.length;
while (i < n) {
  const c = src[i];

  // long bracket [[ ]] or [==[ ]==]
  if (c === "[") {
    let j = i + 1, eq = 0;
    while (src[j] === "=") { eq++; j++; }
    if (src[j] === "[") {
      const close = "]" + "=".repeat(eq) + "]";
      const at = src.indexOf(close, j + 1);
      i = at < 0 ? n : at + close.length;
      out += " ";
      continue;
    }
  }
  // comment: -- , which may itself open a long bracket
  if (c === "-" && src[i + 1] === "-") {
    let j = i + 2, eq = 0;
    if (src[j] === "[") {
      let k = j + 1;
      while (src[k] === "=") { eq++; k++; }
      if (src[k] === "[") {
        const close = "]" + "=".repeat(eq) + "]";
        const at = src.indexOf(close, k + 1);
        i = at < 0 ? n : at + close.length;
        out += " ";
        continue;
      }
    }
    const nl = src.indexOf("\n", i);
    i = nl < 0 ? n : nl;
    out += " ";
    continue;
  }
  // quoted string
  if (c === '"' || c === "'") {
    const q = c;
    let j = i + 1;
    while (j < n) {
      if (src[j] === BS) { j += 2; continue; }
      if (src[j] === q) { j++; break; }
      j++;
    }
    i = j;
    out += '""';
    continue;
  }
  out += c;
  i++;
}

const count = re => (out.match(re) || []).length;
const fn = count(/\bfunction\b/g);
const iff = count(/\bif\b/g);
const forr = count(/\bfor\b/g);
const whl = count(/\bwhile\b/g);
const doo = count(/\bdo\b/g);
const end = count(/\bend\b/g);
const elif = count(/\belseif\b/g);
const els = count(/\belse\b/g) - elif;
const rep = count(/\brepeat\b/g);

// every for/while carries its own `do`; whatever is left is a standalone block
const standaloneDo = doo - forr - whl;
const need = fn + iff + forr + whl + standaloneDo;

console.log("function " + fn + "   if " + iff + " (elseif " + elif + ", else " + els + ")");
console.log("for " + forr + "   while " + whl + "   standalone-do " + standaloneDo + "   repeat " + rep);
console.log("");
console.log("blocks needing `end`: " + need);
console.log("`end` present:        " + end);
console.log(need === end ? ">>> BALANCED" : ">>> MISMATCH by " + (end - need));

const po = count(/\(/g), pc = count(/\)/g), bo = count(/\{/g), bc = count(/\}/g);
console.log("");
console.log("parens " + po + " / " + pc + (po === pc ? "  ok" : "  MISMATCH"));
console.log("braces " + bo + " / " + bc + (bo === bc ? "  ok" : "  MISMATCH"));
