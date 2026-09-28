// Ten ore face masks, as pixel art, written straight to PNG.
//
// Greyscale + alpha rather than colour: the block tints the texture per ore
// (Texture.Color3 multiplies), so one mask serves all 121 ores and the
// highlight/shadow inside each blob survives the tint as lighter and darker
// shades of that ore's own colour.
const fs = require("fs"), zlib = require("zlib"), path = require("path");

const GRID = 16;    // design resolution, same as the reference art
const SCALE = 4;    // nearest-neighbour upscale -> 64px, keeps the pixels hard
const OUT = path.join(__dirname, "..", "build", "ore-textures");

// ---- minimal RGBA PNG ----
const CRC = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c;
  }
  return buf => {
    let c = -1;
    for (const b of buf) c = t[(c ^ b) & 0xff] ^ (c >>> 8);
    return (c ^ -1) >>> 0;
  };
})();
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(CRC(td));
  return Buffer.concat([len, td, crc]);
}
function png(w, h, rgba) {
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) {
    raw[y * (w * 4 + 1)] = 0;
    rgba.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr),
    chunk("IDAT", zlib.deflateSync(raw, { level: 9 })),
    chunk("IEND", Buffer.alloc(0))
  ]);
}

// ---- drawing ----
// value 0 = empty. otherwise a grey: 255 highlight, 205 base, 150 shade, 105 edge.
const HI = 255, BASE = 205, SHADE = 150, EDGE = 105;

function blank() { return Array.from({ length: GRID }, () => new Array(GRID).fill(0)); }

// A rounded, slightly squared blob with light from the upper left. `squash`
// stretches it, `ang` rotates that stretch, which is what makes a streak.
function blob(px, cx, cy, r, squash = 1, ang = 0) {
  const ca = Math.cos(ang), sa = Math.sin(ang);
  const R = Math.ceil(r * Math.max(1, squash)) + 1;
  for (let y = Math.floor(cy - R); y <= Math.ceil(cy + R); y++) {
    for (let x = Math.floor(cx - R); x <= Math.ceil(cx + R); x++) {
      if (x < 0 || y < 0 || x >= GRID || y >= GRID) continue;
      const dx0 = x + 0.5 - cx, dy0 = y + 0.5 - cy;
      const dx = (dx0 * ca + dy0 * sa) / squash;
      const dy = -dx0 * sa + dy0 * ca;
      // superellipse: rounder than a diamond, squarer than a circle
      const d = Math.pow(Math.abs(dx), 2.6) + Math.pow(Math.abs(dy), 2.6);
      const rr = Math.pow(r, 2.6);
      if (d > rr) continue;
      const lit = (-dx0 - dy0) / Math.max(r, 0.001);   // upper-left light
      let v;
      if (d > rr * 0.62) v = EDGE;
      else if (lit > 0.42) v = HI;
      else if (lit < -0.3) v = SHADE;
      else v = BASE;
      px[y][x] = Math.max(px[y][x], v);
    }
  }
}

// ---- the ten layouts, read off the reference sheet ----
const LAYOUTS = {
  // cx, cy, r, squash, angle
  Scatter: [[3.5,3,2.1],[9.5,2.5,1.7],[13,5,1.5],[2.5,9,1.6],[7,8.5,2.2],[12,11,1.9],[4.5,13.5,1.4]],
  Cluster: [[7.5,7,2.6],[4,4.5,1.8],[11,4.5,1.6],[4.5,11,1.7],[11.5,11,2.0],[8,2,1.1],[2,7.5,1.0]],
  Coarse:  [[4.5,4.5,2.9],[11.5,4,2.4],[4,11.5,2.5],[11.5,11.5,2.8]],
  Fine:    [[2.5,2.5,1.0],[6,3.5,0.9],[10,2,1.0],[13.5,4,0.9],[3.5,6.5,0.9],[8,7,1.1],
            [12,8,0.9],[2,10.5,1.0],[6.5,11,0.9],[10.5,12,1.0],[13.5,13,0.9],[4.5,14,0.8]],
  Streak:  [[4,4,2.0,2.4,-0.7],[10.5,8,2.1,2.4,-0.7],[6,12.5,1.8,2.2,-0.7]],
  Twin:    [[5,5.5,3.0],[11,10.5,2.7],[12,3.5,1.2],[3,11.5,1.1],[8.5,2,0.9]],
  Ring:    [[3,3,1.9],[8,2,1.5],[13,3.5,1.8],[13.5,8.5,1.6],[12.5,13,1.9],
            [7.5,14,1.5],[2.5,12.5,1.8],[2,7.5,1.6]],
  Drift:   [[2.5,12.5,1.8],[5.5,9.5,2.1],[8.5,6.5,2.3],[11.5,3.5,2.0],[13.5,9,1.3],[4,4.5,1.2]],
  Dense:   [[3,3,1.9],[8,3.5,1.8],[13,3,1.7],[3.5,8,1.8],[8.5,8,2.1],[13,8.5,1.7],
            [3,13,1.7],[8,13,1.8],[13,13,1.9]],
  Nugget:  [[4.5,4,2.6,1.35,0.4],[11,6,2.3,1.3,-0.3],[6.5,11.5,2.5,1.4,-0.2],[12.5,12,1.9,1.25,0.5]]
};

fs.mkdirSync(OUT, { recursive: true });
const made = [];
for (const [name, spots] of Object.entries(LAYOUTS)) {
  const px = blank();
  for (const [cx, cy, r, sq, ang] of spots) blob(px, cx, cy, r, sq || 1, ang || 0);
  const W = GRID * SCALE;
  const rgba = Buffer.alloc(W * W * 4);
  let lit = 0;
  for (let y = 0; y < W; y++) {
    for (let x = 0; x < W; x++) {
      const v = px[Math.floor(y / SCALE)][Math.floor(x / SCALE)];
      const o = (y * W + x) * 4;
      rgba[o] = rgba[o + 1] = rgba[o + 2] = v;
      rgba[o + 3] = v > 0 ? 255 : 0;
      if (v > 0) lit++;
    }
  }
  const file = path.join(OUT, name + ".png");
  fs.writeFileSync(file, png(W, W, rgba));
  made.push({ name, file, cover: (lit / (W * W) * 100).toFixed(0) });
}
console.log("wrote " + made.length + " masks to build/ore-textures (" + GRID * SCALE + "px):");
for (const m of made) console.log("  " + m.name.padEnd(9) + m.cover.padStart(3) + "% ore coverage");
console.log("\npaths:");
made.forEach(m => console.log(m.file));
