# Mine For Cards — Launch TODO and Handoff

**This file is self-contained.** Hand it to an agent with no other context and it
should be able to start work. It carries the orientation, the verified state of the
code, every design decision taken so far with its rationale, and the task list.

Place: "MINE FOR CARDS! SEASON ONE", placeId `73982848847016`,
owned by the **Mine For Cards group, groupId `35326298`**.
Repo: `VeyrixCasino/PullAPick`. Working branch: `claude/vigilant-fermi-aucqjy`.

Last updated: 2026-10-02.

---

# 1. Orientation — how this repo works

Rojo 7.7 project. `default.project.json` maps folders to services:

| Folder | Service |
| --- | --- |
| `src/ReplicatedFirst` | ReplicatedFirst |
| `src/ReplicatedStorage` | ReplicatedStorage |
| `src/ServerScriptService` | ServerScriptService |
| `src/ServerStorage` | ServerStorage |
| `src/StarterPlayer/StarterPlayerScripts` | StarterPlayer.StarterPlayerScripts |
| `src/StarterPlayer/StarterCharacterScripts` | StarterPlayer.StarterCharacterScripts |

File conventions:

- `*.server.luau` = Script, `*.client.luau` = LocalScript, plain `*.luau` = ModuleScript
- A folder with `init.luau` / `init.server.luau` / `init.client.luau` is a script with children
- `*.rbxm` = binary model (581 of them). **Never hand-edit.** Studio's job.
- `*.meta.json` / `*.model.json` = instance properties and attributes
- `*.txt` = StringValue

Scale: 199 `.luau` files. `MineServer.server.luau` is ~14,800 lines.
`src/ReplicatedStorage/Mine/Shared/` alone is ~55,000 lines.

**Not in the repo** (place-file only): Workspace, Lighting, Teams, TextChatService,
`ReplicatedStorage.ToolModels_50` (~80 MB), `ServerStorage.OreShapes`, and
`ReplicatedStorage.Mine.ToolBakers` (see §4). Every service node sets
`$ignoreUnknownInstances`, so Rojo never deletes Studio-only instances.

Connecting Rojo safely: see `docs/rojo-connect.md`. Short version — the only real
risk is a script edited in Studio and never synced back being overwritten by an older
file in `src/`. Syncback first, commit, then connect.

Other docs: `docs/live-config.md` (numbers measured out of the running place),
`docs/decisions.md` (why things are the way they are), `docs/ore-remake.md` (the live
121-ore roster + per-ore appearance/glow data + the unapplied 40-ore Space set).

---

# 2. Environment limits — read before planning

An agent running in a Claude cloud container **cannot**:

- Read anything on the user's Windows machine. Paths like
  `C:\Users\uybuv\Downloads\oreicons` are unreachable. Files must be committed to the
  repo or pasted into chat.
- Connect to Roblox Studio or run Rojo against the live place. **There is no Studio
  MCP server in this session** — verified by tool search; only Vercel, Canva, GitHub
  and Artifact tools are present.
- Upload assets to Roblox. Any upload must be done by the user in Studio, or by an
  agent that genuinely has Studio MCP, following §7.
- Run the game. There are no playtests. Verify by reasoning from source and by the
  Node harnesses in `tools/verify/`.

What it **can** do: read and edit `src/`, run `node tools/*.js` and
`node tools/verify/*.js`, and use git.

---

# 3. Design pillars

1. **Ore is the currency of power.** Ore drops directly, crafts tools, upgrades
   tools. Endgame tools cost a lot of ore.
2. **Breaking power gates progression; damage does not.** A tool with huge damage
   still cannot touch a block above its breaking power.
3. **Skins are the top prize.** Skins become the most desired drop in the game.
   Nerf whatever gets in the way of that.
4. **Rebirth keeps your gear.** Pickaxe, equipment and ore pouch all persist.
5. **Rarity disparity is the dopamine.** No case holds everything.
6. **Server decides, client displays.** Every verb validates server-side.

---

# 4. Verified facts about the current code

Checked directly; cite these rather than re-deriving.

