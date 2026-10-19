---
title: The verify suite
type: code
status: current
verified: 2026-10-14 @ a299374
sources:
  - tools/verify/suite.sh
  - tools/verify/syntax.sh
  - tools/verify/_luau.js
  - tools/verify/tool-dps.js
  - docs/START-HERE.md §1, §4.5, §4.6
  - docs/HANDOFF.md §2.4
  - docs/OPEN.md
  - tools/verify/runes-retired.js
  - tools/verify/text-motion.js
  - tools/verify/_shared.js
  - tools/verify/pet-identity.js
  - tools/verify/cards-tab.js
  - tools/verify/reveal-runs.js
  - tools/verify/crypt-ui.js
related: [luau-traps, tools-and-generators, local-setup, tools]
---

# The verify suite (`tools/verify/`)

> There are no playtests in a cloud session, so these Node checks are the safety
> net. HANDOFF §2.4 says "Every check in `tools/verify/` was written after a real
> bug." Run `syntax.sh` first, then `suite.sh`.

## How to run it

```
bash tools/verify/syntax.sh     # fetches luau into .luau-bin/, then parses every src/ file
bash tools/verify/suite.sh      # runs every check: pass / FAIL / DID NOT RUN
```

- **`syntax.sh`** downloads the Luau release for this OS into the gitignored
  `.luau-bin/`, then runs `luau-analyze --mode=nonstrict` over every file. It
  reports **SyntaxError only**; type errors are ignored.
  - If the download fails it prints "skipping" and **exits 0**, so work is never
    blocked.
  - It does **not** catch the 200-local overflow. Tested here: `luau-analyze`
    accepts 205 locals, while `luau-compile` rejects them with "Out of local
    registers". See [luau-traps](luau-traps.md).
- **`suite.sh`** runs every `tools/verify/*.js` except helpers (`_*.js`) and the
  `luau-balance` utility.
  - Output containing `luau not present|skipping|cannot run|not runnable` counts
    as **DID NOT RUN**. That fails the run, because a skip is not a pass
    (START-HERE §4.6).
  - `KNOWN_FAIL` is **empty** since 2026-10-06. `trap` was the last entry and it
    passes, so a clean run is 0 failed *and* 0 known. Anything back in that list is
    a regression someone decided to live with, and needs its reason written beside it.
  - Exit code: 0 only if everything ran and passed.
- Single check: `node tools/verify/<name>.js`. Utility: `node tools/verify/luau-balance.js FILE`.
- **Windows / PowerShell:** no suite `.ps1` yet — run one check per line, e.g.
  `node tools/verify/tool-dps.js`, or use Git Bash for `suite.sh`. Never chain
  with `&&` ([local-setup](local-setup.md)).

## Result at `98c141a` (run 2026-10-16 in a Linux cloud container, after merging the owner's working branch)

**66 checks. 64 passed and 2 failed on the first run; 66 passed on the second.** `syntax.sh`:
273 files, no syntax errors. `compile.js`: `MineServer` 12 and `MineClient` 11 top-level
locals left. The two first-run failures are fresh-checkout effects, not regressions:

- `generated-fresh` fails once on a clone with no `build/depth-sheet.json` (see below).
- **`skins` fails once on a Linux checkout.** `tools/gen/skins.js` writes `MineSkins.luau`
  with **CRLF** (`lua.join("\r\n")`), and the check asserts "regenerating is byte-identical".
  Git stores the file as LF (`git ls-files --eol` says `i/lf`). I infer the owner's Windows
  checkout is CRLF, which would explain why it passes there; I have not seen that machine. On Linux the first run rewrites the tracked file to CRLF and fails, and the second
  run passes. **Do not commit that rewrite**: `git checkout -- src/ReplicatedStorage/Mine/Shared/MineSkins.luau`.

Checks documented below are the ones whose rows I kept or wrote; the suite has more than the
table lists (for example `fishing`, `enchants`, `forge-hub`, `today`, `set-pets`), which the
owner's session added without a row here.

## Result at `299dd2c` (run 2026-10-10 on the owner's Windows machine)

**54 passed, 0 failed, 0 did not run, 0 known failures.** The newest check is `daily-wheel`.

## Result at `41d8f3a` (run 2026-10-07 on the owner's Windows machine)

**42 passed, 0 failed, 0 did not run, 0 known failures**, with
`syntax.sh` at 212 files clean and `compile.js` reporting 5 top-level locals of
headroom in `MineServer` and 7 in `MineClient`.

