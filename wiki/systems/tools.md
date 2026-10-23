---
title: Tools
type: system
status: current
verified: 2026-10-19 @ 3863d14
sources:
  - src/ReplicatedStorage/Mine/Shared/MineOreTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineToolSkins.luau
  - src/ReplicatedStorage/Mine/Shared/MineTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineIcons.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineBreaking.luau
  - src/ReplicatedStorage/Mine/Shared/MineShopLadders.luau
  - src/ReplicatedStorage/Mine/Shared/MineBandTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineHorizonTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineCandyTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineCryptRules.luau
  - src/ReplicatedStorage/Mine/Shared/MineToolGrades.luau
  - src/ReplicatedStorage/Mine/Shared/MineHotbar.luau
  - src/ReplicatedStorage/ToolModelFactory.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ServerScriptService/Mine/MinePatterns.luau
  - tools/verify/tool-dps.js
  - docs/TODO.md §0.13
  - docs/TODO.md §0.15
  - docs/TODO.md B1
  - docs/TODO.md B2
  - docs/PR-BALANCE-PASS.md
related: [ores, forge-and-recycling, mining-and-breaking, skins-cases-and-temper, enchants, traits, chests-and-lucky-blocks, shops-and-monetisation, assets-and-uploads, verify-suite]
---

# Tools

> Pickaxes, drills and explosives. The main tool is now **forged from ore** and
> named after it, for example "Stone Pickaxe". **The coin shop no longer sells
> tools** (`9733a05`, below). Chest flagships, zone shops and Event Horizon
> tools still exist alongside it.
> A tool has **damage**, which grows with level, and **breaking power**, which
> is fixed by its ore. These are two separate gates.

## How it works

**What you are holding.** `equippedTool(p)` in MineServer checks, in order:
1. **Event Horizon tool** (zone `bigbang`): `MineHorizonTools`, one per dirt
   section, paid in space coins.
   **Then the Candy Crypt's swap** (Candy Crypt v2, 2026-10-19,
   `MineCryptRules.heldRow` via `MineCrypt.heldTool`): in a zone with
   `eventToolsOnly` (the Crypt) the player's Halloween tool in hand
   (`MineCandyTools`, `p.halloween.tool`), or empty hands; outside, once the
   Crypt has closed, the Halloween tool they chose to keep holding
   (`p.cryptToolWorld`), hitting like a forged tool of its family whose ore and
   level come from its rank and prestige (the Jawbreaker Auger at prestige 10 is a
   level-30 Oganesson drill). Otherwise it returns nil and this list carries on.
   Halloween tools are sixteen, one per candy ore, in four families, take their
   mechanics from the forged frames, are **crafted** from candy ores and
   **prestiged** 1-10 (no levels, no merging), and are never sold or dropped. See
   [world-events](world-events.md). `equipOreTool` and `equipTool` put a kept
   Halloween tool down in the main world.
2. **Forged ore tool**: `p.oreToolEquipped` (a uid) → a `p.oreTools` row
   `{uid, typeId, familyId, tier, level, enchants?}`. `tier` is the **ore's index**
   in `MineConfig.ORES`. Rack cap 200. `enchants` holds the tool's Damage /
   Utility / Special books ([enchants](enchants.md)). Rows carried a `trait`
   until 2026-10-12; load clears it now ([traits](traits.md)).
