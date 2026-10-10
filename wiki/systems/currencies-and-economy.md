---
title: Currencies and economy
type: system
status: current
verified: 2026-10-10 @ 6c08171
sources:
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineOrePouch.luau
  - src/ReplicatedStorage/Mine/Shared/MineDepth.luau
  - src/ReplicatedStorage/Mine/Shared/MineShopBuy.luau
  - src/ReplicatedStorage/Mine/Shared/MineAbbrev.luau
  - src/ServerScriptService/Mine/MineBigNum.luau
  - src/ReplicatedStorage/Mine/Shared/MinePotions.luau
  - docs/TODO.md §0.13, §0.28
  - docs/HANDOFF.md §2.7
  - docs/OPEN.md §7, §7a
  - docs/PROPOSAL.md §0, §E, §H1
related: [mining-and-breaking, zones-layers-and-seams, rebirth-and-skill-tree, ore-pouch-and-backpack, forge-and-recycling, shops-and-monetisation, chests-and-lucky-blocks]
---

# Currencies and economy

> There are three main currencies. **Coins** are pay for digging. **Gems** come from selling ore and buy access and gambles. **Ore** is power, because tools are forged from it. Smaller currencies sit beside these: stardust, space coins, temper tokens, skill points and Robux-bought credits. The open problem is that coins have almost nothing left to buy.

## How it works

| currency | field | comes from (faucets) | goes to (sinks) |
|---|---|---|---|
| **Coins** | `p.coins` | **Digging.** `payDamage` pays 1 coin per HP landed × `coinBonus`, priced into `haulMix` as you mine and paid when you sell. **Chest blocks** (`MineZoneChests.rollCurrency` × coinBonus) and the chest `coins` row (`Dig.Depth.dirtHp`; the crash is fixed). **Pack rows.** **Selling ladder tools back** (`Verbs.sellTool`). **Pass claims.** **AFK ticks.** **Credit products** (`prod.coins`). **Tutorial.** Sale payouts of coins and space coins are ×2 for owners of the `COIN_DOUBLE_GAMEPASS_ID` pass (`p.coinDouble`). | **Surface coin-shop tool ladder** (`MineShopBuy`, `buyTool`). **Depth-desk tools** (`buyDepthTool`). **Coin-tool levels** (`Verbs._upgradeCoinTool`). **Rebirth** (`tryPrestige`). Seams cost 0 now. |
| **Gems** | `p.gems` | **Selling ore from the pouch** (`Verbs.sellOre`, `Verbs.sellAllOres` → `MineOrePouch.stackValue`). **Chests** (× `gemFind`). **Rebirth reward.** **Quests and tutorial.** **The fossil cash-out on load.** | **Zones** (`buyCost`). **Bags** (`MineBags.gemPrice`, 100 × 1.08^rung). **Pouch rungs.** **Trait roll** (`MineTraits.ROLL_PRICE 500`). **Charm merge.** **Rune fuse.** **Charter levels** (`Verbs.buyCharter`). **Crates.** **Gem Vault / Chest Warren pack unlocks** (`MinePackConfig`, 2.5M / 4M). |
| **Ore** | `p.ores` (the pouch) | **Ore blocks** (`MineConfig.oreYieldFor`). | **Forging and upgrading tools**, or selling for gems. See [forge-and-recycling](forge-and-recycling.md) and [ore-pouch-and-backpack](ore-pouch-and-backpack.md). |
| Stardust | `p.dust` | `pulverize`, chest scrap, recycling | ore-tool levels (`TOOL_DUST_BASE 25`), potion merges (`MinePotions`), pet power-up, card merges |
| Space coins | `p.spaceCoins` | Event Horizon haul (currency `"space"`) | event tools (`MineShopBuy.buyEvent`) |
| Temper tokens | `p.temperTokens` | rebirth (`MineSkillData.rebirthTokens`), quests, selling skill points | temper rolls and cases, skill-point buy-back; see [skins](skins-cases-and-temper.md) |
| Credits | `p.credits` | Robux credit packs (`Verbs.buyCreditPack` grants directly only in Studio) | VFX, deals, `buyProductWithCredits`; see [shops](shops-and-monetisation.md) |

