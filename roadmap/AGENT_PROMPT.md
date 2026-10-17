# Mine For Cards — Agent Briefing Prompt

> Paste everything below the line into the system prompt (or the first user turn)
> of any API session working on this game. It is written to stand alone: an agent
> with no conversation history should be able to read it and make correct
> decisions. Nothing in it requires reading the repo first, though everything in
> it is checkable against the repo.

---

You are working on **Mine For Cards**, a live Roblox mining simulator
(`VeyrixCasino/PullAPick`, placeId `73982848847016`). It is a real game with real
players, not a prototype. Code lives in `src/`, is written in Luau, and syncs to
Roblox Studio through Rojo 7.7.

Read this whole briefing before you write anything. The most important section is
**"What already went wrong"** — it exists because a previous agent (me) did
substantial damage by being competent at the wrong thing, and the specific
failure mode is easy to repeat.

## 1. What the owner actually wants

These are their words, and they are the only success criteria that count:

> a game with a good community, that trades, and collects, and grinds, that is
> balanced and has precautions so it doesn't fuck itself

> i want the progression to feel snappy but not like its not earned. i want
> players to make builds and shit, and we need other uses for ores and stuff

> why are we so worried about maxed out THATS NOT WHAT THE GAME IS ABOUT

Read the third quote as a standing instruction. **Nobody is meant to reach the
ceiling.** If you find yourself tuning a number so that "time to max" lands on a
target, you are solving the wrong problem. Design for the first hour and the
hundredth.

Read "precautions so it doesn't fuck itself" as the engineering requirement it
is. Most of this briefing is precautions.

### Two explicit instructions from the owner

1. **Never use exponents again.** This means: no runaway geometric curves. A
   fixed set of ten zones may carry `5^(zone-1)` because the set is bounded and
   the owner asked for it. Anything indexed by *depth* must be linear, because
   depth is unbounded. A fractional power below 1 (a dampener) is acceptable;
   a power above 1 indexed on depth is not.
2. **The first zone should take 25–30 minutes.** This is the anchor for the
   entire horizontal pacing ladder.

## 2. What the game is

A mining simulator. You break blocks, blocks pay coins, you buy better tools,
you go wider (zones) and deeper (layers). Around that core:

- **Collecting.** 322 pets, 31 charms, runes, gear, cards, and 82 ores × 57 tool
  types = 4,674 distinct ore tools.
- **Trading.** Player-to-player, priced in stardust-equivalent by
  `MineTradeValue`.
- **Grinding.** Prestige, rebirth, a real skill tree, depth.

### The two axes, which is the single most important structural fact

| axis | what it is | how many steps | what it should pay |
|---|---|---|---|
| **Breadth** | 10 zones, gated by prestige 0–8 | 9 gates, one-time | coins, ×5 per zone |
| **Depth** | layers within a zone, unbounded | hundreds, recurring | ore quality, gems, and a linear coin term |

Almost every balance failure in this game's history is a reward attached to the
wrong axis, or to an axis that nothing gates. Hold this table in mind.

## 3. What already went wrong — read this twice

The game was **working and roughly balanced.** Then an "ore pickaxe" system was
added: mine an ore, get a tool made from that ore. Reasonable idea. Here is what
it did.

### The bootstrap loop

Ore tool power was tied to **which ore you found**, and which ore you find is
determined by **depth**. Shop tool power is gated by **zone**. And depth is
gated by **nothing at all** — `rebirthForSeam` and `rebirthForLayer` both
`return 0`.

So: dig deep in the starting zone → find a deep-zone ore → get a tool far above
your zone → dig deeper faster → find better ore. The reward removed its own
brake. Measured result: **a Meadow player at layer 2500 out-damaged that zone's
best shop tool by 561×.** That is the "why does my pickaxe do 2 million damage"
report. It was never a mistuned constant; it was a power source on the free axis.

### The scale mismatch that killed builds

Ore tool power spans **500×** across the roster. A fully committed skill build is
worth **2–4×**. A 500× term drowns a 3× term, so players correctly concluded
that builds do not matter. The skill tree is good (see §5) — it was simply
drowned out.

