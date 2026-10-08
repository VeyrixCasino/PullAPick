---
title: The verify suite
type: code
status: current
verified: 2026-10-08 @ bae3c5b
sources:
  - tools/verify/suite.sh
  - tools/verify/syntax.sh
  - tools/verify/_luau.js
  - docs/START-HERE.md §1, §4.5, §4.6
  - docs/HANDOFF.md §2.4
  - docs/OPEN.md
related: [luau-traps, tools-and-generators, local-setup]
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
  - It does **not** catch the 200-local overflow (`luau-analyze` accepts 205
    locals). `tools/verify/compile.js` does; see [luau-traps](luau-traps.md).
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

**L** marks the 18 checks that execute the `luau` binary (the original 14 plus
`compile`, `economy-exploits`, `heldtool` and `oreframes`, by a grep for how each
calls the binary; I did not run the suite with the binary removed). Without the binary they
DID NOT RUN. The docs say "11 of 23", which is stale: there are 41 now, counting `wiki` and `askfirst` (`oreskins` `9733a05`, `heldtool` `b19c4c2`,
`economy-exploits` `4cc82a5`, `compile` `5d59714`, `ui-scale` `39d94bf`,
`oreframes` `bef7b0d`). The run on 2026-10-08 was **40 passed, 0 failed, 0 did not run**.

| check | asserts |
|---|---|
| `askfirst` | the owner's ask-first rule is present at every agent entry point (`CLAUDE.md`, `AGENTS.md`, `house-rules.txt`, the pasted prompts, the Claude.ai text, TODO §0.35); the `UserPromptSubmit` and `SubagentStart` hooks exist, are plain single-quoted `echo`s PowerShell can run, and the subagent one is `additionalContext` JSON; the old soft rule has not come back |
| `bignum` **L** | `MineBigNum` and `MineAbbrev.currency` agree: 4 significant figures, always floored |
| `breaking` | the ORE_REACH +15 rule matches in `MineBreaking.blockStrength` (the gate) and `MineConfig.canBreakOre` (the UI) |
| `build-stamp` | every `MineBuild.EXPECT` module exists and says what the player loses. The client calls `announce()`. |
| `buyqty` | the typed quantity box, the cart and the server clamp share one ceiling |
| `charms` **L** | runs the real MineCharms generator against the real 82-ore roster |
| `check` | the tool-level curve behaves, using the tables in `tools/upgrade-calculator.html` (generated from MineConfig) |
| `compile` **L** | every one of the 212 source files compiles with `luau-compile` (not just `luau-analyze`), and `MineServer` and `MineClient` each have at least 4 top-level locals of headroom (5 and 7 on 2026-10-08) |
| `config-refs` | every `MineConfig.X` the code reads exists. Strips comments first. |
| `craftcost` **L** | craft cost depends on drop amount, rarity and progression |
| `damage-curve` | levelling matters past level 34 for every tier, and forging above tier 60 is a visible gain |
| `dmg-live` **L** | runs `toolTierPower` in real declaration order |
| `economy-exploits` **L** | the depth-desk sell curve never decreases with depth and no desk pays less than the surface, and no (forged-at, scrapped-at) pair beats a full climb. **Executes** the real functions and keeps the pre-fix arithmetic to prove the exploit was real. |
| `forge-snap` | the Forge reads no snapshot field the shop does not pass it |
| `forge-upgrade` | forging the next tier carries the level across, so it is an upgrade |
| `gate-coverage` | every function that deals block damage consults the breaking gate |
| `generated-fresh` | `mine-map.html` and `upgrade-calculator.html` regenerate byte-for-byte (`--check`) |
| `ladder-climbable` | the ore ladder reaches tier 82 with no zone deadlock, and the Exotic band stays rare |
| `heldtool` **L** | the held forged-tool row carries `oreTier` and `oreId`, so `MineBreaking.toolBreakingPower` resolves it from its ore, not as 1. **Executes** the real function against the real row shape, keeps the old broken row to prove it resolves to 1, and asserts both roster-migration guards are `<` not `~=`. |
| `layers` **L** | two boost layers, and the second multiplies the first. The owner's 100 → 300 example. |
| `minemap-runs` | `mine-map.html` actually executes under a DOM stub |
| `oreframes` **L** | the baked `MineOreTools.FRAME_STATS` and `typeMult` steps equal what the priced roster supplied (2,460 values, 0 mismatches), so the roster can be deleted |
| `oreforge` **L** | a forged tool IS its ore: the frame is derived from the ore's tier |
| `orepacks` **L** | the preconditions for `Dig.bankOrePacks`: no pack bigger than a tier-1 pouch, and the midpoint pays fairly |
| `oreskins` | no tool is sold for coins, and every ore tier has its own distinct skin in each family (246 distinct images). The refusal is asserted on the **server**, at the surface and depth doors, not on the shop rail. |
| `oretools` **L** | `ToolModelFactory.oreLook` gives the 82 ore tools distinct looks |
| `outpost-depth` | outpost colours are wired to depth, not constants |
| `packs` **L** | fossil packs are gone, and the chest loot tables are still well formed |
| `pet-spring` **L** | the pet-follow spring is stable at any framerate (`26036a0`) |
| `procs` **L** | proc damage and proc chance are separate stats, and the zap chain terminates |
| `seams` | a JS model of the coin-priced seam ladder. **Seams are free now** (`MineDepth.seamPrice` returns 0), so this asserts a retired design. |
| `skilltree` | every stat the tree grants is applied by the server |
| `statkeys` | renamed stat keys (`oreYield`) still read in old saves |
| `stats` **L** | `MineStats.STATS`, `STAT_ORDER`, `emptyBoosts` and `ADDITIVE_STATS` agree |
| `traits` **L** | the trait rules: prefix, odds tied to MineTemper's skins table, Exotic 1/1000 |
| `trap` | in the calculator, "levels re-bought" is independent of tier, type and level |
| `tune` | which calculator dial controls "too many ores" |
| `veins` **L** | the vein lattice keeps per-block ore density unchanged, the size distribution matches the owner's spec, and the field is re-rolled per server (two layout salts give two different mines; one salt gives the same mine) |
| `chunkload` **L** | generation stops at the open chunk, the far path does not claim the frontier, and layer 1 differs per server cell by cell |
| `depthgate` **L** | depth credit is earned: the one-block jump and the patient `DIG_LEAD` hop both fail, and ordinary digging never does |
| `ui-scale` | the shipped `refreshMineUiScale` rule (parsed from the client) fits every fixed panel on twelve displays, and lists the displays where no scale can help as outstanding panel work |
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
   the output, not with `os.exit` in Luau.
5. Name it `tools/verify/<name>.js`. `suite.sh` picks it up automatically.

## Windows notes

- `syntax.sh` picks `luau-windows.zip` under MINGW, MSYS or Cygwin. It needs
  bash, for example Git Bash *(the owner's setup is unverified)*.
- `_luau.js` prefers `luau.exe` on win32 and reads the ELF/PE header, so a stale
  Linux binary in `.luau-bin/` is reported, not silently run. Delete `.luau-bin`
  and re-run `syntax.sh`.
- From PowerShell, run each line on its own, with no `&&` ([local-setup](local-setup.md)).
