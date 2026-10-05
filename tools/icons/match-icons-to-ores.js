// Which of the 88 pickaxe skins belongs to which of the 82 ores.
//
// The sheet is NOT in ore order -- row one is wood, grey, copper, tan, speckled,
// silver, grey, blue-grey against a roster that starts stone, clay, limestone,
// pumice, halite, coal. Assigning by index would put a black pickaxe on
// Limestone and nobody would notice until it shipped.
//
// Each ore already states its colour in MineConfig.ORES and each icon has one,
// so this measures and matches rather than guessing an order.
//
// MEASURING THE ICON. Not a mean of every pixel: these are shaded 3D renders
// with dark outlines and white speculars, and averaging drags everything to
// mid-grey. Opaque pixels are binned by hue, outline and specular are dropped as
// shading rather than identity, and the dominant bin wins. Within that bin the
// colour is taken at the 70th percentile of value -- the LIT face of the pick,
// not its shadow, which is what the ore's own colour represents. Averaging the
// bin instead returned #2542a0 for a pickaxe that reads as bright cobalt.
//
// MATCHING IS OPTIMAL, NOT GREEDY. The first version fixed the globally closest
// pair, then the next, and so on. That starves whoever comes last: it spent the
// blues early and handed Cobalt -- #0049F8, as blue as the roster gets -- a grey
// pickaxe at distance 1.897. Hungarian minimises the TOTAL cost across all 82
// assignments at once, so a locally worse pair is accepted when it saves more
// elsewhere. Same cost function, very different result.
//
// It still will not be perfect, and it is not meant to be read as final: the
// roster wants about seventeen grey/white picks and the sheet has nine, so some
// grey ore must wear colour no matter how the matching is done. Every assignment
// is printed with its distance, and proposal-sheet.png shows each icon against
// its ore's colour so a bad pair is visible rather than buried in a table.
//
// Usage: node match-icons-to-ores.js <iconDir> <MineConfig.luau> <out.json>
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

// ---------------------------------------------------------- PNG decoding --
function decodeRGBA(buf) {
  let pos = 8, ih = null;
  const idat = [];
  while (pos < buf.length) {
    const len = buf.readUInt32BE(pos);
    const t = buf.toString("ascii", pos + 4, pos + 8);
    const d = buf.subarray(pos + 8, pos + 8 + len);
    if (t === "IHDR") ih = { w: d.readUInt32BE(0), h: d.readUInt32BE(4) };
    else if (t === "IDAT") idat.push(d);
    else if (t === "IEND") break;
    pos += 12 + len;
  }
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const ch = 4, stride = ih.w * ch, out = Buffer.alloc(ih.h * stride);
  let p = 0;
  for (let y = 0; y < ih.h; y++) {
    const ft = raw[p++], line = raw.subarray(p, p + stride);
    p += stride;
    const cur = out.subarray(y * stride, (y + 1) * stride);
    const prev = y > 0 ? out.subarray((y - 1) * stride, y * stride) : null;
    for (let i = 0; i < stride; i++) {
      const a = i >= ch ? cur[i - ch] : 0;
      const b = prev ? prev[i] : 0;
      const c = prev && i >= ch ? prev[i - ch] : 0;
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
  return { w: ih.w, h: ih.h, data: out };
}
const CRC = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c; }
  return t;
})();
const crc32 = (b) => { let c = -1; for (let i = 0; i < b.length; i++) c = CRC[(c ^ b[i]) & 255] ^ (c >>> 8); return (c ^ -1) >>> 0; };
function encodeRGBA(w, h, rgba) {
  const stride = w * 4, raw = Buffer.alloc(h * (stride + 1));
  for (let y = 0; y < h; y++) { raw[y * (stride + 1)] = 0; rgba.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride); }
  const chunk = (t, d) => {
    const l = Buffer.alloc(4); l.writeUInt32BE(d.length, 0);
    const td = Buffer.concat([Buffer.from(t, "ascii"), d]);
    const c = Buffer.alloc(4); c.writeUInt32BE(crc32(td), 0);
    return Buffer.concat([l, td, c]);
  };
  const ih = Buffer.alloc(13); ih.writeUInt32BE(w, 0); ih.writeUInt32BE(h, 4); ih[8] = 8; ih[9] = 6;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk("IHDR", ih),
    chunk("IDAT", zlib.deflateSync(raw, { level: 9 })), chunk("IEND", Buffer.alloc(0))]);
}

// ------------------------------------------------------------- colour --
function rgb2hsv(r, g, b) {
  r /= 255; g /= 255; b /= 255;
  const mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn;
  let h = 0;
  if (d > 1e-6) {
    if (mx === r) h = ((g - b) / d) % 6;
    else if (mx === g) h = (b - r) / d + 2;
    else h = (r - g) / d + 4;
    h *= 60; if (h < 0) h += 360;
  }
  return [h, mx > 0 ? d / mx : 0, mx];
}