3. **Chest flagship / "forever tool"** (shop "Secrets" tab): `p.chestTool` in
   `MineTools.CHEST_TOOLS`, `MineBandTools` (80) or `MineTools.PASS_TOOLS` (3).
   Zone chests call `rollChestTool` on open (forward-declared before
   `openChestBlock` — open-questions #7 fixed 2026-10-14). Rarity words map to
   ★ via `MineStars.beside` on the Secrets chip and Found forever-tool lines.
   Full B3 themed sets / new tables still owner.
4. **Zone shop tool**: `p.shopToolId`, `MineShopLadders` (19 per zone, 190).
5. **Coin ladder**: `MineTools.TOOLS` — 25 pickaxes (incl. `wood_pick`), 16
   drills, 16 explosives; `p.tools[fam]` = highest rung owned, `p.toolTier[fam]`
   = rung held. These rows are also the **frames** for forged tools.
   **Since `9733a05` nothing sells them for coins**: `MineConfig.FORGE_ONLY_FAMILIES`
   (pickaxe, drill, explosive, weapon) is refused at the surface shop, the depth
   desks and the legacy `buy "pickaxe"` action (`buyTool`, `buyDepthTool`). The
   roster is kept because `MineOreTools.frames()` filters it on `price > 0`: the
   prices are now a forge input, not a shelf price.
6. `MineConfig.BARE_HANDS` if no pickaxe was ever collected.

**The skin rides whatever is held** (owner, 2026-10-19: *"one wardrobe
everywhere"*, event tools wear the same skins). That list is `Dig.toolInHand`;
`equippedTool` hands its row through `Dig.wearSkin`. The skin worn on the row's
family (`MineToolSkins.skinFor`: any record with `family`, or a forged row's
`familyId`) multiplies the tool's power by `MineSkins.baseOf` (`MineSkins.BASE`,
x1.15 at F to x5.5 at SSS, times the Halloween set's 1.2 edge at S to SSS since
2026-10-19: [skins](skins-cases-and-temper.md)), and is stamped on the row as `skinId`. The kit stats (`boosts()`), the
look (`givePickaxe`, a thrown charge) and the damage therefore read one skin, on
forged, Event Horizon, Candy Crypt and chest tools alike. Until then the damage
and the kit read the forged tool's uid only, so an event tool wore no skin power.
A path added to `toolInHand` just returns a row with a `family`; it must not
multiply the skin itself (a row carrying `skinId` is left alone).

Families: pickaxe (aim, swing), drill (hold), explosive (throw, cooldown);
weapon is planned (`MineTools.FAMILIES`). Forgeable: `MineOreTools.FAMILY_ORDER`
(`pickaxe`, `hammer`, `drill`, `jackhammer`, `explosive`).

**Drills are instant** (owner, 2026-10-16: *"jack hammer spins up, drill is isntant"*):
- the swing (`swingBlock`) gives every drill zero spin-up, whatever its row says;
- the forged drill, the coin-shop drills and Event Horizon's bores carry `turn = 0`;
- only the jackhammer spins up.
- The deep coin drill's `zeroturn` special no longer sets it apart.

**Family niches (B1 LOCKED 2026-10-14; B2 retuned same day).**

| family | niche |
|---|---|
| pickaxe | fastest melee; chips single blocks |
| **hammer** | **slow / heavy / single-target**: hardest hit **and** highest single-block `dps` of every family (`FAMILY_POWER.hammer = 3.7`). Sink 2 is depth only — still single-target across |
| drill | aimed area (up to 3×3); single-cell `dps` below hammer |
| jackhammer | drill that only digs down; same single-cell `dps` as drill (`FAMILY_POWER` cancels 1.5× rate). It spins up (`turn` 1.2 s; Coolant shortens it) |
| explosive | area king: same-grade full-footprint `edps` tops the chart (`FAMILY_POWER.explosive = 4` + line depth bake + mid cooldown/line length). Higher-grade tools may beat a low explosive |

**DPS table (TODO B2).** `tools/verify/tool-dps.js` computes single-block `dps`
and full-footprint `edps` from live `toolPower` × `FAMILY_POWER` × `FRAME_STATS`.
Explosive `edps` uses `blocksPerBomb × bombs` — for line patterns
`max(cells, depth)` so coverage matches `MinePatterns.line` (depth is baked on
`FRAME_STATS.explosive` and copied onto the equipped tool). Asserts: pick faster
than hammer; hammer crowns single-block `dps`; jackhammer ≈ drill; same-grade
explosive `edps` tops the chart. Run: `node tools/verify/tool-dps.js`.

**Forged tools** ("a forged tool IS its ore", TODO §0.15). Name `{Ore} {Noun}`
(`MineOreTools.name`). Until 2026-10-12 a trait prefix went in front, from the
now-deleted `MineTraits.decorate`; `name` keeps an ignored `_trait` argument so
old callers still work. The frame is
never picked: `MineOreTools.frameForTier` maps ore tier 1..82 proportionally
onto the family's priced rungs (24 / 16 / 16). `typeMult` = the frame's
`RARITY_RANK` (stamped by `MineTools.rarityForTier`). Craft, level and scrap at
the [Forge](forge-and-recycling.md).

**Levels.** `MineConfig.TOOL_MAX_LEVEL = 30` (commit `d505d6c`, was 100; owner
wanted an advertisable *"each level UP%X"*). Rates come from `perLevel(total)`:
`TOOL_DMG_STEP = 350^(1/29) ≈ +22.4%`/level; a full climb is
`TOOL_CLIMB_DAMAGE 350` (one zone's HP growth). `MineConfig.toolUpgradeCost` =
own ore `TOOL_ORE_BASE 4 × TOOL_ORE_GROW^(L-1)` + stardust `25 ×
TOOL_DUST_GROW^(L-1)`, both × `toolCostMult` (bell `TOOL_COST_BANDS`, Epic ×18
peak, Exotic ×1 floor, × `typeMult^0.5`). A new forge inherits the best level on
the rack (`12b528a`). Over-cap saves are clamped on load (`TOOL_CAP_V`), no refund.

**Damage.** `MineConfig.toolPower = TOOL_DMG_BASE 10 × toolTierPower(tier) ×
typeMult × STEP^(L-1)`; `toolTierPower = 6^(TOOL_TIER_SPAN 7 × (t-1)/81) ×
TOOL_BAND_DMG` (Legendary ×2, Mythic ×4, Divine ×8, Exotic ×16 — because tiers
68–82 buy no new ore access at reach 15). Row finishes: Shiny ×1.5, Shadow ×3,
Nightmare ×4.5 (`SHINY_MULT` etc.). A held forged tool hits for
`MineOreTools.hitPower`: that power × `FAMILY_POWER` × the worn skin's base,
floored, then the finish. The Forge's cards print the same function (launch
audit S11, 2026-10-19; a Stone Hammer card said 10 and hit 37).

**Breaking power** (§0.13 rules 1, 2, 11) is never damage.
`MineBreaking.toolBreakingPower`: a stamped `breakingPower`/`bp`; else, if the
tool has `oreId`/`ore`, `oreStrength(oreTier)` on a 1..1000 scale; else
`SHOP_POWER[rung]` (`{1,2,3,4,5}`).

**Tutorial wooden pickaxe** (§0.13 rule 10). `Verbs.grantFirstPick` sets
`p.tools.pickaxe = 1` (coin rung `wood_pick`). `WOOD_PICK_MAX_LEVEL 5`, cost
`WOOD_PICK_COIN_BASE 35 × WOOD_PICK_COIN_GROW 1.55^(L-1)` coins; at the cap
`Verbs._graduateTutorialPick` grants `TUTORIAL_GRADUATION_TOOL = "stone_pick"`.

**Models and icons.** `givePickaxe` builds the Roblox Tool. Forged tools look up
their mesh by ore name via `ToolModelFactory.fromNamed` in
`ReplicatedStorage.ToolModels_50` (Studio-only, ~80 MB, not in git — AGENTS.md);
otherwise procedural, coloured by `ToolModelFactory.oreLook`.

**2026-10-07: 2,060 of those models were archived to `ServerStorage`.** Measured
in a live client, `ToolModels_50` held 4,148 models / 80,797 instances and was
**58% of every client's datamodel** (137,444 instances, replicated to every player
on join). Only **196** were referenced by anything live — they match
`MineShopLadders.LIST` names; the other 3,952 appeared in no live module, only in
the `Wave13Batches` generator scripts that produced them. The 2,060 heaviest
(70,040 instances, ~33 each: 6 real meshes plus a particle/trail/highlight/light
rig sitting in cold storage) moved to
`ServerStorage.ToolModels_50_Unreferenced`. Client `InstanceCount` went
**137,444 → 67,537**, and shop resolution was unchanged at 196 resolved / 54
procedural / 0 errors.