| Fact | Evidence |
| --- | --- |
| **The roster is 82 ores. FINAL.** Event Horizon ores may be added later. `MineConfig.ORES` still holds 121 and is STALE; `ToolBakers.OreToolBaker` is the authority and is not committed. Cutting `MineConfig` to the real 82 gates the Forge recipes, the icons, the charms (one per ore) and the rarity bands. | User, 2026-10-02 |
| ~~121 ores~~ (superseded, kept to explain the 121s still in the repo) | `MineConfig.ORES`, `MineConfig.luau:2051-2173`. Also stated in `live-config.md:68`, `decisions.md:17,26`, and three places in this file's Done list. Tier 1 `stone` → tier 121 `oganesson`. |
| Ore packs exist as `<id>_ore_pack` | `MineConfig.luau:2511` (`o.packId = o.id .. "_ore_pack"`), `MineZonePacks.luau:244,251` |
| Breaking power does **not** exist | 0 files in `src/` match breaking power / block strength. Net-new system. |
| The F–SSS ladder already exists | `MineTemper.GRADE_ORDER = {F,D,C,B,A,S,SS,SSS}`, `MineTemper.luau:22` |
| Temper rarity weights (out of 10,000) | `MineTemper.luau:31` — F 5000, D 2763, C 1250, B 675, A 250, S 50, SS 10, SSS 2. So F 50%, D 27.63%, C 12.5%, B 6.75%, A 2.5%, S 0.5%, SS 0.1%, SSS 0.02%. **Skins inherit exactly this.** |
| Temper magnitude multipliers | `MineTemper.RARITY_MULT` F 0.45 → SSS 7.50; `PROC_RARITY_MULT` F 0.30 → SSS 1.30 |
| Runes already draw off the temper ladder | `MineRunes.luau:190-219` reads `MineTemper.RARITY_WEIGHTS`; a rune drop stops at five tiers |
| A rebirth-token wallet already exists | `MineTemper.luau:1` — "One wallet with rebirth skill tokens" |
| Bench verbs exist, uid-keyed | `Verbs.upgradeOreTool` `MineServer.server.luau:13375`, `Verbs.recycleOreTool` :13441, dispatch :13491-13492, client fires `MineClient.client.luau:4512,4515` |
| Two forge/bench views already exist | `MineForgeView.luau` 780 lines, `MineBenchView.luau` 239 lines. Reconcile; do not add a third. |
| `MineBags` is coin-only today | `MineBags.luau:7` — "Coin prices only. Never gems — zone buyCost is the gem sink." |
| **`ToolBakers.OreToolBaker` is NOT committed** | No `ToolBakers` folder under `src/ReplicatedStorage/Mine/`, and **zero references** to `ToolBakers`/`OreToolBaker` anywhere in `src/`. It exists only in the place file. |
| Ore builds tools **and** upgrades them | The two comments asserting the opposite (`MineZonePacks.luau:195`, `MineServer.server.luau:524`) were removed. A grep for "ore cannot/never build", "never builds a tool" and "only upgrade one" now returns nothing. The *code* still only upgrades — the build path lands with the Forge. |
| `ToolBakers.OreToolBaker` **houses every ore currently in the game** | Place-file only; absent from `src/` with zero references. It is an ore data source, not just a baker, so syncing it back may reveal ore rows or fields the repo does not have. |
| No gem→ore or ore→ore purchase path found | Grep over `src/` found only `gemFind` (`MineSkillData.luau:98`) and a rune-fuse gem penalty (`MineScrolls.luau:11`) |
| Duplicate pet module | `MineEHPets.luau` and `MineEventHorizonPets.luau` are byte-identical (md5 `0a8c6c6612ba54ae42b9310d450d8059`). Consumers read the short name first, so the long one is 34 KB that never loads. |
| No CI | Repo has no `.github/` directory; PR #5 shows 0 check runs. |

---

# 5. Decision log (transcript)

Newest last. Includes reversals, so an agent does not re-litigate settled calls.

1. **`docs/ore-remake.md` was stale and is now the roster.** It claimed "planning
   only, `MineConfig.ORES` is unchanged". False — the remake landed in `deb8f35` and
   `72b81ed`. Replaced with the live 121-ore roster generated from `MineConfig`.
   Kept: the LOOKS block (only written record of per-ore glow colour/intensity, since
   `ORES` rows carry no `glow` key), the unapplied 40-ore Space set, the change log.

2. **Ore count is 121, not ~80.** Settled against code and four docs. If ~80 is what
   you see in game, that is the depth gate: ores are spread across `D 0 → 32.09` and
   the spread curve only rolls ores near your current `D`.

3. **Breaking power is separate from damage.** A tool can have 1000 damage and still
   be unable to scratch a block. Not upgradeable — the only way up is a better tool.

4. **Ore packs are being removed. REVERSED a Claude objection.** Claude argued the
   pack-opening animation was a dopamine beat worth keeping. User overruled: packs
   yield nothing but ore 99–99.5% of the time and are a pain. Ore drops ore directly.
   Rare drops move to **cases**.

5. **Zones stay on GEMS. REVERSED an earlier plan.** An earlier pass planned to move
   zones to coins and bags to gems. User reverted: zones stay gems, runes stay gems.
   The game needs strong gem sinks. `MineBags.luau:7` stays accurate for zones.

