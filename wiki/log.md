---
title: Wiki log
type: meta
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - wiki/SCHEMA.md
related: [index, SCHEMA]
---

# Wiki log

Append-only. Newest last. Each entry starts `## [YYYY-MM-DD] kind | subject`,
where kind is `setup`, `ingest`, `query`, `lint` or `refactor`.

To see the latest entries, run `grep "^## \[" wiki/log.md | tail -5`.

## [2026-10-05] setup | Wiki created
Built on `claude/vigilant-fermi-aucqjy` @ `26036a0` (draft PR #6). That branch
was the newest state on GitHub, about 100 commits ahead of `main`. Added the
schema, 11 top-level pages, 22 system pages and 10 code pages (43 in all). Also
added the `CLAUDE.md` "Ask before you assume" rules, the `UserPromptSubmit`
reminder hook, the `/wiki` skill, and `tools/verify/wiki.js` (which `suite.sh`
runs with the other checks). Lint proven on planted errors; suite: 34 passed,
0 failed, 0 did not run.

## [2026-10-05] ingest | docs/, roadmap/, src/ (first pass)
First full pass over every doc in `docs/` and `roadmap/` and the shared and
server modules, by five parallel research passes (core loop, ore and tools,
build and collectibles, loot and social, codebase). Contradictions and probable
bugs found on the way are in [open-questions](open-questions.md). How current
each doc is, is in [sources-of-truth](sources-of-truth.md). I (the wiki-building
session) re-checked three findings against the code myself: the held-tool
breaking-power fallback, the roster-migration guard, and the `sync.ps1`
deletion of `tools/export/in/`. Everything else in open-questions is marked
*reported*.

## [2026-10-05] ingest | commit 9733a05 (PR #6): tools are forged, not bought
PR #6 gained a commit after the wiki's `26036a0` baseline. It removes every
coin-bought tool path (owner, 2026-10-05), keeps Backpacks, the Ore Pouch and
Secrets, and gives each ore tier its own pickaxe icon. Merged into this branch.
Updated: tools, shops-and-monetisation, currencies-and-economy, owner, glossary,
overview, open-questions, verify-suite (35 checks; `oreskins`),
tools-and-generators (new `tools/icons` scripts), luau-traps (the 200-local
ceiling broke the server again). Re-checked that `equippedTool` and the
`oreRosterV` guard are untouched by it, so probable bugs 1 and 2 still stand.
Pages not touched by that commit keep their `26036a0` stamp.

## [2026-10-05] ingest | commit b19c4c2 (PR #6): the wiki's first two bugs, fixed
Found by the 50-minute drift check. PR #6 gained "Forged tools can break rock
again, and migrations stop re-running", which fixes probable bugs 1 and 2 from
[open-questions](open-questions.md): the held-tool row now carries `oreTier` and
`oreId` (before, every forged tool stalled at zone 1, layer 50, measured live),
and both roster-migration guards are `< version`. Read the diff to confirm both.
It also records that the `sync.ps1` deletion of `tools/export/in/` is **not a
bug** (a gitignored scratch folder, deleted by design); I reworded that entry,
keeping the advice to put Claude.ai exports in `transcripts/`. New check
`heldtool.js` (36 checks now) and new `extract-svg-icons.js` / `_png.js`.
Updated: open-questions, tools, mining-and-breaking, ores,
save-data-and-migrations, verify-suite, tools-and-generators, index. Not
rechecked: Event Horizon tools' breaking power, and whether saves hit by the
migration re-runs need repair.

## [2026-10-07] ingest | the owner's session: chunking, veins, the ToolModels archive
Ingested from the working branch (`8d5c230`..`41d8f3a`) and from live Studio
measurements, because most of this was measured rather than reasoned.

**Chunking.** `MineDigAuth.canCreditDepth` splits depth CREDIT from digging:
`canDigLayer` ends in an unconditional `return true`, so one block at layer 5000
credited depth 5000 to anyone. `chunkCeiling` is the generation twin, clamped
inside `ensureZone`. Also fixed `ensureZone`'s far path claiming `builtTo`, which
left layers 4–2505 permanently ungeneratable after a plaza arrival. New checks
`depthgate.js` and `chunkload.js`.

**Veins, rebuilt.** `VEIN_ORDER` gave every size exactly one silhouette (a four
was always a flat 2×2 slab; 6 and 8 never occurred). Shapes are grown per cell
now, seeded per ore. Size comes from cost/drop/rarity plus a per-ore spread
instead of three tier-index bands. Density and per-ore shares are conserved
throughout — `veinWeights` divides by the mean — and `veins.js` measures both
sides. Two of my own errors are recorded: pricing cost with `toolCraftCost`
double-counted yield, and an unsliced constant with an `or` fallback made the
harness measure defaults silently.

**`oreWeights` cached per section while computing `dl` per layer**, so the first
layer asked set the mix for 49 layers and two servers disagreed at the same
depth. Now keyed on quantised `dl`.

**`ToolModels_50`** was 58% of every client's datamodel; 2,060 unreferenced models
(70,040 instances) moved to `ServerStorage.ToolModels_50_Unreferenced`. Client
`InstanceCount` 137,444 → 67,537, shop resolution unchanged.

Marked probable bugs 3, 5 and 15 **fixed** with their measured before/after. Added
§1b with four new entries, the first being that **nothing multiplies ore
quantity** although the owner expects endgame enchants to.

Updated: ores, zones-layers-and-seams, tools, verify-suite, open-questions, log.
Not rechecked: bugs 4, 6–14, 16, and every rule/code disagreement in §2.

## [2026-10-08] ingest | the candy UI pass, the quest panel, MineCelebrate, audio

The owner asked for a UI that appeals to kids. Their choices were a chunky
candy-game look, juicy motion, bigger text, and a reach of everything. They
added rarity-scaled "dopamine heavy" reveals that stay easy to navigate, and
SFX and music to match. Mid-pass they gave three more instructions:

- Remove the gloss "bubble".
- Make the quest cards and the slide-out arrow one panel.
- *"slot machine wins are fine, maybe even encouraged ... i just dont want alarms"*.

Filed in [client-and-ui](code/client-and-ui.md):

- The candy kit tokens and helpers.
- The single `QuestPanel`, which replaces the two cards and their ear tabs.
- `MineCelebrate`, with its tier table and its honesty rule. Card packs and
  lucky blocks are reachable with Robux credits, so the celebration size comes
  only from the real result, with no near-misses and no fanfare on a dud.

Also fixed the page's stale HUD-scaling section, which said `short/820`. The
code says `short/1080`, 0.80–1.25, plus the panel-fit guard. Sound slots and
the ElevenLabs prompts went to `docs/AUDIO.md`. The `MineAudio` header's "no
casino-style escalation" came from an earlier agent, not the owner, and has
been replaced with the owner's rule.

Found while verifying: `4d7b8e7` deleted the `]]` that closed the doc comment
above `MineConfig.ORE_HP_MULT`. That commented out `ORE_HP_MULT`, `_MIN` and
`_MAX`, so every ore block threw in `oreHardness` and no ore spawned. The `]]`
is restored (committed as `bc2133b`). `orehp.js` did not catch it, because it
fell back to literal defaults when a constant was missing. `7b06a55` now strips
comments before asserting that a constant exists.

Updated: client-and-ui, log.

## [2026-10-08] ingest | the reveal fixes ("fix all")

The owner said "fix all/continue" to the list from the candy pass. Fixed:

- The dead trait ROLL button, plus a new `traitRolled` result and the trait
  tab's missing repaint. See [traits](systems/traits.md).
- Temper-case batches now reveal their best roll.
- Ore-case skins in open-all are now counted by grade. See
  [skins-cases-and-temper](systems/skins-cases-and-temper.md).
- Lucky-block pets and potions now appear on the loot card, and the lucky
  screen moves to layer 120. See
  [chests-and-lucky-blocks](systems/chests-and-lucky-blocks.md).

Updated: traits, skins-cases-and-temper, chests-and-lucky-blocks, client-and-ui, log.

## [2026-10-08] ingest | lucky-block odds, and three crashes luau-analyze found

Lucky blocks are sold for Robux-bought credits and showed no odds. Now:

- The odds are computed exactly from the real climb and loot tables.
- They are shown in three places: the shop row, the bag's ⓘ and the lucky
  screen.
- They are guarded by the new check `lucky-odds`.

The loot rows moved into data unchanged: 16,000 seeded rolls matched the old
inline code exactly.

Running luau-analyze over the touched files found reads of undefined globals:

- `iconArt`: the shop's whole Limited tab stopped after its first offer.
- `spendsTokens`: the Enchanter's Summon tab threw on every repaint.
- `CARD_HI` and `DEAD`: a selected tile showed the wrong colour.
- `opts`: `caseSpin` read a global. Harmless, now a parameter.

`joint` in MineClient is still an unknown global, but it sits in dead code
(the comment above it says there is no Motor6D), so it was left alone.

Updated: chests-and-lucky-blocks, verify-suite, log.

## [2026-10-10] decision | the red lucky block is "Godly Lucky Block"

The owner answered "Godly everywhere". The block had three names: id
`godly_lucky_block`, the name "Mythic Lucky Block", and the shop label "Goldy
Lucky Block". All of them say Godly now, including the rotating-offer texts.
"Mythic" stays a pet and card rarity only, so a "Mythic" block is no longer
confused with a Mythic pull.

Updated: chests-and-lucky-blocks, log.

## [2026-10-10] ingest | toast-only luck gets a celebration

Temperament rolls and rune fuses were the last random outcomes that only
showed a toast. They now send `luckResult`, and `MineCelebrate` sizes the
celebration from the real result. A failed fuse gets a thud, never a fanfare.
Hat merging is deterministic, so it was left alone. A temperament roll was
played in Studio, and the right sound and overlay fired for F, D and C. Trait
rolls are still not played in Studio: the test account has no forged ore tool
to roll on.

Updated: client-and-ui, log.

## [2026-10-10] ingest | the launch-audit week: verbs, economy, ore health, tool shapes
Two audit sweeps (currency faucet/sink census, launch readiness) plus the fixes
they drove. Updated [tools], [ores], [currencies-and-economy] and seeded a
LAUNCH BOARD at the top of [open-questions] — four blockers only the owner can
clear, five decisions, four accepted-for-launch items and four 30-minute
suggestions. Headlines: five server verbs were complete and called by nothing
(three of them advertised by UI strings); `MineSocialView` is 387 lines mounted
nowhere; coins had two live sinks against twelve faucets; every ore had the same
health; every tool in a family was one silhouette in 82 colours. All fixed
except the owner decisions. New harnesses: `orphan-verbs.js`, `orehp.js`,
`megascale.js`, `recycle-quote.js`, `gem-spread.js`.
