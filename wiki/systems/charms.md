---
title: Charms
type: system
status: partial
verified: 2026-10-19 @ 3863d14
sources:
  - src/ReplicatedStorage/Mine/Shared/MineCharms.luau
  - src/ServerScriptService/Mine/MineCharmService.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineInventoryView.luau
  - tools/verify/charms.js
  - tools/verify/charm-tiers.js
  - tools/verify/economy-gems.js
  - src/ServerScriptService/Mine/MineCrypt.luau
  - src/ReplicatedStorage/Mine/Shared/MineCryptRules.luau
  - tools/verify/crypt.js
  - tools/gen-charm-icons.js
  - tools/icons/charm-sheet.js
  - tools/cursor/tasks/chest-and-charm-icons.md
  - src/ReplicatedStorage/Mine/Shared/MineTemper.luau
  - docs/TODO.md §0.13
  - docs/TODO.md §0.25
  - docs/TODO.md §6.1
  - docs/PROPOSAL.md §0
  - docs/AUDIT.md §4
  - docs/BLOCKED.md
  - roadmap/PRINCIPLES.md §1
  - roadmap/CHARMS.md
related: [skins-cases-and-temper, boosts-and-stats, ores, chests-and-lucky-blocks, traits, retired-and-parked, assets-and-uploads, currencies-and-economy, wandering-traders]
---

# Charms

> One equipped trinket that bends your mining numbers. The owner calls charms
> and skins "the build" (TODO §0.13). **Every charm has one rarity, F to SSS,
> forever, and a tier, I to V.** Merging raises the tier; it never changes the
> rarity (owner, 2026-10-19).

## How it works

- **One slot.** `p.equippedCharm`. `boosts()` in MineServer applies it with
  `MineCharms.applyEquipped(b, id, p)` **after** the two boost layers combine, so
  a charm sits in neither layer (`MineBoostLayers.LAYER1` / `LAYER2` do not name
  charms). See [boosts-and-stats](boosts-and-stats.md).
- **Owned as a tally, with tiers.** `p.charms[id]` is how many copies you hold (a
  legacy `true` counts as one, `MineCharms.ownsAnyCharm`). `p.charmTiers[id]` is
  `{ II = n, III = n, IV = n, V = n }`; every other copy is tier I. Every grant
  adds a tier-I copy through the old tally path, so no grant changed. The worn
  copy is your best one (`MineCharms.wornTier`). `MineCharms.normalizeTiers` trims
  a broken tier save on load, keeping the best copies. The snapshot carries
  `charmTiers`, and rebirth keeps it.
