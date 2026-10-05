---
title: The verify suite
type: code
status: current
verified: 2026-10-05 @ b19c4c2
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
  - It does **not** catch the 200-local overflow. Tested here: `luau-analyze`
    accepts 205 locals, while `luau-compile` rejects them with "Out of local
    registers". See [luau-traps](luau-traps.md).
- **`suite.sh`** runs every `tools/verify/*.js` except helpers (`_*.js`) and the
  `luau-balance` utility.
  - Output containing `luau not present|skipping|cannot run|not runnable` counts
    as **DID NOT RUN**. That fails the run, because a skip is not a pass
    (START-HERE §4.6).
  - `KNOWN_FAIL="trap"` is reported as `FAIL (known)`.
  - Exit code: 0 only if everything ran and passed.
- Single check: `node tools/verify/<name>.js`. Utility: `node tools/verify/luau-balance.js FILE`.

## Result at `26036a0` (run 2026-10-05 in a Linux cloud container)

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
DID NOT RUN. The docs say "11 of 23", which is stale: there are 36 checks now (`oreskins` arrived in `9733a05`, `heldtool` in `b19c4c2`).

| check | asserts |
|---|---|
| `bignum` **L** | `MineBigNum` and `MineAbbrev.currency` agree: 4 significant figures, always floored |
| `breaking` | the ORE_REACH +15 rule matches in `MineBreaking.blockStrength` (the gate) and `MineConfig.canBreakOre` (the UI) |
| `build-stamp` | every `MineBuild.EXPECT` module exists and says what the player loses. The client calls `announce()`. |
| `buyqty` | the typed quantity box, the cart and the server clamp share one ceiling |
| `charms` **L** | runs the real MineCharms generator against the real 82-ore roster |
| `check` | the tool-level curve behaves, using the tables in `tools/upgrade-calculator.html` (generated from MineConfig) |
| `config-refs` | every `MineConfig.X` the code reads exists. Strips comments first. |
| `craftcost` **L** | craft cost depends on drop amount, rarity and progression |
| `damage-curve` | levelling matters past level 34 for every tier, and forging above tier 60 is a visible gain |
| `dmg-live` **L** | runs `toolTierPower` in real declaration order |
| `forge-snap` | the Forge reads no snapshot field the shop does not pass it |
| `forge-upgrade` | forging the next tier carries the level across, so it is an upgrade |
| `gate-coverage` | every function that deals block damage consults the breaking gate |
| `generated-fresh` | `mine-map.html` and `upgrade-calculator.html` regenerate byte-for-byte (`--check`) |
| `ladder-climbable` | the ore ladder reaches tier 82 with no zone deadlock, and the Exotic band stays rare |
| `heldtool` | the held forged-tool row carries `oreTier` and `oreId`, so `MineBreaking.toolBreakingPower` resolves it from its ore, not as 1. **Executes** the real function against the real row shape, keeps the old broken row to prove it resolves to 1, and asserts both roster-migration guards are `<` not `~=`. |
| `layers` **L** | two boost layers, and the second multiplies the first. The owner's 100 → 300 example. |
| `minemap-runs` | `mine-map.html` actually executes under a DOM stub |
| `oreforge` **L** | a forged tool IS its ore: the frame is derived from the ore's tier |
| `orepacks` **L** | the preconditions for `Dig.bankOrePacks`: no pack bigger than a tier-1 pouch, and the midpoint pays fairly |
| `oreskins` | no tool is sold for coins, and every ore tier has its own distinct pickaxe icon. The refusal is asserted on the **server**, at the surface and depth doors, not on the shop rail. |
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
| `veins` **L** | the vein lattice keeps per-block ore density unchanged |
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
