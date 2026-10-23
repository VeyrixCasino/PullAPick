---
title: Skins, cases and temper
type: system
status: partial
verified: 2026-10-19 @ 3863d14
sources:
  - src/ReplicatedStorage/Mine/Shared/MineTemper.luau
  - src/ReplicatedStorage/Mine/Shared/MineCaseStack.luau
  - tools/verify/case-stack.js
  - src/ReplicatedStorage/Mine/Shared/MineSkins.luau
  - src/ReplicatedStorage/Mine/Shared/MineToolSkins.luau
  - src/ReplicatedStorage/Mine/Shared/MineCandyTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineSkinsView.luau
  - src/ReplicatedStorage/Mine/Shared/MineForgeView.luau
  - src/ReplicatedStorage/Mine/Shared/MineGradeReveal.luau
  - src/ReplicatedStorage/Mine/Shared/MineIridescence.luau
  - src/ReplicatedStorage/Mine/Shared/MineZonePacks.luau
  - src/ReplicatedStorage/Mine/Shared/MineCharms.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - tools/gen/skins.js
  - docs/SKINS.md
  - tools/verify/skins.js
  - tools/verify/halloween-power.js
  - docs/TODO.md §0.13
  - docs/TODO.md §6.1
  - docs/OPEN.md P1 #9
  - docs/ROADMAP.md
related: [tools, ores, charms, boosts-and-stats, traits, chests-and-lucky-blocks, forge-and-recycling]
---

# Skins, cases and temper

> A **temperament** ("temper") is a stat kit you fit onto a tool family or a
> flagship tool. It is graded F to SSS. **Skins** (`MineSkins`, the Skins
> wardrobe) replace tempers as the main chase item: a skin is worn per tool
> family, multiplies the tool's damage and adds a stat kit. An **ore case** (an
> ore block has a 2% chance to drop one) always pays a skin or a charm; since
> the launch audit (2026-10-19, S14) the skin is a real wardrobe skin, not a
> temper.

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
- **One to five at once, stacked** (owner, 2026-10-19: every case *"up to 5
  slot spins at a time"*; `MineCaseStack`). The Enchanter's Summon tab has a
  1–5 picker on the Temperament Case row (the old ×10 / ×100 buttons are gone
  from it). `Verbs.openTemperCase` hands 1–5 to `Verbs.openTemperStack`: the
  whole price must be there first (all or nothing), every case is rolled
  before a token moves, each is granted and gets its own reel, and they spin
  stacked (`caseSpins`; one case is still the lone `temperCase` reel). The
  3-case bundle plays its three reels stacked too.
- **Batches over five show their best.** The server still takes a count of 10
  or 100 (nothing in the UI sends one now): it grants every roll but plays one
  reel, the **best** grade of the batch (since 2026-10-08; before, an SSS on
  roll 3 of 10 was granted and never shown). The reveal says "BEST OF N".
- **Skins in a pack run.** Ore cases open 1–5 at a time (the server clamps a
  run to five). An ore-case skin in a run carries its reel (`design.reel`) and
  spins on the stacked reels like a lone one; a charm from the same run stays
  in the pack reveal. The skin is also a card whose `rarityId` is a grade
  letter: `MinePackFX.rankOf` reads F…SSS on the same 1–8 ladder, so a skin of
  A or better is a bulk hit. Before that fix, every skin scored as a DUD and an
  SSS was folded into "N cleared".
- **Stat size.** Each stat is its slot share (1.00 / 0.60 / 0.35, from
  `MineTemper.BASE`) × `RARITY_MULT`. Chance stats use `ABS_PRIMARY` ×
  `PROC_RARITY_MULT` instead.
- **What the player sees.** Players see words, not letters (`WORD_OF`).
  - Since 2026-10-10 the words and colours are the cards' rarity ladder
    (owner: *"same goes for skin cases.. same rarities"*). S used to read
    "Mythic" along with SS and SSS.
  - The ladder: F Common grey, D Uncommon green, C Rare blue, B Epic purple,
    A Legendary orange, S Mythic light blue, SS Divine lavender, SSS Exotic
    red (`MineTemper.RARITY_COLOR`).
  - Pack cases' reels use the same ladder, and so does anything else that
    reads it. (Traits did too, through `MineTraitView`, until they were
    retired and that view deleted on 2026-10-12.)
- **Old saves.** `LEGACY_RARITY` and `normalizeRarity` map the old names
  Common…Exotic to F…SSS so old saves still load.
- **Gear grades, charms and the trader** read these same odds
  (`MineTemper.RARITY_WEIGHTS` in `MineGear`, `MineCharms`, `MineTrader`). Tool
  traits reused them too (TODO §0.18) until they were retired on 2026-10-12
  ([traits](traits.md)).

**Owning and fitting.**
- `p.tempers[kitId] = {rarity, n}` keeps the best grade seen and a copy count.
- `Verbs.equipTemper` fits a kit you own, for free, onto either a family
  (`p.toolTempers[fam].tempers[slot]`) or a flagship row. You can fit 1–2
  kits; the number of slots comes from `MineTemper.slotCount`.
- `boosts()` applies **one** temper set: the flagship's if you are holding a
  flagship, otherwise your tool family's (`p.toolTempers[fam]` via
  `MineTemper.applyTemper`). That family path runs for a shop rung (`tier > 0`)
  **or** a forged ore tool (`row.oreTool` / `row.oreTier` — forged tools return
  look-rung `0` on purpose). Fixed in `b0c2430`; pinned by
  `tools/verify/layers.js`. Tempers survive rebirth.
