# Mine For Cards — Launch TODO and Handoff

**This file is self-contained.** Hand it to an agent with no other context and it
should be able to start work. It carries the orientation, the verified state of the
code, every design decision taken so far with its rationale, and the task list.

Place: "MINE FOR CARDS! SEASON ONE", placeId `73982848847016`,
owned by the **Mine For Cards group, groupId `35326298`**.
Repo: `VeyrixCasino/PullAPick`. Working branch: `claude/vigilant-fermi-aucqjy`.

Last updated: 2026-10-03. The ★ NOW section below was added 2026-10-10.

---

# ★ NOW — the owner's 2026-10-10 roadmap. Read this before anything else here.

> **LATEST (2026-10-10, evening): PETS FIRST.** The owner: *"Just make the pet
> models… once all pets are in place I'll get you to re-evaluate rewards."*
> The full spec is [`docs/PETS-AND-SETS.md`](PETS-AND-SETS.md):
> - zone pots for the existing pets;
> - 19 exclusive sets with 2,043 cards;
> - 20–30 new body types;
> - renames (always with an alias) and abilities.
>
> It also lists the legacy to retire (X/Y sets, variant odds at pack open) and
> the queued rewards pass (pack cases, ★ wheel, the stardust NPC). **A1 is done.
> A2 goes inside the Quests panel (decided). A2, A3 and B–D wait behind the pets.**

**How to work this list (any agent, cold start):**

1. **Read [`wiki/code/candy-style.md`](../wiki/code/candy-style.md) before you touch
   any UI.** It is the house style the owner chose: chunky, candy, bubbly, juicy,
   big text, honest rarity-scaled wins and no alarms. Every new screen follows it.
   The kit (`MineUI`, `MineTheme`, `MineCelebrate`, `MineAudio`) makes it the
   default.
2. Read `CLAUDE.md` ("ask before you assume") and the locked rules in §0 below.
3. **Work top-down: A, then B, then C, then D.** Finish and verify a phase before
   starting the next.
4. **Every number not marked *decided* below is PROPOSED.**
   - Put proposed numbers in ONE config table per feature, commented `PROPOSED`.
   - Give the owner a numbered block of them to approve. They answer best by
     pasting it back with edits (`docs/PROPOSAL.md` §0 style).
5. **Another session shares this checkout.**
   - Commit only your own hunks. For a shared file, build a patch of your
     hunks and stage it with `git apply --cached`.
   - Never `git add -A`.
   - Check `git diff` before every commit.
6. **"Done" means all four:** `bash tools/verify/suite.sh --quiet` passes,
   `node tools/verify/wiki.js` passes, the feature was played in Studio with
   a clean console, and a screenshot was taken.
7. **Models.** Opus is the lead for design, balance and cross-system code.
   Hand repetitive bulk (hundreds of near-identical items) to cheaper
   subagents (`model: "sonnet"`).

**The owner's ask, 2026-10-10 (condensed):**

- Fix the ores and tools: icons via Canva, 3D models via the cheapest route.
  That is about 300 tools.
- Add the **hammer**.
- Rebalance speed, damage and range: fast/short/weak against slow/strong,
  area tools (3×3 drills and explosives), and long-range explosives as the
  top DPS short of higher-grade tools.
- **Tool rolls**: rare chest and event drops in 5–6 sets, graded in stars.
- **Grade everything in stars.**
- Design every planet with Roblox psychology: *"nothing is ever too far away
  to lose a player's attention"*.
- **Higher priority:** a working daily wheel, more daily attractions, and
  progression that is not only mining (fishing, events, mini-games).

**Decided 2026-10-10:**

- **Order:** daily loop → tools → art → planets.
- **Daily wheel:** every player gets one free spin a day, group members
  (`MineConfig.GROUP_ID`) get +1, and login streaks grant extra spins. It is
  built in the lobby where everyone walks past it, with its odds printed on it.
- **Second progression track: fishing,** limited by bait. Bait costs **coins**,
  which finally gives coins a real sink (§0.28).
- **Grades:** stars from **1★ to 5★ in half steps, 9 grades**.
  - Tool rolls are graded in stars.
  - Every other grade (Common–Exotic, F–SSS, tiers) shows a ★ equivalent
    beside its current name; nothing is renamed.
  - Compile one reference of every grading system in the game.
- **The red lucky block is "Godly Lucky Block"** everywhere. Done in `223199f`.
- **Icons:** the owner now wants them made (Canva). The rule "icons are the
  owner's job" (START-HERE §6) is **lifted for this work**.
- Assets still go to the group (§7), never to a personal account.

## A. Daily loop (P0). Status: in progress (2026-10-10)

- **A1. Daily wheel. DONE 2026-10-10 (`299dd2c`), verified in Studio.**
  - It is built in the lobby, and the dock has a gold Wheel button whose badge
    counts the free spins left. Each player gets 1 free spin a UTC day, +1 for
    group members, and +1 on a claimed 7-day streak day. The odds are printed on
    every slice, and a prize is celebrated by its real odds.
  - Owner to approve: the PROPOSED allowances and the slice weights
    (the two PROPOSED blocks at the top of `MineGroupWheel.luau`).
  - Paid spins (`group_wheel_1/5/10`) are still `productId = 0`. BLOCKED on
    the owner's product ids. The buy row stays hidden until they have ids.
  - Details: `wiki/systems/social-quests-and-leaderboards.md` (Daily wheel).
- **A1b. Wheel changes (queued for the rewards pass, `docs/PETS-AND-SETS.md`):**
  - a free spin every 6 h;
  - the face as one generated image;
  - ★ pack-case slices instead of specific prizes.
- **A2. More daily attractions.** The TODAY checklist goes **inside the Quests
  panel** (owner, 2026-10-10). First list what exists: the daily reward
  calendar, the 3 daily quests, playtime gifts, the daily surprise, Job Board
  contracts and the pass. Then add:
  - The wheel.
  - A fishing "catch of the day".
  - A "TODAY" checklist on the HUD that shows every daily thing with its
    timer. A ready item pulses (the candy-style rule "what pays out always
    moves").
  - The aim: a player never runs out of things to do, and there is always a
    reason to come back tomorrow.
- **A3. Fishing.**
  - A pond on the lobby surface first, then one per planet surface.
  - Cast → bite → reel, as a short juicy minigame that can be skipped or sped up.
  - Each cast uses one bait. Bait is bought with coins.
  - The catch table is graded in ★, and its odds are shown at the bait seller.
  - A fish collection (album) with set bonuses. Fish sell for coins or gems,
    or can be traded.
  - Fishing has its own progression, separate from mining, and never bottlenecks it.

## B. Tools (P1). Not started

- **B1. The hammer** is a 4th forged family (`MineOreTools.FAMILY_ORDER`), with
  82 ores × 4 = **328 forged tools**. Decide its niche with the owner before
  building. Proposed: slow, heavy, single-target, the highest hit.
- **B2. Archetype rebalance.** Every family and frame trades speed, damage,
  range and area:
  - fast, short, low damage ↔ slow, long, high damage, with higher overall DPS
  - drills and explosives get area (3×3 and up)
  - long-range explosives top the DPS chart, beaten only by higher-grade tools
  - Build the DPS table as a verify script first, so the ordering is asserted.
- **B3. Tool rolls.**
  - Rare drops from chests and events, in 5–6 sets from common to exotic,
    graded 1★–5★ in half steps.
  - "Same function": they plug into the existing chest-tool / flagship path
    (`MineTools.CHEST_TOOLS`, `MineBandTools`).
  - Show the odds wherever a roll can be bought.
- **B4. Grade reference.** Every grading system (Common–Exotic, F–SSS, tiers,
  pack bands, lucky ranks, pass tiers…) goes in one wiki page with its ★
  equivalent, plus a shared `stars(gradeLike)` helper the UI can show beside
  any grade.

## C. Art (P1, after B). Not started

- **3D models.**
  - Today: procedural parts, 5 silhouettes per family, coloured per ore
    (`ToolModelFactory`). Every uploaded mesh in the place is empty; see
    [tools](../wiki/systems/tools.md).
  - The cheapest good route: about 20 high-quality base shapes (5 families ×
    ~4 styles), recoloured and re-materialed per ore. That is about 20
    generations, not 328.
- **Icons.** Render each tool's icon live from its model in a ViewportFrame.
  That needs no uploads and never mismatches its model. Canva is for hero and
  shop art and for the base icons.
- **Ores** get the same treatment.

## D. Planets (P2). Not started

Redesign each planet surface with Roblox retention psychology:

- Nothing worth doing is more than a few seconds' walk away.
- Every station is visible from spawn.
- There is a clear next goal in view.
- The first ten seconds hook.

Research first, then a one-page plan per planet for the owner, then build.

---

# 0. LOCKED RULES — do not relitigate, do not ask again

**0.12 — FOSSILS DO NOT EXIST.** Owner, 2026-10-02. No block spawns one, no pack
drops one, the bench is gone from the plaza. Anything a save held was cashed out
to gems on load at the game's own price. Both modules are **deleted** (owner,
2026-10-02); the payout they priced is frozen into `FossilPay` in MineServer, ~35
lines that need no module. The fossil PACKS are gone too: the three per-zone
slots, the three roster rows, their prices, their art, the chest entries that
dropped them and the "fossils" trade tab. An unopened one is cashed out on load.

Two things deliberately STAY, and neither is open for cleanup:

- **`fossilFind` keeps its KEY.** It was already repurposed to "Ore Finder". Do
  not rename it.
- **The 60 fossil-track BAGS stay in `MineBags.LIST`.** A bag id is
  `bag_<index into LIST>`, so deleting them would renumber every bag above them
  and hand every player a different backpack. They are unobtainable and hidden
  from every shelf and count; that is the fix, not deletion.

**0.34 — THE NUMBERS ARE SIGNED OFF. `docs/PROPOSAL.md` §0 IS LAW.**
Owner, 2026-10-05, pasted the 38-line block back unchanged after asking for
*"all things i have to do.. propose numbers, thats it."*

Every boost ladder, craft constant, gem spread, coin price, pity rule, gear set
and cleanup item in that block is a DECISION. Do not re-propose one, do not
"improve" one while implementing it, and do not treat the arithmetic under it as
an invitation to re-derive. If a number turns out to be wrong in engine, say so
with the measurement and let the owner change it.

Three of those lines are bugs rather than balance, and they are the ones to do
first: 21 (chest coin reward crashes on `number × table`), 14 (`ORE_REACH 15`
is shown in the UI and never read by the gate), and seam pricing computed on a
different curve than the one players are paid on.

**0.33 — `docs/START-HERE.md` IS THE COLD-START DOOR.** Owner, 2026-10-05:
*"update the goddamn handoff with a prompt to get it knowing exactly what its
doing 100% with absolutely no prior knowledge."*

§1 of that file is a prompt the owner pastes verbatim into a fresh agent. It
forces a read of AGENTS.md, CLAUDE.md, the locked rules, the bible and the
audit, then makes the agent **state its understanding and stop** before writing
code. The rest of the file is what that agent reads: what the game is, where the
code lives, the four traps (the 200-local ceiling, the global-read trap, the
missing stdlib, stat keys as data), the honest state of the branch, and how to
work with this owner.

**Two things that file must keep saying, because they are the expensive truths:**
the branch is 101 commits of *unproven* work — only one change all session was
ever confirmed in-engine. (The seam prompt was wrongly called the ship
blocker; it is wired. Corrected 2026-10-05 — see `docs/OPEN.md` P0 item 1.)

The conversation history (`OWNER-MESSAGES.md`, `TRANSCRIPT.md`, the screenshots,
the raw log) is handed over **as files, not committed** — `CLAUDE.md` forbids
raw exports in tracked files and the tooling enforces it. §9 of START-HERE tells
the next agent to ask for them.

**0.32 — THE OWNER DOES NOT KNOW THEIR REPO PATH, AND SHOULD NOT NEED TO.**
2026-10-04: *"i dont know my path and id rather get a local agent anyways"*.

Addendum, 2026-10-05: the local agent then failed with **"Credit balance too
low"**. That is an auth-source problem, not a billing one — Claude Code bills API
credits whenever `ANTHROPIC_API_KEY` is set, because a key outranks a
subscription login. The fix (clear the key, `/login`) is in HANDOFF §1 and
START-HERE §8. **Do not tell this owner to add funds.**

`tools/start-local-agent.ps1` finds the repo itself by searching `$HOME` for
`default.project.json` (it only exists at the repo root), pulls, checks for Node,
installs Claude Code if missing, **fixes PATH in the current window** so the
owner is not told to reopen the terminal, and launches. `docs/HANDOFF.md` carries
a four-line no-script version of the same thing for when the script cannot be
found either.

**Never hand this owner a command containing a path placeholder again.**

**A BUILD IS NOT THE ANSWER, and cannot be.** The owner asked for one. `rojo
build` from this repo would produce a place that OPENS but has no game in it:
Workspace (the map), Lighting, Teams, TextChatService and
`ReplicatedStorage.ToolModels_50` live only in the place file — AGENTS.md says
so and `$ignoreUnknownInstances` is why Rojo never deletes them. The place file
is the source of truth for the world; the repo is the source of truth for the
code. Only a machine with both can make a playable build, which is a local
agent, not this one.

**LUCKY BLOCKS: FIXED AND CONFIRMED IN ENGINE** — the first thing this session
has ever had confirmed by someone actually running it. DisplayOrder 110 → 120 to
match `MinePackReveal`; owner after pulling: *"inventory is under"*.

**0.31 — THE OWNER IS ON WINDOWS POWERSHELL.** 2026-10-04. Every command handed
to them must be PowerShell, not bash. `&&` is not a statement separator in
Windows PowerShell 5.1, `<angle brackets>` are a reserved operator and must never
appear even as a placeholder, and paths with spaces need quotes. The first
version of `docs/HANDOFF.md` got this wrong and the owner pasted it into a wall
of parser errors. Fixed there, with the Node/PATH gotchas alongside it.

**0.27 — THE OWNER'S 2026-10-04 LIST, FACT-CHECKED.** Full detail in
`docs/HANDOFF.md` §2.6. Checked against the code, not taken at face value:

- **"Remove the base 2x coins from rebirths"** — **already gone.**
  `prestigeYield` was `1 + 0.15R` (not 2x) and **nothing read it**. Deleted the
  function outright so it cannot be rewired by someone who finds it.
  `prestigeLuck` stays: luck is a chance, not a faucet.
- **"Potions don't exist"** — **they do, end to end.** 289-line module,
  `drinkPotion` verb, client callback, UI at `MineInventoryView:4812`, granted by
  packs, quests, rotating offers and scrolls. The gap is DESIGN: they are buried
  and weightless. They are also the obvious coin sink (see below).
- **"Depth leaderboard / anti-cheat"** — server-side deepest tracking **exists**
  (`p.deepest`, `creditDeepest`, normalized on load). Whether the leaderboard
  reads it live is unverified.
- **"Packs make you say DONE"** — true. **FIXED**: tap anywhere closes, DONE kept
  as an affordance. Built below `local finish` on purpose — a closure written
  beside the prompt frame would have been a global read and done nothing.
- **"Lucky blocks don't close/reopen the inventory"** — **FIXED**, after the
  owner supplied the missing fact: *"the inventory stays OVER the lucky block."*
  The lucky screen was DisplayOrder 110. By number alone that should already
  have beaten the inventory (which mounts into the HUD gui at 80), so the number
  was not the whole story and the code could not say which layer was winning.
  It now matches `MinePackReveal` at **120** — the layer the owner already
  signed off on, where "the menu stays open" underneath a reveal. One number,
  one pattern, both reveals. Overridable via `opts.displayOrder`.
- **Charm icon direction** — owner supplied a reference: ornate **jewellery**.
  Amulets, pendants, beaded strings, brooches, gem-set lockets; aged brass,
  enamel, cut stones. Replaces the superseded 164 generated icons.
- **Group wheel, battle pass** — both on the ARCHIVE list in `docs/AUDIT.md`.
  Do not polish them; cut them until there is a game.

**0.28 — THE COIN PROBLEM.** Owner: *"now that coins are basically useless,
theres no point... I want the economy to be stable, and a type of economy where
everyone has a chance to contribute."*

**Diagnosis:** coins have exactly ONE sink — the coin-shop tool ladder — and that
ladder was superseded by the Forge, which runs on ore. Coins are a faucet with no
drain. A rebirth income multiplier would have made it strictly worse, which is
why removing it was right.

