---
title: Open questions, contradictions and probable bugs
type: meta
status: current
verified: 2026-10-08 @ bae3c5b
sources:
  - docs/OPEN.md
  - docs/BLOCKED.md
  - docs/PROPOSAL.md §0
  - docs/TODO.md §0
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineBreaking.luau
related: [owner, sources-of-truth, overview, mining-and-breaking, save-data-and-migrations]
---

# Open questions, contradictions and probable bugs

> Everything here is **unresolved**. It is the first place to look before
> asking the owner something, and the first place to add a question you
> cannot answer. Each entry names where the detail lives.
>
> **Bugs 1, 2, 3, 5 and 15 were fixed upstream within a day** (`b19c4c2` and
> `4cc82a5` / `5d59714`, all merged to `main` in PR #6, which credit the wiki
> research pass). They stay in the table, marked fixed, as a record of how the
> loop works: the wiki finds, the owner's session fixes, the wiki re-ingests.
> Still open: 4 (Event Horizon), 6–13 and 16, plus the 2026-10-08 findings 21–24 in §1b.
>
> **Confidence labels.** *Read* means I (Claude, in the wiki-building session)
> checked the cited code myself. *Reported* means a research pass found it and I
> did not independently check it. **Nothing here has been run in Roblox.**

## 1. Probable bugs found while building the wiki

These are not fixed. They are in code that has never run in the engine.
Nobody has asked for fixes; ask the owner before changing any of them.

