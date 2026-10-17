// Tile the 18 extracted charm icons into one contact sheet, so the art can be
// looked at in a single image instead of eighteen.
//
// Pure Node: PNG is zlib-deflated filtered scanlines, and `zlib` is built in.
// There is no ImageMagick, Python or sharp on this machine (tools/icons/raster.js
// exists for the same reason) -- so decode, tile and re-encode by hand.
//
// Usage: node tools/icons/charm-sheet.js <inDir> <outFile> [cols]
const fs = require("fs"), path = require("path"), zlib = require("zlib");

function decodePNG(buf) {
  if (buf.readUInt32BE(0) !== 0x89504e47) throw new Error("not a png");
  let p = 8, w = 0, h = 0, depth = 0, ctype = 0;
  const idat = [];
  let pal = null, trns = null;
  while (p < buf.length) {
    const len = buf.readUInt32BE(p), type = buf.toString("ascii", p + 4, p + 8);
    const data = buf.subarray(p + 8, p + 8 + len);
    if (type === "IHDR") {
      w = data.readUInt32BE(0); h = data.readUInt32BE(4);
      depth = data[8]; ctype = data[9];
      if (data[12] !== 0) throw new Error("interlaced png not supported");
    } else if (type === "IDAT") idat.push(data);
    else if (type === "PLTE") pal = data;
    else if (type === "tRNS") trns = data;
    else if (type === "IEND") break;
    p += 12 + len;
  }
  if (depth !== 8) throw new Error("only 8-bit depth supported, got " + depth);
  const channels = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 }[ctype];
  if (!channels) throw new Error("unsupported colour type " + ctype);
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = w * channels;
  const out = Buffer.alloc(w * h * 4);
  let prev = Buffer.alloc(stride);
  for (let y = 0; y < h; y++) {
    const filter = raw[y * (stride + 1)];
    const line = Buffer.from(raw.subarray(y * (stride + 1) + 1, y * (stride + 1) + 1 + stride));
    // Un-filter in place; bpp is the byte distance to the left neighbour.
    const bpp = channels;
    for (let i = 0; i < stride; i++) {
      const a = i >= bpp ? line[i - bpp] : 0, b = prev[i], c = i >= bpp ? prev[i - bpp] : 0;
      let v = line[i];
      if (filter === 1) v += a;
      else if (filter === 2) v += b;
      else if (filter === 3) v += (a + b) >> 1;
      else if (filter === 4) {
        const pp = a + b - c, pa = Math.abs(pp - a), pb = Math.abs(pp - b), pc = Math.abs(pp - c);
        v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c);
      }
      line[i] = v & 0xff;
    }
    prev = line;
    for (let x = 0; x < w; x++) {
      const o = (y * w + x) * 4;
      if (ctype === 6) { line.copy(out, o, x * 4, x * 4 + 4); }
      else if (ctype === 2) { out[o] = line[x * 3]; out[o + 1] = line[x * 3 + 1]; out[o + 2] = line[x * 3 + 2]; out[o + 3] = 255; }
      else if (ctype === 0) { const g = line[x]; out[o] = out[o + 1] = out[o + 2] = g; out[o + 3] = 255; }
      else if (ctype === 4) { const g = line[x * 2]; out[o] = out[o + 1] = out[o + 2] = g; out[o + 3] = line[x * 2 + 1]; }
      else if (ctype === 3) {
        const idx = line[x];
        out[o] = pal[idx * 3]; out[o + 1] = pal[idx * 3 + 1]; out[o + 2] = pal[idx * 3 + 2];
        out[o + 3] = trns && idx < trns.length ? trns[idx] : 255;
      }
    }
  }
  return { w, h, px: out };
}

function crc32(b) {
  let c, t = crc32.t;
  if (!t) {
    t = crc32.t = [];
    for (let n = 0; n < 256; n++) { c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; }
  }
  c = 0xffffffff;
  for (let i = 0; i < b.length; i++) c = t[(c ^ b[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
function encodePNG(w, h, px) {
  const raw = Buffer.alloc(h * (w * 4 + 1));
  for (let y = 0; y < h; y++) {
    raw[y * (w * 4 + 1)] = 0;
    px.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr), chunk("IDAT", zlib.deflateSync(raw, { level: 9 })), chunk("IEND", Buffer.alloc(0)),
  ]);
}

const inDir = process.argv[2] || ".";
const outFile = process.argv[3] || "charm-sheet.png";
const cols = parseInt(process.argv[4] || "6", 10);

const files = fs.readdirSync(inDir).filter((f) => /\.png$/i.test(f)).sort();
if (!files.length) { console.error("no pngs in " + inDir); process.exit(1); }
const imgs = files.map((f) => ({ f, ...decodePNG(fs.readFileSync(path.join(inDir, f))) }));

// Uniform cells, each icon centred, on a mid grey so both light and dark art reads.
const PAD = 10, LABEL = 16;
const cw = Math.max(...imgs.map((i) => i.w)) + PAD * 2;
const ch = Math.max(...imgs.map((i) => i.h)) + PAD * 2 + LABEL;
const rows = Math.ceil(imgs.length / cols);
const W = cw * cols, H = ch * rows;
const sheet = Buffer.alloc(W * H * 4);
for (let i = 0; i < W * H; i++) { sheet[i * 4] = 70; sheet[i * 4 + 1] = 72; sheet[i * 4 + 2] = 78; sheet[i * 4 + 3] = 255; }

imgs.forEach((img, i) => {
  const cx = (i % cols) * cw, cy = Math.floor(i / cols) * ch;
  const ox = cx + Math.floor((cw - img.w) / 2), oy = cy + LABEL + Math.floor((ch - LABEL - img.h) / 2);
  // A bright bar whose length encodes the index, so each cell is identifiable
  // without needing a font: cell n gets n ticks along its top edge.
  const n = i + 1;
  for (let t = 0; t < n; t++) {
    for (let dx = 0; dx < 6; dx++) for (let dy = 0; dy < 6; dy++) {
      const x = cx + 4 + t * 8 + dx, y = cy + 4 + dy;
      if (x < W && y < H) { const o = (y * W + x) * 4; sheet[o] = 255; sheet[o + 1] = 210; sheet[o + 2] = 90; sheet[o + 3] = 255; }
    }
  }
  for (let y = 0; y < img.h; y++) {
    for (let x = 0; x < img.w; x++) {
      const s = (y * img.w + x) * 4, a = img.px[s + 3];
      if (!a) continue;
      const X = ox + x, Y = oy + y;
      if (X < 0 || Y < 0 || X >= W || Y >= H) continue;
      const d = (Y * W + X) * 4, k = a / 255;
      sheet[d] = Math.round(img.px[s] * k + sheet[d] * (1 - k));
      sheet[d + 1] = Math.round(img.px[s + 1] * k + sheet[d + 1] * (1 - k));
      sheet[d + 2] = Math.round(img.px[s + 2] * k + sheet[d + 2] * (1 - k));
    }
  }
});

fs.writeFileSync(outFile, encodePNG(W, H, sheet));
console.log(`${imgs.length} icons -> ${outFile}  ${W}x${H}`);
console.log("order: " + files.join(" "));
