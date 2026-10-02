# Progression, builds and currency

Three linked questions: make progression snappy but earned, let players make
builds, and give coins a reason to exist. They are linked because all three are
downstream of one thing — **how wide the power spread is.**

---

## 1. You already have a build system, and it is good

This is the most important finding in this document. `MineSkillData` is not a stat
list; it is a real build tree with real trade-offs:

**10 energies**, each with a primary / secondary / tertiary stat:

| energy | verb | primary | secondary | tertiary |
|---|---|---|---|---|
| Fire | Blast | blastRadius | mineSpeed | swingRate |
| Frost | Endurance | swingRate | dirtBreak | mineSpeed |
| Water | Haul | backpack | walkSpeed | coinBonus |
| Grass | Harvest | oreYield | backpack | dirtBreak |
| Ground | Excavate | dirtBreak | mineSpeed | oreYield |
| Metal | Refine | coinBonus | oreYield | backpack |
| Electric | Zap | zap | swingRate | walkSpeed |
| Crystal | Prospect | rareOre | gemFind | oreYield |
| Shadow | Fortune | luck | chestLuck | rareOre |
| Space | Echo | echo | gemFind | luck |

**85 nodes**, and three separate mechanisms that force choices:

- **5 rival pairs** — `fire/metal`, `frost/electric`, `water/crystal`,
  `grass/shadow`, `ground/space`. You cannot hold both keys.
- **10 XOR roads** — inside each energy, `splitA` and `splitB` share an
  `xorGroup`, so committing to one closes the other.
- **Breadth inflation** — `1 + 0.05 × nodesOwned + 0.015 × totalLevels`. Every
  node you own makes the next one dearer, so sprinkling is punished. The file's
  own comment: *"committing to a road pays better per token than sprinkling roots
  everywhere."*

That is a genuinely good design. **Do not rebuild it.** If players are not making
builds, the tree is not the reason.

### Why it does not feel like it matters

Skill stats are small percentages: `blastRadius 0.0167`, `mineSpeed 0.06`,
`swingRate 0.0286` per level. A committed build is worth maybe **2–4×** across its
stats.

Ore tool power spans **500×** across the roster, and which ore you found is luck,
not a choice.

**A 500× term drowns a 3× term.** No build decision survives contact with that, so
players correctly conclude builds do not matter — and they are right, given the
current numbers. The tree is fine; the thing sitting on top of it is too loud.

**Therefore: builds only become meaningful when the power spread from gear and
tools is narrow enough that a build is a large fraction of your output.** This is
the same conclusion `ORE.md` reaches from the other direction. If ore becomes
identity rather than power, the build tree becomes the differentiator
automatically — you do not have to add anything to it.

Rule of thumb worth holding: **the widest power source should be within about an
order of magnitude of the build's contribution.** If tools span 500× and builds
span 3×, tools are the game and builds are decoration.

---

## 2. Coins: 3 sinks against gems' 8

Here is why mining's currency feels pointless. Every coin sink in the game:

| sink | what it is |
|---|---|
| `MineServer:7603` | buy a shop tool |
| `MineServer:7709` | buy a depth-shop tool |
| `MineServer:8629` | rebirth |

That is all of them. Gems have eight or more (crates, bags, packs, upgrades,
rerolls, lucky-block grades…).

So coins are: tools you buy once per rung, and one button. Everything else in the
game — the pets, the packs, the charms, the rerolls, the interesting decisions —
runs on gems or stardust. **Mining pays in the one currency the game barely
consumes.** That is the whole complaint, and it is structural rather than a matter
of prices being wrong.

### The principle

> A currency needs a sink whose cost scales with the income that produces it.

Coins scale with block HP, which scales `6^(zone−1)` × depth — so coin income grows
astronomically while its three sinks are a one-off tool purchase and a fixed
rebirth fee. Income outruns the sinks by orders of magnitude, so coins inflate into
meaninglessness. Any fix has to give coins a sink that grows with depth, or coins
will always end up worthless by mid-game.

### Candidate coin sinks, judged against the invariants

Each is checked against `GATING.md`'s four questions. The good ones consume coins
without granting compounding power.