**Rules that shape the flows:**
- **Bags cost gems, not coins.** The comment in `buy()` explains why: the thing that lets you carry more coins should not be bought with coins.
- **Rebirth charges `MineSkillData.rebirthCost` in coins only, then resets the wallet to 0** (`blank()`). Gems, ore and the pouch survive ([rebirth](rebirth-and-skill-tree.md)).
- **Ore's gem value tracks work.** `MineOrePouch.gemValue = ORE_GEM_BASE 3 × workOf(ore)^k`, where k is solved so the top ore is worth `ORE_GEM_SPREAD` × the bottom one. **`ORE_GEM_SPREAD` is `1e4` as of 2026-10-08** (was `1e6`). Measured off the live modules: tier 1 = 4 gems, tier 41 = 279, tier 82 = 42,727. Gem Find does **not** apply to ore sales; it applies only to chest gems.
- **Haul sold at a depth desk is multiplied by `MineDepth.depthSellMult`.** That is `1.05^(seam/500)` — **×1.05 at seam 500 and ×1.63 at seam 5000**. (This line previously claimed ×487.5 at seam 500, a 464× overstatement from an older formula.) See [zones](zones-layers-and-seams.md).

**Number formatting:**
- **`MineAbbrev.currency`.** Four significant figures, **always floored**: 1.234K, 12.34K, 123.4K. Used for every wallet: the client's `shortNum`, `MineForge`, `MineBenchView`, the leaderboards and the pouch view.
- **`MineAbbrev.format` / `MineAbbrev.ceil`.** These round **up** to one decimal of the unit. They are for block HP labels, so a label never understates the rock. Do not "fix" either one into the other.
- **`MineBigNum`.** It is server-only, in `ServerScriptService` so the client cannot require it.
  - **Suffixes.** It counts in base 30, three digits a step. The first 20 steps use the named suffixes K…Nod. Steps 21–30 use the backlog q…z. After that the suffixes carry positionally.
  - **Science form** looks like `9.999e^99`.
  - **Its one server caller is `Verbs._benchNum`.** `tools/verify/bignum.js` pins its output as byte-identical to `MineAbbrev.currency` below 10^63. Above that, MineAbbrev continues with Vg/Uvg/Dvg.
- **"Simple abbrev"** is a player setting (`MineAbbrev.setSimple`) that switches suffixes past T to aa, ab, ….
- **2^53.** Luau numbers are doubles, so integers are exact only up to 2^53 ≈ 9.007e15.
  - **Block HP.** The linear `MineDepth.dirtHp` tops out at 1.47e10 at zone 10, layer 5000. That is why the old sectioned HP (Terminus 9.3e18) was dropped.
  - **Rebirth cost** crosses 2^53 at rebirth **39** (9.15e15; computed).
  - **The depth-desk multipliers** can inflate wallets far faster than either of those.

## Where it lives
| file | role | key symbols |
|---|---|---|
| `src/ServerScriptService/Mine/MineServer.server.luau` | every faucet and sink | `payDamage`, `Dig.addHaul`, sell flow (`p._sellDesk`), `Verbs.sellOre`, `buyZone`, `tryPrestige`, `buyProductWithCredits` |
| `src/ReplicatedStorage/Mine/Shared/MineOrePouch.luau` | ore → gems | `MineOrePouch.gemValue`, `MineOrePouch.ORE_GEM_SPREAD`, `MineOrePouch.RUNG_COST_SHARE` |
| `src/ReplicatedStorage/Mine/Shared/MineDepthShop.luau` | depth-desk sale | `MineDepthShop.sellPayout` |
| `src/ReplicatedStorage/Mine/Shared/MineShopBuy.luau` | coin and space purchases | `MineShopBuy.buyEvent` |
| `src/ReplicatedStorage/Mine/Shared/MineAbbrev.luau` | client formatter | `MineAbbrev.currency`, `MineAbbrev.format`, `MineAbbrev.ceil` |
| `src/ServerScriptService/Mine/MineBigNum.luau` | server formatter | `MineBigNum.auto`, `MineBigNum.suffix` |

## Decided by the owner
- **Gems come from selling ore.** Zones, runes and the pouch are gem sinks (`docs/TODO.md` §0.13 rule 7).
- **Big numbers are server-side and round down** (§0.13 rule 8). **Currencies show four significant figures, floored** (§0.13 rule 9).
- **No coin multiplier on rebirth.** `prestigeYield` was dead and has been deleted (§0.27, PROPOSAL line 22).
- **Seams are free** (2026-10-05).
- **Approved in PROPOSAL §0 but not yet in code:**
  - line 23, potions priced in coins at `dust × 40` (`MinePotions` is dust-only);
  - line 12, `WOOD_PICK_COIN_GROW 1.55 → 1.40` (code: 1.55);
  - line 35, keep MineAbbrev's Vg/Uvg suffixes and delete §0.8's q…z (MineBigNum still uses q…z).

