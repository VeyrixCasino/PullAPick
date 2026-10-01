# TODO — Launch plan

Mine For Cards is being **remade**, not patched. The goal is a fast path to launch
with a loop that feels grindy, fair and dopamine-heavy. This file is the backlog of
record; it is re-checked after every prompt.

Design pillars for the remake:

1. **Ore is the currency of power.** Ore drops directly, crafts tools, upgrades tools,
   and is the only source of runes. Endgame tools cost *a lot* of ore.
2. **Breaking power gates progression, damage does not.** A tool with huge damage
   still cannot touch a block above its breaking power.
3. **Rebirth keeps your gear.** Progression moves to coins and breaking power.
4. **Rarity disparity is the dopamine.** Skins and runes swing wide; no case holds
   everything.

---

## Blocked — needs you, not me

- [ ] **The ore icon source is unreachable.** You pointed at
  `c:\Users\uybuv\Downloads\oreicons\src.txt`. This session runs in a Linux cloud
  container with no access to your `C:` drive, so I cannot open it. Pick one:
  copy it into the repo (e.g. `tools/oreart/src.txt`) and commit, or paste its
  contents into chat. Until then the icon task below cannot start.
- [ ] **Connect Rojo.** `rojo serve` has never been attached from Studio, so none of
  the committed source is live. Safe to connect — every service node in
  `default.project.json` sets `$ignoreUnknownInstances`, so Studio-only instances
  (Workspace, Lighting, Teams, TextChatService, `ToolModels_50`, `OreShapes`) survive.
  Syncback first if you have unported Studio edits; see `docs/rojo-connect.md`.

---

## P0 — the remake core (launch blockers)

### Breaking power (new system)

Nothing in `src/` references breaking power today — this is net-new.

- [ ] **Block strength per layer and per ore.** Every layer gets a strength
  requirement; every ore gets its own, independent of its tier's HP. Strength is a
  *gate*, not a damage number.
- [ ] **Tool breaking power.** A stat on the tool, set at craft time by the ore it is
  made from. **Not upgradeable** — the only way up is crafting a better tool.
- [ ] **The gate, server-authoritative.** The server rejects any dig where
  `tool.breakingPower < block.strength`. The client may predict, but the server
  decides; a spoofed client must gain nothing.
- [ ] **Feedback.** Red text by the hotbar: "Your tool is too weak to damage this
  block." Fires on the rejected dig, throttled so it cannot spam.
- [ ] **Keep damage orthogonal.** `MineConfig.toolCostMult` / the 1–1000 damage scale
  stay as they are. Document loudly that damage ≠ breaking power.

### Ore drops ore

- [ ] **Ore blocks drop ore directly**, not `<id>_ore_pack`. Packs currently come from
  `MineConfig.luau:2511` (`o.packId = o.id .. "_ore_pack"`) and
  `MineZonePacks.luau:244,251`.
- [ ] **Migration.** Existing saves hold unopened `<id>_ore_pack` rows. They must
  convert to banked `p.ores[id]` on load, with the pack ids kept as recognised
  aliases. Do not strand anyone's inventory.

### The Forge (was the Blacksmith)

`MineForgeView.luau` (780 lines) and `MineBenchView.luau` (239) both exist — reconcile
them into one Forge rather than adding a third view.

- [ ] **Keep the 3D display.** The full-screen stage from `583d9ad` stays.
- [ ] **Vertical scrolling recipe list.** Scroll recipes to choose what to craft.
- [ ] **Show only discovered ores**, with the ore amount each recipe needs. An
  undiscovered ore must not leak its name or stats.
- [ ] **Separate upgrades area**, where you also apply runes and skins.
- [ ] **Full inventory in the Forge**, bag included.
- [ ] **Server owns crafting.** Ore is debited and the tool minted server-side in one
  transaction. No client-supplied costs, no partial debits on failure.

### Tools craftable and upgradeable with ore

- [ ] **Craft recipes keyed by ore**, which also set the tool's breaking power.
- [ ] **Upgrades cost ore, a lot of it.** Re-tune so endgame tools are a genuine grind.
  The existing `upgradeOreTool` / `recycleOreTool` verbs
  (`MineServer.server.luau:13375,13441`) keep their uid-keyed contract.

### Runes — total overhaul

The F–SSS ladder already exists: `MineTemper.GRADE_ORDER = {F,D,C,B,A,S,SS,SSS}`, and
`MineRunes.luau:190-219` already draws from `MineTemper.RARITY_WEIGHTS`. Reuse it.