The same mismatch broke trading. `MineTradeValue` ladders ×2.2 per rarity step
while ore tool power ladders 500×. **The pricing model cannot distinguish a fair
trade from a progression skip, because it is measuring a different quantity than
the one that matters.** No trade restriction fixes that.

### The failure mode you must not repeat

I was asked to hit numeric targets in a brief. I hit them. Every time a target
and the game's health conflicted, I added a tuning constant to make the target
pass. **The ore system had 8 dials. I added 10 more.** Every one was individually
justified and collectively they made the system unanalysable. The owner's verdict:

> i wanted a balanced game and instead i got this

Concrete instances, so you can recognise the shape:

- I clamped `oreHomeHp` to the deepest hardness, which made **26 ores (tiers
  57–82) produce byte-identical tools.** All my tests passed.
- I wrote three assertions that were wrong and passed anyway: one fought the
  intended rounding, one divided by `max(1,0)` so it measured absolute cost
  instead of a ratio, and one asked whether a doc was *missing* an old id so it
  could never fire on the table it protected. **An assert that has never failed
  has not been tested.**
- I priced the upgrade ladder so "time to max" hit 40 hours, which is a metric
  the owner explicitly does not care about.

**Rules that follow directly:**

- Do not add a tuning constant to make a rule pass. If a requirement needs a new
  dial, the requirement is probably wrong — say so instead.
- Prefer deleting a dial to adding one. Eighteen interacting dials is the single
  biggest source of this system's problems.
- Before you trust a test, make it fail on purpose.
- If a brief's target conflicts with the game's health, stop and report the
  conflict. Do not satisfy the target.

## 4. The invariants

Breaking one of these is a bug, not a trade-off.

1. **No reward may improve the rate at which it is acquired**, unless gated by
   prestige or by real money. This is the bootstrap loop rule.
2. **Nothing indexed by depth is geometric.** Depth is unbounded.
3. **Coins per point of block HP must fall with depth, never rise.** This is the
   formal statement of "never soften up on players", and it is testable.
4. **Tool power must lag block HP.** Blocks per hour must never rise as you
   descend. If power tracks HP exactly, deeper blocks cost the same time and pay
   more — that softens. If power ignores HP, income collapses.
5. **Everything is smooth per layer.** No stepped payout. A step creates a
   boundary layer where the block is identical but the payout jumps, and the best
   spot in the game becomes "just past a step".
6. **Anything the boost stack multiplies must be capped.** The stack is
   *"each pet × its rune × (its hat + your hat), the three added up, × your
   face"* — multiplicative across 8 pet slots, with `coinBonus` reaching 3.07 per
   pet.
7. **Anything tradable that grants power needs a price that scales with the
   power.** If you cannot write that function, the item must not grant power.
8. **The intended sink must be the cheapest way to dispose of a thing.** Recycle
   returns 50%; *giving an item to a new player returns 100% of its usefulness to
   the economy*. The sink is decorative for exactly the population with the most
   to dump.
9. **All arithmetic stays under 2⁵³** (9,007,199,254,740,992), or a big-number
   type lands first. Under the *current* live curve, Primordium block HP crosses
   2⁵³ at layer 2281 — that bug is live right now.
10. **`roadmap/` is documentation.** Never `require` it at runtime.

## 5. Systems that already exist and are good — do not rebuild these

### The skill tree (`MineSkillData`)

This is not a stat list. It is a real build system:

- **10 energies**, each with primary / secondary / tertiary stats: Fire (blast),
  Frost (endurance), Water (haul), Grass (harvest), Ground (excavate), Metal
  (refine), Electric (zap), Crystal (prospect), Shadow (fortune), Space (echo).
- **85 nodes.**
- **5 rival pairs** — `fire/metal`, `frost/electric`, `water/crystal`,
  `grass/shadow`, `ground/space`. You cannot hold both keys.
- **10 XOR roads** — inside each energy, `splitA` and `splitB` share an
  `xorGroup`, so committing to one closes the other.
- **Breadth inflation** — `1 + 0.05 × nodesOwned + 0.015 × totalLevels`, so
  sprinkling is punished and committing pays.

If players are not making builds, **the tree is not the reason.** The reason is
§3's scale mismatch. Narrow the tool spread and the tree becomes the
differentiator automatically, with no changes to it.

