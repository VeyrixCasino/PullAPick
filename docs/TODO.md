# Mine For Cards — Launch TODO and Handoff

**This file is self-contained.** Hand it to an agent with no other context and it
should be able to start work. It carries the orientation, the verified state of the
code, every design decision taken so far with its rationale, and the task list.

Place: "MINE FOR CARDS! SEASON ONE", placeId `73982848847016`,
owned by the **Mine For Cards group, groupId `35326298`**.
Repo: `VeyrixCasino/PullAPick`. Working branch: `claude/vigilant-fermi-aucqjy`.

Last updated: 2026-10-02.

---

# 0. LOCKED RULES — do not relitigate, do not ask again

**0.12 — FOSSILS DO NOT EXIST.** Owner, 2026-10-02. No block spawns one, no pack
drops one, the bench is gone from the plaza. Anything a save held was cashed out
to gems on load at the game's own price. `MineFossils` / `MineFossilEconomy` stay
on disk, dormant, only because that payout needs their prices to be exact —
delete them once the migration has run everywhere. `fossilFind` keeps its KEY (it
was already repurposed to "Ore Finder"); do not rename it.

**0.13 — CHARMS AND SKINS ARE THE BUILD.** Owner, 2026-10-02. The two main parts,
and everything else (pets, hats, faces, runes) is support. Later charms are
better, **but never because the number is bigger** — a charm has a SHAPE, and a
shallow charm of the right shape must be able to beat a deep one of the wrong
shape. A pure magnitude ladder is the thing this rule exists to forbid.

These are the owner's decisions. They are not open questions, they are not
derived from any file in this repo, and no document here overrides them. If a
file in this repo disagrees, the file is wrong.

1. **ORE TIER = THE TOOL'S BREAKING POWER.** A tool forged from ore tier T has
   breaking power T. It reaches **T + 15** tiers of ore: any ore of tier <= T+15
   is mineable by it, anything above is not. Breaking power is NOT upgradeable —
   the only way up is forging from a better ore.
   *(`roadmap/ORE.md` argues ore should not drive power. It is OVERRULED.)*

2. **Breaking power is not damage.** A tool with huge damage still cannot touch
   a block above its breaking power. Two separate gates.

3. **Block strength is a function of layer and zone** — a separate gate from the
   ore reach rule above.

4. **The roster is 82 ores. FINAL.** Event Horizon ores may be added later.

5. **Charms are a NEW system: a rare drop from ORES.** Not from chests. One
   charm per ore.

6. **Skin cases: one per ore, 82 of them.** The old system dropped tools from
   cases. Now an ore case rolls at **2% down to 0.5%** to decide whether you get
   a tool.

7. **Zones, runes and the ore pouch are gem sinks. Gems come from selling ore.**

8. **Big numbers are SERVER-SIDE and always round DOWN.** `MineBigNum`
   (`ServerScriptService/Mine`) is the one formatter. Base 30, three digits a
   step: the 20 named suffixes K..Nod, then the backlog q..z, then positional
   carry. Science form `9.999e^99`. The client renders the server's string.

9. **All currencies read at FOUR significant figures, floored.**
   `MineAbbrev.currency` — 1.234K, 12.34K, 123.4K, 1.234M. Deliberately NOT
   `MineAbbrev.format`, which rounds UP so a block HP label never understates
   the rock. A wallet that rounds up tells a player they can afford something
   they cannot.

10. **The wooden pickaxe is a TUTORIAL pick.** It exists to reach the stone
    pick, handed over in the tutorial, then it is done. Cap 5 levels, coins.
    `TUTORIAL_GRADUATION_TOOL = "stone_pick"`.

11. **Breaking power comes from a tool's BASE STATS — its tier — for now.**
    One rule for every tool: an ore tool's tier is its ore, a shop rung's tier
    is its rung. `BreakPower` is stamped on every Tool instance and the swing
    gate reads it. `MineConfig.toolBreakingPower` is the only function to
    change when breaking power gets its own authored curve.


---

## Where the balance design lives (carried over from main's TODO)

The balance design is **not in this repo.** It is `AGENT_PROMPT.md` (the briefing:
what the game is, what already went wrong, the invariants, the formulas) plus
`PROMPTS.md` (tasks in dependency order), both kept outside version control. Ask
for them before starting balance work.