- **One rarity per charm, F to SSS, forever** (owner, 2026-10-19: *"each charm has
  its own rarity always. {sod charm rare always}"*). Every row carries `rarity`:
  - ore charms take their ore's band (Common F … Exotic SSS);
  - the zone, pack and limited rows were given one each (PROPOSED). The Sod
    Charm is C (Rare), the owner's own example, and Pot of Gold is S;
  - the graded and Crypt rows always had one.
- **Four families in `MineCharms.LIST`, 271 charms** (a fifth, the six crafted
  Halloween charms, was retired on 2026-10-19; see below):
  - **164 ore charms**, generated at module load from `MineConfig.ORES`: 82 ores ×
    `ORE_CHARM_VARIANTS` 2. Ids `<ore>_charm` (variant 1, the id old saves hold)
    and `<ore>_charm_2` (`MineCharms.oreCharmId`). Name `<Ore> <Word> Charm`. By
    rarity: F 36, D 22, C 40, B 22, A 18, S 12, SS 8, SSS 6.
  - **31 legacy charms**: 15 zone charms (`CHARM_ZONES` 5 zones × shallow/mid/deep
    by `bandForLayer`), 15 pack charms, and Pot of Gold (id `lucky_charm`, limited).
  - **68 graded charms** (`source = "charm"`): the 36 of 2026-10-07 and 32 more
    from 2026-10-19 (see below).
  - **8 Crypt chest charms** (`source = "crypt"`), one per Crypt chest rank.
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

## Tiers I to V, and merging (2026-10-19)

Owner: merging raises a charm's *"teir i to v"*, costing **gems plus any charm of
the same tier**, which is used up; it **never changes the rarity**. This replaced
the old merge, which turned one ore's charm into the next ore's (one tier of ore
deeper, a different shape) and left every non-ore charm unmergeable.

- **What a tier does.** `MineCharms.statsAt(def, tier)` multiplies each gift by
  `TIER_MULT`: I ×1.00, II ×1.20, III ×1.45, IV ×1.75, V ×2.10, rounded to a whole
  percent. A tier-V Acorn Charm gives +109% Mine Speed where tier I gives +52%.
  Two kinds of stat never grow:
  - **`TIER_FLAT`**: Gem Find, Ore Quality (`rareOre`) and Ore Finder
    (`fossilFind`), so a merge never prints gems;
  - **a pact's cost** (a negative stat) stays as it is at I, so it cannot pass −100%.
- **A merge** (`MineCharms.applyMerge(p, id, tier, fodderId)`, all or nothing):
  - one copy of `id` at `tier` goes up one tier;
  - one charm at the same tier is used up (`fodderId`, any charm; the same id
    needs two copies at that tier);
  - you pay `mergeGemCost(rarity, tier + 1)` gems.
- **The worn copy** is never used up to raise *another* charm. Two copies of
  the worn charm merge fine, and it stays worn, a tier up.
- **The gem price** is `MERGE_GEMS[rarity]` to reach II, ×3 (`MERGE_TIER_STEP`)
  for each tier above. `MERGE_GEMS`: F 500, D 1,000, C 2,500, B 6,000, A 15,000,
  S 40,000, SS 100,000, SSS 250,000 (PROPOSED). One charm's own four merges to V
  cost 40× that: F 20,000 … SSS 10,000,000. Climbing one copy all the way from
  sixteen copies at tier I takes 15 merges.
- **The verb** is still `mergeCharm`, now `{ id, tier, fodderId }`.
  `MineCharmService.merge` runs it; an old `{ id }` payload merges the lowest
  tier with the cheapest fodder. The server reads every price and count from
  MineCharms.
- **The screen** (Inventory → Equipment → a charm → MERGE): pick the tier, then
  the charm to use up (cheapest rarity first, never the worn copy,
  `MineCharms.fodderFor`). The gem price shows before you confirm. Each tile
  shows the charm's rarity and its best tier in roman numerals.

## The graded charms

### The 36 (2026-10-07)

Owner: *"make 36 charms. make them all unique, and each come in their own rarity.
they can be found in chests (0.5%) or bought with tokens"*, then the art for all
thirty-six (`charms2.svg`). Commits `b09cc4a`, `c1795ea`, `fd5c432`.

- **Graded, not zoned.** Each row has a `rarity` on `MineTemper`'s F…SSS ladder and
  **no `zoneId` or `band`** (`ZONE_BAND` indexes on those, so a row with both would
  also become a free zone grant). Magnitude follows the grade: primary about
  `RARITY_MULT × 1.15`, secondary about `× 0.35`.
- **The spread is 8/7/6/5/4/3/2/1 from F to SSS** (one SSS: Galaxy Core; two SS:
  Seraph Edge, Hourglass of Ages).
- **Rarity follows the art.** The grandest pictures take the top grades; a leaf, an
  acorn, a quill or a flask is F. The icon index is on each row (`icon = n`) so the
  pairing survives a re-export, and every row carries its uploaded `art` asset id.
  The first sheet's six charms were **replaced**; their assets were left in place
  rather than deleted. `tools/icons/charm-sheet.js` tiles the extracted icons into
  one contact sheet for review.

### Four more at every rarity (2026-10-19)

Owner: *"more charm types at every rarity"*, Common and Uncommon too.
`MineCharms.NEW_GRADED` adds 32, four per rarity, so the pools run F 12, D 11,
C 10, B 9, A 8, S 7, SS 6, SSS 5. Names, looks and stats are PROPOSED. The stats
follow the 36's scale (primary about `RARITY_MULT × 1.15`, secondary about
`× 0.35`). None carries Gem Find, Ore Quality, Ore Finder or Backpack, so the new
charms add no gem faucet. They have no art yet.

| rarity | the four |
|---|---|
| F | Clover Sprig, Lucky Penny, Firecracker Charm, Pebble Pal |
| D | Four-Leaf Clover, Horseshoe Charm, Cherry Bomb, Tin Soldier |
| C | Rocket Fin, Treasure Map, Thunder Egg, Honeycomb Charm |
| B | Comet Tail, Clockwork Heart, Coin Fountain, Lantern Fish |
| A | Phoenix Feather, Wizard's Monocle, Kraken Tooth, Golden Goose Egg |
| S | Storm Crown, Meteor Core, Moonstone Key, Unicorn Horn |
| SS | World Seed, Halo Ring, Supernova Shard, Golden Gauntlet |
| SSS | Black Hole Heart, Sunheart Crown, Rainbow Dragon Pearl, Big Bang Bell |

### How a graded charm is found

