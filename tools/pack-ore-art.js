// Pack the 30 ore faces into Luau source, so the art needs no uploaded asset.
//
// Uploaded images turned out to be a dead end: the place is group-owned and
// anything upload_image produces is user-owned, so the experience cannot load
// it. Roblox can build an image at runtime from raw pixels instead
// (AssetService:CreateEditableImage + Texture.TextureContent), which removes
// the ownership question entirely -- the art lives in the repo.
//
// Pixel art compresses hard: few colours, long runs. Each tile becomes a
// palette plus a run-length stream over palette indices, base64'd.
const fs = require("fs"), zlib = require("zlib"), path = require("path");
const IN = path.join(__dirname, "..", "build", "ore-sheet");
const OUT = path.join(__dirname, "..", "src/ReplicatedStorage/Mine/Shared/MineOreArt.luau");

function decode(file) {
  const b = fs.readFileSync(file);
  let p = 8, idat = [], w = 0, h = 0;
  while (p < b.length) {
    const len = b.readUInt32BE(p), t = b.toString("ascii", p + 4, p + 8);
    if (t === "IHDR") { w = b.readUInt32BE(p + 8); h = b.readUInt32BE(p + 12); }
    if (t === "IDAT") idat.push(b.slice(p + 8, p + 8 + len));
    p += 12 + len;
  }
  const raw = zlib.inflateSync(Buffer.concat(idat)), st = w * 4, o = Buffer.alloc(h * st);
  let q = 0;
  for (let y = 0; y < h; y++) {
    const f = raw[q++], ln = raw.slice(q, q + st); q += st;
    const c = o.slice(y * st, (y + 1) * st);
    const pr = y > 0 ? o.slice((y - 1) * st, y * st) : Buffer.alloc(st);
    for (let i = 0; i < st; i++) {
      const a = i >= 4 ? c[i - 4] : 0, bb = pr[i], cc = i >= 4 ? pr[i - 4] : 0;
      let v = ln[i];
      if (f === 1) v += a; else if (f === 2) v += bb;
      else if (f === 3) v += (a + bb) >> 1;
      else if (f === 4) {
        const pp = a + bb - cc, pa = Math.abs(pp - a), pb = Math.abs(pp - bb), pc = Math.abs(pp - cc);
        v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? bb : cc);
      }
      c[i] = v & 255;
    }
  }
  return { w, h, d: o };
}