6. **Runes are NOT the per-ore thing — charms are. REVERSED.** An earlier pass had
   runes becoming one-per-ore, tool-only, one slot, permanent bind. User changed their
   mind: runes keep their current role and stay on gems. **Charms** become one-per-ore.

7. **Gem sinks are: zones, runes, the ore pouch.** Gems are earned by selling ore from
   the pouch.

8. **Breaking power inputs fixed.** Tool BP comes strictly from the ore the tool
   is made of. Block strength comes from layer and zone. Ore strength is
   predetermined but looser than the surrounding rock, so ores are not the wall.
   Enchants stop applying to ordinary rock past a depth band, but keep working on
   ore at any depth.

9. **Ore cannot be bought or upgraded. REVERSED an earlier idea.** The user
   dropped the ore-upgrade concept: nothing may let gems buy better ore, and
   nothing may let ore buy or upgrade into better ore. Ore is mined, period.
   (Tool upgrades paid in ore are unaffected — that is ore spent on tools.)

10. **Skin / temper crates are ore-only purchases.** No gems, no coins.

11. **Hat crates do not scale with rebirth.**

12. **Ore builds tools.** Settled. The two source comments asserting the opposite
    were deleted rather than annotated, at the user's instruction to remove
    anything outdated.

13. **The skin system inherits the old tool system.** Whatever the tool system was
    before — the rarity ladder and the chase — becomes the skin system. Tools are
    crafted; skins are hunted.

14. **`OreToolBaker` is an ore data source**, not merely a baker: it houses every
    ore currently in the game. That is why it must be synced back before Forge or
    roster work, and diffed against `MineConfig.ORES`.

15. **Skins replace tempers as the top prize**, at the same drop rates tempers have
   today. Anything that gets in the way of skins being the most desired buff may be
   nerfed.

---

# 6. The TODO

## 6.0 Blocked — needs the user, not an agent

- [ ] **Ore icon source is unreachable.** `C:\Users\uybuv\Downloads\oreicons` is on a
  local Windows drive. Commit it (suggest `tools/oreart/src/`) or paste it. Nothing in
  the icon/case/texture pipeline can start until then.
- [ ] **`ToolBakers.OreToolBaker` is uncommitted, and it houses every ore in the
  game.** Confirmed absent from `src/` with zero references anywhere. This is not
  just a baker — it is an ore data source, so it may hold ore rows or fields that
  `MineConfig.ORES` does not. **Sync it back and diff it against `MineConfig.ORES`
  before any Forge, recipe or icon work**, or that work is built on a partial
  roster. Procedure: `docs/rojo-connect.md` §"Pulling Studio's state into src/".
- [ ] **Connect Rojo.** Never attached. Safe once the syncback above is done.
- [ ] **Asset uploads.** No agent here can upload to Roblox. All uploads follow §7.

## 6.1 P0 — launch blockers

### Breaking power (net-new)

Inputs are settled. The numeric curves still need sign-off.

- [ ] **Tool breaking power is strictly a function of the ore the tool is made
      of.** Nothing else feeds it — not level, not damage, not skins, not runes.
      **Not upgradeable.** The only way up is crafting from a better ore.
- [ ] **Block strength is a function of layer and zone.** Those two inputs only.
- [x] **Ore reach rule settled: +15 tiers.** A tool forged from ore tier T can
      mine any ore up to tier **T + 15**. Not "looser" in a vague sense — an
      exact, flat reach. Over an 82-ore roster that is ~6 crafting steps from
      the first tool to the last ore.
- [ ] Implement the +15 reach check server-side, beside the layer+zone gate.
- [ ] Server-authoritative gate: server rejects any dig where
      `tool.breakingPower < block.strength`. Client may predict; server decides.
- [ ] Red hotbar text: "Your tool is too weak to damage this block." Throttled.
- [ ] **Enchants must not affect blocks in layers that are too deep — ores
      excepted.** An enchant keeps working on ore at any depth, but stops applying
      to ordinary rock past its depth band. Needs a depth ceiling per enchant.
      No enchant/depth coupling exists in `MineConfig` today; enchant code is
      spread across `MineRunesView`, `MineForgeView`, `MineShopView`,
      `MineInventoryView`, `WorldBuilder`, `MineShopFronts`, `GroupWheelService`.
- [ ] Document damage ≠ breaking power everywhere both appear.

### Ore drops ore

- [ ] Ore blocks drop ore directly. Remove the `<id>_ore_pack` drop path
      (`MineConfig.luau:2511`, `MineZonePacks.luau:244,251`).
