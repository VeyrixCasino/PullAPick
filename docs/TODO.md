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

- [ ] **Ore rarity is depth, not scarcity — and both ends are wrong.**
  `ORE_CHANCE` is a flat 1/200 at every depth and `oreWeights` normalises to
  1.0, so you always get ~1 ore per 200 blocks and the curve only decides
  WHICH. There is no scarcity dimension at all.

  Compressing `ORE_DMAX` to fit reachable depth was tried and REVERTED: it put
  the whole ladder in reach, but because the roster ends at tier 82 with
  nothing above competing for weight, the top ores hoovered up the tail and
  Oganesson became the COMMONEST ore in the game at 31.7% — an exotic every
  minute. Backwards.

  Reverted to the original `dirtHp * 2 * 6^9`, so the position now is the
  other extreme: exotic is one per 27,674 years and 24 of 82 ores never reach
  1% of a pool. Neither end is shippable. The fix is a real scarcity term
  (per-ore weight, with the leftover probability becoming "no ore" rather than
  being normalised away) so depth decides WHICH and rarity decides WHETHER —
  not another DMAX value.

- [ ] **Pick a time-to-max, then set the cost dial.** Shape and cap are done;
  only the scale is open. At cap 100, worst case (Epic), 10 blocks/s, best
  depth, no ore finder — `TOOL_ORE_BASE`/`TOOL_CLIMB_ORE`:
  4/1747 = 289 d (live now), 2/400 = 42 d, 1/120 = 7.8 d, 1/40 = 3.3 d,
  1/12 = 1.4 d, 1/4 = 17 h. Floor is 7.7 h — `ceil()` charges at least
  1 x mult across 99 levels, so anything faster needs the cap cut again.


- [ ] **No ore-tool drop exists.** Every `oreTools` reference reads, clears or
  removes; nothing creates one. Bench, upgrade, recycle, equip and 82 models
  are all live with no source feeding them.

- [ ] **Fossil code is still live.** Two sites still roll `Fossils.RECIPES` into
  `p.fossilPieces`, and both scale off `fossilFind` -- now labelled "Ore
  Finder". A stat called Ore Finder multiplying fossil pieces wants resolving
  one way or the other.

- [ ] **Decide on the duplicate Event Horizon pet module.**
  `MineEHPets.luau` and `MineEventHorizonPets.luau` are byte-identical (same
  md5) and both live in the tree. Every consumer reads
  `FindFirstChild("MineEHPets") or FindFirstChild("MineEventHorizonPets")`, so
  the short name always wins and the long one is 34 KB that never loads. It
  looks like a rename that kept the old file as a fallback. Not deleted unasked
  — removing it makes Rojo drop the instance from Studio, and Cursor works in
  this tree too.

- [ ] **Ore faces on every block type, in every zone.** Once access lands:
  confirm the faces read on ore in all 11 zones against each zone's own rock
  colour and accent material, and against every block kind that can carry ore.
  Dark zones (Eclipse, Primordium, Event Horizon) are the risk — a dark face on
  dark rock may vanish.
- [ ] **Export `ToolModels_50` to `.rbxm`.** 82 baked tools live only in the
  place file. Re-bakeable from `ServerStorage.OreToolBaker`, but that is ~40s
  and not version control.
- [ ] **Unique item ids across everything owned.** Every owned thing gets its
  own uid whose FIRST FOUR DIGITS identify which specific thing it is. Applies
  to tools, packs, charms, hats, pets, bags, runes, tempers -- everything
  except currency itself. Some of this existed once and was dropped; packs
  still carry a .
- [ ] **New enchantments** added.

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

- [x] ~~Roster cut 121 -> 82, level cap 1000 -> 100~~ **done** — the 39 ores
  that are gone each map to a survivor, because `p.ores[id]` is banked
  material and every pack is "<id>_ore_pack": an unmapped id does not rename a
  rock, it deletes stock and bricks packs. Seven EXISTING migration entries
  already pointed at ores in the removal list (alumina -> selenite and six
  more) and were chained through to live ores rather than left dangling.
  73 entries total; verified no identity mapping, no dangling target, and
  nothing mapping a surviving id away.

- [x] ~~Grade bands were past the end of the roster~~ **done** — the reveal cut
  at 24/48/72/96/108/114/118 for 121 ores. Trimmed to 82, the top four cuts sat
  beyond the roster entirely: nothing could grade above Epic and the Legendary,
  Mythic, Divine and Exotic reveals were dead code. Now 18/29/49/60/69/75/79.

- [x] ~~Ore cost and pack yield are both bells now~~ **done** — cost was
  `tier^0.85`, strictly rising, while yield fell 6 to 1 across the roster: a
  ~360x double penalty aimed at the endgame. Both peak on Epic now.
  Cost by band: exotic 1.0 (cheapest), common 2.0, divine 4.0, uncommon 6.0,
  mythic 7.0, legendary 11.0, rare 12.0, epic 18.0 (dearest), interpolated
  between band centres so there is no cliff at a boundary. Yield by band:
  8-10 / 10-12 / 11-13 / 12-15 / 8-10 / 6-8 / 4-6 / 2-4. Rare was not in the
  spec; 11-13 fills the gap between uncommon and epic.

- [x] ~~Ore finder is stamped on the pack when you mine it~~ **done** — it was
  read from live boosts at OPEN, so a pack mined with the finder up paid
  nothing extra if you unequipped first, and a bag of old packs all cashed in
  at whatever you happened to be wearing. Stamped at the break like luck.
  Fossils are gone and ore replaced them, so `fossilFind` IS the ore finder;
  the key is unchanged (every rune, charm and card writes it) and only the
  label moved to "Ore Finder".

