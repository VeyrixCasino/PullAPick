---
title: The owner — goals, decisions, and how to work with them
type: meta
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - docs/TODO.md §0, §9
  - docs/START-HERE.md §1, §6
  - docs/HANDOFF.md §2.6–§2.9
  - docs/PROPOSAL.md §0
  - docs/BLOCKED.md
  - roadmap/AGENT_PROMPT.md §1
  - roadmap/README.md
related: [overview, ambiguous-terms, open-questions, sources-of-truth]
---

# The owner — goals, decisions, and how to work with them

> The owner runs Mine For Cards, a Roblox game owned by the Mine For Cards
> group (id `35326298`). They make the design calls. Claude builds, checks and
> keeps records. This page is the short version of everything they have said
> about **what they want** and **how they want to be worked with**. Their
> verbatim messages are the real spec. They live in `transcripts/OWNER-MESSAGES.md`,
> which is gitignored and exists only on the owner's disk.

## What they want the game to be

- *"a game with a good community, that trades, and collects, and grinds, that is
  balanced and has precautions so it doesn't fuck itself"* (`roadmap/README.md`).
  Read "precautions" as an engineering requirement.
- *"why are we so worried about maxed out THATS NOT WHAT THE GAME IS ABOUT"*.
  Design for the first hour and the hundredth. Never tune for time-to-max
  (`roadmap/AGENT_PROMPT.md` §1).
- *"snappy but not like its not earned"*. Players should make builds, and ore
  needs other uses (`roadmap/AGENT_PROMPT.md` §1).
- **Charms and skins are the build.** Everything else supports them. A later
  charm is better because of its *shape*, not its number (TODO §0.13). See
  [charms](systems/charms.md).
- **The coin economy should be stable and let everyone contribute.** It is
  "all progression, less pull rare shit" right now (TODO §0.28, HANDOFF §2.7).
  This is unsolved. See [currencies](systems/currencies-and-economy.md).

## How to work with them (not optional)

From `docs/START-HERE.md` §1 and §6, and TODO §0.31–§0.32:

| rule | why |
|---|---|
| The owner is on **Windows PowerShell**. Never use `&&`. Never use `<angle-bracket placeholders>`. One command per line, real quoted paths. | They pasted bash into PowerShell once and got a wall of parser errors (TODO §0.31). |
| **They do not know their repo path**, and should not need to. Use `tools/start-local-agent.ps1`. | TODO §0.32 |
| **End every reply with the current todo list.** | Standing instruction (START-HERE §1) |
| **Say BLOCKED plainly**, then say exactly what unblocks it and what your default is. Use the TASTE / FACT / REACH format in `docs/BLOCKED.md`. | They asked for detail on every BLOCKED item (BLOCKED.md, top) |
| **Give them numbers to approve, not essays.** They answer best by pasting back a numbered block with edits. See `docs/PROPOSAL.md` §0. | *"propose numbers, thats it"* (PROPOSAL.md, top) |
| **Verify in code before you claim anything.** "Already exists" and "is wired" have both been wrong here. | START-HERE §5, HANDOFF §2.6 |
| **Tell them when they are wrong, with evidence.** | HANDOFF §2.9 |
| **Nothing is "done" until it has run in Roblox.** Almost nothing on the current branch has. | START-HERE §5 |
| "The UI isn't there" usually means **Studio is running old code**. Check sync before debugging. | TODO §0.14 |
| ~~**Icons are the owner's job.**~~ **Lifted 2026-10-10:** the owner asked for icons via Canva for the tool and ore art pass (TODO ★ NOW, C). | START-HERE §6; TODO ★ NOW |
| **Assets are uploaded to the group, never a personal account.** | TODO §7, [assets](code/assets-and-uploads.md) |
| If they swear, something promised did not work. Fix it; do not manage the tone. | START-HERE §6 |
| Billing trouble locally ("Credit balance too low") means an API key outranks their subscription. **Never tell them to add funds.** | TODO §0.32, START-HERE §8 |

## Asking them questions

They asked on 2026-10-05 that Claude **always ask when a request is broad or
unclear**. The rules are in `CLAUDE.md` under "Ask before you assume".

- Ask **few, concrete questions with options and a recommended default**.
  Their own BLOCKED and PROPOSAL formats work well: numbered lines, a default
  on each, paste back to approve.
- Use plain language, because they are not always reading code. Explain a
  trade-off in player terms: what the player feels.
- **Never re-ask a locked rule.** TODO §0 is titled "do not relitigate, do not
  ask again".