1. **Chest, 0.5%.** `MineCharms.CHARM_CHEST_CHANCE 0.005`, rolled in
   `openChestBlock` and **multiplied by `b.chestLuck`**. The half-percent decides
   *whether*; `MineCharms.rollChestCharm` decides *which*: the rarity first, by
   `CHEST_CHARM_GRADE_WEIGHT`, then any graded charm of it, each equally likely.
   The weights keep the 36's shares exactly (F 40,000, D 19,341, C 7,500,
   B 3,375, A 1,000, S 150, SS 20, SSS 2), so adding charms did not make any
   rarity commoner. Before 2026-10-19 each charm was weighted alone; the
   author's 20,000-roll measurement then was F 11,164, D 5,440, C 2,146, B 928,
   A 289, S 25, SS 7, SSS 1. There is **no first-charm guarantee** on this path.
2. **Tokens.** `Verbs.buyCharm` charges **temper tokens** from
   `MineCharms.CHARM_TOKEN_PRICE`: F 15, D 30, C 60, B 120, A 250, S 500, SS 1000,
   SSS 2500 (priced off `MineTemper.CASE_PRICE_TOKENS`). The server takes the price
   from the module, not the payload; only `source == "charm"` rows are buyable; it
   re-reads the balance inside the loop; a buy clamps to 1–10. A first purchase
   auto-equips if nothing is worn.
3. **A Charm Pack** (below).

- **Traders sell them too:** the Charm Case in [wandering-traders](wandering-traders.md)
  uses the same `rollChestCharm` ladder, so a charm is no commoner from a trader.
- `RARITY_LABEL` (grade → word) is built by **inverting** `MineTemper.LEGACY_RARITY`,
  so the reveal panel and the temper UI cannot disagree on a grade's name.
- `luck` is allowed here on the author's reading that the no-self-feeding rule
  bites ore-case charms only.

## The eight Charm Packs (2026-10-19)

Owner: *"charm packs for the main game, one per chest rarity ("{rarity} Charm
Pack")"*, sold for **gems or credits**, with gems held as a sink.

- `MineCharms.CHARM_PACKS`: F Charm Pack … SSS Charm Pack. Each pays **one graded
  charm of its rarity at tier I**, each as likely (`charmPackOdds`, `rollCharmPack`).
  A charm you own comes as another copy to merge. Prices are PROPOSED:

| pack | gems | credits | in minutes of that stage's gem income |
|---|---|---|---|
| F | 2,500 | 10 | 83 at the start |
| D | 7,500 | 15 | 18 early |
| C | 20,000 | 25 | 48 early |
| B | 60,000 | 45 | 52 mid |
| A | 175,000 | 80 | 151 mid |
| S | 500,000 | 150 | 40 late |
| SS | 1,500,000 | 280 | 121 late |
| SSS | 5,000,000 | 500 | 402 late |

- **The shelf** is Inventory → Equipment → Charm: eight rows with a GEMS button,
  a CR button and ODDS. The sheet reads `charmPackOdds`, the same list the server
  draws from (`View.sheet`).
- **The verb** `buyCharmPack { rarity, pay = "gems" | "credits" }`
  (`MineCharmService.buyPack`). The price comes from `CHARM_PACKS`, never the
  payload. The draw happens before the charge, so an empty pack charges nothing.
  The charm is tallied, and worn if nothing is.
- **Paid random rule:** `buyCharmPack` is on `Verbs.PAID_RANDOM`, so the region
  block covers it.
- **The old Charms Pack is retired.** The 2,500-gem pack of the 15 pack charms
  (`PACK_PRICE_GEMS`, `packPool`, `packOdds`, `rollPack`) is off the shelf. Its
  functions stay for old callers, and `buyCharmsPack` only answers *"The Charms Pack
  is now 8 Charm Packs, F to SSS"*.

## Halloween charms (2026-10-19)