**Proposed shape, NOT agreed, do not build without the owner:**
- Coins buy **consumables and access, never power**. Power is ore.
- The underground outposts are the home for it: each seam's outpost sells things
  *for coins* that help you mine the NEXT seam.
- **Potions are the obvious coin sink and already exist.** Give them weight,
  price them in coins, and coins have a job from minute one.
- Three currencies, three jobs, no overlap: **ore = power, gems = gambling,
  coins = consumables and access.**

**0.29 — SEAMS ARE UNDERGROUND OUTPOSTS.** Owner: 1:1 with the surface outpost
(shop, sell), themed underground, **visibly deeper and darker each seam**,
following the mine's theme.

**CORRECTED 2026-10-05 — NOT A BLOCKER.** The seam chain is wired end to end: server fires `seamGate` (`MineServer:6406`), client opens the panel (`MineClient:10859` -> `7415`), the panel fires `buySeam` (`7489`), `Verbs.buySeam` handles it (`9266`). The earlier claim came from grepping only `buySeam`, which finds the server half alone. What remains is confirming it in-game. See `docs/OPEN.md` P0 item 1.

~~Formerly the SHIP BLOCKER:~~
so every player stops at layer 500. `MineDepthPlazas` owns the prompt geometry,
`MineDepth.seamPrice(seam, zi)` gives the figure. A LOCAL agent can place the
prompt in Studio and wire it in an afternoon. **Highest-value task in the project.**

**0.30 — `docs/HANDOFF.md` IS THE BIBLE.** Owner asked for a way off the cloud
client or a handover doc. It is both: how to run Claude Code locally (nothing is
trapped — everything is in git), what is NOT in the repo, the five traps that
have already cost days, the house style, and where to start.

**0.25 — CHARMS MERGE ON GEMS, NOT ON COPIES.** Owner, 2026-10-04: *"rather
than merging it should cost gems."*

`MERGE_COST` 3 → **1**. One charm in, one charm out; `MineCharms.mergeGemCost`
charges gems for the step, priced off the TARGET's tier and charged only after
`mergeTarget` resolves, so a charm that cannot merge never takes the gems.

Eating three copies to make one was the "everything is worthless" problem in its
purest form: if three of a thing are worth one of a thing, each is worth a third
of a thing. `tools/verify/charms.js` asserted `MERGE_COST >= 2` — it was
asserting the bad design — and now asserts the new rule instead.

**0.26 — THE AUDIT, AND THE CUT.** See `docs/AUDIT.md`. Owner proposed archiving
the unfinished, deleting the useless, and shipping in 2-3 weeks. **I agree.** The
numbers: 120,662 lines across 180 modules, of which **70 modules / 20,633 lines
are referenced by nothing**. One line in six is unreachable.

Headline findings:
- **The charm family breaks locked rule 0.13.** 164 charms are GENERATED in a
  loop (`for each ore, for each variant`), so a Diamond Surge Charm is a Coal
  Surge Charm with a bigger number. 0.13 forbids exactly that. Proposal: cut
  164 → ~24 hand-authored charms that are rules, not percentages.
- **Gear, backpacks and coin-shop tools are pure ladders** — each rung strictly
  obsoletes the last. Cut or give them a kind-difference.
- **The seam blocker is still the only true ship blocker.**
- `_c.luau` is a **stale 1,710-line duplicate of MineConfig** that nothing
  requires. A trap, not just dead weight.

**0.23 — THEY ARE CALLED TRAITS.** Owner, 2026-10-04: *"Rename runes/traits to
traits, enchants will come later."*

`MineEnchants` → **`MineTraits`**, `MineEnchantView` → **`MineTraitView`**,
`tool.ench` → `tool.trait`, the verb `enchantTool` → **`rollTrait`**, the stat
`bumpStat("enchants")` → `"traits"`, the boost layer `enchantments` → `traits`,
the Enchanter's tab **Enchant → Traits**, and the button **ROLL TRAIT**.

**The Enchanter keeps its name.** It is a building, and the owner says enchants
are coming later — so the word is being freed, not retired. `enchantP`,
`showEnchantTab`, `enchantTabs` and `onOpenEnchanter` are all the PANEL and were
deliberately left alone.

The owner's own quotes in `MineTraits` are left **verbatim** and still say
"enchantment", with a header note saying to read them as "trait". Rewriting a
quote so it matches the new name would make the record wrong.

**0.24 — PET AND HAT SEATS, AND THE FORMATION.** Owner, 2026-10-04.

- **The 4th pet seat and the 4th hat seat were already gone.** `MAX_PET_SLOTS`
  and `STARTER_PET_SLOTS` are both 3, `effectivePetSlots` clamps to 3..3, and
  `MineGear.HAT_SLOTS` is `{ hat, hat2, hat3 }`. Verified, not assumed; VIP's
  fourth seat was removed earlier and the comment at `MineConfig:605` records it.
- **FIXED — pets were never centred.** `stepPetFollow` positioned a pet at
  `(slot - 2) * 2.15`, which only centres when there are exactly three. With one
  pet out it walked 2.15 studs to your LEFT and never behind you; with two, both
  sat off-centre. It centres on `(total + 1) / 2` now, so one pet is directly
  behind you and any count is symmetrical. The spawn-in pivot uses the same
  centring, or a pet popped in off-formation and slid across.

**0.22 — THE ENCHANTER HAS AN ENCHANT TAB, AND IT OPENS ON IT.** 2026-10-04,
stage 2 of 0.17.

`MineEnchantView` is the front door: pick a forged tool on the left, see what it
is wearing, pay `ROLL_PRICE`, roll. Every number on screen comes from
`MineEnchants` — odds from `odds()`, price from `ROLL_PRICE` — so the screen
cannot drift from the roll the way a hand-written "1 in 1000" would, and the
check forbids writing one.

The tab leads the strip and is the landing tab: enchantments replaced runes as
the reason to walk here, so the retiring bench must not sit in front of its
replacement. Mounted through a guarded require that **warns** on failure, per
0.14.

The confirm line names what a roll would replace. The gamble is the feature;
silently eating an Exotic V is not.

**Stage 3 — retiring runes and gear — is the only part of 0.17 left.**

**0.21 — BLAST RADIUS IS CUBIC; BACKPACK AND WALKSPEED ARE RETIRED; THE TREE IS
REGENERATED.** Owner, 2026-10-04: *"Can we remove backpack and walkspeed as
boost, and balance fire.. i agree with your changes but lets try to reblance a
little because rn fire is just way to over powered"*.

**Why Fire was overpowered — found, not guessed.** `MinePatterns` builds the
pattern with `sphere(out, cx, cy, cz, radius)` where
`radius = tool.radius * (1 + blastRadius)`. A sphere's cell count goes as **r³**,
so +50% radius is ~**3.4×** the blocks, not 1.5×. Every system that spends a
MineStats budget divides by the stat's weight, so at `6.0` the tree, the
enchanter, gear and runes were all handing out roughly **three times** the power
they thought. It got worse the instant the missing `sk.blastRadius` line was
restored and Fire's nine nodes started paying at all.

**Fix: `blastRadius` weight 6.0 → 18.0** (6 × 3, the derivative of r³ at the
margin). One number; every system corrects together. Fire's nodes fell 3.0–3.6×.

**`backpack` and `walkSpeed` retired**, by the `echo`/`autoMine` precedent: the
entries STAY so old saves, old kits and the two live `boosts(p).x` reads still
resolve, and they leave `STAT_ORDER` and every roll pool. Capacity now comes
only from the backpack ladder and the ore pouch tier.
`MineRunes.SETS.longhaul` had to be repointed by hand — **a set rune takes its
stat straight from that list and bypasses `NO_ROLL_STATS` entirely.**

**THE TREE IS REGENERATED.** `tools/skills/gen.js` is the missing generator,
rebuilt from the rule the file states. Topology is untouched — ids, names,
angles, rows, costs, prereqs, xor groups, rivals and cross-links are written
back unchanged — and only each node's `stats = { … }` is re-priced. Run
`node tools/skills/gen.js --check` to see if it has gone stale again.

    best road / worst road:   2.44x  ->  1.001x

**The five element swaps are applied**, plus Water rebuilt (its primary AND
secondary were the two retired stats): Space `echo`→`procPower`, Ground
2nd→`earthquake`, Electric 2nd→`ricochet`, Crystal 3rd→`oreLuck`, Shadow
3rd→`packLuck`, Water → `coolant`/`reach`/`coinBonus`, verb *Flow* — the drill
wedge. Grass 2nd→`pulverize`, Metal 3rd→`shortFuse`.

**EIGHT MORE DROPPED STATS, same bug as blastRadius.** Once the remap put the
new stats on elements, the tree granted `coolant`, `reach`, `earthquake`,
`shortFuse`, `ricochet`, `oreLuck`, `packLuck` and `procPower` and the server
read none of them. All eight wired. `tools/verify/skilltree.js` now fails if the
tree grants a stat the server does not apply, so the list cannot fall behind
the roster again.

**0.20 — THE ELEMENTS ARE `MineSkillData.ENERGIES`, AND THE TREE IS UNEVEN.**
Owner, 2026-10-04: *"elements should be on skill tree. check skill tree and
gather whatever info you can find"*.

They already are. Ten energies 36° apart, 75 nodes, each with a verb and a
primary/secondary/tertiary stat. §6.0's "BLOCKED — the element roster" was
**wrong**: I was grepping for "element" and the file says "energy".

Found while checking, full detail in `docs/SKILL-TREE.md`:

1. **FIXED — Fire's primary did nothing.** Nine nodes grant `blastRadius`; the
   server read seventeen `sk.*` stats and never `sk.blastRadius`. Every point
   spent on the Fire road's headline stat was discarded in silence.
   `tools/verify/skilltree.js` now asserts every stat the tree GRANTS is a stat
   the server APPLIES, guarding the whole class.
2. **The ten roads are no longer equal.** Scored against current MineStats
   weights: Grass 2.03×, Water 0.83× — **best road is 2.44× the worst**, against
   a header that promises 1.00×. The tree is GENERATED by `skills/gen.js` +
   `skills/emit.js`, **neither of which is in the repo**, and the weights it
   baked against have since moved. The rule is recoverable (budget `points/100`,
   split 50/30/20, each ÷ its stat weight — verified exactly on `fire.root`).
3. **Space's primary is `echo`**, a retired stat. Not dropped — converted to
   swing rate — but it means Space and Frost both grant swing rate and Space has
   no identity.
4. **12 of 25 stats are on no element**, including all five built this week:
   `earthquake`, `ricochet`, `procPower`, `oreLuck`, `packLuck`.

**Proposed, needs the owner:** five swaps — Space primary → `procPower`, Ground
secondary → `earthquake`, Electric secondary → `ricochet`, Crystal tertiary →
`oreLuck`, Shadow tertiary → `packLuck`. Applying them means regenerating the
baked node stats, which is the same job as fixing (2) and rebalances every
existing tree.

**0.19 — TWO BOOST LAYERS, AND THE SECOND MULTIPLIES THE FIRST.** Owner,
2026-10-04:

> "skills+skins+tools+enchantments are the very bottom ... (all multipliers go
> ontop of that, as if it was default), equipment+pets are #2 [if skin has +50%
> damage, and pet says +100% damage, and the tools base is 100, then it turns to
> 300, rather than 250 (if it was all the same)]"

**LAYER 1 (the base):** skills, skins, tools, enchantments.
**LAYER 2 (on top):** equipment, pets.
Everything inside a layer **adds**; the layers **multiply**.

    100 x (1 + 0.5 + 1.0)       = 250   <- rejected
    100 x (1 + 0.5) x (1 + 1.0) = 300   <- this

The property this buys, beyond the arithmetic: a +100% pet is worth exactly
double **whatever your skin is**. In one pile its marginal value shrinks as you
get stronger, so each layer is worth building independently only under this rule.

- **"Gear powers pets. Should just be a boost."** `MineGear.stackPets` took
  `(pets, hats, face)` and counted your hats **once per pet**, with the face
  multiplying them — a fourth pet made your hat 33% better without the hat
  changing. It now takes `pets` only. `MineGear.flatBoost(hats, face)` sums gear
  **once**, and both land in layer 2.
- **Gear is NOT deleted** (0.18 said it would be). The owner's layer list names
  "equipment" in layer 2, so it stays — as a flat boost.
- **Chance stats are never layered.** `1 + x` on a blast chance is meaningless;
  `MineCards.ADDITIVE_STATS` are summed straight through.

**NOT in either layer, on purpose:** prestige, VIP and the event pass. The owner
named four sources and two, and those three were in neither list. Moving them
into layer 1 would make every rebirth worth substantially more. Left exactly as
they were and raised in `docs/BLOCKED.md` 8b.

Guarded by `tools/verify/layers.js`, whose first assertion is the owner's own
100 -> 300.

**0.18 — ENCHANTMENT ODDS, AND GEAR IS DELETED NOT NERFED.** Owner, 2026-10-04.

- **Gear powering pets: "get rid of this."** The each-pet x its-rune x (its-hat +
  your-hat) x your-face stack is DELETED, not replaced. Pets do not get an
  enchantment of their own. This also makes the hat-sheet nerf in
  `docs/BALANCE-PROPOSAL.md` §2 moot.
- **Rarity rides the skins ladder.** Exotic **1/1000**, Exotic V **1/5000**,
  levels 1-5 **uniform**. Each enchantment has a fixed rarity; the roll picks a
  tier by weight, then an enchantment inside it, then a level.
- **The condense rule**, owner's words: *"the rarity is the chance to get a the V
  level, for all the rarest ones (over 1-200)"*. Enchant weights put SS at
  exactly 1/200 and SSS at 1/1000, so **SS V = 1/1000 and SSS V = 1/5000 — the
  skins table's own SS and SSS odds.** Asserted against `MineTemper`, not against
  a copied number.
- **Price is FLAT across rebirths.** `ROLL_PRICE = 500` gems, constant. The verb
  reads no prestige, rebirth, zone or tool tier, and the check enforces that.
- Magnitude scales by rarity on MineTemper's own two ladders; CHANCE stats take
  `PROC_RARITY_MULT` or a Divine Blasting would be +75 points of blast chance.

Guarded by `tools/verify/enchants.js`.

**STILL TO DO from the same message:** craft cost variable on (a) ore drop
amount, (b) ore rarity, (c) progression depth; pack "open all"; buy-N packs with
a typed amount (default 1); the new drop tables. And stages 2-3 of the
enchantment work: the Enchanter screen, then ripping out runes and gear.

**`docs/BLOCKED.md`** now explains every BLOCKED item in detail — what it is, why
it is the owner's, the exact sentence that unblocks it, and my default if they
say "just pick".

**0.17 — ENCHANTMENTS REPLACE RUNES *AND* GEAR.** Owner, 2026-10-04: *"replace
runes with enchantments. Pretty much just walk to the enchanter and its a prefix
too your tool (Sharp Stone Pickaxe, Lucky Stone Drill)"*, then *"and gear
aswell"*.

One enchantment, worn on the TOOL (by uid, not by family — a prefix names a
specific pickaxe), applied at the Enchanter by **naming** it and paying gems. No
rolling, no fusing, no sockets, no three hat slots and a face.

- `MineEnchants.LIST` — 25 prefixes, one per stat, every id/prefix/stat unique.
- **Magnitudes are DERIVED**: per level is `BUDGET / MineStats.weight`, clamped
  to [0.02, 0.20]. Nobody maintains a second opinion about what a stat is worth.
  At `BUDGET = 0.12`: Sharp (mineSpeed, w1.0) reaches +120% at level 10, Blasting
  (oreYield, w4.0) +30%, Wide (blastRadius, w6.0) +20%.
- Price is gems, `GEM_BASE 150 × 1.75^(level-1)`, nil past the cap.
- Only the tool **in your hands** pays out.
- The prefix lives in `MineOreTools.name`, so there is nowhere an unprefixed
  name can leak out. The level is NOT in the name.

Guarded by `tools/verify/enchants.js`.

**NOT YET DONE, and deliberately so:** runes and gear are still in place and
still paying out. Ripping out ~5,000 lines across `MineRunes`, `MineGear`,
`MineHats` and three screens, plus five save fields (`p.runes`, `p.gear`,
`p.equippedGear`, `p.toolSockets`, `p.petSockets`), **before the Enchanter UI
exists** would leave the game unplayable between commits. Order: (1) data model
+ naming + fold + verb [DONE], (2) the Enchanter screen, (3) migrate old runes
and gear into enchantments and retire the old modules.