| # | what | confidence | where |
|---|---|---|---|
| 1 | **FIXED in `b19c4c2`: every forged tool had breaking power 1.** The row `equippedTool` built for a forged tool had no `oreId`, `oreTier`, `tier` or `breakingPower`, so `MineBreaking.toolBreakingPower` fell through to `SHOP_POWER[1]`. The fix commit measured it in a live session: before, every tool from Stone to Oganesson stopped at zone 1, layer 50. The row now carries `oreTier` and `oreId`, derived per swing so no migration is needed. `tools/verify/heldtool.js` pins it. This was the wiki's first catch. | *Read* in code; the commit message reports the live before/after | [mining-and-breaking](systems/mining-and-breaking.md); `MineServer.equippedTool` |
| 2 | **FIXED in `b19c4c2`: the ore-roster migrations re-ran on every load.** The v1 and v2 guards used `~=`, so a save stamped 2 re-entered v1, stamped itself back to 1, and then re-entered v2. Both guards now test `< version` (monotonic). **Not stated in the commit: whether saves already damaged by earlier re-runs were repaired.** The live log showed 0 changes, so any damage would only show on a save that held old-roster tools. | *Read* (guards); damage to saves unverified | [save-data-and-migrations](code/save-data-and-migrations.md); `MineServer` `load()` |
| 3 | **FIXED in `4cc82a5`: recycling paid for levels the tool never bought.** A new forge inherits your best level, and `toolRecycle` refunded half of `toolSpent(level)`, so forge, scrap and repeat printed ore and dust. The row now stamps the level it was forged at (`base`), and the refund is the difference. The fix's author measured it at tier 40: forged at 30 and scrapped at 30 refunds 0 (was 145,022 ore). Tools saved before the `base` stamp existed fall back to base 1 and refund on the old terms, which the commit calls generous to the few tools already out there. `tools/verify/economy-exploits.js` pins it. | *Read* (`MineConfig.toolRecycle`); the live before/after is in the commit message | [forge-and-recycling](systems/forge-and-recycling.md) |
| 4 | **Event Horizon cannot be mined**: it counts as zone 11 (strength 1000) and event tools get breaking power 1. **Reframed by the owner's session (TODO §6.1 P0, 2026-10-07):** this is *not* a breaking-power bug to patch. `MineBreaking` says zone 11 is off the normal ladder on purpose and its own progression was never built; the owner wants Event Horizon tools "EXTREMELY strong", to be built from the new `EVENT.SVG` art (38 ore + pickaxe pairs) on a strength scale above `MineBreaking.MAX`. | *Reported* | [world-events](systems/world-events.md) |
| 5 | **FIXED in `4cc82a5`: depth desks paid hundreds of times too much.** `depthSellMult` special-cased two seams (×487.5 at 500, ×12,187.5 at 1500), and every other seam paid ×0.78, below the surface. It is now one smooth curve, `1.05 ^ (seam / 500)` (`MineDepth.DEPTH_SELL_PER_SEAM`), so every desk beats the surface and deeper pays more (owner, 2026-10-05: *"make seams sell for more not less"*). `DEPTH_SELL_FRAC` was deleted. Measured by the author on a 10,000 haul: surface 10,000, seam 500 10,500, seam 2000 12,155, seam 10000 26,532. `economy-exploits.js` pins it. | *Read* (`MineDepth.depthSellMult`); the live numbers are in the commit message | [zones-layers-and-seams](systems/zones-layers-and-seams.md) |
| 6 | **The chest coin crash fix landed in dead code.** The `e77d84e` fix is in `rollChestLoot`, reached only by `giveDrop`, which nothing calls. Live chests use `MineZoneChests.rollCurrency`. | *Reported* | [chests-and-lucky-blocks](systems/chests-and-lucky-blocks.md) |
| 7 | **Chest flagship tools never drop** (static read): `openChestBlock` reads `rollChestTool` about 2,600 lines above its declaration, so it is a global read and nil. | *Reported* | same page; see the global-read trap in [luau-traps](code/luau-traps.md) |
| 8 | **Tutorial step 29 hands a new player SSS hats**, worth +1050% in layer 2. | *Reported* | [hats-and-faces](systems/hats-and-faces.md) |
| 9 | **`MineStats.RUNE_ONLY` silently zeroes the `blastRadius` line on all 26 pets that have one.** | *Reported* | [pets](systems/pets.md) |
| 10 | **The charm MERGE button wants 2 copies** (`math.max(2, MERGE_COST)`); the server needs 1 and the gem price is never shown. | *Reported* | [charms](systems/charms.md) |
| 11 | **24 ore charms carry `luck`**, which raises the ore-case chance that drops them. This breaks the "no reward boosts its own acquisition" rule. **24 carry the retired `backpack` stat.** | *Reported* | [charms](systems/charms.md) |
| 12 | **Meadow zone packs can never pay Mythic, Divine or Exotic** (computed from `cardOdds`). | *Reported* | [cards-and-packs](systems/cards-and-packs.md) |
| 13 | **Bag prices show in coins; the server charges gems.** | *Reported* | [ore-pouch-and-backpack](systems/ore-pouch-and-backpack.md) |
| 14 | **`tools/export/sync.ps1` deletes `tools/export/in/`** (`Remove-Item $in -Recurse -Force`). **Not a bug in the script**: that folder is a gitignored scratch directory the Studio export flow fills and consumes, and deleting it is the documented last step (the `b19c4c2` author checked and dismissed it). The only hazard was `CLAUDE.md` naming that folder as a place for Claude.ai exports. `CLAUDE.md` and the wiki now point exports at the gitignored `transcripts/` folder. | *Read* | [rojo-and-studio](code/rojo-and-studio.md); `tools/export/sync.ps1` |
| 15 | **FIXED in `5d59714`: nothing checked Luau's 200-top-level-local ceiling.** `MineServer` had **zero** registers left; `luau-analyze` accepts what `luau-compile` rejects. New `tools/verify/compile.js` compiles every file with `luau-compile` and measures headroom (it fails below 4). Seven services became fields of one `Svc` table, buying `MineServer` 5 registers (MineClient has 7). I ran it on 2026-10-08: **all 212 files compile; 5 and 7 left.** It has since caught the same break twice more (per the owner's session), once from a `do` block for the dev-scaffolding strip, fixed by making it an IIFE: `do` shares the main chunk's register budget, an IIFE gets its own. A new top-level local in either file will soon fail the suite again, which is the point. | *Read* (I ran the check) | [luau-traps](code/luau-traps.md) |
| 16 | **`tools/start-local-agent.ps1` prints a `cd "<that path>"` hint**, which breaks the owner's no-placeholder rule, and still says "read HANDOFF". | *Reported* | [local-setup](code/local-setup.md) |