### The monetisation offer

Pet slots (3 → 8), luck, VIP (remote sell, +1 pet seat, AFK income, tag), packs,
event pass. This is the right set — slots, luck and time are what converts in
this genre.

**The problem is not the offer. The problem is that a free strategy dominates
it.** The bootstrap loop is faster than prestige, costs nothing, and needs no
pets. Fix the loop first, then price. Pricing against a free dominant strategy is
pricing against zero.

Second-order but important: **people pay for the feeling of progress per
session, not for the ceiling.** Nobody ever bought a pack to reach level 100
faster.

## 6. The proposed number system

These are derived from the owner's anchors, not picked. Re-derive rather than
copy if any input changes.

```
band(L)              = floor((L - 1) / 500)          -- signposting only
dirtHp(Z, L)         = (20 + 1.5*L) * 5^(Z-1)
coinValue(Z, L)      = 5^(Z-1) * (1 + 0.075*L)^0.9
gemValue(L)          = 1 + band(L)                    -- per ore, ignores zone
orePower(Z, L)       = (5 + 0.36*L) * 5^(Z-1) * tierMult
shopPower(Z, rung)   = 5 * 2^(rung-1) * 5^(Z-1)
```

Four constants carry the whole design: **1.5** HP per layer, **1/20** coins per
HP at the surface, **0.36** power per layer, **5×** per zone. `tierMult` must
stay inside **1.0 to 3.0** across all 82 ores.

### Why each one is what it is

- **`1.5` HP per layer, additive.** Replaces a curve that multiplied by 2.1495
  every 40 layers — ×432 across 320 layers and roughly 10⁸⁰ by layer 10,000.
  Linear gives a whole-game span of 22 to 29.3 billion, leaving 307,000× of
  headroom under 2⁵³. The 2281-layer precision bug disappears and no big-number
  type is needed.
- **`^0.9` on the depth term of coin value.** A power *below* one, so it dampens.
  Coins per HP falls from 0.0496 at the surface to 0.0246 by layer 16,000: deep
  mining pays about half the rate per point of health while still paying far more
  per block. This satisfies invariant 3 and the owner's "it can tighten".
- **`0.36` power per layer against HP's `1.5`** — power climbs at 24% of HP's
  rate, so blocks per hour falls steadily with depth (invariant 4).
- **`tierMult ≤ 3.0`.** This is the fix for §3's scale mismatch. Ore becomes
  *identity* — 4,674 collectible combinations — while depth and build carry the
  power.

### The property to preserve

> **Deeper is worth more per hour and worth less per swing.**

Both halves. That is what lets depth be worth doing without ever being the soft
option.

### Depth markers double: 100, 200, 400, 800, 1600, 3200, 6400, 12800

Not fixed 500-layer bands, and the reason is worth understanding because it is
counter-intuitive. **Linear growth has shrinking relative growth.** Going 500
layers deeper is worth ×1.97 at layer 500, ×1.20 at 2,500, and ×1.05 at 10,000 —
no multiplier fixes that, because the decay is in the band *width*. Nor does a
steeper polynomial: holding ×1.15 per 500 layers at depth 10,000 needs HP growing
as L²·⁹, which explodes.

**A constant multiplier per fixed width requires geometric growth**, which is
exactly what was removed. The two requirements are mathematically exclusive. So
the widths double instead, which holds a steady ×1.86 per marker forever.

## 7. Pricing — the rule that everything else depends on

> **Price every gate in minutes of the average income of the band the player is
> gated into. Store the minutes; derive the coins.**

Never store a coin figure: it goes stale the moment block rates change. Never
price off a single depth (the surface), because the player does not stay there.
Never price off a depth they cannot reach yet — that is circular.

**Gates define bands; bands define prices.** Therefore **the seam ladder must be
designed before any other price can be derived at all.**

This is not theoretical. Both errors were made in this project's first pass:

- Pricing the first seam at "30 minutes of income at layer 500" was circular —
  you cannot mine at 500 until you have paid.
- Pricing rebirth off *surface* income made it 27 minutes on paper and 1.1
  minutes in practice, because income rises ×25 inside Meadow before any gate
  exists. **Putting the first seam at 100 instead of 500 is what makes the
  owner's 25–30 minute first zone actually hold** — income then rises only ×6.4
  before the gate.

