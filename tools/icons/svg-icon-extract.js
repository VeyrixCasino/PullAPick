// Pull the 88 icons out of an SVG that is really a wrapper around paired PNGs.
//
// The document is not vector art. It is 176 embedded base64 PNGs: 88 content
// images (8-bit RGB, no alpha) and 88 masks (8-bit greyscale), arranged as
//
//   <defs><mask id="ID"><g filter=..><g transform="matrix(a,0,0,d,e,f)">
//       <image href="data:image/png;base64,..."/>   <- the alpha
//   </g></g></mask></defs>
//   <g mask="url(#ID)"><g transform="matrix(a,0,0,d,e,f)">
//       <image href="data:image/png;base64,..."/>   <- the colour
//   </g></g>
//
// so an icon on its own needs the two combined: RGBA = content RGB + mask
// luminance as alpha. The mask's filter chain is
// feColorMatrix(.. 0.2126 0.7152 0.0722 0 0) on the alpha row, i.e. standard
// Rec.709 luminance -> alpha, and the mask PNGs are already greyscale, so
// luminance is just the grey value.
//
// Pure Node. There is no ImageMagick, Python or sharp on this machine, but
// zlib is built in, which is the only hard part of reading and writing a PNG.
//
// Usage: node svg-icon-extract.js <input.svg> <outDir>
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

// ----------------------------------------------------------------- PNG io --
const CRC = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c;
  }
  return t;
})();
function crc32(buf) {
  let c = -1;
  for (let i = 0; i < buf.length; i++) c = CRC[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ -1) >>> 0;
}

function decodePNG(buf) {
  if (buf.readUInt32BE(0) !== 0x89504e47) throw new Error("not a PNG");
  let pos = 8, ihdr = null;
  const idat = [];
  while (pos < buf.length) {
    const len = buf.readUInt32BE(pos);
    const type = buf.toString("ascii", pos + 4, pos + 8);
    const data = buf.subarray(pos + 8, pos + 8 + len);
    if (type === "IHDR") {
      ihdr = {
        w: data.readUInt32BE(0), h: data.readUInt32BE(4),
        bit: data[8], ct: data[9], interlace: data[12],
      };
    } else if (type === "IDAT") idat.push(data);
    else if (type === "IEND") break;
    pos += 12 + len;
  }
  if (ihdr.interlace !== 0) throw new Error("interlaced PNG not supported");
  if (ihdr.bit !== 8) throw new Error("bit depth " + ihdr.bit + " not supported");
  const channels = { 0: 1, 2: 3, 4: 2, 6: 4 }[ihdr.ct];
  if (!channels) throw new Error("colour type " + ihdr.ct + " not supported");

  const raw = zlib.inflateSync(Buffer.concat(idat));
  const bpp = channels;
  const stride = ihdr.w * bpp;
  const out = Buffer.alloc(ihdr.h * stride);
  let p = 0;
  // Undo the per-scanline filter. subarray shares memory with `out`, so writing
  // through `cur` writes the real output and the next row can read it back as
  // `prev` -- which is required, because filters reference the row above.
  for (let y = 0; y < ihdr.h; y++) {
    const ft = raw[p++];
    const line = raw.subarray(p, p + stride);
    p += stride;
    const cur = out.subarray(y * stride, (y + 1) * stride);
    const prev = y > 0 ? out.subarray((y - 1) * stride, y * stride) : null;
    for (let i = 0; i < stride; i++) {
      const a = i >= bpp ? cur[i - bpp] : 0;
      const b = prev ? prev[i] : 0;
      const c = prev && i >= bpp ? prev[i - bpp] : 0;
      let v = line[i];
      if (ft === 1) v += a;
      else if (ft === 2) v += b;
      else if (ft === 3) v += (a + b) >> 1;
      else if (ft === 4) {
        const pa = Math.abs(b - c), pb = Math.abs(a - c), pc = Math.abs(a + b - 2 * c);
        v += pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
      }
      cur[i] = v & 0xff;
    }
  }
  return { w: ihdr.w, h: ihdr.h, ct: ihdr.ct, channels, data: out };
}

function encodeRGBA(w, h, rgba) {
  const stride = w * 4;
  const raw = Buffer.alloc(h * (stride + 1));
  for (let y = 0; y < h; y++) {
    raw[y * (stride + 1)] = 0; // filter: none
    rgba.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }
  const chunk = (type, data) => {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length, 0);
    const td = Buffer.concat([Buffer.from(type, "ascii"), data]);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(crc32(td), 0);
    return Buffer.concat([len, td, crc]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6; // 8-bit RGBA
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr),
    chunk("IDAT", zlib.deflateSync(raw, { level: 9 })),
    chunk("IEND", Buffer.alloc(0)),
  ]);
}

// ------------------------------------------------------------- the parse --
const SRC = process.argv[2];
const OUT = process.argv[3];
const svg = fs.readFileSync(SRC, "utf8");
fs.mkdirSync(OUT, { recursive: true });

const b64of = (tag) => {
  const href = (/xlink:href="([^"]*)"|href="([^"]*)"/.exec(tag) || []).slice(1).find(Boolean) || "";
  return href.slice(href.indexOf(",") + 1);
};

// 1. every mask id -> its greyscale PNG
const masks = new Map();
for (const m of svg.matchAll(/<mask id="([^"]+)">([\s\S]*?)<\/mask>/g)) {
  const img = /<image\b[^>]*>/.exec(m[2]);
  if (img) masks.set(m[1], b64of(img[0]));
}