| candidate | verdict |
|---|---|
| **Repair / upkeep on tools** | Bad. Punishes play, feels like a tax, and players route around it. |
| **Charm upgrades priced in coins** | Tempting but **no** — `CHARMS.md` requires stardust, because charms boost mining and coins come from mining. Closes a loop. |
| **Rebirth cost, scaled harder** | Already exists. Good, but it is one button; it cannot be the only sink. |
| **Bag / backpack capacity** | Good. Scales naturally with depth, is a comfort purchase, grants no damage. |
| **Depth access — pay coins to open a seam** | **Strong.** It converts coins into the thing the game is missing: a *gate on depth* (`GATING.md`). It scales with depth by construction, and it is a sink that grows exactly as fast as coin income. |
| **Cosmetics — tool skins, trails, nameplates** | Strong. Infinite sink, zero power, and it feeds the collecting goal. |
| **Re-rolling an ore tool's type** | Good. Consumes coins, keeps the ore, gives agency over a random drop. Feeds trading. |
| **Prestige-adjacent conveniences** (faster travel, extra loadout slots) | Good, if they do not grant power. |

The strongest pair is **depth access** and **cosmetics**: one gives coins a
mechanically important job and plugs the ungated-depth hole at the same time; the
other absorbs unlimited surplus without touching balance.

---

## 3. Ores and gems fuelling rebirth

The owner's idea: rebirth costs coins **and** ores **and** gems.

**This is a good instinct and it solves a real problem.** Right now ore is a pure
source — it enters the economy and never leaves except through a 50% recycle that
pawning bypasses (`ECONOMY.md`). Making ore a *rebirth ingredient* gives it a sink
that is large, recurring, and scales with progression. It also gives ore a use that
is not power, which is the direction `ORE.md` wants.

**One caution, and it is the usual one.** Ore → rebirth → prestige → new zone →
deeper rock → more ore is a loop. It is an *acceptable* loop, because the rebirth
cost curve is a hard gate that the loop does not control — unlike the ore-tool
loop, where the reward removed its own brake. But it only stays acceptable while
the cost curve keeps pace. Which brings us to the wall.

### The rebirth wall — already documented in your own code

```lua
rebirthCost(n) = 7500 × 2.08^(n-1)
```

And the comment above it, which is the clearest warning in the codebase:

> *THIS ONLY HOLDS WHILE ZONES KEEP UNLOCKING. Each rebirth up to the last zone
> gate opens a zone whose blocks pay substantially more, and that is what pays for
> a doubling. Past the final zone the only income growth left is prestigeYield —
> `1 + 0.15 × R` — which lifts income about 1.5× over six rebirths while this curve
> lifts cost 81×.*

There are 10 zones, gated at prestige 0–8. **So the last gate is prestige 8, and
rebirth 9 onward runs into a cost curve doubling against income that is nearly
flat.** The comment says what to do: *"If zones stop being added, this curve needs
a knee at the last gate instead."* That knee does not exist yet.

This is the single biggest threat to "snappy but earned" past mid-game, and it is
independent of everything ore-related.

---

## 4. Snappy but earned

These pull in opposite directions, and the resolution is not a middle setting — it
is that they are properties of *different things*.

**Snappy is about frequency and legibility.** Something should change every few
minutes, and the player should be able to name what it was. Ten charm levels at
+20% each are snappy; ninety-nine tool levels at +3.7% are not, even though they
sum to more. Fewer, bigger, nameable steps.

**Earned is about cost and choice.** A step is earned when the player gave up
something to get it — coins they could have spent elsewhere, an XOR road they
closed, a rival key they will never hold. Note that *time* is the weakest form of
earned: grinding a fixed number is a toll, not a decision.

So the shape to aim for:

- **Frequent small steps** that are *bought*, not waited for. A coin sink you visit
  often (bag space, seam access, a cosmetic) beats a slow accumulation.
- **Rare large steps** that are *chosen* — a rival key, an XOR road, which charm to
  pour stardust into. These are the build, and they should be memorable and
  ideally not freely reversible.
- **No step that is purely luck and also purely dominant.** Finding an ore is
  currently both, which is why it feels unearned however long it took.

The current failure against this shape, precisely: the biggest power step in the
game (which ore you found, 500×) is pure luck and costs nothing, while the steps
that *are* chosen and paid for (build roads, 3×) are too small to feel. Snappy and
earned are both broken by the same imbalance, and both are fixed by narrowing the
tool spread.