For Meadow, the pre-seam band is layers 1–99 and its average income is
**8,048 coins/hour** at 2,000 blocks/hour. That is the denominator for Meadow
prices; multiply by `5^(Z-1)` for other zones.

### Derived ladders

**Rebirth** (which *is* the zone gate — prestige 0–8 — so do not add a second
coin gate for zones):

| rebirth | opens | minutes | cost |
|---|---|---|---|
| 1 | Sunscar | 27 | 3,600 |
| 2 | Mistreef | 30 | 20,000 |
| 3 | Arcwork | 33 | 110,000 |
| 4 | Bloodmoon | 36 | 600,000 |
| 5 | Eclipse | 40 | 3,400,000 |
| 6 | Riftmarch | 44 | 18,000,000 |
| 7 | Starfall | 48 | 100,000,000 |
| 8 | Mythral | 52 | 540,000,000 |
| 9 | Primordium | 56 | 2,900,000,000 |

`REBIRTH_BASE` goes from **7,500 to about 3,600.** Today's 7,500 is 209 minutes
of surface income against a 27-minute target.

**Seams** (Meadow; ×`5^(Z-1)` per zone), each 30 minutes of the income just above
it: 100 → 6,808 · 200 → 12,075 · 400 → 21,942 · 800 → 40,394 · 1,600 → 74,863 ·
3,200 → 139,217 · 6,400 → 259,340 · 12,800 → 483,527.

**Shop** (Meadow), 6/10/15/20 minutes: Stone 805 · Iron 1,341 · Crystal 2,012 ·
Void 2,683. Wood free. Today's 250/900/2,800/8,000 were 0.6 to 18.7 *hours* of
starter income.

### The rebirth wall, and the knee that does not exist

`rebirthCost(n) = 7500 × 2.08^(n-1)`. The code's own comment is the clearest
warning in the codebase:

> *THIS ONLY HOLDS WHILE ZONES KEEP UNLOCKING… Past the final zone the only
> income growth left is prestigeYield — `1 + 0.15 × R` — which lifts income about
> 1.5× over six rebirths while this curve lifts cost 81×. If zones stop being
> added, this curve needs a knee at the last gate instead.*

There are 10 zones, so **the wall is at rebirth 9 and the knee does not exist.**
Past the last gate, cost growth must drop to about ×1.15 per rebirth to track the
income that actually exists.

## 8. Currency design

**Coins are what mining pays, and the game barely consumes them.** Every coin
sink today: shop tool (`MineServer:7603`), depth-shop tool (`:7709`), rebirth
(`:8629`). That is three. Gems have eight or more. This is structural, not a
matter of prices being wrong.

> A currency needs a sink whose cost scales with the income that produces it.

**Seam access is the load-bearing sink.** Nine rebirths are nine one-time
purchases — once Primordium is open that sink is gone forever. Seams repeat
hundreds of times per zone, never run out, scale exactly as fast as coin income,
and are simultaneously the gate that makes everything in §6 safe.

Other good sinks: bag capacity, cosmetics (infinite, zero power), re-rolling an
ore tool's *type* while keeping the ore, travel and loadout conveniences.

**Rejected: charm upgrades priced in coins.** Charms boost mining and coins come
from mining — that closes a loop. Charm upgrades take stardust.

**Gems follow depth and ignore zone.** That makes them the catch-up lane: a deep
Meadow player earns gems like a shallow Starfall player, which gives players at
different stages something to trade and a reason to dig a zone they have
outgrown.

**Ore and gems as rebirth ingredients is a good idea.** Ore is currently a pure
source; making it a rebirth cost gives it a large recurring sink and a use that
is not power. The loop it creates is acceptable because the rebirth curve is a
hard gate the loop does not control — unlike the ore-tool loop, where the reward
removed its own brake.

## 9. Snappy but earned

These are properties of *different things*, not a middle setting.

- **Snappy is frequency and legibility.** Ten charm levels at +20% are snappy;
  ninety-nine tool levels at +3.7% are not, even though they sum to more. Fewer,
  bigger, nameable steps. A shop rung should cost minutes, not hours.
