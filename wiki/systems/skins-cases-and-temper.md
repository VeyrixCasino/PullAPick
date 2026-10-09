---
title: Skins, cases and temper
type: system
status: partial
verified: 2026-10-05 @ 26036a0
sources:
  - src/ReplicatedStorage/Mine/Shared/MineTemper.luau
  - src/ReplicatedStorage/Mine/Shared/MineForgeView.luau
  - src/ReplicatedStorage/Mine/Shared/MineGradeReveal.luau
  - src/ReplicatedStorage/Mine/Shared/MineIridescence.luau
  - src/ReplicatedStorage/Mine/Shared/MineZonePacks.luau
  - src/ReplicatedStorage/Mine/Shared/MineCharms.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - docs/TODO.md §0.13
  - docs/TODO.md §6.1
  - docs/OPEN.md P1 #9
  - docs/ROADMAP.md
related: [tools, ores, charms, boosts-and-stats, traits, chests-and-lucky-blocks, forge-and-recycling]
---

# Skins, cases and temper

> A **temperament** ("temper") is a stat kit you fit onto a tool family or a
> flagship tool. It is graded F to SSS. **Skins** are meant to replace tempers
> as the main chase item. Today the code's "skin" *is* a temper, delivered by
> an **ore case**: an ore block has a 2% chance to drop a case, and opening it
> always pays a skin or a charm.

## How it works

**Kits.** `MineTemper.KITS` holds 100 kits: F 7, D 9, C 9, B 24, A 18, S 14,
SS 12 and SSS 7. Each kit names 1–4 stats, for example "Godnail" or
"Absolute Dig".

**Grade ladder** F, D, C, B, A, S, SS, SSS. The weights are
`MineTemper.RARITY_WEIGHTS`, out of 10,000:

| grade | F | D | C | B | A | S | SS | SSS |
|---|---|---|---|---|---|---|---|---|
| weight | 5000 | 2763 | 1250 | 675 | 250 | 50 | 10 | 2 |
| chance | 50% | 27.63% | 12.5% | 6.75% | 2.5% | 0.5% | 0.1% | 0.02% |
| `RARITY_MULT` | 0.45 | 0.70 | 1.05 | 1.55 | 2.30 | 3.40 | 5.00 | 7.50 |

- **The roll.** `rollTemperament` picks a grade, then picks a kit uniformly
  within that grade.
- **Batches show their best.** A ×10/×100 buy (`Verbs.openTemperCase`) or the
  3-case bundle grants every roll but plays one reel. Since 2026-10-08 that
  reel shows the **best** grade of the batch, not the last roll. Before, an SSS
  on roll 3 of 10 was granted and never shown. The reveal says "BEST OF N".
- **Skins in a pack run.** Ore-case skins ride an open-10 or open-all as cards
  whose `rarityId` is a grade letter. `MinePackFX.rankOf` reads F…SSS on the
  same 1–8 ladder, so a skin of A or better is a bulk hit. Before, every skin
  scored as a DUD and an SSS was folded into "N cleared".
- **Stat size.** Each stat is its slot share (1.00 / 0.60 / 0.35, from
  `MineTemper.BASE`) × `RARITY_MULT`. Chance stats use `ABS_PRIMARY` ×
  `PROC_RARITY_MULT` instead.
- **What the player sees.** Players see words, not letters (`WORD_OF`). S, SS
  and SSS all read "Mythic".
- **Old saves.** `LEGACY_RARITY` and `normalizeRarity` map the old names
  Common…Exotic to F…SSS so old saves still load.
- **Traits** reuse these same odds (TODO §0.18,
  [enchantments](traits.md)).

**Owning and fitting.**
- `p.tempers[kitId] = {rarity, n}` keeps the best grade seen and a copy count.
- `Verbs.equipTemper` fits a kit you own, for free, onto either a family
  (`p.toolTempers[fam].tempers[slot]`) or a flagship row. You can fit 1–2
  kits; the number of slots comes from `MineTemper.slotCount`.
- `boosts()` applies **one** temper set: the flagship's if you are holding a
  flagship, otherwise your tool family's. Tempers survive rebirth.

**Sources.**
1. **Temperament Case**, at the Enchanter. `Verbs.openTemperCase` costs
   `CASE_PRICE_TOKENS 20` **temper tokens**. After a rebirth you are offered 3
   for 50. The server decides the winner first and builds the reel around it
   (`CASE_REEL 44`, `CASE_WINNER_AT 38`), then fires the `temperCase` event.
2. **Rolling directly.** `Verbs.rollTemper(family | flagship)` costs
   `MineSkillData.TEMPER_ROLL_COST 20` tokens.