// 2. every content group -> its mask id, its transform, its RGB PNG
const icons = [];
const groupRe = /<g mask="url\(#([^)]+)\)">\s*<g transform="matrix\(([^)]+)\)">\s*(<image\b[^>]*>)/g;
for (const m of svg.matchAll(groupRe)) {
  const [a, , , d, e, f] = m[2].split(",").map((v) => parseFloat(v));
  // On-canvas height: the image's own height through this group's scale. Used
  // to derive the row threshold below, so it must come off the same transform.
  const hAttr = /height="(\d+)"/.exec(m[3]);
  icons.push({
    maskId: m[1], sx: a, sy: d, x: e, y: f,
    h: (hAttr ? parseFloat(hAttr[1]) : 0) * d,
    colour: b64of(m[3]),
  });
}

console.log(`masks ${masks.size}, content groups ${icons.length}`);

//[[ 3. Reading order. Rows are found by clustering y, because transforms are
//    sub-pixel and no two icons in a row share an exact y.
//
//    THE THRESHOLD IS HALF AN ICON. It was hardcoded at 40, which suits a sheet
//    whose rows sit ~200 apart and fails on one whose rows sit 34 apart with 5px
//    of jitter inside each row: 40 merged every pair of rows and the ores sheet
//    read as 19,13,17,20,12,3 instead of a grid.
//
//    Inferring it from the GAPS was worse. Splitting the sorted gaps at their
//    largest jump fixed ores and broke the tool sheets, turning 8 rows of 11
//    into 22,22,11,22,11 -- the jump landed between two between-row spacings
//    rather than between jitter and spacing, and nothing in the gaps alone says
//    which is which.
//
//    The icon's own on-canvas height does say. Two icons in a row overlap in y
//    by far less than their height; two rows are separated by about one. So
//    half the median height sits cleanly between the two, whatever the sheet's
//    scale. Verified across all four supplied sheets: ores 9 rows, picks,
//    drills and explosives 8 each. ]]
icons.sort((p, q) => p.y - q.y || p.x - q.x);
const heights = icons.map((i) => i.h).filter((h) => h > 0).sort((a, b) => a - b);
const medianH = heights.length ? heights[Math.floor(heights.length / 2)] : 80;
const rowGap = medianH * 0.5;
let row = 0, rowY = icons.length ? icons[0].y : 0;
for (const ic of icons) {
  if (ic.y - rowY > rowGap) { row++; rowY = ic.y; }
  ic.row = row;
}
console.log(`row threshold ${rowGap.toFixed(1)} (half the median icon height ${medianH.toFixed(1)})`);
for (const ic of icons) ic.key = ic.row * 1e6 + ic.x;
icons.sort((p, q) => p.key - q.key);
const perRow = {};
for (const ic of icons) perRow[ic.row] = (perRow[ic.row] || 0) + 1;
console.log("grid:", Object.keys(perRow).length, "rows ->",
  Object.values(perRow).join(","));

// 4. composite
let written = 0;
const notes = [];
const index = [];
icons.forEach((ic, i) => {
  const mb64 = masks.get(ic.maskId);
  if (!mb64) { notes.push(`#${i}: no mask ${ic.maskId}`); return; }
  const col = decodePNG(Buffer.from(ic.colour, "base64"));
  const msk = decodePNG(Buffer.from(mb64, "base64"));
  if (col.w !== msk.w || col.h !== msk.h) {
    notes.push(`#${i}: size mismatch colour ${col.w}x${col.h} vs mask ${msk.w}x${msk.h}`);
  }
  const w = Math.min(col.w, msk.w), h = Math.min(col.h, msk.h);
  const rgba = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const ci = (y * col.w + x) * col.channels;
      const mi = (y * msk.w + x) * msk.channels;
      const o = (y * w + x) * 4;
      rgba[o] = col.data[ci];
      rgba[o + 1] = col.data[ci + (col.channels > 1 ? 1 : 0)];
      rgba[o + 2] = col.data[ci + (col.channels > 1 ? 2 : 0)];
      rgba[o + 3] = msk.data[mi]; // greyscale mask IS the luminance
    }
  }
  const n = String(i + 1).padStart(2, "0");
  const name = `icon-${n}.png`;
  fs.writeFileSync(path.join(OUT, name), encodeRGBA(w, h, rgba));
  index.push({ name, w, h, row: ic.row, x: Math.round(ic.x), y: Math.round(ic.y) });
  written++;
});

// 5. a contact sheet, so the numbering is checkable at a glance
const cells = index.map((r) =>
  `<figure><img src="${r.name}" alt="${r.name}"><figcaption>${r.name}<br><small>${r.w}x${r.h}</small></figcaption></figure>`
).join("\n");
fs.writeFileSync(path.join(OUT, "index.html"), `<!doctype html>
<meta charset="utf-8"><title>Extracted icons</title>
<style>
 body{background:#17132f;color:#ecaeff;font:14px system-ui;margin:24px}
 h1{font-size:18px;color:#fff}
 .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:14px}
 figure{margin:0;background:#241c4e;border:1px solid #4b3f93;border-radius:10px;padding:10px;text-align:center}
 img{width:100%;height:auto;display:block;
     background:repeating-conic-gradient(#2a2250 0 25%,#1d1840 0 50%) 0 0/16px 16px}
 figcaption{margin-top:6px;color:#cfc8ff;font-size:12px}
</style>
<h1>${written} icons extracted &mdash; checkerboard shows transparency</h1>
<div class="grid">
${cells}
</div>`);

console.log(`wrote ${written} PNGs + index.html to ${OUT}`);
if (notes.length) console.log("notes:\n  " + notes.join("\n  "));