## State right now — the coin problem
- **The owner's complaint**, `docs/TODO.md` §0.28: *"now that coins are basically useless, theres no point... I want the economy to be stable"*.
- **The diagnosis** (`docs/HANDOFF.md` §2.7): coins are a faucet with almost no drain. The coin-shop ladder was superseded by the Forge, which runs on ore, and since `9733a05` the server no longer sells tools for coins at all (owner, 2026-10-05). Making seams free removed one of the three sinks (seams, rebirth, shop tools) (`docs/OPEN.md` §7a).
- **The shape proposed but NOT agreed** (§0.28, OPEN §7): *ore = power, gems = gambling, coins = consumables and access*. Potions would become the load-bearing coin sink, and each outpost would sell for coins the things that help with the next seam. Whether the coin shop survives is also open.

### Measured 2026-10-09, and it was worse than "almost no drain"

A full faucet/sink census found **twelve coin faucets against TWO live sinks**:
the wooden-pickaxe ladder, which is **306 coins across an entire lifetime**, and
rebirth. Four further coin sinks exist only as **unreachable code** — every shop
tool family is refused by `MineConfig.FORGE_ONLY_FAMILIES`, and
`MineDepth.seamPrice` returns a hard `0`. Meanwhile the main tap is one coin per
point of block HP, multiplied by a skill tree reaching ×10.97.

**First real sink shipped** (`9019354`, PROPOSAL §0 line 23): potions cost coins
at `dust × 40` — Sip 1,600 → Elixir 56,000 — *in addition* to dust, since dust's
own sink (ore tool levels) is healthy. Repeatable, inside the mining loop,
never closes.

**It is an early-game sink only**, measured: an Elixir is 2,545 blocks at meadow
L1, 73 blocks at L500, and **0.1 blocks at zone 5 L1000**. A flat price against
an exponential faucet. A depth-scaled coin sink is still owed; the owner has
picked the direction (progression-flavoured, repeatable, in the loop).

**Gems are the healthiest currency**: one metered tap (pouch-capped ore sales)
against ~17 sinks. The `1e4` change fixed the top end but left the FLOOR alone —
trait roll 500, pack crate 200, backpack rung 1 at 100, re-socket 10 were pocket
change at `1e6` and still are. Derived sinks (ore pouch, charm merge) corrected
themselves; authored ones cannot.

**Three gem/token sinks were unreachable and are now wired**: the Charter
(`2ae2c74`, 4 upgrades, 14,039,800 gems for the full ladder ≈ 329 Oganesson),
rune cases and set crates (`ec097dc`, `5cbf80e`, 300 → 60,000 gems), and the
36-charm token shelf (`69f3de6`, 15 → 2,500 tokens). All three had complete
servers and no caller; two were advertised by UI strings pointing at nothing.

## Gotchas
- **`p.haulGems` is permanently zero, and that is CORRECT.** Read in five places, incremented in none. Coins bank into the haul as you dig; gems come from selling ore out of the pouch at the moment of sale. Documented at its declaration (`4f45483`) so it is not "fixed" into a second faucet. Kept because it is a persisted profile key.
- **Stale `MineStats` descriptions.** "Gem Find: gems dropped by ore" is wrong; Gem Find only touches chests. `MineOrePouch`'s "1.9 billion at tier 82" note predates the spread dial.
- **The client formats its own wallet** through `MineAbbrev.currency`, so §0.13 rule 8's "the client renders the server's string" only holds for server-quoted text.

## Open questions
- **A depth-scaled coin sink.** Potions fixed the early game only (0.1 blocks for an Elixir at zone 5 L1000). Owner has picked the direction: progression-flavoured, repeatable, in the loop.
- **The flat gem floor prices** — trait roll 500, crate 200, backpack rung 1 at 100, re-socket 10 — did not move with `ORE_GEM_SPREAD 1e6 -> 1e4` and are pocket change at every stage.
- **Chests may now out-faucet ore sales.** Chest gems scale on their own ladder (`GEM_MULT.primordium = 820`) and are not pouch-capped, so a top chest can pay 3.7-6.5 Oganesson units. That inverts the stated rule that ore is the one gem tap.
- ~~What is the final `ORE_GEM_SPREAD`?~~ **SETTLED**: `1e4`, applied 2026-10-08 (`0b98d13`).

## See also
[shops-and-monetisation](shops-and-monetisation.md) · [ore-pouch-and-backpack](ore-pouch-and-backpack.md) · [rebirth-and-skill-tree](rebirth-and-skill-tree.md) · [zones-layers-and-seams](zones-layers-and-seams.md) · [save-data-and-migrations](../code/save-data-and-migrations.md)
