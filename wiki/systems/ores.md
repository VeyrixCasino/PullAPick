---
title: Ores
type: system
status: current
verified: 2026-10-10 @ 6c08171
sources:
  - src/ReplicatedStorage/Mine/Shared/MineOreFace.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - docs/ore-yield-and-vein-balance.md
  - tools/verify/veins.js
  - src/ReplicatedStorage/Mine/Shared/MineBreaking.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineZonePacks.luau
  - src/ReplicatedStorage/Mine/Shared/MineOreArt.luau
  - src/ReplicatedStorage/Mine/Shared/MineOreIcons.luau
  - src/ServerStorage/OreToolBaker.luau
  - tools/gen-ores.js
  - docs/TODO.md §0.13
  - docs/PROPOSAL.md §0
  - docs/OPEN.md P0 #3
related: [ore-pouch-and-backpack, tools, forge-and-recycling, skins-cases-and-temper, mining-and-breaking, zones-layers-and-seams, charms, save-data-and-migrations, tools-and-generators, assets-and-uploads]
---

# Ores

> 82 minerals, Stone (tier 1) to Oganesson (tier 82). Ore is the power currency:
> you mine it in veins, it lands in the [ore pouch](ore-pouch-and-backpack.md),
> and you forge and level tools from it ("a forged tool *is* its ore",
> [tools](tools.md)). It also sells for gems.

## How it works

- **Roster.** `MineConfig.ORES`, 82 rows: `id, name, tier, color, material, met,
  rough`, optional `glow`/`glowBright` (27 rows) and `rainbow` (4). Read
  `MineConfig.ORE_COUNT`, never a literal. The `ORE_BY_ID` block derives `d =
  (tier-1)*ORE_DMAX/81`, `packId = <id>_ore_pack`, `band`/`bandIndex`, and
  `homeHp = 20*6^d`. Lookup: `MineConfig.oreById`.
- **Bands** = `MineConfig.ORE_YIELD_BANDS` (also the ore-per-block table), read
  through `oreBandForTier`:

  | band | Common | Uncommon | Rare | Epic | Legendary | Mythic | Divine | Exotic |
  |---|---|---|---|---|---|---|---|---|
  | tiers | 1–18 | 19–29 | 30–49 | 50–60 | 61–69 | 70–75 | 76–79 | 80–82 |
  | ore/block | 8–10 | 10–12 | 11–13 | 12–15 | 8–10 | 6–8 | 4–6 | 2–4 |

- **Is it ore?** Flat `MineConfig.ORE_CHANCE = 1/200` per block, everywhere. The
  curve only picks *which* ore.
- **Which ore.** `MineConfig.oreWeights(zone, layer, rareOre)`: local hardness
  `oreDifficulty = log6(dirt blockHp / 20)`; per ore `x = d - hardness`; weight
  is a logistic cliff above hardness (`ORE_X0 -4.2`, `ORE_K 0.45`) times a decay
  below (`ORE_S 4`, `ORE_W 3`). It peaks ~21 tiers under local hardness.
  `ORE_MIN_SHARE = 1e-6` floors each ore's **share** of the final total (fixed
  point), so every ore is possible everywhere and odds never fall with depth.
  The spread is **narrow at the top and widens with depth** (`oreSpreadK`):
  `ORE_K_TOP 0.040` ramps to `ORE_K 0.45` over `ORE_K_RAMP 1.5` in D, which is
  what makes the first layers predominantly stone.
- **The weight row is cached per depth, not per section** (`ORE_DL_STEP 0.05`).
  It used to key on `Depth.sectionFor(layer).id` while computing `dl` from the
  layer it was handed, so the **first layer anyone asked about fixed the mix for
  the whole section** — zone 1 layers 1–49 all reported one stone share (44.5%
  flat) though `dl` runs 0.053→0.511 across them, and two servers with different
  dig orders got different mines at the same depth. Fixed 2026-10-07; the key is
  the quantised `dl` and the row is computed from that same value.