- When they say "just do it", proceed on your defaults and list your
  assumptions afterwards.

## Decided 2026-10-10 (TODO ★ NOW)

- **Priority order:** daily loop (wheel, dailies, fishing), then tools (hammer,
  rebalance, star-graded tool rolls), then art (328 tools), then planets.
- **The daily wheel:** every player gets one free spin a day, group members
  get +1, and login streaks grant extra spins. It sits in the lobby with its
  odds printed.
- **Fishing is the second progression track.** It is limited by bait, and
  bait costs coins (a coin sink, §0.28).
- **Stars:** 1★–5★ in half steps (9 grades). Every other grade shows a ★
  equivalent beside its name.
- **"Godly Lucky Block"** is the red block's only name.
- **The UI follows [candy-style](code/candy-style.md)** (owner, 2026-10-08):
  chunky and juicy, with honest rarity-scaled wins and *"no alarms"*.

## Decided 2026-10-10, evening (`docs/PETS-AND-SETS.md`)

- **Pets come first.** *"Just make the pet models… once all pets are in place
  I'll get you to re-evaluate rewards."* The daily loop (A2 onward) waits.
- **Zone pots:** the current pets are divided among the 11 zones. Later zones
  are better, *"but not exponentially"*. Each zone's Mythic, Divine and Exotic
  pets get a different buff set.
- **19 exclusive sets**, graded F–SSS, each with six star-graded packs and its
  own pets. The owner named every set and pack.
- **About 100 new pet body types** (first 20–30, then *"prob more like 100,
  but then we will be set for good"*). Renaming is allowed, and abilities get
  designed properly.
- **Every pet has its own name,** all 2,043 set cards included.
- **Power steps are +5%:** each zone's pot over the zone before it, and each
  set's pet budget over the set before it. 12% was rejected as *"a lot"*.
- **Universal packs** (a pack that draws a random set from everything) are to
  go. *"Don't nuke them"* yet: count first.
- **Old content:** *"XY is old"*, and so are the variant drop rates at pack
  open. They are legacy and nothing new should build on them.
- **Rewards direction** (queued):
  - star-graded pack cases holding 3–5 packs: chest drops, the wheel, and a
    stardust NPC at about 60–70% RTP;
  - zone packs carry no stars, and only exclusive packs are given as rewards;
  - packs must differ a lot from each other;
  - the wheel gives a free spin every 6 h and gets a one-image face.
- **The TODAY checklist** lives inside the Quests panel.
- **Before a big job, they want a model recommendation**, and they switch
  models before the work starts.

## Decided 2026-10-10, late ([next-up](next-up.md) has the full spec and a prompt)

- **Pet power:** an Exotic is worth *"489 at top, 300 at start"*, meaning 300
  points at zone 1 and 489 at zone 11, with the +5% step kept.
- **Procs:** Blast's share drops to 12%, below Tidal Wave's 18%. Blast is 3D
  and stacks with blast range (*"way to OP"*).
  - Tidal Wave gets its own damage stat and no range modifiers.
  - The three top Tidal Wave pets top out at about 50–60% together.
  - Zap gets a start chance and a separate continue formula (*"ensure its balanced"*).
  - Ricochet becomes **Shatter**: shards in all directions, chaining, at most
    3 procs per block you break.
  - Every proc gets a low chance plus a damage %.
  - The new stats go on hats.
- **"Equation"** meant the proc damage formula.
- **Halloween:** 10 new bodies. Bat, Mummy, Zombie, Vampire, Cauldron, Candy
  Corn, Scarecrow, Haunted Lantern, Frankenstein, Eyeball.
- **No holiday pets in the game.** They come only from a *"{Holiday} {year}
  Pack"*. Done for the six existing holiday pets.
- **Hand-offs:** when the queue is long, they want it written into the wiki
  with a prompt, then they restart the work.

## Decided 2026-10-10, sets and rewards

- **Set power:** set 1 (Pebblebound) starts at zone 1's level, and each set is
  +5% (Chaos Theory ×2.41).
- **Names:** all 2,043 ship now, and the owner reviews the sheet after.
- **Pack cases** can roll any set, with top grades rarer. They are sold for
  stardust in a new tab of the stardust shop.
- **Pack cases, refined later that day** ([pack-cases](systems/pack-cases.md)):
  - Two kinds. Set cases (Starter, Collector and Vault, with exact packs, sold
    for stardust) and wild cases (random packs of one star grade, sold in both
    shops).
  - Cases replace the wheel's pack slices.
  - The credit shop sells "cases by star + a few featured set packs".
  - Prices come from expected value. A better set costs 10% more than the set
    before it.
  - Shops carry no sets above grade B.
  - Chaos Theory (SSS) comes from credit-bought wild cases only, at 0.5% of
    slots.
  - Case art is a booster box.
- **The Halloween 2026 Pack** comes from a Halloween event mine only.
- **Old generated cards stop dropping;** owned ones keep working.
- **Theme:** a set's theme must be the predominant type of its pets, not every
  single one.

## Decided 2026-10-10, Halloween 2026

- **Window:** 17 October to 7 November 2026, on real dates. If the game is not
  live by then, it simply does not happen.
- **A second event mine**, beside Event Horizon, not instead of it.
- **The mine:** *"just like EH (same concept, and depth progression; just devided
  by 10000, and you can bring surface tools there. make there be like 5-10 chests"*.
- **The pack:** 60 Halloween pets. The 15 Halloween bodies are the rare ones;
  the other 45 are everyday pets *"with a costume {simple shit like a dog costume
  on or something}"*.
