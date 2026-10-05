---
title: Trading
type: system
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - src/ServerScriptService/Mine/TradeService.luau
  - src/ReplicatedStorage/Mine/Shared/MineTradeValue.luau
  - src/ReplicatedStorage/Mine/Shared/MineTradeView.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - roadmap/PRINCIPLES.md §3, §5, §8
  - docs/AUDIT.md §5
  - docs/TODO.md §0.12, §0.17
related: [cards-and-packs, currencies-and-economy, enchantments-runes-and-gear, pets-and-traits, forge-and-recycling]
---

# Trading

> Two players in the same server open a trade window. Each side puts up items
> and some currencies, and both accept, then confirm. The design goal is that
> nothing can be duplicated. A coinflip mode exists but is switched off for launch.

`MineServer` below means `src/ServerScriptService/Mine/MineServer.server.luau`.

## How it works

The flow is written out in the header of `TradeService.luau`:

1. **Invite.** One player invites the other with `tradeAsk`. The invite lives
   `INVITE_TTL` 30 s, a player can send one every `INVITE_COOLDOWN` 4 s, and nobody
   can trade for the first `JOIN_GRACE` 15 s after joining.
2. **Draft.** Each side may offer up to `MAX_ITEMS` 16 items, named by id, never
   by list position:
   - **cards**, by registry serial;
   - **packs**, by `uid`. Any `p.packs` row has one, so ore cases and lucky blocks
     can be traded too;
   - **runes**, **gear** and **potions**;
   - and currency: **gems**, **stardust** (`dust`) and **temper tokens**
     (`temperTokens`).
3. **Talk.** Players can mark the other side's items WANT or NO, and put a number
   on the gems, stardust or tokens they want. These are talk only and never change
   the deal.
4. **Accept, then confirm.** Both press accept. A `CONFIRM_DELAY` of 3 s follows,
   then both press confirm. Any change to an offer resets both accepts.
5. **Commit.** Everything is escrowed in one step with no yield. Card owners move
   in the global serial registry (`transferSerial` in MineServer); if any move
   fails, the moves that succeeded are undone. Both players are then saved.

**What can't be offered.** The `setOffer` and `gather` checks refuse:
- socketed runes (`runeBusy`);
- worn gear;
- cards without a registry serial;
- anything from an ephemeral profile (one whose save failed to load).

`PolicyNoTrade` also blocks a player whose `PolicyService` says paid-item trading
is not allowed in their region (`Verbs.fetchPolicy`).

**Never tradeable, because no trade kind exists for them:**
- coins, credits and ore (`p.ores`);
- ore tools, chest tools and secrets;
- charms, skins and tempers;
- event tools and VFX.

**What gets stripped from a traded item:**
- **Pets.** A traded pet leaves the giver's `p.equipped` (`escrow`).
- **Pet runes.** A pet's rune socket lives in the *giver's* `p.petSockets[cardId]`,
  which TradeService never touches. The rune stays behind with the giver, still
  pointing at a card they no longer own.
- **Gear runes.** A gear piece's `sockets` travel with it, but they hold rune ids
  from the giver's `p.runes`.

Both rune points are static reads and have not been tested in engine.

**Pricing.** `MineTradeValue` puts a stardust-equivalent price on everything. The
trade windows show it, and the coinflip announcement uses it (`lootValue`). It
never blocks a trade.
- **Rates:** `GEM_TO_DUST` 2, `COIN_TO_DUST` 0.002.
- **Cards:** `MinePackConfig.recycleValue`, then ×(1 + 0.35 × (powerLevel − 1)).
- **Packs:** rune pack 55 and gear pack 70 (`PACK_DUST`). Any other pack is its
  credit price × 2 × 0.6.
- **Runes, by tier:** 25 / 100 / 400 / 1600 / 6400 (`RUNE_TIER_DUST`).
- **Gear, by grade:** F → SSS is mapped onto Common → Exotic, then priced 12 → 3600
  (`GEAR_DUST`, `GRADE_TO_NAME`).

