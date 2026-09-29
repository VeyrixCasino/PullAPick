# The gating map

Every reward in the game sits on some axis. If you know which, you know whether it
can run away. This is the map. **It is the single document that would have
prevented the ore mess.**

## The axes

| axis | gated by | how hard is the gate |
|---|---|---|
| **Zone** (1–10) | prestige 0–8 | real. You cannot enter Primordium under prestige 8. |
| **Depth** (L1–L2500+) | **nothing** | `rebirthForSeam()` and `rebirthForLayer()` both `return 0` |
| **Coins** | mining | soft — it is the mining reward itself |
| **Gems** | ore + chests | soft |
| **Stardust** | chest rolls, card salvage, pulverize, quests | soft |
| **Prestige** | a reset | hard, and it is the only hard gate in the game |
| **Robux** | money | hard |

Note how short the "hard" column is. **Prestige and money are the only two things
a player cannot simply grind past.** Any reward that must not run away has to hang
off one of those two, directly or transitively.

## The map

| reward | gated by | runs away? | notes |
|---|---|---|---|
| Shop tools | zone (prestige) | no | `MineShopEconomy.toolPowerRaw` keys on `zoneIndex` |
| Depth-shop tools | seam band reached | weak | shop is priced in coins, which mining produces |
| Block coins | zone + depth | — | see `ECONOMY.md`; currently coins == block HP |
| Chests | flat 0.3% per block | no | rate is constant, does not scale with power |
| Pets | packs (gems/Robux) | no | pets do not drop from mining |
| Pet slots (3→8) | Robux | no | hard gate |
| Runes / gear | packs, chests | no | |
| Cards | packs | no | |
| Charms | zone × depth band roll + pack pool | **weak** | drops from digging; boosts digging. See `CHARMS.md` |
| **Ore** | depth only | **YES** | ungated axis |
| **Ore tools** | ore | **YES** | bootstrap loop, `PRINCIPLES.md` §1 |
| Rebirth skills | prestige | no | |
| Prestige luck | prestige | no | |

Two rows are marked YES and one is marked weak. Those three are where the work is.

## How to use this when adding a reward

Answer these four questions **in writing** before you build it:

1. **Which axis does it hang off?** If the answer is depth, stop — depth is
   ungated (`PRINCIPLES.md` §2).
2. **Does it improve the rate at which you get more of it?** If yes, it needs a
   gate from the hard column (`PRINCIPLES.md` §1).
3. **Does the boost stack multiply it?** If yes, it needs a cap
   (`PRINCIPLES.md` §4).
4. **Is it tradable, and does it grant power?** If both, its price must scale with
   its power (`PRINCIPLES.md` §3).

If any answer is uncomfortable, the reward is on the wrong axis. Move it before
you tune it — tuning a reward that is on the wrong axis is what produced the 18
dials.

## The fix nobody has made yet

**Depth is the hole.** Two options, and they are not equivalent:

**(a) Gate depth.** Put the rebirth requirement back into `rebirthForSeam` /
`rebirthForLayer`. The scaffolding is still there — `REBIRTH_PER_ZONE_B = 10`
(band B at L500, so `10 × zoneIndex`) and `REBIRTH_BAND_C_BASE = 60` (band C at
L1500, so `60 + 10 × zoneIndex`) are defined and unused. This makes depth a real
axis and ore tools legitimate where they are.

Cost: deep Meadow then needs prestige 70 while Primordium needs 8, so players go
wide before deep. That is a coherent design, but it is a large change to how the
game feels, and it makes the ten zones the spine and depth the endgame.

**(b) Stop paying power for depth.** Leave depth open and let it pay in
collectibles, currency and trade value instead of damage. This is the cheaper
change and it is what `ORE.md` recommends.

**Do not do neither.** Right now the game does neither, and that is the state that
produced a 2-million-damage pickaxe in half an hour.
