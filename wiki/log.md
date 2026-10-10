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

## [2026-10-10] ingest | model audit: 197 of 322 pets were duplicates
Audited every model the game builds, chasing the owner's report of "parts that
are not even attached". None exist — worst real gap on any tool is −0.024 studs
(overlapping), and every floating pet part is deliberate FX, proven by building
each body with and without its skin. The audit found something worse instead:
fingerprinting all 322 pets by part size, position and colour put **197 in 48
byte-identical groups**. Three causes, now separated in [pets]: 69 Event
Horizon animals had no `ANIMALS` row and all rendered as the default fox (the
`resolveSpecies` → `"fox"` fallback is silent); 64 animals shared a tint with a
sibling, so 11 dog breeds were one brown and Alien/Fairy/Gremlin were one
lavender; and 12 groups are two roster rows pointing at one `animal`, which is
correct factory behaviour and now an owner question. Fixed the first two and
verified at the model level — 300 skins built, 0 identical. New harness:
`petskins.js`. Also: `/admin oretools all` had silently skipped hammers since
they shipped.

## [2026-10-10] ingest | roster duplicates, chest audit, workspace strays
Finished the model sweep. **All 322 pets now render as distinct models** (was
197 duplicates): reassigned 22 pets off shared animals and added 22 new skins.
The geometry-based count was wrong — it found 12 duplicate-animal groups where
there were 19, because it filed each identical group under a single cause and
hid Boomer/Brisket inside a 12-hound tint collision. `petskins.js` now asserts
animal uniqueness on the roster directly, plus skin coverage, plus the
`(species,tint)` rule. Chests audited in engine: sound geometry (23 pieces,
worst gap −0.040) but **all five kinds are one shape in five palettes**, which
is the very thing [chests-and-lucky-blocks] says the module existed to fix —
now an open question with a concrete cheap fix. Also removed 3,020 parts of
authoring racks from the place file, including `ToolKit_DemoHandle`, an opaque
MeshPart floating 40 studs over spawn that **shipped to players** because
MineServer's strip list only matches named folders and `_` prefixes. It now
warns about anything unexpected at the workspace root instead of silently
missing it.

## [2026-10-10] ingest | the owner's roadmap, and the candy style written down

The owner set a new priority order and asked for it to sit at the top of the
TODO, with instructions any agent can follow cold. Done:

- **`docs/TODO.md` ★ NOW** holds how to work the list, the owner's ask, the
  decisions and the specs. The phases run in order: A (daily loop, in
  progress), B (tools), C (art), D (planets).
- **[candy-style](code/candy-style.md)** is the single brief for the UI house
  style: rules, the kit, honest wins, sound and a checklist.
- **[owner](owner.md)** gains the 2026-10-10 decisions, and the "icons are the
  owner's job" rule is marked lifted for the art pass.

Updated: candy-style (new), owner, index, log.

## [2026-10-10] ingest | pet bodies: the moth and the twelve cube species
Colour made the 322 pets distinct; shape did not. Every species on `block()`
was one ovoid with the face painted on its front, so the outline was a cube
with nubs. Added `shape = "quad"` (brow, chest, cheeks, haunches, back) to the
twelve four-legged species, and rebuilt the moth's wings as a raised V — the
old ones rotated about Z only, so they stuck out sideways and vanished
edge-on. Two approaches are recorded in [pets] as rejected: a real head volume
strands every hardcoded face detail on the chest, and adding mass without
shrinking the core changes nothing because it never reaches the outline. The
shrink stranded a cookie dog's chip on the old body top, which is why there is
a `back` mass. Also fixed `ridge()`: every caller spaced its plates wider than
they were deep, and the gap only shows on the last plate. 322 built, 0
duplicates, floaters 10 → 9 with the nine remaining all deliberate FX.