---

## 5. Zones are coin-based — and there are two clocks, not one

The decision: **opening a zone costs coins.** That is right, and it is the best
available use for the currency mining pays in. But it only works if you hold two
separate clocks in your head, because the owner's two statements are about
different ones:

> first zone should be like 25-30 mins
>
> but depth is another story, because there's still 10 more zones to explore

| clock | axis | how long | what it costs | how many purchases |
|---|---|---|---|---|
| **Horizontal** | zones | 25–30 min per rung, ~7 h total | coins | **9, ever** |
| **Vertical** | depth / seams | open-ended, forever | coins | hundreds, recurring |

**Zone unlocks cannot be the coin sink.** Nine one-time purchases is a pacing
device, not an economy — once you own Primordium, that sink is gone permanently
and coins go back to being worthless. The recurring sink has to be **seam
access** (§2), which is per-zone, repeats hundreds of times, and never runs out.
Design them together: zones pace the first seven hours, seams absorb coins for
the rest of the game's life.

### Price gates in minutes of local income, never in coins

This is the one technique that makes the whole ladder hold. A fixed coin formula
cannot keep its feel, because income climbs 5× per zone while any formula you
write climbs at its own rate. Concretely, `10,000 × 5^(zone−2)` looks
zone-aware and still fails:

| unlock | cost | = how long to earn |
|---|---|---|
| zone 2 | 10,000 | 13.3 min |
| zone 5 | 1,250,000 | 13.3 min |
| zone 10 | 3,906,250,000 | 13.3 min |

That one happens to work because it was *built* from the income curve. Change
`ZONE_COIN_STEP`, or change how fast players break blocks, and every rung drifts
at once. So do not store the coins. **Store the minutes, and derive the coins
from the income rate.** The unit is then income itself, and the ladder
self-corrects when anything upstream moves.

Note how this differs from the mistake in `POSTMORTEM.md`. That was pricing a
*ceiling* in hours — "level 100 should take 40 hours" — which is the wrong
problem because nobody is meant to arrive there. This is pricing a *gate* in
minutes of the income you have *at that moment*, so every rung feels the same
whether it is your first hour or your hundredth.

### The ladder, from the 25–30 minute anchor

At 1 coin per block, `ZONE_COIN_STEP = 5`, and a steady ~2,000 blocks/hour:

| open | minutes of local income | cost |
|---|---|---|
| Sunscar | 27 | 900 |
| Mistreef | 30 | 5,000 |
| Arcwork | 33 | 28,000 |
| Bloodmoon | 36 | 150,000 |
| Eclipse | 40 | 830,000 |
| Riftmarch | 44 | 4,600,000 |
| Starfall | 48 | 25,000,000 |
| Mythral | 52 | 140,000,000 |
| Primordium | 56 | 730,000,000 |

~7 hours of horizontal play, rungs lengthening gently so the last zone feels
like an arrival without any single rung becoming a wall. These are *derived*
numbers — re-derive them, do not copy them, if the block rate changes.

**Keep the prestige requirement as well.** Coins should be the immediate cost and
prestige the ceiling on which zones exist for you at all. Coins alone would make
the only hard gate in the game buyable, and `GATING.md` is about not having that
happen twice. But see the collision below: prestige 1 currently costs 7,500
coins, which under the flat rate is **17.5 hours**, so the gate that is supposed
to take 27 minutes is behind one that takes most of a day.

### Under "1 block = 1 coin", coins/hour *is* blocks/hour

Worth stating plainly, because it is the best property this change buys. With no
depth term and no HP term, a player's coin income is literally their block-break
rate times `5^(zone−1)`. The entire coin economy becomes readable off one number
that players can feel directly, and the sign at the zone mouth —
`1× block ⟶ 1× coin` — is not a simplification, it is the actual rule.

Protect that. The moment anything multiplies the payout by HP, depth, or a
stacking bonus, the sign starts lying and the inflation comes straight back.

### The depth collapse — the thing to fix before shipping this

A flat payout against rising block HP means **descending makes you poorer.**
Same pickaxe, one zone, Meadow top to bottom:

| depth | block HP | coins/hour |
|---|---|---|
| L1–40 | 20 | 1,286 |
| L81–120 | 94 | 274 |
| L161–200 | 434 | 59 |
| L241–280 | 2,008 | 13 |
| L281–320 | 4,318 | **6** |

Block HP rises ×432 across Meadow while the payout stays at 1, so going deep
costs you **99.5% of your income.** Depth is meant to be the forever-track with
ten zones of it, and as specified it is a pure penalty — no player will choose
it, and the vertical clock never starts.

**The fix is not a depth coin bonus.** That was the old system and it is what
produced the astronomical numbers. The fix is:

> **Blocks per hour must stay roughly flat as you descend.** Tool power has to
> climb with depth at the same rate block HP does — ×216 across Meadow — so the
> break rate holds, income holds, and depth is income-*neutral* rather than
> income-positive or income-negative.

Then the two axes have clean, separate jobs:

- **Zones (horizontal) pay coins.** 5× per zone.
- **Depth (vertical) pays ore quality, access, and a coarse coin band.** See §6
  — depth carries a *linear* coin term in 500-layer bands, not an HP term.

That split is what makes "depth is another story" true in the code and not just
in intent, and it is the same conclusion `ORE.md` reaches: ore belongs to depth,
money belongs to breadth.

### Consequence: every existing coin price is now wrong

This is not optional follow-up work — it ships with the change or the early game
is unplayable. Prices were calibrated against HP-based income, where a deep
Meadow block paid 4,318. Against flat income they are off by orders of magnitude:

| price | coins | = hours of starter income (429/h) |
|---|---|---|
| Stone Pickaxe | 250 | 0.6 |
| Iron Pickaxe | 900 | 2.1 |
| Crystal Pickaxe | 2,800 | 6.5 |
| Void Pickaxe | 8,000 | 18.7 |
| **rebirth 1** | **7,500** | **17.5** |

A first rebirth at 17.5 hours against a first zone at 27 minutes is the whole
problem in one line. Rebirth 1 wants to land in the same 25–30 minute band as
the first zone unlock — a few hundred coins, not 7,500 — and `REBIRTH_BASE`
plus the shop ladder both need re-deriving from block rate the same way the zone
ladder above was.

**Checklist for this change:**

- [ ] Zone unlock costs derived from minutes of local income, not hardcoded.
- [ ] Seam access exists as the recurring sink before zone unlocks are the only one.
- [ ] Blocks/hour measured at the top and bottom of a zone, and within ~2× of each other.
- [ ] `REBIRTH_BASE` and every shop price re-derived against flat income.
- [ ] Prestige requirements kept, and none of them gated behind a longer clock than the coin cost.
- [ ] Payout multiplied by nothing except `coinBonus` and `zoneCoinRate`.
---

## 6. The depth-band value equation

The request: one equation for what dirt is worth at sub-500, sub-1000, sub-1500
and so on; the same formula in every zone; and **it must never soften up on
players.** All three are satisfiable, and the third one is what pins the shape.

### The equation

```
band(L)      = floor((L - 1) / 500)
value(Z, L)  = 5^(Z-1)  ×  (1 + band(L))
                └ zone ┘    └── depth ──┘
```

**Linear in depth.** One extra coin per 500-layer band, forever. Layer 1 pays
×1, layer 501 pays ×2, layer 2001 pays ×5, layer 10001 pays ×21. No exponent on
the depth term — the only power in the formula is the 5×-per-zone step that was
asked for explicitly.

| layer | band | depth mult | Meadow | Bloodmoon | Primordium |
|---|---|---|---|---|---|
| 1–500 | 0 | ×1 | 1 | 625 | 1,953,125 |
| 501–1000 | 1 | ×2 | 2 | 1,250 | 3,906,250 |
| 1001–1500 | 2 | ×3 | 3 | 1,875 | 5,859,375 |
| 1501–2000 | 3 | ×4 | 4 | 2,500 | 7,812,500 |
| 2001–2500 | 4 | ×5 | 5 | 3,125 | 9,765,625 |
| 4501–5000 | 9 | ×10 | 10 | 6,250 | 19,531,250 |