function iconColour(img) {
  const bins = new Map();
  const lits = [];
  let n = 0, satN = 0;
  for (let i = 0; i < img.w * img.h; i++) {
    const o = i * 4;
    if (img.data[o + 3] < 200) continue;
    const r = img.data[o], g = img.data[o + 1], b = img.data[o + 2];
    const [h, s, v] = rgb2hsv(r, g, b);
    if (v < 0.14 || v > 0.97) continue; // outline / specular: shading, not identity
    n++; lits.push(v);
    if (s < 0.18) continue;
    satN++;
    const k = Math.floor(h / 10);
    const e = bins.get(k) || [];
    e.push([r, g, b, v]);
    bins.set(k, e);
  }
  let best = null;
  for (const e of bins.values()) if (!best || e.length > best.length) best = e;
  const satShare = n ? satN / n : 0;
  if (!best || satShare < 0.12) {
    // Genuinely a grey/white pick. Lightness is the only signal it has.
    lits.sort((a, b) => a - b);
    const g = Math.round((lits[Math.floor(lits.length * 0.7)] || 0.5) * 255);
    return { r: g, g: g, b: g, grey: true, satShare };
  }
  // The LIT face of the dominant hue, not its average -- see the header.
  best.sort((a, b) => a[3] - b[3]);
  const lo = Math.floor(best.length * 0.6), hi = Math.floor(best.length * 0.9);
  let r = 0, g = 0, b = 0, c = 0;
  for (let i = lo; i <= Math.max(lo, hi); i++) { r += best[i][0]; g += best[i][1]; b += best[i][2]; c++; }
  return { r: Math.round(r / c), g: Math.round(g / c), b: Math.round(b / c), grey: false, satShare };
}

function dist(ic, ore) {
  const [ah, as, av] = rgb2hsv(ic.r, ic.g, ic.b);
  const [bh, bs, bv] = rgb2hsv(ore.r, ore.g, ore.b);
  const oreGrey = bs < 0.15;
  if (ic.grey || oreGrey) {
    // One side has no hue, so lightness carries it. Penalise pairing a strongly
    // coloured icon with a grey ore, which is what actually looks wrong.
    const mismatch = ic.grey !== oreGrey ? 0.55 + Math.max(as, bs) * 0.5 : 0;
    return Math.abs(av - bv) * 1.3 + Math.abs(as - bs) * 0.5 + mismatch;
  }
  let dh = Math.abs(ah - bh);
  if (dh > 180) dh = 360 - dh;
  // Hue dominates; value barely matters because the renders are all lit alike.
  return (dh / 180) * 2.0 + Math.abs(as - bs) * 0.45 + Math.abs(av - bv) * 0.35;
}

// --------------------------------------------- optimal assignment (JV) --
// Classic O(n^3) Hungarian with potentials, for n rows <= m cols.
function hungarian(cost) {
  const n = cost.length, m = cost[0].length;
  const u = new Float64Array(n + 1), v = new Float64Array(m + 1);
  const p = new Int32Array(m + 1), way = new Int32Array(m + 1);
  for (let i = 1; i <= n; i++) {
    p[0] = i;
    let j0 = 0;
    const minv = new Float64Array(m + 1).fill(Infinity);
    const used = new Uint8Array(m + 1);
    do {
      used[j0] = 1;
      const i0 = p[j0];
      let delta = Infinity, j1 = -1;
      for (let j = 1; j <= m; j++) {
        if (used[j]) continue;
        const cur = cost[i0 - 1][j - 1] - u[i0] - v[j];
        if (cur < minv[j]) { minv[j] = cur; way[j] = j0; }
        if (minv[j] < delta) { delta = minv[j]; j1 = j; }
      }
      for (let j = 0; j <= m; j++) {
        if (used[j]) { u[p[j]] += delta; v[j] -= delta; }
        else minv[j] -= delta;
      }
      j0 = j1;
    } while (p[j0] !== 0);
    do { const j1 = way[j0]; p[j0] = p[j1]; j0 = j1; } while (j0);
  }
  const assign = new Int32Array(n).fill(-1);
  for (let j = 1; j <= m; j++) if (p[j] > 0) assign[p[j] - 1] = j - 1;
  return assign;
}

// --------------------------------------------------------------- inputs --
const DIR = process.argv[2], CFG = process.argv[3], OUT = process.argv[4];
const cfg = fs.readFileSync(CFG, "utf8").split(/\r?\n/);
const start = cfg.findIndex((l) => l.startsWith("MineConfig.ORES = {"));
const ores = [];
for (let i = start + 1; i < cfg.length; i++) {
  if (cfg[i] === "}") break;
  const m = cfg[i].match(/id\s*=\s*"([^"]+)".*?name\s*=\s*"([^"]+)".*?tier\s*=\s*(\d+).*?Color3\.fromRGB\((\d+),\s*(\d+),\s*(\d+)\)/);
  if (m) ores.push({ id: m[1], name: m[2], tier: +m[3], r: +m[4], g: +m[5], b: +m[6] });
}
const files = fs.readdirSync(DIR).filter((f) => /^icon-\d+\.png$/.test(f)).sort();
const imgs = new Map();
const icons = files.map((f) => {
  const im = decodeRGBA(fs.readFileSync(path.join(DIR, f)));
  imgs.set(f, im);
  return { file: f, ...iconColour(im) };
});
console.log(`${ores.length} ores, ${icons.length} icons`);

