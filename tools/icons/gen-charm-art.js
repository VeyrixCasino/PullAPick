// Draws one 256x256 PNG per charm into build/charm-icons/.
//
// THE READ IS: colour tells you WHICH ORE, glyph tells you WHAT IT DOES.
// That is the same construction the charms themselves use -- 82 ore colours x 6
// shapes -- so an ore's two variants share a colour and differ in glyph, which
// is exactly how they differ in play. The name says the same thing in words
// ("Stone Focus Charm"), so art and name cannot tell different stories.
//
// Shape and ore are read from the real modules (tools/icons/charm-data.js), not
// re-derived here, so the art cannot drift from the data.
//
// RARITY is the pip row along the bottom: one pip per band, Common 1 to Exotic
// 8. Deliberately counted rather than coloured -- a colour would fight the ore
// colour, which is already carrying identity.
//
//   node tools/icons/gen-charm-art.js [--only stone_charm] [--size 512]
//
// Output is art only. Uploading is a separate, manual step: every asset must be
// created as the Mine For Cards group (see docs/TODO.md section 7), which no
// agent here can do. tools/gen-charm-icons.js turns the uploaded ids into Luau.
const fs = require("fs");
const path = require("path");
const { Surface } = require("./raster.js");
const { load } = require("./charm-data.js");

const ROOT = path.resolve(__dirname, "../..");
const OUT = path.join(ROOT, "build/charm-icons");

const argv = process.argv.slice(2);
const argOf = (flag, dflt) => {
  const i = argv.indexOf(flag);
  return i >= 0 && argv[i + 1] ? argv[i + 1] : dflt;
};
const ONLY = argOf("--only", null);
// 256 is the shipping size, set by the owner. The ore icons are 512 authored
// art; these are generated geometry with no fine detail to lose, so the extra
// 4x of pixels bought nothing but file size and generation time.
const SIZE = Number(argOf("--size", 256));

const PLATE = [22, 22, 28];
const PLATE_EDGE = [44, 44, 56];
const INK = [250, 250, 255];
const SHADOW = [0, 0, 0];

// Lift a dark ore colour so the glow and ring still read on a dark plate. Onyx
// is 15,15,15; left alone it would be invisible against the plate.
function lift([r, g, b]) {
  const lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  if (lum >= 0.34) return [r, g, b];
  const k = 0.34 / Math.max(lum, 0.04);
  return [r, g, b].map((v) => Math.min(255, Math.round(18 + v * k)));
}

//----------------------------------------------------------------------------
// THE SIX GLYPHS. Each is drawn in a 0..1 box and scaled, so the same shape
// reads the same at any output size.
//----------------------------------------------------------------------------
const GLYPH = {
  // FOCUS -- everything in one place. One disc, one tight ring.
  focus(s, cx, cy, R, ink) {
    s.ring(cx, cy, R * 0.86, R * 0.13, ink, 0.55);
    s.disc(cx, cy, R * 0.52, ink);
  },

  // TWIN (pair) -- two stats, 60/40. Two discs, sized the same way.
  pair(s, cx, cy, R, ink) {
    s.disc(cx - R * 0.30, cy, R * 0.56, ink);
    s.disc(cx + R * 0.44, cy, R * 0.40, ink, 0.72);
  },

  // PACT -- it gives and it takes. A full half, and a half cut back to a thin
  // crescent: the shape of a trade rather than a gain.
  pact(s, cx, cy, R, ink) {
    {
      // A half-disc: the giving side. Written as a raw predicate because it is
      // the one shape here that is not a whole primitive, and it carries its own
      // bounds for the same reason every other primitive does.
      const SS = require("./raster.js").SS;
      const Cx = cx * SS, Cy = cy * SS, rad = R * 0.72 * SS;
      s.fill(
        (px, py) => ((px - Cx) ** 2 + (py - Cy) ** 2 <= rad * rad && px <= Cx ? 1 : 0),
        ink, 1, [Cx - rad, Cy - rad, Cx, Cy + rad]
      );
    }
    s.ring(cx, cy, R * 0.72, R * 0.14, ink, 0.6);
    // The bite taken out of the giving half, in plate colour.
    s.disc(cx + R * 0.34, cy, R * 0.30, PLATE, 1);
  },

  // WARD (condition) -- a shield. It protects you while something holds.
  //
  // Solid, with only a thin inner line. The first cut hollowed out most of the
  // body and the remaining outline read as a pennant, not a shield.
  condition(s, cx, cy, R, ink) {
    const w = R * 0.80, top = cy - R * 0.78, mid = cy + R * 0.16, tip = cy + R * 0.92;
    const body = [[cx - w, top], [cx + w, top], [cx + w, mid], [cx, tip], [cx - w, mid]];
    s.poly(body, ink);
    // A single inset line, thin enough to read as an engraving rather than a hole.
    const k = 0.70;
    const inner = body.map(([x, y]) => [cx + (x - cx) * k, cy + (y - cy) * k]);
    s.poly(inner, PLATE, 0.55);
    const k2 = 0.52;
    s.poly(body.map(([x, y]) => [cx + (x - cx) * k2, cy + (y - cy) * k2]), ink, 0.95);
  },

  // BRINK (threshold) -- a narrow window. An hourglass pinched almost shut.
  threshold(s, cx, cy, R, ink) {
    const w = R * 0.74, h = R * 0.86, pinch = R * 0.10;
    s.poly([[cx - w, cy - h], [cx + w, cy - h], [cx + pinch, cy], [cx - pinch, cy]], ink);
    s.poly([[cx - pinch, cy], [cx + pinch, cy], [cx + w, cy + h], [cx - w, cy + h]], ink);
  },

  // SURGE (ramp) -- it builds. Three bars climbing, the last brightest.
  ramp(s, cx, cy, R, ink) {
    const bw = R * 0.34, gap = R * 0.10;
    const heights = [0.40, 0.72, 1.06];
    const alphas = [0.45, 0.70, 1.0];
    for (let i = 0; i < 3; i++) {
      const x = cx + (i - 1) * (bw + gap);
      const h = R * heights[i];
      s.roundedRect(x - bw / 2, cy + R * 0.74 - h, bw, h, bw * 0.28, ink, alphas[i]);
    }
  },
};

