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

## [2026-10-08] ingest | main after PR #6 merged (9 commits since b19c4c2)
Asked "are we good to go?", I found PR #6 merged into `main` on 2026-10-06
(`ea255bb`) and its branch nine commits past the last ingest, so PR #7 pointed at
a stale base and the wiki described old code. Merged `main` into this branch (no
conflicts) and read all nine commit messages. The owner's session had **fixed
three more of the wiki's findings**: depth desks (bug 5) and the recycle loop
(bug 3) in `4cc82a5`, and the 200-local ceiling (bug 15) with a new `compile.js`
check in `5d59714`. I read the new code to confirm each and ran `compile.js`
(5 and 7 registers left). Other ingests: 246 per-ore tool skins, forge frame
stats baked so the coin tool roster can be deleted, UI rescale, vein cost and
random-mine fix, first layers mostly stone, pet bob rate, shadows (a Studio-only
change), the Rojo stale-sync gotcha, and a correction that the 2026-10-05 upload
"ownership" problem was moderation latency. Suite: **40 passed, 0 failed, 0 did not
run** (was 36; new checks `compile`, `economy-exploits`, `oreframes`, `ui-scale`).
Owner's newest decisions are in [owner](owner.md). Still open: bugs 4 and 6-13 and
16 in [open-questions](open-questions.md). Retargeted PR #7 to `main`.

## [2026-10-08] refactor | ask first, always: a stronger rule for ALL agents
The owner said: *"from now on i want ALL agents to fucking hound me with questions
so noithing is EVER unclear"*. That replaces the softer 2026-10-05 rule. Rewrote
"Ask first, always" in `CLAUDE.md` (no cap on questions, restate before starting,
ask the moment a new doubt appears, list assumptions at the end, and what to do when
nobody can answer) and added it to `AGENTS.md`, `tools/agent/house-rules.txt`, the
pasted prompts in `docs/START-HERE.md` and `docs/FABLE-PROMPT.md`,
`roadmap/AGENT_PROMPT.md`, `roadmap/PROMPTS.md`, `docs/HANDOFF.md`, TODO §0.35 and
§9, and the Claude.ai text. Replaced the `FABLE-PROMPT` line that said to ask only
"one sharp question rather than guessing or stopping". Added a `SubagentStart` hook
beside the prompt hook, and `tools/verify/askfirst.js` (proved to fail on a broken
copy). Subagent coverage was tested rather than assumed: the JSON hook reached a
general-purpose subagent, and did not reach the built-in `Explore` type (see
[local-setup](code/local-setup.md)). Four design points were applied on my defaults
and put to the owner as questions: the cap, locked rules, unattended runs, and
restating before work.

## [2026-10-08] query | owner confirms the four ask-first design points
Asked the owner four open design points about the ask-first rule (question cap,
locked rules, unattended runs, restating first). Every answer was the recommended
default, which was already live, so no rule changed. Recorded in [owner](owner.md)
and TODO §0.35. Found while checking the branches: the owner's working branch
`claude/vigilant-fermi-aucqjy` holds an older merge of this wiki (`c04adad`) plus its
own ingest (`c9b93c6`), and does not have the ask-first rule or hooks. Reconciling
the two lines is an open question for the owner (5 wiki files would conflict).

