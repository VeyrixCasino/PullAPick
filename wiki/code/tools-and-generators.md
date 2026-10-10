---
title: Tools and generators
type: code
status: current
verified: 2026-10-05 @ b19c4c2
sources:
  - tools/serve.js
  - .claude/launch.json
  - tools/gen-mine-map.js
  - tools/gen/upgrade-calculator.js
  - tools/skills/gen.js
  - tools/gen-ores.js
  - tools/gen-depth-sheet.js
  - tools/gen-ore-icons.js
  - tools/gen-charm-icons.js
  - tools/icons/gen-charm-art.js
  - docs/HANDOFF.md §2.3
  - docs/OPEN.md
related: [verify-suite, assets-and-uploads, code-map, rojo-and-studio, local-setup]
---

# Tools and generators (`tools/`)

> About 50 Node scripts and six HTML pages. Some **generate** files from the live
> config and are safe to re-run. Many are **one-off patches** that edited `src/`
> once and must not be run again. The rest **model** numbers and write nothing.
> Every script is run from the repo root: `node tools/X.js`.

## Generators: safe to re-run, and each has a `--check`

| script | writes | from | notes |
|---|---|---|---|
| `tools/depth-sheet-data.js` then `tools/gen-mine-map.js` | `build/depth-sheet.json` (gitignored), then `tools/mine-map.html` | `MineDepth` and `MineConfig`, plus `tools/mine-map.body.html` | `--check` diffs without writing. Run the data script first on a fresh clone ([verify-suite](verify-suite.md)). |
| `tools/gen/upgrade-calculator.js` | the data in `tools/upgrade-calculator.html` | `MineConfig` | `--check`. Replaced a hand-written 121-ore, 1000-level copy (OPEN Housekeeping). |
| `tools/skills/gen.js` | `MineSkillData` node percentages | `MineSkillData.ENERGIES` and `MineStats.weight` | `--check` gives "0 would change" at `26036a0`. Rebuilt because the original was never committed (HANDOFF §2.3). |
| `tools/gen/zone-pets.js` | `MineZonePets.luau`, `docs/ZONE-PETS.md` | its own name and buff tables, the roster, `PetModelFactory` | `--check`. The zone pots (70 a zone) and every named pet's kit. Never reads the sets. |
| `tools/gen/set-pets.js` | `SetPets/<Set>.luau` (19), `docs/SET-PETS.md` | `tools/gen/sets/*.json`, `PetBodies/*.luau`, `Zone.build()` | `--check`. The 19 sets' 2,043 pets. Checked by `tools/verify/set-pets.js`. |
| `tools/gen-ore-icons.js` | `src/ReplicatedStorage/Mine/Shared/MineOreIcons.luau` | `build/icons/ids.json` (tracked) and the live roster | exits non-zero if any ore lacks an icon |

`tools/verify/generated-fresh.js` fails the suite when the mine map or the
calculator page drifts from the config.

## Generators you should not re-run as-is

| script | why not |
|---|---|
| `tools/gen-ores.js` | It writes `MineConfig.ORES` and `ORE_MIGRATION` from `docs/ore-remake.md`, which is the **121-ore** roster, marked STALE. A dry run is the default and harmless. **`--write` refuses today**, because 13 live ids (ember, rime, aetherite…) have no mapping. That refusal is its only guard; never bypass it. |
| `tools/gen-depth-sheet.js` | It overwrites `docs/depth-sheet.md` using the **retired** HP curve (`SECTIONS` × 6^(z−1) × 2). `MineDepth.dirtHp` is now linear × 5^(z−1) (`5a85c73`). Fix the script before running it. |
| `tools/icons/gen-charm-art.js` (+ `charm-data.js`, `raster.js`) | It draws 164 charm PNGs into the gitignored `build/charm-icons/` and writes the tracked `manifest.json`. The owner rejected this art (HANDOFF §2.6), and **icons are the owner's job** (START-HERE §6). |
| `tools/gen-charm-icons.js` | It would write `MineCharmIcons` from `build/charm-icons/ids.json`. Neither file exists yet, because no charm icons have been uploaded. |
| `tools/icons/svg-icon-extract.js`, `match-icons-to-ores.js` (+ `ore-map.json`, `asset-ids.json`) | Added in `9733a05`. The first pulls 88 pickaxe icons out of an SVG that is really paired base64 PNGs (content plus mask). The second matches icons to the 82 ores by colour with an optimal (Hungarian) assignment and writes `ore-map.json`. **The matching is not final**: the roster wants about 17 grey picks and the sheet has 9, and every pair is printed with its distance. `asset-ids.json` maps icon files to uploaded asset ids; `MineIcons.ORE_PICK` is what the game reads. |
| `tools/extract-svg-icons.js` (+ `tools/_png.js`) | Added in `b19c4c2`. It saves every icon in a Canva-exported SVG sheet as its own transparent PNG (colour image plus its matte folded into RGBA), numbered in reading order. `_png.js` is a zero-dependency PNG codec shared by the sheet tools; `slice-ore-sheet.js` still carries its own copy. The 88 pickaxe icons it produced are tracked in `build/pickaxe-sheet/`. Usage: `node tools/extract-svg-icons.js` followed by the sheet path. |
| `tools/map-ores-to-tiles.js`, `tools/slice-ore-sheet.js`, `tools/pack-ore-art.js` | The 2026-09-28 ore-face pipeline: hand-made tiles become `build/ore-sheet/` files, which become `MineOreArt` packed pixels. It was built for 121 ores. |
| `tools/balance-board-data.js` | It writes `build/balance-board.json` (gitignored). `tools/balance-board.html` does not fetch that file *(how the page gets its data is unverified)*. |