function draw(charm) {
  const s = new Surface(SIZE);
  // Every number below is written in 512-space and scaled, so the layout is
  // identical at any output size and --size is a real knob rather than a crop.
  const u = SIZE / 512;
  const ore = lift(charm.rgb);
  const cx = SIZE / 2, cy = SIZE / 2;

  // Plate: a soft outer edge, then the face, so the icon has an edge of its own
  // against any background the UI puts it on.
  s.roundedRect(10 * u, 10 * u, 492 * u, 492 * u, 92 * u, PLATE_EDGE);
  s.roundedRect(18 * u, 18 * u, 476 * u, 476 * u, 86 * u, PLATE);

  //[[
  //  The ore's colour has to carry identity, so it is the loudest thing on the
  //  plate after the glyph. The first pass washed it in at half alpha and a grey
  //  ore like Stone came out indistinguishable from the bare plate -- which
  //  defeats the point, since colour is the half of the read that says WHICH ore.
  //
  //  It is a filled disc with a glow over it now, not a glow alone.
  //]]
  s.disc(cx, cy, 186 * u, ore, 0.22);
  s.glow(cx, cy - 10 * u, 250 * u, ore, 0.78, 1.5);
  s.glow(cx, cy - 10 * u, 130 * u, ore, 0.55, 2.2);
  // A dark pool directly under the glyph, so white ink keeps its contrast over
  // the brightest ores (Limestone and Celestine are nearly white themselves).
  s.glow(cx, cy, 150 * u, [8, 8, 12], 0.55, 1.5);

  // Identity ring. Thicker as the band climbs, so rarity is felt before it is
  // counted on the pips.
  const ringW = (10 + charm.bandIndex * 1.9) * u;
  s.ring(cx, cy, 196 * u, ringW, ore, 0.95);
  s.ring(cx, cy, 196 * u - ringW * 0.9, 2.5 * u, [255, 255, 255], 0.22);

  // Glyph, with a drop shadow so it holds up over the brightest ore colours.
  const R = 112 * u;
  const g = GLYPH[charm.shape];
  if (!g) throw new Error(`no glyph for shape "${charm.shape}" (charm ${charm.id})`);
  g(s, cx + 4 * u, cy + 5 * u, R, SHADOW);
  g(s, cx, cy, R, INK);

  // Rarity pips: bandIndex of them, centred along the bottom.
  const n = Math.max(1, Math.min(8, charm.bandIndex));
  const pipR = 11 * u, pipGap = 30 * u;
  const total = (n - 1) * pipGap;
  const pipY = SIZE - 52 * u;
  // A dark lozenge behind the row, so the pips read on a bright plate too.
  s.roundedRect(cx - total / 2 - pipR * 2.1, pipY - pipR * 1.9,
    total + pipR * 4.2, pipR * 3.8, pipR * 1.9, [10, 10, 14], 0.72);
  for (let i = 0; i < n; i++) {
    const x = cx - total / 2 + i * pipGap;
    s.disc(x, pipY, pipR, [255, 255, 255], 0.92);
    s.disc(x, pipY, pipR * 0.58, ore, 1);
  }

  return s.toPNG();
}

function main() {
  const { charms } = load();
  const todo = ONLY ? charms.filter((c) => c.id === ONLY) : charms;
  if (!todo.length) {
    console.error(ONLY ? `no charm with id "${ONLY}"` : "no charms to draw");
    process.exit(1);
  }
  fs.mkdirSync(OUT, { recursive: true });

  const manifest = [];
  let bytes = 0;
  for (const c of todo) {
    const png = draw(c);
    const file = path.join(OUT, `${c.id}.png`);
    fs.writeFileSync(file, png);
    bytes += png.length;
    manifest.push({
      id: c.id, name: c.name, oreId: c.oreId, variant: c.variant,
      shape: c.shape, band: c.band, bandIndex: c.bandIndex, rgb: c.rgb,
      file: `build/charm-icons/${c.id}.png`,
    });
  }
  if (!ONLY) {
    fs.writeFileSync(path.join(OUT, "manifest.json"), JSON.stringify(manifest, null, "\t") + "\n");
  }
  console.log(`>>> ${todo.length} icons at ${SIZE}x${SIZE} -> build/charm-icons/  (${(bytes / 1024 / 1024).toFixed(2)} MB)`);
  if (!ONLY) console.log(">>> manifest.json written; upload as the group, then run tools/gen-charm-icons.js");
}

main();