- [ ] **Migration:** existing saves hold unopened `<id>_ore_pack` rows. Convert to
      banked `p.ores[id]` on load, keeping pack ids as recognised aliases. Do not
      strand inventories.

### Ore pouch (net-new)

- [ ] The main store for a player's ore.
- [ ] **Upgraded with gems.** Upgrade level and contents **both survive rebirth** —
      the upgrade process does not reset.
- [ ] Opening shows all owned ores, **sorted by descending rarity by default**.
- [ ] **Filter button top-right** with the full set of sort options.
- [ ] **Lock individual ores** so Sell All skips them.
- [ ] **Sell All button at the bottom**, with a **confirmation dialog**.
- [ ] **Selling ore yields GEMS.** This is the gem faucet.
- [ ] **BALANCE RISK, flagged by the user:** if ore values are not balanced this
      breaks the economy. Model the gem income curve against the gem sinks (zones,
      runes, pouch upgrades) before shipping. Do not ship on guessed numbers.

### Charms — one per ore

- [ ] One charm per ore (121 charms).
- [ ] **0.5% drop chance**, excluding the first Coal Charm (the starter, guaranteed).
- [ ] **Mergeable** into higher tiers.

### Universal recycling

Applies to tools, pets, runes, charms, and anything recyclable added later.

- [ ] Recycle returns **50% in ore and stardust**.
- [ ] Plus an extra amount scaled to the item's value — "decent but not game
      breaking". Needs a curve; propose and get sign-off before shipping.

**Bulk recycle UI** — in *every* inventory menu that houses recyclables (pets,
hats, faces, tools, runes, charms, and anything recyclable added later):

- [ ] A **Select** button that puts the menu into selection mode.
- [ ] **Bulk select** — go through and tick multiple items.
      **No select-all.** Every item in a recycle batch is ticked deliberately.
- [ ] A **Recycle** button that opens a **review screen listing everything about to
      be recycled**, with the total return.
- [ ] **Hold 3 seconds to confirm.** Not a click — a hold, so a bulk recycle can
      never happen by accident.
- [ ] Server re-validates the whole selection on confirm: every uid is owned,
      unlocked and recyclable. The client's list is a request, never the authority.
- [ ] One transaction — all items recycle or none do. No partial payout.

### Ore cases and skins

- [ ] **Ore packs become Ore cases.** Asset names: `{Ore}` for the icon,
      `{Ore}Case` for the case.
- [ ] A case drops **only when you find a tool skin**. This replaces the old
      rare-tool drop entirely.
- [ ] Reuse the **existing charm-find animation** (pull-from-pack) for the case drop.
- [ ] Opening a case yields a **skin that applies to a whole tool family**.
- [ ] **81 skin cases**, one per tool rarity.
      *Open question — 81 does not divide into 121 ores; confirm the mapping.*
- [ ] **Drop rates identical to tempers today**: F 50%, D 27.63%, C 12.5%, B 6.75%,
      A 2.5%, S 0.5%, SS 0.1%, SSS 0.02% (`MineTemper.RARITY_WEIGHTS`).
- [ ] **Naming**: every skin name states which ore it is and what type of skin.
- [ ] **A skin must not change the tool's colour.** It is a wrap — a cool, easily
      duplicatable look that canvas can mass-produce.
- [ ] Rename tempers → skins across `MineTemper.luau` (537) and its views. Keep
      `LEGACY_RARITY` / `normalizeRarity` so old saves load.
- [ ] **The skin system takes over what the tool system used to be.** The old
      rare-tool-drop mechanics — rarity ladder, drop pacing, the chase — move onto
      skins wholesale. Tools stop being the chase item; they are crafted from ore.
      Skins become the thing you hunt.
- [ ] Nerf anything that competes with skins for "most desired buff".

### The Forge (was the Blacksmith)

- [x] **CRAFT / UPGRADE tabs** in the Forge detail pane. The first cut inferred
      the mode from ownership, so craft recipes silently did not exist for any
      tool already owned and the panel looked like it had no crafting at all.
      The mode now defaults by ownership but is always switchable.
- [x] **Notification badges sit on the top-right corner**, half outside the
      plate, instead of inset two pixels inside it where they read as part of
      the button's own label. `mkBadge` clears `ClipDescendants` on the plate,
      since a badge hanging outside is otherwise cropped.
- [x] **The Forge is the front line.** It is first in the tab strip, relabelled
      from "Upgrade" to "Forge", and is the tab the shop now opens on. The
      coin-shop families are the second line behind it, and a COIN SHOP button
      in the Forge header routes down to them. The button is only drawn when
      the host supplies `onCoinShop`, so `MineForge` never requires
      `MineShopView` — that would be a cycle, since ShopView mounts the Forge.
      `paint()` falls back to the first coin-shop family if the Forge module
      ever fails to require, because a missing panel on the default tab would
      otherwise be a blank shop on open for every player.