- **It is named `_Unreferenced` deliberately.** `ToolModelFactory.toolModelsRoot()`
  returns the **first** container it finds (ReplicatedStorage → ServerStorage →
  workspace) and does not search across them, so a `ServerStorage` folder sharing
  the name would silently become the live roster if the ReplicatedStorage one were
  ever removed.
- **`git` cannot revert this.** `ToolModels_50` lives in the place file, not the
  Rojo-synced tree. Reversing it means dragging the folder back in Studio; the
  owner chose moving over deleting to keep that option.
- A `fromNamed` miss degrades to a procedural model, so a wrongly-archived tool
  shows up as a plain mesh rather than an error. Verify any change here by
  counting shop resolution: `MineShopLadders.LIST` must stay 196 resolved / 54
  procedural.
- **Measuring the client in Studio play-solo:** trust `Stats.InstanceCount`, not
  `GetTotalMemoryUsageMb()`. Play-solo shares one process with the server, so the
  archive still occupies memory there and the memory figure hides the win.
`src/ServerStorage/OreToolBaker.luau` bakes the 82 heads. `MineToolIcons` is a
spritesheet atlas for named tools.

**Hotbar and equip.** `MineHotbar` switches off Roblox's Backpack CoreGui (the
"grey cube"): max 5 slots, 1 tool slot (2 for VIP), the rest for consumables;
clicking the held slot sends `equipOreTool` with an empty uid (unequip).
`Verbs.equipOreTool(uid)` sets `p.oreToolEquipped`, clears flagship and shop-tool
picks, and calls `givePickaxe`. **Rebirth** keeps forged tools, levels and the
equip; the coin ladder resets.

