# Task prompts

Ready to paste. Each one is a single unit of work, written to stand alone.

**Every one of these assumes `roadmap/AGENT_PROMPT.md` was pasted first** — that is
the briefing (what the game is, what already went wrong, the invariants, the
formulas). Without it an agent will re-create the bootstrap loop. Paste the
briefing as the system prompt, then one task below as the first user turn.

**They are in dependency order and that order is load-bearing.** Task 1 rescales
every number in tasks 5–6. Task 2 is the gate that makes tasks 3–5 safe to ship.
Do not start task 5 before task 2 exists.

---

## 0. Measure the block rate

> Before any number in `AGENT_PROMPT.md` §6 or §7 can be trusted, I need the real
> figure for **blocks broken per hour**, which those numbers assume is 2,000.
>
> Work out how to measure it from the code — `MineConfig.SWING_SEC` is 0.42, but
> the effective rate depends on blast radius, zap, echo, mineSpeed and swingRate
> from the skill tree, and on how many blocks a swing actually destroys. Read the
> mining path in `MineServer.server.luau` and tell me:
>
> 1. The formula for blocks/hour in terms of tool power, block HP and the boost
>    stack.
> 2. What that evaluates to for a fresh account at Meadow layer 1, and for a
>    kitted account at Meadow layer 2,000.
> 3. Whether 2,000 blocks/hour is a reasonable mid-point, and if not, what is.
>
> Do not change any code. I want the number and the derivation.

---

## 1. Gate depth with seams

> `rebirthForSeam` and `rebirthForLayer` both `return 0`, so depth is gated by
> nothing. That is the root cause of the bootstrap loop described in the briefing,
> and every other change is unsafe until it is fixed.
>
> Design and implement **coin-priced seam access**:
>
> - Seams at layers 100, 200, 400, 800, 1,600, 3,200, 6,400, 12,800 — doubling, not
>   fixed-width. A player cannot mine below a seam until they have bought it.
> - Price each at 30 minutes of the income available *just above* it, per the
>   pricing rule in the briefing §7. Store the minutes; derive the coins.
> - Per zone, so the ladder repeats in each of the 10 zones and scales `5^(Z-1)`.
>
> Show me the resulting price table before you write the code. Then implement it,
> and tell me what happens to a player who already has characters below layer 100
> — I do not want existing players locked out of depth they already reached.

---

## 2. Replace the block HP curve

> `meadowDirtHp` multiplies by 2.1495 every 40 layers, which is ×432 across 320
> layers and roughly 10⁸⁰ by layer 10,000. Primordium block HP crosses 2⁵³ at layer
> 2281 today, so damage arithmetic is already losing precision in the live game.
>
> Replace it with the linear curve from the briefing §6:
>
> ```
> dirtHp(Z, L) = (20 + 1.5*L) * 5^(Z-1)
> ```
>
> Note this changes `ZONE_HP_MULT` from 6 to 5. Before you touch anything, find
> every caller that depends on the current curve's shape — `MineDepth.dirtHp`,
> `zoneMult`, the abbreviation snapping in `MineAbbrev.ceil`, anything computing
> sell values or backpack space from HP — and tell me which ones break.
>
> Then implement, and print a table of block HP at layers 1 / 500 / 2,500 / 10,000
> for Meadow, Bloodmoon and Primordium, with the max value checked against 2⁵³.

---

## 3. Rebuild the tool power curves

> Two changes, and the second matters more than the first.
>
> **Shop tools:** `shopPower(Z, rung) = 5 * 2^(rung-1) * 5^(Z-1)`. Five rungs per
> zone, ×5 per zone.
>
> **Ore tools:** `orePower(Z, L) = (5 + 0.36*L) * 5^(Z-1) * tierMult`. The 0.36 is
> chosen against block HP's 1.5 so power climbs at 24% of HP's rate — blocks per
> hour must fall steadily with depth and never rise. Verify that it does, at
> layers 1 / 500 / 2,500 / 10,000, and show me the table.
>
> **`tierMult` must be compressed into the range 1.0 to 3.0 across all 82 ores.**
> It currently spans 500×, which is why builds feel pointless and why trade pricing
> cannot tell a fair swap from a progression skip. This is the single most
> important line in the task. Ore becomes identity, not power.
>
> `MineConfig.ORES` is generated from `docs/ore-remake.md` by `tools/gen-ores.js`,
> which has a staleness guard — work with the generator, do not `--force-stale`
> around it. Confirm all 82 ores still produce distinct tools afterwards; a
> previous attempt at this clamped the range and silently made 26 ores identical.

---

## 4. Coin and gem value

