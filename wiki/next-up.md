---
title: Next up (handoff, 2026-10-10)
type: meta
status: current
verified: 2026-10-10 @ 6335086
sources:
  - docs/PETS-AND-SETS.md
  - docs/ZONE-PETS.md
  - tools/gen/zone-pets.js
  - src/ReplicatedStorage/Mine/Shared/MineZonePets.luau
  - src/ReplicatedStorage/Mine/Shared/MineProcFx.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
related: [owner, pets, mining-and-breaking, boosts-and-stats, open-questions]
---

# Next up: the owner's queued work, with a prompt to start it

> The owner asked for this page on 2026-10-10: *"put it in the wiki along with a
> prompt to do all this then ill get u back to work"*. Everything below is the
> owner's decision unless it is marked **assumed**. Paste the prompt at the
> bottom into a new session to start.

## Where things stand (all pushed to `claude/vigilant-fermi-aucqjy`)

| done | commit |
|---|---|
| Daily wheel | `299dd2c` |
| Zone pots: 70 pets per zone (451 new), the pet display rebuilt from code | `0aff5e8` |
| Old pet/card data removed; Event Horizon put on the pet ladder as zone 11 | `d69c6f1` |
| Tidal Wave proc; every proc has an animation and a sound (`MineProcFx`) | `6335086` |
| Holiday pets out of the game (this page's commit) | see `wiki/log.md` |

## 1. Pet power: a new top and bottom — DONE 2026-10-10

The owner chose: Commons stay, everything else grows towards Exotic ×4/3
(see [pets](systems/pets.md)). The rest of this section is the original brief.

Owner: *"make it 489 at top, 300 at start"*. That means an Exotic's whole kit is
worth **300 points at zone 1 (Meadow)** and **489 at zone 11 (Event Horizon)**,
at Normal and power level 1. Today those are 225 and 367; 300 × 1.05¹⁰ = 489,
so the +5% zone step stays.

- **Assumed: the whole ladder scales by 4/3.** `LADDER` in
  `tools/gen/zone-pets.js` becomes Common 45.3 … Exotic 200 (primary; the
  secondary stays half). That puts a zone-1 Common at 68 points. The owner only
  gave the Exotic numbers, so ask if lower tiers should move differently.
- After the change, re-run the generator and `tools/verify/zone-pets.js`. Its
  ladder assertions read `LADDER`, so they follow.

## 2. Procs: rework (the owner's "equation" meant the damage formula) — DONE 2026-10-10

The owner chose:
- one damage stat per proc;
- Shatter goes to the 6 sides;
- **no caps**: proc chances are priced high instead (Blast 9, Zap 8, Shatter 9,
  Earthquake 9, Tidal Wave 10 per +1%).

Built and measured in Studio; see [mining-and-breaking](systems/mining-and-breaking.md).
The rest of this section is the original brief.

Today a proc hit is `PROC_SHARE[proc] × swing damage × (1 + procPower)`
(`MineConfig.procDamage`). On a weak pick that rounds to 1. The owner's rules:

1. **Blast drops below Tidal Wave.** `PROC_SHARE.blast` 0.35 → **0.12**. Blast is
   three-dimensional and combines with blast range (`blastRadius`), which makes
   it *"way to OP"*.
2. **Tidal Wave stays at 0.18 per block**, flat, on its own layer.
   - **No range modifiers:** nothing may grow `Dig.TIDE_RING`.
   - It gets **its own damage % stat**, e.g. `tideDamage`, added to its share.
3. **The three top Tidal Wave pets are capped.** Jumble (Exotic, 41%), Shimmer
   (Divine, 32%) and Fizzgig (Mythic, 24.5%) are Mistreef's top pets, shown at
   Normal. Together they reach 98%; the owner wants about **50–60%**.
   - Lower their tide amounts.
   - **Assumed:** also hard-cap the Tidal Wave chance at 0.6 in `Dig.procsAt`, so
     variants (Rainbow ×5.5) cannot blow past it.
4. **Zap gets two numbers:** a **start chance** and a **continue equation**.
   - Today one stat does both: it starts if `rng < zap`, then continues while
     `rng < zap × ZAP_FALLOFF^hop`.
   - Split it: a low start chance, plus a continue probability per hop with its
     own formula.
   - Owner: *"just ensure its balanced"*. Target an expected total near Tidal
     Wave's at the same chance.
5. **Ricochet becomes Shatter**, an area proc. When a block breaks, there is a
   chance to send shards in all directions. If a shard breaks a block, that
   block rolls Shatter too. **At most 3 Shatter procs per block you break.**
   - **Keep the stat key `ricochet`.** It is data: the skill tree's Electric
     secondary, the "Bouncing" trait, `MineGear.STAT_WEIGHT`, kits and saves.
     Relabel it "Shatter", as `fossilFind` became "Ore Finder".
   - **Assumed:** shards go to the 6 faces, like Blast.
6. **Every proc has a low chance and a damage %.** Chances stay around Tidal
   Wave's level; each proc gets a damage % stat on top of its share.
   - **Assumed:** these are per-proc stats (`blastDamage`, `tideDamage`,
     `zapDamage`, `shatterDamage`), and `procPower` stays the global multiplier.
     Ask if the owner meant one shared stat.
7. **Hats get the new stats.** Tidal Wave, Shatter and the damage % stats must
   roll on hats.
   - Find where a hat's stat is chosen: `MineGear` (`rollPiece`,
     `STAT_WEIGHT`) and `MineHats`. Add them there.
   - Also add them to `MineStats.STATS` and `STAT_ORDER`, to
     `MineCards.ADDITIVE_STATS` and `emptyBoosts`, and to the two additive lists
     in MineServer (`ADDITIVE_BOOST`, `Dig.boostSources`).
   - `tools/verify/stats.js` fails if these lists disagree.