Three checks arrived after the run below: `compile` (the register ceiling,
2026-10-06), `depthgate` (depth credit, 2026-10-06) and `chunkload` (the chunk
generation ceiling plus per-server randomness, 2026-10-07).

## Earlier result at `26036a0` (run 2026-10-05 in a Linux cloud container)

- `syntax.sh`: fetched `luau-ubuntu.zip`, so the network was available. Result:
  **212 files, no syntax errors.**
- `suite.sh`: **32 passed, 2 failed, 0 did not run, 0 known failures.**
  - `generated-fresh` **FAIL on a fresh clone only.**
    - It runs `gen-mine-map.js --check` *before* it rebuilds the gitignored
      `build/depth-sheet.json`, so the first run hits ENOENT.
    - The same check then rebuilds the file, so a second run passes. Confirmed
      by re-running.
  - `wiki` FAIL. `tools/verify/wiki.js` arrived with the wiki itself, in the
    commit after `26036a0`. It fails until the wiki index and log pages exist.
  - `trap` **passes**. `suite.sh` still lists it in `KNOWN_FAIL`, and START-HERE
    §1, §5, HANDOFF §2.4 and OPEN Housekeeping all still say it fails. Those
    notes are stale; `5a85c73` fixed it. `zones` also passes, although OPEN
    still calls it RED.

## Every check

**L** marks the 14 checks that execute the `luau` binary. Without the binary they
DID NOT RUN. The docs say "11 of 23", which is stale: there were 36 checks at `b19c4c2` (`oreskins` arrived in `9733a05`, `heldtool` in `b19c4c2`). **This table is not complete:** at `4e4fbb3` `tools/verify/` holds 67 `.js` files (helpers included), and many newer checks (for example `enchants`, `forge-hub`) are not listed here yet. The counts in this paragraph were not rechecked on 2026-10-12.