- **Zone dependence is only through block HP.** No per-zone ore lists
  (`MineConfig.oresFor` returns all 82). `ORE_DMAX` = log6 of
  `Depth.dirtHp(10, LAYERS)` minus `ORE_DMAX_MARGIN 0.4`, so Oganesson sits just
  under zone 10's floor. Event Horizon is off the ladder (`ORE_LADDER_ZONES = 10`).
- **Ore finder** (`rareOre` stat): `MineConfig.oreFindShift` = `log6(rareOre)`
  raises the hardness the roll thinks it is at. Better ore, not more ore; it is
  not applied again at break.
- **Veins** (rebuilt 2026-10-07; measured tables in
  `docs/ore-yield-and-vein-balance.md`). `MineConfig.veinOreAt` is a pure function
  of `(zone, x, y, z, rareOre)`: 4×4×4 cells (`VEIN_CELL`), murmur3 hash per zone,
  re-salted per server by `setVeinSalt`. Server `rollKind` and `spawnVoxel` both
  ask `veinOreAt`, so a vein is one ore and regen agrees. `rollOre`/`oreIdentity`
  stay for sims and harnesses.
  - **Size** is `veinSizeMean(tier)`, no longer the tier index. An "effort"
    position blends `craftBlocks` (0.60), drop count inverted (0.25) and rarity
    band (0.15), maps through a curve with separate tail powers
    (`VEIN_TAIL_POWER_BIG 12`, `_SMALL 5`), then multiplies by that ore's own
    spread factor `VEIN_SPREAD_LO + GAIN·u²` = 0.70×–2.20×, `u` hashed from the
    tier. Owner's shape (2026-10-07): highest average 12–14 for one or two ores,
    90% under 8, rarer ore smaller. Measured: stone 13.0, clay 14.0, 80 of 82
    under 8, median 3.57, Exotic 1.00–1.74.
    **Cost is priced in `craftBlocks`, not `toolCraftCost`** — the latter *is*
    `craftBlocks × oreYieldMid`, so reading it double-counted yield and pulled the
    Exotic ores back to mid-roster.
  - **`veinSizeFor` is derived from the mean** by stochastic rounding, so
    `E[size]` equals `veinSizeMean` by construction. The two used to sit side by
    side, correct only by inspection; if they drift, `veinWeights` divides by the
    wrong number and that ore's share moves.
  - **Shape is grown, not stamped.** `veinGrow` starts at the anchor and bolts on
    face neighbours, seeded per ore with an axis bias (`VEIN_AXIS_BIAS 0.62`):
    contiguous by construction, any size to `VEIN_MAX 14`, and each ore has its
    own habit. The retired `VEIN_ORDER` was the eight corners of a 2×2×2 in fixed
    order, so **every size had exactly one silhouette** — a four was always a flat
    2×2 slab, and sizes 6 and 8 never appeared at all.
  - **The anchor is clamped per axis by the shape's extent**, so a vein cannot
    leave its cell. A flat `cell - 1` used to let a 2-wide vein anchored at offset
    3 lose half itself to the next cell, and the density correction then divided
    by a size that was never placed.
  - **Size never moves a spawn rate.** `veinWeights` sets `q_i = share_i / mean_i`,
    so twice the size is half the frequency; measured density holds at 1 in ~208
    against `ORE_CHANCE`'s 1 in 200.
- **An ore block** has dirt HP × `ORE_HP_MULT 3`, is stamped `OreId`/`OreName`/
  `OreTier`, and wears a name tag. Breaking it puts `oreYieldFor(tier)` (uniform
  lo..hi) **straight into the pouch** via `Dig.addOre` (no pack), pays coin haul
  per HP like any block, and rolls 2% × ore luck for an
  [ore case](skins-cases-and-temper.md).