**The one real open question:** gear currently powers PETS — the stack is each
pet × its rune × (its hat + your hat), all × your face. Removing gear removes
that, so pets need either an enchantment of their own ("Lucky Emberfox") or a
different power source. `MineEnchants.fromStatAmount` / `bestOf` exist for the
migration either way. This needs the owner.

**0.16 — PROC DAMAGE AND PROC CHANCE ARE TWO STATS.** Owner, 2026-10-03:
*"almost no effect should do full pickaxe damage"*, *"Just make damage and chance
2 different stats."*

Every proc used to hand its neighbour the player's WHOLE swing, so one stat
bought both how often it fired and how hard. Zap was 9.7x a swing off one roll.

- CHANCE stays on `oreYield` / `zap` / `earthquake` / `ricochet`.
- DAMAGE is `MineConfig.PROC_SHARE` scaled by the new `procPower` stat, through
  `MineConfig.procDamage` and nowhere else.
- Every share is **under 1.0**. Blast 0.35 (x6 faces), Zap 0.45, Ricochet 0.60,
  Quake 0.12/s. Zap capped at 6 hops at 0.75 falloff, was 32 at 0.9.
- `procPower` weight 3.0, capped +300%, rollable on gear and on pet / pickaxe /
  explosive / **drill** runes — the last being the drill-friendly ask.

Guarded by `tools/verify/procs.js`. Full numbers and the before/after table are
in `docs/BALANCE-PROPOSAL.md` §1.

**STILL BLOCKED, now written up with numbers to approve** — see
`docs/BALANCE-PROPOSAL.md` §2-§4: the hat sheet nerf (+1225% -> +420%),
`TOOL_CRAFT_BASE` 250 -> 150, `WOOD_PICK_COIN_GROW` 1.55 -> 1.40,
`EARTHQUAKE_SEC`, and whether `oreYield` should be renamed to a blast key.

**0.15 — A FORGED TOOL *IS* ITS ORE.** Owner, 2026-10-03, on first seeing the
Forge working: *"everything in forge should be called {ore} {tool}"*, *"i want
crafting to be sorted by the actual ore"*, *"i dont want different tools to cost
different ores. If i want to upgrade my stone pick, it should cost stone, at an
increasing amount each time."*

The data model already agreed; the PANEL was the liar. A forged row is
`{uid, typeId, familyId, tier, level}` and `tier` has always been the **ore's**
tier, with `upgradeOreTool` charging `C.ORES[tool.tier]` — the tool's own ore —
growing by `TOOL_ORE_GROW` per level. What was wrong: the rail listed tool TYPES
under the coin shop's invented names ("Chipped Crown", "Widow's Notch"), then
asked you to pick any ore to forge one from. So the thing you selected had no ore
in its name and one name could be made of 82 ores at 82 prices.

Now, and not open for re-litigation:

- **Name is `{Ore} {Noun}`** — "Stone Pickaxe", "Clay Drill". `MineOreTools.name`.
- **The frame is DERIVED, never picked.** `frameForTier` maps ore tier 1..82
  proportionally onto a family's priced rungs (24 / 16 / 16). Proportional, not
  nearest: nearest parks every ore past rung 24 on the top frame.
- **`craftOreTool` ignores `payload.typeId`** and re-derives. The panel quotes
  with the same pure function, so they cannot drift and a modified client cannot
  ask for a deep ore in a cheap frame.
- **The free starter never enters the pool** — filtered on `price > 0`, so
  `wood_pick` (price 0) and the unpriced chest flagships are out by construction.
- **CRAFT / UPGRADE / SHOP are modes of the panel**, on a left rail, with the
  family picker under them. The owner drew a box in that empty gutter and wrote
  *"all tabs should be there (crafting, upgrade, shop, shit like that)"*.

Guarded by `tools/verify/oreforge.js`.

**Bug found doing it:** `craftOreTool` ended with a copy of `equipOreTool`'s
toggle that read `uid` — not a local in that function, so Luau compiled it as a
global read and it was **nil in both branches**. Forging never equipped the new
tool, and if you were already holding one it silently put it away. Now
`p.oreToolEquipped = row.uid`.

