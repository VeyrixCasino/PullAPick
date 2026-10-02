# Charms — rework

## What charms are today

31 charms, **one equip slot** (`p.equippedCharm`). The header calls them
"one-equip chase identities", which is the right instinct: a charm is a choice, not
a stat stick you accumulate.

Sources:
- **Zone grants** — 5 zones (`meadow, mistreef, bloodmoon, riftmarch, mythral`) ×
  3 depth bands (`shallow ≤500, mid ≤1500, deep >1500`) = 15, dropped on a roll
  (`zoneDropChance`).
- **Pack pool** — 15 more, gems/Robux.
- **Lucky Charm** — reserved limited, not in the pack.

Magnitudes, by band: shallow **+100–140%**, mid **+170–230%**, deep **+250–320%**.
Better charms are also *wider* — one stat at shallow, two or three deeper.

```lua
sod         mineSpeed 1.10                        -- shallow, 1 stat
rootstride  mineSpeed 1.80, backpack 0.60         -- mid, 2 stats
thornvault  dirtBreak 2.60, pulverize 0.40        -- deep, 2 stats
```

Observed stat ranges across the 31: `mineSpeed 1.10–3.00`, `dirtBreak 0.50–2.60`,
`coinBonus 1.70–2.80`, `luck 0.50–2.00`.

## What the rework must deliver

1. Each charm **unique** — already true, keep it.
2. A **rare drop from ores**.
3. **Upgradeable.**
4. Better charms are usually better, **but a heavily upgraded weak charm should be
   endgame-viable.**

## Design

### The shape

Charm = **base identity** (its stat set, fixed, unique) + **level** (a multiplier
on those stats). Upgrading never adds a stat and never changes which stats — a Sod
Charm is always a mine-speed charm. Identity is what makes it collectable and
tradable; level is what makes it yours.

### Making requirement 4 work

This is the interesting constraint. The spread between the weakest and strongest
charm is roughly **3×** on the headline stat (1.10 → 3.00), plus the better ones
carry an extra stat or two — call the effective spread **4–5×**.

So the upgrade ceiling must exceed that spread, or a maxed weak charm can never
catch an unupgraded strong one. **Target: a fully upgraded charm is worth about 6×
its base.** Then:

| | base | fully upgraded |
|---|---|---|
| Sod (weakest) | +110% | **+660%** |
| Deep charm (strongest) | +320% | +1920% |

A maxed Sod (+660%) comfortably beats an unupgraded deep charm (+320%), which is
exactly the ask — and a maxed deep charm still beats a maxed Sod, which preserves
"better charms are usually better". With one slot, the player's real decision is
*invest in what I have* versus *chase something better and start over*. That is a
good decision to hand someone, and it is the whole design.

Keep the level count modest — **10 levels, not 100.** The ore-tool postmortem is
clear that 99 levels of small increments is effort nobody feels; ten steps of
~20% each are legible and each one is an event.

### The gate — read this before writing any code

Charms drop from ores. Charms boost mining. **That is a bootstrap loop**
(`PRINCIPLES.md` §1), and charms are the second system to walk into it.

Two hard rules follow:

**(a) Upgrade material must not be ore, and must not be anything a charm's own
boosts help you get faster.** Stardust is the natural candidate — it comes from
chest rolls, card salvage and pulverize, so it is only weakly coupled to digging
speed. If you use ore, the loop closes and you have rebuilt the ore-tool mistake
in a new system.

**(b) No charm may boost ore acquisition.** Check the roster against this: any
charm carrying `oreYield`, `rareOre` or `luck` *and* dropping from ore is a closed
loop on its own. Today three charms carry `oreYield 0.55–0.75`. Either those
charms come from packs only, or the stat comes off them.

### Rarity, drop rate and trade value

- Drop from ore should be **rare enough to be an event** — the design word is
  "chase". Tie the rate to the **ore's band**, not to depth, so it hangs off the
  roster rather than the ungated axis (`PRINCIPLES.md` §2). A Divine ore having a
  better charm roll than a Common one is the right feel.
- **Trade value must include the level**, or the §3 mismatch reappears in miniature:
  a maxed charm is 6× a fresh one and the pricing model must know. Extend
  `MineTradeValue` with a charm table keyed on base rarity, multiplied by the level
  multiplier. Do not price charms on base identity alone.
- A maxed charm is a large investment of stardust. That makes it a **sink** — good,
  the economy needs those (`PRINCIPLES.md` §5) — but it also makes a traded maxed
  charm a way to hand someone else your sunk cost. Decide deliberately whether
  upgrades survive a trade. Recommendation: **they do not.** Trading transfers the
  charm at base level. That keeps the sink real, keeps the chase meaningful, and
  removes the pawn-to-new-player exploit before it exists.

### What to build, in order

1. Add `level` to the charm record and a level multiplier to `MineCharms.applyEquipped`.
2. Add the upgrade verb, server-authoritative, uid-based, priced in stardust,
   `snap` + `markDirty` after — mirror the existing tool-upgrade verb's shape.
3. Add the ore-band drop roll. Audit every charm against rule (b) first.
4. Extend `MineTradeValue` with level-aware charm pricing, and strip levels on trade.
5. UI: the charm panel needs current → next, the stardust cost, and what the
   ceiling looks like, so the "invest vs chase" decision is visible.

## Hats and faces — context

Same slot logic, and they feed the same multiplicative stack: *each pet × its rune
× (its hat + your hat), summed, × your face*. Faces/gear is a 10-entry table
(`MineGear.luau`, stats include `coinBonus` via `foundry`).

Note that hats multiply **per pet** — so a hat's value scales with how many pets
you have equipped, up to 8. Any hat change is therefore an 8× lever at the top of
the stack, not a 1× one. Treat hat numbers with more care than their size suggests.
