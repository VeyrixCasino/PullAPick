# Mine For Cards — direction

You are reading this because you are about to change this game. Read `PRINCIPLES.md`
before you write anything. It is short and it is the part that matters.

This folder is not a spec to implement. It is the **direction** — what the game is
for, which mistakes have already been made, and which rules cannot be broken
without the economy eating itself. A spec tells you what to build; this tells you
what is true, so that what you build fits.

## What this game is

A Roblox mining simulator. You dig, blocks pay coins, you buy better tools, you
go deeper and wider. Around that core sit the things that keep people playing and
talking to each other:

- **Collecting.** 322 pets, 31 charms, runes, gear, cards, and (the newest layer)
  82 ores × 57 tool types = 4,674 distinct ore tools.
- **Trading.** Player-to-player, priced in stardust-equivalent by `MineTradeValue`.
- **Grinding.** Prestige, rebirth skills, depth.

The owner's words for what they want, and the only success criterion that counts:

> a game with a good community, that trades, and collects, and grinds, that is
> balanced and has precautions so it doesn't fuck itself

Read that last clause as the engineering requirement it is. Most of `PRINCIPLES.md`
is about precautions.

## What the game is NOT about

**Maxing.** Nobody is meant to arrive at the ceiling. Design for the first hour and
the hundredth, not for level 100 of anything. If you find yourself tuning a number
so that "time to max" lands on a target, stop — you are solving the wrong problem,
and there is a postmortem in this folder about exactly that failure.

Concretely, in the current ore system: levelling a tool 99 times is worth **36×**.
Which ore you found is worth **500×**. The ceiling is a rounding error next to the
find. Tune the find.

## How to use this folder

| file | read it when |
|---|---|
| `PRINCIPLES.md` | **always, first.** Invariants. Breaking one is a bug, not a trade-off. |
| `GATING.md` | you are adding or changing any reward |
| `ECONOMY.md` | you touch supply, sinks, trade, prices or monetisation |
| `ORE.md` | you touch ore, ore tools, or ore packs |
| `CHARMS.md` | you touch charms (there is a rework pending) |
| `NUMBERS.md` | you need real magnitudes — HP, boosts, zones — or hit a big-number bug |
| `POSTMORTEM.md` | before proposing a redesign. It lists what has already been tried and how it failed. |

## Ground rules for agents

1. **Verify against the code, not against this folder.** These documents cite real
   values with file references, but code moves. If they disagree, the code is
   right and this folder needs a patch — say so.
2. **`MineConfig.ORES` is generated** from `docs/ore-remake.md` by
   `tools/gen-ores.js`. It also has a guard that refuses to write when the live
   table has moved past what the generator can express. Do not `--force-stale`
   around it.
3. **Nothing in `roadmap/` is load-bearing at runtime.** It is documentation. Never
   `require` it.
4. **Do not add a tuning constant to make a rule pass.** See `PRINCIPLES.md` §7.
   The ore system currently carries 18 interacting dials and that is the single
   biggest source of its problems.
5. **Studio is the source of truth for the place, `src/` for code.** Rojo syncs
   files → Studio only. Changes made in Studio are not written back; see
   `AGENTS.md` and `tools/export/sync.ps1`.
