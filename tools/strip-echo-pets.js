// Take the echo stat off every pet, keeping all 140 pets.
//
// echo stays a mechanic -- runes, skills, tool specials and Dig.echoAt are
// untouched. What changes is that pets stop being a source of it.
//
// Space loses its signature stat by doing this, so it gets rareOre instead:
// "weighting toward deeper, richer ore", which is what the Ore Finder enchant
// already drives, is not yet any type's signature, and reads correctly for a
// type whose verb is Find.
const fs = require("fs"), path = require("path");
const R = path.join(__dirname, "..", "src/ReplicatedStorage/Mine/Shared");
const FILES = [path.join(R, "MinePetBoosts.luau"), path.join(R, "MinePackConfig.luau")];

let totalStripped = 0, totalOnly = 0;
const onlyEcho = [];

for (const file of FILES) {
  const raw = fs.readFileSync(file, "utf8");
  const crlf = raw.indexOf("\r\n") >= 0;
  let s = raw.split("\r\n").join("\n");
  const lines = s.split("\n");
  let stripped = 0;

  for (let i = 0; i < lines.length; i++) {
    const l = lines[i];
    // only touch pet boost rows: ["Name"] = { stat = n, ... },
    const m = l.match(/^(\s*\["([^"]+)"\]\s*=\s*\{)(.*)(\},?\s*)$/);
    if (!m) continue;
    const body = m[3];
    if (!/\becho\s*=/.test(body)) continue;

    const parts = body.split(",").map(p => p.trim()).filter(p => p.length > 0);
    const kept = parts.filter(p => !/^echo\s*=/.test(p));
    stripped++;

    if (kept.length === 0) {
      //[[ A pet whose only stat was echo would be left with an empty boost
      //   table -- a pet that does nothing. Give it the replacement signature
      //   rather than shipping a dud. ]]
      const was = parts.find(p => /^echo\s*=/.test(p)) || "echo = 0.1";
      const val = was.split("=")[1].trim();
      kept.push("rareOre = " + val);
      onlyEcho.push(m[2]);
      totalOnly++;
    }
    lines[i] = m[1] + " " + kept.join(", ") + " " + m[4].trim();
  }

  s = lines.join("\n");
  // the type signature: Space secondary echo -> rareOre
  s = s.replace(/(Space\s*=\s*\{[^}]*secondary\s*=\s*)"echo"/, '$1"rareOre"');
  s = s.replace(/Space\s*=\s*"echo"/, 'Space = "rareOre"');

  fs.writeFileSync(file, crlf ? s.split("\n").join("\r\n") : s);
  console.log(path.basename(file) + ": stripped echo from " + stripped + " pets");
  totalStripped += stripped;
}

// and the registry, which lives in MineStats
const MS = path.join(R, "MineStats.luau");
const raw = fs.readFileSync(MS, "utf8");
const crlf = raw.indexOf("\r\n") >= 0;
let s = raw.split("\r\n").join("\n");
const before = s;
s = s.replace(/(Space\s*=\s*\{[^}]*secondary\s*=\s*)"echo"(\s*,)/, '$1"rareOre"$2');
if (s === before) console.log("MineStats: Space signature NOT changed (check by hand)");
else console.log("MineStats: Space secondary echo -> rareOre");
fs.writeFileSync(MS, crlf ? s.split("\n").join("\r\n") : s);

console.log("\ntotal pet rows stripped: " + totalStripped);
if (onlyEcho.length) {
  console.log("pets whose ONLY stat was echo (given rareOre instead): " + onlyEcho.join(", "));
} else {
  console.log("no pet was left statless");
}
