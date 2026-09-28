# TODO

Everything outstanding for Mine For Cards, plus what's already landed.
Checked after every prompt; items get struck through and marked **done** as
they finish.

---

## Blocked — needs you, not me

- [ ] **Push to GitHub.** 8 commits sit on local `main`; `origin` is
  `VeyrixCasino/PullAPick`. Not pushed because you said to wait.

- [ ] **Connect Rojo.** `rojo serve` is running but Studio has never attached,
  so none of the committed source is live. Every Studio-only edit from these
  sessions is already ported into `src/`, so connecting is safe and will not
  revert anything. `ServerStorage` survives regardless
  (`$ignoreUnknownInstances`).

---

## Next up

- [ ] **Ore faces on every block type, in every zone.** Once access lands:
  confirm the faces read on ore in all 11 zones against each zone's own rock
  colour and accent material, and against every block kind that can carry ore.
  Dark zones (Eclipse, Primordium, Event Horizon) are the risk — a dark face on
  dark rock may vanish.
- [ ] **Pickaxe models.** None of the pickaxes have one. 2,278 `.obj` tool
  meshes (119 unique) are merged into `ToolParts_import.obj` ready for Studio's
  3D importer; `AssetService:CreateEditableMesh` is proven with Pickaxe tier 0.
- [ ] **Shop GUI → fullscreen pedestal.** Still renders as a window.
- [ ] **Unique item ids across everything owned.** Every owned thing gets its
  own uid whose FIRST FOUR DIGITS identify which specific thing it is. Applies
  to tools, packs, charms, hats, pets, bags, runes, tempers -- everything
  except currency itself. Some of this existed once and was dropped; packs
  still carry a .
- [ ] **New enchantments** added.
- [ ] **Blacksmith bench: UI + verb.** The pricing model is committed and
  tested (`MineConfig.toolUpgradeCost` / `toolSpent` / `toolRecycle`,
  `p.toolLevels`); what's missing is the server verb that spends ore + dust and
  the bench screen. The blacksmith building itself already exists.

---

## Economy, queued

- [ ] **Potions and merging move to gems.**
- [ ] **Runes stay on gems** — confirm nothing moved them.
- [ ] **Ore → gem sell pad.** Gems are minted from scrap ore; the sell
  interaction doesn't exist yet. `MineConfig` has the curve
  (`gemBase 2`, `gemSpan 1.5` → 12 / 45 / 176 gems a find across tiers 1/60/121).
- [ ] **Chests spawn everywhere but supremely rare**, like ore.
- [ ] **Zone-1 case rates lower.** `MineZonePacks.cardOdds(zoneIndex, heat)`
  already takes the zone index and ignores it.
- [ ] **28 legacy packs onto the ore system** in `MinePackConfig`: anomaly,
  apex, ashen, cinder, clay, cobalt, crimson, end, heirloom, hopper, iron,
  loam, magma, night, omen, shadow, shiny, slate, void, plus the gear/rune/
  fossil families.
- [ ] **Luck → Treasure Hunter refactor.** 47 `luck` references. Tool-finder
  names floated: Divining Rod, Loadstone, Assayer's Eye.
- [ ] **Event Horizon `minRebirth`** is 0 but its surface is now 1.30e9 HP —
  the gate probably needs raising.
- [ ] **Coin shop** — you were contemplating removing it entirely. Undecided.

---

## Content, queued

- [ ] **Space ores** — the separate 40-ore set in `ore-remake.md`, own 1–40
  ladder, ties into the `eventhorizon` / `bigbang` zones.
- [ ] **Tool generator LOOKS table** needs the same roster so ore blocks and
  the tools made from them stay in sync.
- [ ] **Export `OreShapes` / place-only instances to `.rbxm`** so they're under
  version control instead of living only in the place file.

---

## Deferred, with a reason

- [ ] **1.5× per 25 layers HP curve.** Not applied. It makes L4921 1.4e23×
  harder and breaks every hand-tuned chest and fossil tool, so it can only ship
  alongside tool power. The clean unification on offer: damage-per-level =
  HP-per-layer (×1.016351), so one level = one layer, cap ~11,000.
- [ ] **Chests → packs only** (55% card / 25% ore / 20% fossil, chest type adds
  +D). Designed in the proposal artifact; superseded in part by the chest table
  rework, needs a decision on whether the rest still applies.

---

## Done

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
- **Don't cripple the datastore.** Ore ids are load-bearing twice —
  `p.ores[id]` is banked material and packs are `<id>_ore_pack`. Any roster
  change needs an id→id migration with old ids kept as aliases.
- No limits on the upside. Infinitely lucky is the point.
- Studio and Cursor edit the same scripts concurrently, so every edit anchors
  and asserts the source is unchanged before committing.
- Verify before claiming done. No playtests — Edit-mode probes.