Three corrections to apply when reading them:

- **`roadmap/` DOES exist on this branch.** Main's copy of this note said it did
  not, and that was true of main — the eleven docs under `roadmap/` came in on
  this branch. `AGENT_PROMPT.md` §13's reading order resolves here. Note that
  `roadmap/ORE.md` carries an **OVERRULED** banner, and §0 wins over all of them.
- **The "Rebalance Numbers" artifact is superseded** by `AGENT_PROMPT.md` on seam
  placement and `REBIRTH_BASE` (artifact ~1,000, briefing ~3,600).
- **The briefing prices seams on a doubling ladder**; shipped code gates on
  `MineDepth.SEAMS`. The pricing *rule* (minutes of local income) is unchanged and
  is what makes either ladder honest.

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
ore roster (STALE at 121 rows; the real roster is 82) + per-ore appearance/glow
data + the unapplied 40-ore Space set).

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
| **The roster is 82 ores. FINAL.** Event Horizon ores may be added later. `MineConfig.ORES` now holds the real 82 rows, merged from the `ore-roster-82` branch, with `ORE_MIGRATION_V2` carrying old saves. Each row carries its own `band`, `home` and `yield`. | User, 2026-10-02 |
| ~~121 ores~~ (superseded, kept to explain the 121s still in the repo) | `MineConfig.ORES`, `MineConfig.luau:2051-2173`. Also stated in `live-config.md:68`, `decisions.md:17,26`, and three places in this file's Done list. Tier 1 `stone` → tier 121 `oganesson`. |
| Ore packs exist as `<id>_ore_pack` | `MineConfig.luau:2511` (`o.packId = o.id .. "_ore_pack"`), `MineZonePacks.luau:244,251` |
| Breaking power config EXISTS; the gate does not | `MineConfig.ORE_REACH = 15`, `toolBreakingPower`, `canBreakOre`, `oreReachCap`. The swing gate is unwired because ore tools cannot be equipped — see below. |
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

> **What counts as decided:** only what the owner has stated. Numbers derived
> from files in this repo are NOT decisions — much of this repo is out of date
> (it still describes a 121-ore roster when the real one is 82). Where a value
> was needed to keep code working, it is labelled a placeholder in the source
> and listed below as awaiting instruction. Do not promote a placeholder to a
> decision by finding it written down somewhere.
>
> **Awaiting the owner's instruction, currently placeholders:**
> - Rarity band cutoffs at 82 (`MineConfig.ORE_BANDS`) — carried over from the
>   stale 121 ladder's proportions purely so bands stay reachable.
> - `TOOL_CRAFT_BASE = 250`, the ore cost to forge a tool.
> - `WOOD_PICK_*` coin ladder and its level cap of 25.
> - The 200-row cap on a player's tool rack.

Newest last. Includes reversals, so an agent does not re-litigate settled calls.

1. **`docs/ore-remake.md` was stale and is now the roster.** It claimed "planning
   only, `MineConfig.ORES` is unchanged". False — the remake landed in `deb8f35` and
   `72b81ed`. Replaced with the roster generated from `MineConfig` — which has
   since turned out to be STALE at 121 rows; the real roster is 82.
   Kept: the LOOKS block (only written record of per-ore glow colour/intensity, since
   `ORES` rows carry no `glow` key), the unapplied 40-ore Space set, the change log.

2. **Ore count is 82. FINAL.** (Event Horizon ores may be added later.) An earlier
   pass argued for 121 off `MineConfig.ORES` and four docs that all trace back to
   it. All of them are stale. `ToolBakers.OreToolBaker` is the authority, and so is
   the user. `MineConfig.ORE_COUNT = 82` is now the single source of truth, and
   rarity bands derive from it as fractions so nothing hardcodes a roster size again.

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
- [ ] **A way to BUY a seam — SHIP BLOCKER, from main.** Depth is gated on coins
  (`MineDepth.SEAMS`, enforced in `MineDigAuth.unlockedForLayer`) and
  `Verbs.buySeam` is live on the `"buySeam"` action, but **nothing fires it.**
  Do not ship the gate without a prompt or every player stops dead at layer 500.
  `MineDepthPlazas` already owns the prompt geometry and is the obvious host;
  `MineDepth.seamPrice(seam, zi)` gives the figure to show.
