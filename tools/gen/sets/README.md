# The 19 exclusive sets: how a set is authored

Owner, 2026-10-10: 19 exclusive sets, each pet in them named by hand
(2,043 in all), and about 100 new bodies. Read `_sets.json` first: it lists
each set in the owner's order, with its grade, its rarity counts
(C U R E L M D X), its six packs and its theme, quoting the owner's own notes.

A set has two parts:

1. **`src/ReplicatedStorage/Mine/Shared/PetBodies/<Key>.luau`**: its new bodies.
2. **`tools/gen/sets/<key>.json`**: its names, palette, buff set and the bodies
   it uses.

`tools/gen/set-pets.js` turns these into the game data, and
`tools/verify/set-pets.js` checks it.

## 1. A body module

```lua
--[[ PetBodies/Pebblebound -- Pebblebound's bodies. See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block, ears = K.C3, K.block, K.ears
	local INK, WHITE, METAL, NEON = K.INK, K.WHITE, K.METAL, K.NEON
	local S = {}

	S.pb_pebblet = {
		label = "Pebblet",            -- shown in looks: "Granite Pebblet"
		set = "pebblebound",          -- the set key
		tint = C3(132, 128, 124),     -- default colour; each pet repaints it
		head = CFrame.new(0, 1.04, 0.06),   -- accessory anchors: top of head,
		neck = CFrame.new(0, -0.30, 0.62),  -- front low,
		back = CFrame.new(0, 0.20, -0.62),  -- rear
		-- scale = 1.2,               -- only if wide props shrink it (see FIT_SIZE)
		build = function(c, p)
			block(c, p, { shape = "round", tail = false })
			c:cone(Vector3.new(0.4, 0.5, 0.4), CFrame.new(0.3, 1.1, 0), p.dark)
		end,
	}

	return S
end
```

**Ids.** Prefix every species id with the set's `prefix` from `_sets.json`
(`pb_`, `sr_`, …), so ids never clash. `_species.txt` lists the ids already
taken. An id is data: never rename one once it ships.

**The kit (`K`).**
- Constants: `C3`, `PLASTIC`, `METAL`, `NEON`, `GLASS`, `SLATE`, `WOOD`, `INK`,
  `WHITE`, `NOSE`.
- Helpers: `block`, `ears`, `wings`, `spots`, `ridge`, and the table `SHAPES`.
- Read their code in `PetModelFactory.luau`: grep `^local function block`,
  `^local function ears`, and `^function Ctx:`.

**The canvas `c`.** Each call returns the Part it made.

| call | makes |
|---|---|
| `c:box(size, cf, colour, mat)` / `c:ovoid(...)` | a hard-edged block. `ovoid` is a box: the house style is cube pets, like Pet Simulator 99 |
| `c:ball(size, cf, colour, mat)` | a sphere |
| `c:round(size, cf, colour, mat)` | a softened block (Head mesh); use it for eyes and soft lumps |
| `c:cyl(size, cf, colour, mat)` | a cylinder whose axis is **X**. Rotate it with `CFrame.Angles(0, 0, math.pi / 2)` to stand it up |
| `c:cone(size, cf, colour, mat)` | a square pyramid, base at −Y and apex at +Y. Flip it with `CFrame.Angles(math.pi, 0, 0)` |
| `c:prism(size, cf, colour, mat)` | a prism mesh |
| `c:wedge(size, cf, colour, mat)` | a WedgePart |
| `c:rod(fromV3, toV3, radius, colour, mat, caps)` | a capsule between two points; `caps = false` skips the end balls |
| `c:eye(pos, radius, iris)` / `c:eyes(y, z, spread, radius, iris)` | cartoon eyes |
| `c:light(colour, brightness, range)`, `c:sparkle(colour, rate, speed, size)` | glow and particles; use sparingly |

**The palette `p`.** It is built from the pet's tint: `p.base`, `p.dark`,
`p.deep`, `p.light`, `p.pale`, `p.glow` and `p.iris`.
- **Use `p.*` for the body's main colours.** That is what lets each pet on a
  body wear its own colour.
- Fixed colours are only for accents that must not change: eyes, metal trim,
  a glowing core.

**`block(c, p, o)`, the chassis.** It makes a body, two eyes, a mouth or snout,
four legs and a tail. Its envelope is about 2.02 × 1.88 × 1.80 (x × y × z),
centred at y = 0.06. The front face is near z = +0.9, the top near y = +1.0 and
the feet near y = −0.86.