**Every zone uses it identically** — the zone term is a pure multiplying factor,
so the depth profile is `1×, 2×, 3×, 4×, 5×…` in Meadow and in Primordium alike.
That is a property of the form, not something to maintain by hand.

### Why linear, and why that is the safe choice

Because the coin side must never be the thing that explodes. Across 10,000
layers this formula grows the payout **×21**, while block HP over the same span
grows by something like 10⁸⁰. Whatever else goes wrong, it will not be the coin
value — and `NUMBERS.md`'s 2⁵³ problem stays a block-HP problem rather than
becoming a currency problem too.

### "Never softens": the test, and the result

Softening means the reward growing faster than the effort to earn it. The
measurable form is **coins per point of block HP, which must never increase with
depth.** It does not:

| layer | coins per HP |
|---|---|
| 1 | 5.00e-02 |
| 501 | 9.96e-06 |
| 1001 | 6.91e-10 |
| 2001 | 5.31e-18 |
| 5001 | 1.14e-42 |

Monotonically falling, by a wide margin, at every depth. The formula gets
*harsher* per unit of work the whole way down. Requirement met.

### One real exception, and it is bounded

**Block HP changes every 40 layers; the band changes every 500.** So at the exact
boundary layer, the block is identical and the payout jumps:

| boundary | free multiplier |
|---|---|
| L500 → L501 | ×2.00 |
| L1000 → L1001 | ×1.50 |
| L1500 → L1501 | ×1.33 |
| L10000 → L10001 | ×1.05 |

That is a genuine local softening — do not pretend otherwise. It is bounded and
self-correcting: the step shrinks at every band, and descending 40 layers past a
boundary multiplies HP by 2.15 while value holds, so the advantage is gone within
one HP section. The consequence to accept is that the best coins-per-hour spot is
always just past a band boundary, and some players will camp there. If that is not
acceptable, align the band edges to the 40-layer HP sections instead of to round
500s — but then the sign can no longer say "sub 500", so this is a legibility
trade, not a bug to fix.

### The catch: this equation only works with the §5 power fix

The equation alone does **not** make depth worth mining, and it is important to
see why before shipping it. Income is:

```
coins/hour  =  (power / blockHP)  ×  value
               └─ blocks/hour ─┘
```

**With tool power fixed** — the situation today — `blocks/hour` collapses as HP
climbs, and a ×21 linear value term cannot begin to offset a 10⁸⁰ HP term.
Meadow coins/hour goes 1,286 at the surface to effectively zero by layer 500. The
bands would be decoration on a cliff.

**With tool power tracking block HP** (§5's requirement), `blocks/hour` holds
steady, and then:

| depth | band | coins/hour |
|---|---|---|
| L1 | 0 | 2,000 |
| L501 | 1 | 4,000 |
| L1001 | 2 | 6,000 |
| L2001 | 4 | 10,000 |
| L2501 | 5 | 12,000 |

Depth now pays more per hour, linearly, exactly as the bands intend — **while
still paying less per unit of effort.** Those two facts are not in conflict, and
holding both at once is the whole point:

> **Deeper is worth more per hour and worth less per swing.**

That sentence is the design. It rewards the player for descending without ever
making descent the soft option, and it is why the answer needed both halves.

**Therefore: the power curve and the value bands ship together, or neither
ships.** Adding the bands to today's power curve produces a reward players cannot
reach; fixing power without the bands produces depth that pays the same as the
surface. `GATING.md` applies to the pair — power that climbs with depth is power
on the ungated axis, so seam access (§2, §5) has to be the brake.

### Checklist

- [ ] `value(Z,L)` is one function, used by every zone, with no per-zone table.
- [ ] Depth term is linear in `band(L)`; nothing exponentiates it.
- [ ] Coins-per-HP re-measured after any HP-curve change, and still falling.
- [ ] Band edges and the zone-mouth sign agree on what "sub 500" means.
- [ ] Power curve landed first or in the same change, per §5.
- [ ] Seam access gates the depth the power curve now permits.
---

## Reading order for a change in this area

1. `PRINCIPLES.md` §1, §2, §7
2. this file
3. `GATING.md` — especially the depth hole, since the best coin sink fills it
5. §5 and §6 above if you are touching zone unlocks, block value, coin prices or rebirth cost
4. `ECONOMY.md` — the pre-ship checklist