- [ ] **Ore gem value magnitude.** `MineOrePouch.ORE_GEM_SPREAD` (10^6) sets the
  whole gem faucet: how much more the deepest ore is worth than the shallowest.
  The SHAPE is derived from work and defensible; the magnitude is a placeholder,
  and the user flagged ore balance as the thing that breaks the economy if it is
  wrong. One number, and it is a question with an answer. See §6.1 "Ore pouch".
- [ ] **Zone and rune gem prices.** Flat tables that the ore value curve will
  outrun. Same fix the pouch rungs got — price as a share of income at the depth
  they gate — but the pacing is an owner call.
- [ ] **Delete `MineFossils` / `MineFossilEconomy`** once the retirement migration
  has run for everyone. Dormant, and kept only so the payout uses exact prices.
  Needs a call on how long to leave the window open.
- [ ] **The legacy 31 charms.** Zone grant + gem pack + limited. §0.5 makes charms
  an ore drop; these predate it and still drop. Retire them, or keep both sources?
- [ ] **VIP lost a perk.** It advertised an extra pet seat in three places and can
  no longer deliver one. Replacement perk, or leave it at three?

## 6.1 P0 — launch blockers

### Breaking power

**The rule is locked (§0.1).** Ore tier = breaking power, +15 reach, never
upgradeable. Config is shipped; the gate is blocked on an equip path.

- [ ] **Tool breaking power is strictly a function of the ore the tool is made
      of.** Nothing else feeds it — not level, not damage, not skins, not runes.
      **Not upgradeable.** The only way up is crafting from a better ore.
- [ ] **Block strength is a function of layer and zone.** Those two inputs only.
      The curve is the one number still unspecified.
- [x] **Big-number system shipped** — `MineBigNum` (server-only), base 30, three
      digits a step, always floors, science form `9.999e^99`, capped at four
      significant digits. Wheel verified distinct across 2000 steps.
- [ ] Wire `MineBigNum` into what the server sends, so the client stops
      formatting its own numbers. Nothing calls it yet.
- [x] **Currencies at 4 significant figures, floored**, everywhere:
      `MineAbbrev.currency`, with `shortNum` (client), `money` (shop, runes)
      and the Forge wallet all routed through it.
- [x] **Wooden pickaxe is a tutorial pick** — cap 5,
      `TUTORIAL_GRADUATION_TOOL = "stone_pick"`.
- [x] **Breaking power off base stats, uniform.** `BreakPower` is stamped on
      every tool from its tier, and the gate reads that rather than `OreTier`,
      so a shop rung is measured by the same rule instead of being exempt.
- [ ] **Consequence to check:** shop rungs 1-25 now reach ore tiers 16-40, and
      a forged tier-67 pick already reaches the top ore, so the real forging
      ladder is tier 1 -> 67 in about five steps. Confirm that pacing.
- [x] **Ore reach rule, from the owner: +15 tiers.** A tool forged from ore tier T can
      mine any ore up to tier **T + 15**. Not "looser" in a vague sense — an
      exact, flat reach. Over an 82-ore roster that is ~6 crafting steps from
      the first tool to the last ore.
- [x] **Config shipped** — `MineConfig.ORE_REACH = 15`, `toolBreakingPower(tool)`,
      `canBreakOre(bp, oreTier)`, `oreReachCap(bp)`.
- [x] **Equip path shipped.** `equippedTool()` has an ore-tool branch above the
      chest flagship, `Verbs.equipOreTool` equips/unequips and clears the
      competing overrides, the Forge has an EQUIP button, and scrapping an
      equipped tool takes it out of your hands.
- [x] **Gate shipped.** `swingBlock` refuses any ore where
      `not C.canBreakOre(bp, oreTier)` and fires `weakTool`; the client shows
      red throttled text by the hotbar. Tool BP reads the `OreTier` attribute
      stamped at give time — never `Tier`, which is cosmetic.
