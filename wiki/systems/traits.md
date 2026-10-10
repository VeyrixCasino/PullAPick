---
title: Traits (and the runes they replace)
type: system
status: partial
verified: 2026-10-05 @ 26036a0
sources:
  - src/ReplicatedStorage/Mine/Shared/MineTraits.luau
  - src/ReplicatedStorage/Mine/Shared/MineTraitView.luau
  - src/ReplicatedStorage/Mine/Shared/MineOreTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineRunes.luau
  - src/ReplicatedStorage/Mine/Shared/MineRunesView.luau
  - src/ReplicatedStorage/Mine/Shared/MineSocketsView.luau
  - src/ReplicatedStorage/Mine/Shared/MineScrolls.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau
  - tools/verify/traits.js
  - docs/TODO.md §0.17
  - docs/TODO.md §0.18
  - docs/TODO.md §0.22
  - docs/TODO.md §0.23
  - docs/PROPOSAL.md §0
  - docs/HANDOFF.md §2.5
  - docs/AUDIT.md §5
related: [tools, forge-and-recycling, hats-and-faces, boosts-and-stats, skins-cases-and-temper, pets, retired-and-parked, save-data-and-migrations]
---

# Traits (and the runes they replace)

> A **trait** is one prefix word on one forged tool, for example "Sharp Stone Pickaxe".
> You roll it at the Enchanter for gems. The owner asked for it on 2026-10-04 as the
> replacement for runes. It was first called an "enchantment" (TODO §0.17) and
> renamed "trait" the same evening (§0.23). "Enchant" is now reserved for a
> later feature. Runes, scrolls and sockets **still run alongside it**.

## How it works

- **Where it lives.** `tool.trait = { id, level }` sits on one `p.oreTools` row, keyed by
  uid. Only the tool in your hands pays: `boosts()` finds `p.oreToolEquipped`
  and adds `MineTraits.amount(id, level)` to **layer 1**
  ([boosts-and-stats](boosts-and-stats.md)).
- **The name.** `MineOreTools.name` calls `MineTraits.decorate`, giving
  `{Trait} {Ore} {Noun}`. The level is not part of the name. `MineTraits.label` gives
  "Exotic Wide V" for panels.
- **The roll.** The client sends `rollTrait {uid}` and `Verbs.rollTrait` does the rest. It costs
  `MineTraits.ROLL_PRICE` 500 gems, flat: no prestige, zone or tier scaling, and
  `traits.js` asserts that. `MineTraits.roll` makes three independent draws: a tier from
  `RARITY_WEIGHTS` (F 4200 · D 2700 · C 1600 · B 900 · A 400 · S 140 · SS 50 ·
  SSS 10, out of 10,000), then a trait uniformly within that tier, then a level 1–5
  (`MAX_LEVEL`). A new roll **replaces** the old trait with no undo; the toast names what was lost.
- **The ROLL button was dead until 2026-10-08.** `MineTraitView` checked
  `opts.onTrait` and then called `opts.onRollTrait`, which nothing passes, so
  no roll ever reached the server from the UI. It calls `onTrait` now. The
  server also sends a `traitRolled` result (`id`, `level`, `grade`, `label`,
  `oneIn`), and the client celebrates it with `MineCelebrate` by the trait's
  real grade. The trait tab now repaints on the snapshot after a roll, which
  it never did while the rune bench was mounted.
- **Odds.** Wide is the only SSS trait, so Wide is 1/1000 and Wide V is 1/5000. An SS
  tier is 1/200, so an SS V is 1/1000. Those are the skins table's own SS and SSS
  odds (`MineTemper.RARITY_WEIGHTS`), and `traits.js` checks the match against MineTemper.
- **Magnitude.** `amount = perLevel × level × rarityMult`, where `perLevel = clamp(BUDGET
  0.12 / MineStats weight, 0.02, 0.20)`. `rarityMult` comes from
  `MineTemper.RARITY_MULT` (F 0.45 → SSS 7.50), or from `PROC_RARITY_MULT` (F 0.30 →
  SSS 1.30) for `MineTraits.CHANCE_STATS`. Values at level V, derived from today's weights:
  Sharp +27%, Lucky +31.5%, Blasting +16.8 points of blast chance, Wide +75% radius.

| tier (odds of the tier) | traits: prefix = stat |
|---|---|
| SSS Exotic (1/1000) | Wide = blastRadius |
| SS Divine | Blasting = blastChance, Grinding = pulverize |
| S Mythic | Charmed = luckyFind, Violent = procPower, Rumbling = earthquake |
| A Legendary | Shocking = zap, Cooled = coolant, Bouncing = ricochet (paid as **Shatter** since 2026-10-10) |
| B Epic | Prospecting = oreLuck, Fated = packLuck, Hasty = shortFuse, Prying = chestLuck |
| C Rare | Lucky = luck, Gleaming = gemFind, Rich = rareOre |
| D Uncommon | Seeking = fossilFind, Swift = swingRate, Reaching = reach, Salvaging = scrap |
| F Common | Sharp = mineSpeed, Churning = dirtBreak, Golden = coinBonus |

That is 23 traits. Deep (backpack) and Fleet (walkSpeed) were removed with their stats,
and §0.17's "25" predates that.

## The Enchanter

