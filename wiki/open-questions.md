---
title: Open questions, contradictions and probable bugs
type: meta
status: current
verified: 2026-10-10 @ 6c08171
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
> **Bugs 1 and 2 were fixed upstream the same day** (`b19c4c2` on PR #6, which
> credits the wiki research pass). They stay in the table, struck as fixed, as a
> record of how the loop works: the wiki finds, the owner's session fixes, the
> wiki re-ingests.
>
> **Confidence labels.** *Read* means I (Claude, in the wiki-building session)
> checked the cited code myself. *Reported* means a research pass found it and I
> did not independently check it. **Nothing here has been run in Roblox.**

## Help needed: pets and pack sets (2026-10-10)

The owner asked for this note. The pet job is specified in
`docs/PETS-AND-SETS.md`. Claude needs the owner for the items below. Each one
has a default that is used if the owner says "you decide".

| # | what I need | my default |
|---|---|---|
| H1 | **How many pets get a hand-made name and look?** The 19 sets hold 2,043 cards, and a card is a pet. | Name and design every Epic or better by hand (450). Commons to Rares get set-themed generated names on shared bodies, the way packs mint today. |
| H2 | **How much better is each zone's pot?** "Better, but not exponentially." | +12% per zone, so zone 11 is about 3.1× zone 1. Mythic, Divine and Exotic get a different buff set per zone. |
| H3 | **"Heartwood" is used twice** (Mosswood ★★★★★, Worldtree ★★). Pack ids must be unique. | Rename Worldtree ★★ to "Sapwood". |
| H4 | **A names sheet.** I will send every new and renamed pet per zone and set for one yes/edit pass before anything is built. Names are save data, so changing them later costs aliases. | Approve in one pass, by pasting it back with edits. |
| H5 | **Is the old card content legacy?** That is the 41 `MineCards.SETS`, the 55 `MineZonePacks` and the 19 `Mine1PacksData` card packs. X/Y and the variant odds at pack open are already confirmed old. | Retire them from dropping. Owned cards keep working. |
| H6 | **Art uploads.** The pack and set images, and the wheel's one-image face. An agent can make the images but cannot upload to the group (35326298). | The owner uploads to the group and pastes the asset ids back. |
| H7 | **The 6-hour wheel spin** (rewards pass): do unused spins bank, and how many? | Bank up to 4 (one day's worth). |
| H8 | **One pet session at a time.** Another session rebuilt pet bodies in `PetModelFactory` (`c62fad6`, `1af78a4`). Two sessions editing that 3,500-line file collide. | Only the session the owner continues with touches it. |

## 0. LAUNCH BOARD — owner wants to ship in 4–5 days (asked 2026-10-10)

Everything below is either **blocking**, **a decision only the owner can make**,
or **cut**. Anything already fixed is out of this list entirely; see `wiki/log.md`.

### 0a. Blocking, and nobody else can do them

| # | item | why it blocks |
|---|---|---|
| 1 | **Throw the launch switch.** `/admin launch now` exists (`cc0262f`). | Until it is thrown, `seasonNow()` is pinned to `SEASON_START`: offers frozen on slot one, battle pass never counting, Event Horizon's window never opening. |
| 2 | **Merge PR #7.** `gh` is unauthenticated here. | Carried since 2026-10-07. |
| 3 | **Upload the ore and charm icons.** §7 governs; no agent can upload to a group place. | `docs/TODO.md` 796–803. |
| 4 | **Play it.** Almost nothing in this repo has run in the engine with a real player. | Every measurement is static or Studio-side. |

### 0b. Decisions only the owner can make

| # | decision | the shape of it |
|---|---|---|
| 5 | **Ship social, or cut it?** `MineSocialView` is 387 lines, complete, **mounted nowhere**, with `MineProfileView` parked beside it. Text IS filtered (`TextService:FilterStringAsync`, fails closed). | One line mounts friends, DMs, global chat and groups together. That is a moderation surface, not a bug fix. |
| 6 | ~~**Group Wheel: ship or strip?**~~ **Answered 2026-10-10: ship it, as the daily wheel** (`299dd2c`). Still open: approve its PROPOSED allowances and slice weights, and create the three Robux product ids. | See [social-quests-and-leaderboards](systems/social-quests-and-leaderboards.md). |
| 7 | **Event Horizon's roster.** It builds **138 tools for a 2-section zone** because it walks all of `Depth.SECTIONS`. Prices are capped now (`4f45483`) so nothing overflows 2^53, but **68 of 138 sit at the cap**. | Changing the count moves every event tool's breaking power through `MineBreaking.eventStrength`. |
| 8 | **A depth-scaled coin sink.** Potions fixed the early game only. | Owner picked the direction: progression-flavoured, repeatable, in the loop. |
| 9 | **Ore mastery as the endgame.** Owner chose it over ladders/endless/guilds. | Not started. Advised *after* launch — the 2-hour systems only just became visible. |

### 0c. Known-and-accepted for launch

- **Flat gem floor prices** (trait roll 500, crate 200, backpack rung 1 at 100,
  re-socket 10) did not move with `1e6 → 1e4` and are pocket change. Harmless;
  they make early play generous.
- **Chests may out-faucet ore sales** — chest gems scale on their own ladder and
  are not pouch-capped. Watch it in live data rather than pre-tuning it.
- **26 of 39 tutorial steps remain unreachable.** The three that mattered are in
  (`cc0262f`); the rest grant items, and switching them on would pay out to every
  existing player on next login.
- **`buyCrate`/social orphans** — tracked by `tools/verify/orphan-verbs.js`, which
  fails the suite on any NEW orphan.

### 0d. Suggestions worth 30 minutes each, before launch

1. **A first-session smoke test with a blank profile.** Nothing in this repo has
   been played from zero. The intro path reads sound on paper and that is all.
2. **Turn on one leaderboard.** `LeaderboardService` is 1,747 lines and wired;
   a visible board is the cheapest "other people exist" signal a new game has.
3. **Check the Forge recipe page on a phone.** It is five cells per row at a
   scale fraction, untested at narrow widths.
4. **Decide the Discord/code reward values.** `LAUNCH` grants 500 gems and the
   Discord link 5,000 — both flat, both now worth very little after `1e4`.

## 1. Probable bugs found while building the wiki

These are not fixed. They are in code that has never run in the engine.
Nobody has asked for fixes; ask the owner before changing any of them.

| # | what | confidence | where |
|---|---|---|---|
| 1 | **FIXED in `b19c4c2`: every forged tool had breaking power 1.** The row `equippedTool` built for a forged tool had no `oreId`, `oreTier`, `tier` or `breakingPower`, so `MineBreaking.toolBreakingPower` fell through to `SHOP_POWER[1]`. The fix commit measured it in a live session: before, every tool from Stone to Oganesson stopped at zone 1, layer 50. The row now carries `oreTier` and `oreId`, derived per swing so no migration is needed. `tools/verify/heldtool.js` pins it. This was the wiki's first catch. | *Read* in code; the commit message reports the live before/after | [mining-and-breaking](systems/mining-and-breaking.md); `MineServer.equippedTool` |
| 2 | **FIXED in `b19c4c2`: the ore-roster migrations re-ran on every load.** The v1 and v2 guards used `~=`, so a save stamped 2 re-entered v1, stamped itself back to 1, and then re-entered v2. Both guards now test `< version` (monotonic). **Not stated in the commit: whether saves already damaged by earlier re-runs were repaired.** The live log showed 0 changes, so any damage would only show on a save that held old-roster tools. | *Read* (guards); damage to saves unverified | [save-data-and-migrations](code/save-data-and-migrations.md); `MineServer` `load()` |
| 3 | **FIXED 2026-10-06: recycling paid for levels the tool never bought.** `MineConfig.toolRecycle` now takes a `baseLevel` and refunds a **differential** — `max(0, toolSpent(level) - toolSpent(baseLevel))` — so an inherited level refunds nothing. Measured in `tools/verify/economy-exploits.js`: a freshly forged tool went from 145,022 ore of profit to 0. | *Read* in code, pinned by harness | [forge-and-recycling](systems/forge-and-recycling.md) |
| 4 | **Event Horizon cannot be mined**: it counts as zone 11 (strength 1000) and event tools get breaking power 1. | *Reported* | [world-events](systems/world-events.md) |
| 5 | **FIXED 2026-10-06: depth desks paid hundreds of times too much.** `DEPTH_SELL_FRAC` (the 0.78 haircut) is deleted and `depthSellMult` is now `DEPTH_SELL_PER_SEAM 1.05 ^ (depth/500)` — a smooth curve instead of ×487.5 at seam 500 and ×12,187.5 at seam 1500. Owner asked for seams to sell for **more**, not less, so the ramp rises gently rather than being clamped down. | *Read* in code | [zones-layers-and-seams](systems/zones-layers-and-seams.md) |
| 6 | **The chest coin crash fix landed in dead code.** The `e77d84e` fix is in `rollChestLoot`, reached only by `giveDrop`, which nothing calls. Live chests use `MineZoneChests.rollCurrency`. | *Reported* | [chests-and-lucky-blocks](systems/chests-and-lucky-blocks.md) |
| 7 | **Chest flagship tools never drop** (static read): `openChestBlock` reads `rollChestTool` about 2,600 lines above its declaration, so it is a global read and nil. | *Reported* | same page; see the global-read trap in [luau-traps](code/luau-traps.md) |
| 8 | **Tutorial step 29 hands a new player SSS hats**, worth +1050% in layer 2. | *Reported* | [hats-and-faces](systems/hats-and-faces.md) |
| 9 | **`MineStats.RUNE_ONLY` silently zeroes the `blastRadius` line on all 26 pets that have one.** | *Reported* | [pets](systems/pets.md) |
| 10 | **The charm MERGE button wants 2 copies** (`math.max(2, MERGE_COST)`); the server needs 1 and the gem price is never shown. | *Reported* | [charms](systems/charms.md) |
| 11 | **24 ore charms carry `luck`**, which raises the ore-case chance that drops them. This breaks the "no reward boosts its own acquisition" rule. **24 carry the retired `backpack` stat.** | *Reported* | [charms](systems/charms.md) |
| 12 | **Meadow zone packs can never pay Mythic, Divine or Exotic** (computed from `cardOdds`). | *Reported* | [cards-and-packs](systems/cards-and-packs.md) |
| 13 | **Bag prices show in coins; the server charges gems.** | *Reported* | [ore-pouch-and-backpack](systems/ore-pouch-and-backpack.md) |
| 14 | **`tools/export/sync.ps1` deletes `tools/export/in/`** (`Remove-Item $in -Recurse -Force`). **Not a bug in the script**: that folder is a gitignored scratch directory the Studio export flow fills and consumes, and deleting it is the documented last step (the `b19c4c2` author checked and dismissed it). The only hazard was `CLAUDE.md` naming that folder as a place for Claude.ai exports. `CLAUDE.md` and the wiki now point exports at the gitignored `transcripts/` folder. | *Read* | [rojo-and-studio](code/rojo-and-studio.md); `tools/export/sync.ps1` |
| 15 | **FIXED 2026-10-06: nothing checked Luau's 200-top-level-local ceiling.** `tools/verify/compile.js` now runs `luau-compile` over all 212 files and asserts at least 4 locals of headroom in both big scripts. It found `MineServer` sitting at **0 headroom** on arrival; collapsing seven service locals into one `Svc` table bought 5 back. It has since caught the same break twice more — a `do` block for the dev-scaffolding strip (fixed by making it an IIFE, since `do` shares the main chunk's budget while an IIFE gets its own). | *Read*, pinned by harness | [luau-traps](code/luau-traps.md) |
| 16 | **`tools/start-local-agent.ps1` prints a `cd "<that path>"` hint**, which breaks the owner's no-placeholder rule, and still says "read HANDOFF". | *Reported* | [local-setup](code/local-setup.md) |