| check | asserts |
|---|---|
| `askfirst` | the owner's ask-first rule is present at every agent entry point (`CLAUDE.md`, `AGENTS.md`, `house-rules.txt`, the pasted prompts, the Claude.ai text, TODO §0.35); the `UserPromptSubmit` and `SubagentStart` hooks exist, are plain single-quoted `echo`s PowerShell can run, and the subagent one is `additionalContext` JSON; the old soft rule has not come back |
| `bignum` **L** | `MineBigNum` and `MineAbbrev.currency` agree: 4 significant figures, always floored |
| `breaking` | the ORE_REACH +15 rule matches in `MineBreaking.blockStrength` (the gate) and `MineConfig.canBreakOre` (the UI) |
| `build-stamp` | every `MineBuild.EXPECT` module exists and says what the player loses. The client calls `announce()`. |
| `buyqty` | the typed quantity box, the cart and the server clamp share one ceiling |
| `charms` **L** | runs the real MineCharms generator against the real 82-ore roster |
| `check` | the tool-level curve behaves, using the tables in `tools/upgrade-calculator.html` (generated from MineConfig) |
| `config-refs` | every `MineConfig.X` the code reads exists. Strips comments first. |
| `crypt` **L** | the Candy Crypt redesign (2026-10-19), on the real modules and the real `MineCrypt`: only Crypt tools spend Crypt rock and Event Horizon's pools are unchanged, the swap rule in and out of the Crypt, Trick-or-Treat 85/5/7/2.9/0.1 with no candy back (200,000 rolls), chest tool odds by band, candy 3x, rock from zone 3 to zone 10 with the old coin curve, sixteen candy ores, the 3-into-1 variant merge, keep-after-event (weaker in the main world), the six charm recipes, SELL ALL never selling locked or candy ores, and the MineServer hooks |
| `crypt-ui` **L** | the Candy Crypt's client half and the event themes (2026-10-19). Statically: every `crypt*` verb read off `MineCrypt`'s `VERBS`, and `buyTrickOrTreat`, is sent by some UI with the payload it reads. The exceptions are `cryptEquip`, `cryptMerge` and `cryptCraftCharm`, whose screens wait for the Crypt's next redesign (owner, 2026-10-19). OPEN reaches the remote through every hop (`MineCryptView` -> `MineEventsView` -> `MineClient`). Every push the Crypt fires is handled, except `cryptMerged`. No Events or Crypt screen reads `bigbangOwned` or says "Claim Event Horizon" / "enter from Zones", and the Events tab mounts through `pcall`. The pouch's SELL UP TO and candy sale are wired end to end: the pouch reads no field the shop does not pass, a locked candy ore is never sent, and the pouch can be opened. The pop-up shows once and sends `cryptNoticeSeen`. The case's price is the snapshot's, the odds sheet's placeholder (`mountCaseOdds`) is in place, and no new screen scales text. **Runs** `MineEventTabs`, `MineEventNotice.shouldShow`, `MineTheme` (roles, contrast over 7:1, `eventKeyOf` on 14 ids) and `MineCryptView.openState` against the real `MineConfig` / `MineCryptRules`. Then it **mounts** the Events tab, the pop-up and the pouch on a GUI stand-in and presses their buttons. Fails on `db59c60` (59 failures). |
| `craftcost` **L** | craft cost depends on drop amount, rarity and progression |
| `daily-wheel` **L** | the daily wheel: weights sum to 100, the 16 slice ids are unchanged, every slice prints odds, a free spin gives a pet at most 10% of the time, the daily allowance (base, group, streak), a UTC-day reset, and a landing on the rolled slice from any start angle. Source checks: the lobby build is live, rebirth keeps the field, a spin saves, free spins go first and paid spins obey `PolicyNoRandom`, and the world wheel spins on the client. Added 2026-10-10. |
| `damage-curve` | levelling matters past level 34 for every tier, and forging above tier 60 is a visible gain |
| `deals` **L** | limited deals and the Founders Pack give what the shop says (launch audit M6, M7, M8, S4, S6, 2026-10-19). **Runs** the real `MineRotatingOffers`: the header counts the 47-day season, countdowns run on the season clock, "new offers" counts to the next weekly offer, Lucky Block Week is refused without a pet minter and otherwise mints its pet once and pays 9 blocks and 8 paid wild cases, max 3, and the random-buy test. **Runs** `MineFounders.grant`: the bag is granted once. Statically: the deal's pet is a real Epic set pet, its packs are wild cases, nothing touches `ownedPets.lucky_block`, no blurb names a date, a Robux receipt at the max pays credits back, the client will not prompt for a maxed deal, every `Founders.grant` passes the bag grant. Fails on `2efdf89` (27 failures). |
| `economy-exploits` **L** | the depth-desk sell curve never decreases with depth and no desk pays less than the surface, and no (forged-at, scrapped-at) pair beats a full climb. **Executes** the real functions and keeps the pre-fix arithmetic to prove the exploit was real. |
| `launch` **L** | the season is a duration: before launch `seasonNow()` is pinned to `SEASON_START`, after launch it advances from `launchedAt` (a year-late launch gives the same first week), the cosmetic teaser falls and rolls over, the three `SEASON_START` constants agree **the pass is exactly `PASS_SEASON_DAYS` (28) long and ends inside the 47-day season, which the offers and Event Horizon share**, the save happens before the announcement, a failed read or save leaves it unlaunched, `launchSeason` is reachable, **the launch stamp is mirrored to clients only after it is saved, and no client hands the raw server clock to the pass countdown** |
| `paid-odds` **L** | every paid random buy shows its odds before purchase, and the region rule covers it (launch audit M3, 2026-10-19). Statically: the Mystery Case buyer, the Packs hero, every Build-a-Box tile, the Charms Pack, the Forge's book bundle and every trader case have an ODDS / ⓘ button whose sheet reads a module, with no typed percentages; `Verbs.PAID_RANDOM` covers random credit deals, trader cases and bought wheel spins. **Runs** the real `MineCharms`, `MineEnchants`, `MineTrader` and `MineCases` and draws each roll against its odds: `packOdds`/`rollPack`, `chestCharmOdds`/`rollChestCharm`, `bookOdds`/`rollBookId`, `caseOdds`/`rollCase` (tiers, families, grades), `wildGradeOdds(true)`/`rollWildSet(paid)`. Fails on `2efdf89` (17 failures, then the run errors). |
| `oreframes` **L** | the baked `MineOreTools.FRAME_STATS` and `typeMult` steps equal what the priced roster supplied (2,460 values, 0 mismatches), so the roster can be deleted |
| `tool-dps` | TODO B1/B2 DPS table for forged families: prints single-block `dps` and full-footprint `edps`; asserts pick faster than hammer, hammer crowns single-block `dps`, jackhammer ≈ drill, area on drills/explosives, line depth baked, and same-grade explosives top `edps`. Pure JS. Added 2026-10-13; retuned 2026-10-14. |
| `dmg-live` **L** | runs `toolTierPower` in real declaration order |
| `forge-snap` | the Forge reads no snapshot field the shop does not pass it |
| `forge-upgrade` | forging the next tier carries the level across, so it is an upgrade |
| `forge-cards` **L** | a Forge card says what the server does (launch audit S9, S11, 2026-10-19): the craft verb and every panel price through `MineOreTools.craftCost`, the held forged tool and every card's hit through `MineOreTools.hitPower`, a new craft's level through `inheritedLevel`. **Executes** them: the price is the card's number for every ore x family and the server's old tierless price really differed; `hitPower` equals the swing's old inline arithmetic on 14,000 rows (nothing held moved) and the card's old `toolPower`-only number really differed (Stone Hammer: card 10, hits 37); the hits a second, area and use each family reports. |
| `recycle-quote` **L** | every SCRAP quote equals the server's payout: the server's `recycleOreTool`, the Forge hub and the old Forge all call `MineOreTools.recycleRefund`, and nobody computes `toolRecycle` by hand. **Executes** it against the server's pre-S10 arithmetic (nothing moved) and both old panel forms, base 1 and the three-arg call, to prove the harness sees them. |
| `skin-wear` **L** | one rule for which skin a tool wears (owner, 2026-10-19: *"one wardrobe everywhere"*): `equippedTool` wears the skin on whatever `Dig.toolInHand` returns, the kit and the look read its `skinId` stamp, `equipSkin` falls back to the class in hand, the ore case pays a wardrobe skin (S14), and the wardrobe reads `snap.tool` and shows power and "stats only". **Executes** `MineToolSkins` and the server's own `skinBase` / `Dig.wearSkin` / `equippedTool` slices on a forged row, an event tool and a Crypt-shaped record. |
| `gate-coverage` | every function that deals block damage consults the breaking gate |
| `generated-fresh` | `mine-map.html` and `upgrade-calculator.html` regenerate byte-for-byte (`--check`) |
| `ladder-climbable` | the ore ladder reaches tier 82 with no zone deadlock, and the Exotic band stays rare |
| `heldtool` | the held forged-tool row carries `oreTier` and `oreId`, so `MineBreaking.toolBreakingPower` resolves it from its ore, not as 1. **Executes** the real function against the real row shape, keeps the old broken row to prove it resolves to 1, and asserts both roster-migration guards are `<` not `~=`. |
| `layers` **L** | two boost layers, and the second multiplies the first. The owner's 100 → 300 example. |
| `lucky-odds` **L** | lucky blocks show their odds, and those odds are the odds rolled. `gradeOdds` sums to 1 from every start and matches 200,000 real `rollClash` rolls. `rollLoot` draws match `KIND_TABLES`. The sheet adds up. The credit shop, the bag's ⓘ and the lucky screen all show `MineLuckyOddsView`, with no percentages typed in by hand. Since 2026-10-10 it also checks the prizes are real wild cases and real ore tiers, a better grade or block never pays a worse case, and grade-ups are off. Added 2026-10-08, because blocks are sold for Robux-bought credits and showed no odds. |
| `minemap-runs` | `mine-map.html` actually executes under a DOM stub |
| `oreforge` **L** | a forged tool IS its ore: the frame is derived from the ore's tier |
| `orepacks` **L** | the preconditions for `Dig.bankOrePacks`: no pack bigger than a tier-1 pouch, and the midpoint pays fairly |
| `oreskins` | no tool is sold for coins, and every ore tier has its own distinct pickaxe icon. The refusal is asserted on the **server**, at the surface and depth doors, not on the shop rail. |
| `oretools` **L** | `ToolModelFactory.oreLook` gives the 82 ore tools distinct looks |
| `outpost-depth` | outpost colours are wired to depth, not constants |
| `packs` **L** | fossil packs are gone, and the chest loot tables are still well formed |
| `pet-spring` **L** | the pet-follow spring is stable at any framerate (`26036a0`) |
| `pet-identity` **L** | runs the real `MineCards`, `MineEnchants` and the whole roster (via `_shared.js`): every named pet's family and trait come from its name and home, the spread is healthy (no family over 30%, all 12 traits, none over 15%), every copy from any source agrees, pay and text read one identity, the 41 legacy sets' prints keep theirs; Lone Wolf and Squad Bond text reads the pets-out count; lines the Special gate zeroes carry "needs a Zap Special". Launch audit S32–S34, 2026-10-19. |
| `halloween-power` **L** | the Candy Crypt v2 pet and skin rules (owner, 2026-10-19), on the real modules via `_shared.js` (MineConfig's `cardPower` sliced in): every Halloween Mythic, Divine and Exotic is at least 1.2x (and its `TOP_BEAT`) the best non-Halloween pet on `MineCards.boostScore`, and the generator's `BEST_NORMAL` is the one the game finds; every Halloween S/SS/SSS skin is 1.2x the best other skin of its grade on `baseOf` and kit points, and `MineToolSkins.wear` spends it; `MineHalloweenPets` (`pool`, `isHalloween` from any source, `card`, `buildOf`); the twelve new pets build today (`PetModelFactory` wears the fallback until their body exists) and keep identity from name and home; the builds beat every normal pet's chance in their family by 20%, Blast Radius pays only on a named Halloween kit (at most 30 pets), the gate keeps it on a bomb and zeroes it on a Zap tool, and `MinePatterns.MAX_BLAST_RADIUS` bounds a bomb. Fails on `3863d14`. |
| `cards-tab` **L** | the Cards tab's rail draws only the real seats (no "GET VIP"); its card faces go through a cache that is **run** against stub frames (paint once, reuse, repaint on a change, lift, prune); the Hats/Faces collection lists `MineHats.dropCatalog`, which matches the drop pools exactly. Launch audit M5, S35, S37, 2026-10-19. |
| `reveal-runs` **L** | a Gear Vault reels all its items; a run of reels waits for each close and has SKIP ALL (the run logic is lifted out and **run**); a rare find prints its true rarity while `hypeRankOf` sizes the celebration (the pull score is run); the lucky SKIP ALL card lists books, potions and named skin cases (`runRows` is run). Launch audit S24, S25, S28, S29, 2026-10-19. |
| `procs` **L** | proc damage and proc chance are separate stats, and the zap chain terminates |
| `seams` | a JS model of the coin-priced seam ladder. **Seams are free now** (`MineDepth.seamPrice` returns 0), so this asserts a retired design. |
| `shop-guards` **L** | the shops charge what they say, once, for things they still sell (launch audit M4, S1, S3, S5, S7, S8, 2026-10-19). Statically: the Founders Rig reads and charges credits in two taps; a cart checkout sends nothing while one is out, carries an order id, and `buyCart` refuses an order it was paid for (one debit, after pricing); the desk prices bags in gems; the Starter popup reads the bag, coins and pet fields the server grants, with the same fallbacks. **Runs** `MineDepthShop.catalog` (no refused coin tools, gem-priced bags, no Founders Rig, Event Horizon tools kept) and the real `MinePackConfig` + `MineCases` shelf (no retired pack has a price; a box of ten of one pack is the 10x bundle, a mixed box 12% off). Fails on `2efdf89` (22 failures). |
| `skilltree` | every stat the tree grants is applied by the server |
| `statkeys` | renamed stat keys (`oreYield`) still read in old saves |
| `stats` **L** | `MineStats.STATS`, `STAT_ORDER`, `emptyBoosts` and `ADDITIVE_STATS` agree |
| `runes-retired` | runes, scrolls, sockets and tool traits stay retired (2026-10-12): the five modules are deleted and nothing requires them; no rune, scroll or trait verb; `boosts()` pays none; old saves drop the fields; the pass, Founders pack and wheel pay books where they paid scrolls and runes; the tutorial and quests teach enchants; the Enchanter keeps Summon / Temper / Salvage / Dust; runes are not a trade kind; the rune cases are gone. Replaces the deleted `traits` **L** check (`tools/verify/traits.js`), which pinned the trait rules. |
| `kid-text` | the kid-friendly pass (2026-10-19): `MineKidText.toast` turns "800 Coins" into "💰 800" on real toasts and leaves "Gem Shop" alone; the client runs every toast through it; every tutorial step in the walk-through carries an icon. |
| `text-motion` | text never rides a scale animation: `MineUI.pulse` gives anything with text a ring pulse (a text-free ring scales, the thing holds still), `popNumber` lights the outline instead of popping a size, and the Forge hub repaints on a snapshot only on a real change, at most about once a second. Pure JS. Added 2026-10-17 (owner: *"the font sizes flicker"*). |
| `trader` **L** | the wandering-trader rules: 5 distinct placements and no collisions over thousands of rotations, flat visit spread, a trader cannot stock a case outside its depth gate (and the deep spot can), prices rise with depth and zone and never fall below base, the charm and hat cases follow the chest/temper ladders; statically, that the outpost list is **sorted** before placement, `buyTraderCase` re-derives the roster, checks the shelf and takes the price from the shelf row, trader parts are non-query and non-shadow, and the panel's countdown ticks on `RunService.Heartbeat` |
| `trap` | in the calculator, "levels re-bought" is independent of tier, type and level |
| `tune` | which calculator dial controls "too many ores" |
| `ui-scale` | the shipped `refreshMineUiScale` rule (parsed from the client) fits every fixed panel on twelve displays, and lists the displays where no scale can help as outstanding panel work |
| `veins` **L** | the vein lattice keeps per-block ore density unchanged, the size distribution matches the owner's spec, and the field is re-rolled per server |
| `chunkload` **L** | generation stops at the open chunk, the far path does not claim the frontier, and layer 1 differs per server cell by cell |
| `compile` | every file passes `luau-compile`, and the two big scripts have top-level-local headroom left |
| `depthgate` **L** | depth credit is earned: the one-block jump and the patient `DIG_LEAD` hop both fail, and ordinary digging never does |
| `wiki` | wiki frontmatter, links, index coverage, cited paths, `Module.SYMBOL` drift |
| `zones` | the calculator's zone panel reproduces the live numbers |

## Known weak spots

- **Negative assertions with no floor**: `skilltree.js:48`, `skilltree.js:100` and
  `forge-snap.js:63` pass when their regex matches nothing (START-HERE §4.6, OPEN).
- **Checks built on a model**: `check`, `trap`, `tune` and `zones` read the
  generated calculator page, not the Luau. They are only as good as
  `tools/gen/upgrade-calculator.js`.
- `dmg-live`'s harness calls `os.exit(1)`, which is nil in this Luau build. A
  failure still exits non-zero, but only because calling nil errors.
  `bignum.js` explains why that is fragile.
- `luau-balance.js` crashes when run without an argument (OPEN Housekeeping).
- **A sliced constant with an `or` fallback is invisible when you forget to slice
  it.** The checks that run real Luau rebuild a module by slicing named lines out
  of the source. `MineConfig.veinSizeMean` reads its dials as
  `MineConfig.X or <default>`, so when `VEIN_SPREAD_LO/GAIN` were added and
  `veins.js`'s slice list was not updated, the harness silently measured the
  **defaults** and returned a byte-identical histogram after the shipped values
  changed. Nothing failed. If a tuning change appears to do nothing, check the
  slice list before believing the measurement (2026-10-07).
- **`block(head, "}")` runs past a one-line table.** It scans forward for a line
  that is exactly `}`, so asking for `MineConfig.ORE_BAND_ORDER = { ... }` — a
  one-liner — swallowed 90 further lines, including the `do` block that derives
  `ORE_DMAX` from `MineDepth`, and the harness then died on a `Depth` stub with no
  `dirtHp`. Use `line()` for one-liners. Same trap as `MineDepth.SEAMS` and
  `MineBreaking.MAX`.

## How to add a check

1. Write it **after** a real bug, and make sure it **fails on the broken code**
   before you fix anything (HANDOFF §2.9).
2. **Strip comments before matching.** Four checks once matched their own
   explanatory comments (START-HERE §4.5). `config-refs.js` has a `stripComments`.
3. Put a non-zero floor under every count you assert over.
4. To run Luau, use `require("./_luau")` for the binary path. If it cannot run,
   print the skip wording `suite.sh` matches. Decide the exit code in JS from
   the output, not with `os.exit` in Luau. To run real `Mine/Shared` modules
   with their own lazy requires, `require("./_shared").prelude(ROOT, names,
   folders)` gives a fake `Shared` folder (`pet-identity.js` uses it).
5. Name it `tools/verify/<name>.js`. `suite.sh` picks it up automatically.

## Windows notes

- `syntax.sh` picks `luau-windows.zip` under MINGW, MSYS or Cygwin. It needs
  bash, for example Git Bash *(the owner's setup is unverified)*.
- `_luau.js` prefers `luau.exe` on win32 and reads the ELF/PE header, so a stale
  Linux binary in `.luau-bin/` is reported, not silently run. Delete `.luau-bin`
  and re-run `syntax.sh`.
- From PowerShell, run each line on its own, with no `&&` ([local-setup](local-setup.md)).
