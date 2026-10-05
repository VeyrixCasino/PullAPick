# Game audit — 2026-10-04

Owner's brief, verbatim:

> *"i want a full game audit on pretty much how the game should be played, the
> dopamine levels it should give, without making shit feel worthless, because
> theres better stuff (SOMETHING IM REALLY TRYING TO AVOID, BUT FROM WHERE IM
> STANDING ALL I SEE IS SHITTY SHIT LOOKING LIKE SHITTY SHIT [charms should not
> just be a huge family of clones. they would each be different and special in
> their own way. rather than merging it should cost gems.])"*
>
> *"We have a lot of issues and a lot of half features that aren't ready for
> launch... WE MAKE A VERSION OF THE GAME, ARCHIVING ALL USEFUL STUFF THAT IS
> NOT FULLY IMPLEMENTED, AND CUT OUT ALL THE BULLSHIT THAT ADDS NOTHING TO THE
> GAME, AND WE MAKE A PLAYABLE GAME READY FOR LAUNCH WITHIN THE NEXT 2-3 WEEKS*

**I agree with the proposal.** The numbers below are why.

---

## 1. The size of the problem

| | |
|---|---|
| Lua in `src/` | **120,662 lines** across 180 modules |
| Shared modules alone | 88 modules, 60,420 lines |
| Referenced by nothing | **70 modules, 20,633 lines** |
| Biggest single file | `MineInventoryView` at 7,867 lines |

**One in six lines in this project is not reachable from the game.** That is
before counting the systems that *are* reachable but unfinished.

This is not a code-quality complaint. It is the reason the game feels like
"shitty shit": the effort is spread across forty systems, so no single one got
the polish that makes it feel good, and several of them actively undercut each
other.

---

## 2. How the game should be played

Stated plainly, because nothing in the repo says it:

> **You break rock to get ore. Ore is the only thing that makes you stronger.
> Everything else decides WHICH ore is worth breaking, and how fast.**

That is a good loop. It is also already built: the Forge, the ore roster, the
pouch, breaking power and reach all work and all point at it.

The one-sentence test for every system in the game should be:
**"does this change which ore I go break next?"**

- **Passes:** Forge, ore pouch, breaking power, zones/depth, traits, skill tree.
- **Fails:** most of the rest.

---

## 3. The dopamine map, and where the dead air is

A session should have a hit roughly every 30–90 seconds early, stretching to
every few minutes late. Mapping what the game actually delivers:

| beat | frequency | status |
|---|---|---|
| Block breaks, number moves | constant | ✅ good |
| Ore case drops (2%) | ~1 per 50 blocks | ✅ good — guaranteed payout, no dud roll |
| Pouch fills → sell → gems | every few minutes | ✅ good |
| Forge a new tool | ~30–70 blocks of one ore | ✅ **the best beat in the game** |
| Level a tool | continuous | ⚠️ invisible — a number in a panel |
| Open a pack | whenever | ⚠️ ceremony is good, **no pity, no collection pressure** |
| Roll a trait | 500 gems | ⚠️ brand new, 1-in-1000 chase with **no pity** |
| Rebirth | hours | ⚠️ the tree is strong but **unexplained before you buy in** |
| Buy a seam | — | ❌ **UNREACHABLE. Everyone stops at layer 500.** |

**The dead air is 4–6 hours in**, and it is not subtle: `Verbs.buySeam` is live
and nothing fires it. Every player hits layer 500 and the game ends. Nothing
else on this list matters until that is wired.

---

## 4. "Everything feels worthless because better stuff exists"

This is the real question, and the project already has the right answer written
down — **locked rule 0.13**:

> *"later charms are better, **but never because the number is bigger** — a
> charm has a SHAPE, and a shallow charm of the right shape must be able to beat
> a deep one of the wrong shape."*

**Differ in KIND, not DEGREE.** A thing is worthless when a strictly better
version of the same thing exists. It stays valuable when the better thing is
better *at something else*.

Scoring the game against its own rule:

| system | differs in kind? | verdict |
|---|---|---|
| Ore tools | ✅ ore → tier, family → playstyle | **healthy** |
| Traits | ✅ 23 prefixes, 23 different stats | **healthy** |
| Skill tree | ✅ 10 roads, XOR splits, rival keys | **healthy** |
| Tool families | ✅ pick/drill/bomb play differently | **healthy** |
| **Charms** | ❌ **164 generated clones** | **breaks the rule** |
| Pets | ⚠️ 43 species, but stats are the differentiator | at risk |
| Gear (hats/faces) | ❌ one stat, bigger at higher grade | **pure degree** |
| Backpacks | ❌ a ladder of bigger numbers | **pure degree** |
| Coin-shop tools | ❌ a ladder of bigger numbers | **pure degree** |

### Exhibit A: the charms