- [ ] ~~BLOCKED — ore tools cannot be equipped~~ Verified at the time: `equippedTool()`
      (`MineServer:1556`) has no ore-tool branch and nothing anywhere equips a
      `p.oreTools` row. No equipped ore tool means no ore tier to gate on. Order:
      1. Give `equippedTool()` an ore-tool branch, and the Forge an EQUIP action.
      2. Stamp the ore tier on the Tool instance. **NOT** the existing `Tier`
         attribute — that is `lookTier`, a cosmetic ladder value clamped to the
         shop family's length (`MineServer:4227`). Gating on it is silently wrong.
      3. Gate `swingBlock` on `C.canBreakOre(bp, part:GetAttribute("OreTier"))`
         plus the red hotbar text.
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

- [x] **Ore blocks drop ore directly**, into the pouch, with a toast. Yield
      comes from the roster's own `yield` field via `oreYield`, scaled by the
      `oreYield` boost.
- [x] **Ore cases are THE rare drop. 2%, luck-scaled** (`ORE_CASE_CHANCE`),
      rolling a `<id>_ore_case` on an ore break. There is no second roll inside
      it. Cases are registered per ore in `MineZonePacks` and the lazy-rebuild
      path catches the `_ore_case` suffix alongside `_ore_pack`.
- [x] **Opening one is GUARANTEED: a skin or a charm.** Never a tool, never ore,
      never a dud. `ORE_CASE_CHARM_SHARE = 0.25`, and that quarter is not a taste
      call — 2% × 25% = **0.5%**, exactly the charm rate §0.5 asks for, so the two
      numbers are one decision. A skin gets the same reel ceremony a bought
      temper case gets.
- [x] **Corrected from a wrong first build.** It shipped as a 0.5% drop that then
      rolled 2%→0.5% for a TOOL and paid ore on a miss — two rolls to clear, with
      the likely outcome being ore the block had already dropped.
      `ORE_CASE_TOOL_HI`/`LO` and `oreCaseToolChance` are deleted.
- [x] **The `CHEST_TOOLS` content gap is moot.** It holds only 4 Exotic, 4 Divine
      and 1 Mythic, so any band below Divine walked up the ladder to the same
      single Mythic tool. Cases pay skins and charms now and never touch that
      table, which is what §0.6 described all along.
- [ ] **Migration:** existing saves hold unopened `<id>_ore_pack` rows. Convert to
      banked `p.ores[id]` on load, keeping pack ids as recognised aliases. Do not
      strand inventories.

### Ore pouch (net-new)

`MineOrePouch.luau` (rules + prices), `MineOrePouchView.luau` (panel), a shop tab
beside the Forge.

- [x] The main store for a player's ore. **One way in:** every path that grants
      ore goes through `Dig.addOre`, so the cap is enforced in one place instead
      of the five call sites that hand out ore. A full pouch refuses and says so
      (throttled) rather than silently eating the ore.
- [x] **Upgraded with gems.** Ten rungs, 2,000 → 1,024,000 units.
- [x] **Rung level AND contents survive rebirth**, plus the locks and
      `oresSeen`. The pouch is the only store that crosses a rebirth — that is
      the point of it.
- [x] **Descending rarity by default**, ties on depth then name so the order is
      stable.
- [x] **Filter button top-right.** Cycles rather than opening a menu, and skips
      bands you hold nothing of. Sort cycles beside it (rarity / depth / amount /
      value / name).
- [x] **Per-ore lock.** Sell All can never touch a locked ore — that is what lets
      one confirmation stand in for a prompt per row. A single-row sell still
      works on a locked ore: the lock guards the bulk button, not the row.
- [x] **Sell All at the bottom, behind a confirmation.** Two calls: the server
      prices the sale, the panel shows the server's figures, the same verb with
      `confirm` applies it. Both build the plan from `sellAllPlan`, so the total
      agreed to is the total paid.
- [x] **Selling ore yields GEMS.** The only gem faucet.
- [ ] **STILL THE BALANCE RISK the user flagged. Needs owner numbers.**
      `MineOrePouch.gemValue` is anchored on work — the home rock's HP over the
      ore's yield (`workOf`). The SHAPE (deeper always pays better per unit) is
      defensible; **the magnitude is a placeholder.**
      The dial is `ORE_GEM_SPREAD` — tier-82 worth 10⁶× tier-1 — and the exponent
      is solved from it. **It used to be the exponent itself, and that broke:** set
      to 0.5 against a roster whose depth coordinate plateaued at 21.8 it gave a
      3×10⁸ spread, and on the roster that shipped (coordinate running linearly to
      32.1) the same 0.5 gave 5.9×10¹² — four thousand times wider, for a number
      nobody touched. Asking for a spread instead survives the next model change.