**0.14 — "THE UI ISN'T THERE" IS A SYNC QUESTION FIRST.** 2026-10-03. Reported
twice: "still no forge ui", then "THERE'S STILL NO FUCKIN FORGE". Both times the
Forge was in the repo and had been for days. The screenshot settled it — the
shop's tab row read `Pickaxes · Drills · Explosives · Backpacks · Secrets ·
Upgrade` and the subtitle read *"Level the ore tools you found. Paid in their own
ore, plus stardust."* That string is the `bench` tab blurb **as it was written at
`0122667` (2026-09-28)**, deleted in `663fbb2` when the Forge took the front
line. It does not exist anywhere in the current tree. The Studio was running
`MineShopView` from before the Forge was written — older than `main`, never mind
the branch.

So, in order, before touching code:

1. Ask what the on-screen tabs say. The current set opens with **Forge** and
   **Ore Pouch**. An `Upgrade` tab means pre-2026-09-28 code.
2. `git log --all -S'<a string from the screenshot>'` dates the running build in
   one command. Screenshot text is the cheapest version stamp there is.
3. Only then look for a bug.

The fix for this class is never in `src/` — it is `git pull` in the clone
`rojo serve` is running out of, then reconnect the plugin. Note that every
service node uses `$ignoreUnknownInstances`, so a Studio that is **not** connected
keeps serving whatever scripts were last written into the place file, forever,
with no warning.

What changed in code so this cannot hide again (2026-10-03):

- `MineBuild.luau` — a `STAMP` to eyeball against the repo, and `EXPECT`, the
  modules this build needs. `announce()` runs first thing in `MineClient` and
  warns by name when one is absent, since a build older than `src/` is missing
  `src/`'s newest modules. That is the tell, and it cannot go stale into a lie.
- `MineShopView` no longer loses the **Forge** or the **Ore Pouch** tab in
  silence. The guarded require and the guarded mount both `warn` now. The silent
  version of that guard is most of why this took a week.
- `tools/verify/build-stamp.js` keeps `EXPECT` honest: every name must be a real
  module in `src/`, or the warning cries wolf and everyone learns to ignore it.

**0.13 — CHARMS AND SKINS ARE THE BUILD.** Owner, 2026-10-02. The two main parts,
and everything else (pets, hats, faces, runes) is support. Later charms are
better, **but never because the number is bigger** — a charm has a SHAPE, and a
shallow charm of the right shape must be able to beat a deep one of the wrong
shape. A pure magnitude ladder is the thing this rule exists to forbid.

These are the owner's decisions. They are not open questions, they are not
derived from any file in this repo, and no document here overrides them. If a
file in this repo disagrees, the file is wrong.

1. **ORE TIER = THE TOOL'S BREAKING POWER.** A tool forged from ore tier T has
   breaking power T. It reaches **T + 15** tiers of ore: any ore of tier <= T+15
   is mineable by it, anything above is not. Breaking power is NOT upgradeable —
   the only way up is forging from a better ore.
   *(`roadmap/ORE.md` argues ore should not drive power. It is OVERRULED.)*

2. **Breaking power is not damage.** A tool with huge damage still cannot touch
   a block above its breaking power. Two separate gates.

3. **Block strength is a function of layer and zone** — a separate gate from the
   ore reach rule above.

4. **The roster is 82 ores. FINAL.** Event Horizon ores may be added later.

5. **Charms are a NEW system: a rare drop from ORES.** Not from chests. One
   charm per ore.

6. **Skin cases: one per ore, 82 of them.** The old system dropped tools from
   cases. Now an ore case rolls at **2% down to 0.5%** to decide whether you get
   a tool.

7. **Zones, runes and the ore pouch are gem sinks. Gems come from selling ore.**

8. **Big numbers are SERVER-SIDE and always round DOWN.** `MineBigNum`
   (`ServerScriptService/Mine`) is the one formatter. Base 30, three digits a
   step: the 20 named suffixes K..Nod, then the backlog q..z, then positional
   carry. Science form `9.999e^99`. The client renders the server's string.

9. **All currencies read at FOUR significant figures, floored.**
   `MineAbbrev.currency` — 1.234K, 12.34K, 123.4K, 1.234M. Deliberately NOT
   `MineAbbrev.format`, which rounds UP so a block HP label never understates
   the rock. A wallet that rounds up tells a player they can afford something
   they cannot.

10. **The wooden pickaxe is a TUTORIAL pick.** It exists to reach the stone
    pick, handed over in the tutorial, then it is done. Cap 5 levels, coins.
    `TUTORIAL_GRADUATION_TOOL = "stone_pick"`.

11. **Breaking power comes from a tool's BASE STATS — its tier — for now.**
    One rule for every tool: an ore tool's tier is its ore, a shop rung's tier
    is its rung. `BreakPower` is stamped on every Tool instance and the swing
    gate reads it. `MineConfig.toolBreakingPower` is the only function to
    change when breaking power gets its own authored curve.


---

## Where the balance design lives (carried over from main's TODO)

The balance design is **not in this repo.** It is `AGENT_PROMPT.md` (the briefing:
what the game is, what already went wrong, the invariants, the formulas) plus
`PROMPTS.md` (tasks in dependency order), both kept outside version control. Ask
for them before starting balance work.

Three corrections to apply when reading them:

- **`roadmap/` DOES exist on this branch.** Main's copy of this note said it did
  not, and that was true of main — the eleven docs under `roadmap/` came in on
  this branch. `AGENT_PROMPT.md` §13's reading order resolves here. Note that
  `roadmap/ORE.md` carries an **OVERRULED** banner, and §0 wins over all of them.
- **The "Rebalance Numbers" artifact is superseded** by `AGENT_PROMPT.md` on seam
  placement and `REBIRTH_BASE` (artifact ~1,000, briefing ~3,600).
- **The briefing prices seams on a doubling ladder**; shipped code gates on
  `MineDepth.SEAMS`. The pricing *rule* (minutes of local income) is unchanged and
  is what makes either ladder honest.

---

# 1. Orientation — how this repo works

Rojo 7.7 project. `default.project.json` maps folders to services:

| Folder | Service |
| --- | --- |
| `src/ReplicatedFirst` | ReplicatedFirst |
| `src/ReplicatedStorage` | ReplicatedStorage |
| `src/ServerScriptService` | ServerScriptService |
| `src/ServerStorage` | ServerStorage |
| `src/StarterPlayer/StarterPlayerScripts` | StarterPlayer.StarterPlayerScripts |
| `src/StarterPlayer/StarterCharacterScripts` | StarterPlayer.StarterCharacterScripts |

File conventions:

- `*.server.luau` = Script, `*.client.luau` = LocalScript, plain `*.luau` = ModuleScript
- A folder with `init.luau` / `init.server.luau` / `init.client.luau` is a script with children
- `*.rbxm` = binary model (581 of them). **Never hand-edit.** Studio's job.
- `*.meta.json` / `*.model.json` = instance properties and attributes
- `*.txt` = StringValue

Scale: 199 `.luau` files. `MineServer.server.luau` is ~14,800 lines.
`src/ReplicatedStorage/Mine/Shared/` alone is ~55,000 lines.

**Not in the repo** (place-file only): Workspace, Lighting, Teams, TextChatService,
`ReplicatedStorage.ToolModels_50` (~80 MB), `ServerStorage.OreShapes`, and
`ReplicatedStorage.Mine.ToolBakers` (see §4). Every service node sets
`$ignoreUnknownInstances`, so Rojo never deletes Studio-only instances.

Connecting Rojo safely: see `docs/rojo-connect.md`. Short version — the only real
risk is a script edited in Studio and never synced back being overwritten by an older
file in `src/`. Syncback first, commit, then connect.

Other docs: `docs/live-config.md` (numbers measured out of the running place),
`docs/decisions.md` (why things are the way they are), `docs/ore-remake.md` (the live
ore roster (STALE at 121 rows; the real roster is 82) + per-ore appearance/glow
data + the unapplied 40-ore Space set).

---

# 2. Environment limits — read before planning

An agent running in a Claude cloud container **cannot**:

- Read anything on the user's Windows machine. Paths like
  `C:\Users\uybuv\Downloads\oreicons` are unreachable. Files must be committed to the
  repo or pasted into chat.
- Connect to Roblox Studio or run Rojo against the live place. **There is no Studio
  MCP server in this session** — verified by tool search; only Vercel, Canva, GitHub
  and Artifact tools are present.
- Upload assets to Roblox. Any upload must be done by the user in Studio, or by an
  agent that genuinely has Studio MCP, following §7.
- Run the game. There are no playtests. Verify by reasoning from source and by the
  Node harnesses in `tools/verify/`.

What it **can** do: read and edit `src/`, run `node tools/*.js` and
`node tools/verify/*.js`, and use git.

---

# 3. Design pillars

1. **Ore is the currency of power.** Ore drops directly, crafts tools, upgrades
   tools. Endgame tools cost a lot of ore.
2. **Breaking power gates progression; damage does not.** A tool with huge damage
   still cannot touch a block above its breaking power.
3. **Skins are the top prize.** Skins become the most desired drop in the game.
   Nerf whatever gets in the way of that.
4. **Rebirth keeps your gear.** Pickaxe, equipment and ore pouch all persist.
5. **Rarity disparity is the dopamine.** No case holds everything.
6. **Server decides, client displays.** Every verb validates server-side.

---

# 4. Verified facts about the current code

Checked directly; cite these rather than re-deriving.

| Fact | Evidence |
| --- | --- |
| **The roster is 82 ores. FINAL.** Event Horizon ores may be added later. `MineConfig.ORES` now holds the real 82 rows, merged from the `ore-roster-82` branch, with `ORE_MIGRATION_V2` carrying old saves. Each row carries its own `band`, `home` and `yield`. | User, 2026-10-02 |
| ~~121 ores~~ (superseded, kept to explain the 121s still in the repo) | `MineConfig.ORES`, `MineConfig.luau:2051-2173`. Also stated in `live-config.md:68`, `decisions.md:17,26`, and three places in this file's Done list. Tier 1 `stone` → tier 121 `oganesson`. |
| Ore packs exist as `<id>_ore_pack` | `MineConfig.luau:2511` (`o.packId = o.id .. "_ore_pack"`), `MineZonePacks.luau:244,251` |
| Breaking power config EXISTS; the gate does not | `MineConfig.ORE_REACH = 15`, `toolBreakingPower`, `canBreakOre`, `oreReachCap`. The swing gate is unwired because ore tools cannot be equipped — see below. |
| The F–SSS ladder already exists | `MineTemper.GRADE_ORDER = {F,D,C,B,A,S,SS,SSS}`, `MineTemper.luau:22` |
| Temper rarity weights (out of 10,000) | `MineTemper.luau:31` — F 5000, D 2763, C 1250, B 675, A 250, S 50, SS 10, SSS 2. So F 50%, D 27.63%, C 12.5%, B 6.75%, A 2.5%, S 0.5%, SS 0.1%, SSS 0.02%. **Skins inherit exactly this.** |
| Temper magnitude multipliers | `MineTemper.RARITY_MULT` F 0.45 → SSS 7.50; `PROC_RARITY_MULT` F 0.30 → SSS 1.30 |
| Runes already draw off the temper ladder | `MineRunes.luau:190-219` reads `MineTemper.RARITY_WEIGHTS`; a rune drop stops at five tiers |
| A rebirth-token wallet already exists | `MineTemper.luau:1` — "One wallet with rebirth skill tokens" |
| Bench verbs exist, uid-keyed | `Verbs.upgradeOreTool` `MineServer.server.luau:13375`, `Verbs.recycleOreTool` :13441, dispatch :13491-13492, client fires `MineClient.client.luau:4512,4515` |
| Two forge/bench views already exist | `MineForgeView.luau` 780 lines, `MineBenchView.luau` 239 lines. Reconcile; do not add a third. |
| `MineBags` is coin-only today | `MineBags.luau:7` — "Coin prices only. Never gems — zone buyCost is the gem sink." |
| ~~**`ToolBakers.OreToolBaker` is NOT committed**~~ **CORRECTED 2026-10-05** | It **is** committed, at `src/ServerStorage/OreToolBaker.luau`, 29 KB, landed in `0a91d6a`. The original row was right only about `ReplicatedStorage.Mine.ToolBakers` — there is no such folder, and nothing references the name `ToolBakers`. But the module itself is in git, so "exists only in the place file" is wrong and §6.0's syncback entry (which cites the real path) is the accurate one. |
| Ore builds tools **and** upgrades them | The two comments asserting the opposite (`MineZonePacks.luau:195`, `MineServer.server.luau:524`) were removed. A grep for "ore cannot/never build", "never builds a tool" and "only upgrade one" now returns nothing. The *code* still only upgrades — the build path lands with the Forge. |
| `ToolBakers.OreToolBaker` **houses every ore currently in the game** | Partly stale, see the row above: the module is at `src/ServerStorage/OreToolBaker.luau`. Nothing references it, so it is an **unread** ore data source rather than an absent one. Diff its roster against `MineConfig.ORES` (82, Stone → Oganesson) before trusting either. |
| No gem→ore or ore→ore purchase path found | Grep over `src/` found only `gemFind` (`MineSkillData.luau:98`) and a rune-fuse gem penalty (`MineScrolls.luau:11`) |
| Duplicate pet module | `MineEHPets.luau` and `MineEventHorizonPets.luau` are byte-identical (md5 `0a8c6c6612ba54ae42b9310d450d8059`). Consumers read the short name first, so the long one is 34 KB that never loads. |
| No CI | Repo has no `.github/` directory; PR #5 shows 0 check runs. |

---

# 5. Decision log (transcript)

> **What counts as decided:** only what the owner has stated. Numbers derived
> from files in this repo are NOT decisions — much of this repo is out of date
> (it still describes a 121-ore roster when the real one is 82). Where a value
> was needed to keep code working, it is labelled a placeholder in the source
> and listed below as awaiting instruction. Do not promote a placeholder to a
> decision by finding it written down somewhere.
>
> **Awaiting the owner's instruction, currently placeholders:**
> - Rarity band cutoffs at 82 (`MineConfig.ORE_BANDS`) — carried over from the
>   stale 121 ladder's proportions purely so bands stay reachable.
> - `TOOL_CRAFT_BASE = 250`, the ore cost to forge a tool.
> - `WOOD_PICK_*` coin ladder and its level cap of 25.
> - The 200-row cap on a player's tool rack.

Newest last. Includes reversals, so an agent does not re-litigate settled calls.

1. **`docs/ore-remake.md` was stale and is now the roster.** It claimed "planning
   only, `MineConfig.ORES` is unchanged". False — the remake landed in `deb8f35` and
   `72b81ed`. Replaced with the roster generated from `MineConfig` — which has
   since turned out to be STALE at 121 rows; the real roster is 82.
   Kept: the LOOKS block (only written record of per-ore glow colour/intensity, since
   `ORES` rows carry no `glow` key), the unapplied 40-ore Space set, the change log.

2. **Ore count is 82. FINAL.** (Event Horizon ores may be added later.) An earlier
   pass argued for 121 off `MineConfig.ORES` and four docs that all trace back to
   it. All of them are stale. `ToolBakers.OreToolBaker` is the authority, and so is
   the user. `MineConfig.ORE_COUNT = 82` is now the single source of truth, and
   rarity bands derive from it as fractions so nothing hardcodes a roster size again.

3. **Breaking power is separate from damage.** A tool can have 1000 damage and still
   be unable to scratch a block. Not upgradeable — the only way up is a better tool.

4. **Ore packs are being removed. REVERSED a Claude objection.** Claude argued the
   pack-opening animation was a dopamine beat worth keeping. User overruled: packs
   yield nothing but ore 99–99.5% of the time and are a pain. Ore drops ore directly.
   Rare drops move to **cases**.

5. **Zones stay on GEMS. REVERSED an earlier plan.** An earlier pass planned to move
   zones to coins and bags to gems. User reverted: zones stay gems, runes stay gems.
   The game needs strong gem sinks. `MineBags.luau:7` stays accurate for zones.

6. **Runes are NOT the per-ore thing — charms are. REVERSED.** An earlier pass had
   runes becoming one-per-ore, tool-only, one slot, permanent bind. User changed their
   mind: runes keep their current role and stay on gems. **Charms** become one-per-ore.

7. **Gem sinks are: zones, runes, the ore pouch.** Gems are earned by selling ore from
   the pouch.

8. **Breaking power inputs fixed.** Tool BP comes strictly from the ore the tool
   is made of. Block strength comes from layer and zone. Ore strength is
   predetermined but looser than the surrounding rock, so ores are not the wall.
   Enchants stop applying to ordinary rock past a depth band, but keep working on
   ore at any depth.

9. **Ore cannot be bought or upgraded. REVERSED an earlier idea.** The user
   dropped the ore-upgrade concept: nothing may let gems buy better ore, and
   nothing may let ore buy or upgrade into better ore. Ore is mined, period.
   (Tool upgrades paid in ore are unaffected — that is ore spent on tools.)

10. **Skin / temper crates are ore-only purchases.** No gems, no coins.

11. **Hat crates do not scale with rebirth.**

12. **Ore builds tools.** Settled. The two source comments asserting the opposite
    were deleted rather than annotated, at the user's instruction to remove
    anything outdated.

13. **The skin system inherits the old tool system.** Whatever the tool system was
    before — the rarity ladder and the chase — becomes the skin system. Tools are
    crafted; skins are hunted.

14. **`OreToolBaker` is an ore data source**, not merely a baker: it houses every
    ore currently in the game. That is why it must be synced back before Forge or
    roster work, and diffed against `MineConfig.ORES`.

15. **Skins replace tempers as the top prize**, at the same drop rates tempers have
   today. Anything that gets in the way of skins being the most desired buff may be
   nerfed.

---

# 6. The TODO

## 6.0 BLOCKED — needs the owner, not an agent

Terse on purpose: each line is BLOCKED and the one sentence you need to unblock
it. Nothing here is an agent's to decide.

- [ ] **BLOCKED — Ore icon source.** `C:\Users\uybuv\Downloads\oreicons` is on a
  local drive. Owner is supplying art.
- [ ] **BLOCKED — Charm and ore icons.** Owner is making these. The 164 generated
  charm icons in `build/charm-icons/` are **superseded — owner did not want
  them**; `tools/icons/*` and `tools/gen-charm-icons.js` stay only as the
  ids.json → `MineCharmIcons.luau` wiring for whatever art arrives.
- [ ] **BLOCKED — Asset uploads.** No agent here can upload to Roblox. §7 governs.
- [ ] **BLOCKED — `ToolBakers.OreToolBaker` syncback.** `src/ServerStorage/OreToolBaker.luau`
  exists and holds an 82-row roster of its own; diff it against `MineConfig.ORES`
  before trusting either. Nothing requires it.
- [ ] **BLOCKED — Rojo syncback.** Owner reported Rojo connected; the Studio-side
  syncback in `docs/rojo-connect.md` has still not been run.
- [ ] **BLOCKED (DEFERRED by owner) — `ORE_GEM_SPREAD` magnitude.** 10^6 is a
  placeholder and sets the whole gem faucet. Owner: "we tackle that later."
- [x] **CLEARED 2026-10-05 — Seam purchase was never unwired.** **CORRECTED 2026-10-05 — NOT A BLOCKER.** The seam chain is wired end to end: server fires `seamGate` (`MineServer:6406`), client opens the panel (`MineClient:10859` -> `7415`), the panel fires `buySeam` (`7489`), `Verbs.buySeam` handles it (`9266`). The earlier claim came from grepping only `buySeam`, which finds the server half alone. What remains is confirming it in-game. See `docs/OPEN.md` P0 item 1. Formerly: `Verbs.buySeam` is live and
  nothing fires it, so every player stops at layer 500. `MineDepthPlazas` owns
  the prompt geometry; `MineDepth.seamPrice(seam, zi)` gives the figure.
- [ ] **BLOCKED — Zone and rune gem prices.** Flat tables the ore curve will
  outrun. Pacing is an owner call.
- [ ] **BLOCKED — The legacy 31 charms.** Zone grant + gem pack + limited, all
  predating §0.5. Retire, or keep both sources?
- [ ] **BLOCKED — VIP lost a perk.** It can no longer grant a fourth pet seat.
  Replacement, or leave it at three?
- [ ] **BLOCKED — Suffixes past `Nod` (10^63).** §0.8 says `q r s t …`, §0.9's
  formatter says `Vg Uvg Dvg`. Identical below 10^63 and pinned there by
  `tools/verify/bignum.js`, so nothing waits on it. Academic — decide cheaply.
- [ ] **BLOCKED — Hat/pet/face boost budget.** "Nerf hats substantially",
  "nerf zap and blast", "almost no effect should do full pickaxe damage":
  all of these need target percentages, and a number invented here is a number
  nobody signed off. Say what a hat should be worth and it is a day's work.
- [ ] **BLOCKED — The element roster.** The new-boost mapping ("each element type
  gets one of these as its native boost") cannot be finished without it.
  Earthquake and Ricochet are BUILT and rollable on runes; what is missing is
  only which element grants which.
- [ ] **BLOCKED — `OreBalanceSim` is broken.** It reads five `MineConfig` symbols
  the `c59bec5` merge removed (`ORE_BAND_WEIGHT`, `ZONE_ORE_SHIFT`,
  `ORE_EXOTIC_HOME_ZONE`/`OFF_ZONE`, `abbrev`). It is the offline ore-balance
  sim, so it matters once the gem spread is taken off deferral. Nothing requires
  it, so it does not break the game.

## 6.1 P0 — launch blockers

### Owner, 2026-10-07 — the 10,000x pass and the launch timer

- [ ] **Event Horizon tools must be EXTREMELY strong.** Owner's word. Zone 11
      has always been off the normal ladder (`MineBreaking` says so: *"horizon is
      different... doesnt use normal tools"*), and its own progression was never
      built — which is the real reason Event Horizon reads as unmineable
      (open-questions #4), not a breaking-power bug to patch. The art for it
      arrived 2026-10-07 as `charms2`-style sheet `EVENT.SVG`: **38 ore +
      pickaxe pairs**, meteorite rock up to a black-hole pick. Build zone 11 its
      own ore roster and tool ladder off that art, on its own strength scale
      above `MineBreaking.MAX`.
- [x] **Every block and ore goes up 10,000x, and so does every tool cost.**
      **DONE 2026-10-08 — EVENT MINE ONLY.** Owner clarified on seeing it go in
      globally: *"nooo 10 thousand x in ONLY the event mine. Not in the normal
      game."* The clue was in the original sentence — *"whatever custom
      currency they are using"* is SPACE COINS, and only Event Horizon is
      priced in those.
      - `MineDepth.HP_SCALE = 10000` with `HP_SCALE_ZONE = 11`, and
        `hpScaleFor(zoneIndex)` is the single place that decides. Zones 1-10
        are byte-identical to the unscaled curve, verified at 50 points.
      - Zone 11 is a closed loop and that is why it can take it: its blocks are
        only broken by `MineHorizonTools` (eventOnly, minZone 11) and it is
        paid in a currency that buys nothing else, so scaling it moves no
        number outside it. Both halves scale — blocks through the depth curve,
        tool power through the authored `SECTIONS` table — and `megascale.js`
        checks they cancel.
      - A global pass is still a real project, for the reason noted below: ore
        quantity feeds `workOf` → `gemCompress` → every gem price, and the bag,
        rune, trait and charm-merge tables are all authored in gems.
      - Side effect worth keeping: Horizon tools were **86% off** their
        advertised hit counts, because `power = max(1, floor(refHp/hits+0.5))`
        clamped to 1 on shallow sections — a sinkcharge rated "about 70 hits"
        took ten. The scale gives the integer room; now within 1.4%.
      Owner: *"i want all blocks and ores to be 10000x what they are right now
      (SAME WITH THE COST OF TOOLS, WITH WHATEVER CUSTOM [currency] THEY ARE
      USING)"*. Both sides scale together, so the ratio a player experiences is
      unchanged — this is a headroom and big-number change, not a balance one.
      Before touching it, note what it collides with:
      - `MineBigNum` already exists for display (§6.1, base 30, science form at
        `9.999e^99`). Check the cap holds at 10,000x the top of the ore ladder.
      - `toolCraftCost` is `craftBlocks x oreYieldMid`, and **`veinSizeMean` now
        reads `craftBlocks`** (see `docs/ore-yield-and-vein-balance.md` §3). A
        blanket multiply must not silently move vein sizes; scale the cost, not
        the block count, or re-measure `veins.js` after.
      - Gem value derives from work-per-unit (`MineOrePouch.workOf`), so ore
        HP going up 10,000x moves gem prices unless it is scaled with them.
      - Datastore: verify a 10,000x number still round-trips through the save
        without precision loss.
- [x] **The launch timer must not start until the owner says launch.** Owner:
      *"i want the timer to not actually start until i say launch, and rather
      just keep ticking down"*. **DONE 2026-10-08.** `MineLaunch` holds the
      flag (`launchedAt`, 0 = not launched) and `seasonNow()` is the clock every
      season-timed system reads instead of `os.time()`: it returns
      `SEASON_START` exactly until launch, then `SEASON_START + (now -
      launchedAt)`, so a delay of any length costs nothing and the season is
      still a whole season. `MineRotatingOffers` and `MineScrolls` were already
      on it.
      - The last thing still on the wall clock was **`MineConfig.limitedActive`**,
        which counted Event Horizon's 47 days from 2026-09-22 and would have
        closed the event on **2026-11-08 with nobody having played**, with no way
        for the launch switch to stop it. It and `limitedCountdown` now read the
        season clock. Measured: unlaunched holds the full 47d, launched counts 47d
        from the switch, day 48 closes.
      - The **visible countdown** is wired. `teaserLeft()` existed and was
        referenced by nothing; `MineEventsView` now shows it while unlaunched
        (live, falling second by second off real `os.time()`, rolling over — it
        counts toward nothing by design) and hands over to the real event
        countdown the moment the switch is thrown, saying "Starts in" rather than
        "Closes in" while it is teasing.

### Breaking power

**The rule is locked (§0.1).** Ore tier = breaking power, +15 reach, never
upgradeable. Config is shipped; the gate is blocked on an equip path.

- [ ] **Tool breaking power is strictly a function of the ore the tool is made
      of.** Nothing else feeds it — not level, not damage, not skins, not runes.
      **Not upgradeable.** The only way up is crafting from a better ore.
- [ ] **Block strength is a function of layer and zone.** Those two inputs only.
      The curve is the one number still unspecified.
- [x] **Big-number system shipped** — `MineBigNum` (server-only), base 30, three
      digits a step, always floors, science form `9.999e^99`, capped at four
      significant digits. Wheel verified distinct across 2000 steps.
- [x] **`MineBigNum` has a caller.** `Verbs._benchNum` — the server's one
      number-to-string, behind every toast a player reads — went through
      `MineAbbrev.currency`, the *client* formatter, which left MineBigNum with
      no callers at all. It is `MineBigNum.auto` now.
      - **The swap is invisible, by design rather than by luck.** The two
        produce byte-identical output for every magnitude below 10^63.
      - **Getting there needed a real fix: MineBigNum did not do four
        significant figures.** It floored to one decimal flat, so 1234 read
        `1.2 K` — two figures, against the four its own header, §0.8 and §0.9
        all call for. It also printed `1 K` for 1000 where the shipping
        formatter prints `1.000K`. Now adaptive, like `MineAbbrev.currency`.
      - **`MineAbbrev` stays.** It is in ReplicatedStorage because the client
        needs a formatter for numbers it works out itself (a preview, a running
        total), and MineBigNum is deliberately server-only. The guarantee that
        matters is not that the client never formats — it is that when it does
        it cannot disagree with the server, and `tools/verify/bignum.js` now
        makes that a checked property rather than a hope.
      - Still client-formatted: every number the server does not send as a
        string. Sending one per field is a bigger change and is only worth it
        once something actually disagrees — which the check would catch.
- [x] **Currencies at 4 significant figures, floored**, everywhere:
      `MineAbbrev.currency`, with `shortNum` (client), `money` (shop, runes)
      and the Forge wallet all routed through it.
- [x] **Wooden pickaxe is a tutorial pick** — cap 5,
      `TUTORIAL_GRADUATION_TOOL = "stone_pick"`, coin ladder, `isCoinTool`.
      **Also dropped by `c59bec5` and restored.** The constant exists again, but
      nothing yet READS `TUTORIAL_GRADUATION_TOOL` — the tutorial does not hand
      the stone pick over. That part is still open, below.
- [x] **The tutorial hands over the stone pick.**
      `Verbs._graduateTutorialPick` reads `TUTORIAL_GRADUATION_TOOL` (which had
      zero readers) and grants that coin-ladder rung free on the step that
      reaches the wooden pick's cap. No-ops if the player already owns it.
- [x] **Breaking power off base stats, uniform.** `BreakPower` is stamped on
      every tool from its tier, and the gate reads that rather than `OreTier`,
      so a shop rung is measured by the same rule instead of being exempt.
- [ ] **Consequence to check:** shop rungs 1-25 now reach ore tiers 16-40, and
      a forged tier-67 pick already reaches the top ore, so the real forging
      ladder is tier 1 -> 67 in about five steps. Confirm that pacing.
- [x] **Ore reach rule, from the owner: +15 tiers.** A tool forged from ore tier T can
      mine any ore up to tier **T + 15**. Not "looser" in a vague sense — an
      exact, flat reach. Over an 82-ore roster that is ~6 crafting steps from
      the first tool to the last ore.
- [x] **Config shipped** — `MineConfig.ORE_REACH = 15`, `toolBreakingPower(tool)`,
      `canBreakOre(bp, oreTier)`, `oreReachCap(bp)`. **Dropped by the merge
      `c59bec5` and restored.** It was marked done here while the code was
      gone — see the entry in §8 for how that happened and what it broke.
- [x] **Equip path shipped.** `equippedTool()` has an ore-tool branch above the
      chest flagship, `Verbs.equipOreTool` equips/unequips and clears the
      competing overrides, the Forge has an EQUIP button, and scrapping an
      equipped tool takes it out of your hands.
- [x] **Gate shipped.** `swingBlock` refuses any ore where
      `not C.canBreakOre(bp, oreTier)` and fires `weakTool`; the client shows
      red throttled text by the hotbar. Tool BP reads the `OreTier` attribute
      stamped at give time — never `Tier`, which is cosmetic.
- [ ] ~~BLOCKED — ore tools cannot be equipped~~ Verified at the time: `equippedTool()`
      (`MineServer:1556`) has no ore-tool branch and nothing anywhere equips a
      `p.oreTools` row. No equipped ore tool means no ore tier to gate on. Order:
      1. Give `equippedTool()` an ore-tool branch, and the Forge an EQUIP action.
      2. Stamp the ore tier on the Tool instance. **NOT** the existing `Tier`
         attribute — that is `lookTier`, a cosmetic ladder value clamped to the
         shop family's length (`MineServer:4227`). Gating on it is silently wrong.
      3. Gate `swingBlock` on `C.canBreakOre(bp, part:GetAttribute("OreTier"))`
         plus the red hotbar text.
- [ ] Server-authoritative gate: server rejects any dig where
      `tool.breakingPower < block.strength`. Client may predict; server decides.
- [ ] Red hotbar text: "Your tool is too weak to damage this block." Throttled.
- [ ] **Enchants must not affect blocks in layers that are too deep — ores
      excepted.** An enchant keeps working on ore at any depth, but stops applying
      to ordinary rock past its depth band. Needs a depth ceiling per enchant.
      No enchant/depth coupling exists in `MineConfig` today; enchant code is
      spread across `MineRunesView`, `MineForgeView`, `MineShopView`,
      `MineInventoryView`, `WorldBuilder`, `MineShopFronts`, `GroupWheelService`.
- [ ] Document damage ≠ breaking power everywhere both appear.

### Ore drops ore

- [x] **Ore blocks drop ore directly**, into the pouch, with a toast. Yield
      comes from the roster's own `yield` field via `oreYield`, scaled by the
      `oreYield` boost.
- [x] **Ore cases are THE rare drop. 2%, luck-scaled** (`ORE_CASE_CHANCE`),
      rolling a `<id>_ore_case` on an ore break. There is no second roll inside
      it. Cases are registered per ore in `MineZonePacks` and the lazy-rebuild
      path catches the `_ore_case` suffix alongside `_ore_pack`.
- [x] **Opening one is GUARANTEED: a skin or a charm.** Never a tool, never ore,
      never a dud. `ORE_CASE_CHARM_SHARE = 0.25`, and that quarter is not a taste
      call — 2% × 25% = **0.5%**, exactly the charm rate §0.5 asks for, so the two
      numbers are one decision. A skin gets the same reel ceremony a bought
      temper case gets.
- [x] **Corrected from a wrong first build.** It shipped as a 0.5% drop that then
      rolled 2%→0.5% for a TOOL and paid ore on a miss — two rolls to clear, with
      the likely outcome being ore the block had already dropped.
      `ORE_CASE_TOOL_HI`/`LO` and `oreCaseToolChance` are deleted.
- [x] **The `CHEST_TOOLS` content gap is moot.** It holds only 4 Exotic, 4 Divine
      and 1 Mythic, so any band below Divine walked up the ladder to the same
      single Mythic tool. Cases pay skins and charms now and never touch that
      table, which is what §0.6 described all along.
- [x] **Migration shipped.** `Dig.bankOrePacks(p)` converts unopened
      `<id>_ore_pack` rows to banked `p.ores[id]` on load, and the `_ore_pack`
      ids stay registered in `MineZonePacks` so any row that does not convert
      still resolves and can be opened by hand.
      - **Capacity decides how many, and nothing is destroyed to tidy up.**
        `addOre` spills what does not fit and spilled ore is gone, so this
        checks for room FIRST and converts a pack only when its whole yield
        lands. The remainder stays a pack and is retried next load.
      - **No version stamp, deliberately.** A stamp would mark a player with a
        full pouch as done and strand the rest for good. It is idempotent.
      - **Pays the band MIDPOINT, not a roll** — the same expectation as
        opening, and deterministic, so rejoining cannot re-roll it. The pack's
        stamped ore finder still applies, capped exactly as the open branch
        caps it.
      - Does **not** bump the `packs` stat: these were not opened, and counting
        them would jump every pack quest at once.
      - Runs after the v1/v2 roster renames, or the old ids would not resolve.
- [x] **`MineConfig.ORE_PACK_FIND_CAP` is a real constant now.** MineServer read
      it as `tonumber(C.ORE_PACK_FIND_CAP) or 1` and the constant **did not
      exist**, so the `or 1` fallback was doing the work the comment credited to
      the knob. Behaviour is unchanged (1.0 is what the fallback gave); the dial
      is just real and tunable.
- [x] **`tools/verify/orepacks.js`** asserts the two things the migration leans
      on that are not obvious from reading it: no pack can outgrow a tier-1
      pouch (worst is 27 against 2,000, so stranding is not reachable), and the
      midpoint always lands inside what opening could have paid. Runs the real
      `MineOrePouch` against the real roster and yield bands.

### Ore pouch (net-new)

`MineOrePouch.luau` (rules + prices), `MineOrePouchView.luau` (panel), a shop tab
beside the Forge.

- [x] The main store for a player's ore. **One way in:** every path that grants
      ore goes through `Dig.addOre`, so the cap is enforced in one place instead
      of the five call sites that hand out ore. A full pouch refuses and says so
      (throttled) rather than silently eating the ore.
- [x] **Upgraded with gems.** Ten rungs, 2,000 → 1,024,000 units.
- [x] **Rung level AND contents survive rebirth**, plus the locks and
      `oresSeen`. The pouch is the only store that crosses a rebirth — that is
      the point of it.
- [x] **Descending rarity by default**, ties on depth then name so the order is
      stable.
- [x] **Filter button top-right.** Cycles rather than opening a menu, and skips
      bands you hold nothing of. Sort cycles beside it (rarity / depth / amount /
      value / name).
- [x] **Per-ore lock.** Sell All can never touch a locked ore — that is what lets
      one confirmation stand in for a prompt per row. A single-row sell still
      works on a locked ore: the lock guards the bulk button, not the row.
- [x] **Sell All at the bottom, behind a confirmation.** Two calls: the server
      prices the sale, the panel shows the server's figures, the same verb with
      `confirm` applies it. Both build the plan from `sellAllPlan`, so the total
      agreed to is the total paid.
- [x] **Selling ore yields GEMS.** The only gem faucet.
- [ ] **STILL THE BALANCE RISK the user flagged. Needs owner numbers.**
      `MineOrePouch.gemValue` is anchored on work — the home rock's HP over the
      ore's yield (`workOf`). The SHAPE (deeper always pays better per unit) is
      defensible; **the magnitude is a placeholder.**
      The dial is `ORE_GEM_SPREAD` — tier-82 worth 10⁶× tier-1 — and the exponent
      is solved from it. **It used to be the exponent itself, and that broke:** set
      to 0.5 against a roster whose depth coordinate plateaued at 21.8 it gave a
      3×10⁸ spread, and on the roster that shipped (coordinate running linearly to
      32.1) the same 0.5 gave 5.9×10¹² — four thousand times wider, for a number
      nobody touched. Asking for a spread instead survives the next model change.
- [x] **Rung prices are derived, not authored**, and had to be: a flat table
      topping out at 520,000 gems was my first cut, and one tier-30 ore unit more
      than covers that. Capacity only grows 512× against income's 3×10⁸. Each rung
      now costs ¾ of a full pouch valued at the ore for its depth
      (`RUNG_COST_SHARE`), so every rung costs the same mining TIME and the prices
      follow `ORE_GEM_SPREAD` on their own.
- [ ] **ZONE AND RUNE GEM PRICES ARE STILL FLAT TABLES** and the ore value curve
      will outrun them the same way it outran my pouch table. They are the other
      two gem sinks; they need the same treatment (price as a share of income at
      the depth they gate) or they become free by mid-game. **Not done — flagged.**

### Charms — one per ore

**A NEW system. Charms drop rarely from ORES — not from chests.**

- [x] **TWO charms per ore — 164**, generated from the roster, not authored.
      An ore's two variants are guaranteed to differ in both **shape and primary
      stat**, so neither is an upgrade of the other: picking between Stone Focus
      and Stone Twin is a question about your build, not about which number is
      bigger. The guarantee comes from the indexing (`k = (tier-1)*2 + variant-1`,
      shape `= k mod 6`, stat `= (k + k/6) mod 8` — consecutive k always differ in
      both), not from a check.
      **86 of 96 possible (shape, stat, condition) signatures** are used across
      the 164. Both divisor terms are load-bearing: drop `k/6` and the pair cycles
      every LCM(6,8)=24; drop `k/48` and the condition rides the same 48-slot
      cycle and the count falls to 48.
- [x] **Variant 1 keeps the id `<ore>_charm`** that saves already hold; variant 2
      is `<ore>_charm_2`. `oreCharm(id)` with no variant still returns variant 1,
      so every existing caller keeps working. An ore case rolls evenly between the
      two — weighting either would make the other a consolation prize.
- [x] **The name carries the shape** — `<Ore> <Word> Charm`, where the word is
      Focus / Twin / Pact / Ward / Brink / Surge. All 164 names distinct by
      construction, and you can tell what a charm does before reading the blurb.
- [x] One charm per ore was the first cut; the roster is **generated from the
      roster**, not authored.
      `MineCharms.oreCharm(oreId)` is the only way to ask for one. Generated so
      "one per ore" is a property of the code — the tool ladder has already been
      silently mis-pointed once by a roster renumber, and 82 hand-written rows is
      82 chances to repeat it.
- [x] **FIVE SHAPES, not a magnitude ladder** (§0.13). My first cut was the exact
      anti-pattern: one stat, one ramp, so tier 82 strictly beat tier 41 and there
      was one best charm per stat and 81 obsolete ones. Budget still rises with
      tier; what changed is how it is spent. The multiplier is the price of
      reliability — `FOCUS` 1.00× always-on, `PAIR` 1.15× split 60/40, `PACT`
      1.75× minus a real cost, `CONDITION` 2.00× in a moderate window,
      `THRESHOLD` 2.40× in a narrow one. Shape strides 5 against 8 stats, so the
      pair repeats only every 40 ores: **40 (shape, stat) families, each with its
      own best charm.**
- [x] **Two bugs in my own first pass at the shapes, fixed.** The PACT cost was a
      fraction of the BUDGET, so it scaled with the upside: −96% of a stat at
      tier 1 and **−308%** at tier 82, which is not a steep cost but a broken
      number. It is a fraction of the STAT now, −30% to −60%, bounded so it can
      never erase one. And two "conditions" (`deep`, `reborn`) read a high-water
      mark, so they were **permanent once passed** — a 2.4× budget that never
      switches off is not conditional. Every condition is revocable now.
- [x] **Conditions cost something real to hold:** pouch fullness against selling,
      pet count against the pet pillar, skin/no-skin against the other half of the
      build, home zone against where you want to stand. A backpack-fullness
      condition was **dropped rather than shipped broken** — `p.backpack` is the
      bag-ownership table, not a capacity, so it would have silently never fired.
- [x] **The UI says ACTIVE or inactive.** Conditions are pure reads of state the
      profile and snapshot carry identically, so one function serves the live
      boost and the preview. A conditional bonus that looks the same whether or
      not it is paying is the worst thing it can do.
- [x] **RAMP, the sixth shape.** Builds a stack per block broken, resets after
      `RAMP_IDLE_SEC` idle, pays budget × stacks/`RAMP_MAX` — so it is the one
      shape that rewards a long active session rather than a state you set up and
      sit in. **Fed only by real block breaks, never the AFK block:** an idle
      source would let a player park there at full stacks forever, which is a
      permanent bonus wearing a ramp's clothes.
      Uses `os.time()`, not `os.clock()` — the timestamp is persisted and read
      back after a rejoin, and a process-relative clock would read a stale stack
      as freshly earned. `rampFraction` is read-only; `bumpRamp` is the only
      mutator, because a boost calculation that changes state behaves differently
      depending on how often something asks for it.
- [x] **The sixth shape nearly removed variety.** 5 shapes against 8 stats are
      coprime, giving 40 distinct (shape, stat) pairs; 6 and 8 share a factor, so
      plain modulo would have cycled every LCM(6,8) = **24**. The stat index now
      carries an extra `(tier-1)/6` term, making the period 6 × 8 = **48** —
      verified, first repeat is tier 49 against tier 1.
- [x] **Echo, zap and blastRadius are excluded from that pool.** A generated
      table is the last place a stat under review should pick up 82 new sources.
- [x] **A rare drop off ore itself**, via the ore case: 2% case × 25% charm.
- [x] **0.5% drop chance** — falls out of the above rather than being set twice.
- [x] **First charm guaranteed, from either source.** `MineCharms.caseCharmShare`
      returns 1 while you own none, so an ore case pays the charm outright rather
      than spending three cases in four on the half of the build a new player
      cannot use yet. One function owns the rule so the two sources cannot drift.
      The zone grant's own check moved to `MineCharms.ownsAnyCharm` on the way —
      it used `next(p.charms) ~= nil`, which reads a tally left at zero as
      ownership and would have quietly cancelled the guarantee.
- [x] **Mergeable into higher tiers.** Three copies become one of the charm one
      ore tier deeper, same variant. Three because the card merge is already
      "MERGE 3 → UP" and a second merge arithmetic is a thing players learn twice.
      - **It is a TRADE, not an upgrade**, and that is the point. Shape comes
        from `k = (tier-1) * variants + (variant-1)`, so a merge moves `k` by
        `variants` and the shape ALWAYS changes — you buy depth and variety, not
        a bigger number, which is what §0.13 asks for. `tools/verify/charms.js`
        asserts it across all 162 mergeable charms rather than trusting it.
      - **Legacy charms do not merge.** §6.0 still has an open owner call on
        whether they are retired; feeding them into a ladder would decide it
        quietly.
      - The card's right-hand button was "CAN'T SELL — charms are kept, not sold",
        a control whose only job was to refuse. It is MERGE now, and it names
        what the charm becomes, because the target has a different shape and a
        player who is not told cannot judge the trade.
      - Merging away the last copy of the EQUIPPED charm moves you onto the one
        you just made, rather than leaving `p.equippedCharm` dangling for the
        load path to clear.
- [ ] **Decide what happens to the legacy 31.** 15 zone-grant + 15 gem-pack + 1
      limited charm still exist and still drop. §0.5 says charms are an ORE drop;
      these predate it. Left in place deliberately so nobody loses one — **needs
      an owner call** on whether the zone grant and the gem pack are retired.
- [ ] `roadmap/CHARMS.md` is on disk from the merge. Read it, but §0 wins where
      it disagrees.

### Universal recycling

Applies to tools, pets, runes, charms, and anything recyclable added later.

- [ ] Recycle returns **50% in ore and stardust**.
- [ ] Plus an extra amount scaled to the item's value — "decent but not game
      breaking". Needs a curve; propose and get sign-off before shipping.

**Bulk recycle UI** — the flow is built; it is wired into the EQUIPMENT menu so far.

- [x] A **Select** button that puts the menu into selection mode.
- [x] **Bulk select** — tick multiple. **No select-all**, as specified.
- [x] A **Recycle** button that opens a **review screen listing everything about to
      be recycled**, each item's payout and the total — plus anything that cannot
      go, with the reason. The hold used to sit on the SELECT bar and fire
      straight into the scrap, so a player held three seconds over a list they had
      never seen and a total they had never been quoted.
- [x] **Hold 3 seconds to confirm**, on the review screen where there is finally
      something to confirm against. Disabled outright when anything is blocked —
      holding three seconds for a guaranteed refusal is worse than not offering it.
- [x] Server re-validates on confirm. `scrapPlan` is read-only and builds both the
      review and the commit, so the two cannot disagree. **Socketed gear is now
      blocked**, which the old path did not do: a rune in a piece is permanent, so
      scrapping the piece strands it.
- [x] **One transaction — all or none.** The old path scrapped what it could and
      skipped the rest silently; for a *reviewed* batch that is a broken promise.
- [x] **Fixed a real bug on the way:** `packScrapDustFor` was declared BELOW
      `scrapMany`, and a `local function` is not in scope inside a function written
      earlier in the file — the name compiled as a global read, so the pack arm of
      bulk scrapping called a nil value and **threw on every use**. Confirmed with
      a minimal repro under the interpreter.
- [x] **CARDS and PACKS have the Select UI now**, on the same server path.
      - **Selection is one kind-tagged table** (`pick`), shared by every tab.
        It was two untagged fields on the equipment state, which was fine while
        EQUIPMENT was the only tab with a button — with three tabs it is a bug
        waiting to happen: tick gear, switch to PACKS, hit RECYCLE, and the
        client sends gear ids under kind `pack`. Changing kind clears it.
      - **A pack tile is a stack**, so ticking one selects every uid in it; the
        server scraps packs one uid at a time and a half-ticked stack has
        nowhere to show itself. Lucky blocks are excluded — they have no scrap
        value, so the review would open on a wall of refusals.
      - **Open buttons are not drawn while selecting.** Opening a pack and
        recycling it are opposites; a few pixels apart they are a trap.
      - **`into` is per kind and passed, not guessed**: cards pay stardust,
        gear and packs pay gems, matching what `scrapPlan` prices.
      - **`MineConfig.SCRAP_MAX` is shared now.** The cap was server-only, so
        the UI could let a player tick a 300-pack stack that the server
        truncates to 200 — a review honest about a list they never chose. One
        number, read by both, and the UI refuses past it with a toast.
- [x] **RUNES too — all four kinds are wired now.** The control moved out to
      `MineScrapSelect.luau` rather than being copied into the Enchanter: it was
      ~100 lines of inline UI, and two copies is how one of them learns about
      `SCRAP_MAX` or about kinds and the other does not.
      - **The review screen is parented to the SCREEN now, not to the inventory
        panel.** It is drawn by `MineInventoryView` and the server's
        `confirmScrap` is routed there, so under `root` a player recycling runes
        from the Enchanter would have held RECYCLE and seen *nothing happen* —
        the review inherited a hidden panel's `Visible`. `ctl.close()` destroys
        it for the matching reason.
      - **`sel.prune(keep)`** drops ids that no longer exist. The Enchanter's
        selection can go stale without it doing anything: the commit clears the
        INVENTORY's copy of the control, so a rune scrapped, fused or traded
        away would otherwise stay ticked and turn the next batch into an
        all-or-nothing refusal.
      - **Selecting takes the tap on a rune card**, because fusing and recycling
        are opposites and one gesture must not mean both.
      - The rune list opens on CAN FUSE, which hides every rune you hold only
        one of — exactly the ones worth recycling — so the empty-selection hint
        points at the ALL chip.
- [ ] Recycle returns **50% in ore and stardust** plus a value-scaled extra. Still
      needs the curve and sign-off; current payouts are the pre-existing scrap
      rates, not this.

### Ore cases and skins

- [ ] **Ore packs become Ore cases.** Asset names: `{Ore}` for the icon,
      `{Ore}Case` for the case.
- [ ] **82 cases, one per ore.** Not per tool rarity.
- [ ] **The case rolls 2% down to 0.5% to decide whether you get a tool.** The
      old system dropped tools from cases directly; that roll is now the case's.
- [ ] Reuse the **existing charm-find animation** (pull-from-pack) for the case drop.
- [ ] Opening a case yields a **skin that applies to a whole tool family**.
      the real ore count all along. Confirm: one case per ore, 82?*
- [ ] **Drop rates identical to tempers today**: F 50%, D 27.63%, C 12.5%, B 6.75%,
      A 2.5%, S 0.5%, SS 0.1%, SSS 0.02% (`MineTemper.RARITY_WEIGHTS`).
- [ ] **Naming**: every skin name states which ore it is and what type of skin.
- [ ] **A skin must not change the tool's colour.** It is a wrap — a cool, easily
      duplicatable look that canvas can mass-produce.
- [ ] Rename tempers → skins across `MineTemper.luau` (537) and its views. Keep
      `LEGACY_RARITY` / `normalizeRarity` so old saves load.
- [ ] **The skin system takes over what the tool system used to be.** The old
      rare-tool-drop mechanics — rarity ladder, drop pacing, the chase — move onto
      skins wholesale. Tools stop being the chase item; they are crafted from ore.
      Skins become the thing you hunt.
- [ ] Nerf anything that competes with skins for "most desired buff".

### The Forge (was the Blacksmith)

- [x] **CRAFT / UPGRADE tabs** in the Forge detail pane. The first cut inferred
      the mode from ownership, so craft recipes silently did not exist for any
      tool already owned and the panel looked like it had no crafting at all.
      The mode now defaults by ownership but is always switchable.
- [x] **Notification badges sit on the top-right corner**, half outside the
      plate, instead of inset two pixels inside it where they read as part of
      the button's own label. `mkBadge` clears `ClipDescendants` on the plate,
      since a badge hanging outside is otherwise cropped.
- [x] **The Forge is the front line.** It is first in the tab strip, relabelled
      from "Upgrade" to "Forge", and is the tab the shop now opens on. The
      coin-shop families are the second line behind it, and a COIN SHOP button
      in the Forge header routes down to them. The button is only drawn when
      the host supplies `onCoinShop`, so `MineForge` never requires
      `MineShopView` — that would be a cycle, since ShopView mounts the Forge.
      `paint()` falls back to the first coin-shop family if the Forge module
      ever fails to require, because a missing panel on the default tab would
      otherwise be a blank shop on open for every player.
- [x] **Forge shell built** — `MineForge.luau`. Vertical rail of **every tool in
      the game** down the left, detail pane on the right: CRAFT when unowned,
      UPGRADE when owned. Mounted in place of `MineBenchView` on the shop's
      Upgrade tab (same `{refresh, root}` contract, same pcall guard).
      `MineBenchView` is now superseded and can be deleted once the Forge has
      its own front.
- [ ] `MineForgeView.luau` (780, temperaments) still needs folding in as the
      skin/rune application area — see below.
- [ ] Keep the full-screen 3D display from `583d9ad`.
- [x] **Vertical scrolling recipe list**, and the tool rail is vertical on the
      left-hand side as specified.
- [x] **Show only discovered ores**, with the amount each recipe needs.
      `discoveredOres()` prefers an explicit `snapshot.oresSeen` set and falls
      back to ores currently held — which under-reports but can never
      over-report, so an unseen ore cannot leak its name, tier or colour.
- [x] **Depth sheet extracted and documented** — `docs/depth-sheet.md`,
      generated by `tools/gen-depth-sheet.js` from the live `MineDepth.SECTIONS`.
      Carries the exact HP equation, the section-size progression, the per-band
      step ratios and the zone 1-10 table to depth 10,000.
- [x] **`oresSeen` ships end to end.** `p.oresSeen` is a grow-only set on the
      profile, seeded on load from banked `p.ores` so existing saves keep what
      they already found, marked at both grant sites (mining and recycle),
      sent in the snapshot, copied in `MineShopView.setState` and read by the
      Forge. A recipe no longer vanishes when the last unit of that ore is
      spent. No new top-level locals: `MineServer` sits at 197 of 200 and
      `Verbs` is declared below the mining grant, so the marks are inlined.
- [x] **Separate upgrades area** — the detail pane switches to UPGRADE for an
      owned tool: level, next step's price, +1 / +10 / MAX and SCRAP.
- [x] **The skin and rune on a tool are shown in the upgrade pane**, with buttons
      to the Enchanter's Temper and Sockets tabs.
      - **Both are PER FAMILY, not per tool** — `p.toolSockets` and
        `p.toolTempers` are keyed `pickaxe`/`drill`/`explosive`, and a forged row
        carries only `uid, typeId, familyId, tier, level`. It cannot hold either.
        The pane says "ON THIS FAMILY" rather than implying the fit is per-tool.
      - It **reports and routes** rather than reimplementing. The Enchanter's two
        tabs are several hundred lines each and work; a second copy is how two
        screens start disagreeing about what is fitted.
- [ ] **Whether the Temper/Sockets tabs should MOVE here** (so the Enchanter stops
      owning them) is a design call, not a side effect of this panel. `MineForgeView`
      already has `mountList(parent, opts)`, which takes a position and size and
      is embeddable — so the mechanics are cheap once the call is made. What is
      expensive is deciding whether the Enchanter keeps a Temper tab at all.
- [x] **The ORE POUCH is in the Forge**, along the bottom: every ore you hold,
      rarest first, with fill against capacity. The wallet strip answered
      coins/gems/dust and the detail pane quotes the ore cost of whatever is
      SELECTED — neither answered the question you actually have while browsing a
      rail of a hundred recipes. Reference, not somewhere to act: nothing in it
      is clickable.
      - **Found a bug in the addition itself:** it read `snapshot.orePouchTier`,
        which the shop's hand-built `getSnap` did not pass, so capacity read as
        tier 1 for everybody. `tools/verify/forge-snap.js` now fails when the
        Forge reads a field the shop omits — nil does not throw there, it falls
        through a `tonumber(…) or 1` and prints a plausible wrong number.
- [ ] **The BAG is not in the Forge.** Cards, packs, runes and gear are still
      inventory-only. The pouch was the part that mattered for forging; the rest
      is a second large panel inside a panel and wants a design call on what it
      is for.
- [ ] Server owns crafting: ore debited and tool minted in one transaction. No
      client-supplied costs, no partial debits on failure.

### Tools craftable and upgradeable with ore

- [x] Craft recipes keyed by ore. `MineConfig.toolCraftCost(tier, typeMult)`
      prices off the same `toolCostMult` the level curve uses, so one curve
      governs both. `TOOL_CRAFT_BASE = 250` is the single knob.
- [ ] The crafting ore must also set the tool's **breaking power** — blocked on
      the breaking-power curves (open question 1).
- [ ] Upgrades cost ore, **a lot of it** — endgame tools are a real grind.
- [ ] Keep the uid-keyed contract of `upgradeOreTool` / `recycleOreTool`.

### Economy removals — ore cannot be bought or upgraded

User reversed the ore-upgrade idea entirely. Ore is earned by mining, full stop.

- [ ] **Remove any path where gems buy better ore.**
- [ ] **Remove any path where ore buys or upgrades into better ore.**
      No ore merging, no ore tier-up, no ore trade-up.
- [ ] *Audit status:* a first grep found **no such path**. The only gem/ore
      couplings are the `gemFind` skill stat (`MineSkillData.luau:98`) and a
      rune-fuse gem penalty (`MineScrolls.luau:11`), neither of which buys ore.
      Confirm exhaustively before closing, and add a standing rule so it does not
      creep back in.
- [ ] **Skin / temperament crates are buyable with ORE only.** Not gems, not
      coins, not anything else.
- [ ] **Hat crates must not increase on rebirth.** Find and remove any
      rebirth-scaled hat-crate yield.

### Rebirth

- [x] **Gear survives rebirth** — audited every carry, and found a real one missing.
      **`p.oreTools` was not carried, so rebirth destroyed every forged tool.**
      A forged tool is THE tool now (built from ore, levelled with ore plus
      stardust, nothing found in walls), so rebirth was deleting the whole tool
      investment while the ore pouch beside it survived. `fresh.oreTools` and
      `fresh.oreToolEquipped` now carry; the load path already self-heals a
      dangling equip, so a missing tool clears the hand rather than erroring.
      The COIN-LADDER tools still reset deliberately — cheap early rungs rebirth
      is meant to make you re-buy — and their socketed runes stay on the family.
      Verified carried: runes, gear, `equippedGear`, pet sockets, charms, the
      equipped charm, `tempers` and `toolTempers` (so the skin pillar survives),
      the ore pouch and its locks. Deliberately NOT carried: `charmRamp`, which is
      a session thing that expires in 12s, and `shopToolRunes`, whose wipe returns
      those runes to the bag free rather than losing them.
- [x] Ore pouch contents and upgrade level survive rebirth — plus the ore locks
      and `oresSeen`.
- [ ] *Needs confirmation:* an earlier pass planned "rebirth raises coin value" and
      "soften the zone/depth coin multipliers". That was motivated partly by the
      now-reverted coin-zones plan. Confirm whether it still applies.

## 6.2 P1 — boosts, hats, pets

### Hats and faces

- [x] **Hats cost rebirth tokens.** Flat `MineGear.ROLL_TOKEN_COST = 5` against a
      temperament case's 20, spent from `p.temperTokens`. Deliberately NOT
      zone-scaled: that existed because gems inflate with depth, and rebirth
      already paces token supply. Client's gear row joined temper on tokens via
      one `spendsTokens` predicate (it was four separate `kind == "temper"`
      tests). Tutorial step 10 fixed — it taught gems AND said hats go on pets.
- [ ] Hats give **1–2 boosts directly to the player**. Same for pets and faces.
- [x] **Hats are player-only — hats removed from pets.** `p.petHats` is gone, not
      emptied; hats on pets fold into free seats on load. `Verbs.equipPetHat` /
      `unequipPetHat`, `clearGearFromPets` and the pet-hat seat column are all
      removed. Pet rows no longer carry a `hat`, and `Gear.stackPets` takes an
      array of your worn hats rather than two positional args plus the pet's own.
- [x] **Three hat slots, all the player's.** `MineGear.HAT_SLOTS` is the one list
      every reader walks. Tapping a hat fills the seat you are looking at.
- [x] **Two latent bugs fixed on the way.** The load-time slot collapse nil'd every
      slot that was not literally `hat` or `face`, so **`hat2` never survived a
      rejoin**; and Equip Best planned `hat` only, leaving `hat2` holding whatever
      it held. Both came from spelling the seats out by hand.
- [ ] Faces work the same way, with a **bigger effect than hats**.
- [ ] **Hats nerfed substantially.** Re-derive the budget percentages with
      hypothetical tests, not guesses: test each boost alone, then stacked with its
      amplifiers (blast with blast-radius and blast-damage; zap with zap boosters).
- [ ] Add hats and faces as **chest drops**.
- [x] **Echo is barred as a buff.** Void gear set rolls Gem Find; `NO_ROLL_STATS`
      blocks it on runes; the Demolition rune SET took its stat straight from
      `set.slots`, bypassing that, so slot 2 is Short Fuse. The 14 temperament
      kits carrying it — 5 NAMED for it — are untouched: echo is retired the way
      `autoMine` was, converted to Swing Rate at `ECHO_TO_SWING` in
      `MineServer.boosts`, one site that catches every source. Renaming shipped
      content is an owner call. The 4 chest flagships whose `special` is echo
      keep it; that is a named tool's identity, not a rolled buff.
- [x] **Luck is split into three channels.** Generic `luck` was doing three
      unrelated jobs at once, which is why a hat that wanted to be about one of
      them had to be about all three. Read off its four call sites:
      - it scaled `ORE_CASE_CHANCE` on an ore break → **ore luck** (`oreLuck`)
      - it decided IF a chest spawned, and with `chestLuck` WHICH one →
        **chest + rare-drop luck**, which needed no new stat: that pair already
        was this channel
      - it was stamped onto pack rows as `row.luck`, which siphons that pack's
        card odds when opened → **pack luck** (`packLuck`)
      - **`luck` KEEPS all three as the shared base**, so prestige, VIP, the
        event pass, skills, runes and the Umbra set all behave exactly as before.
        The two new stats are MULTIPLIERS on top of it, so one source can move
        one channel. `Dig.oreLuck` / `Dig.packLuck` are the only readers.
      - `tools/verify/stats.js` slices both helpers out of MineServer verbatim
        and asserts the channels are INDEPENDENT — a property invisible in the
        stat tables.
- [ ] **No GEAR SET rolls the new lucks yet.** All ten sets have an assigned stat
      and Umbra is generic `luck`; pointing three of them at the new channels
      changes three set identities, which is a content call. They are rollable on
      runes (pet pool) now, so they are reachable and testable.

### Pets and boost balance

- [x] **Three pet slots, and no fourth.** `MAX_PET_SLOTS = 3`, equal to
      `STARTER_PET_SLOTS`, which retires the ladder through the clamps that were
      already there. A save that bought its way to eight comes back down on load
      with every pet still owned. Every seat-four surface is closed, not just the
      cap: the gem row, the Robux product, the credits grant, the VIP bump and the
      "Fourth pet seat — VIP unlocks one more team pet" card.
- [x] **VIP's blurb no longer claims an extra pet seat** (three places). It cannot
      deliver one, so it must not say so. **VIP is now one perk lighter — an owner
      call on whether to add a replacement.**
- [x] **Pets follow naturally.** Three causes of the jolt, none of which more
      position smoothing would have fixed: the formation basis was built off raw
      instantaneous velocity (so a strafe jumped every pet sideways by its full
      lateral offset — the spring was chasing a step function); hard thresholds at
      `speed > 1.15` flipped the basis, bob amplitude and bob rate on one frame,
      and strobed when walking right at it; and `pos:Lerp(target, alpha)` has no
      velocity, so it could never overshoot — no wind-up, no follow-through, a
      dead stop. Now: smoothed basis, one continuous `gait` value replacing every
      speed branch, a real damped spring slightly under critical, bob advanced by
      gait rather than wall-clock, and banking into turns.
- [ ] **Far fewer pets grant blast on normal pickaxes.** At current strength this is
      game-breaking and makes every other pet stack pointless.
- [ ] **Fewer pets affect blast radius.**
- [ ] **Nerf zap and blast.**
- [ ] **Almost no effect should do full pickaxe damage** without dedicated amplifiers
      (+blast damage and the like). This is the main lever against builds collapsing
      into one another.
- [ ] Make pet and hat buffs **more easily matchable with setups**.
- [ ] Add **drill-friendly** boosts.
- [ ] **Guardrails** preventing too many boosts overlapping.
- [x] **Not all packs spawn all pets.** `MinePackConfig.cardPoolFor` narrows each
      pack to a contiguous window of its rarity pool, generated from a hash of
      the pack id rather than authored — a hand-written subset per pack goes
      stale the first time a card is added and nobody notices which pet became
      unobtainable. The window SNAPS TO A TILE so two packs cover the pool
      between them; a free offset orphaned a card at pool size 4, which
      `tools/verify/packs.js` caught.

### New build boosts

Each element type gets one of these as its native boost. *The element roster is needed
to finish the mapping.*

User-specified:

- [x] **Earthquake — BUILT.** `Dig.startQuake` + one tick loop. Registry keyed on
      the PART, so "cannot stack" needs no comparison; keyed on the Instance
      rather than a voxel key because a mine reset destroys parts and a stale
      coordinate would name a different rock. 20% and 5 blocks are the owner's
      numbers. **`EARTHQUAKE_SEC = 5` is mine** — a full quake is then 100% of
      one swing over five seconds. Argue with that one.
- [x] **Ricochet — BUILT.** Break-only, and `swingNeighbour` is called directly
      rather than through anything re-entering `procsAt`, so "no chain reactions"
      is enforced by the call rather than by a counter somebody could raise.

Claude-proposed (need sign-off). Chosen to be mostly non-damage so they do not
collide with blast and zap, which is the guardrail asked for:

- [ ] **Fracture** — breaking a block lowers adjacent blocks' *strength* (not HP) by
      X% for N seconds. Interacts with breaking power instead of damage, so it opens
      progression rather than inflating DPS.
- [ ] **Resonance** — consecutive breaks of the *same ore* build a stacking damage
      bonus that resets when a different ore is broken. Rewards deliberate mining.
- [ ] **Siphon** — a break has a chance to yield ore without consuming the block's
      normal drop roll. Pure economy, zero damage overlap.
- [ ] **Permafrost** — damage dealt to a block persists longer before it heals.
      Helps slow/heavy builds without raising peak damage.

## 6.3 P1 — art pipeline

### Charm icons — DRAWN, not yet uploaded

- [x] **164 charm icons generated**, 256×256, one per charm.
      `tools/icons/gen-charm-art.js` draws them; `tools/icons/raster.js` is a
      dependency-free surface + PNG encoder over built-in zlib (no canvas/sharp
      /pngjs here, and the native ones need a toolchain).
- [x] **The read is colour = which ore, glyph = what it does, pips = rarity.**
      82 ore colours × 6 shape glyphs, so an ore's two variants share a colour and
      differ in glyph — exactly how they differ in play. Shape and ore come from
      **running the real MineCharms**, not a JS copy, so the art cannot drift.
- [x] Checked against the extremes: Onyx (15,15,15) is lifted to a readable dark,
      near-white Limestone keeps glyph contrast via a dark pool, band 8 fits all
      eight pips.
- [ ] **UPLOAD THEM AS THE GROUP (35326298)** — §7 rules, and no agent here can
      do it. The PNGs are in `build/charm-icons/` (gitignored; rebuild with
      `node tools/icons/gen-charm-art.js`). Then write
      `build/charm-icons/ids.json` as `{ "<charmId>": <assetId> }` and run
      `node tools/gen-charm-icons.js`, which writes `MineCharmIcons.luau` the
      same way `gen-ore-icons.js` writes the ore one.
- [ ] **Wire `MineCharmIcons.icon(charmId)` into the charm rows** once ids exist.
      Nothing reads it yet.


- [ ] **Ore icons + case art: APPLY, do not process.** The art lives at
      `C:\Users\uybuv\Downloads\oreicons`, is the owner's, and cannot be
      dragged in. Do **not** read or transform those images. Upload per §7 and
      wire the asset ids under `{Ore}` and `{Ore}Case` naming.
- [ ] **Regenerate the block FACE textures procedurally** rather than using the
      supplied images: no shadow, every chunk fully on its own face and never
      across a corner, more visible, and a spectrum of the ore's own colour so
      it reads against same-coloured rock.
- [ ] **PR #2 `ore-face-art` does NOT cover this** — owner checked. Do not merge
      it expecting it to fix the faces.
- [ ] **Ore block textures, rebuilt on canvas.** The supplied images have problems:
  - small specks used as ore chunks
  - chunks half-off the block, so a 6-sided application does not line up
  - a weird little shadow on each chunk
  Requirements: **no shadow**; **every chunk fully on its own face**, never on a
  corner or crossing into a neighbouring block; **more noticeable** overall; and use
  **a spectrum of the ore's colour** so an ore stays visible against a section that
  happens to share its colour.
- [ ] Wire uploaded ids into the real modules (`MineIcons`, pack ART, mesh tables) and
      record them in that feature's handoff file. An uploaded asset nothing references
      is as good as lost.

## 6.4 P2 — after launch

- [ ] 28 legacy packs onto the ore system in `MinePackConfig`: anomaly, apex, ashen,
      cinder, clay, cobalt, crimson, end, heirloom, hopper, iron, loam, magma, night,
      omen, shadow, shiny, slate, void, plus the gear/rune/fossil families.
- [ ] Luck → Treasure Hunter refactor. 47 `luck` references. Names floated: Divining
      Rod, Loadstone, Assayer's Eye. Overlaps with the luck split in P1.
- [ ] Zone-1 case rates lower. `MineZonePacks.cardOdds(zoneIndex, heat)` takes the
      zone index and ignores it.
- [ ] Chests spawn everywhere but supremely rare, like ore.
- [ ] Space ores (40, separate set) — spec in `docs/ore-remake.md`, unapplied.
- [ ] Tool generator LOOKS table needs the live roster.
- [ ] Export `OreShapes` and other place-only instances to `.rbxm`.
- [ ] Delete the duplicate Event Horizon pet module (34 KB that never loads).
- [x] **Coin shop moved to the second line**, reachable from the Forge header.
- [ ] **Decide whether the coin shop survives at all.** Kept and working for
      now; flagged for possible removal. Do not polish it before that call.
- [ ] Event Horizon `minRebirth` is 0 while its surface is 1.30e9 HP.

## 6.5 Deferred, with a reason

- [ ] **1.5× per 25 layers HP curve.** Not applied. Makes L4921 1.4e23× harder and
      breaks every hand-tuned chest and fossil tool. **Breaking power may remove the
      need for this entirely** — decide before spending time on it.
- [ ] **Chests → packs only.** Superseded by the chest table rework and by skins and
      hats moving into chests.

---

# 6.6 LONG-GAME ROADMAP — owner asked for it, 2026-10-04

> *"we need to make packs funner, and adjust the game to be fun long term, with
> a roadmap for first 1-15 mins, 15-1h, 1h-2h 3-4h 4-6h 6-12h 12-24 24-48-96 etc"*

**This is a PROPOSAL and nothing here is built.** It is written as bands because
that is how it was asked for, and because the honest question at every band is
the same one: *what is the player reaching for in the next ten minutes, and can
they see it?* A band with no visible next thing is where people quit.

What the game currently HAS at each band is marked ✅; what is missing is the
work.

| band | what it should feel like | has | missing |
|---|---|---|---|
| **0–15 min** | Break rock, watch numbers move, forge your FIRST tool. | ✅ wooden pick, coin ladder, ore drops | First forge is ~30 blocks of one ore — needs a playtest. Tutorial hands over the stone pick ✅ |
| **15 min–1 h** | First real choice: which ore, which family. First pack. First trait. | ✅ Forge, packs, Traits tab | Nothing teaches that traits exist. A first free trait roll would do it |
| **1–2 h** | A build starts to exist. First charm, first skin, a second tool family. | ✅ charms, skins, 3 families | The three systems never meet on one screen |
| **2–4 h** | First rebirth in sight. The skill tree opens and a road gets picked. | ✅ 10 roads, 75 nodes | No in-game explanation of what a road DOES before you buy into it |
| **4–6 h** | Rebirth. Tokens. The tree starts paying. Deeper zones. | ✅ rebirth, tokens, zones | ~~SHIP BLOCKER~~ seam purchase is wired (corrected 2026-10-05); confirm in-game |
| **6–12 h** | Chasing a specific tier of ore for a specific tool. Trait rerolling. | ✅ 82 ores, trait gacha | 1-in-1000 Exotic with no pity and no collection view |
| **12–24 h** | Second and third rebirth. A second road. Deep ore. | ✅ | Nothing marks "you have seen everything in this band" |
| **24–48 h** | Mastery: the right trait on the right ore on the right family. | partial | No endgame goal that is not just a bigger number |
| **48–96 h+** | Social, trading, leaderboards, prestige identity. | ✅ trading | No leaderboard, no prestige cosmetic, no reason to be seen |

**The three biggest holes, in order:**

1. **The seam blocker (4–6 h).** Nothing else on this list matters if everyone
   stops at layer 500. See `docs/BLOCKED.md` item 10.
2. **Nothing teaches the systems (15 min – 2 h).** The Forge, traits, charms and
   skins all exist and none of them announces itself.
3. **No endgame that is not a bigger number (24 h+).** Needs an owner decision
   about what mastery looks like.

## Making packs funner

Current: you open a pack, cards come out, the rare ones get a tap-through. The
ceremony is good. What is thin:

- **No pity.** A 1-in-400 chase with no floor is the single most common reason
  people put a game down. A counter that guarantees the band after N opens costs
  very little and changes how the whole loop feels.
- **No collection pressure.** Duplicates roll at `DUPE_DROP_WEIGHT = 0.25` so
  collection leads, but nothing shows you *what you are missing* at the moment
  you open.
- **Open-all is a summary screen.** It skips the filler and tap-throughs the
  hits, which is right — but a 50-pack run ends on a static list. It should end
  on what CHANGED: new cards, completed sets, a better pull than last time.
- **Every pack feels the same.** `MinePackConfig.cardPoolFor` already gives each
  pack a subset of the pool; nothing on the tile says so.

None of this is started. All of it is cheap next to the roadmap holes above.

# 7. Asset upload rules (group-owned game)

**Owner context:** the experience is owned by the **Mine For Cards group,
`groupId = 35326298`**, not the personal iPressBars account. Every new image, mesh,
model, audio and decal must be created **as the group**, so assets stay with the game
and do not land in a personal inventory nobody else can manage.

**Do**

- **Open the correct place first.** Edit the live group experience in Studio (place
  `73982848847016`). Asset Manager uploads go to whoever owns the open game.
- **Set Creator = group on every upload.**
  - Asset Manager → Import, with the group place open (preferred for images/audio/meshes)
  - 3D Importer: enable Upload to Roblox, set Creator to Mine For Cards, enable Add to
    Workspace if the place must use a private asset
  - Open Cloud / API: `creationContext.creator.groupId = "35326298"` — never `userId`
    for production assets
  - The API key must be a **group** key with create/configure development items
- **Keep assets in group / experience inventory.** Prefer Asset Manager under the open
  game, or Group Inventories → Mine For Cards. Roblox **cannot move assets between
  user and group inventories**, so uploading to My Inventory "for now" is permanent.
- **Avoid collisions.** Unique prefixed names: `mfc_<feature>_<name>_vN`
  (e.g. `mfc_pack_loam_v2`, `mfc_tool_ironvine_mesh`). Folders by feature under group
  inventory (`packs/`, `tools/`, `ui/`, `audio/`). Version the name or replace the id
  in code; do not re-upload the same file under a new generic name.
- **In code use stable `rbxassetid://…`**, not `rbxgameasset://…` unless you accept
  place-local name coupling.
- **Wire ids into config.** After upload and moderation, paste ids into the real
  modules and record them in that feature's handoff json/md.
- **Permissions.** The uploading account needs the group role *Create and configure
  development items*. Private assets used in-place need the experience granted use.

**Don't**

- Upload as iPressBars / personal creator for anything that ships.
- Treat random Creator Store meshes as the long-term source of truth without copying
  into group inventory.
- Reuse another owner's inventory asset as the canonical id without consent.
- Rely on renaming collisions in Asset Manager — names are for humans, `rbxassetid` is
  the real id.

**Verify before shipping**

1. Asset Manager filtered to group Mine For Cards: the new asset is listed and its
   creator is the group.
2. The id loads in-game in a fresh session.
3. Code references the new `rbxassetid://…`, not an old personal upload.

**If using Studio MCP `upload_image`:** it uploads through the logged-in Studio
session and open place. Confirm the open place is the group experience *before*
uploading, and confirm afterwards that returned ids appear under group/universe
inventory. **If creator shows as iPressBars, stop and re-upload with
Creator = Mine For Cards.** Do not ship personal-owned ids.

---

# 8. Done

**A merge had silently broken forging, and nothing noticed for four commits
(2026-10-03):**

- [x] **`c59bec5` took main's `MineConfig` wholesale and dropped ~13 symbols
      while every caller stayed.** Luau parses a missing field happily, so
      `syntax.sh` saw nothing and the failures waited for runtime.
      `C.toolBreakingPower` is called on EVERY tool grant, `C.toolCraftCost` on
      every craft, `C.woodPickCoinCost` is the starter's whole coin ladder, and
      `C.WOOD_PICK_MAX_LEVEL` was compared with `>=` so nil threw. Forging,
      crafting and handing out a tool were all dead on this branch.
- [x] **`ORE_MIGRATION_V2` was the quiet one.** The lookup came back nil, the
      `type(map) == "table"` guard skipped the whole 121 → 82 remap, and the
      stamp at the bottom still wrote `p.oreRosterV = 2` — so it marked itself
      complete having moved nothing, once, permanently, per save.
- [x] **Restored from `c59bec5^1`, not reinvented**, and checked against the
      roster that actually shipped: all 39 v2 targets exist in the current
      `ORES`, no source id is a live ore, every v1 target lives or chains.
- [x] **`tools/verify/config-refs.js` is the guard.** Every `MineConfig` symbol a
      LIVE module reads must exist; modules nothing requires are a note, not a
      failure. Against the broken config it reports 11 and exits 1.
- [x] **The TODO had claimed both the breaking-power config and the tutorial pick
      as shipped while the code was absent.** Corrected.

**Boosts, the tutorial and the ore tools (2026-10-03):**

- [x] Tutorial graduation, hats on rebirth tokens, Echo barred, Earthquake,
      Ricochet, per-pack pet subsets — see §6.1/§6.2 for each.
- [x] **Ore tools stopped being "one flat colour, 82 times".** No mesh is named
      after an ore, so every forged tool took the procedural path, and those
      builders colour from an eight-step ramp indexed by a COSMETIC shop rung.
      `ToolModelFactory.oreLook` drives colour, haft, material, gleam and
      silhouette off the ore row instead. **The authored glow wins:** 27 rows
      carry a hand-picked `glow`, and deriving one instead got Phosphorus
      (green glow, pale yellow rock) wrong in the one way a player notices.
- [x] **`MineBigNum` has a caller, and did not do four significant figures.** It
      floored to one decimal flat, so 1234 read `1.2 K`. Fixed, then wired into
      `Verbs._benchNum`; `tools/verify/bignum.js` pins it against
      `MineAbbrev.currency` below 10^63.
- [x] **Five new behavioural checks**, each written after a real bug:
      `config-refs` (missing config symbols), `stats` (a stat with no
      `emptyBoosts` key is a silent no-op), `bignum`, `oretools`, and the pack
      subset assertions in `packs`. Three of them also had their own exit-code
      bug fixed: they printed "N FAILED" and then "all assertions passed" in the
      same run.


**The fossil modules deleted (2026-10-02):**

- [x] **`MineFossils` and `MineFossilEconomy` are gone from disk.** Owner call: the
      migration window closes now. They had been kept dormant for one reason — the
      retirement payout had to use the game's own prices — so the payout came first:
      it was a **formula, not authored data** (`gemMin = zi x band`, `gemMax` a
      multiple of it, graded by layer and quality), plus 6 legacy ids that predate
      the `pair_<name>_<band>_<slot>` scheme. That is ~35 lines, now frozen into
      `FossilPay` in MineServer, and `retireFossils` requires nothing.
- [x] **Every dependent stripped**, not stubbed: the legacy fossil PACK prices
      through `FossilPay`, three client loot-card branches are gone, `fossilItem`
      (57 lines) and its call site are out of `MineLootPacks` and `"fossil"` is no
      longer an equipment kind, and the zone map lost its fossil section with
      `fossilsForZone` / `ownsFossil`. No `require` of either module remains.
- [x] **Fitting the payout back in cost a refactor.** Self-contained `retireFossils`
      pushed MineServer to **205 top-level locals**, past Luau's hard 200 — eight
      of them collapsed into the one `FossilPay` table, back to 198.
- [x] **The one consequence, stated plainly:** `FossilPay` is the last fossil code
      in the repo and is itself deletable later. Deleting it costs exactly one
      thing — a player who has not logged in since retirement keeps their pieces as
      dead state instead of gems.

**And then the rest of the fossils, which were still live (2026-10-02):**

Deleting the modules turned up a much larger surface than the modules. These were
not dormant — they were reachable:

- [x] **Fossil PACKS were still obtainable.** `MineZonePacks` authored three of
      every zone's eight slots (33 registered packs) and ~37 chest loot entries
      dropped them. Gone: the slots, the `SLOT_META` rows, `fossilOdds`, the
      `SLOT_ALIAS` table, the three `Mine1PacksData` rows, seven `PACK_PRICE` /
      `CREDIT_PRICE` entries, the `DUST_EXCLUDE` row, three `MinePackFX` art rows
      and their lookup, and the five `MineTradeValue` dust rows.
- [x] **Chest loot kept its shape.** Each fossil slot was REPLACED, not dropped —
      removing them would have left chests like Rootbox and Hillock with a single
      pack slot. Each became the same-band card pack at the same chance, stepping
      up the ladder when that slot was already present, so no chest lost a slot
      and none rolls the same slot twice.
- [x] **A "Fossils" tab in the trade window.** A whole trade kind, server and
      client, over `p.fossilPieces` which is always nil now. Gone from
      `TradeService` (KINDS, the offer/view/items skeletons, sanitise, peek,
      take, remove, append, the log line) and `MineTradeView` (the tab, the
      stack key, the rarity ink, the rank, the inspector lines).
- [x] **The Fossil Bench PANEL in MineClient.** Already reduced to a notice, kept
      against a stale waypoint. Nothing routes to it (the plaza station is gone,
      and the router no-ops on an unknown key), so it went with its refresh
      function, `countFossilPieces`, the WIDE entry and the `RETIRED` station
      label.
- [x] **Fossil tools in two more screens.** `MineSocketsView` and `MineRunesView`
      both listed them as rune targets (`onSocketFossilTool`), `MineRunes`
      counted their runes as busy, and `MineInventoryView` had a whole fourth
      equip source for them (tiles, temper text, equip call, sell confirm).
- [x] **Dead server plumbing.** The legacy-pack open branch (51 lines), the
      `kind ~= "fossil"` spawn guards, the `PROC_SKIP` entry, the intro-chest
      guard, the `setName` map row, the pack-luck guard and two unused
      `fossilId` locals. `MineConfig` lost `BLOCKS.fossil`,
      `FOSSIL_LAYER_CHANCE` and the `fossilTools` bag field — and the
      unknown-kind fallback `C.BLOCKS[kind] or C.BLOCKS.fossil` had to become
      `C.BLOCKS.dirt` first, or an unrecognised kind would have thrown.
- [x] **Found a real bug on the way: the event pass had an impossible quest.**
      Its last quest, "Find a fossil pack in the event mine", read stat
      `fossils` — which has **no writer anywhere** — and the chest roller
      excluded Event Horizon from fossil packs regardless. The top 30 xp of the
      track was unreachable. It is a depth step now, on a stat the server
      actually bumps, keeping the id so `questIndex` does not shift for anyone
      part-way through.
- [x] **Player-facing text that promised fossils.** The `depth1k` quest tip
      ("Fossils become forever tools"), the Pulverizer stat description, the bag
      refusal toast ("crafted on the fossil track"), and the "Fossil Bed" block,
      renamed to "Pressed Bed" with its id kept because saves carry it.
- [x] **`tools/verify/packs.js`, a new behavioural check.** Grep can prove a word
      is absent; it cannot prove 89 chest tables still line up after three of
      eight slots were removed. This RUNS the real `MineZonePacks` and
      `MineZoneChests` and asserts no fossil pack is registered, 11 zones × 5
      slots = 55 packs, every chest names a known slot with no duplicates and
      offers at least one pack, and every rolled id resolves.

**Fossils retired + charms given shapes (2026-10-02):**

- [x] **Fossils are gone** (§0.12). Generation, the break branch, the three
      fossil packs, the three bench verbs, the plaza station, the client panel and
      every dead state read. `reconcileFossilIds` became `retireFossils`, which
      **cashes out pieces and tools once at the game's own price** and tells the
      player — nobody loses a bank they spent hours on. A legacy fossil PACK cashes
      out the same way when opened rather than opening into nothing.
- [x] **Tutorial step 15 repurposed to the ore pouch**, not deleted: `introAdvance`
      walks the steps by NUMBER, so removing 15 would strand every player sitting
      on it.
- [x] **Charms given five shapes** (see §6.1 Charms). Later is better without
      "bigger number is better".
- [x] **Checked that skins are already the other pillar** and left them alone.
      Tempers run +45% (F) to **+750%** (SSS) on a primary, so the two are in the
      same league — and the contrast is right: charms progress with depth, skins
      are the chase (SSS is 0.02%). No magnitude change needed, so none made.
- [x] **`tools/verify/charms.js` is a behavioural check, not another syntax one.**
      It RUNS the real generator against the real roster under a small Roblox stub
      and asserts 21 properties — one charm per ore, every shape used, 48 (shape,
      stat) families, no penalty at or past −100%, no banned stat, conditionals
      paying nothing while unmet, and a ramp that is cold at zero stacks, scales
      with them, expires, and cannot be faked forward with a future timestamp.
      Worth building because the alternative was re-deriving the expected roster in
      Python, which only proves Python agrees with my intent.
- [x] **Switched to a real Luau parser for validation.** `tools/verify/luau-balance.js`
      is a brace-counting heuristic; `luau-analyze` actually parses. Worth it for
      surgery this structural — all 206 files verified, and one of my own
      brace-counting scripts had already aborted mid-batch and silently written
      nothing. **Worth committing a wrapper for this.**

**Earlier batch (ore case correction, charm roster, pouch, hats, pet slots, pet motion):**

- [x] **Ore case rebuilt to the user's correction** — 2% drop, and opening it pays a
      guaranteed skin or charm. The tool roll and the ore consolation are gone.
      `ORE_CASE_CHARM_SHARE = 0.25` ties the 2% and the 0.5% charm rate into one
      number instead of two that must be kept in step.
- [x] **82 ore charms**, generated from the roster, one per ore, with
      `MineCharms.oreCharm(oreId)` as the only accessor.
- [x] **The ore pouch**, end to end: `MineOrePouch.luau`, `MineOrePouchView.luau`,
      a shop tab, `Dig.addOre` as the single way in, four server verbs, rebirth
      carry, per-ore locks, and Sell All behind a server-priced confirmation.
      Rung prices derived from the value curve after a flat table proved wrong by
      eight orders of magnitude.
- [x] **Hats are the player's, three seats**; pet hats removed entirely. Fixed two
      latent bugs: `hat2` never surviving a rejoin, and Equip Best ignoring it.
- [x] **Three pet slots, no fourth**, every purchase surface closed, VIP copy
      corrected.
- [x] **Pet follow rewritten** — smoothed basis, continuous gait, real damped
      spring, gait-driven bob, banking.
- [x] **Five currency formatters** routed through `MineAbbrev.currency` (server
      `_benchNum`, Forge, bench view, leaderboard). Each rounded (a price quoting
      lower than it charges), showed 2–3 significant figures against the rule's
      four, and ran out of suffixes between a billion and a trillion — which ore
      values pass well before the end of the ladder.

**Earlier:**

- [x] `docs/ore-remake.md` replaced with the roster generated from
      `MineConfig.ORES`; LOOKS/glow block, Space set and change log preserved
- [x] `docs/TODO.md` rebuilt as this handoff
- [x] **Forge, first slice.** `MineForge.luau` (view), `MineConfig.toolCraftCost`
      / `woodPickCoinCost` / `isCoinTool`, server `Verbs.craftOreTool` and
      `Verbs._upgradeCoinTool`, `craftOreTool` dispatch, client
      `onCraftOreTool`, and the ShopView mount swapped from `MineBenchView` to
      `MineForge`. The wooden pickaxe is the only tool that levels on coins
      (cap 25); every other tool levels on its own ore plus stardust.
- [x] Removed the two outdated "ore cannot build a tool" claims
      (`MineZonePacks.luau`, `MineServer.server.luau`). Grep for the phrasings
      now returns nothing.
- [x] `rokit.toml` pins `rojo-rbx/rojo@7.7.0` (it previously pinned nothing, so
      `rokit install` was a no-op)
- [x] `.vscode/` — Rojo + Luau LSP + StyLua recommendations, sourcemap autogeneration,
      tasks for serve / sourcemap watch / place build / both syncback steps
- [x] `docs/rojo-connect.md` — the safe-connect runbook and loss matrix
- [x] `.claude/settings.json` — `bypassPermissions` with a deny list that blocks
      `.rbxm` hand-edits, place files, the export inbox, history-rewriting git and
      credential paths
- [x] Shop stage goes full screen (visual pass still unrun)
- [x] Blacksmith bench verbs — upgrade and recycle, uid-keyed so a reordered bag
      cannot upgrade the wrong tool. Proven over 550 levels.
- [x] Every owned instance carries a uid. Quantity maps (charms, tempers, eventTools,
      ores, tools) deliberately keep counts — instancing them would grow the save.
- [x] Echo stripped from every pet, all 140 kept (45 main + 12 Event Horizon)
- [x] Ore art ships as packed pixels; 30 hand-made face tiles mapped across the roster
- [x] Ore roster remake with a save migration; 14 renames regenerated
- [x] Chest tables redone: hats and charms in, gems out
- [x] Blacksmith upgrade model: per-tool 1–1000 scale, flat 50% recycle
- [x] Wormhole bag autosell + live-ticking timers
- [x] Client-killer audio bug (`CompressorSoundEffect.Gain` doesn't exist)
- [x] Item bag: 500 base, +100 a rung, gems `100 × 1.08^x`, `0/500` readout
- [x] First pickaxe free from the Blacksmith, "Wooden Pickaxe"
- [x] Ore spawn curve tuned to the rarity targets; Ore Finder enchant
- [x] Depth: L4921 flatline removed, Big Bang unpinned to zone index 11
- [x] Upgrade calculator: tools, costs, recycle, drops, rebirth, zones panel

---

# 9. Standing rules

- **No pity systems.** No floors, no guarantees after N.
- **Don't cripple the datastore.** Ore ids are load-bearing twice — `p.ores[id]` is
  banked material and packs are `<id>_ore_pack`. Any roster change needs an id→id
  migration keeping old ids as aliases. The ore-drops-ore change is exactly this.
- **No limits on the upside.** Infinitely lucky is the point.
- **Server decides, client displays.** Craft, upgrade, rune bind, skin apply, sell-all
  and the breaking-power gate all validate server-side. A modified client gains
  nothing but a wrong picture.
- **Breaking power is not damage.** Say so wherever both appear.
- **Gem sinks are zones, runes and the ore pouch.** Gems come from selling ore. Do not
  move zones off gems.
- **Echo is not a buff.** It must not appear on hats, pets or anything else.
- **No effect does full pickaxe damage** without its dedicated amplifier.
- **Ore is mined, never bought.** Nothing may let gems buy ore, or ore buy or
  upgrade into better ore. Spending ore on tools is fine; spending anything on ore
  is not.
- **Skin and temper crates cost ore only.**
- **Hat crates do not scale with rebirth.**
- **Uploads are group-owned.** §7 is not optional.
- Studio and Cursor edit these same scripts concurrently. Anchor every edit on unique
  surrounding text, never line numbers alone, and re-read before committing.
- **Kill stale comments on sight.** A comment asserting a contract the design has
  moved past is worse than no comment. If you change a rule, grep for every place
  the old rule is written down and fix them in the same commit.
- **Verify before claiming done.** No playtests — reason from source, run
  `tools/verify/*.js`, paste output.

---

# 10. Open questions

1. **Breaking power — the +15 reach is the owner's instruction. Everything else
   about it is NOT decided.** Tool BP = the tier of the ore it
   is made of. A tool reaches **15 ore tiers above its own**: an ore of tier T is
   mineable by any tool forged from tier >= T-15. Across 82 ores that is ~6
   crafting steps end to end. Block strength stays f(layer, zone) and is a
   separate gate from the ore rule. Still open: the depth band past which each
   enchant stops applying to non-ore rock.
2. ~~**Breaking power — inputs settled, numbers still open.**~~ Tool BP = f(ore the
   tool is made of); block strength = f(layer, zone); ore strength predetermined and
   looser. What is still needed: the actual curve shapes, and the depth band past
   which each enchant stops applying to non-ore rock. Highest-leverage remaining
   unknown — the rest of P0 is paced by these numbers.
2. **Skin cases vs the 82-ore roster.** The old "81 cases" figure almost certainly
   tracked the real ore count. Confirm it is one case per ore at 82.
3. **Recycle bonus curve.** "Decent but not game breaking" needs numbers.
4. **Element roster.** Needed to assign one native build boost per element type.
5. **Rebirth coin value.** Does "rebirth raises coin value / soften zone+depth coin
   multipliers" still apply now that zones stayed on gems?
