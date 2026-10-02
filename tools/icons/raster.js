// A tiny dependency-free raster surface and PNG encoder.
//
// Written rather than pulled in because this container has no canvas, sharp or
// pngjs, and the native ones need a toolchain. zlib is built into node, and a
// PNG is a handful of chunks around a deflate stream, so the whole thing is
// about a hundred lines and will keep working with no install step.
//
// Everything draws into an RGBA byte buffer at SS times the final size and is
// box-downsampled on the way out, which is the cheapest honest antialiasing
// there is: no edge cases, no coverage maths, and it treats every primitive the
// same way.
const zlib = require("zlib");

const SS = 3; // supersample factor

class Surface {
  constructor(size) {
    this.size = size;
    this.w = size * SS;
    this.h = size * SS;
    this.px = Buffer.alloc(this.w * this.h * 4, 0);
  }

  // Straight source-over alpha blend. a is 0..1.
  blend(x, y, [r, g, b], a) {
    if (a <= 0 || x < 0 || y < 0 || x >= this.w || y >= this.h) return;
    const i = (y * this.w + x) * 4;
    const sa = this.px[i + 3] / 255;
    const oa = a + sa * (1 - a);
    if (oa <= 0) return;
    this.px[i] = Math.round((r * a + this.px[i] * sa * (1 - a)) / oa);
    this.px[i + 1] = Math.round((g * a + this.px[i + 1] * sa * (1 - a)) / oa);
    this.px[i + 2] = Math.round((b * a + this.px[i + 2] * sa * (1 - a)) / oa);
    this.px[i + 3] = Math.round(oa * 255);
  }

  //[[
  //  Fill where test(x, y) is true. Every shape goes through this, so a new
  //  primitive is a predicate rather than a new blending path.
  //
  //  `box` is the primitive's own bounds in supersampled pixels, and it is not
  //  an optimisation detail -- without it this scans the whole 1536x1536 surface
  //  once per primitive, which at ~15 primitives x 164 icons is minutes rather
  //  than seconds. A glyph covers about a twelfth of the plate.
  //]]
  fill(test, colour, alpha = 1, box = null) {
    const x0 = Math.max(0, Math.floor(box ? box[0] : 0));
    const y0 = Math.max(0, Math.floor(box ? box[1] : 0));
    const x1 = Math.min(this.w, Math.ceil(box ? box[2] : this.w));
    const y1 = Math.min(this.h, Math.ceil(box ? box[3] : this.h));
    for (let y = y0; y < y1; y++) {
      for (let x = x0; x < x1; x++) {
        const a = test(x + 0.5, y + 0.5);
        if (a > 0) this.blend(x, y, colour, alpha * (a === true ? 1 : a));
      }
    }
  }

  roundedRect(x, y, w, h, r, colour, alpha = 1) {
    const s = SS;
    [x, y, w, h, r] = [x * s, y * s, w * s, h * s, r * s];
    this.fill((px, py) => {
      if (px < x || py < y || px > x + w || py > y + h) return 0;
      const cx = Math.min(Math.max(px, x + r), x + w - r);
      const cy = Math.min(Math.max(py, y + r), y + h - r);
      return (px - cx) ** 2 + (py - cy) ** 2 <= r * r ? 1 : 0;
    }, colour, alpha, [x, y, x + w, y + h]);
  }

  disc(cx, cy, rad, colour, alpha = 1) {
    const s = SS;
    [cx, cy, rad] = [cx * s, cy * s, rad * s];
    this.fill((px, py) => ((px - cx) ** 2 + (py - cy) ** 2 <= rad * rad ? 1 : 0), colour, alpha,
      [cx - rad, cy - rad, cx + rad, cy + rad]);
  }

  ring(cx, cy, rad, width, colour, alpha = 1) {
    const s = SS;
    [cx, cy, rad, width] = [cx * s, cy * s, rad * s, width * s];
    const lo = (rad - width / 2) ** 2, hi = (rad + width / 2) ** 2;
    this.fill((px, py) => {
      const d = (px - cx) ** 2 + (py - cy) ** 2;
      return d >= lo && d <= hi ? 1 : 0;
    }, colour, alpha, [cx - rad - width, cy - rad - width, cx + rad + width, cy + rad + width]);
  }