| option | does |
|---|---|
| `shape` | `"quad"` (four-legged), `"bird"` or `"round"`: adds mass so the outline is not a plain cube |
| `bodySize` | a Vector3 envelope |
| `square = true` | a box body |
| `eyeColor`, `eyeSize`, `eyeY`, `eyeSpread` | the eyes |
| `mouth = false` / `mouthSize` / `mouthY` / `mouthColor` | the mouth |
| `snout = { w, h, d, y, color, nose }` | a snout |
| `brow = colour` | a brow |
| `bib = { w, h, y, color }` | a chest patch |
| `legs = false` / `legSize` / `legX` / `legY` / `legZ = {…}` / `legColor` | the legs |
| `tail = false` / `tailSize` / `tailColor` | the tail |

It returns `size, frontZ, bodyPart`. A body may skip `block` and build from
parts (see `S.candycorn` and `S.eyeball` in PetModelFactory), but it must still
have a readable face.

**The rules** (each learnt the hard way; see `wiki/systems/pets.md`):
- **Features sit on the envelope, never inside it.** A part centred inside the
  body vanishes.
- **Do not build a separate head volume above the body.** Faces live on the
  body's front.
- **FIT_SIZE (2.5).** Every model is scaled so its LARGEST dimension is 2.5
  studs. Wide wings or a tall prop shrink the whole pet. Keep the total extent
  near 3 studs, or set `scale` (1.1–1.35) to compensate.
- **Budget 12–40 parts per body.** The display builds hundreds of pets.
- **Every body is distinct:** a clear silhouette, different from the other
  bodies in its set and from the existing 54. Theme it from `_sets.json`.
  Make it cute and kid-friendly: no gore and no scary realism.
- **No `season` field.** A season tag makes a body a holiday body, which keeps
  it out of the game.
- **No top-level side effects:** just `return function(K) … end`.

## 2. A set data file

`tools/gen/sets/<key>.json`:

```json
{
  "key": "pebblebound",
  "bodies": [ { "id": "pb_pebblet", "label": "Pebblet", "role": "Bruiser" } ],
  "extraBodies": ["golem", "beetle"],
  "buffs": ["dirtBreak", "oreHaul", "fossilFind"],
  "palette": [["Granite", 132, 128, 124], ["Copper", 190, 110, 60]],
  "topWords": { "Legendary": ["Polished"], "Mythic": ["Geode"], "Divine": ["Radiant"], "Exotic": ["Heart"] },
  "names": ["Pebble", "Flint", "..."]
}
```

- **`bodies`**: the set's new bodies, about 5. `role` is the job the body
  suggests, one of Striker, Bruiser, Digger, Seeker, Prospector, Tidecaller,
  Trader or Mystic (see `ROLES` in `tools/gen/zone-pets.js`).
- **`extraBodies`**: 2–4 existing everyday species that also fit the theme,
  from `_species.txt`, never a holiday one. Spread the set's pets over these
  and its own bodies.
- **`buffs`**: three stats for the set's Mythic, Divine and Exotic pets, themed
  to the set. Choose from mineSpeed, swingRate, dirtBreak, oreHaul, fossilFind,
  coinBonus, luck, chestLuck, packLuck, gemFind, rareOre, oreLuck, luckyFind,
  pulverize, scrap, zap, blastChance, tidalWave, ricochet (Shatter), earthquake,
  blastDamage, tideDamage, zapDamage and shatterDamage. **At most one** of them
  may be a proc chance (zap, blastChance, tidalWave, ricochet, earthquake).
- **`palette`**: about 24 named, themed colours `[name, r, g, b]`. Make them
  clearly different from each other, because they are what tell two pets on one
  body apart.
- **`topWords`**: 3–5 themed adjectives each for Legendary, Mythic, Divine and
  Exotic looks.
- **The theme is the predominant type** (owner, 2026-10-10). Not every pet has
  to be literal (not every Atlantis Rising pet is underwater), but the set's
  theme must clearly dominate: about three names in four should obviously
  evoke it, and the rest stay near it. The own bodies carry the theme and are
  weighted double, so they dress most of the set; `extraBodies` must fit too.
- **`names`**: the set's pet count plus at least 40% spare. Each must be unique
  and themed, kid-friendly, 1–2 words, at most 16 characters, and not a brand,
  a franchise character or a real person. None may be in `_taken.txt`, and none
  may be a plural or case twin of one there ("Murmurs" vs "Murmur"). Order does
  not matter; the generator assigns them.