## 1b. Found 2026-10-06/07, measured, not yet decided

These were found while doing other work and are **recorded rather than fixed**,
because each moves the economy in more than one place. Measured figures are in
`docs/ore-yield-and-vein-balance.md`.

| # | what | confidence | where |
|---|---|---|---|
| 17 | **Nothing multiplies ore quantity, and the owner expects enchants to.** `MineServer` rolls ore as `math.random(lo, hi)` straight off `oreYieldFor` — no boost, enchant, luck or finder is applied, and the comment there says the finder is deliberately a *quality* stat. Owner, 2026-10-06: *"REMEMBER ESPICALLY ENDGAME ENCHANTS BUFF THAT SO KEEP IT HIGH"*. So the measured **12 million blocks for an Exotic tool is the real figure, not a pre-multiplier one**. Three options written up in the doc §4: a quantity multiplier, raising the top-rarity bands, or lifting `ORE_CHANCE` for deep zones. Each ripples: `toolCraftCost` and gem value both derive from the drop band. | *Read* in code, measured | [ores](systems/ores.md), `docs/ore-yield-and-vein-balance.md` §4 |
| 18 | **The legacy ore-pack path and the live drop path disagree about the ore finder.** Pack conversion does `each = mid * (1 + oreFind)` — a straight quantity multiplier — while the live drop deliberately does not. One of the two is wrong about the design rule. | *Read* in code | [ores](systems/ores.md), [boosts-and-stats](systems/boosts-and-stats.md) |
| 19 | **`MineDigAuth.canDigLayer` ends in an unconditional `return true`**, so every entitlement check above it is unreachable. This is deliberate for mining and was silently load-bearing for crediting; `canCreditDepth` now carries the strict half (see [zones-layers-and-seams](systems/zones-layers-and-seams.md)). **The dead checks in `canDigLayer` are still dead** — worth deciding whether they should be deleted or re-enabled, because right now they read as protection that does not exist. | *Read* in code | `MineDigAuth.canDigLayer` |
| 20 | **A 6,500-block first tool.** With stone's surface share raised to hit the owner's 1-vein-per-3,000 target, the cheapest craftable tool costs ~6,500 blocks broken (was 13,500). Not obviously wrong, but it is the first number a new player meets and nobody has signed off on it. | measured | `docs/ore-yield-and-vein-balance.md` §2 |

