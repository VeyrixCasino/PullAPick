// Save every icon in a Canva-exported SVG sheet as its own transparent PNG.
//
// Canva writes each placed image as <g mask=url(#m)><g transform=matrix(...)><image/></g></g>
// where the mask holds a grey matte of the same picture (luminance = opacity). So an
// icon is its colour PNG plus that matte; this folds them into one RGBA PNG.
// Icons are numbered in reading order (rows top to bottom, left to right).
//
// Run: node tools/extract-svg-icons.js <sheet.svg> [outDir] [prefix]
// Out: <outDir>/<prefix>-01.png ...      (prefix defaults to "icon")
const fs = require("fs"), path = require("path");
const { decode, encode } = require("./_png.js");

const SRC = process.argv[2];
if (!SRC) { console.error("usage: node tools/extract-svg-icons.js <sheet.svg> [outDir] [prefix]"); process.exit(1); }
const OUT = process.argv[3] || path.join(__dirname, "..", "build", path.basename(SRC, ".svg"));
const PREFIX = process.argv[4] || "icon";
const svg = fs.readFileSync(SRC, "utf8");

const png = (b64) => decode(Buffer.from(b64, "base64"));
const imgRe = /<image[^>]*href="data:image\/png;base64,([^"]+)"/;

// mask id -> matte image
const mattes = new Map();
for (const m of svg.matchAll(/<mask id="([^"]+)">([\s\S]*?)<\/mask>/g)) {
  const im = imgRe.exec(m[2]);
  if (im) mattes.set(m[1], im[1]);
}
// placed icons: everything after </defs>
const body = svg.slice(svg.indexOf("</defs>"));
const icons = [];
for (const g of body.matchAll(/<g mask="url\(#([^)]+)\)">\s*<g transform="matrix\(([^)]+)\)">\s*(<image[^>]*>)/g)) {
  const [a, , , d, e, f] = g[2].split(",").map(Number);
  const im = imgRe.exec(g[3]);
  if (!im || !mattes.has(g[1])) continue;
  const w = +/width="(\d+)"/.exec(g[3])[1], h = +/height="(\d+)"/.exec(g[3])[1];
  // Placed by top-left, and the pictures differ in size, so order by their centres.
  icons.push({ x: e + w * a / 2, y: f + h * d / 2, color: im[1], matte: mattes.get(g[1]) });
}
// rows = icons whose centres are within a third of an icon height of each other
icons.sort((a, b) => a.y - b.y);
const rows = [];
for (const ic of icons) {
  const r = rows[rows.length - 1];
  if (r && Math.abs(ic.y - r[0].y) < 70) r.push(ic); else rows.push([ic]);
}
const ordered = rows.flatMap(r => r.sort((a, b) => a.x - b.x));

fs.mkdirSync(OUT, { recursive: true });
let bad = 0;
ordered.forEach((ic, k) => {
  const c = png(ic.color), m = png(ic.matte);
  if (c.w !== m.w || c.h !== m.h) { bad++; console.log("  size mismatch on " + (k + 1)); return; }
  const out = Buffer.from(c.d);
  for (let i = 0; i < c.w * c.h; i++) {
    const lum = 0.2126 * m.d[i*4] + 0.7152 * m.d[i*4+1] + 0.0722 * m.d[i*4+2];
    out[i*4+3] = Math.round(lum * (m.d[i*4+3] / 255));
  }
  fs.writeFileSync(path.join(OUT, `${PREFIX}-${String(k + 1).padStart(2, "0")}.png`), encode(c.w, c.h, out));
});
console.log(`${ordered.length} icons in ${rows.length} rows (${rows.map(r => r.length).join(" ")}) -> ${path.relative(process.cwd(), OUT)}${bad ? ", " + bad + " skipped" : ""}`);
