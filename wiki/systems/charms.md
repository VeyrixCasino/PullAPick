---
title: Charms
type: system
status: partial
verified: 2026-10-05 @ 26036a0
sources:
  - src/ReplicatedStorage/Mine/Shared/MineCharms.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineInventoryView.luau
  - tools/verify/charms.js
  - tools/gen-charm-icons.js
  - docs/TODO.md §0.13
  - docs/TODO.md §0.25
  - docs/TODO.md §6.1
  - docs/PROPOSAL.md §0
  - docs/AUDIT.md §4
  - docs/BLOCKED.md
  - roadmap/PRINCIPLES.md §1
  - roadmap/CHARMS.md
related: [skins-cases-and-temper, boosts-and-stats, ores, chests-and-lucky-blocks, traits, retired-and-parked, assets-and-uploads, currencies-and-economy]
---

# Charms

> One equipped trinket that bends your mining numbers. The owner calls charms
> and skins "the build" (TODO §0.13). Ore charms drop from ore cases, two per
> ore, and each is meant to differ in *shape*, not just in size.

## How it works

- **One slot.** `p.equippedCharm`. `boosts()` in MineServer applies it with
  `MineCharms.applyEquipped(b, id, p)` **after** the two boost layers combine, so
  a charm sits in neither layer (`MineBoostLayers.LAYER1` / `LAYER2` do not name
  charms). See [boosts-and-stats](boosts-and-stats.md).
- **Owned as a tally.** `p.charms[id]` is a count; a legacy `true` counts as one
  (`MineCharms.ownsAnyCharm`).
- **Two families in `MineCharms.LIST`:**
  - **164 ore charms**, generated at module load from `MineConfig.ORES`: 82 ores ×
    `ORE_CHARM_VARIANTS` 2. Ids `<ore>_charm` (variant 1, the id old saves hold)
    and `<ore>_charm_2` (`MineCharms.oreCharmId`). Name `<Ore> <Word> Charm`.
  - **31 legacy charms**: 15 zone charms (`CHARM_ZONES` 5 zones × shallow/mid/deep
    by `bandForLayer`), 15 pack charms, and Pot of Gold (id `lucky_charm`, limited).
- **Ore-charm drop.** Each ore block rolls a case at `MineConfig.ORE_CASE_CHANCE`
  0.02 × `Dig.oreLuck(b)`. An opened case pays a charm with
  `ORE_CASE_CHARM_SHARE` 0.25, else a skin. That is 0.5% per ore block before luck.
  The charm is one of that ore's two, picked uniformly (`MineCharms.rollOreCharm`).
  **Your first charm is guaranteed:** `MineCharms.caseCharmShare` returns 1 while
  you own none.
- **Budget.** `(ORE_CHARM_MIN 1.00 + 2.20 × (tier−1)/81) × shape.mult`, floored to
  0.01. So a tier-1 Focus is +100% and a tier-82 Focus is +320%.
- **Shapes** (`MineCharms.SHAPES`, name word from `SHAPE_WORD`):

| shape | word | mult | what it does |
|---|---|---|---|
| focus | Focus | 1.00 | one stat, always on |
| pair | Twin | 1.15 | 60/40 split over two stats |
| pact | Pact | 1.75 | one stat up, another down 30%→60% (bounded, never −100%) |
| condition | Ward | 2.00 | pays only in a moderate window: `skinned`, `homeZone`, `hoard` (pouch >50%), `lean` (≤2 pets) |
| threshold | Brink | 2.40 | narrow window: `brimming` (pouch >90%), `noPets`, `soloPet`, `bare` (no skin) |
| ramp | Surge | 2.20 | scales with stacks: +1 per real block break, `RAMP_MAX` 60, cold after `RAMP_IDLE_SEC` 12 s |

- **Stat pool** `ORE_CHARM_STATS`: mineSpeed, dirtBreak, coinBonus, gemFind, luck,
  chestLuck, backpack, swingRate. Echo, zap and blastRadius are barred.
- **Indexing** decides everything. `k = (tier−1)×2 + (variant−1)`; shape = `k mod 6`;
  stat = `(k + ⌊k/6⌋) mod 8`; condition = `(k + ⌊k/48⌋) mod 4`. An ore's two
  charms therefore always differ in shape *and* stat. 86 of 96 possible
  (shape, stat, condition) signatures are used (`charms.js` `EXPECTED_SIGNATURES`).
- **Merging costs gems, not copies.** `Verbs.mergeCharm`: one copy
  (`MERGE_COST` 1) plus `mergeGemCost(targetTier)` = ⌈1200 × 1.14^(t−1) / 50⌉ × 50
  gems, charged only after `mergeTarget` resolves. The target is the same variant,
  one ore tier deeper. The shape always changes, so a merge is a trade, not an
  upgrade (asserted in `tools/verify/charms.js`). Costs: t2 1,400; t24 24,450;
  t82 48,806,150 (computed from the formula). Only ore charms merge. If you
  merge away your equipped charm, the new one is equipped.