- [x] **Rung prices are derived, not authored**, and had to be: a flat table
      topping out at 520,000 gems was my first cut, and one tier-30 ore unit more
      than covers that. Capacity only grows 512× against income's 3×10⁸. Each rung
      now costs ¾ of a full pouch valued at the ore for its depth
      (`RUNG_COST_SHARE`), so every rung costs the same mining TIME and the prices
      follow `ORE_GEM_SPREAD` on their own.
- [ ] **ZONE AND RUNE GEM PRICES ARE STILL FLAT TABLES** and the ore value curve
      will outrun them the same way it outran my pouch table. They are the other
      two gem sinks; they need the same treatment (price as a share of income at
      the depth they gate) or they become free by mid-game. **Not done — flagged.**

### Charms — one per ore

**A NEW system. Charms drop rarely from ORES — not from chests.**

- [x] One charm per ore (82 charms), **generated from the roster**, not authored.
      `MineCharms.oreCharm(oreId)` is the only way to ask for one. Generated so
      "one per ore" is a property of the code — the tool ladder has already been
      silently mis-pointed once by a roster renumber, and 82 hand-written rows is
      82 chances to repeat it.
- [x] **FIVE SHAPES, not a magnitude ladder** (§0.13). My first cut was the exact
      anti-pattern: one stat, one ramp, so tier 82 strictly beat tier 41 and there
      was one best charm per stat and 81 obsolete ones. Budget still rises with
      tier; what changed is how it is spent. The multiplier is the price of
      reliability — `FOCUS` 1.00× always-on, `PAIR` 1.15× split 60/40, `PACT`
      1.75× minus a real cost, `CONDITION` 2.00× in a moderate window,
      `THRESHOLD` 2.40× in a narrow one. Shape strides 5 against 8 stats, so the
      pair repeats only every 40 ores: **40 (shape, stat) families, each with its
      own best charm.**
- [x] **Two bugs in my own first pass at the shapes, fixed.** The PACT cost was a
      fraction of the BUDGET, so it scaled with the upside: −96% of a stat at
      tier 1 and **−308%** at tier 82, which is not a steep cost but a broken
      number. It is a fraction of the STAT now, −30% to −60%, bounded so it can
      never erase one. And two "conditions" (`deep`, `reborn`) read a high-water
      mark, so they were **permanent once passed** — a 2.4× budget that never
      switches off is not conditional. Every condition is revocable now.
- [x] **Conditions cost something real to hold:** pouch fullness against selling,
      pet count against the pet pillar, skin/no-skin against the other half of the
      build, home zone against where you want to stand. A backpack-fullness
      condition was **dropped rather than shipped broken** — `p.backpack` is the
      bag-ownership table, not a capacity, so it would have silently never fired.
- [x] **The UI says ACTIVE or inactive.** Conditions are pure reads of state the
      profile and snapshot carry identically, so one function serves the live
      boost and the preview. A conditional bonus that looks the same whether or
      not it is paying is the worst thing it can do.
- [x] **RAMP, the sixth shape.** Builds a stack per block broken, resets after
      `RAMP_IDLE_SEC` idle, pays budget × stacks/`RAMP_MAX` — so it is the one
      shape that rewards a long active session rather than a state you set up and
      sit in. **Fed only by real block breaks, never the AFK block:** an idle
      source would let a player park there at full stacks forever, which is a
      permanent bonus wearing a ramp's clothes.
      Uses `os.time()`, not `os.clock()` — the timestamp is persisted and read
      back after a rejoin, and a process-relative clock would read a stale stack
      as freshly earned. `rampFraction` is read-only; `bumpRamp` is the only
      mutator, because a boost calculation that changes state behaves differently
      depending on how often something asks for it.
- [x] **The sixth shape nearly removed variety.** 5 shapes against 8 stats are
      coprime, giving 40 distinct (shape, stat) pairs; 6 and 8 share a factor, so
      plain modulo would have cycled every LCM(6,8) = **24**. The stat index now
      carries an extra `(tier-1)/6` term, making the period 6 × 8 = **48** —
      verified, first repeat is tier 49 against tier 1.