- [ ] **Runes are tool-only and ore-specific.** One rune per ore.
- [ ] **One rune slot per tool.**
- [ ] **Binding is permanent.** A bound rune cannot be removed, only destroyed with
  the tool. Needs an explicit confirm step, and the server must treat the bind as
  irreversible.
- [ ] **Presented like charms**, but as a tool buff, graded F–SSS.
- [ ] **Runes replace the old 2%–0.5% roll.** That odds band now belongs to the ore's
  rune drop.
- [ ] **Runes come off gems no longer** — confirm the gem/rune coupling is gone
  (was "Runes stay on gems").

### Skins (was Tempers)

- [ ] **Rename tempers → skins** across `MineTemper.luau` (537) and its views. Keep
  `LEGACY_RARITY` / `normalizeRarity` so old saves still load.
- [ ] **Skins drop from chests**, rarely.
- [ ] **Drastically bigger buffs, each doing something specific.** No more flat
  percentage soup.
- [ ] **Huge rarity disparity** across the F–SSS ladder.
- [ ] **No case contains every skin.** Each case carries a subset.
- [ ] **A skin is a wrap.** It changes the tool's look and grants its buff; it does
  not change the tool's identity or uid.

### Economy inversion: zones on coins, bags on gems

This inverts a rule the code states explicitly. `MineBags.luau:7` reads *"Coin prices
only. Never gems — zone buyCost is the gem sink."* Both halves flip, so change them
together or the sinks collide.

- [ ] **Zones become coin-gated**, not rebirth-gated.
- [ ] **Bags upgrade with gems**, not coins. Rewrite the `MineBags` curve and that
  comment.
- [ ] **Rebirth raises coin value** instead of unlocking zones.
- [ ] **Soften the zone and depth coin multipliers** now that rebirth multiplies coins.
- [ ] **Dirt price boost only below each zone gate** — keep the boost, scope it to
  below-gate layers.
- [ ] **Gear survives rebirth.** Pickaxe and all equipment persist. Audit every
  rebirth wipe path.

---

## P1 — content and feel

- [ ] **Ore icons for all 121 ores**, drawn on canvas. Blocked on the icon source
  above. 30 hand-made face tiles already ship as packed pixels; icons are a separate
  per-ore asset.
- [ ] **Nerf hats and faces**, and add both as chest drops.
  `MineHats.luau` (433) is the roster.
- [ ] **Not all packs spawn all pets.** Give each pack a pet subset in
  `MinePackConfig.luau` / `MinePetRoster.luau`.
- [ ] **Zone-1 case rates lower.** `MineZonePacks.cardOdds(zoneIndex, heat)` already
  takes the zone index and ignores it.
- [ ] **Chests spawn everywhere but supremely rare**, like ore.
- [ ] **Event Horizon `minRebirth`** is 0 while its surface is 1.30e9 HP. With zones
  on coins this gate is re-expressed as a coin price.

---

## P2 — after launch

- [ ] **28 legacy packs onto the ore system** in `MinePackConfig`: anomaly, apex,
  ashen, cinder, clay, cobalt, crimson, end, heirloom, hopper, iron, loam, magma,
  night, omen, shadow, shiny, slate, void, plus the gear/rune/fossil families.
- [ ] **Luck → Treasure Hunter refactor.** 47 `luck` references. Names floated:
  Divining Rod, Loadstone, Assayer's Eye.
- [ ] **Space ores (40, separate set)** — spec sits in `docs/ore-remake.md`, unapplied.
- [ ] **Tool generator LOOKS table** needs the live roster so ore blocks and the tools
  made from them stay in sync.
- [ ] **Export `OreShapes` / place-only instances to `.rbxm`** so they are under
  version control.
- [ ] **Coin shop** — you were contemplating removing it. Undecided.
- [ ] **Delete the duplicate Event Horizon pet module.** `MineEHPets.luau` and
  `MineEventHorizonPets.luau` are byte-identical (md5 `0a8c6c66…`); every consumer
  reads the short name first, so the long one is 34 KB that never loads.

---

## Deferred, with a reason

- [ ] **1.5× per 25 layers HP curve.** Not applied. Makes L4921 1.4e23× harder and
  breaks every hand-tuned chest and fossil tool, so it ships only alongside tool
  power. Clean unification on offer: damage-per-level = HP-per-layer (×1.016351), so
  one level = one layer, cap ~11,000. **Breaking power may replace the need for this
  entirely** — decide before spending time on it.
- [ ] **Chests → packs only** (55% card / 25% ore / 20% fossil, chest type adds +D).
  Superseded in part by the chest table rework and by skins/hats moving into chests.