## One-off patch scripts: already applied, do not re-run

These scripts edit `src/` (mostly MineServer, MineConfig or a view) by splicing
strings at anchor text. Most have **no "already applied" guard**, so running one
again would double-insert code or fail half-way.

- **Ore and save:** `add-ore-migration.js`, `rename-ores.js`, `add-item-uids.js`,
  `add-upgrade-model.js`, `add-bench-verbs.js`
- **Shop and bench:** `shop-fit-cylinder.js`, `shop-fit-radius.js`,
  `shop-fullscreen-stage.js`, `shop-restore-stage.js`, `shop-tabs-and-bench.js`,
  `bench-fail-loud.js`
- **Procs and pets:** `proc-clamp.js`, `proc-rework.js`, `quake-stacks.js`,
  `ricochet-identity.js`, `strip-echo-pets.js`
- **Other:** `redo-chest-tables.js` (it does detect "already applied" for its
  table), and `port-studio-edits.js`, which carried Studio-only edits into `src/`

Read them as a record of how a change was made. The commit that ran each one is
the real source.

## Models and measurements: read-only, safe to run

`damage-fix.js`, `depth-gate.js`, `zone-gate-fix.js` ("does NOT write anything"),
`forge-feel.js`, `level-steepness.js`, `ore-dmax-fit.js` ("MODELS ONLY"),
`proc-odds.js`, `q-primordium-5000.js`, `zap-ev.js`, `zap-solve.js`.

- Each one prints the numbers behind a 2026-10-04/05 balance decision, with the
  owner's request quoted in its header.
- They parse constants from the Luau, so a re-run reflects the current config.

## HTML pages and the local server

| page | what | current? |
|---|---|---|
| `tools/mine-map.html` | depth, HP and ore map, plus a tool calculator | generated, checked by `generated-fresh` and `minemap-runs` |
| `tools/upgrade-calculator.html` | the tool upgrade bench | data generated; read by `check`, `trap`, `tune`, `zones` |
| `tools/balance-board.html` | the balance board | rethemed in `44a1d5f`; data source unverified |
| `tools/forge-mockup.html` | a Forge UI mockup | design reference only |
| `tools/ore-browser.html` | the "Ore Cabinet" | **stale**: it embeds the 121-ore roster |

- **Running the pages.** `tools/serve.js` is a static server on port 7421. The
  "tools" entry in `.claude/launch.json` runs `node tools/serve.js`. Its header
  says it is "started via `.claude/launch.json`, never by hand".
- It sends `no-store` headers, and refuses paths outside the repo.
- **Use the full path**, for example `http://localhost:7421/tools/mine-map.html`.
  `/` maps to `tools/index.html`, which does not exist.

## Studio, sync and agent helpers

- `tools/studio-probe.luau`: read-only probes to paste into the Studio command
  bar. They check the depth gate and measure blocks per hour.
- `tools/export/`: the syncback receiver, the export script and the sync script.
  See [rojo-and-studio](rojo-and-studio.md).
- `tools/start-local-agent.ps1` and `tools/claude-rojo-clean.ps1`: launchers for
  the owner's machine. See [local-setup](local-setup.md).
- `tools/agent/house-rules.txt`: a short briefing for any agent. Its "~14.8k
  lines" for MineServer is stale; the file is 17,050 lines.
- `tools/verify/`: see [verify-suite](verify-suite.md).

## Gotchas

- `MineTools` says "GENERATED BY skills-src/gentools.js". That generator is
  not in the repo (HANDOFF §2.3), so edit MineTools by hand with care.
- Scripts preserve CRLF line endings when the target file has them. Keep that
  behaviour in any new patch script.