- [x] **Forge shell built** — `MineForge.luau`. Vertical rail of **every tool in
      the game** down the left, detail pane on the right: CRAFT when unowned,
      UPGRADE when owned. Mounted in place of `MineBenchView` on the shop's
      Upgrade tab (same `{refresh, root}` contract, same pcall guard).
      `MineBenchView` is now superseded and can be deleted once the Forge has
      its own front.
- [ ] `MineForgeView.luau` (780, temperaments) still needs folding in as the
      skin/rune application area — see below.
- [ ] Keep the full-screen 3D display from `583d9ad`.
- [x] **Vertical scrolling recipe list**, and the tool rail is vertical on the
      left-hand side as specified.
- [x] **Show only discovered ores**, with the amount each recipe needs.
      `discoveredOres()` prefers an explicit `snapshot.oresSeen` set and falls
      back to ores currently held — which under-reports but can never
      over-report, so an unseen ore cannot leak its name, tier or colour.
- [x] **Depth sheet extracted and documented** — `docs/depth-sheet.md`,
      generated by `tools/gen-depth-sheet.js` from the live `MineDepth.SECTIONS`.
      Carries the exact HP equation, the section-size progression, the per-band
      step ratios and the zone 1-10 table to depth 10,000.
- [x] **`oresSeen` ships end to end.** `p.oresSeen` is a grow-only set on the
      profile, seeded on load from banked `p.ores` so existing saves keep what
      they already found, marked at both grant sites (mining and recycle),
      sent in the snapshot, copied in `MineShopView.setState` and read by the
      Forge. A recipe no longer vanishes when the last unit of that ore is
      spent. No new top-level locals: `MineServer` sits at 197 of 200 and
      `Verbs` is declared below the mining grant, so the marks are inlined.
- [x] **Separate upgrades area** — the detail pane switches to UPGRADE for an
      owned tool: level, next step's price, +1 / +10 / MAX and SCRAP.
- [ ] Runes and skins are **not** applied there yet. That is `MineForgeView`'s
      temperament UI, which still has to move into the Forge's upgrade pane.
- [ ] **Full inventory shown in the Forge**, bag and ore pouch included. Only a
      wallet strip (coins / gems / dust) exists so far.
- [ ] Server owns crafting: ore debited and tool minted in one transaction. No
      client-supplied costs, no partial debits on failure.

### Tools craftable and upgradeable with ore

- [x] Craft recipes keyed by ore. `MineConfig.toolCraftCost(tier, typeMult)`
      prices off the same `toolCostMult` the level curve uses, so one curve
      governs both. `TOOL_CRAFT_BASE = 250` is the single knob.
- [ ] The crafting ore must also set the tool's **breaking power** — blocked on
      the breaking-power curves (open question 1).
- [ ] Upgrades cost ore, **a lot of it** — endgame tools are a real grind.
- [ ] Keep the uid-keyed contract of `upgradeOreTool` / `recycleOreTool`.

### Economy removals — ore cannot be bought or upgraded

User reversed the ore-upgrade idea entirely. Ore is earned by mining, full stop.

- [ ] **Remove any path where gems buy better ore.**
- [ ] **Remove any path where ore buys or upgrades into better ore.**
      No ore merging, no ore tier-up, no ore trade-up.
- [ ] *Audit status:* a first grep found **no such path**. The only gem/ore
      couplings are the `gemFind` skill stat (`MineSkillData.luau:98`) and a
      rune-fuse gem penalty (`MineScrolls.luau:11`), neither of which buys ore.
      Confirm exhaustively before closing, and add a standing rule so it does not
      creep back in.
- [ ] **Skin / temperament crates are buyable with ORE only.** Not gems, not
      coins, not anything else.
- [ ] **Hat crates must not increase on rebirth.** Find and remove any
      rebirth-scaled hat-crate yield.

### Rebirth

- [ ] **Gear survives rebirth** — pickaxe and all equipment. Audit every wipe path.
- [ ] Ore pouch contents and upgrade level survive rebirth.
- [ ] *Needs confirmation:* an earlier pass planned "rebirth raises coin value" and
      "soften the zone/depth coin multipliers". That was motivated partly by the
      now-reverted coin-zones plan. Confirm whether it still applies.

## 6.2 P1 — boosts, hats, pets

### Hats and faces