- [x] ~~Pot of Gold carries every kind of luck~~ **done** — it was pack luck
  alone on the item sold as the luck item. Now chest, ore quality, ore
  quantity, gems and lucky blocks at 100% each. `luck` stays at 2: it is
  advertised at 200% on a limited item people paid for, and levelling it to
  1.00 for tidiness would be a nerf to something already bought.

- [x] ~~Ore tools can be equipped, and the 82 models are wired in~~ **done** —
  the system could find, level and scrap a tool but never HOLD one, so a
  levelled tool changed no numbers and the baked models had nowhere to appear.
  `Verbs.equipOreTool` (uid-keyed, toggles, clears chest/fossil so nothing is
  silently masked) plus a branch in `equippedTool` that outranks the ladder the
  way a chest flagship does. The synthesised row's `name` is the ORE's name,
  which is the same string `ToolModels_50` keys the baked head on, so the model
  comes back through the existing `fromNamed` path with no second lookup table
  to drift. All 82 resolve, both directions, 21,148 tris each.

  Two constraints shaped it: MineServer sits at 197 top-level locals against a
  ceiling of 200, so nothing new is declared at top level; and `Verbs` is
  declared ~6,000 lines below `equippedTool`, so that lookup is inlined rather
  than calling `Verbs._findOreTool`.

  Scrapping the tool in your hand lets go of it first, so the hand never keeps
  a uid that no longer resolves.

- [x] ~~Bench buttons were stacked on top of each other~~ **done** — SCRAP was
  160px wide from x = -168, exactly the span MAX, +10 and +1 occupy, and as
  later siblings they drew over it: the only way to scrap a tool was covered by
  the buttons that level it. Rows are 104 tall with levelling on line one and
  EQUIP / SCRAP on line two; verified 0 overlapping pairs. The tool you are
  holding sorts to the top.

- [x] ~~82 ore tools baked, every head exactly 20,000 triangles~~ **done** —
  `ServerStorage.OreToolBaker`. Fifteen silhouettes (five picks, five drills,
  five explosives) spread evenly at five to six tools each. Head and haft are
  separate MeshParts, so the 20k is literally per head and readable straight
  off the part rather than a claim about a merged blob. Colour, material and
  glow come from `MineConfig.ORES` by name — Ruby is ruby, Uranium is Neon.
  Geometry is 85–100% of the budget (avg 97%) after a resolution pass; the
  first attempt spent ~80% of every head on scattered filler and looked like
  glitter on a stick. NOT yet seen properly in-viewport: the numbers, sizes,
  colours and one explosive row check out, the rest is unshot.

- [x] ~~Shop showed only a background~~ **done** — `ShopBg` was an OPAQUE
  ImageLabel at ZIndex 80, and this ScreenGui runs ZIndexBehavior.Sibling, so
  it painted over every sibling beneath it: the 3D stage (2), the tab strip
  (41) and the temperament picker (70). One plate hid the tools AND the sort
  options. Removed. What sits behind the pedestal now is drawn — gradient,
  forge glow, vignette — with nothing above ZIndex 3.

- [x] ~~Tool framing in the shop~~ **done** — the fit sphere was measured about
  the WORLD ORIGIN while the camera aims at the tool at y≈−9.7, so radius read
  16.64 against a true 7.97 and a 4-stud pickaxe sat in a 33-stud-wide view.
  Measured from the aim point now, with the plinth fitted as the cylinder it is
  rather than its box diagonal: 2.4× bigger on screen, nothing cropped, and
  `Dist` is seeded in setModel so the first frame is never inside the plinth.

- [x] ~~Secrets tab existed everywhere except the tab bar~~ **done** —
  FAMILY_TINT, rows(), paint() and the tab counter all handled `secrets`, and
  no commit in this file's history ever put it in TABS. It has a button now.

- [x] ~~Wallet shows what the blacksmith actually spends~~ **done** — five
  chips, not three: stardust pays for tool levels and temperament tokens pay
  for rolls, and neither was shown, so you had to leave the shop to find out
  whether you could afford what was in front of you. Right-aligned
  UIListLayout instead of hard-coded offsets, with real MineIcons art in place
  of coloured dots.

- [x] ~~Blacksmith bench: the UI~~ **done** — `MineBenchView` is mounted as the
  Upgrade tab and wired to `upgradeOreTool` / `recycleOreTool`, both uid-keyed.
  Rows build in their own pcall and say what failed, so one unpriceable tool no
  longer blanks the panel the way a nil TOOL_MAX_LEVEL did.

- [x] ~~Blacksmith logo moved down~~ **done** — header 64 → 78, title y 11 → 22.

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

- **Never touch ore spawn chances.** `ORE_CHANCE`, the spread-curve constants
  (`ORE_X0/K/S/W`), `ORE_DMAX`, and the bodies of `oreWeights` / `oreIdentity` /
  `rollOre` are off limits unless explicitly asked. Rarity here is DEPTH, not
  scarcity — a flat 1/200 everywhere with the curve only choosing WHICH ore --
  so any edit to the depth axis silently rewrites every ore's rarity at once.
  Report the numbers and stop. (Learned the hard way: an ORE_DMAX "fix" made
  Oganesson the commonest ore in the game at 31.7%.)

- **No pity systems anywhere.** No floors, no guarantees after N.
- **Don't cripple the datastore.** Ore ids are load-bearing twice —
  `p.ores[id]` is banked material and packs are `<id>_ore_pack`. Any roster
  change needs an id→id migration with old ids kept as aliases.
- No limits on the upside. Infinitely lucky is the point.
- Studio and Cursor edit the same scripts concurrently, so every edit anchors
  and asserts the source is unchanged before committing.
- Verify before claiming done. No playtests — Edit-mode probes.