## 1b. Found 2026-10-06 to 08, not yet decided

These were found while doing other work and are **recorded rather than fixed**,
because each moves the economy in more than one place. Measured figures are in
`docs/ore-yield-and-vein-balance.md`.

| # | what | confidence | where |
|---|---|---|---|
| 17 | **Nothing multiplies ore quantity, and the owner expects enchants to.** `MineServer` rolls ore as `math.random(lo, hi)` straight off `oreYieldFor` — no boost, enchant, luck or finder is applied, and the comment there says the finder is deliberately a *quality* stat. Owner, 2026-10-06: *"REMEMBER ESPICALLY ENDGAME ENCHANTS BUFF THAT SO KEEP IT HIGH"*. So the measured **12 million blocks for an Exotic tool is the real figure, not a pre-multiplier one**. Three options written up in the doc §4: a quantity multiplier, raising the top-rarity bands, or lifting `ORE_CHANCE` for deep zones. Each ripples: `toolCraftCost` and gem value both derive from the drop band. | *Read* in code, measured | [ores](systems/ores.md), `docs/ore-yield-and-vein-balance.md` §4 |
| 18 | **The legacy ore-pack path and the live drop path disagree about the ore finder.** Pack conversion does `each = mid * (1 + oreFind)` — a straight quantity multiplier — while the live drop deliberately does not. One of the two is wrong about the design rule. | *Read* in code | [ores](systems/ores.md), [boosts-and-stats](systems/boosts-and-stats.md) |
| 19 | **`MineDigAuth.canDigLayer` ends in an unconditional `return true`**, so every entitlement check above it is unreachable. This is deliberate for mining and was silently load-bearing for crediting; `canCreditDepth` now carries the strict half (see [zones-layers-and-seams](systems/zones-layers-and-seams.md)). **The dead checks in `canDigLayer` are still dead** — worth deciding whether they should be deleted or re-enabled, because right now they read as protection that does not exist. | *Read* in code | `MineDigAuth.canDigLayer` |
| 20 | **A 6,500-block first tool.** With stone's surface share raised to hit the owner's 1-vein-per-3,000 target, the cheapest craftable tool costs ~6,500 blocks broken (was 13,500). Not obviously wrong, but it is the first number a new player meets and nobody has signed off on it. | measured | `docs/ore-yield-and-vein-balance.md` §2 |
| 21 | **No client ever sends `buyCharm`.** `Verbs.buyCharm` is dispatched and carefully guarded (price from `charmTokenPrice`, `source == "charm"` gate, balance re-read per iteration), but a search of `src/` finds no caller (the only dynamic `FireServer` picks `equip` or `unequip`): the "bought with tokens" half of the 36 graded charms has no shop panel in the repo. **A Studio-only script in the place file would not show up in `src/`**, so confirm in Studio before calling it dead. | *Read* (searched `src/`) | [charms](systems/charms.md) |
| 22 | **Nothing calls `launchSeason`.** The server dispatches it (admin-gated) but no admin panel button or client script sends it, so the repo has no way to press launch. Until something does, the season stays pinned at its start. Same caveat: a place-only script or a command-bar line would not show up in `src/`. | *Read* (searched `src/`, `tools/`, `docs/`) | [season-and-launch](systems/season-and-launch.md) |
| 23 | **The battle pass ends a week before the offers.** `MineRotatingOffers.SEASON_END` is 2026-11-01 plus `EXTEND_SEC` (one week) = 2026-11-08; `MineScrolls.PASS_SEASON_END` is still 2026-11-01. `launch.js` pins the three season *start* constants but not the ends. Intended? | *Read* | [season-and-launch](systems/season-and-launch.md) |
| 24 | **Chest Luck feeds the chest charm drop.** `CHARM_CHEST_CHANCE × b.chestLuck`, and five graded charms carry `chestLuck` (one at +575%). The code comment on `luck` says a chest charm is not rolled off luck. Breaks the self-feeding rule from `roadmap/PRINCIPLES.md` §1? | *Read* | [charms](systems/charms.md) |