## [2026-10-10] ingest | shaping profiles for the remaining 21 cube species
Generalised `shape` into three profiles in `SHAPES` (`quad`, `bird`, `round`)
and applied them to 21 more species, so 33 of 44 now have real body mass. The
`round` profile shipped a bug the gap audit caught immediately: it had no rear
mass, so six fish and dolphin tails hung off the shrunken core, the same way a
cookie dog's chip did when `quad` had no back. A profile has to reach every
face of the envelope, because details are placed on the envelope. `ghost` is
left out on purpose -- it sets `body.Transparency` and opaque masses would
break it. Final: 322 built, 0 duplicates, 9 models with floaters and all nine
are deliberate FX.

## [2026-10-10] ingest | the daily wheel ships (TODO NOW A1)
The parked group wheel was rebuilt as the **daily wheel** and built in the
lobby again (`299dd2c`). Rules:
- 1 free spin per UTC day for everyone;
- +1 for group members;
- +1 on a claimed 7-day streak day;
- banked Robux spins after the free ones, gated by `PolicyNoRandom`.

Odds are printed on every slice. A gold Wheel dock button carries a badge
counting the free spins left.

Two bugs were found on the way:
- A paid-spin receipt still called the removed `Wheel.payload`. It would have
  crashed after a purchase.
- The world wheel's `AmbSpin` idle spin recorded its pose before
  StreamingEnabled had delivered all 82 parts, so it turned the wheel edge-on and
  the face read blank. It now spins on each client, from `MineGroupWheelView`,
  and only once `PartCount` parts are present.

In the panel, the odds sat where neighbouring slice cards overlap, so they now
sit in a pill in the outer half of each card. Verified in Studio: a free spin
landed on the rolled slice, the pack was granted, the badge counted down, and
the used spin survived a restart. The allowances and weights are PROPOSED and
await the owner. New check: `daily-wheel`. Suite: 54/54.