- Separately, equipped **MineSkins** (`p.skinEquipped[fam]`, one skin per tool
  family) dress **every tool of that family you hold**: forged, Event Horizon,
  Candy Crypt or chest (owner, 2026-10-19: *"one wardrobe everywhere"*).
  `equippedTool` puts the skin on the held row through `Dig.wearSkin`
  (`MineToolSkins.skinFor`, keyed on the row's `family`), so its base
  (`MineSkins.baseOf`: `MineSkins.BASE`, x1.15 at F to x5.5 at SSS, times the set's
  edge, below) multiplies the tool's power
  "off the rip", and it is stamped as `skinId`; `boosts()` folds that skin's kit
  into layer 1 and `givePickaxe` builds its look. Until 2026-10-19 the damage
  and the kit read the held FORGED tool only, so an event tool wore none of a
  skin's power. Checked by `tools/verify/skin-wear.js`.
- **Halloween tools love Halloween skins** (Candy Crypt v2, owner, 2026-10-19:
  *"make each tool different, but yeah always multiplier to the full
  multiplier"*). Each of the sixteen Halloween tools has its own factor
  (`MineCandyTools` `skinFactor`, 1.5 to 2.5), carried on the held row as
  `halloweenSkinFactor`; `MineToolSkins.mult(skin, tool)` multiplies a
  **Halloween-set** skin's whole damage multiplier by it (an S Halloween skin, x3,
  on a x2.5 tool is x7.5). Other skins, and Halloween skins on other tools, are
  unchanged; the kit stats are not scaled. Checked by `tools/verify/crypt.js`.
- **Equipping.** `Verbs.equipSkin({id, family})`: an empty id takes the skin
  off; an empty family means the class in hand (any tool); only a real tool
  class (`MineToolSkins.FAMILIES`) is stored. The toast says "(stats only)"
  when that class has no skin form for the set yet.
- **The wardrobe** (`MineSkinsView`, the Skins dock button) reads the class in
  hand from the snapshot's `tool.family` and marks that class's skin EQUIPPED
  (a skin worn on another class says "ON DRILL"); tapping it again takes it
  off. Every tile shows the skin's damage multiplier and its top stat, the line
  under the grid the whole kit, and "stats only" where the class in hand has
  no form. Until 2026-10-19 it read `heldFamily`, which the server never sends,
  so no tile ever said EQUIPPED. The Forge's skin picker shows the same power.

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
     - otherwise you get a **wardrobe skin** (launch audit S14, 2026-10-19).
       The grade rolls on a temper case's odds (`rollTemperament`, i.e.
       `RARITY_WEIGHTS` below) and `Dig.grantChestSkin`, the chests' own
       grant, pays a skin of that grade: never a pass skin, and a duplicate pays
       stardust. Same `temperCase` reel, built of skins
       (`MineToolSkins.caseReel`). Until then it was a temper filed in
       `p.tempers`, where the wardrobe never looks; tempers already owned keep
       the Enchanter's Temper tab.
   - **Never a tool, never ore.** 2% × 25% = 0.5% charm rate per ore block.
4. **Scrapping.** `Verbs.scrapTemper` pays `SCRAP_TOKENS`: F 1, D 2, C 5, B 20,
   A 177, S 555, SS 1,515, SSS 6,312. That is aimed at about 65% return on a
   case. Temper tokens also come from rebirth (`MineSkillData.rebirthTokens`)
   and from selling forever tools.

**Grade reveal and iridescence.**
- `MineGradeReveal` plays the step-by-step F→SSS animation that the server
  scripted with `MineToolGrades.rollClash`. Its header says gear crates; the one
  live `rollClash` caller in MineServer is opening a lucky block. It is
  **not** used for tempers.