const SIZE = 32;   // logical resolution; the art reads well below this
const tiles = [];
for (let n = 1; n <= 30; n++) {
  const img = decode(path.join(IN, 'ore_' + String(n).padStart(2, '0') + '.png'));
  const { w, h, d } = img;
  //[[ The source is antialiased, so a straight read gives ~2000 colours for
  //   what is visually a handful. Take the MODE of each logical pixel's block
  //   instead of a sample, after snapping channels to 5 bits -- that collapses
  //   the halo pixels onto the colour they were smeared from. ]]
  const snap = v => Math.min(255, (v >> 3) << 3);
  const idx = new Uint8Array(SIZE * SIZE);
  const map = new Map([['t', 0]]);
  const pal = [[0, 0, 0, 0]];
  for (let y = 0; y < SIZE; y++) {
    for (let x = 0; x < SIZE; x++) {
      const x0 = Math.floor(x * w / SIZE), x1 = Math.max(x0 + 1, Math.floor((x + 1) * w / SIZE));
      const y0 = Math.floor(y * h / SIZE), y1 = Math.max(y0 + 1, Math.floor((y + 1) * h / SIZE));
      const tally = new Map();
      let clear = 0, total = 0;
      for (let yy = y0; yy < y1; yy++) for (let xx = x0; xx < x1; xx++) {
        const o = (yy * w + xx) * 4; total++;
        if (d[o + 3] < 128) { clear++; continue; }
        const k = snap(d[o]) + ',' + snap(d[o+1]) + ',' + snap(d[o+2]);
        tally.set(k, (tally.get(k) || 0) + 1);
      }
      if (clear > total / 2 || tally.size === 0) { idx[y * SIZE + x] = 0; continue; }
      let best = null, bc = -1;
      for (const [k, c] of tally) if (c > bc) { bc = c; best = k; }
      let pi = map.get(best);
      if (pi === undefined) { pi = pal.length; map.set(best, pi); pal.push([...best.split(',').map(Number), 255]); }
      idx[y * SIZE + x] = pi;
    }
  }
  //[[ A few tiles -- the rainbow one especially -- still carry more than a byte
  //   of palette after snapping. Keep the colours that cover the most pixels
  //   and fold the rest onto their nearest survivor, which is invisible at this
  //   size because the ones being dropped are single-pixel halo shades. ]]
  if (pal.length > 256) {
    const use = new Array(pal.length).fill(0);
    for (const v of idx) use[v]++;
    const keep = pal.map((c, i) => ({ i, c, n: use[i] }))
      .filter(e => e.i !== 0)
      .sort((a, b) => b.n - a.n)
      .slice(0, 255);
    const keepSet = new Map(keep.map((e, k) => [e.i, k + 1]));
    const near = new Map();
    for (let i = 1; i < pal.length; i++) {
      if (keepSet.has(i)) { near.set(i, keepSet.get(i)); continue; }
      let best = 1, bd = Infinity;
      for (const e of keep) {
        const d2 = (pal[i][0]-e.c[0])**2 + (pal[i][1]-e.c[1])**2 + (pal[i][2]-e.c[2])**2;
        if (d2 < bd) { bd = d2; best = keepSet.get(e.i); }
      }
      near.set(i, best);
    }
    for (let i = 0; i < idx.length; i++) if (idx[i] !== 0) idx[i] = near.get(idx[i]);
    const np = [[0,0,0,0]];
    for (const e of keep) np.push(e.c);
    pal.length = 0; pal.push(...np);
  }
  if (pal.length > 256) throw new Error('tile ' + n + ' still has ' + pal.length + ' colours');
  const rle = [];
  let cur = idx[0], run = 1;
  for (let i = 1; i < idx.length; i++) {
    if (idx[i] === cur && run < 255) run++;
    else { rle.push(cur, run); cur = idx[i]; run = 1; }
  }
  rle.push(cur, run);
  tiles.push({ n, w: SIZE, h: SIZE, pal, rle: Buffer.from(rle) });
}

const b64 = b => b.toString("base64");
const lines = tiles.map(t => {
  const pal = t.pal.map(c => "{" + c.join(",") + "}").join(",");
  return "\t{ w = " + t.w + ", h = " + t.h + ", pal = {" + pal + '}, rle = "' + b64(t.rle) + '" },';
});
const bytes = tiles.reduce((s, t) => s + t.rle.length + t.pal.length * 4, 0);