- [ ] **Hats cost rebirth tokens**, not gems. A rebirth-token wallet already exists
      (`MineTemper.luau:1`). **Update the tutorial**, which still teaches gems.
- [ ] Hats give **1–2 boosts directly to the player**. Same for pets and faces.
- [ ] **Hats are player-only — remove hats from pets.**
- [ ] **Reduce to 3 clothing slots.**
- [ ] Faces work the same way, with a **bigger effect than hats**.
- [ ] **Hats nerfed substantially.** Re-derive the budget percentages with
      hypothetical tests, not guesses: test each boost alone, then stacked with its
      amplifiers (blast with blast-radius and blast-damage; zap with zap boosters).
- [ ] Add hats and faces as **chest drops**.
- [ ] **Echo must not appear as a buff** on hats or anything else.
- [ ] **Split the hat luck boost** into the specific new luck types: **ore luck**,
      **chest + rare-drop luck**, **pack luck**.

### Pets and boost balance

- [ ] **Far fewer pets grant blast on normal pickaxes.** At current strength this is
      game-breaking and makes every other pet stack pointless.
- [ ] **Fewer pets affect blast radius.**
- [ ] **Nerf zap and blast.**
- [ ] **Almost no effect should do full pickaxe damage** without dedicated amplifiers
      (+blast damage and the like). This is the main lever against builds collapsing
      into one another.
- [ ] Make pet and hat buffs **more easily matchable with setups**.
- [ ] Add **drill-friendly** boosts.
- [ ] **Guardrails** preventing too many boosts overlapping.
- [ ] **Not all packs spawn all pets** — give each pack a pet subset
      (`MinePackConfig.luau` / `MinePetRoster.luau`).

### New build boosts

Each element type gets one of these as its native boost. *The element roster is needed
to finish the mapping.*

User-specified:

- [ ] **Earthquake** — the block tremors/shakes and takes **20% tool damage per
      second**. Cannot stack. Maximum 5 blocks.
- [ ] **Ricochet** — after breaking a block the effect jumps to one nearby block.
      Happens at most once; no chain reactions.

Claude-proposed (need sign-off). Chosen to be mostly non-damage so they do not
collide with blast and zap, which is the guardrail asked for:

- [ ] **Fracture** — breaking a block lowers adjacent blocks' *strength* (not HP) by
      X% for N seconds. Interacts with breaking power instead of damage, so it opens
      progression rather than inflating DPS.
- [ ] **Resonance** — consecutive breaks of the *same ore* build a stacking damage
      bonus that resets when a different ore is broken. Rewards deliberate mining.
- [ ] **Siphon** — a break has a chance to yield ore without consuming the block's
      normal drop roll. Pure economy, zero damage overlap.
- [ ] **Permafrost** — damage dealt to a block persists longer before it heals.
      Helps slow/heavy builds without raising peak damage.

## 6.3 P1 — art pipeline

- [ ] **Ore icons for all 121 ores** — `{Ore}` naming.
- [ ] **Ore case art** — `{Ore}Case` naming.
- [ ] **Ore block textures, rebuilt on canvas.** The supplied images have problems:
  - small specks used as ore chunks
  - chunks half-off the block, so a 6-sided application does not line up
  - a weird little shadow on each chunk
  Requirements: **no shadow**; **every chunk fully on its own face**, never on a
  corner or crossing into a neighbouring block; **more noticeable** overall; and use
  **a spectrum of the ore's colour** so an ore stays visible against a section that
  happens to share its colour.
- [ ] Wire uploaded ids into the real modules (`MineIcons`, pack ART, mesh tables) and
      record them in that feature's handoff file. An uploaded asset nothing references
      is as good as lost.

## 6.4 P2 — after launch

- [ ] 28 legacy packs onto the ore system in `MinePackConfig`: anomaly, apex, ashen,
      cinder, clay, cobalt, crimson, end, heirloom, hopper, iron, loam, magma, night,
      omen, shadow, shiny, slate, void, plus the gear/rune/fossil families.
- [ ] Luck → Treasure Hunter refactor. 47 `luck` references. Names floated: Divining
      Rod, Loadstone, Assayer's Eye. Overlaps with the luck split in P1.
- [ ] Zone-1 case rates lower. `MineZonePacks.cardOdds(zoneIndex, heat)` takes the
      zone index and ignores it.
- [ ] Chests spawn everywhere but supremely rare, like ore.
- [ ] Space ores (40, separate set) — spec in `docs/ore-remake.md`, unapplied.
- [ ] Tool generator LOOKS table needs the live roster.
- [ ] Export `OreShapes` and other place-only instances to `.rbxm`.
- [ ] Delete the duplicate Event Horizon pet module (34 KB that never loads).
- [x] **Coin shop moved to the second line**, reachable from the Forge header.
- [ ] **Decide whether the coin shop survives at all.** Kept and working for
      now; flagged for possible removal. Do not polish it before that call.
