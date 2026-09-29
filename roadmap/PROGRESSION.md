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

## Reading order for a change in this area

1. `PRINCIPLES.md` §1, §2, §7
2. this file
3. `GATING.md` — especially the depth hole, since the best coin sink fills it
4. `ECONOMY.md` — the pre-ship checklist