3. **Ore case.**
   - **Ids.** `MineZonePacks` registers `<ore>_ore_case` for every ore, so
     there are 82 cases.
   - **Drop.** Each ore block broken drops one at `ORE_CASE_CHANCE 0.02 ×
     max(1, oreLuck)`. It still drops when the pouch is full. It lands in
     `p.packs`.
   - **Opening** (in `openPack`, the `ore_case` branch):
     - with chance `ORE_CASE_CHARM_SHARE 0.25`, you get one of that ore's
       charms (`MineCharms.rollOreCharm`). A player who owns no charm yet
       always gets a charm (`caseCharmShare`).
     - otherwise you get a **"skin"**, which is a `rollTemperament` with the
       same reel.
   - **Never a tool, never ore.** 2% × 25% = 0.5% charm rate per ore block.
4. **Scrapping.** `Verbs.scrapTemper` pays `SCRAP_TOKENS`: F 1, D 2, C 5, B 20,
   A 177, S 555, SS 1,515, SSS 6,312. That is aimed at about 65% return on a
   case. Temper tokens also come from rebirth (`MineSkillData.rebirthTokens`)
   and from selling forever tools.

**Grade reveal and iridescence.**
- `MineGradeReveal` plays the step-by-step F→SSS animation that the server
  scripted with `MineToolGrades.rollClash`. Its header says gear crates; the one
  live `rollClash` caller in MineServer is the lucky-block grade-up. It is
  **not** used for tempers.
- `MineIridescence` draws the shared S / SS / SSS badge: 1, 2 or 3 marks on a
  9-stop pastel gradient. Inventory, sockets and grade reveal use it.

## Where it lives

| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineTemper.luau` | kits, odds, case, scrap | `KITS`, `RARITY_WEIGHTS`, `rollTemperament`, `applyTemper`, `caseReel` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | verbs, ore case open, case drop | `Verbs.openTemperCase`, `Verbs.rollTemper`, `Verbs.equipTemper`, `Verbs.scrapTemper` |
| `src/ReplicatedStorage/Mine/Shared/MineForgeView.luau` | Temper tab UI (the Enchanter's) | `mountList` |
| `src/ReplicatedStorage/Mine/Shared/MineGradeReveal.luau` | F→SSS step animation | `play` |

## Decided by the owner

- Charms and skins are "the build" (TODO §0.13). One ore case per ore, 82 in all
  (§0.13 rule 6).
- **TODO §9:** "Skin and temper crates cost ore only." **Not done:** the code
  charges temper tokens (OPEN P0 #5).
- **OPEN #9 / TODO §6.1 "Ore cases and skins"** asks for:
  - rename tempers to skins, keeping `LEGACY_RARITY`
  - a skin applies to a whole tool family
  - the name states the ore and the skin type
  - a skin does **not** change the tool's colour (it is a wrap)
  - the drop rates match the temper table
  - skins inherit "the chase"

  Mostly not done: kit names say nothing about an ore.

## State right now

**Partial.** The ore-case drop, the 75/25 skin/charm split and the per-ore case
ids are shipped. The skin rename and wrap art are not started. Untested in the
engine.

## Gotchas

- **The family skin does nothing on a forged tool.** `boosts()` applies the
  family temper only when `equippedTool` returns rung > 0, and a forged tool
  returns 0. Since forged tools are now the main tool, skins and tempers
  mostly do nothing (found by reading the code; not run).
- **Rule 6 contradicts the code.** TODO §0.13 rule 6 says the case "rolls 2%
  down to 0.5% to decide whether you get a tool". The code (`ORE_CASE_CHANCE`)
  and TODO §6.1 "Ore drops ore" say a case never pays a tool: that first build
  was "corrected". The locked text was never updated. The unchecked list under
  §6.1 "Ore cases and skins" still repeats the tool roll.
- **Docs disagree on whether skins give power.** `docs/ROADMAP.md` says "Tool
  skins are a cosmetic wrap only — zero power". But §0.13 makes skins half of
  "the build", TODO §0.19 lists skins in boost layer 1, and the code's skins
  are stat kits.
- **Skins skip the boost layers.** They are applied outside `T1` (OPEN #10).
- **Dead stats in kits.** 20 stat entries in kits still name the retired
  `backpack` or `walkSpeed` stats (`MineStats` marks them `legacy`).
- **One charm or two per ore?** TODO §0.13 rule 5 says one charm per ore, but
  the ore case picks one of the ore's **two** charms. See [charms](charms.md).

## Open questions

- Are skins cosmetic, or a power source? This blocks the rename and the art.
- Should ore cases cost or need ore, as standing rule "ore only" says? Or does
  that rule cover only bought crates?
- Should the family temper apply to forged tools (OPEN #15 fold-in)?

## See also

[tools](tools.md) · [charms](charms.md) · [boosts-and-stats](boosts-and-stats.md) ·
[chests-and-lucky-blocks](chests-and-lucky-blocks.md)