The Enchanter is a building; the panel code keeps its old names (`enchantP`, `showEnchantTab`,
`enchantTabs`, `onOpenEnchanter`) on purpose (§0.23). Its tabs, in order (MineClient
`refreshEnchanter`): **Traits** (the landing tab, `MineTraitView`), **Merge** (the rune bench,
`MineRunesView`), **Sockets** (`MineSocketsView`), **Summon** (rune rolls plus hat
crates), **Temper** (`MineForgeView.mountList`), **Salvage**, **Dust**. The
Traits tab is a guarded require that `warn`s if it fails (§0.14), and every number on
it comes from `MineTraits` (`odds()`, `ROLL_PRICE`).

## Runes, scrolls and sockets: still live

- **Runes** (`MineRunes`, save field `p.runes`). Rolled at Summon (`Verbs.rollRuneBanner`,
  `MineRunes.rollPriceFor(zone)` = 25 × 1.2^(z−1)). Fused with `Verbs.fuseRunes`
  (`FUSE_SUCCESS` 0.50, gems `50 × 3.5^(t−1)`, `MAX_FUSE_LEVEL` 99). A rune can be socketed into
  a tool family (`p.toolSockets[fam].main` / `.omni`), a chest tool (`runeId`), a shop
  tool (`p.shopToolRunes`), a pet (`p.petSockets`) or a gear piece (`piece.sockets`, 1 each).
- **How runes pay.** In `boosts()`, *after* the layers combine, each worn rune pays
  `SOCKET_GAIN` 1.5×, and `MineRunes.applySetBonuses` adds set bonuses. A pet's rune is read
  twice by design: once as its own stat, and once as `WEAR_BROAD` 0.45 × pct on that pet's
  whole kit, inside `MineGear.stackPets`.
- **`boosts()` ends with `MineRunes.clampBoosts(b)`**, so MineRunes cannot be deleted
  until that clamp moves.
- **Scrolls** (`MineScrolls`, save field `p.scrolls`, bought with credits). White protects a fuse, Black
  unsockets a rune, Omniscroll adds a second tool socket, and the Runesmith bundle sells all three. The same module
  also carries the live `CREDIT_PACKS` and `BATTLE_PASS` products, so it is not rune-only.
- **The tutorial still teaches runes.** `Intro.steps` 8 ("ROLL A RUNE"), 9 (requires
  `socketToolRune`) and 11 (the RUNES tab).

## Decided by the owner

- §0.17, 2026-10-04: *"replace runes with enchantments… its a prefix too your tool
  (Sharp Stone Pickaxe, Lucky Stone Drill)"*, then *"and gear aswell"*.
- §0.18: rarity rides the skins ladder; Exotic 1/1000, Exotic V 1/5000; level is
  uniform; the price stays flat across rebirths, because *"broke players aren't going to try
  to get exotic V, endgame players will"* (as quoted in PROPOSAL §I).
- §0.23, as quoted in the MineTraits header: *"Rename runes/enchantments to traits,
  enchants will come later."* TODO §0.23 prints it as "runes/traits to traits",
  which is the rename's own find-and-replace hitting the quote.
- PROPOSAL §0: line 19 keeps the trait roll at 500 gems flat; line 27 says trait pity is **NONE**;
  line 18 keeps the rune fuse at `50 × 3.5^(t−1)`.
- §0.19 overrode "and gear aswell": gear stays, as a flat layer-2 boost.
  See [hats-and-faces](hats-and-faces.md).

## State right now

- **Traits are shipped but have never been run in the engine** (START-HERE §5).
- **Stage 3 has not started:** migrating runes and gear, then retiring `MineRunes`,
  `MineRunesView` and `MineSocketsView`. OPEN P2 defers it until traits are verified in-engine.
  `MineTraits.fromStatAmount` / `bestOf` were written for that migration and nothing calls them.
- AUDIT §5 lists runes for ARCHIVE. They have not been moved.

## Gotchas

- **Three names for one lineage.** TODO §0.17–0.22 still say `MineEnchants`,
  `MineEnchantView`, `enchantTool` and `enchants.js`. Today they are `MineTraits`,
  `MineTraitView`, `Verbs.rollTrait` and `tools/verify/traits.js`.
- **"Trait" also names a pet's per-print perk** (`MineCards.TRAITS`, for example Lone Wolf).
  That is unrelated. See [pets](pets.md).
- A trait `id` is save data (see the MineTraits header). Change `prefix`, never `id`.
- The MineTraits header says "+120% at level 10". That is stale: `MAX_LEVEL` is 5.
- Seeking pays `fossilFind` ("Ore Finder"). A grep found no live reader of `b.fossilFind` on
  the ore path in MineServer, so it may be a dead prefix (unverified; see
  [boosts-and-stats](boosts-and-stats.md)).
- Set runes take their stat straight from `MineRunes.SETS` and bypass `NO_ROLL_STATS`
  (HANDOFF §2.3).

## Open questions

- **Pity.** OPEN §12 still lists "pity counters on… trait rolls", but PROPOSAL line 27 says none.
- **Runes as a gem sink.** TODO §0.13.7 (locked) names runes a gem sink, yet runes are being retired. What replaces them as the sink?
- **Stage 3.** Do old runes and gear convert into traits through `bestOf`, or get refunded?
- **Temper and Sockets tabs.** Should they move to the Forge (OPEN §15)?

## See also

[tools](tools.md) · [forge-and-recycling](forge-and-recycling.md) ·
[retired-and-parked](retired-and-parked.md) ·
[save-data-and-migrations](../code/save-data-and-migrations.md) ·
[ambiguous-terms](../ambiguous-terms.md)