- [x] **Echo, zap and blastRadius are excluded from that pool.** A generated
      table is the last place a stat under review should pick up 82 new sources.
- [x] **A rare drop off ore itself**, via the ore case: 2% case × 25% charm.
- [x] **0.5% drop chance** — falls out of the above rather than being set twice.
- [x] **First charm guaranteed, from either source.** `MineCharms.caseCharmShare`
      returns 1 while you own none, so an ore case pays the charm outright rather
      than spending three cases in four on the half of the build a new player
      cannot use yet. One function owns the rule so the two sources cannot drift.
      The zone grant's own check moved to `MineCharms.ownsAnyCharm` on the way —
      it used `next(p.charms) ~= nil`, which reads a tally left at zero as
      ownership and would have quietly cancelled the guarantee.
- [ ] **Mergeable** into higher tiers.
- [ ] **Decide what happens to the legacy 31.** 15 zone-grant + 15 gem-pack + 1
      limited charm still exist and still drop. §0.5 says charms are an ORE drop;
      these predate it. Left in place deliberately so nobody loses one — **needs
      an owner call** on whether the zone grant and the gem pack are retired.
- [ ] `roadmap/CHARMS.md` is on disk from the merge. Read it, but §0 wins where
      it disagrees.

### Universal recycling

Applies to tools, pets, runes, charms, and anything recyclable added later.

- [ ] Recycle returns **50% in ore and stardust**.
- [ ] Plus an extra amount scaled to the item's value — "decent but not game
      breaking". Needs a curve; propose and get sign-off before shipping.

**Bulk recycle UI** — the flow is built; it is wired into the EQUIPMENT menu so far.

- [x] A **Select** button that puts the menu into selection mode.
- [x] **Bulk select** — tick multiple. **No select-all**, as specified.
- [x] A **Recycle** button that opens a **review screen listing everything about to
      be recycled**, each item's payout and the total — plus anything that cannot
      go, with the reason. The hold used to sit on the SELECT bar and fire
      straight into the scrap, so a player held three seconds over a list they had
      never seen and a total they had never been quoted.
- [x] **Hold 3 seconds to confirm**, on the review screen where there is finally
      something to confirm against. Disabled outright when anything is blocked —
      holding three seconds for a guaranteed refusal is worse than not offering it.
- [x] Server re-validates on confirm. `scrapPlan` is read-only and builds both the
      review and the commit, so the two cannot disagree. **Socketed gear is now
      blocked**, which the old path did not do: a rune in a piece is permanent, so
      scrapping the piece strands it.
- [x] **One transaction — all or none.** The old path scrapped what it could and
      skipped the rest silently; for a *reviewed* batch that is a broken promise.
- [x] **Fixed a real bug on the way:** `packScrapDustFor` was declared BELOW
      `scrapMany`, and a `local function` is not in scope inside a function written
      earlier in the file — the name compiled as a global read, so the pack arm of
      bulk scrapping called a nil value and **threw on every use**. Confirmed with
      a minimal repro under the interpreter.
- [ ] **Extend selection to the other menus** — pets/cards, runes and packs. The
      server already handles all four kinds (`scrapPlan` covers card/rune/gear/
      pack); only the EQUIPMENT tab has the Select UI wired so far.
- [ ] Recycle returns **50% in ore and stardust** plus a value-scaled extra. Still
      needs the curve and sign-off; current payouts are the pre-existing scrap
      rates, not this.

### Ore cases and skins

- [ ] **Ore packs become Ore cases.** Asset names: `{Ore}` for the icon,
      `{Ore}Case` for the case.
- [ ] **82 cases, one per ore.** Not per tool rarity.
- [ ] **The case rolls 2% down to 0.5% to decide whether you get a tool.** The
      old system dropped tools from cases directly; that roll is now the case's.
- [ ] Reuse the **existing charm-find animation** (pull-from-pack) for the case drop.
- [ ] Opening a case yields a **skin that applies to a whole tool family**.
      the real ore count all along. Confirm: one case per ore, 82?*
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
      (Runes, gear, `equippedGear`, pet sockets, charms and the equipped charm
      already carry. The pickaxe itself still needs checking.)