// icon-01 is the wooden starter: the only unambiguously identifiable one, and it
// must not be eaten by a brown ore like Petrifact.
const STARTER = "icon-01.png";
const pool = icons.filter((i) => i.file !== STARTER);

const cost = ores.map((o) => pool.map((ic) => dist(ic, o)));
const assign = hungarian(cost);

const hex = (o) => "#" + [o.r, o.g, o.b].map((v) => v.toString(16).padStart(2, "0").toUpperCase()).join("");
const rows = ores.map((o, i) => {
  const ic = pool[assign[i]];
  return { tier: o.tier, id: o.id, name: o.name, ore: hex(o), oreRGB: [o.r, o.g, o.b],
    icon: ic.file, iconColour: hex(ic), d: +cost[i][assign[i]].toFixed(3), grey: ic.grey };
});
const total = rows.reduce((s, r) => s + r.d, 0);
const used = new Set(rows.map((r) => r.icon));
const leftovers = pool.filter((i) => !used.has(i.file)).map((i) => i.file);

console.log(`total cost ${total.toFixed(2)}, mean ${(total / rows.length).toFixed(3)}`);
console.log("\nworst 10 (check by eye):");
[...rows].sort((a, b) => b.d - a.d).slice(0, 10).forEach((r) =>
  console.log(`  d=${r.d.toFixed(3)}  t${String(r.tier).padStart(2)} ${r.name.padEnd(12)} ore ${r.ore}  <-  ${r.icon} ${r.iconColour}`));
console.log("\nbest 6:");
[...rows].sort((a, b) => a.d - b.d).slice(0, 6).forEach((r) =>
  console.log(`  d=${r.d.toFixed(3)}  t${String(r.tier).padStart(2)} ${r.name.padEnd(12)} ore ${r.ore}  <-  ${r.icon} ${r.iconColour}`));
console.log("\nunused:", leftovers.join(", ") || "(none)");

fs.writeFileSync(OUT, JSON.stringify({ starter: STARTER, rows, leftovers }, null, 1));

// ------------------------------------------------- the proposal sheet --
// Each icon drawn on a swatch of its ore's colour, in tier order. If the pairing
// is wrong the icon fights its background, which no table makes as obvious.
const COLS = 8, CELL = 120, BAR = 14;
const ROWS = Math.ceil(rows.length / COLS);
const W = COLS * CELL, H = ROWS * CELL;
const sheet = Buffer.alloc(W * H * 4);
rows.forEach((row, i) => {
  const cx = (i % COLS) * CELL, cy = Math.floor(i / COLS) * CELL;
  const [orr, org, orb] = row.oreRGB;
  for (let y = 0; y < CELL; y++) {
    for (let x = 0; x < CELL; x++) {
      const d = ((cy + y) * W + (cx + x)) * 4;
      // ore colour as a bar across the bottom, dark field above it
      const onBar = y >= CELL - BAR;
      sheet[d] = onBar ? orr : 26;
      sheet[d + 1] = onBar ? org : 22;
      sheet[d + 2] = onBar ? orb : 48;
      sheet[d + 3] = 255;
    }
  }
  const im = imgs.get(row.icon);
  const box = CELL - BAR - 10, sc = Math.min(box / im.w, box / im.h);
  const dw = Math.round(im.w * sc), dh = Math.round(im.h * sc);
  const ox = cx + Math.floor((CELL - dw) / 2), oy = cy + Math.floor((CELL - BAR - dh) / 2);
  for (let y = 0; y < dh; y++) {
    for (let x = 0; x < dw; x++) {
      const sx = Math.min(im.w - 1, Math.floor(x / sc)), sy = Math.min(im.h - 1, Math.floor(y / sc));
      const s = (sy * im.w + sx) * 4, d = ((oy + y) * W + (ox + x)) * 4, a = im.data[s + 3] / 255;
      sheet[d] = Math.round(im.data[s] * a + sheet[d] * (1 - a));
      sheet[d + 1] = Math.round(im.data[s + 1] * a + sheet[d + 1] * (1 - a));
      sheet[d + 2] = Math.round(im.data[s + 2] * a + sheet[d + 2] * (1 - a));
    }
  }
});
const sheetPath = path.join(DIR, "proposal-sheet.png");
fs.writeFileSync(sheetPath, encodeRGBA(W, H, sheet));
console.log("\nwrote", OUT, "and", sheetPath);