## Where it lives

| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineCharms.luau` | roster, shapes, conditions, merge rule | `LIST`, `SHAPES`, `applyEquipped`, `mergeTarget`, `mergeGemCost`, `rollOreCharm`, `rampFraction`, `bumpRamp` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | grants, equip, merge, case opening | `Verbs.mergeCharm`, `equipCharm`, `buyCharmsPack`, `finishBreak` (zone grant + ramp), ore-case branch of pack opening |
| `src/ReplicatedStorage/Mine/Shared/MineConfig.luau` | drop dials | `ORE_CASE_CHANCE`, `ORE_CASE_CHARM_SHARE`, `CHEST_LOOT` |
| `src/ReplicatedStorage/Mine/Shared/MineInventoryView.luau` | Inventory → Equipment charm rows, MERGE button | `onMergeCharm` |
| `tools/verify/charms.js` | runs the real generator in luau | needs `syntax.sh` first |

## Decided by the owner

- **§0.13 (2026-10-02):** charms + skins are the build. Later charms may be
  better, "but never because the number is bigger": a charm has a shape.
- **§0.13.5:** charms are a rare drop **from ores, not chests. "One charm per
  ore."** The code ships *two* per ore. That was an agent design (TODO §6.1), not an owner decision. See Open questions.
- **§0.25 (2026-10-04):** "rather than merging it should cost gems." So
  `MERGE_COST` (copies eaten) went from 3 to 1, and gems pay for each step.
- **PROPOSAL §0 line 20:** merge price stays `1200 × 1.14^(t−1)`.
- **PROPOSAL §0 line 33:** legacy 31: "keep the items, kill the three sources".
  **Not implemented yet** (see State).
- Owner, per AUDIT §4 (2026-10-04): "charms should not just be a huge family of
  clones. they would each be different and special in their own way."

## State right now

- **Shipped, never run in engine** (START-HERE §5): 164 ore charms, six shapes,
  gem merge, first-charm guarantee.
- **Legacy sources are still live:** the zone roll (`ZONE_DROP_ONE_IN` 10000, first
  charm guaranteed), the tutorial step 28 Sod Charm, the Charms Pack
  (`PACK_PRICE_GEMS` 2500, never a duplicate), the chest `charm` row (weight 1.1,
  draws from `packPool`), and Pot of Gold via `MineRotatingOffers` / Robux.
- **Proposed, not built:** cut 164 generated charms to about 24 hand-authored rule-charms
  (AUDIT §4, OPEN §8). AUDIT's reason: about 78 charms share a signature with another
  and differ only in magnitude, which is the clone family §0.13 forbids.
- **Charm icons: blocked on the owner.** `tools/icons/gen-charm-art.js` drew 164
  PNGs into the gitignored `build/charm-icons/`. The owner rejected them; their reference is
  jewellery (TODO §0.27, BLOCKED #11). This checkout has only `manifest.json`
  there. `tools/gen-charm-icons.js` turns `ids.json` into a `MineCharmIcons`
  module that does not exist yet. Nothing reads charm icons.

## Gotchas

- **Client merge gate disagrees with the server.** `MineInventoryView` uses
  `math.max(2, MERGE_COST)`, so the button needs two copies and says "MERGE 2". The
  server needs one, and the gem price is never shown. Found by reading the code.
- **Stale comments:** the MineCharms header still says "THE FIVE SHAPES" and that
  ramp is "deliberately absent", the merge block still says "Three copies", and
  `charms.js` / MineCharms say §6.0 legacy is open. PROPOSAL line 33 decided it.
- **Self-feeding loop.** Rule from `roadmap/PRINCIPLES.md` §1 and `roadmap/CHARMS.md`
  rule (b): "no charm that drops from ore may boost ore acquisition." It is direction only,
  not locked. 24 ore charms carry `luck`, and `Dig.oreLuck = b.luck × b.oreLuck`
  scales the ore-case roll that drops them. Legacy chestLuck charms likewise
  feed the chest row that drops legacy charms.
- **24 ore charms roll `backpack`**, which `MineStats` marks retired. It still pays,
  because `cap(p)` reads `boosts(p).backpack`.
- `roadmap/CHARMS.md` predates all of this (31 charms, stardust levels). Its
  "three charms carry oreYield" means the stat now called `blastChance` (rename
  `eb973f6`). Treat it as history.

## Open questions

- One charm per ore (§0.13.5) or two (code)? Ask the owner.
- Rewrite to about 24 authored charms: is it approved, and who authors them?
- Should charms join a boost layer, or stay outside both?
- Remove `luck` and `backpack` from `ORE_CHARM_STATS`?

## See also

[skins-cases-and-temper](skins-cases-and-temper.md) ·
[ores](ores.md) · [chests-and-lucky-blocks](chests-and-lucky-blocks.md) ·
[retired-and-parked](retired-and-parked.md) ·
[assets-and-uploads](../code/assets-and-uploads.md) ·
[open-questions](../open-questions.md)