- [x] Ore pouch contents and upgrade level survive rebirth — plus the ore locks
      and `oresSeen`.
- [ ] *Needs confirmation:* an earlier pass planned "rebirth raises coin value" and
      "soften the zone/depth coin multipliers". That was motivated partly by the
      now-reverted coin-zones plan. Confirm whether it still applies.

## 6.2 P1 — boosts, hats, pets

### Hats and faces

- [ ] **Hats cost rebirth tokens**, not gems. A rebirth-token wallet already exists
      (`MineTemper.luau:1`). **Update the tutorial**, which still teaches gems.
- [ ] Hats give **1–2 boosts directly to the player**. Same for pets and faces.
- [x] **Hats are player-only — hats removed from pets.** `p.petHats` is gone, not
      emptied; hats on pets fold into free seats on load. `Verbs.equipPetHat` /
      `unequipPetHat`, `clearGearFromPets` and the pet-hat seat column are all
      removed. Pet rows no longer carry a `hat`, and `Gear.stackPets` takes an
      array of your worn hats rather than two positional args plus the pet's own.
- [x] **Three hat slots, all the player's.** `MineGear.HAT_SLOTS` is the one list
      every reader walks. Tapping a hat fills the seat you are looking at.
- [x] **Two latent bugs fixed on the way.** The load-time slot collapse nil'd every
      slot that was not literally `hat` or `face`, so **`hat2` never survived a
      rejoin**; and Equip Best planned `hat` only, leaving `hat2` holding whatever
      it held. Both came from spelling the seats out by hand.
- [ ] Faces work the same way, with a **bigger effect than hats**.
- [ ] **Hats nerfed substantially.** Re-derive the budget percentages with
      hypothetical tests, not guesses: test each boost alone, then stacked with its
      amplifiers (blast with blast-radius and blast-damage; zap with zap boosters).
- [ ] Add hats and faces as **chest drops**.
- [ ] **Echo must not appear as a buff** on hats or anything else.
- [ ] **Split the hat luck boost** into the specific new luck types: **ore luck**,
      **chest + rare-drop luck**, **pack luck**.

### Pets and boost balance

- [x] **Three pet slots, and no fourth.** `MAX_PET_SLOTS = 3`, equal to
      `STARTER_PET_SLOTS`, which retires the ladder through the clamps that were
      already there. A save that bought its way to eight comes back down on load
      with every pet still owned. Every seat-four surface is closed, not just the
      cap: the gem row, the Robux product, the credits grant, the VIP bump and the
      "Fourth pet seat — VIP unlocks one more team pet" card.
- [x] **VIP's blurb no longer claims an extra pet seat** (three places). It cannot
      deliver one, so it must not say so. **VIP is now one perk lighter — an owner
      call on whether to add a replacement.**
- [x] **Pets follow naturally.** Three causes of the jolt, none of which more
      position smoothing would have fixed: the formation basis was built off raw
      instantaneous velocity (so a strafe jumped every pet sideways by its full
      lateral offset — the spring was chasing a step function); hard thresholds at
      `speed > 1.15` flipped the basis, bob amplitude and bob rate on one frame,
      and strobed when walking right at it; and `pos:Lerp(target, alpha)` has no
      velocity, so it could never overshoot — no wind-up, no follow-through, a
      dead stop. Now: smoothed basis, one continuous `gait` value replacing every
      speed branch, a real damped spring slightly under critical, bob advanced by
      gait rather than wall-clock, and banking into turns.
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

- [ ] **Ore icons + case art: APPLY, do not process.** The art lives at
      `C:\Users\uybuv\Downloads\oreicons`, is the owner's, and cannot be
      dragged in. Do **not** read or transform those images. Upload per §7 and
      wire the asset ids under `{Ore}` and `{Ore}Case` naming.
- [ ] **Regenerate the block FACE textures procedurally** rather than using the
      supplied images: no shadow, every chunk fully on its own face and never
      across a corner, more visible, and a spectrum of the ore's own colour so
      it reads against same-coloured rock.
- [ ] **PR #2 `ore-face-art` does NOT cover this** — owner checked. Do not merge
      it expecting it to fix the faces.
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

**Fossils retired + charms given shapes (2026-10-02):**