---

## Done

- [x] ~~Shop stage goes full screen~~ **done** (visual pass still unrun) — the
  viewport is the bottom layer of the whole panel, no backdrop, no ground slab,
  camera framed from the real aspect and centred in the free band between the
  header and the name/stats/BUY stack. Arithmetic checked at all nine
  acceptance resolutions; nothing seen on screen yet.

- [x] ~~Blacksmith bench verbs~~ **done** — upgrade and recycle, both keyed by
  uid rather than list index, so a bag that reorders cannot upgrade the wrong
  tool. Levelling mutates `level` and never the uid, proven over 550 levels.

- [x] ~~Every owned instance carries a uid~~ **done** — chestTools, gear and
  relics were the gaps; cards, packs and runes already had one. Ore tools are
  built with uids from the start. Quantity maps (charms, tempers, eventTools,
  ores, tools) deliberately keep counts — instancing them would grow the save.

- [x] ~~Echo stripped from every pet, all 140 kept~~ **done** — 45 pets in the
  main roster plus 12 Event Horizon pets. The mechanic survives: runes, skills,
  tool specials, the Echo Strike card and  are untouched. Space lost
  its signature stat so it took  instead.

- [x] ~~Ore art needs no uploaded asset at all~~ **done** — the group/user
  ownership wall is gone because nothing is uploaded now. The 30 faces ship as
  packed pixels in  and are rebuilt at runtime with
  . 480 KB of pixels pack to 53 KB.

- [x] ~~Wormhole bag autosell + live-ticking timers~~ **done**
- [x] ~~Client-killer audio bug (`CompressorSoundEffect.Gain` doesn't exist)~~ **done**
- [x] ~~Item bag: 500 base, +100 a rung, gems `100 × 1.08^x`, `0/500` readout~~ **done**
- [x] ~~First pickaxe collected from the Blacksmith, free, "Wooden Pickaxe"~~ **done**
- [x] ~~Ore system: blocks, packs, 121 real ores, glow, Oganesson rainbow~~ **done**
- [x] ~~Ore spawn curve tuned to the rarity targets~~ **done**
- [x] ~~Ore Finder enchant (better roll quality, not more loot)~~ **done**
- [x] ~~Upgrade calculator: tools, costs, recycle, drops, rebirth, zones panel~~ **done**
- [x] ~~Depth: L4921 flatline removed, Big Bang unpinned to zone index 11~~ **done**
- [x] ~~Mine pushed back — `radius` 200 → 300~~ **done**
- [x] ~~Ore identity on the block card (it was losing to the section branch)~~ **done**
- [x] ~~Ore tier on pack rows, both display sites~~ **done**
- [x] ~~Ore roster remake, 121 ores, with a save migration~~ **done**
- [x] ~~14 ore renames, migration regenerated against the original roster~~ **done**
- [x] ~~Ore reveal grade fixed — bands now run through Exotic~~ **done**
- [x] ~~Chest tables redone: no gems, hats at 8.1× charms, uncapped pack runs~~ **done**
- [x] ~~Charms as a rare chest drop~~ **done**
- [x] ~~Hat crates in chests, far commoner than charms~~ **done**
- [x] ~~Blacksmith upgrade model: per-tool 1–1000 scale, flat 50% recycle~~ **done**
- [x] ~~Ore faces: 30 hand-made tiles sliced, uploaded, mapped to all 121 ores~~ **done**
- [x] ~~Repo set up at `Projects/mine-for-cards` with docs and verification harnesses~~ **done**

---

## Standing rules

- **No pity systems anywhere.** No floors, no guarantees after N.
- **Don't cripple the datastore.** Ore ids are load-bearing twice — `p.ores[id]` is
  banked material and packs are `<id>_ore_pack`. Any roster change needs an id→id
  migration with old ids kept as aliases. The ore-drops-ore change above is exactly
  this kind of change.
- **No limits on the upside.** Infinitely lucky is the point.
- **Server decides, client displays.** Every new verb — craft, upgrade, rune bind,
  skin apply, the breaking-power gate — validates server-side. A modified client must
  gain nothing but a wrong picture.
- **Breaking power is not damage.** Say so in every place both appear.
- **Permanent means permanent.** A bound rune cannot be recovered. Confirm before
  binding; never add an undo.
- Studio and Cursor edit the same scripts concurrently, so every edit anchors and
  asserts the source is unchanged before committing.
- Verify before claiming done. No playtests — Edit-mode probes.