- **Ore reach.** `MineBreaking.blockStrength` asks for the ore as if it sat
  `reach` tiers lower and takes the harder of that and layer strength.
  `MineBreaking.reachFor`: `ORE_REACH_HOME 5` in the zone you are working,
  `ORE_REACH 15` once `p.maxUnlockedZone` is past it. Mirrored in MineConfig
  (`canBreakOre`, `oreReachCap` — what the Forge quotes); `tools/verify/breaking.js`
  fails on drift and asserts home reach 0 deadlocks at tier 4. Full gate:
  [mining-and-breaking](mining-and-breaking.md).
- **Art.** A block is the zone rock (darkened SmoothPlastic) wearing one of 30
  hand-drawn faces: `MineConfig.ORE_FACE[id]` → `MineOreArt` tile, rebuilt
  client-side as an EditableImage — not an uploaded asset, so no group-ownership
  problem. Packed by `tools/pack-ore-art.js`, mapped by `tools/map-ores-to-tiles.js`.
  `MineOreIcons.BY_ID` holds 82 icons + 82 case images (164 uploaded assets,
  `tools/gen-ore-icons.js`) and **nothing reads it yet**. Tool look:
  `ToolModelFactory.oreLook`, `src/ServerStorage/OreToolBaker.luau`.

## Where it lives

| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineConfig.luau` | roster, bands, curve, veins, migrations | `ORES`, `oreWeights`, `veinOreAt`, `ORE_MIGRATION_V2`, `ORE_TIER_REMAP_V2` |
| `src/ReplicatedStorage/Mine/Shared/MineBreaking.luau` | live reach gate | `reachFor`, `oreStrength`, `blockStrength` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | spawn, drop, roster migration | `rollKind`, `spawnVoxel`, `Dig.addOre`, `oreRosterV` blocks in `load` |
| `src/ReplicatedStorage/Mine/Shared/MineZonePacks.luau` | `<id>_ore_pack` + `<id>_ore_case` for all 82 | `PACKS`, `get` |
| `src/ReplicatedStorage/Mine/Shared/MineOreArt.luau` | 30 packed face tiles | `image`, `apply` |

## Decided by the owner

- 82 ores, final; Event Horizon ores may come later (TODO §0.13 rule 4).
- Ore tier = the tool's breaking power, with reach above it (§0.13 rule 1);
  reach later split into 5 at home / 15 once cleared (PROPOSAL banner, "Line 14 was
  also changed"). `roadmap/ORE.md`'s contrary argument is OVERRULED.
- Gems come from selling ore (§0.13 rule 7). Ore ids are load-bearing; ore is
  mined, never bought (TODO §9).
- Every rarity possible in every zone; veins (owner, 2026-10-05, quoted in
  MineConfig). `tools/verify/ladder-climbable.js` also cites *"never touch spawn
  chances"* as an owner rule — not found in TODO §0.

## State right now

Shipped on `claude/vigilant-fermi-aucqjy`: 82 roster, veins, share floor, reach
split, ore dropping straight into the pouch.

### Every ore has its own health (2026-10-08, `b747891`)

`ORE_HP_MULT` was a flat **3 for every ore in the game**, written out at its one
call site rather than behind a function — so a Stone block and an Oganesson
block at the same layer took the same number of swings, and the only thing that
varied was the dirt curve underneath, which describes the LAYER.

Now `oreHardness(ore) × dirtHp(zone, layer)`. The layer term is untouched, so no
other block moved. The ore term is a MULTIPLIER, so an ore keeps its character
at every depth instead of being trivial deep down and impossible early.

Character comes from `met` and `rough` — already on every roster row and already
driving the block's colour — so an ore that *feels* like metal is one:

| character | multiplier |
|---|---|
| metal (`met ≥ 0.5`) | ×1.12 |
| crystal (`rough ≤ 0.45`) | ×1.06 |
| rock | ×0.94 |

Measured: **82 distinct hardness values** where there was one, spanning
**0.75 → 4.48**, 81 of 81 adjacent pairs differing, 30 metal / 40 crystal /
12 rock. **Stone is 0.75×** — deliberately under 1, so the first ore a player
swings at is softer than the dirt around it rather than three times harder
(owner: *"make stone a little weaker"*). Pinned by `tools/verify/orehp.js`.

### Ore faces are drawn per ore and hung as decals (2026-10-08, `7042cf0`)

`MineOreFace` replaces the `MineOreArt` path for blocks. The old one looked the
ore up in `ORE_FACE`, an index into **thirty** hand-packed tiles shared across
82 ores, and hung six *tiling* `Texture`s per block — the tiling is what looked
glitchy at block edges. Decals have no tiling properties at all.

A face is a cluster of bevelled nodules covering 7–25% of the side, crowded
centrally and clamped off the edge (a nodule that runs off lines up with the
neighbouring block and reads as a seam). Four looks from the same `met`/`rough`
the hardness uses: **20 metal, 24 crystal, 11 rock, 27 glow**.

**Stone is a plain grey block.** `MineConfig.ORE_PLAIN` is one list both sides
read: the server paints the block the ore's own colour and material instead of
the darkened art host, and the client draws no face.

## Gotchas

- **Ore ids are save data**: `p.ores`, `p.oresSeen`, `p.oreLocks`,
  `<id>_ore_pack`, `<id>_ore_case`, `ORE_FACE`, `MineOreIcons`. Renames need a
  migration: `ORE_MIGRATION` (v1), `ORE_MIGRATION_V2` (121→82, 39 ids),
  `ORE_TIER_REMAP_V2` — because `p.oreTools[].tier` is an **index** into `ORES`,
  not an id. Stamp `p.oreRosterV`, `ORE_ROSTER_V = 2`.
- **Fixed in `b19c4c2`: the roster migrations used to re-run on every load.**
  The v1 and v2 guards were `~=`, so a profile stamped 2 re-entered v1, was
  re-stamped 1, then re-entered v2. Both are now `< version`. Whether saves
  already touched by the re-runs were repaired is not stated (unverified). See
  [save-data-and-migrations](../code/save-data-and-migrations.md).
- **`tools/gen-ores.js` is stale — never `--write`.** It parses 121 rows from
  `docs/ore-remake.md`. The `--force-stale` staleness guard described by
  `roadmap/README.md`, `roadmap/AGENT_PROMPT.md` and `roadmap/PROMPTS.md` is
  commit `9932508`, which is only on `origin/ore-tools-power`, not this branch.
  Here `--write` refuses only by accident (13 live ids unmapped). Dry run is safe.
- `docs/ore-remake.md`'s own banner is stale: it says MineConfig "has NOT caught
  up" and the OreToolBaker authority is "not committed". MineConfig is 82, and
  `src/ServerStorage/OreToolBaker.luau` is committed and matches `MineConfig.ORES`
  name-for-name and band-for-band (checked).
- TODO §6.1 "Ore drops ore" says yield comes from a roster `yield` field scaled by
  the `oreYield` boost — stale: it is `ORE_YIELD_BANDS`, and `oreYield` is now the
  blast-chance key. `roadmap/ORE.md` says `ore.d` comes from an authored `home` —
  not on this branch (linear in tier).
- `ServerStorage.OreShapes` (the ten plate patterns in `docs/decisions.md`) is
  place-file only, not in git, and nothing in `src/` reads it any more.
- `ORE_DMAX` was once anchored on the retired `Depth.SECTIONS` and deadlocked the
  forge ladder at tier 8 — treat old balance numbers in docs as suspect.

## Open questions

- Space ores (40, `docs/ore-remake.md`, unapplied): are they the "Event Horizon
  ores later"?
- `MineOreIcons`: where should icons show (pouch, Forge, case), and were the 164
  assets uploaded to the group? (unverified; [assets-and-uploads](../code/assets-and-uploads.md))
- OreShapes: export to `.rbxm` (OPEN P2) or delete?
- BLOCKED #4: does the Studio copy of `ToolBakers.OreToolBaker` match the repo
  copy? ([open-questions](../open-questions.md))

## See also

[forge-and-recycling](forge-and-recycling.md) · [zones-layers-and-seams](zones-layers-and-seams.md) ·
[charms](charms.md) · [tools-and-generators](../code/tools-and-generators.md)