## Where it lives

| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineOreTools.luau` | forged naming and frames; the Forge's numbers, shared by the verbs and the cards | `name`, `frameForTier`, `oreOf`, `typeMult`, `hitPower`, `cardStats`, `craftCost`, `recycleRefund`, `inheritedLevel` |
| `src/ReplicatedStorage/Mine/Shared/MineToolSkins.luau` | which skin a tool wears, by family, on any tool | `skinFor`, `wear`, `familyOf`, `FAMILIES`, `powerLine`, `caseReel` |
| `src/ReplicatedStorage/Mine/Shared/MineTools.luau` | coin ladder, flagships, pass tools | `TOOLS`, `CHEST_TOOLS`, `PASS_TOOLS`, `RARITY_RANK` |
| `src/ReplicatedStorage/Mine/Shared/MineConfig.luau` | level and damage curve | `TOOL_MAX_LEVEL`, `toolPower`, `toolUpgradeCost`, `TOOL_BAND_DMG` |
| `src/ReplicatedStorage/Mine/Shared/MineBreaking.luau` | breaking power gate | `toolBreakingPower`, `SHOP_POWER`, `canBreak` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | what is held, its skin, equip | `equippedTool`, `Dig.toolInHand`, `Dig.wearSkin`, `givePickaxe`, `Verbs.equipOreTool` |
| `src/ReplicatedStorage/Mine/Shared/MineHotbar.luau` | custom hotbar | `mount` |

## Decided by the owner

- Ore tier = breaking power; level never raises it; damage is separate (§0.13
  rules 1, 2, 11). Name = `{Ore} {Noun}`; the frame is derived; levelling costs
  the tool's own ore (§0.15). The wooden pickaxe is a 5-level tutorial pick paid
  in coins (§0.13 rule 10).
- Cap 30 (owner, 2026-10-05; `docs/PR-BALANCE-PASS.md` §2).
- **No coin-bought tools** (owner, 2026-10-05, quoted in the `9733a05` comments:
  *"i think its time to get rid of all coin bought tools"*). Every tool family is
  forged from ore. Backpacks, the Ore Pouch and chest Secrets stay. The wooden
  pickaxe is given, never sold, and the commit says it **still levels on coins**
  (`MineConfig.isCoinTool`), kept on purpose as the on-ramp to the Forge.
- **Every ore tier has its own pickaxe skin** (`MineIcons.ORE_PICK`, one asset id
  per tier; `Icons.forTool(tool)` is the one rule the hotbar, Forge and inventory
  share). `tools/verify/oreskins.js` asserts the ids are distinct.
- **New icons from Canva, one per ore** (owner, 2026-10-11).
  - **Hammers and jackhammers** got icons for the first time (`ORE_HAMMER`,
    `ORE_JACKHAMMER`). The owner approved them, with Frostfire redone as fire
    against ice.
  - **Pickaxes 1–81 are redone** (`ORE_PICK_CANVA`). The owner: *"i like
    PICKAXE 82, BUT REDO THE RESTs ... make sure the colors make sense"*. Tier
    82 keeps the original.
  - **Drills and explosives 1–81 are redone too** (`ORE_DRILL_CANVA`,
    `ORE_BOMB_CANVA`, 2026-10-18). Some were redrawn on 2026-10-19:
    - explosives 19, 29, 65, 67, 68, 71 and 77, because the first cut-out
      clipped the fuse spark (65 to 77 got a flatter star spark);
    - pickaxes 52 and 57, because their heads read as axes.
  - **Jackhammers 75–82 are done** (2026-10-19). Every family now has an icon
    for every ore (`oreskins.js`).
  - **All of it is on** (`MineIcons.NEW_TOOL_ICONS_SHARED`, 2026-10-19). The
    owner shared the uploads ([assets-and-uploads](../code/assets-and-uploads.md)).
- **Decided, not shipped:** `WOOD_PICK_COIN_GROW` 1.55 → 1.40 (PROPOSAL §0 line
  12).
- **B1 hammer niche LOCKED (owner, 2026-10-14):** slow / heavy / single-target,
  hardest hit, **and** highest single-block DPS of all families. Code:
  `FAMILY_POWER.hammer = 3.7` (was 2.2 pickaxe-parity), half rate, sink 2.
- **B2 explosive area crown (owner, 2026-10-14):** same-grade explosive `edps`
  from the full blast footprint tops other families. Code:
  `FAMILY_POWER.explosive = 4`; line `depth` baked + wired through `equippedTool`;
  line cells/depth 42–46 and 53–57 lengthened to 13; mid sphere cooldown trimmed.

## State right now

The forged-tool system is shipped. As of 2026-10-10 all 246 tools build, are
visually distinct, and none is invisible — measured against the live modules,
not inferred.

### What a tool actually looks like (2026-10-10)

**Procedural Parts are the only thing that renders.** Every MeshPart archive in
this place is EMPTY: `ToolKitMeshes` 102/102, `ToolModels_50` 2,058/2,088,
`ToolModels_50_Unreferenced` 2,060/2,060, all with
`MeshContent = Content{SourceType=None}`. They came from
`AssetService:CreateMeshPartAsync`, whose geometry is session-only and does not
survive a place save — see [editablemesh constraint](../code/tools-and-generators.md).
`fromNamed` and `tryToolKitMesh` both refuse an empty mesh now (`71386b0`) and
fall through to the part builders.

**Fifteen silhouettes, five per family** (`6c08171`), chosen by the ore's place
on the roster so the shape climbs the ladder:

| family | styles |
|---|---|
| pickaxe | hook · adze · warpick · crescent · spire |
| drill | auger · tri-bit · ring corer · percussive hammer · lance |
| explosive | orb · keg · canister · cluster · faceted prism |

Only the business end swaps; haft, grip and motor stay shared so a drill still
reads as a drill. Measured: 16–17 ores per style in every family, 246 built,
0 invisible.

**Hammers and jackhammers, built to the icons** (2026-10-11). Owner: *"i need
the hammers and jackhammers fully built in.. every tool, every ore, all color
ways.. extremely hq"*. `buildHammer` and `buildJackhammer` were rebuilt to match
the Canva icons (`art/tool-icons/`). Each is the same silhouette at every ore,
made of the ore (`oreLook`), and checked in Studio: all 82 of each build with no
errors, at 39–59 and 45–68 parts.
- **Sledge:** swelled throat, ferrules, an 8-turn wound grip and a three-piece
  pommel. The head has bevelled edges, face plates with bosses, bands, cheek
  panels with a rune slot (a glowing decorative part, not a socket) and rivets,
  a collar and a wedge.
  - Stone-age ores (rock, not metal) are rope-lashed and chipped instead.
  - From t 0.35 it gains langets, from 0.62 shards of its ore, from 0.85 crown
    fins and a pommel gem.
- **Jackhammer:** T-bar with ridged grips and caps, braces and a throttle; a
  finned air cylinder, a slotted muffler, and an air coupling with a curved
  hose. Below that a striker with bolts, a retainer latch, an octagonal shank
  and a flat chisel. Plates from 0.35, shards and an energy ring from 0.62,
  coils and a gem from 0.85.
- The Handle part, `GRIPS` and `SCALE` are unchanged, so both sit in the hand
  where they did.

**Frostfire is split** (all five families). Owner: *"should feel like more of a
fight between fire and ice ... MAKE SURE FROSTFIRE IS GOOD"*. `oreLook` gives
Frostfire a `split`, and `applySplit` runs after every builder:
- parts left of the tool's centre turn to Ice, right of it to bright orange
  fire with Neon embers;
- a part running across the centre (a hammer head, a crossbar) is cut in two,
  with a white-hot seam between the halves;
- what cannot be cut goes by height (ice low, fire high);
- a flame particle rises off the fire side.

**Skins have a look on hammers and jackhammers** (`ToolModelFactory.buildSkinned`,
`SKIN_FORMS`, `SKIN_PALETTES`). The owner picked "Ore look + skins". Each of the
9 skin sets has the form `docs/SKINS.md` gives it (Toybox mallet and pogo stick,
Cursed gravedigger's maul and iron stake, and so on: 18 forms).
- **Shared per set:** palette, material and trim.
- **Per skin:** an accent from its id.
- **Per grade:** trim from B, glow and a PointLight from S, sparkles at SSS.
- **The ore still shows:** an inlay gem in the ore's colour.
- `givePickaxe` builds the form of the skin `equippedTool` stamped on the held
  row (`row.skinId`), on any tool of the family; so do a thrown charge
  (`flingCharge`) and the Forge hub's stage for a tool you own.
  `Verbs.equipSkin` re-gives the tool, so the look changes at once.
- All 18 build at 15–38 parts. They are a solid first pass, simpler than the
  ore tools.
- Pickaxe, drill and explosive skins still have no look, and neither has the
  Season One Pass set on any family (it has no palette). Every screen says so:
  "stats only" wherever `ToolModelFactory.hasSkinForm` is false (it now needs a
  palette as well as a form). The Cursor job
  `tools/cursor/tasks/skin-looks-more.md` builds the other 32 forms.

**The colour and material come from the ore** (`0b041f8`), via
`ToolModelFactory.oreLook` reading `color / material / met / rough / glow`
straight off the `MineConfig.ORES` row — the same row that colours the ore
block, so a Copper pick matches the copper you mined.

## Gotchas

- **Fixed in `b19c4c2`: forged tools used to have breaking power 1 at the gate.**
  The row `equippedTool` synthesised for a forged tool had no `oreId`, `oreTier`
  or `breakingPower`, so `MineBreaking.toolBreakingPower` fell through to
  `SHOP_POWER[1] = 1` and every tool stalled at zone 1, layer 50 (measured live
  by the fix's author). The row now carries `oreTier` and `oreId`, derived per
  swing. `tools/verify/heldtool.js` runs the real function against the real row
  shape. **Event Horizon tools and coin-ladder rows take a different path and
  that commit does not mention them**, so their breaking power is not rechecked.
  - There are still three different "breaking power" numbers: the `BreakPower`
    attribute (`MineConfig.toolBreakingPower`, the raw ore tier), the equip toast
    (the raw tier) and the gate (`oreStrength`, 1..1000).
- **The wooden pickaxe's coin path looks unreachable** (found before `9733a05`,
  not re-checked since; that commit says the owner kept the coin path on
  purpose). `_upgradeCoinTool` and the graduation step run only for a
  `p.oreTools` row with `typeId wood_pick`, and nothing on this branch creates
  one. The starter is coin rung 1 instead.
- ~~**The family skin skips forged tools.**~~ **FIXED 2026-10-08 (`b0c2430`).**
  The gate tested `tier > 0` to exclude found objects, but `equippedTool`
  returns `0` on THREE paths — the two found-tool paths *and* the forged one,
  deliberately, because a forged tool's rung is its ore's tier. So skins did
  nothing on every tool past hour one while the Forge reported them as fitted.
  Now tested positively on `oreTier`, which only a forged row carries.
- **"tier" means three things.** On a forged row it is the ore index. On a coin
  row it is the rung. On the Tool instance, the attribute `Tier` is
  `lookTier`, which is cosmetic.
- **"grade" is not a tool grade.** `MineToolGrades` is the F→SSS Clash-Royale
  climb (`UPGRADE_P 1/3`, `MISS_LIMIT 3`); its one live server caller is
  opening a lucky block (gear now rolls letters from the temper weights, per its
  header). Forged tools have no grade.
- **Raising the cap above 100 fails silently.** MineServer and OreBalanceSim
  read `math.min(100, TOOL_MAX_LEVEL)`.
- **The coin ladder's generator is missing.** The `MineTools` header says
  "GENERATED BY skills-src/gentools.js", but that folder is not in the repo.

## Open questions

- The coin shop no longer sells tools (`9733a05`). What are coins for now? OPEN #7
  is still open, and the wood-pick graduation design depends on the answer.
- Should the `MineBreaking` scale (1..1000) or the raw-tier scale be the one a
  player sees? See [mining-and-breaking](mining-and-breaking.md).

## See also

[ores](ores.md) · [forge-and-recycling](forge-and-recycling.md) ·
[traits](traits.md) ·
[chests-and-lucky-blocks](chests-and-lucky-blocks.md)