> Requires tasks 1–3. Do not start this before seam gating exists.
>
> ```
> coinValue(Z, L) = 5^(Z-1) * (1 + 0.075*L)^0.9
> gemValue(L)     = 1 + floor((L-1)/500)
> ```
>
> Coins are one per 20 HP at the surface, tightening with depth — the 0.9 is a
> power below one, so it dampens. Gems are depth-only and ignore zone entirely,
> which makes them the catch-up lane.
>
> Two properties must hold and both are testable. Write the tests so they fail
> first, then make them pass:
>
> 1. **Coins per point of block HP never increases with depth.** Check every 250
>    layers out to 20,000. It should fall from about 0.0496 to 0.0246.
> 2. **Blocks per hour never rises with depth** (from task 3).
>
> The one-sentence version of what these two buy: *deeper is worth more per hour
> and worth less per swing.* If a change breaks either half, it is wrong.
>
> `MineConfig.coinsFor(kind, zone, mult)` is the payout entry point. `mult` is for
> the player's own `coinBonus` only — nothing else may multiply the payout.

---

## 5. Reprice everything

> Every coin price in the game was calibrated against HP-based income that no
> longer exists. Rebirth 1 at 7,500 coins is 209 minutes of surface income against
> a first zone I want to take 25–30 minutes.
>
> Re-derive all of them using the rule in the briefing §7: **minutes of the average
> income of the band the player is gated into.** For Meadow that band is layers
> 1–99 (above the first seam) and its average income is about 8,048 coins/hour at
> 2,000 blocks/hour — rescale if task 0 gave a different figure.
>
> - `MineSkillData.REBIRTH_BASE`: 7,500 → about 3,600.
> - The rebirth ladder, 27 → 56 minutes across the nine zone gates.
> - **The knee at rebirth 9.** The comment above `rebirthCost` already warns that
>   ×2.08 only holds while zones keep unlocking, and there are 10 zones. Past the
>   last gate income grows only via `prestigeYield` (`1 + 0.15R`). Drop cost growth
>   to about ×1.15 so it tracks the income that actually exists.
> - The shop ladder: 6 / 10 / 15 / 20 minutes per rung. Wood stays free.
>
> Store minutes, derive coins. A hardcoded coin figure goes stale the moment block
> rates move.

---

## 6. Zone-mouth signs

> Put a sign at the entrance to each zone showing that zone's coin rate, in the
> form `1× [block icon] ⟶ N× [coin icon]`.
>
> Because value is anchored to the zone's own top block, N is just `5^(Z-1)`:
> Meadow 1, Sunscar 5, Mistreef 27, Arcwork 133, Bloodmoon 667, Eclipse 3,335,
> Riftmarch 16,676, Starfall 83,379, Mythral 416,896, Primordium 2,084,480.
>
> The sign must read the live value from `MineConfig`, not a hardcoded table, so it
> cannot drift from the payout. Existing outpost/zone-entrance geometry is in the
> zone build code — find it and match the surrounding style rather than inventing a
> new prop.

---

## 7. Charm rework

> Read `roadmap/CHARMS.md`, then implement it.
>
> Charms become unique, upgradeable rare drops from ore. Each has an identity; a
> heavily upgraded weak charm should still be endgame-viable, so the upgrade range
> has to be wide enough that investment beats rarity.
>
> **The load-bearing constraint, and it is not negotiable:** upgrade material must
> not be ore, and no charm that drops from ore may boost ore acquisition. Three
> charms currently carry `oreYield`. That is the same bootstrap loop that broke ore
> tools — a reward improving the rate at which it is acquired — and charms are the
> second system to walk into it.
>
> Upgrades cost stardust, not coins: charms boost mining and coins come from
> mining, which would close the loop from the other direction.
>
> Levels are stripped on trade (`roadmap/ECONOMY.md`), so the sunk stardust does
> not transfer and the sink stays real.

---

## 8. Make trade pricing track power

> `MineTradeValue` ladders ×2.2 per rarity step. Ore tool power ladders 500×. The
> pricing model is measuring a different quantity than the one that matters, so it
> cannot distinguish a fair trade from a progression skip.
>
> If task 3 has landed and `tierMult` is inside 1.0–3.0, check whether this is now
> self-correcting — it may be, since the power spread would be close to the price
> spread. Tell me either way rather than assuming.
>
> If it is not, the rule from `roadmap/ECONOMY.md` applies: anything tradable that
> grants power needs a price that is a function of what it *does*, not only of what
> rarity it *is*. If you cannot write that function, the item must not grant power.

---

## 9. Count the dials and cut them

> The ore system had 8 tuning constants. A previous pass took it to 18, one
> constant at a time, each added to make some brief's assertion pass. That is the
> single biggest source of this system's problems.
>
> Inventory every tuning constant in the ore and economy path. For each one tell
> me: what it does, what breaks if it is deleted, and whether its job is now done
> by one of the curves in the briefing §6.
>
> Then propose a deletion list. I would rather lose a knob than keep one "just in
> case" — an unused dial is a future inconsistency. Do not add any new ones to
> make this work.

---

## A prompt for when something goes wrong

> I think [X] is wrong. Before you change anything: compute the current behaviour
> and paste the actual numbers, then compute what the proposed change would give
> and paste those too. If the two requirements behind [X] are mathematically
> exclusive, prove it and say so instead of resolving it with a new constant.
>
> If you write a test, make it fail on purpose first. An assert that has never
> failed has not been tested.
