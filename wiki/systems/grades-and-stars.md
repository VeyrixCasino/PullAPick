---
title: Grades and stars
type: system
status: current
verified: 2026-10-14 @ 98c141a
sources:
  - docs/TODO.md ★ NOW
  - docs/TODO.md B4
  - src/ReplicatedStorage/Mine/Shared/MineStars.luau
  - src/ReplicatedStorage/Mine/Shared/MineLoadoutView.luau
  - src/ReplicatedStorage/Mine/Shared/MineInventoryView.luau
  - src/ReplicatedStorage/Mine/Shared/MineForgeView.luau
  - src/ReplicatedStorage/Mine/Shared/MineSkinsView.luau
  - src/ReplicatedStorage/Mine/Shared/MineLuckyOddsView.luau
  - src/ReplicatedStorage/Mine/Shared/MineFishing.luau
  - src/ReplicatedStorage/Mine/Shared/MineCases.luau
  - src/ReplicatedStorage/Mine/Shared/MineTemper.luau
  - src/ReplicatedStorage/Mine/Shared/MineToolGrades.luau
  - src/ReplicatedStorage/Mine/Shared/MineCards.luau
  - src/ReplicatedStorage/Mine/Shared/MineGear.luau
  - src/ReplicatedStorage/Mine/Shared/MinePackConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineSetPacks.luau
  - src/ReplicatedStorage/Mine/Shared/MineLuckyBlocks.luau
  - src/ReplicatedStorage/Mine/Shared/MineChestRanks.luau
  - src/ReplicatedStorage/Mine/Shared/MineEventPass.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
related: [fishing, pack-cases, skins-cases-and-temper, cards-and-packs, chests-and-lucky-blocks, hats-and-faces, ores, world-events, ambiguous-terms]
---

# Grades and stars

> The game grades many things with different names (letters, words, pack bands,
> pass rungs). The owner locked one **display** scale for all of them: **1★ to
> 5★ in half steps, nine grades**. Nothing is renamed; UI shows the ★
> equivalent beside the name it already uses (`docs/TODO.md` ★ NOW / B4).

This page is the reference. The shared helper is `MineStars`
(`src/ReplicatedStorage/Mine/Shared/MineStars.luau`). It does **not** change
odds, prices or power — only how a grade reads next to stars.

## The shared ★ ladder

| ★ | ★½ | ★★ | ★★½ | ★★★ | ★★★½ | ★★★★ | ★★★★½ | ★★★★★ |
|---|---|---|---|---|---|---|---|---|
| 1 | 1.5 | 2 | 2.5 | 3 | 3.5 | 4 | 4.5 | 5 |

Glyphs: `MineStars.TEXT`, also `MineFishing.GRADE_TEXT` and
`MineCases.WILD_GRADES[].text`.

## Letter / word ladder (eight rungs)

Tempers, gear, skins, charms, trader rolls and card rarities share one
eight-rung ladder. Letters and words are the same rungs
(`MineTemper.WORD_OF` / `LEGACY_RARITY`, `MineGear.PRINT_OF` /
`OLD_RARITY`, `MineCards.RARITY_ORDER`).

| letter | word | ★ | glyph |
|---|---|---|---|
| F | Common | 1 | ★ |
| D | Uncommon | 1.5 | ★½ |
| C | Rare | 2 | ★★ |
| B | Epic | 2.5 | ★★½ |
| A | Legendary | 3 | ★★★ |
| S | Mythic | 3.5 | ★★★½ |
| SS | Divine | 4 | ★★★★ |
| SSS | Exotic | 5 | ★★★★★ |

★★★★½ has **no** letter/word twin: eight rungs onto nine half-steps. Native
star systems (fishing, wild cases) still use 4.5★.

Lucky-block and gear climb use the same letters via `MineToolGrades.ORDER`
(F→SSS). Chest pool ranks are a shorter cut of the same letters
(`MineChestRanks.ORDER` = S, A, B, C, D, F; no SS/SSS).

## Systems that are already stars

| system | where | values |
|---|---|---|
| Fishing catch grade | `MineFishing.GRADES` | 1 … 5 half steps (index 1..9) |
| Wild pack cases | `MineCases.WILD_GRADES` | same nine grades |
| Set packs (six slots) | `MineSetPacks.STARS` | 1, 1.5, 2, 3, 4, 5 (no 2.5 / 3.5 / 4.5 in the six pack slots; wild cases fill those) |
| Zone card packs | `MinePackConfig.ZONE_PACK_STARS` | Common 1★, Rare 2★, Legendary 3★ |
| Hand-rated shop packs | `MinePackConfig.packStars` | half-star rating per pack id |
| Lucky-block shop rating | `MineLuckyBlocks.blockStars` | type band (2.5 / 3.5 / 4.5) + start-grade nudge — a **shop score**, not the letter→★ map above |

## Pass tiers

Event Horizon pass (`MineEventPass.TRACKS.event_horizon.tiers`): six named
rungs `eh1`…`eh6`. Display map in `MineStars.PASS_TIER` puts them on ★ …
★★★½. That is UI only; XP thresholds and bonuses stay in `MineEventPass`.

## Ore bands

`MineConfig.ORE_BAND_ORDER` is the same Common…Exotic words as the letter
ladder, so an ore band uses the word row in the table above.

## Helper API

```
MineStars.value(gradeLike)   -> number | nil   -- half-star 0.5..5
MineStars.stars(gradeLike)   -> string         -- "★★★½" or ""
MineStars.label(gradeLike)   -> string         -- "3.5★" or ""
MineStars.beside(gradeLike)  -> string         -- "SSS  ★★★★★" for letters/words
```

`gradeLike` may be a letter, a rarity word, a half-star number, a zone-pack
slot id, a pass tier id, a glyph string, or a table with `grade` / `rarity` /
`stars` / `gradeIndex` (fishing index 1..9).

**Wired beside sites** (letter/word kept; ★ next to it; no balance change):

| UI | module | what shows stars |
|---|---|---|
| Loadout inspect rarity | `MineLoadoutView` | gear letter badge |
| Pack odds rows | `MineInventoryView` | card rarity word |
| Equipment card Grade row | `MineInventoryView` | hat/face letter |
| Forge temper word lines | `MineForgeView` | seat / selected / flagship |
| Skins tier badge | `MineSkinsView` | F…SSS badge |
| Lucky-block odds | `MineLuckyOddsView` | final grade + pet tier |

Tiny letter chips (forge temper tiles, inventory thumbs) stay letter-only —
too narrow for glyphs.

## Gotchas

- Do not treat `MineLuckyBlocks.blockStars` as the letter→★ map; it rates the
  block SKU for the shop grid.
- Do not rename F…SSS or Common…Exotic to stars in saves or roll tables.
- Fishing stores a **grade index** (1..9); pass `{ gradeIndex = f.grade }` or
  `MineFishing.GRADES[f.grade]` into `MineStars`, not the bare index if you
  might confuse it with a 1..5 star value.
- `MineSetPacks.STARS` has six slots; the full nine half-steps live on wild
  cases and fishing.

## See also

[fishing](fishing.md) · [pack-cases](pack-cases.md) ·
[skins-cases-and-temper](skins-cases-and-temper.md) ·
[cards-and-packs](cards-and-packs.md) ·
[chests-and-lucky-blocks](chests-and-lucky-blocks.md) ·
[hats-and-faces](hats-and-faces.md) · [ores](ores.md) ·
[ambiguous-terms](../ambiguous-terms.md)