- [ ] Event Horizon `minRebirth` is 0 while its surface is 1.30e9 HP.

## 6.5 Deferred, with a reason

- [ ] **1.5× per 25 layers HP curve.** Not applied. Makes L4921 1.4e23× harder and
      breaks every hand-tuned chest and fossil tool. **Breaking power may remove the
      need for this entirely** — decide before spending time on it.
- [ ] **Chests → packs only.** Superseded by the chest table rework and by skins and
      hats moving into chests.

---

# 7. Asset upload rules (group-owned game)

**Owner context:** the experience is owned by the **Mine For Cards group,
`groupId = 35326298`**, not the personal iPressBars account. Every new image, mesh,
model, audio and decal must be created **as the group**, so assets stay with the game
and do not land in a personal inventory nobody else can manage.

**Do**

- **Open the correct place first.** Edit the live group experience in Studio (place
  `73982848847016`). Asset Manager uploads go to whoever owns the open game.
- **Set Creator = group on every upload.**
  - Asset Manager → Import, with the group place open (preferred for images/audio/meshes)
  - 3D Importer: enable Upload to Roblox, set Creator to Mine For Cards, enable Add to
    Workspace if the place must use a private asset
  - Open Cloud / API: `creationContext.creator.groupId = "35326298"` — never `userId`
    for production assets
  - The API key must be a **group** key with create/configure development items
- **Keep assets in group / experience inventory.** Prefer Asset Manager under the open
  game, or Group Inventories → Mine For Cards. Roblox **cannot move assets between
  user and group inventories**, so uploading to My Inventory "for now" is permanent.
- **Avoid collisions.** Unique prefixed names: `mfc_<feature>_<name>_vN`
  (e.g. `mfc_pack_loam_v2`, `mfc_tool_ironvine_mesh`). Folders by feature under group
  inventory (`packs/`, `tools/`, `ui/`, `audio/`). Version the name or replace the id
  in code; do not re-upload the same file under a new generic name.
- **In code use stable `rbxassetid://…`**, not `rbxgameasset://…` unless you accept
  place-local name coupling.
- **Wire ids into config.** After upload and moderation, paste ids into the real
  modules and record them in that feature's handoff json/md.
- **Permissions.** The uploading account needs the group role *Create and configure
  development items*. Private assets used in-place need the experience granted use.

**Don't**

- Upload as iPressBars / personal creator for anything that ships.
- Treat random Creator Store meshes as the long-term source of truth without copying
  into group inventory.
- Reuse another owner's inventory asset as the canonical id without consent.
- Rely on renaming collisions in Asset Manager — names are for humans, `rbxassetid` is
  the real id.

**Verify before shipping**

1. Asset Manager filtered to group Mine For Cards: the new asset is listed and its
   creator is the group.
2. The id loads in-game in a fresh session.
3. Code references the new `rbxassetid://…`, not an old personal upload.

**If using Studio MCP `upload_image`:** it uploads through the logged-in Studio
session and open place. Confirm the open place is the group experience *before*
uploading, and confirm afterwards that returned ids appear under group/universe
inventory. **If creator shows as iPressBars, stop and re-upload with
Creator = Mine For Cards.** Do not ship personal-owned ids.

---

# 8. Done

- [x] `docs/ore-remake.md` replaced with the live 121-ore roster, generated from
      `MineConfig.ORES`; LOOKS/glow block, Space set and change log preserved
- [x] `docs/TODO.md` rebuilt as this handoff
- [x] **Forge, first slice.** `MineForge.luau` (view), `MineConfig.toolCraftCost`
      / `woodPickCoinCost` / `isCoinTool`, server `Verbs.craftOreTool` and
      `Verbs._upgradeCoinTool`, `craftOreTool` dispatch, client
      `onCraftOreTool`, and the ShopView mount swapped from `MineBenchView` to
      `MineForge`. The wooden pickaxe is the only tool that levels on coins
      (cap 25); every other tool levels on its own ore plus stardust.
- [x] Removed the two outdated "ore cannot build a tool" claims
      (`MineZonePacks.luau`, `MineServer.server.luau`). Grep for the phrasings
      now returns nothing.
- [x] `rokit.toml` pins `rojo-rbx/rojo@7.7.0` (it previously pinned nothing, so
      `rokit install` was a no-op)
- [x] `.vscode/` — Rojo + Luau LSP + StyLua recommendations, sourcemap autogeneration,
      tasks for serve / sourcemap watch / place build / both syncback steps