## 2. Where the owner's rules and the code disagree

| rule | what the code does | where |
|---|---|---|
| **TODO §0.13.5: "one charm per ore"** | Two per ore (164 generated). That was an agent design (TODO §6.1), never confirmed. | [charms](systems/charms.md) |
| **TODO §0.13.6: "ore case rolls … to decide whether you get a tool"** | A case never pays a tool; it pays a skin (75%) or a charm (25%). | [skins-cases-and-temper](systems/skins-cases-and-temper.md) |
| **TODO §9: "skin and temper crates cost ore only"** | Temper cases cost **temper tokens**. | same page |
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
- Is the depth-desk multiplier (bug 5) intended?
- Dirt Meadow floor: 5000, or uncapped?
- Earthquake: capped at 10× a swing, or ~1.2× (the code)?
- Should gem-bought bags and item slots survive rebirth?
- Should several rebirths be allowed at once? Should rebirth affect coin value?
- What goes in the station bay behind each outpost?
- How should the recycle refund be fixed (bug 3)?

**Reach (only the owner can do these)**
- Play the branch in Studio. Nothing from the last week has run.
- Charm and ore icons: 164 ore icons (`MineOreIcons`) and the new 88 pickaxe skins (`MineIcons.ORE_PICK`, `9733a05`) are uploaded, but which account owns them is unverified (they must be group-owned). The pickaxe-to-ore matching is by colour and not final.
- Export or delete `OreShapes`. Sync `ToolBakers.OreToolBaker` back.

## 4. Stale docs and comments

Fix these as you touch them (TODO §9: "kill stale comments on sight").

- **`trap.js` no longer fails.** START-HERE §1 and §5, HANDOFF §2.4, OPEN and
  `suite.sh` (`KNOWN_FAIL="trap"`) all call it a known failure. On 2026-10-05 the
  suite ran **34 passed, 0 failed, 0 did not run**, with `trap` among the passes.
  *Read.* OPEN also says `zones.js` is red; it passes.
- Counts have drifted. START-HERE says "101 commits ahead" and "23 checks" and
  "11 need luau"; git says 86 commits ahead of `main` at the time, and the suite
  has 34 checks, 14 of which need the luau binary. MineServer is about 17,050
  lines and MineClient about 12,255 (docs say 16.7k / 14.8k and 11.9k); there
  are 212 `.luau` files (docs say 199 or 210). *Reported.*
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
  35326298. Ore icon art was uploaded in `f5b6c34` (164 assets) although TODO
  §6.3 and BLOCKED #11 say it is not applied. Who owns the uploads is unverified.
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