- **Split:** costumes Common 20 / Uncommon 15 / Rare 10; Halloween bodies Epic 6
  / Legendary 4 / Mythic 2 / Divine 2 / Exotic 1. **Power:** Event Horizon's level.

## Locked decisions: one line each

These come from `docs/TODO.md` §0. Each is settled: build on it and do not
reopen it.

- **0.1–0.3** Ore tier = the tool's breaking power. Breaking power is not damage.
  Block strength depends on layer and zone. Since then the zone has become the
  gate; see [mining-and-breaking](systems/mining-and-breaking.md).
- **0.4** The roster is **82 ores, final**. Event Horizon ores may be added later.
- **0.5–0.6** Charms drop from ore. There is one skin case per ore.
- **0.7** Gems come from selling ore. Zones, traits (formerly runes) and the
  pouch are the gem sinks.
- **0.8–0.9** Big numbers are formatted server-side and round down. Currencies
  show 4 significant figures, floored.
- **0.10** The wooden pick is only a tutorial pick. The tutorial hands over the
  stone pick.
- **2026-10-05, after TODO §0 was written** (commit `9733a05`): **no tool is bought with coins**; every tool is forged from ore. Backpacks, the pouch and chest Secrets stay. Every forged ore tier gets its own pickaxe skin. Source: the comments on `MineConfig.FORGE_ONLY_FAMILIES`.
- **0.12** **Fossils do not exist.** The modules are deleted. The `fossilFind`
  key and the 60 fossil bags stay, because removing them would break saves.
- **0.13** Charms and skins are the build: shape, not magnitude.
- **0.15** **A forged tool is its ore.** It is named `{Ore} {Noun}` and upgrading
  it costs the same ore.
- **0.16** Proc damage and proc chance are separate stats.
- **0.17–0.18, 0.22–0.23** Runes and gear-on-pets are replaced by **traits**, a
  prefix on your tool rolled at the Enchanter. The word "enchant" is reserved
  for a future feature.
- **0.19** **Two boost layers.** Inside a layer, bonuses add. The two layers then
  multiply. See [boosts](systems/boosts-and-stats.md).
- **0.24** Three pet seats and three hat seats. Pets stand behind you, centred.
- **0.25** Charms merge by paying **gems**, not by consuming copies.
- **0.26** The audit cut list is in `docs/AUDIT.md`: archive the unfinished,
  delete the useless.
- **0.28–0.29** Coins have no real sink yet (still open). Seams are underground
  outposts that get darker with depth.
- **0.34** **`docs/PROPOSAL.md` §0 is law**: 38 signed-off numbers. Two lines
  were changed afterwards: **seams are free**, and ore reach is two numbers,
  home 5 and cleared 15.

## Standing rules (TODO §9)

- No pity systems. **But see [open-questions](open-questions.md)**: PROPOSAL
  line 26 adds pack pity.
- No limits on the upside.
- Ore is mined, never bought.
- Skin and temper crates cost ore only.
- Hat crates do not scale with rebirth.
- Echo is not a buff.
- The server decides; the client displays.
- Do not cripple the datastore (ids and stat keys are data).
- Kill stale comments on sight.
- Verify before you claim something is done.

## See also

- [overview](overview.md)
- [ambiguous-terms](ambiguous-terms.md)
- [open-questions](open-questions.md)
- [sources-of-truth](sources-of-truth.md)
- [local-setup](code/local-setup.md)