8. **Update the effects.** `MineProcFx` needs Shatter shards flying out and
   chaining, and a sound. Zap's arcs must follow the new chain.

## 3. Halloween: 10 new bodies (approved) — DONE 2026-10-10

Built, rendered in Studio and on the display; see [pets](systems/pets.md). The rest of
this section is the original brief.

Bat, Mummy, Zombie, Vampire, Cauldron, Candy Corn, Scarecrow, Haunted Lantern,
Frankenstein, Eyeball.

- Build them as new species builders in `PetModelFactory`, following the body
  rules in [pets](systems/pets.md) (`shape` profiles, details on the envelope).
- List them in a new `HALLOWEEN` list on PetModelFactory (create it). The
  display builder already draws that list as its own block.
- **They are not in the game** (next section). They come only from a
  "Halloween 2026 Pack", which is built in the rewards pass.

## 4. Holiday rule (done; keep it true)

Owner: *"make sure NO holiday ones are in the game.. only allow it from {Holiday}
{year} Pack"*.
- `MineZonePets.HOLIDAY` lists the six holiday pets:
  - Halloween: Spindle, Spooky, Wisp;
  - Christmas: Jolly, Tinsel, Tinseltoe.
- They are in no zone pot, and `MineGroupWheel.rollPetOfTier` (the wheel and
  lucky blocks) skips them. Verified with 16,000 rolls in Studio.
- They keep a zone-1 kit, so an owned copy still pays.
- **New holiday content goes the same way:** never in a pot or a random roll,
  only through a "{Holiday} {year} Pack". `tools/verify/zone-pets.js` fails if a
  pet on a holiday body is not on the list.

## 5. After that

- The rewards pass (`docs/PETS-AND-SETS.md`): pack cases, the stardust shop
  tab, ★ wheel slices, the 6-hour spin, removing universal packs, and the
  Halloween 2026 Pack. **Done so far:** set packs open into their set's pets,
  and zone pots are the drop source for every other pack (2026-10-10).
- The 19 sets' pets (2,043, every one named) and about 100 new bodies.
- A2 (the TODAY checklist in the Quests panel), then A3 (fishing).

## How to test a pet or proc in Studio

- `devGrant { pet = "Fizzgig" }` (Studio only) mints a pet and seats it. Fire it
  from a Client `execute_luau` through `ReplicatedStorage.Mine.Remotes.MineNet`,
  then swing at blocks with `net:FireServer("swing", block)`.
- The display rebuilds with `require(game.ServerStorage.PetShowcaseBuilder).build()`
  in Edit mode. It loads fresh module copies itself.
- **Restart play after code changes.** A running session keeps its old modules.

## The prompt (paste into a new session)

```
Read CLAUDE.md, then wiki/index.md, wiki/owner.md and wiki/next-up.md. Do
wiki/next-up.md sections 1, 2 and 3 in that order, on branch
claude/vigilant-fermi-aucqjy.

Rules:
- Ask me before acting on anything marked "Assumed" in next-up.md if you are not
  sure. Give me options with your recommended default first.
- Ids and stat keys are data: never rename one (Ricochet keeps the key
  "ricochet").
- Never add top-level locals to MineServer or MineClient (MineServer has 4 left).
- Another session may share the checkout: commit only your own hunks, never
  `git add -A`.
- After Luau changes run `node tools/verify/compile.js`,
  `bash tools/verify/suite.sh --quiet` and `node tools/verify/wiki.js`.
- Prove every change in Studio, not just in tests. Proc chances and damage: break
  real blocks with devGrant pets and count the procs. Effects and bodies: take
  screenshots.
- Keep the wiki current in the same commit, add a wiki/log.md entry, and push.
- I am on Windows PowerShell: one command per line, no &&. End every reply with
  the current todo list.
```