- [x] `docs/rojo-connect.md` — the safe-connect runbook and loss matrix
- [x] `.claude/settings.json` — `bypassPermissions` with a deny list that blocks
      `.rbxm` hand-edits, place files, the export inbox, history-rewriting git and
      credential paths
- [x] Shop stage goes full screen (visual pass still unrun)
- [x] Blacksmith bench verbs — upgrade and recycle, uid-keyed so a reordered bag
      cannot upgrade the wrong tool. Proven over 550 levels.
- [x] Every owned instance carries a uid. Quantity maps (charms, tempers, eventTools,
      ores, tools) deliberately keep counts — instancing them would grow the save.
- [x] Echo stripped from every pet, all 140 kept (45 main + 12 Event Horizon)
- [x] Ore art ships as packed pixels; 30 hand-made face tiles mapped to all 121 ores
- [x] Ore roster remake, 121 ores, with a save migration; 14 renames regenerated
- [x] Chest tables redone: hats and charms in, gems out
- [x] Blacksmith upgrade model: per-tool 1–1000 scale, flat 50% recycle
- [x] Wormhole bag autosell + live-ticking timers
- [x] Client-killer audio bug (`CompressorSoundEffect.Gain` doesn't exist)
- [x] Item bag: 500 base, +100 a rung, gems `100 × 1.08^x`, `0/500` readout
- [x] First pickaxe free from the Blacksmith, "Wooden Pickaxe"
- [x] Ore spawn curve tuned to the rarity targets; Ore Finder enchant
- [x] Depth: L4921 flatline removed, Big Bang unpinned to zone index 11
- [x] Upgrade calculator: tools, costs, recycle, drops, rebirth, zones panel

---

# 9. Standing rules

- **No pity systems.** No floors, no guarantees after N.
- **Don't cripple the datastore.** Ore ids are load-bearing twice — `p.ores[id]` is
  banked material and packs are `<id>_ore_pack`. Any roster change needs an id→id
  migration keeping old ids as aliases. The ore-drops-ore change is exactly this.
- **No limits on the upside.** Infinitely lucky is the point.
- **Server decides, client displays.** Craft, upgrade, rune bind, skin apply, sell-all
  and the breaking-power gate all validate server-side. A modified client gains
  nothing but a wrong picture.
- **Breaking power is not damage.** Say so wherever both appear.
- **Gem sinks are zones, runes and the ore pouch.** Gems come from selling ore. Do not
  move zones off gems.
- **Echo is not a buff.** It must not appear on hats, pets or anything else.
- **No effect does full pickaxe damage** without its dedicated amplifier.
- **Ore is mined, never bought.** Nothing may let gems buy ore, or ore buy or
  upgrade into better ore. Spending ore on tools is fine; spending anything on ore
  is not.
- **Skin and temper crates cost ore only.**
- **Hat crates do not scale with rebirth.**
- **Uploads are group-owned.** §7 is not optional.
- Studio and Cursor edit these same scripts concurrently. Anchor every edit on unique
  surrounding text, never line numbers alone, and re-read before committing.
- **Kill stale comments on sight.** A comment asserting a contract the design has
  moved past is worse than no comment. If you change a rule, grep for every place
  the old rule is written down and fix them in the same commit.
- **Verify before claiming done.** No playtests — reason from source, run
  `tools/verify/*.js`, paste output.

---

# 10. Open questions

1. **Breaking power — SETTLED, implement it.** Tool BP = the tier of the ore it
   is made of. A tool reaches **15 ore tiers above its own**: an ore of tier T is
   mineable by any tool forged from tier >= T-15. Across 82 ores that is ~6
   crafting steps end to end. Block strength stays f(layer, zone) and is a
   separate gate from the ore rule. Still open: the depth band past which each
   enchant stops applying to non-ore rock.
2. ~~**Breaking power — inputs settled, numbers still open.**~~ Tool BP = f(ore the
   tool is made of); block strength = f(layer, zone); ore strength predetermined and
   looser. What is still needed: the actual curve shapes, and the depth band past
   which each enchant stops applying to non-ore rock. Highest-leverage remaining
   unknown — the rest of P0 is paced by these numbers.
2. **81 skin cases vs 121 ores.** 81 does not divide into 121. Is it 81 tool
   rarities/families rather than per-ore, and how does `{Ore}Case` naming map onto 81?
3. **Recycle bonus curve.** "Decent but not game breaking" needs numbers.
4. **Element roster.** Needed to assign one native build boost per element type.
5. **Rebirth coin value.** Does "rebirth raises coin value / soften zone+depth coin
   multipliers" still apply now that zones stayed on gems?