## [2026-10-08] refactor | the wiki now follows the owner's working branch
The owner chose (asked twice) that the wiki follows `claude/vigilant-fermi-aucqjy`,
that the ask-first rule reaches their branch through a PR their other session merges
(never a push from here), and that conflicts resolve as "merge both; theirs wins on
code facts". Merged that branch (`bae3c5b`) into this one (`06b5f89`). Five pages
conflicted: `ores` (their rebuilt Veins block won; my K 0.228/0.353/0.434 figures were
stale because `ORE_K_TOP` is now 0.040 after `41d8f3a`, so I replaced them), `open-questions`
(kept my rows 3, 5 and 15 for the commit hashes and measurements, added their "caught the
same break twice more"), `verify-suite`, `zones-layers-and-seams` and this log. After the
merge: `wiki.js`, `askfirst.js` and `syntax.sh` clean, and the suite is **45 passed, 0
failed, 0 did not run**, with `compile.js` at 5 and 7 registers left (215 files).

## [2026-10-08] ingest | the owner's session: 36 charms, traders, season hold (`b09cc4a`..`bae3c5b`)
Eight commits the other session's own ingest (`c9b93c6`) predates. Read the code, not only
the messages. New pages: [wandering-traders](systems/wandering-traders.md) and
[season-and-launch](systems/season-and-launch.md). Updated: charms (the 36 graded charms,
their two ways in, prices), chests-and-lucky-blocks (the 0.5% drop), shops-and-monetisation,
skins-cases-and-temper (new temper-token sinks), world-events (the season-end gotcha was
stale: offers now end 11-08), tools, glossary, ambiguous-terms (`launch`, `trader`,
`charm`, `tokens`), index, overview, owner, sources-of-truth, server, client-and-ui,
code-map, tools-and-generators, verify-suite (`launch`, `trader`; 45 checks, 22 run the luau
binary) and open-questions.

**Four findings from reading the code, none fixed** ([open-questions](open-questions.md)
§1b, #21–#24): nothing in `src/` sends `buyCharm`, so the token half of the graded charms
has no shop; nothing sends `launchSeason`, so the owner has no launch button; the battle
pass ends 2026-11-01 while the offers end 11-08; and Chest Luck raises the chest charm drop
though a code comment says it does not. Also reframed bug 4 (Event Horizon) as the owner
did in TODO §6.1: a missing progression, not a breaking-power bug. Not rechecked: the
`ToolModels` archive move and anything not in the eight commits.

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

## [2026-10-10] ingest | Tidal Wave, and every proc gets an animation and a sound
Owner: *"a water theme aoe would be great"*, then *"we also need a little sfx …
on top of an animation (while your at it a blast and zap and whatever else we
got needs an anamation too)"*.

**Tidal Wave** (`tidalWave`) is Blast's flat cousin. A break hits the 12 cells
of `Dig.TIDE_RING` on the same layer for `PROC_SHARE.tide` 0.18 each: 2.16
swings, against Blast's 2.10. MineStats weight is 4.0, the same as Blast.
- It is additive like the other chances: `ADDITIVE_STATS`, `emptyBoosts`, the
  relic fold and boost sources.
- It is on 15 pets: Mistreef's top pets (buff set Tide) and Rare+ Tidecallers.
- Verified in Studio with three Tidal Wave pets: 4 breaks gave 4 waves, and all
  45 diamond cells were hit.

**`MineProcFx`** (new, client) gives Blast, Tidal Wave, Zap, Ricochet and
Earthquake an animation and a library sound each. Two lessons:
- **Effects sit on a block's top face.** The server reports centres, and the
  first build hid every zap arc inside the rock.
- **A proc hit is a share of a swing,** so a starter pick lands 1 damage. The
  animation is what tells a player it fired; the damage formula is a separate
  question for the owner.

`devGrant { pet = … }` (Studio only) was added so pet abilities can be tested
in the engine.

Updated: mining-and-breaking, boosts-and-stats, pets, glossary, log.

## [2026-10-10] ingest | holiday pets out of the game; handoff page for the queued work
The owner: *"make sure NO holiday ones are in the game.. only allow it from
{Holiday} {year} Pack"*.

**Six pets are now listed in `MineZonePets.HOLIDAY`:**
- three on Halloween bodies: Spindle, Spooky, Wisp;
- three with Christmas themes on ordinary bodies: Jolly, Tinsel, Tinseltoe.

They left the zone pots, so 6 more new pets keep every zone at 70 (457 new in
all). The random pet roll that the wheel and lucky blocks use now skips them.
They keep a zone-1 kit, so owned copies still pay.

**Verified:**
- 16,000 random rolls in Studio gave no holiday pet;
- the display shows 10 × 70, Event Horizon's 73 and a Holiday block of 6.

**Display fix.** The builder now stands a fresh copy of the zone data in under
its real name while it loads. Studio's command-bar cache otherwise left six
zones showing 69.

**Handoff.** The owner's answers on pet power (300/489), the proc rework and the
Halloween bodies went into [next-up](next-up.md) with a paste-in prompt. They
asked for it so they can restart the work from it.

Updated: next-up (new), index, owner, pets, log, `docs/TODO.md`.

## [2026-10-10] ingest | pack art, set and rarity icons, stars and best-first sort
Pack covers for the 19 graded sets (57, three per set: 1-2, 2.5-3.5 and 4-5 star)
in `art/cover-art/`, rendered into 3D foil pack sprites (732x1024, set name on the
top seal, theme-colour seals only: the owner dropped silver and gold, "make it
apparent in UI that the packs are good") in `art/pack-sprites/`. Set medallions
(19, ring = grade) and rarity gems (8, `MineCards.RARITY_COLOR`) in `art/icons/`.
Renderer and icon tools: `tools/pack-sprites/` (`render.ps1`, `icons.ps1`).
`art/` is untracked and not yet uploaded as the group. Code: pack tiles show
stars and `Set · Grade`; the inventory sorts best first (stars, then set grade).
Zone packs stay unrated, per the owner. Updated
[cards-and-packs](systems/cards-and-packs.md).

## [2026-10-10] ingest | pet ladder lifted; the proc rework (next-up §1–2)
The owner's answers:
- Commons stay where they are, and everything else grows to Exotic ×4/3;
- one damage stat per proc;
- Shatter goes to the 6 sides;
- no caps: proc chances are priced high instead.

**The ladder** is approved × (4/3)^(rank/7). An Exotic kit is 300 at Meadow and
489 at Event Horizon.

**Procs:**
- Blast's share is 0.12, so it is now the smallest proc.
- Tidal Wave keeps 0.18 and gains its own damage stat.
- Zap's stat only starts a chain; hops continue with `ZAP_CONTINUE 0.80 ×
  ZAP_FALLOFF 0.88^(h−1)`. Studio measured 3.11 hops against 3.05 expected.
- Ricochet is now **Shatter**. It hits the 6 sides and chains on breaks, up to 3
  per block broken; Studio showed chains of 2 and 3, and never more. The key
  stays `ricochet` because it is data.
- Each proc gained a damage stat that adds to procPower.
- Chance weights: Blast 9, Zap 8, Shatter 9, Earthquake 9, Tidal Wave 10.
  Mistreef's tide trio totals 50.4%, and no pet tops 40%.

**Hats:**
- the four proc sets carry chance + damage;
- the proc lines are priced by weight when read, which repriced owned hats too
  (an SSS Storm hat's Zap went from about 259% to 34%);
- Tide's dead Backpack and Prism's Rare Ore lines now follow their set.

**Effects:** Shatter's animation (crystal shards) and its glass sound replace
Ricochet's.

**Checks:** `procs.js` and `zone-pets.js` lock all of this in. The Studio pet
grant now trims to the seat cap.

Updated: mining-and-breaking, hats-and-faces, pets, boosts-and-stats, traits,
rebirth-and-skill-tree, glossary, next-up, log.

## [2026-10-10] ingest | ten Halloween bodies (next-up §3)
Added Bat, Mummy, Zombie, Vampire, Cauldron, Candy Corn, Scarecrow, Haunted
Lantern, Frankenstein and Eyeball as `PetModelFactory` species, tagged
`season = "Halloween"`. `PetModelFactory.HALLOWEEN` lists all 15 Halloween
bodies, and the display draws them as a block. All built cleanly in Studio.

**One lesson.** `FIT_SIZE` fits a model's largest dimension, so the first Bat
(4.6-stud wingspan) and Lantern (tall handle) came out tiny. Narrower wings, a
lower handle and a `scale` fixed both.

**Holiday bodies are now read from the season tags.** The generator and the
check no longer use a typed-in list. That surfaced Penguin's Christmas tag,
which would have pulled 22 ordinary pets out of the game; the tag was removed.

The display now shows 794: 10 × 70, Event Horizon's 73, 6 holiday pets and 15
Halloween bodies.

Updated: pets, next-up, log.

## [2026-10-10] ingest | pack art uploaded (personal account, shared)
The owner allowed personal uploads plus sharing. 84 images (57 pack sprites,
19 set icons, 8 rarity icons) uploaded as iPressBars via Studio MCP; ids in
`build/pack-art/ids.json`. One proven to draw in the group place after sharing;
the other 83 await the owner's share (`build/pack-art/share-list.txt`). Found
that Studio caches a failed asset load for the session. Updated
[assets-and-uploads](code/assets-and-uploads.md).

## [2026-10-10] ingest | packs pay named pets (set packs, zone pots)
Owner: old generated cards *"stop dropping"*; set packs draw only their set.
`openPack` now mints a named pet at the rolled rarity: a set pack from its set
(`MinePetRoster.BY_SET`), every other card pack from a zone pot
(`BY_ZONE`; the pack's zone, else its old set's zone, else the player's
deepest zone). The starter pet is a meadow Common. Set packs
(`MineSetPacks`, `<setkey>_pack_1..6`) are registered in
`MinePackConfig.PACK_BY_ID`, not `PACKS`. Verified in a Studio play test with a
new Studio-only `devGrant { packIds = {...} }`. Found: lucky-block and
group-wheel pets use their own `cardKey`, so they do not merge with pack copies.

Updated: cards-and-packs, pets, next-up, log.

## [2026-10-10] ingest | set packs wear the uploaded sprites
`MinePackArt` (generated from `build/pack-art/ids.json`) maps every set pack id
to its set's sprite by star band; `MinePackFX.art` reads it. Verified in Studio:
114/114 set pack ids resolve and all 57 sprites load. Split with the session
that owns the set packs: it owns sets, pets and `openPack`; this one owns pack
art, cases, chest case drops, the credit shop, the stardust tab and the wheel.
Updated [assets-and-uploads](code/assets-and-uploads.md).

## [2026-10-10] ingest | the 19 sets: 2,043 named pets, 98 bodies; Halloween handoff
Five agents wrote each set's bodies (`PetBodies/`) and names, palette and buffs
(`tools/gen/sets/<key>.json`); `tools/gen/set-pets.js` generated `SetPets/` and
`docs/SET-PETS.md`. Owner's theme rule (*"DEFINATLY be the prodionent type"*):
own bodies dress 71–85% of each set, checked by `tools/verify/set-pets.js`.
Found and fixed: the zone generator read set names, which shifted its
shuffled name pool and would have renamed committed zone pets; it no longer
reads the sets. Display: 2,837 pets build in Studio. The owner's Halloween 2026
answers (window, second event mine, 60 pets, "divided by 10000") are recorded
in owner and PETS-AND-SETS, and handed off in next-up with a prompt.

Updated: pets, tools-and-generators, owner, next-up, log.

## [2026-10-10] ingest | pack cases: wild and set cases, chests, wheel, both shops
Owner: two kinds of case. Set cases have exact contents and are sold for
stardust: Starter, Collector and Vault, three per set. Wild cases are a
complete random draw. Cases replace the wheel's pack slices. The credit shop
sells "Cases by star + a few featured set packs", and its old packs came off.
Prices come from expected value.

New `MineCases` holds both kinds, opening, chest drops, the shelves and the
PROPOSED prices:
- stardust = expected value / 0.65, times 1.05 per set;
- credits come from a curve fitted to the old credit shelf.

Where cases now appear:
- Cases are registered in `MinePackConfig.PACK_BY_ID`.
- MineServer hands a case to `MineCases.open` before `openPack`.
- Chests roll a case by rank.
- The wheel's apex, heirloom, anomaly and jackpot slices pay wild cases.
- The stardust shop gained a Pack Cases tab.

Played in Studio: bought, opened (single and run), tiles, inspector, both shelves.

Filed: [pack-cases](systems/pack-cases.md), with the full pricing table and
what is still to approve. Updated: shops-and-monetisation,
social-quests-and-leaderboards, chests-and-lucky-blocks, cards-and-packs,
assets-and-uploads, index.

## [2026-10-10] query | pack cases: the owner's pricing and shop rules
The owner answered three questions:
- **"Better does still cost more [10% more than last]".** `SET_VALUE_STEP` is
  now 1.10.
- **"Make it so shops dont carry any sets above b".** Set cases and featured
  set packs only come from the 9 sets graded F to B. The A to SS sets come out
  of wild cases only.
- **Chaos Theory (SSS) is "credits, and 0.5% only".** Only a wild case bought
  with credits can roll it, at exactly 0.5% of its slots. Its bag row carries
  `paid`.

Also decided: the case art is a booster box, and wild cases stay in both shops.

Checked in Studio: the cart stamps `paid`, and a set case above B is refused
for stardust. Over 200k rolls, SSS came from 0.53% of credit-case slots and
none of the others.

Updated: pack-cases (rules and repriced tables), owner,
shops-and-monetisation, TODO A1c.

## [2026-10-10] ingest | Candy Crypt: a second limited mine (partly built)
Owner asked for a Halloween candy mine. Built the foundation and wrote it up in
[world-events]: the zone (`hallow`, index 12), a per-zone window, a per-zone
claim flag, a 3x3 pit, no chests, the candy balance and candy strata. Three
things assumed exactly ONE limited zone and had to be made per-zone first —
`limitedActive()` took no argument, the claim read `p.bigbangOwned` for any
limited zone, and `rollKind` named bigbang for chest density. Windows are day
offsets from SEASON START rather than real dates, because the clock is
MineLaunch's season clock and a wall-clock window is the failure MineLaunch
exists to prevent; 25/21 gives the owner's 17 Oct – 7 Nov and slips with launch.
Also found a trap worth knowing: MineConfig has TWO section builders.
**(Corrected 2026-10-10, see the entry below — this line first said the first
builder was dead and the second was live, which is backwards.)** Not built yet: candy ores,
10-layer sections and the 3x curve, sell values, the cases, and the Halloween
tools. `zone.noStrengthGate` is set but nothing reads it — the hardness gate is
block HP, not a flag.

## [2026-10-10] query | set pets: every proc fits its set
Owner asked whether every pet has buffs "that make sense". 9–31% of each set's
pets below Mythic carried another theme's proc from their body's role (every
Mystic zapped). Owner chose "use the set's own proc": those become the set's
proc, and sets with no proc get plain buff stats. Power unchanged. Also checked
in Studio: all 2,043 set pets have a real body, a unique name and a kit, and set
packs open into their set's pets (pebblebound_pack_1, atlantis_rising_pack_4,
chaos_theory_pack_6, dragonfall_pack_6).

Updated: pets, log.

## [2026-10-10] ingest | candy ores; correcting which section builder is live
Twelve candy ores in their own `MineConfig.CANDY_ORES`, NOT in `ORES`: that is
one global 82-rung ladder weighted only by each rung's `d` against zone
difficulty, with no per-zone filter, so a candy rung would appear in every mine
and shift the share of every ore around it. ORES verified still 82 rungs. Candy
also bypasses the ore pouch — it is a currency, banked at spawn and paid on
break. The mix walks with depth (L1 70% Candy Corn, L130 77% Jawbreaker) and is
chosen from the cell position so a block is the same candy everywhere.

**Correction to the entry above:** MineConfig's FIRST section builder is the
live one — it runs at module load. The second is inside
`MineConfig.refreshZoneSections()`, behind a guard that returns early unless
MineDepth's section count changed, so it normally never runs. I had it
backwards, put the Candy Crypt's strata only in the second, and
`ZONE_SECTIONS["hallow"]` stayed nil while the file looked correct. Caught only
because a Studio probe printed NIL beside meadow's 138. **A new zone must be in
both**, and they are easy to confuse: different table shapes (`word`+`hue` vs
`THEME_WORD`/`THEME_HUE`), identical contents. Now 138 sections reading
Sugarloam, Gumsod, Toffeeclay.

## [2026-10-10] ingest | Candy Crypt: sell curve and the candy tools
The Crypt now has its own HP curve instead of a place on the zone ladder —
index 12 put its surface rock past Primordium at 41,992,188 HP, the opposite of
"no hardness requirement". One curve is both the difficulty and the sell value,
since coins are one per point of HP: base 1, ×3 per 10-layer section, so L1
pays 1 and L100 pays 19,683. Checked the zones it must not touch (meadow,
sunscar, primordium, bigbang) — all unchanged.

Twelve candy tools in `MineCandyTools`, four families, priced in candy, every
row carrying the owner's warning and `seasonalOnly`. Not `eventOnly`: that is
Event Horizon's matter lock, and the Crypt has no pool. The best candy tool
needs 9,481 hits per block on Primordium's surface.

**A probe lied and nearly got believed.** Cloning `MineCandyTools` in Edit mode
left its internal `require(MineConfig)` on the cached pre-edit copy, so every
tool read MEADOW's curve — powers of 6/11/16 instead of 2/182/14,762, three
near-identical tiers. The module was correct throughout. **Verify a module that
requires an edited module in PLAY, where the graph loads fresh**, not with a
clone in Edit.

Still unbuilt: the Trick-or-Treat case. A case holds packs and the Halloween
2026 Pack has no id yet.

## [2026-10-10] ingest | pack-case art: 20 booster boxes
The owner chose the booster-box look ("Booster box") and approved three
samples with "Yes, do all 20".

How the images were made:
- Canva `generate-image` drew one themed box per set and one rainbow
  mystery box for the wild cases.
- `remove-background` cut each one out.
- They were laid out on two pages of a working copy of the cover sheet and
  exported as transparent PNGs.
- `tools/pack-sprites/slice-cases.ps1` cut those into 732×1024
  `art/case-art/{Set}Case.png`.

Uploaded as the owner's account; the ids are in `build/pack-art/ids.json`
`cases`, and `MinePackArt` was regenerated. BLOCKED: the images do not load
in the group place until the owner shares them
(`build/case-art/share-list.txt`).

Updated: assets-and-uploads, pack-cases, TODO A1c.

## [2026-10-10] ingest | the Trick-or-Treat case, and three fields that do not exist
The case is built. I had called it blocked on the Halloween 2026 Pack, but that
was true of only one of its five outcomes — the other four draw on pools that
already exist, so the pack slot is conditional instead: `resolvedPack()` looks
it up at roll time and the weights drop the slot while it is missing, folding
its chance into hats. 200,000 rolls: candy 52.0%, hat 32.8%, skin 15.1%, bucket
1 in 1,015, with 19.5% of spend returning as candy.

**Three profile fields I invented compiled cleanly and would each have eaten
the prize**: `p.hats[id]` (a hat is a gear piece appended to the `p.gear`
array, rolled by `Gear.rollPiece`), `p.tempers` as a list (it is a map keyed by
`kit.id` holding `{rarity, n}`, and a duplicate keeps the better grade), and
`p.bagsOwned` (there is none — `backpackTier` is an index, and limited bags use
a dedicated flag like `p.wormholeBag`). Written up in [world-events] because
guessing any of them type-checks.

`orphan-verbs` earned its keep again: it failed with "UNEXPLAINED:
buyTrickOrTreat" until the button existed. `MineEventsView` only ever rendered
`EVENTS[1]` and read `bigbangOwned` directly, so with two limited mines the
Crypt would have had no screen at all; `currentEvent()` now prefers an event
whose own window is open, and owned/active are per event.

## [2026-10-10] lint | set body look pass; invisible cones; duplicate modules in Studio
Looked at all 98 set bodies in Studio, one set per screenshot. Found that
Roblox no longer draws the Pyramid and Prism SpecialMesh types, so
`PetModelFactory`'s `cone`/`prism` were invisible everywhere (51 set bodies,
16 older ones). Rebuilt them from CornerWedgeParts / WedgeParts; heaviest body
now 47 parts. Disco Ball got front tiles. Also found 13 duplicated modules in
ReplicatedStorage.Mine.Shared (newly added files, both copies synced); removed
the identical extras, and the display builder no longer renames instances.

Updated: luau-traps (§10, §11), pets, next-up, log.

## [2026-10-10] query | pack-case art shared and verified
The owner shared all 20 case images. `PreloadAsync` loaded 20/20 at 732×1024
in the group place, using leading-zero ids to get past Studio's cached
failures. In a play test the boxes drew on the bag tiles and on the case
opening screen ("TAP TO RIP"), and the packs inside revealed after it. The
console was clean.

Updated: assets-and-uploads, pack-cases, TODO A1c.

## [2026-10-10] query | wild cases at nine grades; no luck carry
The owner corrected and added two things:
- **"A luck boost per each star/grade"** meant that a higher grade has
  better drop rates by design, "Not a % boos[t]". A case no longer passes
  chest luck to its packs. The owner chose to keep chest luck raising the
  chance of a case dropping.
- **"I need 2.5, 3.5 and 4.5 stars per case".** There are now nine wild
  grades (`MineCases.WILD_GRADES`). The half grades are `case_3_4`,
  `case_4_5` and `case_5_6`. Each pack in one is a coin flip between the two
  neighbouring levels (owner: "Mix of both").
  - Prices fall between the neighbours: ★★½ is 38 credits, ★★★½ is 67 and
    ★★★★½ is 116.
  - Chests drop the half grades at half the geometric mean of their
    neighbours' weights.

Checked in Studio:
- 3.5★ packs split 7,292 / 7,326 between the two levels;
- an S chest drops all nine grades;
- opened packs carry no luck;
- the credit shelf shows the nine cases with the mystery box art.

Updated: pack-cases, TODO A1c.

## [2026-10-10] query | old packs off the stardust shelf
Owner: *"remove old packs from the stardust shelf too"*. The rotating
stardust shelf (`MinePackConfig.dustRotation`) now deals potions only. The
switch is `MinePackConfig.DUST_OLD_PACKS = false`. Packs for stardust are the
Pack Cases tab. Checked over 48 rotations (12 days): no pack offers and 4
potions each time. The shelf text now says potions.

Updated: shops-and-monetisation, pack-cases, TODO A1c.

## [2026-10-10] ingest | the Halloween 2026 Pack: 60 pets, costumes, the holiday rule
Owner chose the split (costumes C20/U15/R10, Halloween bodies E6/L4/M2/D2/X1) and
Event Horizon power. Built `tools/gen/holiday-pets.js`, `HolidayPets/`, eight
`cos_*` costumes, the `halloween_2026` pack (kind `holiday`) and its check. The
Candy Crypt's Trick-or-Treat case now pays it. Studio: the display builds 2,897
pets; the pack opened six times into Halloween pets; 3,200 wheel rolls, no
holiday pet. Found: passing the species to props broke `D.bands` (bees), whose
third argument was a colour; fixed. Flagged: the Crypt's window counts from
season start, but the owner told this session real dates.

Updated: pets, cards-and-packs, world-events, tools-and-generators, owner,
next-up, log.

## [2026-10-10] query | chest case rates decided: 10%, each grade half as common
Owner, on the old 0.5–10% by rank: *"WAY to high (look at the value
difference.. make each rarity 2x as rare as the last.. 10% base drop rate
for case)"*. They chose "10% get a case, grades halve" and "better chests,
better grades".

What changed (`MineCases.CHEST_CASE_CHANCE`, `CHEST_GRADE_FALLOFF`,
`CHEST_RANK_SHIFT`, `chestCaseOdds`):
- A C chest is ★ 5%, ★½ 2.5% … ★★★★★ 0.02%.
- Each rank above C starts the ladder a half-star higher; S starts at ★★½.
- F and D drop a case 2.5% and 5% of the time.
- Chest luck still multiplies the chance (cap ×3).
- The old chest-case tables in `MineSetPacks` are no longer read.

Checked over 200k simulated chests. Found while pricing: card power-up costs
25 × level (7,500 to max any card), and recycling pays +10% per level, which
makes stardust. The owner wants the Exotic max at 2–3M or more; that is next.

Updated: pack-cases, chests-and-lucky-blocks, TODO A1c.

## [2026-10-10] ingest | Halloween on real dates
Owner chose real dates for the Candy Crypt over the season clock. `MineConfig`:
a window with `opensUnix`/`closesUnix` reads the wall clock (`windowNow`);
`hallow` is 2026-10-17 00:00 to 2026-11-08 00:00 US Eastern. Event Horizon is
unchanged. Studio: closed today, "6d 5h" to opening.

Updated: world-events, next-up, log.

## [2026-10-10] query | pet power levels repriced; the recycle loop closed
Owner, on "maxing an Exotic costs 7,500": *"SHOULD COST A MINIMUM OF 2 OR 3
MILLION … (REMEMBER HOW MUCH DAMAGE THAT DOES)"*. They then chose:
- 30M to max an Exotic;
- other cards scaled by card value;
- each level 20% pricier than the last;
- recycling refunds half the spend.

`powerDustCost(level, card)` (gone: levelling was removed later that day) was `POWER_MAX_EXOTIC` ×
card value ÷ Exotic dust, along a ×1.2 curve:
- Common 5,625 to max;
- Legendary 1.5M;
- Divine 10.5M;
- Exotic 30M;
- Shadow Exotic 90M.

`salvageDust` is the card's value plus `POWER_REFUND` × `powerSpent`. A
level now records what was paid on the card. An old card counts the old flat
25 × level as its spend, so the 7,500 → 76,800 loop is gone.

Verified in a Studio play test; suite 57/57.

Updated: pets (new "Power levels" section), currencies-and-economy.

## [2026-10-10] query | pet levelling removed
The owner asked for clean numbers ("make it an even number"), then asked how
strong levelling makes pets. Shown the answer, they chose "Remove leveling":
- Level 25 was ×1.96 to a pet's own boosts.
- A maxed Shadow Exotic was about 26× a plain Common: Scanline's shatter
  damage went from +321% to +629% at level 25, and +1,887% as a Shadow.

What was removed:
- MineServer `powerUp` and its `power` action;
- the Scrapper's POWER-UP tab;
- the 30M price curve in `MineConfig`.

What stays:
- levels already on cards, which still count in `cardPower`;
- recycling's half-refund, now always of the old 25 × level spend, so the
  power-then-recycle faucet stays closed.

Also: the quest tip about powering up cards was rewritten. Checked in Studio:
the Scrapper shows CARDS / PACKS / RUNES / GEAR, and the console is clean.
Suite 57/57.

Updated: pets, currencies-and-economy.

## [2026-10-10] ingest | pets stack across sources; hats fuse three of a kind
Pets: one `cardKey` per named pet (`MinePetRoster.cardKeyOf`), applied by `mint`
and by a load re-key. Studio: a devGrant Breezy now reads `meadow:Breezy`, like
a pack copy; the test save holds no `dev:` / `lucky_block:` / `group_wheel:` keys.
Hats: owner chose three of the same hat, same grade, exactly +1 grade, max A, as
the only way to combine; the two-hat multi-stat merge verb is removed. Studio
check of `MineGear.canFuse` on made-up pieces (pairs, quads, mixed hats and
grades, A, worn and merged hats all refused).

Updated: hats-and-faces, client-and-ui, cards-and-packs, save-data-and-migrations,
next-up, log.

## [2026-10-10] query | case prices set by return, pretty numbers
Owner: *"Make it even, pretty numbers.. 50-70% rtp"*. Wild cases *"should return
70% stardust value across the board"*. Set cases *"55-65 (Higher teir less rtp,
but more volitile)"*.

How prices work now (`MineCases`):
- Recycle value only (`expectedDust`). The "+10% per set" markup
  (`SET_VALUE_STEP`) and the wild-case set average are gone; they had pushed
  returns down to about 30%.
- Stardust = value / return (`rtpOf`):
  - wild cases 70%;
  - set cases 65% for Pebblebound, falling evenly to 55% for Royal Reserve.
- Credits come off the old credit curve, scaled by 70% / return.
- Everything is rounded by `prettyPrice`.

Examples:
- ★★★★★ wild case: 41,500 stardust / 100 credits.
- Pebblebound Vault 19,500 → Royal Reserve Vault 23,000.

Every return was checked in Studio and lands within about 1 point of its
target. Suite 57/57.

Updated: pack-cases (the prices section rewritten), TODO A1c.

## [2026-10-10] ingest | A2: the TODAY checklist
Built TODAY at the top of the HUD Quests panel (`MineToday`, MineClient
`paintTodayBox` / `todayOpen`, `tools/verify/today.js`). First pass listed all
nine dailies with timers; the owner: *"to many quests and unneed info.. just
put active ones"*, so it now shows only rows that pay out now or open event
mines, and hides when empty. Studio: rows matched the save (gifts, wheel, Job
Board, pass ready; Event Horizon open); tapping Wheel opened the Daily Wheel.
Found while mapping: the wheel is one free spin a day (the 6-hour version only
lived in an old worktree); the battle pass has no quests (only Event Horizon's
event pass does); the client cannot read Event Horizon's window.

Updated: client-and-ui, next-up, TODO, log.

## [2026-10-10] query | pricing pass closed; zone packs get stars; set cases show their grade
The owner closed the pricing pass:
- The wheel's case slices stay.
- The featured set packs stay: 4 a day at ★★★ / ★★★★ / ★★★★ / ★★★★★.
- **Set cases show their set's grade, not stars.** Owner: *"A 1 star pack of
  the top set and a 1 star of shittiest set means vastly different things"*.
  The bag and stardust tiles draw "GRADE F" and so on (`MineInventoryView`
  gradeRow); the sort still uses stars.
- **Zone packs get stars.** Owner: *"EVERY PACK HAS A STAR VALUE"*, then "Pack 1,
  Rare 2, Legendary 3". This is `MinePackConfig.ZONE_PACK_STARS`, read by
  `isRated` and `packStars`, and it reverses "Zone packs get no stars".

Checked in a Studio play test: Meadow Pack 1★, Meadow Rare 2★, Meadow and
Primordium Legendary 3★; the Vault tiles read GRADE SSS / A / B. Suite 58/58.

Updated: pack-cases, cards-and-packs, owner, docs/PETS-AND-SETS.md, TODO A1c.

## [2026-10-10] query | mystery cases spin like CS:GO; one rarity ladder for reels
Owner: *"these myster cases are meant to be like csgo slots. Make each color
on the reel be reflective of the grade"*. Their follow-ups:
- *"Whatever reel lands on, you get 3 of"*;
- *"mythic should be light blue, divine … lavender … and exotic a red"*;
- *"same goes for skin cases.. same rarities"*.

What changed:
- **Wild cases** now spin once and give 3 of the pack the reel lands on
  (`MineCases.WILD_PACKS`, `rollWildPack`, `wildReel`).
- **The client** plays the spin on the existing case reel
  (`ClientFns.playCaseReels`). `MineGradeReveal.caseSpin` gained optional
  result text, note and colour fields, plus `isOpen`.
- **The ladder** `MineTemper.RARITY_COLOR` / `WORD_OF` is now F Common grey →
  SSS Exotic red. Skin cases, pack-case reels and traits all read it.
- **Prices** were recomputed for 3 packs at a 70% return, e.g. ★★★★★ 34,000
  stardust / 95 credits.

Checked in a Studio play test: a ★★★★½ case spun 44 tiles, stopped on the
winner, and gave 3x Royal Confectionery. The console was clean. Suite 58/58.

Updated: pack-cases, skins-cases-and-temper.

## [2026-10-10] query | mystery case buyer: pick the stars and how many; ★½ is 15 credits
The owner asked for two things:
- *"make ★½ 15 credits"*. This is `MineCases.CREDIT_SET` (case_2 = 15).
- *"when i go to buy mystery crates i can choose what star count i want and
  quanity"*.

Both shops now show one MYSTERY CASE panel (`MineInventoryView` mysteryBuyer):
star chips, then −/+/×10 or a typed quantity from 1 to 100.
- Credits: the order goes to the cart as tens at the bundle price plus singles,
  and the panel shows the saving.
- Stardust: it buys at once (`Verbs.buyDustCase`, quantity cap raised to
  `Const.BUY_QTY_MAX`).

Played in Studio: ★★★ × 13 = 300 credits, "save 90". Suite 60/60.

Also seen: another session's Skins panel (`_SkinProbeGui`) opens over the
shop and hides MineUI, and its SS chip is pale yellow where the reels now
use lavender for Divine.

## [2026-10-10] decision | lucky blocks pay cases; grade-ups removed
The owner said lucky blocks were *"hella boring, and not worth shit (ezpically
with the way you get gems now)"*, and gave these answers:
- gems and stardust stay, *"not scaled.. good way to break economy"*;
- pets, skins and charms come *"through cases/packs"*, using mystery cases;
- the gem and stardust amounts stay small;
- *"Remove grade-ups"*.

`MineLuckyBlocks` now rolls four kinds:
- a mystery (wild) case, ★ on a plain Lucky F up to 2× ★★★★★ on a Godly SSS;
- a skin (ore) case, from an ore tier range set by the block and grade band;
- fixed gems;
- fixed stardust.

Zone packs, pickaxes, scrolls and direct pets are gone. `GRADE_UP_ON` is false,
so there is no price and no button, and the server verb refuses. Every number is
PROPOSED (tables in chests-and-lucky-blocks). From an F start, a Godly block pays
a case 81% of the time.

Checked in Studio: 15 real opens paid ★ to ★★★★★ cases, Peridot and Starmetal
skin cases, and stardust. All of it landed in the bag. The loot card showed
"2x ★★★★★ Wild Case" with the case art. lucky-odds now also checks that every
prize is a real case. Suite 60/60.

Updated: chests-and-lucky-blocks, pets, skins-cases-and-temper, tools, glossary,
verify-suite.

## [2026-10-10] decision | star row, pulled-card tap, SSS! title, build-up flash
The owner found five things in play:
- **"these 4 stars be saying their 5 star packs ... also stars are far from
  centered".** `starRow` clipped one five-star string to a width guessed from
  the text size. BuilderSans stars are much narrower (40 px against 66), so a
  4-star fill showed five gold stars. Now each star has its own centred cell.
- **"you used to be able to click what u found in the packs to look at them,
  but now you cant".** TapAnywhere (z-index 24) sat over the YOU PULLED strip
  (z-index 8). The strip and the open-all hits grid now rise above it while the
  prompt is up, and hits can be tapped too.
- **"make it so the sss doesnt stick around".** The MineCelebrate title is
  cleared on collect, close and the next spin.
- **The card build-up.** Legendary ×2, Mythic ×2, Divine ×2, then the card's
  own rarity ×3, and one tap skips it.
- **"why is SSS behind B B C".** Set cases sort by hidden stars (Collector ★★★★),
  and the broken star row made 4-star packs look like 5-star ones.

Checked in Studio:
- 4-star packs show 4 gold stars, centred;
- the topmost button at every pulled card is Pick, and a tap lifts the card
  with its stats;
- an Exotic build-up ran Legendary to Mythic to Divine to Exotic.

Also found (not changed): each set has ~100 pets on only 7–9 base bodies, so
its ~24 Epic-and-up pets are recolours of the same few models. That is why
good pulls "all the same exact cards". Raised with the owner.

Updated: cards-and-packs, chests-and-lucky-blocks.

## [2026-10-10] decision | a set's grade scales its packs' odds; case prices follow
The owner said *"i swear some lower grade packs are pulling nothing but epics"*,
then named low-grade set packs. An audit (a seeded replay of `openPack`, 4,000
opens per set pack) found no roll bug, but the grade never entered the roll. An
F set's ★★★★★ pack paid 60% Epic-or-better per card, the same as the SSS set's.

What changed:
- `MineSetPacks.GRADE_ODDS_MULT` (PROPOSED) multiplies every Epic-and-up chance:
  F 0.40, D 0.50, C 0.60, B 0.70, A 0.80, S 0.90, SS 0.95, SSS 1.00.
- What that removes goes back to Common, Uncommon and Rare in proportion.
- ★★★★★ Epic-or-better per card is now F 24% … SSS 60%.
- Cases price off the new odds:
  - a set case by its set's grade;
  - a wild case averaged over the grades its reel lands on (mostly low).
- ★★★★★ wild fell from 34,000 to 23,000 stardust and from 95 to 80 credits.
- `creditPrice` now bumps a wild tie by 5, so the credit ladder always climbs:
  10, 15, 20, 25, 30, 35, 45, 65, 80.

The audit also flagged three things, reported to the owner and not changed:
- chest-found zone packs ignore the zone (depth only);
- Apex is rated 2.5★ but pays Epic or better 77% of the time;
- the open-all hits screen counts ribboned Epics as hits.

Updated: cards-and-packs, pack-cases.

## [2026-10-11] ingest | Better chests deeper; the 5★ case is a chance; chest skin cases
Owner asked for depth to matter for chests (*"people with explosoves nuking starter mine"*)
and chose: better chests only (count unchanged), ×1 → ×3 inside every zone except Meadow,
front-loaded (`MineConfig.chestRankLuck`, lifting B/A/S only). Then for cases: skins get
"same logic/rates" (a chest's rank shifts its skin tier, 3% of chests), and *"make myster 5
stars not garunteed 5 stars"*: the ★★★★★ case is 35% ★★★★★, and the ★★★★½ case drops to 15%
so the ladder does not invert (both owner's picks). Found: chests never paid a skin case,
because the CHEST_LOOT row's only caller (`giveDrop`) is never called. Also settled: "tokens"
always means temper tokens. Checked by `tools/verify/chest-depth.js` and in Studio
(case values 7,000 / 9,350 / 12,500 dust for ★★★★ / ★★★★½ / ★★★★★).

Updated: chests-and-lucky-blocks, pack-cases, ambiguous-terms, log.

## [2026-10-11] decision | cases give the stars they say; Apex retired
- **Mystery cases.** *"set it up so they all give how many sars it sasys.. keep
  original price"*.
  - The ★★★★★ case pays only ★★★★★ packs again. Earlier the same day it was
    set to 35% ★★★★★ / 65% ★★★★.
  - ★★★★½ is a 50/50 coin flip again; it had been set to 15/85.
  - Prices are back on the 70% return: ★★★★½ 15,000 / 65, ★★★★★ 23,000 / 80.
- **Apex.** *"we dont need apex pack anymore"*.
  - The four quests (Merge 25 / 60, Collect 500 / 1,000 cards) and the Pot of
    Gold deal pay a ★★★ Wild Case for each Apex. It is the nearest in value
    (~1,360 against ~1,500).
  - Quest and deal grants now write proper case rows (`MineCases.bagRow`), and
    a quest's reward text names the case.
  - Packs already owned still open.
- Also committed: the load migration that puts every set pet's card on the
  roster's current look (MineServer). It is idempotent, and it is needed once
  the unique set bodies land.

Suite 61/61.

Updated: pack-cases, cards-and-packs.

## [2026-10-11] ingest | A3: fishing, first cut
Built fishing on Greyvein (owner: *"Make the first fishing spot in zone 2"*): the
surface Quarry Pool, the 1,000 / 3,000 station-bay pools, 12 fish, a cast bar and the
GREEN / YELLOW / RED reel fight in the owner's words, a 15-a-day bait cap (AFK, quests,
tokens), 4 rods with x1.6 levels and a token prestige every 10 (kept on rebirth), a
5-bait rod that is one all-or-nothing fight, and the cooler. The server replays the
fight from the client's presses. The owner's "learning machine" is
`tools/sim/fishing-tune.js`: it found the brink (0.951 with the Quarry Rod L10) and
set the grades under it (docs/FISHING-TUNING.md). Tuning found that identical fish fall
off a cliff; a fish's size now sets its fight. Play-tested in Studio (the owner was
fishing in the same session: three catches, a rod bought and levelled). Settled:
"tokens" means temper tokens; bait is no longer the coin sink, the rods are.

Updated: fishing (new), index, owner, next-up, zones-layers-and-seams, TODO, log.

## [2026-10-11] fix | AFK stays out of menus
Owner: *"make the afk not pop up when in ui"*. Seen in Studio: AFK CHILL over an open Blacksmith. Cause: taps on buttons are "game processed" and the AFK block ignored them before resetting its idle clock. Any input now counts, and `ClientFns.inUi()` holds AFK and its tip off while a screen is up.

Updated: client-and-ui, log.

## [2026-10-11] ingest | Fishing: harder, and played in the pond
Owner: *"make the fishing harder"*. Holding REEL still pulls on yellow and red and
slows a run, so spam-tapping is a strategy with close calls. The finish is a fight:
inside 14 m the fish stops tiring and runs more, and it lunges at 9 m. The minigame
moved into the world: a rod and a line, a cast bobber, and a 🐟 marker with its
distance swimming the pool. One Cast/Reel button sits at the bottom centre with a
half-circle tension gauge, and instructions show only on the first cast. The
fishing screen became icons and numbers, with sentences behind (?).

Retuned: tuning every grade to a catch rate made easy fish minute-long fights, so
fights were made spikier (closer starts, shorter calms), rods reel ×1.5, and only
the top grade is tuned to a rate. Starter rod: ★ 98% in 15 s, ★★★ 66%, ★★★★ 26%.
The new view is not yet play-tested; Studio was busy.

Updated: fishing, log.

## [2026-10-11] decision | hammers and jackhammers built HQ; Frostfire split; skin looks
The owner asked: *"i need the hammers and jackhammers fully built in.. every
tool, every ore, all color ways.. extremely hq"*. Their picks: icons and 3D
models, icons from Canva, colourways = ore look plus skins.
- `ToolModelFactory`: `buildHammer` and `buildJackhammer` rebuilt to the icons.
  All 164 ore tools build in Studio with no errors.
- **Frostfire** (*"more of a fight between fire and ice"*) is split down the
  middle on every family: ice against fire, a cut seam, a flame particle.
- **Skins:** 18 set looks for hammer and jackhammer (`buildSkinned`), shown when
  a skin is equipped, with the ore as an inlay.
- **Icons:** in progress in Canva.
  - The hammer and jackhammer icons are approved, except Frostfire, which is
    being regenerated.
  - The owner also asked to redo pickaxe, drill and explosive tiers 1–81,
    keeping each tier-82 icon (*"i like PICKAXE 82, BUT REDO THE RESTs"*), with
    colours that match the ore.
  - Canva rate-limits generation: per its help, about 7 images per 30 minutes,
    plus a monthly allowance.

Updated: tools.

## [2026-10-11] ingest | Two demo Forges (molten, candy)
The owner was tired of the pitch-black Forge and asked for two demos behind buttons. Canva made the layout mockup ("Mine For Cards FORGE menu"). `MineForgeDemo` builds it in both themes and works for real: craft, upgrade, equip, recycle. 3D tools spin over a glow, cards scroll, and new tools celebrate. Seen in Studio Edit with sample data, not yet in play. Also: `snapNow` (a throttled fresh snapshot), and the trap that a UIGradient on a TextButton tints its text.

Updated: client-and-ui, log.

## [2026-10-12] ingest | Enchants core and the player level
The owner asked for a 3-slot enchant system (Damage, Utility, Special; I to V) to replace traits and runes. The Special slot decides the proc (pets only boost it; chance over 100% becomes damage). The owner chose: books from chests and cases, merge 3 for +1, slots unlocking at levels 1/10/25 from a new player level (XP from ores and chests), and refunds for retired traits and runes. Built: `MineEnchants` (data), `MineEnchantService` (verbs, XP, books), Layer 1 stats and the proc gate in `boosts()`, chest books, ore and chest XP, books returned on recycle, kept through rebirth. Checked by `tools/verify/enchants.js`. Flagged: no procs before a Special enchant, which needs level 25.

Updated: enchants (new), index, log.

## [2026-10-12] ingest | The Forge hub (Forge A + the inventory brief)
The owner loved Forge A but found it cramped, with buttons too big, and gave the inventory brief as the feature list ("DONT LISTEN TO ANY DESIGN TIPS"). Built `MineForgeHub`, wider and with smaller buttons, with three tabs: Crafting (search / filter / sort, craftable first, best first), Loadout (inspect, equip, skin, jump to upgrades) and Upgrades (level, enchant slots and book picker, scrap with confirm, merge books). The Forge dock button opens it; it hides the dock like the Blacksmith. Demo Forges removed. Not yet seen in Studio: it was in use.

Updated: client-and-ui, log.

## [2026-10-12] decision | tool icons uploaded and wired behind the share flag
Canva made these:
- 82 hammer and 74 jackhammer icons (Frostfire redone as fire against ice);
- pickaxes 1–81, redone with ore-true colours (owner: keep pickaxe 82, *"REDO
  THE RESTs"*).

All 237 are uploaded as the owner's account and wired into `MineIcons`
(`ORE_HAMMER`, `ORE_JACKHAMMER`, `ORE_PICK_CANVA`). They stay behind
`NEW_TOOL_ICONS_SHARED`, false until the owner shares them in the Creator Hub
(`build/hammer-icons/share-list.txt`).

`oreskins.js` now checks the new tables:
- each tier is complete, except jackhammers 75–82 and pickaxe 82;
- no two ores share an icon;
- no icon is shared with another family.

**Blocked:** jackhammers 75–82, drills 1–81 and explosives 1–81. Canva's AI
allowance stopped generation after about 19 hours of cooldowns. Resume from
`build/hammer-icons/state.json` and `build/tool-icons/state.json` when the
credits reset.

Suite 65/65.

## [2026-10-12] decision | Three tiers per ability
The owner: *"Make 3 levels of abilities"*, and chose "Each ability has 3 tiers that change how it works". The Special enchant's level picks the tier (I–II = 1, III–IV = 2, V = 3). Before a Special, the pets' best proc runs at tier 1. Zap chains 1/2/3 times. Blast hits 6, 18 or 26 blocks, and its tier 3 chains up to 3 pops. Tidal Wave clears 1–3 layers. Shatter allows 3, 6 or 10 procs. Quake spreads to 0, 2 or 4 neighbours, ×1.5 at tier 3. The tier table is in enchants; `Dig.procsAt` reads `b.procTier`. Checked by `tools/verify/enchants.js`.

Updated: enchants, log.

## [2026-10-12] decision | The pet calm pass
The owner: *"rework all pets so most a liitle less abiliy oriented"*, and chose "Both". Pets with an ability fell from 116 to 55 in the zone pots, from 399 to 234 in the sets and from 7 to 6 at Halloween. No pet has two ability families now (28 did). The abilities that remain are 30% weaker, but every pet keeps its power: the points go to a plain stat. Eclipse and Riftmarch lost Earthquake from their buff sets, and the Mystic Earthquake + Zap pair became Earthquake + Mine Speed. The Tidal Wave trio check is now 35–42%, which is the old 50–60% × 0.7. No names, tiers, serials or set `buffs` JSON changed.

Updated: pets, log.

## [2026-10-12] ingest | The eight mining enchants, book bundles, the Blacksmith opens the Forge
The owner asked to make the "coming soon" enchants work. All eight are live:
- Critical Strike, Executioner, Demolitionist and Combo act in the swing.
- Overclock is real swing speed; the server budget and the client bar share it.
- Vein Miner, Alchemy and Duplicator act on an ore drop.
- Explosives take none of the five in-swing ones.

Fixing this found that Ore Haul never paid: the ore drop read an undefined `b` instead of `bb`.

Books come as bundles now (the owner chose 2–5, scaled):
- chests: 2–4 books;
- lucky blocks, every one: Lucky 2, Diamond 3, Godly 5;
- the Forge's gems shop: 3 books, 500 gems × 1.15 a zone, PROPOSED (the owner chose gems as the sink runes were);
- never cases.

The Blacksmith counter opens the Forge hub. Its new BAGS and COIN SHOP buttons reach the old shop's two shelves, and the tutorial's buy-a-pick step still lands on the coin pickaxes.

Updated: enchants, client-and-ui, chests-and-lucky-blocks, log.

## [2026-10-12] lint | Studio checks: the Forge hub, and fishing played
- **The Forge hub, in Edit with sample data.** The BAGS and COIN SHOP buttons, the BOOK BUNDLE card and the bundle reveal render. Rojo had left duplicate copies of MineForgeHub (×2 in Shared and in StarterPlayerScripts), MineEnchants and MineEnchantService; the identical extras were removed.
- **Fishing, played on the Quarry Pool with the owner's OK** (two short Play runs, both closed after; owner: *"close playtest from now on"*). Cast, bite and reel work, with no console errors. Fixed: the pool now counts from the tip of the dock (fights used to start under the planks), and the tutorial card hides during the minigame.
- **Open:** whether the 🐟 marker reads well (Studio screenshots skip in-world labels), and the camera angle. While closing the daily reward popup a click landed on CLAIM, so Day 1 (400 gems) was claimed on the owner's Studio profile.

Updated: fishing, log.

## [2026-10-12] decision | Traits and runes retired
The owner: *"Retire traits and runes <no one has played.. ur good"*, so nothing was refunded. Their choices:
- only tool traits go; pet per-print perks stay;
- gems buy book bundles, the gem sink runes were;
- the Enchanter keeps Summon, Temper, Salvage and Dust;
- the battle pass uses books *"but we have to rework the entire battle pass"*;
- the daily wheel's 6% slice is *"3 lucky enchanted books"*;
- the tutorial and the quests teach enchants.

Deleted: MineRunes, MineRunesView, MineSocketsView, MineTraits, MineTraitView, the three rune cases, the scroll items, rune trading, and the Runes tabs and sections. Old saves drop the fields on load.

The pass's scroll tiers (25 / 55 / 88) pay 3 / 4 / 5 books. The Founders pack pays 3 books; that one is an assistant default.

Moving the floor to `MineCards.clampBoosts` found that it had floored Tidal Wave, the proc damages, Proc Power and Ore Haul at 0.05: a 5% Tidal Wave on every tool. It now floors every additive stat at 0.

Open: Coolant and Short Fuse now come only from the skill tree; should enchants offer them? `tools/verify/runes-retired.js` guards it all. Unopened rune cases are dropped from old bags on load.

Updated: traits, retired-and-parked, boosts-and-stats, enchants, index, log (and the other pages that described runes as live).

## [2026-10-12] lint | Wiki sweep after the rune and trait retirement
About 25 pages now describe the current game without runes, scrolls, sockets or tool traits, with the history marked "until 2026-10-12". The pages swept were trading, shops, ambiguous terms, save data, rebirth, packs, open questions, economy, client UI, quests, pets, the pouch, hats, the Forge, tools, chests, admin, the glossary, the server, Luau traps, sources of truth, the code map, the overview, the owner page, skins and the verify suite.

The sweep corrected one claim: Coolant and Short Fuse still come from the skill tree (Water, Metal). It also found that unopened rune cases in old bags could never open; load drops them now.

Updated: the pages above, log.

## [2026-10-13] query | family tempers on forged tools (digest)
Confirmed the digest against `MineServer.boosts` / `equippedTool`: the bug was
real (`(tier or 0) > 0` excluded forged look-rung 0) and **already fixed in
`b0c2430`**. No further MineServer edit. Pinned the gate in
`tools/verify/layers.js`. Wiki gotcha / open Q updated; cosmetic-vs-power
left open (do not invent).

Updated: skins-cases-and-temper, boosts-and-stats, open-questions, log.

## [2026-10-13] ingest | A3: cooler sell + catch of the day
Built cooler sell for coins (fishSell / fishSellAll, ore-pouch confirm) and
wired catch of the day into TODAY / FISH tab (global UTC target, fishClaimCotd).
Sell and reward numbers are PROPOSED. Updated fishing.md, next-up, client-and-ui.

## [2026-10-13] ingest | A3: hand rod + cork bobber
`MineFishingView.rigFx` rebuilt: pose Parts in world, WeldConstraint to
RightHand (wood shaft / handle / reel / tip eye), cork float (tan + red cap +
stem) under `Workspace.MineFishFx`, Beam line, tip-track during cast wind-up.
Cork stays on the water through the fight (no longer Transparency = 1 on bite).
Studio Play on Quarry Pool (`sunscar_pond`): rod welded to RightHand, cork on
surface after cast, Beam on, clean console for fishing. Fight module untouched.
Updated: fishing.md, log.

## [2026-10-13] ingest | A3: fish album set bonuses
Album = cooler known (row kept at n=0 after sell). One set per zone (12 fish).
PROPOSED luck at that zone's spots: +2% at 3/12, +5% at 12/12 (complete
replaces milestone). Applied in `fishCast` / `fullState` with rod × spot ×
album × cast. FISH + COOLER + ODDS show progress. Updated fishing.md, next-up.

## [2026-10-13] ingest | TODO B4 grade reference + MineStars
Surveyed every grade ladder (F�SSS / Common�Exotic, fishing GRADES, wild
cases, set/zone pack stars, lucky ranks, chest ranks, pass tiers, ore bands).
Added wiki/systems/grades-and-stars.md, MineStars.luau (stars/value/label/beside),
and wired Loadout inspect rarity to MineStars.beside. No balance changes.

Updated: grades-and-stars, index, glossary, ambiguous-terms, log.

## [2026-10-14] fix | TODAY font-size flicker
Ready TODAY rows pulsed `UIScale` on the status `TextLabel` (~15 Hz), which
read as font sizes flickering. Pulse moved to the green ready-dot. Fishing cooler
cards dropped `TextScaled` on name/foot (fixed size + truncate).

Updated: MineClient, MineFishingView, log.

## [2026-10-13] ingest | TODO B2 tool-dps verify (no rebalance)
Added `tools/verify/tool-dps.js`: forged family DPS/`edps` table from live
`toolPower` � `FAMILY_POWER` � `FRAME_STATS`. Soft-asserts B2 ordering; current
tree fails same-grade explosive-top at most sample tiers (drills win on area
throughput). No balance edits. Noted missing explosive `depth` RLE.

Updated: tools.md, verify-suite.md, log.

## [2026-10-14] ingest | MineStars.beside more UI sites
Wired `MineStars.beside` on pack odds, inventory Grade row, forge temper word
lines, skins tier badge, and lucky-block odds. Tiny letter chips unchanged. No
balance changes. Candy-style gotcha: never pulse UIScale on TextLabels.

Updated: MineInventoryView, MineForgeView, MineSkinsView, MineLuckyOddsView,
grades-and-stars, candy-style, log.

## [2026-10-14] ingest | B1 hammer niche lock + B2 explosive rebalance
Owner locked B1: hammer = slow / heavy / single-target + highest single-block
DPS. Retuned `FAMILY_POWER.hammer` 2.2?3.7, `explosive` 1?4; baked explosive
`depth` RLE (wired through `equippedTool`); lengthened mid line cells/depth to
13; trimmed mid sphere cooldowns. `tool-dps.js` now asserts hammer crowns
single-block `dps` and full-footprint explosive `edps`.

Updated: MineOreTools, MineServer, tool-dps.js, tools.md, next-up.md,
verify-suite.md, log.

## [2026-10-14] ingest | chest tool drops live + tool ? display
Fixed open-questions #7: forward-declare `rollChestTool` before
`openChestBlock` so zone chests can drop Secrets/forever tools again.
Secrets shop rarity chip and Found forever-tool sub-lines use
`MineStars.beside` (word kept). New `tools/verify/chest-tools.js`.
Full B3 (5?6 themed sets / new drop tables) still needs the owner.

Updated: MineServer, MineShopView, MineInventoryView, chest-tools.js,
open-questions, chests-and-lucky-blocks, tools.md, next-up, log.

## [2026-10-17] fix | font sizes flicker, everywhere else
Owner: *"the font sizes flicker.. fix"*. The 2026-10-14 fix only covered the
TODAY rows. The same cause was still live across the HUD: a UIScale easing over
text, which Roblox draws at whole font sizes, so it steps a pixel at a time.
- `MineUI.pulse` on anything that carries text (quest CLAIM, dock badges with
  counts, the rebirth button, the gifts button) now runs a ring that ripples
  off the edge while the thing holds still. Dots still throb as before.
- `MineUI.popNumber` (wallet pills, quest progress, skins count) lights the
  outline gold on a change and fades after the last one. It used to restart a
  size pop on every change, several times a second while digging.
- The Forge hub rebuilt every card on every snapshot (up to ten a second). It
  now repaints only on a real change, at most about once a second.
- New check `tools/verify/text-motion.js`. Not yet seen in Studio (no place was
  open).

Updated: candy-style, client-and-ui, verify-suite, log.

## [2026-10-16] decision | Drills are instant; Short Fuse on pets and an enchant
The owner: *"jack hammer spins up, drill is isntant, and short fuse should be a pet thing (and skill tree.. spin up is fine on skill tree, short fuse and enchnat [dont overdo it.. explosives cam be game breaking])"*. They chose "a few per zone, small" for the pets.
- Every drill winds in no time. The swing rule is `fam == "drill"`, and the forged, coin-shop and Event Horizon drills carry `turn = 0`. Only jackhammers spin up, and Coolant (skill tree only) shortens that.
- 2 pets in every zone carry Short Fuse as their second stat, at most 10%, with power unchanged. `shortFuse` left `MineStats.RUNE_ONLY`.
- A new Damage enchant, Short Fuse, fits explosives only: +3% a level, +15% at V (PROPOSED).

Updated: tools, pets, enchants, boosts-and-stats, traits, open-questions, log.

## [2026-10-16] decision | The battle pass rework
The owner's answers:
- *"about 2 weeks no daily xp cap"*;
- *"100 teirs, every 5 should be decent, every 10 should be good and every 25 is huge"*;
- the premium track is exclusive pets, skins and books;
- the free track pays something every tier, smaller;
- 4 season pets on the huge tiers, made by this session;
- "4 skins".

What changed:
- 90 XP a tier, 9,000 a season, from quests only, with no daily cap.
- Both tracks pay every tier, in four classes.
- The premium huge tiers pay Pickwick, Nuggetail, Gemheart and Bedrock Bob, a new `pass_2026_10` pack that nothing random rolls.
- The premium 20 / 40 / 60 / 80 pay a new MineSkins pass set that no case drops.
- Pets and skins are granted on the live profile only.
- The rail flags ★ BIG and ★ HUGE tiles.

`tools/verify/battle-pass.js` runs the real track. The amounts and names are PROPOSED. Not yet seen in Studio: no place was open.

Updated: shops-and-monetisation, pets, skins-cases-and-temper, open-questions, traits, log.

## [2026-10-16] refactor | PR #7 rebuilt on the owner's branch, 144 commits later
The owner's working branch had moved from `bae3c5b` to `98c141a` (PR #8, "Season 1 build",
144 more commits, 269 files), and that branch's own wiki edits conflicted with mine in 20
files. It still had **no ask-first rule**: no `CLAUDE.md` section, no hooks, no
`askfirst.js`. I asked four questions; the owner answered *"ok build"*, which I read as a go
ahead on my recommended defaults: merge, take **their** version of every conflicted wiki page,
re-add only mine. Re-added: the "Asking them questions" section and the 2026-10-07/08 decision
lines in `owner`, the intro and the `launch`, `trader` and `charm` rows in `ambiguous-terms`,
six verify-suite rows (`askfirst`, `launch`, `trader`, `economy-exploits`, `oreframes`,
`ui-scale`), my five 2026-10-08 log entries (in date order), the two new pages, and two
findings that still hold (open-questions 21 and 22). **Dropped as already fixed upstream:** my
findings that nothing sent `buyCharm` (`69f3de6` put the token shop in the Inventory charm list)
and that nothing sent `launchSeason` (`cc0262f` added `/admin launch now`). Corrected stale
statements in `charms`, `world-events`, `season-and-launch`, `sources-of-truth` and `overview`
(PR #6 was merged; the Event Horizon window now reads the season clock). `wiki.js` now treats
`build/hammer-icons` and `build/tool-icons` as owner-disk-only. Suite: **66 checks, 66 passed on
the second run**; the first run's `skins` failure is a CRLF/LF artefact of a Linux checkout
(see [verify-suite](code/verify-suite.md)). Nothing under `src/` is changed.

## [2026-10-17] decision | the four open questions, decided for the players
The owner: *"do what you think is best for the game [for the players.. we pushing this to
come out asap]"*. Applied to the four questions left open on 2026-10-16:
(1) graded charms from chests stay, and TODO §0.13 rule 5 now records the 2026-10-07
exception; (2) Chest Luck keeps scaling the 0.5% chest charm drop, like every other chest
reward, because one charm slot makes it a trade-off (my earlier "a comment denies it" was a
misreading: that comment is about `luck`); (3) the battle pass runs 47 days like the offers
and Event Horizon (`PASS_SEASON_END` 1793505600 → 1794110400); (4) the wiki is edited by
merging first and only adding gaps.

Checking (3) turned up a **launch-day bug** that I fixed in the same change: clients never
learned `launchedAt`, so after a launch the shop would have shown week one's deals (which the
server refuses), and the battle pass panel counted down on the raw server clock to a printed
"Oct 31". The server now mirrors the stamp to `ReplicatedStorage` (`MineLaunchedAt`) after a
successful read or save, `MineLaunch.stamp()` reads it on clients only, and the pass panel uses
`MineScrolls.seasonClock` and `passEndLabel`. `launch.js` gained nine checks, proved to fail on
the old code and pass on the new. **Not run in Studio.** Updated: season-and-launch, charms,
open-questions (21 fixed, 22 decided), owner, verify-suite.

## [2026-10-17] refactor | merged the pass rework (`d258771`) into PR #7
The working branch moved to `d258771` (5 commits: the battle pass rework, drills, text
animation, hammer and explosive niches, a restore point). Merged it into this branch: three
wiki pages conflicted (`tools-and-generators`, `verify-suite`, `log`), took theirs and
re-added only this branch's rows and log entries. The code merged without conflict, and
both sides survive: their 100-tier pass at 90 XP a tier, my season clock and 47-day end.
**One new ambiguity, asked, not decided:** the rework added `PASS_SEASON_DAYS = 28`
(unused), the branch's pass ends at 40 days, and this PR says 47
([open-questions](open-questions.md) 23). Checks: `launch` and `battle-pass` pass,
`syntax.sh` 306 files clean, compile 12 and 11 locals left, suite 70/70 on the second run
(first-run `skins` is the CRLF effect). Their `log.md` holds four bytes that are not valid UTF-8
(Windows-1252 `…` and `×`, in the MineStars entry); I kept them as they were.
