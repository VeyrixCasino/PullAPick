const fs = require("fs");
const src = fs.readFileSync("src/ReplicatedStorage/Mine/Shared/MineDepth.luau", "utf8");
const re = /\{ id = "([^"]+)", name = "([^"]+)", layers = \{ (\d+), (\d+) \}, dirtHp = ([0-9.eE+]+), band = "(\w+)" \}/g;
const S = []; let m;
while ((m = re.exec(src)) !== null) S.push({ name: m[2], lo: +m[3], hi: +m[4], hp: Number(m[5]), band: m[6] });

function ceilTenth(x){const t=x*10;let f=Math.floor(t+1e-6);if(t-f>1e-4)f+=1;return f/10;}
function abbrevCeil(n){if(n<=0)return 0;if(n<1000)return Math.ceil(n-1e-8);
  let e=Math.max(1,Math.min(679,Math.floor(Math.log10(n)/3)));let u=Math.pow(10,e*3);
  let s=ceilTenth(n/u);if(s>=1000&&e<679){e+=1;u=Math.pow(10,e*3);s=ceilTenth(n/u);}return s*u;}
const sectionFor=(L)=>S.find(s=>L>=s.lo&&L<=s.hi)||S[S.length-1];
const dirtHp=(z,L)=>Math.max(1,abbrevCeil(sectionFor(L).hp*Math.pow(6,z-1)*2));
const fmt=(n)=>{if(n<1000)return String(Math.round(n));
  const u=["","K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc"];
  const e=Math.min(Math.floor(Math.log10(n)/3),u.length-1);
  if(n>=1e36)return n.toExponential(2);
  return (n/Math.pow(10,e*3)).toFixed(2).replace(/\.?0+$/,"")+u[e];};

let o = "";
o += "# Depth sheet — the rock HP equation, verbatim\n\n";
o += "Generated from `MineDepth.SECTIONS` by `tools/gen-depth-sheet.js`. Regenerate\n";
o += "after any change to the section table; do not hand-edit the tables below.\n\n";
o += "## The equation, exactly as the game runs it\n\n";
o += "```\ndirtHp(zone, layer) = MineAbbrev.ceil(\n";
o += "    SECTIONS[sectionFor(layer)].dirtHp   -- authored per-section constant\n";
o += "  * 6 ^ (zoneIndex - 1)                  -- MineDepth.ZONE_HP_MULT\n";
o += "  * 2                                    -- flat toughness factor\n)\n```\n\n";
o += "`MineConfig.blockHp(kind, zone, layer)` wraps it:\n\n";
o += "- `core` -> flat `BLOCKS.core.hp`\n";
o += "- `chest` / `crate` / `lucky_block` -> `floor(dirt * CHEST_HP_MULT(2) + 0.5)`\n";
o += "- anything else -> `dirt`\n";
o += "- `bigbang` is forced to `zoneIndex = 11` (it sits above Primordium, not beside Meadow)\n\n";
o += "**It is a step function, not a curve.** HP is constant across a whole named\n";
o += "section and jumps at the boundary. Interpolating between sections invents\n";
o += "difficulty the game does not have.\n\n";
o += "`MineAbbrev.ceil` snaps up to one decimal of the thousands unit, so the block\n";
o += "and the label a player reads are the same number (1.209B becomes 1.3B).\n\n";
o += "## Section-size progression (current)\n\n";
const runs=[];
for(const s of S){const size=s.hi-s.lo+1;const last=runs[runs.length-1];
  if(last&&last.size===size){last.count++;last.hi=s.hi;}else runs.push({size,count:1,lo:s.lo,hi:s.hi});}
o += "```\n" + runs.map(r=>`${String(r.size).padStart(4)} x ${String(r.count).padStart(3)} = ${String(r.size*r.count).padStart(5)} layers  (L${r.lo}-${r.hi})`).join("\n") + "\n```\n\n";
o += "So: **" + runs.map(r=>`(${r.size}x${r.count})`).join(" + ") + "**, " + S.length + " sections, layers 1-" + S[S.length-1].hi + ".\n\n";
o += "### HP step between consecutive sections\n\n| band | sections | avg step | min | max |\n| --- | ---: | ---: | ---: | ---: |\n";
const ratios=S.slice(1).map((s,i)=>s.hp/S[i].hp);const band={};
S.forEach((s,i)=>{if(i===0)return;(band[s.band]||=[]).push(ratios[i-1]);});
for(const [b,rs] of Object.entries(band)){const avg=rs.reduce((a,c)=>a+c,0)/rs.length;
  o += `| ${b} | ${rs.length} | x${avg.toFixed(4)} | x${Math.min(...rs).toFixed(3)} | x${Math.max(...rs).toFixed(3)} |\n`;}
o += "\nThe deep band is a flat x1.28 per section. Shallow front-loads at x2.04.\n\n";
o += "## Zones 1-10 to depth 10,000\n\nDirt HP. Every zone is exactly x6 the one before, so Zone N = Zone 1 x 6^(N-1).\n\n";
const cps=[1,100,250,500,750,1000,1500,2000,2500,3000,4000,5000,6000,7000,8000,9000,10000];
o += "| depth | " + Array.from({length:10},(_,i)=>"Z"+(i+1)).join(" | ") + " |\n";
o += "| ---: |" + " ---: |".repeat(10) + "\n";
for(const L of cps) o += `| ${L} | ` + Array.from({length:10},(_,z)=>fmt(dirtHp(z+1,L))).join(" | ") + " |\n";
o += "\n### Zone multipliers\n\n| zone | x | zone | x |\n| ---: | ---: | ---: | ---: |\n";
for(let i=0;i<5;i++) o += `| ${i+1} | ${Math.pow(6,i).toLocaleString("en-US")} | ${i+6} | ${Math.pow(6,i+5).toLocaleString("en-US")} |\n`;
o += "\n## Every section (Zone 1 dirt HP)\n\nMultiply by 6^(zone-1) for other zones, then snap with `MineAbbrev.ceil`.\n\n";
o += "| # | section | layers | band | Z1 dirt HP |\n| ---: | --- | --- | --- | ---: |\n";
S.forEach((s,i)=>{o+=`| ${i+1} | ${s.name} | ${s.lo}-${s.hi} | ${s.band} | ${fmt(dirtHp(1,s.lo))} |\n`;});
fs.writeFileSync("docs/depth-sheet.md", o);
console.log("wrote docs/depth-sheet.md:", o.split("\n").length, "lines,", S.length, "sections");