## 2. Where the owner's rules and the code disagree

| rule | what the code does | where |
|---|---|---|
| **TODO §0.13.5: charms drop "from ores, not chests"** (2026-10-07) | The owner's own newer words say the 36 graded charms "can be found in chests (0.5%)", and the chest drop is built. §0.13.5 has not been edited. | [charms](systems/charms.md) |
| **TODO §0.13.5: "one charm per ore"** | Two per ore (164 generated). That was an agent design (TODO §6.1), never confirmed. | [charms](systems/charms.md) |
| **TODO §0.13.6: "ore case rolls … to decide whether you get a tool"** | A case never pays a tool; it pays a skin (75%) or a charm (25%). | [skins-cases-and-temper](systems/skins-cases-and-temper.md) |
| **TODO §9: "skin and temper crates cost ore only"** | Temper cases cost **temper tokens**, and so now do the wandering traders' cases and the graded charms. | same page, [wandering-traders](systems/wandering-traders.md) |
| **TODO §0.13.11: "the swing gate reads `BreakPower`"** | The gate reads the tool row (`oreTier` / `oreId`, derived per swing since `b19c4c2`). Per the research pass the `BreakPower` *attribute* is not read by the gate (not rechecked). | [mining-and-breaking](systems/mining-and-breaking.md) |
| **Standing rule "no pity systems"** | PROPOSAL §0 lines 26 and 28 (**approved**) add pack pity and an Exotic floor. Neither is built. | [cards-and-packs](systems/cards-and-packs.md) |
| **PROPOSAL line 27: "trait pity: NONE"** | OPEN §12 still lists trait pity. | [traits](systems/traits.md) |
| **PROPOSAL line 37: "keep the `oreYield` key"** | It was renamed to `blastChance` in `eb973f6`, the day before. | [boosts-and-stats](systems/boosts-and-stats.md) |
| **TODO §0.7 / §0.17: runes are a gem sink and are replaced by traits** | Runes, scrolls and sockets are still live ("stage 3", the retirement, is deferred). | [traits](systems/traits.md) |
| **TODO §0.21: capacity comes only from the bag ladder and pouch** | `cap(p)` still multiplies by the `backpack` boost. | [ore-pouch-and-backpack](systems/ore-pouch-and-backpack.md) |
| **PROPOSAL §0 line 13 / §F0** (`ZONE_STEP 1`, `ORE_POW 2.0`, `MAX 209`) | Code has 100 / 1.0 / 1000. | [mining-and-breaking](systems/mining-and-breaking.md) |