**The six crafted Halloween charms are retired** (owner, 2026-10-19, "Candy Crypt
v2": *"SORRY CHEST ONLY CHARMS"*). They were crafted from candy ores
(`hallow_kernel` .. `hallow_skull`, `source = "candy"`, `cryptCraftCharm`), and
they are gone from `LIST` with their helpers (`candyCharms`, `recipeFor`) and the
verb. `MineCharms.RETIRED_CANDY_CHARMS` lists the six ids so
`MineCrypt.normalize` can take them out of a test save and off its slot.

**The Crypt's charms now come from Crypt chests only:** each of the eight Crypt
chest ranks has its own Halloween charm, `MineCharms.cryptChestCharm(rank)` (built
by another session), rolled by `MineCrypt.openChest` at **0.5% x Chest Luck**
(`MineCryptChests.CHARM_CHANCE`) and granted through the normal tally,
`p.charms[id]`. While the event runs it belongs to the **Halloween inventory**: it
counts only inside the Crypt, worn in the Halloween slot (`cryptCharm`), and not
in the main slot (`MineCryptRules.charmFor`); after the event it is an ordinary
charm ([world-events](world-events.md)).

- **Candy Find** (`candyFind`) multiplies the candy a block or Crypt chest pays
  (`MineCrypt` reads `boosts().candyFind`). **Event Digging** (`eventDig`)
  multiplies a Halloween tool's power (`MineCryptRules.eventDigOf` reads the
  charm that counts in the Crypt, at that copy's own best tier, because `boosts()`
  asks for the held tool and would loop). Both labels stay in `STAT_LABEL` for
  whichever charms carry them. Neither touches a normal tool, and Event Digging
  does not touch Event Horizon's.
- **Tiers count in the Halloween slot too.** `MineCharms.applyEquipped` asks the
  tier of the charm it is applying (`bestTier(p, id)`), not of the main slot, so
  a Halloween charm worn in the Halloween slot pays at its tier inside the Crypt
  (fixed in the merge of the two branches, 2026-10-23; `tools/verify/crypt.js`).

## The eight Crypt chest charms (2026-10-19)

One Halloween charm per Crypt chest rank: `MineCharms.cryptChestCharm(rankKey)`
takes "F".."SSS" and returns the charm id (nil for anything else). They are
`MineCharms.CRYPT_CHEST_CHARMS`, `source = "crypt"`, holiday Halloween. A Crypt
chest pays its rank's charm at 0.5% x Chest Luck (above). They are not
token-bought, not in a Charm Pack and not in the main game's 0.5% chest roll,
and they merge up the tiers. Their stats are `RARITY_MULT` × `CANDY_CHARM_SHARE`
(Candy Find 0.8, Event Digging 0.6, the normal stat 0.15: the rule the six
retired crafted charms used). Names and normal stats are PROPOSED:

| rank | id | name | normal stat |
|---|---|---|---|
| F | `hallow_wrapper` | Candy Wrapper Charm | Coin Bonus |
| D | `hallow_batwing` | Bat Wing Charm | Scrap |
| C | `hallow_catbell` | Black Cat Bell | Luck |
| B | `hallow_broom` | Witch's Broom Charm | Dirt Break |
| A | `hallow_spidersilk` | Spider Silk Locket | Chest Luck |
| S | `hallow_pumpkincrown` | Pumpkin King Crown | Swing Rate |
| SS | `hallow_ravenfeather` | Raven Moon Feather | Lucky Find |
| SSS | `hallow_cryptkey` | Crypt Keeper's Key | Mine Speed |

So the F charm gives +36% Candy Find, +27% Event Digging and +6% Coin Bonus, and the
SSS one +600%, +450% and +112% Mine Speed.

## Where it lives

| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineCharms.luau` | roster, rarities, shapes, tiers, merge rule, Charm Packs | `LIST`, `GRADED`, `NEW_GRADED`, `CRYPT_CHEST_CHARMS`, `cryptChestCharm`, `TIER_MULT`, `TIER_FLAT`, `statsAt`, `tierCounts`, `canMerge`, `applyMerge`, `fodderFor`, `mergeGemCost`, `MERGE_GEMS`, `CHARM_PACKS`, `charmPackOdds`, `rollCharmPack`, `rollChestCharm`, `applyEquipped` |
| `src/ServerScriptService/Mine/MineCharmService.luau` | the merge and Charm Pack verbs (`Verbs.Charm`) | `init`, `merge`, `buyPack`, `normalize` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | grants, equip, routing, the tier save | `Verbs.mergeCharm`, `buyCharmPack` route, `Verbs.PAID_RANDOM`, `equipCharm`, `finishBreak` (zone grant + ramp), ore-case branch of pack opening |
| `src/ReplicatedStorage/Mine/Shared/MineConfig.luau` | drop dials | `ORE_CASE_CHANCE`, `ORE_CASE_CHARM_SHARE`, `CHEST_LOOT` |
| `src/ReplicatedStorage/Mine/Shared/MineInventoryView.luau` | charm rows, the merge picker, the Charm Pack shelf | `onMergeCharm`, `onBuyCharmPack` |
| `tools/verify/charm-tiers.js` | runs the tiers, the merge, the service verbs, the packs and the Crypt contract | needs `syntax.sh` first |
| `tools/verify/charms.js` | runs the real generator in luau | needs `syntax.sh` first |

## Decided by the owner

- **§0.13 (2026-10-02):** charms + skins are the build. Later charms may be
  better, "but never because the number is bigger": a charm has a shape.
- **§0.13.5:** charms are a rare drop **from ores, not chests. "One charm per
  ore."** The code ships *two* per ore. That was an agent design (TODO §6.1), not an owner decision. See Open questions.
  **Amended 2026-10-07:** the 36 graded charms also come from chests (0.5%) and tokens.
  TODO §0.13 rule 5 records the exception (added 2026-10-17).
- **§0.25 (2026-10-04):** "rather than merging it should cost gems." So
  `MERGE_COST` (copies eaten) went from 3 to 1, and gems pay for each step.
- **PROPOSAL §0 line 20:** merge price stays `1200 × 1.14^(t−1)`. **Superseded
  2026-10-19** by the tier merge and its rarity prices.
- **PROPOSAL §0 line 33:** legacy 31: "keep the items, kill the three sources".
  **Not implemented yet** (see State).
- Owner, per AUDIT §4 (2026-10-04): "charms should not just be a huge family of
  clones. they would each be different and special in their own way."
- **2026-10-19** ([open-questions](../open-questions.md) §0e): one fixed rarity per
  charm, tiers I to V by merging (gems + any charm of the same tier), more charm
  types at every rarity, 8 Charm Packs for gems or credits. The numbers are PROPOSED.

## State right now

- **Shipped, never run in engine** (START-HERE §5): 164 ore charms, six shapes,
  first-charm guarantee. **Rarities, tiers, the new merge, the 32 new charms, the
  Crypt chest charms and the Charm Packs** are built and harnessed
  (`tools/verify/charm-tiers.js`), never run in the engine.
- **Gems hold their value** (`tools/verify/economy-gems.js`): gems in per hour are
  within +0.9% of `3863d14` at every stage. The strongest Gem Find on one charm is
  unchanged, because Gem Find never grows with tier. Charm Packs and merges only
  take gems.
- **Legacy sources still live:** the zone roll (`ZONE_DROP_ONE_IN` 10000, first
  charm guaranteed), the tutorial step 28 Sod Charm, the chest `charm` row (weight
  1.1, draws from `packPool`), and Pot of Gold via `MineRotatingOffers` / Robux.
  The Charms Pack is retired (above).
- **The Charm Packs show their odds** (launch audit M3); the wandering trader's
  Charm Case shows the chest ladder (`chestCharmOdds`).
- **Proposed, not built:** cut 164 generated charms to about 24 hand-authored rule-charms
  (AUDIT §4, OPEN §8). AUDIT's reason is that "a Diamond Surge Charm is a Coal Surge
  Charm with a bigger number". In numbers: there are only 86 signatures across 164 charms, so 78
  repeat an earlier signature at a different size (derived from `EXPECTED_SIGNATURES`; not stated in AUDIT).
- **Charm icons: only the first 36 graded charms are skinned.** `tools/icons/gen-charm-art.js`
  drew 164 PNGs into the gitignored `build/charm-icons/`. The owner rejected them;
  their reference is jewellery (TODO §0.27, BLOCKED #11). `tools/gen-charm-icons.js`
  turns `ids.json` into a `MineCharmIcons` module that does not exist yet. The
  graded 36 sidestep that: each row carries its own `art = "rbxassetid://…"` from the
  owner's `charms2.svg`. `tools/cursor/tasks/chest-and-charm-icons.md` is the Cursor
  job for every other charm.
- **The token shop exists.** `69f3de6` lists the buyable graded charms **after the
  owned ones** in the Inventory charm list (`opts.onBuyCharm`), and `MineClient` sends
  `buyCharm` with `{ charmId, count }`.

## Gotchas

- ~~**Client merge gate disagrees with the server.**~~ Fixed 2026-10-19: the merge
  picker asks the shared `canMerge` / `fodderFor`, and shows the gem price.
- **Stale comments:** the MineCharms header still says "THE FIVE SHAPES" and that
  ramp is "deliberately absent". PROPOSAL line 33 decided the legacy question.
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

- **Settled 2026-10-17** (owner: *"do what you think is best for the game"*): graded
  charms drop from chests, and TODO §0.13 rule 5 now says so; Chest Luck keeps scaling
  that 0.5% like every other chest reward, because one charm slot makes wearing a Chest
  Luck charm a trade-off.
- The 2026-10-19 numbers are PROPOSED: the tier multipliers, the merge prices, the
  Charm Pack prices, the legacy rows' rarities, and the 40 new charms' names and stats.
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