**Coinflip.** This mode pools both offers, and a 50/50 picks who takes the lot.
`TradeService.COINFLIP_ENABLED = false`, commented *"off for launch: gems/packs
trace back to Robux"*. `setMode` refuses it, and the old `coinflipAsk` verb now
just returns a toast.

## Where it lives
| file | role | key symbols |
|---|---|---|
| `TradeService.luau` | sessions, offers, escrow, commit | `invite`, `setOffer`, `confirm`, `commit`, `COINFLIP_ENABLED`, `MAX_ITEMS` |
| `MineTradeValue.luau` | stardust-equivalent prices | `cardValue`, `packValue`, `runeValue`, `gearValue`, `total` |
| `MineTradeView.luau` | the trade window, mounted in MineClient as `ClientFns.tradeCtl` | `mount` |
| MineServer | action router (`tradeAsk` … `tradeConfirm`), serial registry, policy | `transferSerial`, `isCardSerial`, `runeBusy`, `Verbs.fetchPolicy` |

There is a second, broken entry point. `MineProfileView` has a trade button, but
nothing mounts that view ([social-quests-and-leaderboards](social-quests-and-leaderboards.md)).

## The "pawning off to new players" concern
`roadmap/PRINCIPLES.md` gives direction only (it ranks fifth in [sources-of-truth](../sources-of-truth.md)). Two of its rules apply here:
- **§3 — trade value must share a scale with power.** Trade prices ladder about
  ×2.2 per rarity step. Power can ladder 500×. So a veteran can hand a new player
  something "worth a few thousand dust" that is huge for them. PRINCIPLES says
  this *"cannot be fixed with trade restrictions"*. Its fix is to bind price to
  power, or to make the item not grant power.
- **§5 — sinks must be the cheapest exit.** If giving an item away beats recycling
  it, the recycle sink is decorative.

**Where the code stands against those rules:**
- **Ore tools are not tradeable**, so the 500× ore-tool route that §3 worries
  about is closed today.
- **Pets, runes and gear still move.** Their prices are flat rarity ladders that
  are not tied to their stats.
- **One part of PRINCIPLES is stale.** §8's "pet slots (3→8)" no longer holds;
  everyone has 3 (`MineConfig.effectivePetSlots`).

## Decided by the owner
- **Fossils are gone.** The fossils trade tab went with them (TODO §0.12, `ba345b7`).
- **Runes and gear are being replaced by traits** (TODO §0.17). Runes and gear are still tradeable until stage 3 retires them.
- **Coinflip-off and the 16-item cap** are code choices. No owner decision on them was found.

## State right now
- **Shipped.** TradeService is unchanged since the import, apart from removing the fossils tab.
- **On the ARCHIVE list.** AUDIT §5 says: *"Trading (~1,900 lines) — a trading
  economy before there is an economy."* That is a proposal; the owner's yes to the
  cut list is not recorded, and trading is still wired.

## Gotchas
- **Grep the action names.** The client sends `tradeOffer`, `tradeAccept` and
  `tradeConfirm`, so grepping `TradeService.setOffer` alone misses the router
  (START-HERE §5).
- **Escrow takes items, not equips.** It removes rows and does not unequip
  anything except pets. See the rune notes above.
- **Card serials are permanent.** A card's serial is never regenerated on trade.
  The `mint` comment says the serial is "PPP + 16-hex".

## Open questions
- Should trading ship at launch, or be archived (AUDIT §5)?
- If it ships, should price bind to power (PRINCIPLES §3), or should power-bearing items be untradeable?
- Should runes and gear stay tradeable while they are being retired?
- Should pet and gear runes be detached and returned on trade?

## See also
[cards-and-packs](cards-and-packs.md) · [currencies-and-economy](currencies-and-economy.md) · [enchantments-runes-and-gear](enchantments-runes-and-gear.md) · [forge-and-recycling](forge-and-recycling.md) · [save-data-and-migrations](../code/save-data-and-migrations.md)