  // Radial falloff, for the plate glow. `power` shapes how fast it dies.
  glow(cx, cy, rad, colour, alpha = 1, power = 2) {
    const s = SS;
    [cx, cy, rad] = [cx * s, cy * s, rad * s];
    this.fill((px, py) => {
      const d = Math.sqrt((px - cx) ** 2 + (py - cy) ** 2) / rad;
      if (d >= 1) return 0;
      return (1 - d) ** power;
    }, colour, alpha, [cx - rad, cy - rad, cx + rad, cy + rad]);
  }

  // Convex or concave polygon, even-odd rule.
  poly(points, colour, alpha = 1) {
    const s = SS;
    const pts = points.map(([x, y]) => [x * s, y * s]);
    let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
    for (const [x, y] of pts) {
      minX = Math.min(minX, x); maxX = Math.max(maxX, x);
      minY = Math.min(minY, y); maxY = Math.max(maxY, y);
    }
    this.fill((px, py) => {
      if (px < minX || px > maxX || py < minY || py > maxY) return 0;
      let inside = false;
      for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) {
        const [xi, yi] = pts[i], [xj, yj] = pts[j];
        if (yi > py !== yj > py && px < ((xj - xi) * (py - yi)) / (yj - yi) + xi) inside = !inside;
      }
      return inside ? 1 : 0;
    }, colour, alpha, [minX, minY, maxX, maxY]);
  }

  // Thick line segment, as a distance-to-segment test.
  line(x1, y1, x2, y2, width, colour, alpha = 1) {
    const s = SS;
    [x1, y1, x2, y2, width] = [x1 * s, y1 * s, x2 * s, y2 * s, width * s];
    const dx = x2 - x1, dy = y2 - y1;
    const len2 = dx * dx + dy * dy || 1;
    const half = width / 2;
    this.fill((px, py) => {
      let t = ((px - x1) * dx + (py - y1) * dy) / len2;
      t = Math.max(0, Math.min(1, t));
      const qx = x1 + t * dx, qy = y1 + t * dy;
      return (px - qx) ** 2 + (py - qy) ** 2 <= half * half ? 1 : 0;
    }, colour, alpha,
      [Math.min(x1, x2) - half, Math.min(y1, y2) - half,
       Math.max(x1, x2) + half, Math.max(y1, y2) + half]);
  }

  // Box-downsample to the final size, then encode.
  toPNG() {
    const n = this.size;
    const out = Buffer.alloc(n * (n * 4 + 1));
    for (let y = 0; y < n; y++) {
      out[y * (n * 4 + 1)] = 0; // filter: none
      for (let x = 0; x < n; x++) {
        let r = 0, g = 0, b = 0, a = 0;
        for (let sy = 0; sy < SS; sy++) {
          for (let sx = 0; sx < SS; sx++) {
            const i = ((y * SS + sy) * this.w + (x * SS + sx)) * 4;
            const pa = this.px[i + 3] / 255;
            r += this.px[i] * pa; g += this.px[i + 1] * pa; b += this.px[i + 2] * pa; a += pa;
          }
        }
        const k = SS * SS;
        const o = y * (n * 4 + 1) + 1 + x * 4;
        // Un-premultiply, so a soft edge keeps its colour instead of going dark.
        out[o] = a > 0 ? Math.round(r / a) : 0;
        out[o + 1] = a > 0 ? Math.round(g / a) : 0;
        out[o + 2] = a > 0 ? Math.round(b / a) : 0;
        out[o + 3] = Math.round((a / k) * 255);
      }
    }
    return encodePNG(n, n, out);
  }
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body) >>> 0);
  return Buffer.concat([len, body, crc]);
}

let TABLE = null;
function crc32(buf) {
  if (!TABLE) {
    TABLE = new Int32Array(256);
    for (let i = 0; i < 256; i++) {
      let c = i;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      TABLE[i] = c;
    }
  }
  let c = -1;
  for (let i = 0; i < buf.length; i++) c = TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return c ^ -1;
}

function encodePNG(w, h, raw) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8;  // bit depth
  ihdr[9] = 6;  // colour type: RGBA
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr),
    chunk("IDAT", zlib.deflateSync(raw, { level: 9 })),
    chunk("IEND", Buffer.alloc(0)),
  ]);
}

module.exports = { Surface, SS };