- [x] **Fossils are gone** (§0.12). Generation, the break branch, the three
      fossil packs, the three bench verbs, the plaza station, the client panel and
      every dead state read. `reconcileFossilIds` became `retireFossils`, which
      **cashes out pieces and tools once at the game's own price** and tells the
      player — nobody loses a bank they spent hours on. A legacy fossil PACK cashes
      out the same way when opened rather than opening into nothing.
- [x] **Tutorial step 15 repurposed to the ore pouch**, not deleted: `introAdvance`
      walks the steps by NUMBER, so removing 15 would strand every player sitting
      on it.
- [x] **Charms given five shapes** (see §6.1 Charms). Later is better without
      "bigger number is better".
- [x] **Checked that skins are already the other pillar** and left them alone.
      Tempers run +45% (F) to **+750%** (SSS) on a primary, so the two are in the
      same league — and the contrast is right: charms progress with depth, skins
      are the chase (SSS is 0.02%). No magnitude change needed, so none made.
- [x] **`tools/verify/charms.js` is a behavioural check, not another syntax one.**
      It RUNS the real generator against the real roster under a small Roblox stub
      and asserts 21 properties — one charm per ore, every shape used, 48 (shape,
      stat) families, no penalty at or past −100%, no banned stat, conditionals
      paying nothing while unmet, and a ramp that is cold at zero stacks, scales
      with them, expires, and cannot be faked forward with a future timestamp.
      Worth building because the alternative was re-deriving the expected roster in
      Python, which only proves Python agrees with my intent.
- [x] **Switched to a real Luau parser for validation.** `tools/verify/luau-balance.js`
      is a brace-counting heuristic; `luau-analyze` actually parses. Worth it for
      surgery this structural — all 206 files verified, and one of my own
      brace-counting scripts had already aborted mid-batch and silently written
      nothing. **Worth committing a wrapper for this.**

**Earlier batch (ore case correction, charm roster, pouch, hats, pet slots, pet motion):**

- [x] **Ore case rebuilt to the user's correction** — 2% drop, and opening it pays a
      guaranteed skin or charm. The tool roll and the ore consolation are gone.
      `ORE_CASE_CHARM_SHARE = 0.25` ties the 2% and the 0.5% charm rate into one
      number instead of two that must be kept in step.
- [x] **82 ore charms**, generated from the roster, one per ore, with
      `MineCharms.oreCharm(oreId)` as the only accessor.
- [x] **The ore pouch**, end to end: `MineOrePouch.luau`, `MineOrePouchView.luau`,
      a shop tab, `Dig.addOre` as the single way in, four server verbs, rebirth
      carry, per-ore locks, and Sell All behind a server-priced confirmation.
      Rung prices derived from the value curve after a flat table proved wrong by
      eight orders of magnitude.
- [x] **Hats are the player's, three seats**; pet hats removed entirely. Fixed two
      latent bugs: `hat2` never surviving a rejoin, and Equip Best ignoring it.
- [x] **Three pet slots, no fourth**, every purchase surface closed, VIP copy
      corrected.
- [x] **Pet follow rewritten** — smoothed basis, continuous gait, real damped
      spring, gait-driven bob, banking.
- [x] **Five currency formatters** routed through `MineAbbrev.currency` (server
      `_benchNum`, Forge, bench view, leaderboard). Each rounded (a price quoting
      lower than it charges), showed 2–3 significant figures against the rule's
      four, and ran out of suffixes between a billion and a trillion — which ore
      values pass well before the end of the ladder.

**Earlier:**

- [x] `docs/ore-remake.md` replaced with the roster generated from
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
- [x] Ore art ships as packed pixels; 30 hand-made face tiles mapped across the roster
- [x] Ore roster remake with a save migration; 14 renames regenerated
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

1. **Breaking power — the +15 reach is the owner's instruction. Everything else
   about it is NOT decided.** Tool BP = the tier of the ore it
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
2. **Skin cases vs the 82-ore roster.** The old "81 cases" figure almost certainly
   tracked the real ore count. Confirm it is one case per ore at 82.
3. **Recycle bonus curve.** "Decent but not game breaking" needs numbers.
4. **Element roster.** Needed to assign one native build boost per element type.
5. **Rebirth coin value.** Does "rebirth raises coin value / soften zone+depth coin
   multipliers" still apply now that zones stayed on gems?