`MineCharms` generates them in a loop — `for each ore, for each variant` —
producing `"{Ore} {Shape} Charm"`. **82 ores × 2 variants = 164 charms built
from a handful of shapes**, plus 31 legacy ones.

So a Diamond Surge Charm and a Coal Surge Charm are *the same charm with a
different number*. That is the clone family, and it is exactly what 0.13 was
written to forbid. The rule was written; the content was generated anyway.

**Owner's fix, which I agree with:** charms should be **hand-authored, few, and
each strange in its own way**. My proposal:

- **Cut 164 → ~24 hand-written charms.** One page of design, not a loop.
- Each is a RULE, not a percentage. *"Ore you break at under 20% pouch pays
  double."* *"Your first swing on a new block always crits."* *"Drills cost no
  stamina below layer 1000."* A player should be able to *describe* their charm.
- **Merging costs GEMS, not charms** (owner's instruction). `MERGE_COST = 3`
  currently consumes three charms to make one — which is precisely the "clones
  are fodder" economy that makes each one feel worthless.

### The other three failures

**Gear, backpacks and coin-shop tools are pure ladders.** Each rung strictly
obsoletes the last. Options: give each a kind-difference, or cut them. Given 2–3
weeks, **cut**: backpacks already lost their stat (capacity is the pouch now),
coin tools are superseded by the Forge, and gear is a flat boost that could
simply be rolled into traits.

---

## 5. The cut list

### ARCHIVE — good work, not finished, not shipping (move to `archive/`)

| what | lines | why |
|---|---|---|
| Runes (`MineRunes`, `MineRunesView`, `MineSocketsView`) | ~2,600 | Replaced by traits. Keep the fuse/socket design for later. |
| Trading (`MineTradeView`, `TradeService`) | ~1,900 | A trading economy before there is an economy. |
| Group wheel | ~1,100 | Needs a group and a player base. |
| Leaderboards | ~1,750 | Needs a player base. |
| Event pass / limited events | ~900 | A live-ops feature with no live game. |
| Lucky blocks | ~700 | A second gacha on top of packs and traits. |
| Potions, scrolls, credits shop | ~1,200 | Three currencies nobody has a use for yet. |

### DELETE — adds nothing, and some of it is a trap

| what | lines | why |
|---|---|---|
| `_c.luau` | 1,710 | **A stale duplicate of MineConfig.** Nothing requires it. Someone will edit the wrong one. |
| `MineDepthPlazas_OLD_pre_v4` | 673 | Superseded, named as such. |
| `MineBenchView` | 345 | Superseded by the Forge. Already unmounted. |
| `MineGear_AdminTest`, `MineBags_NameCheck` | 1,105 | Test scaffolding in `ReplicatedStorage`, shipped to every client. |
| 4× `CaptureToolIcons*` duplicates | ~1,550 | Four near-identical copies of one Studio script. |
| `chk_*`, `rig_*` | 3,625 | Numeric-suffix scratch copies of PetModelFactory. |

### KEEP — this is the game

Forge · ore roster + pouch + bands · breaking power/reach · zones and depth ·
**seam purchase (wire it)** · traits · skill tree · packs + cards + chests ·
pets · charms (rewritten) · rebirth · the shop.

### Rough totals

| | lines |
|---|---|
| Archive | ~10,000 |
| Delete | ~9,000 |
| **Remaining game** | **~100,000** |

Studio-only bakers in `ServerStorage` (~5,500 lines) stay where they are — they
are tools, not game code, and they do not ship.

---

## 6. The 2–3 week plan

**Week 1 — make it finishable.**
1. **Wire the seam purchase.** The only true ship blocker. Needs the owner to
   name a plaza part or place it in Studio.
2. Delete the DELETE list. Half a day, no gameplay risk.
3. Archive the ARCHIVE list behind one flag so nothing dangles.
4. Play it end to end and write down where it stalls.

**Week 2 — make it feel good.**
5. **Rewrite charms**: 164 generated → ~24 authored rules.
6. **Pity counters** on packs and traits. Single biggest felt improvement
   available, and cheap.
7. **Teach the systems.** First forge, first trait, first charm each need one
   line of in-game copy at the moment they become possible.
8. Cut or fix the three pure ladders (gear, backpacks, coin tools).

**Week 3 — polish and ship.**
9. Balance pass against the roadmap bands (TODO 6.6).
10. The owner's art: ore and charm icons.
11. Launch.

**What I need to start:** the seam-prompt answer (`docs/BLOCKED.md` item 10),
and a yes to the cut list. Everything else on week 1 I can do without you.

---

## 7. The honest risk

Everything built this week — the Forge rewrite, the proc split, two-layer
boosts, the regenerated skill tree, traits — **has never run in Roblox.** The
audit above assumes it works. The first thing in week 1, before any cutting,
should be a full playthrough on the current branch. If something fundamental is
broken, the plan changes.