- `MineIridescence` draws the shared S / SS / SSS badge: 1, 2 or 3 marks on a
  9-stop pastel gradient. The inventory, MineClient and the grade reveal use it
  (the sockets screen did too, until it was deleted on 2026-10-12).

## Halloween's top grades are 20% better (2026-10-19)

Owner, 2026-10-19 (Candy Crypt v2): Halloween Mythic+ *"pets and skins are 20% better
than the best normal ones, even after the event"*. Skins' Mythic+ is S, SS and SSS.
Every other skin of a grade shares one base and one budget, so `tools/gen/skins.js`
gives the Halloween set an **edge of 1.2** at those grades (`EDGE`, emitted as
`MineSkins.EDGE`) on both halves: the damage base (S x3.6, SS x4.8, SSS **x6.6**) and
the buff budget (348, 456, **600** points). `MineSkins.baseOf` multiplies the edge in,
and it is the only reader of the base (`MineToolSkins.mult`, the forged path through
`skinBase`, the wardrobe's `multText`), so the server, the Forge and the wardrobe agree.
`MineSkins.edgeOf` and `MineSkins.isHalloween` answer the rest. No seasonal gate: the
edge outlives the event. `docs/SKINS.md` has the table; `tools/verify/skins.js` checks
each kit spends its budget times its edge, and `tools/verify/halloween-power.js` that
each Halloween S/SS/SSS is 1.2x the best other skin of its grade on base and points.

## The pass set (2026-10-16)

MineSkins has a tenth set, **Season One Pass**: Gemfire (S), Geode Heart (SS),
Deepgold Seam (SS) and The Motherlode (SSS), leaning on Ore Haul, Chest Luck
and Rare Ore. Only the battle pass gives them, at tiers 20 / 40 / 60 / 80 of
the premium track.
- `docs/SKINS.md` heads it "Pass set — …". `tools/gen/skins.js` stamps the set
  `pass = true`, and `MineSkins.isPass` reads it.
- The chest skin case and the old temperament-to-skin migration both skip pass
  skins.
- The 225-skin roster and the drop model count only the core sets.

## Where it lives

| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineTemper.luau` | kits, odds, case, scrap | `KITS`, `RARITY_WEIGHTS`, `rollTemperament`, `applyTemper`, `caseReel` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | verbs, ore case open, case drop, the worn skin | `Verbs.openTemperCase`, `Verbs.openTemperStack`, `Verbs.rollTemper`, `Verbs.equipTemper`, `Verbs.scrapTemper`, `Verbs.equipSkin`, `Dig.wearSkin`, `Dig.grantChestSkin` |
| `src/ReplicatedStorage/Mine/Shared/MineSkins.luau` | the 229 skins (generated by `tools/gen/skins.js`) | `LIST`, `SETS`, `BASE`, `EDGE`, `baseOf`, `edgeOf`, `isPass`, `isHalloween` |
| `src/ReplicatedStorage/Mine/Shared/MineToolSkins.luau` | which skin a tool wears, and its power in words | `skinFor`, `wear`, `FAMILIES`, `powerLine`, `caseReel`, `STATS_ONLY` |
| `src/ReplicatedStorage/Mine/Shared/MineSkinsView.luau` | the Skins wardrobe | `mount` |
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
ids are shipped, and since 2026-10-19 the case's skin is a wardrobe skin. Skins
apply by one rule on every tool (damage, kit, look). Looks exist on hammers and
jackhammers for 9 sets; pickaxe, drill and explosive forms and the Season One
Pass palette are a Cursor job (`tools/cursor/tasks/skin-looks-more.md`), and
until then the screens say "stats only". Untested in the engine.

## Gotchas

- ~~**The family skin does nothing on a forged tool.**~~ **FIXED in `b0c2430`.**
  The old gate was `(tier or 0) > 0`; forged tools return look-rung 0, so the
  family temper never applied. `boosts()` now treats `oreTool` / `oreTier` as
  forged and applies `p.toolTempers[fam]` the same way as a shop rung.
  `tools/verify/layers.js` fails if the rung-only gate returns.
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

- Are skins cosmetic, or a power source? Docs disagree (`ROADMAP` says wrap-only;
  TODO §0.13 / §0.19 and the live code treat them as F→SSS stat kits). This
  blocks the rename and the art — do not invent; ask the owner.
- Should ore cases cost or need ore, as standing rule "ore only" says? Or does
  that rule cover only bought crates?
- ~~Should the family temper apply to forged tools?~~ **Yes in code** (`b0c2430`):
  same family `toolTempers` path as a non-forged held tool.

## See also

[tools](tools.md) · [charms](charms.md) · [boosts-and-stats](boosts-and-stats.md) ·
[chests-and-lucky-blocks](chests-and-lucky-blocks.md)