**Approved in PROPOSAL §0 but not built** (reported): lines 1–8 (hat, face and pet
ladders, kits), 9, 10, 12, 15, 16, 17 (craft constants, recycle curve,
`ORE_GEM_SPREAD` 1e4 vs the code's 1e6, vault prices), 23 (potion coin prices),
29 (gear sets), 30, 33 and 35.

## 3. Questions for the owner

Check `docs/BLOCKED.md` and TODO §0 first. These are not answered anywhere.
Ask them with options and a recommended default (see `CLAUDE.md`).

**Design**
- **Coins: what are they for?** Seams are free, the Forge runs on ore, tools are
  no longer sold for coins (`9733a05`), and the proposed shape (potions,
  consumables, outpost shops) is unsigned.
- **Are skins cosmetic or a power source?** Docs disagree; today they are
  tempers (stat kits).
- **One charm per ore, or two?** Is the ~24 hand-authored charm rewrite (AUDIT)
  approved? Should charms sit in a boost layer?
- **Charms from chests:** TODO §0.13.5 says "from ores, not chests" but the owner's
  2026-10-07 words (and the built drop) say chests, 0.5%. Rewrite §0.13.5? And may
  Chest Luck raise that 0.5%?
- **How do you press launch?** `Verbs.launchSeason` exists but nothing calls it. Admin
  panel button, a chat command, or a Studio command-bar line?
- **Where do players buy graded charms with tokens?** `Verbs.buyCharm` has no panel.
  A tab in the Enchanter, in Inventory → Shop, or at the traders?
- **Should the battle pass end with the offers (11-08) or a week earlier (11-01)?**
- **Pack pity and the Exotic floor:** build them, or keep "no pity"?
- **Runes at stage 3:** migrate into traits, or refund?
- **What will "enchants" be?** The word is reserved. Should the pet perks in
  `MineCards.TRAITS` be renamed to avoid the clash?
- **Should family tempers apply to forged tools?** Today they do not.
- **Is a Meadow pack with no Mythic+ intended?**

**Ship or cut** (AUDIT §5 asked for a yes that was never recorded)
- Trading, lucky blocks, leaderboards, group wheel, event pass, battle pass,
  and the social UI (`SocialView`, `ProfileView` are mounted nowhere).
- **Coins: what are they for now?** The coin shop stopped selling tools in `9733a05` (owner, 2026-10-05), which leaves backpacks as the main coin sink. Is the wooden-pick coin path reachable? It looked unreachable before that commit, and the commit says it is kept on purpose.
- Is `NewGear` meant to replace the current hat catalog? Should faces drop
  from chests?
- Product ids in `MineConfig.PRODUCTS` are all 0: set them, or cut the unsold rows.
- VIP lost a perk. What replaces it? Founders seats: per server or global?
- What happens to Event Horizon after it closes (2026-11-08 04:00 UTC)? Are the
  "Space" ores the planned Event Horizon ores?

**Numbers**
- Dirt Meadow floor: 5000, or uncapped?
- Earthquake: capped at 10× a swing, or ~1.2× (the code)?
- Should gem-bought bags and item slots survive rebirth?
- Should several rebirths be allowed at once? Should rebirth affect coin value?
- What goes in the station bay behind each outpost?

**Reach (only the owner can do these)**
- Play the branch in Studio. Nothing from the last week has run.
- Icons: the 164 ore icons and case images (`MineOreIcons`), the 246 per-ore tool skins (`MineIcons.ORE_SKINS`) and the new rendered ore icons are all uploaded and wired. The author counted 246 distinct images live, and ownership was not the problem for the pickaxe batch (it was moderation latency; `97c42ac`). Which account owns each batch is still unverified; they should be group-owned.
- Export or delete `OreShapes`. Sync `ToolBakers.OreToolBaker` back.

## 4. Stale docs and comments

Fix these as you touch them (TODO §9: "kill stale comments on sight").

- **`trap.js` no longer fails.** START-HERE §1 and §5, HANDOFF §2.4, OPEN and
  `suite.sh` (`KNOWN_FAIL="trap"`) all call it a known failure. On 2026-10-05 the
  suite ran **34 passed, 0 failed, 0 did not run**, with `trap` among the passes.
  *Read.* OPEN also says `zones.js` is red; it passes.
- Counts have drifted. START-HERE says "101 commits ahead" and "23 checks" and
  "11 need luau"; git says 86 commits ahead of `main` at the time, and the suite
  has 45 checks (2026-10-08, counting `wiki` and `askfirst`), 22 of which execute the luau binary. MineServer is about 17,700
  lines and MineClient about 12,490 (docs say 16.7k / 14.8k and 11.9k); there
  are 215 source files that compile (docs say 199 or 210). *Reported.*
- START-HERE §5 says only one change was ever confirmed in-engine; about 50 later
  commit messages say they were verified in Studio (for example `44a1d5f`). Treat
  "has it run in Roblox?" as **unknown per feature**, and ask the owner.
- HANDOFF §1 says `AGENT_PROMPT` and `PROMPTS` are outside the repo; they are in
  `roadmap/`. TODO §4 lists a duplicate pet module that was deleted in `f6bb23f`.
- The HP formula in `docs/depth-sheet.md`, `roadmap/NUMBERS.md` and
  `docs/live-config.md` is the old ×6 ×2 one; the code is linear ×5, and
  `tools/gen-depth-sheet.js` would write the stale formula back.
- `tools/verify/seams.js` checks a coin price ladder, but `MineDepth.seamPrice`
  returns 0 (seams are free).
- `build/ore-sheet/ASSETS.md` gives group id 7706885185; `MineConfig.GROUP_ID` is
  35326298. Ore icon art was uploaded (164 assets in `f5b6c34`, 246 tool skins and
  82 rendered ore icons since) although TODO §6.3 and BLOCKED #11 say it is not
  applied. Who owns the uploads is unverified.
- `TOOL_MAX_LEVEL` is 30; OPEN and `tools/gen/upgrade-calculator.js` still say 100.
- `tools/gen-ores.js` reads the stale `docs/ore-remake.md` and only refuses
  `--write` today because 13 live ore ids have no mapping.
- `MineBuild.STAMP` is still set to 2026-10-04. `docs/rojo-connect.md` says Rojo
  was "never attached" (stale). START-HERE §7 points at BALANCE-PROPOSAL and
  leaves out PROPOSAL.

- `docs/START-HERE.md` §2 calls layer 500 the ship blocker; its own §5 and
  OPEN P0 §1 say the seam chain is wired. Line numbers in OPEN P0 §1 and HANDOFF
  are stale (`Verbs.buySeam` is near line 9540).
- `AGENTS.md` and START-HERE say Workspace exists only in the place file, but
  `WorldBuilder.build()` rebuilds `MineWorld` at boot.
- `docs/ore-remake.md` banner, `docs/decisions.md`, `docs/depth-sheet.md`,
  `roadmap/CHARMS.md`: superseded. `docs/SKILL-TREE.md` has a pre-remap roster.
- OPEN P2 says the battle pass is parked in `MineParked` (it is live) and the
  Event Horizon duplicate is still to delete (done in `f6bb23f`).
- `PRINCIPLES §8` still says "pet slots 3→8". The code has 3.
- The roadmap docs claim `gen-ores.js` has a `--force-stale` guard; that commit
  (`9932508`) is only on `origin/ore-tools-power`.
- Stale code comments: `MineCharms`, `MineGear`, `MineHats`, `MineTraits`,
  `MineRunes`, `MineOrePouch`, `MineBags`, `MineStats` (zap, earthquake,
  gemFind), `MineDigAuth` ("snap-back"), `MineBreaking`, `MineDepth`, the World
  Pulse comment in `MineServer`, `MinePackConfig.PACK_PRICE`, `LIMITED_DAYS`.
- Founders price: comments say 1000 credits / R$999; constants say 799.
  `PlaceConfig.MAIN_PLACE_ID` is not the placeId in START-HERE.
- Dead code the research passes found: `NEW_CARD_BIAS` (never read), the X/Y
  named pet roster (not wired into minting), `rollChestLoot` and `giveDrop`.

## See also

- [owner](owner.md)
- [sources-of-truth](sources-of-truth.md)
- [ambiguous-terms](ambiguous-terms.md)
- `docs/OPEN.md`, `docs/BLOCKED.md`
