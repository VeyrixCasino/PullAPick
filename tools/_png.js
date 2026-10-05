// Zero-dependency PNG codec shared by the sheet tools (8-bit, non-interlaced).
// Same code as tools/slice-ore-sheet.js, which still carries its own copy.
const fs = require("fs"), zlib = require("zlib");

// ---- PNG read (8-bit, non-interlaced) ----
function decode(file) {
  const b = Buffer.isBuffer(file) ? file : fs.readFileSync(file);
  let p = 8, idat = [], w = 0, h = 0, ct = 6, bd = 8, pal = null, trns = null;
  while (p < b.length) {
    const len = b.readUInt32BE(p), type = b.toString("ascii", p + 4, p + 8);
    const data = b.slice(p + 8, p + 8 + len);
    if (type === "IHDR") {
      w = data.readUInt32BE(0); h = data.readUInt32BE(4);
      bd = data[8]; ct = data[9];
      if (data[12] !== 0) throw new Error("interlaced PNG not supported");
      if (bd !== 8) throw new Error("only 8-bit supported, got " + bd);
    } else if (type === "PLTE") pal = data;
    else if (type === "tRNS") trns = data;
    else if (type === "IDAT") idat.push(data);
    else if (type === "IEND") break;
    p += 12 + len;
  }
  const ch = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 }[ct];
  if (!ch) throw new Error("colour type " + ct + " unsupported");
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = w * ch;
  const out = Buffer.alloc(h * stride);
  let pos = 0;
  for (let y = 0; y < h; y++) {
    const f = raw[pos++];
    const line = raw.slice(pos, pos + stride); pos += stride;
    const cur = out.slice(y * stride, (y + 1) * stride);
    const prev = y > 0 ? out.slice((y - 1) * stride, y * stride) : Buffer.alloc(stride);
    for (let i = 0; i < stride; i++) {
      const a = i >= ch ? cur[i - ch] : 0, bb = prev[i], c = i >= ch ? prev[i - ch] : 0;
      let v = line[i];
      if (f === 1) v += a;
      else if (f === 2) v += bb;
      else if (f === 3) v += (a + bb) >> 1;
      else if (f === 4) {
        const pp = a + bb - c, pa = Math.abs(pp - a), pb = Math.abs(pp - bb), pc = Math.abs(pp - c);
        v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? bb : c);
      }
      cur[i] = v & 0xff;
    }
  }
  // normalise to RGBA
  const rgba = Buffer.alloc(w * h * 4);
  for (let i = 0; i < w * h; i++) {
    let r, g, bl, al = 255;
    if (ct === 6) { r = out[i*4]; g = out[i*4+1]; bl = out[i*4+2]; al = out[i*4+3]; }
    else if (ct === 2) { r = out[i*3]; g = out[i*3+1]; bl = out[i*3+2]; }
    else if (ct === 0) { r = g = bl = out[i]; }
    else if (ct === 4) { r = g = bl = out[i*2]; al = out[i*2+1]; }
    else { const k = out[i]; r = pal[k*3]; g = pal[k*3+1]; bl = pal[k*3+2]; if (trns && k < trns.length) al = trns[k]; }
    rgba[i*4] = r; rgba[i*4+1] = g; rgba[i*4+2] = bl; rgba[i*4+3] = al;
  }
  return { w, h, d: rgba };
}

// ---- PNG write ----
const CRC = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c; }
  return buf => { let c = -1; for (const x of buf) c = t[(c ^ x) & 0xff] ^ (c >>> 8); return (c ^ -1) >>> 0; };
})();
function chunk(type, data) {
  const l = Buffer.alloc(4); l.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const c = Buffer.alloc(4); c.writeUInt32BE(CRC(td));
  return Buffer.concat([l, td, c]);
}
function encode(w, h, rgba) {
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) { raw[y*(w*4+1)] = 0; rgba.copy(raw, y*(w*4+1)+1, y*w*4, (y+1)*w*4); }
  const ih = Buffer.alloc(13);
  ih.writeUInt32BE(w, 0); ih.writeUInt32BE(h, 4); ih[8] = 8; ih[9] = 6;
  return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]), chunk("IHDR", ih),
    chunk("IDAT", zlib.deflateSync(raw, { level: 9 })), chunk("IEND", Buffer.alloc(0))]);
}

module.exports = { decode, encode };