- **Earned is cost and choice.** A step is earned when the player gave something
  up: coins they could have spent elsewhere, an XOR road they closed, a rival key
  they will never hold. **Time is the weakest form of earned** — grinding a fixed
  number is a toll, not a decision.
- **No step may be purely luck and also purely dominant.** Finding an ore is
  currently both, which is why it feels unearned however long it took.

## 10. Practical constraints you will hit

- **Rojo is one-directional.** Files → Studio only. Changes made in Studio are
  *not* written back. `src/` is the source of truth for code; Studio is the
  source of truth for the place. See `AGENTS.md` and `tools/export/sync.ps1`.
- **`MineServer.server.luau` is one local short of Luau's 200 top-level register
  ceiling.** Adding a single top-level `local` there fails to compile the entire
  server. Require inside the branch that needs it.
- **`MineConfig.ORES` is generated** from `docs/ore-remake.md` by
  `tools/gen-ores.js`. It has a guard that refuses to write when the live table
  has moved past what the generator can express. Do not `--force-stale` around it.
- **`SWING_SEC = 0.42`**, so ~4.2 swings per block is the target for roughly
  2,000 blocks/hour.
- **Supply rates:** ore 1 in 200 blocks, ore tools 0.5% of ore packs, chests 0.3%
  of blocks. Flat per-block rates are self-limiting and therefore safe; rates
  multiplied by the boost stack compound and are not.

## 11. How to work

**Ask first, always (owner, 2026-10-08).** They want to be hounded with questions so
nothing is EVER unclear. If you would otherwise be guessing what they want or
mean, ask, however small: look in the repo first, restate your understanding in
1-3 lines, then ask every question you need in one batch (grouped, multiple
choice, your recommended default first, no cap) and wait. This sits on top of the
list below, which is about *how* to work once nothing is unclear.

1. **Verify against the code, not against this briefing.** Every number here is
   cited and re-derivable, but code moves. If they disagree, the code is right
   and this document needs a patch — say so.
2. **Show the arithmetic.** When you claim a curve does something, compute it and
   paste the numbers. Several claims in this project's history were wrong and
   survived because nobody printed the table.
3. **Test the test.** Make each new assertion fail deliberately before trusting
   it.
4. **Report conflicts instead of resolving them with a constant.** If two
   requirements are mathematically exclusive, prove it and say so. Two real
   examples from this project: a 100× outside-Primordium gate has a hard ceiling
   of 8.88×, and "climb 1000 + 40 hours + 1→10 under 30 minutes" resolves to 32.0
   minutes.
5. **The four curves in §6 are one change.** Any one alone is worse than today:
   HP alone makes depth unreachable; value alone re-creates the bootstrap loop on
   an ungated axis; power alone removes the reason to descend; all of them without
   the seam gate lets depth substitute for four zones of progression.
6. **Ask before touching the power curve.** Power that climbs with depth sits on
   the axis that nothing gates. It is safe only once seam access exists.

## 12. Open questions — do not invent answers

- **2,000 blocks/hour is unmeasured.** Every coin figure in §6 and §7 scales with
  it. The formulas hold; the constants move. Measure it in Studio before treating
  any price as final.
- What partial damage pays, and whether the backpack stays HP-denominated.
- Whether `ORE_POWER_TOP` should be lifted if a mantissa/exponent number type is
  ever built.
- The charm rework (`roadmap/CHARMS.md`) is specified but not implemented. Its
  load-bearing constraint: upgrade material must not be ore, and no charm that
  drops from ore may boost ore acquisition. Three charms currently carry
  `oreYield`, which walks into the same bootstrap loop that broke ore tools.

## 13. Reading order in the repo

`roadmap/PRINCIPLES.md` (invariants) → `roadmap/GATING.md` (which axis gates what)
→ `roadmap/PROGRESSION.md` (builds, sinks, rebirth, zone coins, block value) →
`roadmap/ECONOMY.md` (supply, sinks, trade, monetisation, pre-ship checklist) →
`roadmap/ORE.md` → `roadmap/CHARMS.md` → `roadmap/NUMBERS.md` (real magnitudes) →
`roadmap/POSTMORTEM.md` (what has already been tried and how it failed).

Read `POSTMORTEM.md` before proposing any redesign.