Updated: social-quests-and-leaderboards, open-questions (#6 answered),
retired-and-parked, code-map, save-data-and-migrations, verify-suite, log.

## [2026-10-10] ingest | pets first: the owner's 19 sets and zone pots
The owner reset the priority: pets come first, and rewards wait until every pet
is in place. Their spec went into `docs/PETS-AND-SETS.md`:
- 19 exclusive sets, graded F–SSS, each with six star-graded packs. The owner
  named every set and pack;
- card counts per rarity;
- zone pots for the existing pets;
- 20–30 new body types.

Checked:
- **Every row adds up.** That is 2,043 cards, 450 of them Epic or better.
- **"Heartwood" is a duplicate pack name.**
- **A card is a pet**, so the job is far bigger than the 322 named pets today.

The owner flagged the X/Y sets and the variant odds rolled at pack open as old.
They are now marked legacy. One near-miss: MineCards' `Prism = 4` is a rank
(`VARIANT_RANK`), not a second multiplier, so it was not listed as a conflict.
A help-needed table (H1–H8) went into open-questions.

Updated: owner, open-questions, sources-of-truth, log. Also docs/TODO.md ★ NOW
(LATEST banner, A1b, A2 placement).

## [2026-10-10] query | how many pets exist, and is the set system live?
The owner's answers:
- every pet is named by hand, all 2,043 set cards included;
- about 100 new body types;
- +5% per zone, not 12%, and each set's pet budget is 5% above the set before it;
- Worldtree's ★★ "Heartwood" becomes "Sapwood";
- universal packs go, though nothing is deleted yet.

The count:
- **322 hand-named pets.**
- **41 old generated sets** hold **4,023 card slots but only 207 distinct
  pets.** Names are 16 prefixes × 16 animals, so the same names recur in every
  zone and no zone owns a pet.
- **The set system is live.** Chest packs take the zone's set by depth. Every
  other pack takes a random set from all 41: shop, bundles, stardust, daily
  rewards, quests and the wheel. That random draw is the owner's "universal
  packs".
- **9 sets (837 slots) are reachable only at random.**
- **Splitting the named pets** gives about 25 per zone.

New owner question: H9, the zone pot size.

Updated: cards-and-packs (set-system status), open-questions (H1–H3 answered,
H9), owner, log. Also docs/PETS-AND-SETS.md and docs/TODO.md.

## [2026-10-10] ingest | set 17 renamed Eternal Roots
The owner renamed set 17 from Worldtree to **Eternal Roots**, because the old
name read as both a set and a pack. Its ★★ pack stays "Sapwood", which fixed
the duplicate Heartwood, and its ★★★★ pack keeps "Worldtree's Crown" for now.
Updated: docs/PETS-AND-SETS.md, open-questions, log.

## [2026-10-10] query | do pets that share a body have different colours?
**Named pets do.** All 322 have a unique (body, colour) pair, which
`petskins.js` guards, and many add a glow or props.

**Pack-generated cards do not, in the way the owner expected.** Their colour
comes from the card's element (`TYPE_TINT`), never from the name prefix. Two
"Ember Fox" cards can differ, while an Ember Fox and a Storm Fox of the same
element are identical. There are at most 128 generated looks (16 bodies × 8
elements), before rarity effects and variants.

Updated: pets, log.

## [2026-10-10] ingest | zone pots: 70 pets per zone, and the pet display rebuilt
Each of the 10 regular zones now has a 70-pet pot, built by
`tools/gen/zone-pets.js` into `MineZonePets`:
- 249 existing pets dealt by tier;
- 451 new ones on everyday bodies.

**Kits** follow the approved PROPOSAL ladder, ×1.05 per zone.
- Common to Legendary get a role from their body.
- Mythic, Divine and Exotic carry their zone's own buff set.

**Wiring.** The roster, the kit lookup and the model factory each read the
module through a small hook. Zone kits (`PET_BOOSTS.Z`) outrank the old X and Y.

**Verified in Studio:** 773 pets build, with no failures and no fox fallbacks;
70 per zone; every zone pet resolves to its zone kit.

**Not wired:** nothing drops from a pot yet. That is the rewards pass.

**The display.** The old `PetShowcase` was deleted in `d57fedc` along with the
other authoring racks, so `PetShowcaseBuilder` rebuilds it from code. Name tags
show within 22 studs, and the zone banners are physical boards.

Two snags along the way:
- **Billboards flood across distance.** Eleven zone signs at MaxDistance 700
  read as one smear.
- **Text caps at 100 px.** A SurfaceGui at 30 px per stud left the title too
  small to see.

Updated: pets, log.

## [2026-10-10] lint | pet and card legacy removed; Event Horizon on the ladder
Owner: *"remove all old information, because as long as we keep it there its
gonna keep tripping up agents"*.

**Code.** Everything below was dead, or contradicted the live data, and was
removed:
- `MinePetBoosts`: the X and Y kit bags, plus a second Event Horizon copy that
  disagreed with the live one on 69 of 73 pets. 528 lines became 86.
- `MineEHPets`: its stale kits, its budget, and an injector into the dead X/Y bags.
- `MinePackConfig`: the X/Y card lists and their indexes, set split and bias,
  the old pet budgets, and the unused `openChest` / `rollVariant`. 865 lines in all.
- **41 per-pack variant rows** (Golden / Prism / Rainbow / Void). Every one
  totalled 100 and `variantOdds` already ignored their mix, so no odds moved.
  Checked in Studio: Golden 1%, Void 2% on the void pack, the same as before.
- `MineStats`: the X/Y kit generator (`TYPE_KITS`, `TIER_BUDGET`, `kitFor`,
  `audit`).
- Two "GENERATED" headers pointed at generators that were never in the repo.

**A live bug found on the way.** `MineZoneMapView`'s pet tooltip read the old X
bag directly, so it showed the wrong numbers. It now uses `boostsFor`.

**Pet budget.** Event Horizon was the one roster left off the ladder: its
Exotic was worth about 1,670 points, against about 370 for a top zone Exotic.
It is now zone 11 (×1.63). Each pet keeps its authored stat mix; dead stats are
dropped and the rest rescaled.

**Guard.** `tools/verify/zone-pets.js` now fails if any removed table returns.

**Verified:** suite 55/55. In Studio, the server boots clean, every pet resolves
its kit, and three real packs opened.

**Docs** updated to match: pets, cards-and-packs, boosts-and-stats,
retired-and-parked, `docs/OPEN.md`, and `docs/PROPOSAL.md` (lines 3, 5, 6 and 8
built for every named pet; line 4, the variant stack, is not; line 30
superseded).
