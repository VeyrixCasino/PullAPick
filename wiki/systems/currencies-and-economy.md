---
title: Currencies and economy
type: system
status: current
verified: 2026-10-08 @ ea255bb
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
- **Ore's gem value tracks work.** `MineOrePouch.gemValue = ORE_GEM_BASE 3 × workOf(ore)^k`, where k is solved so that the top ore is worth `ORE_GEM_SPREAD 1e6` × the bottom one. Gem Find does **not** apply to ore sales; it applies only to chest gems.
- **Haul sold at a depth desk is multiplied by `MineDepth.depthSellMult`**, a smooth curve `1.05 ^ (seam / 500)` since `4cc82a5` (owner, 2026-10-05: *"make seams sell for more not less"*). Every desk beats the surface and deeper pays more: a 10,000 haul sells for 10,500 at seam 500 and 26,532 at seam 10,000 (measured by the fix's author). It used to be ×487.5 and ×12,187.5 at two seams and ×0.78 elsewhere. See [zones](zones-layers-and-seams.md).

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
  - line 16, `ORE_GEM_SPREAD 1e6 → 1e4` (code still says `1e6`);
  - line 23, potions priced in coins at `dust × 40` (`MinePotions` is dust-only);
  - line 12, `WOOD_PICK_COIN_GROW 1.55 → 1.40` (code: 1.55);
  - line 35, keep MineAbbrev's Vg/Uvg suffixes and delete §0.8's q…z (MineBigNum still uses q…z).

## State right now — the coin problem
- **The owner's complaint**, `docs/TODO.md` §0.28: *"now that coins are basically useless, theres no point... I want the economy to be stable"*.
- **The diagnosis** (`docs/HANDOFF.md` §2.7): coins are a faucet with almost no drain. The coin-shop ladder was superseded by the Forge, which runs on ore, and since `9733a05` the server no longer sells tools for coins at all (owner, 2026-10-05). Making seams free removed one of the three sinks (seams, rebirth, shop tools) (`docs/OPEN.md` §7a).
- **The shape proposed but NOT agreed** (§0.28, OPEN §7): *ore = power, gems = gambling, coins = consumables and access*. Potions would become the load-bearing coin sink, and each outpost would sell for coins the things that help with the next seam. **Do not build it without the owner.** Whether the coin shop survives is also open.

## Gotchas
- **`p.haulGems` is a legacy field.** The sell flow still pays it out, but nothing credits it any more. The live gem faucet is the pouch.
- **Stale `MineStats` descriptions.** "Gem Find: gems dropped by ore" is wrong; Gem Find only touches chests. `MineOrePouch`'s "1.9 billion at tier 82" note predates the spread dial.
- **The client formats its own wallet** through `MineAbbrev.currency`, so §0.13 rule 8's "the client renders the server's string" only holds for server-quoted text.

## Open questions
- What are coins for? Is the depth-desk multiplier intended? What is the final `ORE_GEM_SPREAD` (`docs/BLOCKED.md` #6)? See [open-questions](../open-questions.md).

## See also
[shops-and-monetisation](shops-and-monetisation.md) · [ore-pouch-and-backpack](ore-pouch-and-backpack.md) · [rebirth-and-skill-tree](rebirth-and-skill-tree.md) · [zones-layers-and-seams](zones-layers-and-seams.md) · [save-data-and-migrations](../code/save-data-and-migrations.md)