const src = `--!strict
--[[
	ORE FACE ART, as pixels rather than assets.

	Thirty hand-drawn ore faces, packed as a palette plus a run-length stream
	and rebuilt at runtime with AssetService:CreateEditableImage. Nothing here
	is an uploaded asset, which is the entire point: this place belongs to a
	GROUP, and anything the upload tooling produces belongs to a USER, so the
	experience could not load it -- Roblox rendered nothing and raised nothing.
	Art that ships in the source has no owner to argue with.

	Images are built lazily and cached, so a face costs one decode the first
	time an ore of that face is seen and nothing after.

	EditableImage does not replicate, so this runs where things are drawn: the
	CLIENT builds the image and hangs Textures on the ore part. The server only
	stamps OreId, which it already did.

	Regenerate with tools/pack-ore-art.js.
]]

local AssetService = game:GetService("AssetService")

local MineOreArt = {}

-- w/h, a palette (index 0 is always transparent), and RLE pairs of
-- (paletteIndex, runLength) over the pixels, base64'd.
local TILES = {
${lines.join("\n")}
}

MineOreArt.COUNT = #TILES

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local LOOKUP = {}
for i = 1, #B64 do
	LOOKUP[string.byte(B64, i)] = i - 1
end

local function unbase64(s: string): buffer
	local clean = (s:gsub("=", ""))
	local outLen = (#clean * 6) // 8
	local out = buffer.create(outLen)
	local acc, bits, at = 0, 0, 0
	for i = 1, #clean do
		local v = LOOKUP[string.byte(clean, i)]
		if v then
			acc = acc * 64 + v
			bits += 6
			if bits >= 8 then
				bits -= 8
				local byte = (acc // (2 ^ bits)) % 256
				buffer.writeu8(out, at, byte)
				at += 1
				acc = acc % (2 ^ bits)
			end
		end
	end
	return out
end

local cache: { [number]: any } = {}

--[[
	The EditableImage for a face, built once and kept.

	Returns nil rather than erroring when the API is unavailable, so a caller
	can fall back to a flat colour instead of taking the whole client down.
]]
function MineOreArt.image(index: number)
	local t = TILES[index]
	if not t then
		return nil
	end
	if cache[index] then
		return cache[index]
	end
	--[[ Roblox bilinear-filters a Texture and offers no pixelated mode for one,
	     so a 32px image renders as mush. Blowing each logical pixel up into a
	     SCALE x SCALE block leaves the filter almost nothing to smear across. ]]
	local SCALE = 8
	local W, H = t.w * SCALE, t.h * SCALE
	local ok, img = pcall(function()
		return AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
	end)
	if not ok or not img then
		return nil
	end
	local px = buffer.create(W * H * 4)
	local rle = unbase64(t.rle)
	local at = 0
	local i = 0
	while i < buffer.len(rle) - 1 do
		local pi = buffer.readu8(rle, i)
		local run = buffer.readu8(rle, i + 1)
		i += 2
		local c = t.pal[pi + 1]
		local r, g, b, a = c[1], c[2], c[3], c[4]
		for _ = 1, run do
			if at < t.w * t.h then
				local sx, sy = (at % t.w) * SCALE, (at // t.w) * SCALE
				for dy = 0, SCALE - 1 do
					local row = (sy + dy) * W + sx
					for dx = 0, SCALE - 1 do
						local o = (row + dx) * 4
						buffer.writeu8(px, o + 0, r)
						buffer.writeu8(px, o + 1, g)
						buffer.writeu8(px, o + 2, b)
						buffer.writeu8(px, o + 3, a)
					end
				end
				at += 1
			end
		end
	end
	local okW = pcall(function()
		img:WritePixelsBuffer(Vector2.zero, Vector2.new(W, H), px)
	end)
	if not okW then
		return nil
	end
	cache[index] = img
	return img
end

--[[
	Hang the face on all six sides of an ore block.

	Safe to call twice: it clears any faces already there, so a block that gets
	re-skinned does not end up with twelve textures fighting for the same side.
]]
local FACES = {
	Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Right,
	Enum.NormalId.Left, Enum.NormalId.Top, Enum.NormalId.Bottom,
}

function MineOreArt.apply(part: BasePart, index: number): boolean
	local img = MineOreArt.image(index)
	if not img then
		return false
	end
	for _, d in ipairs(part:GetChildren()) do
		if d.Name == "OreFace" then
			d:Destroy()
		end
	end
	local size = part.Size.X
	local content = Content.fromObject(img)
	for _, face in ipairs(FACES) do
		local tex = Instance.new("Texture")
		tex.Name = "OreFace"
		tex.Face = face
		tex.StudsPerTileU = size
		tex.StudsPerTileV = size
		tex.TextureContent = content
		tex.Parent = part
	end
	return true
end

return MineOreArt
`;
fs.writeFileSync(OUT, src);
console.log("30 tiles packed");
console.log("  pixel bytes if raw : " + (30 * 64 * 64 * 4 / 1024).toFixed(0) + " KB");
console.log("  packed             : " + (bytes / 1024).toFixed(1) + " KB");
console.log("  module             : " + (src.length / 1024).toFixed(1) + " KB");
console.log("  palettes           : " + tiles.map(t => t.pal.length).join(",").slice(0, 70) + "…");
console.log("\nwrote " + path.relative(path.join(__dirname, ".."), OUT));
