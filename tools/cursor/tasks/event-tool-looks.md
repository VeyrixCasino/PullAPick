# Job: themed 3D models and icons for the Candy Crypt and Event Horizon tools

## Why

The owner, 2026-10-19 (`wiki/open-questions.md` "§0e decided", "The look"):
**events get their own themes**, Halloween for the Candy Crypt and a dark
universe for Event Horizon, *on everything that belongs to an event wherever it
shows*, its tools included; and **"event tools get themed 3D models and icons (a
Cursor job, checked in Studio)"**. Tool looks should match the event themes.

Today neither event's tools look like their event:

- **3D.** `givePickaxe` in `MineServer` builds an event tool on the plain
  procedural branch, `ToolModels.build(family, lookTier, count, oreLook)`. An
  event row has no `oreTier`, so there is no ore look: a Horizon pick or a
  Candy Corn Pick is an ordinary rung-coloured pick from the ladder ramp.
- **Icons.** `MineIcons.forTool` keys on `oreTier or tier`, and an event row's
  `tier` is its index in its own roster, so an event tool shows the icon of the
  forged ore tool with that index (Event Horizon pick 3 wears the third ore's
  pickaxe icon). There are no event tool icons at all.

## The rosters (read the files at job time; they may have changed)

**Candy Crypt**, `src/ReplicatedStorage/Mine/Shared/MineCandyTools.luau`: three
tiers x four families, ids `candy_<tier>_<family>`, `zoneId = "hallow"`.

| tier | pickaxe | hammer | drill | explosive |
|---|---|---|---|---|
| corn | Candy Corn Pick | Candy Corn Mallet | Candy Corn Auger | Candy Corn Cracker |
| toffee | Toffee Pick | Toffee Mallet | Toffee Auger | Toffee Cracker |
| jawbreaker | Jawbreaker Pick | Jawbreaker Mallet | Jawbreaker Auger | Jawbreaker Cracker |

**The Crypt is being redesigned in parallel** (owner, 2026-10-19): Crypt tools
drop from Crypt chests and Trick-or-Treat cases (the candy shop goes), and
**3 identical Crypt tools merge into Golden, then Prism, then Rainbow**, the
pets' steps. That work may change this roster, add tiers or add the three merge
steps. Build for whatever `MineCandyTools` (or its replacement) holds when you
start, and treat Golden / Prism / Rainbow as **finish-style looks** layered on
the base model, the way `ToolModelFactory.applyFinish` lays Shiny / Shadow /
Nightmare on any model: Golden a gold foil coat and glints, Prism a clear
faceted shimmer, Rainbow a cycling hue. If the merge steps are not in the code
yet, build the three finishes anyway and report that nothing calls them.

**Event Horizon**, `src/ReplicatedStorage/Mine/Shared/MineHorizonTools.luau`:
generated from `MineDepth.SECTIONS`, one tool per section, `zoneId = "bigbang"`:

- 12 picks, "Horizon <Section> Pick" (pickaxe, shallow band; the first is
  `eh_shallow_pick`, given free);
- 38 bores, "Singularity <Section> Bore" (drill, a 5x5 bore straight down);
- 88 charges, "Event <Section> Sinkcharge" (explosive, a shaft blast).

138 tools is too many to model one by one. Build **three forms, one per
family, with a ramp**: the tool's `tier` (its index in its family) drives how
much it glows, how bright its star points are and how far its inlay shifts
along the theme's colours, so a deep charge reads as stronger than a shallow
one without being a different model.

## The themes

- **Candy Crypt (Halloween):** candy corn (yellow, orange and white bands),
  pumpkin, bone, licorice (black and red twists), wrapped candy, glossy amber
  toffee, layered jawbreaker spheres, wax drips and cobwebs. Corn, toffee and
  jawbreaker tiers should be told apart at a glance.
- **Event Horizon (dark universe):** dark metal, star glow, nebula inlay
  (purple to cyan), an accretion ring, a point of white light at the business
  end. Calm and deep, not neon soup.

Match the house style for tool models: chunky, readable silhouettes, the
family's shape kept (a pick is a pick, a bore is a bore, a charge is a bomb).

## Scope

1. **Models.** In `src/ReplicatedStorage/ToolModelFactory.luau` add
   `ToolModelFactory.buildEvent(row)`, returning `model, handle, grip` (or nil)
   for a row whose `zoneId` is `"hallow"` or `"bigbang"`, keyed by `row.family`
   and ramped by `row.tier`. Keep the Handle, `GRIPS` and `SCALE` exactly as the
   plain build of that family, so the tool sits in the hand where it does now.
   Add the three Crypt merge finishes next to `applyFinish` (or inside it, as
   new finish names), without changing what the existing finishes do.
2. **Wiring, two lines each, no new top-level `local`.** `MineServer` and
   `MineClient` sit near Luau's 200-local ceiling (`wiki/code/luau-traps.md`
   §1): use `ToolModels.` fields and locals inside the function only.
   - `givePickaxe` in `MineServer`: in the procedural branch, **after** the skin
     attempt (`row.skinId` / `ToolModels.buildSkinned`) and **before** the
     `ToolModels.build(...)` fallback. A worn skin with a form wins over the
     event look: the owner wants **one wardrobe everywhere**, event tools wear
     the same skins.
   - `flingCharge` in `MineServer`: the same order for a thrown event charge.
3. **Icons.** Render one icon per event tool (and per Crypt merge step) with
   the existing capture pipeline in `src/ServerStorage/CaptureToolIcons*.luau`
   (read how it poses, lights and saves first). Then:
   - upload them with `upload_image` (this task lists them, so the upload is in
     scope), named `mfc_tools_<id>_v1` (`wiki/code/assets-and-uploads.md`);
   - add their ids to `MineIcons` behind a new flag
     `EVENT_TOOL_ICONS_SHARED = false`, looked up by tool **id** in
     `MineIcons.forTool` **before** the ore-skin lookup, so an event tool stops
     borrowing an ore tool's icon;
   - stop there: the owner shares the uploads in the Creator Hub and flips the
     flag, as with the Canva tool icons (`NEW_TOOL_ICONS_SHARED`).

Do not touch the tools' stats, prices, drops or odds, `MineCandyTools` or
`MineHorizonTools` data, the skin forms, or any other family's builders.

## Rules

- **Size:** each model stays the size of the plain tool of its family. Aim for
  30-70 parts at the top of the ramp; never above 90.
- **Shapes:** no `MeshType.Pyramid` or `Prism` (Roblox no longer draws them).
- **No new top-level locals** in `MineServer` or `MineClient`;
  `node tools/verify/compile.js` must pass with at least 4 locals of headroom.

## Check it in Studio (Edit mode only; do not start Play)

1. Build every Crypt tool, and the first, middle and last tool of each Horizon
   family, with `ToolModelFactory.buildEvent`, plus each Crypt merge finish on
   one tool. Parent them in rows in Workspace under `_EventToolLooksCheck`.
2. Screen-capture each row from the front and from a 3/4 angle. Look for
   floating parts, z-fighting, parts through the handle, and a handle that is
   no longer where a hand would hold it.
3. Count the parts per model; paste a table into the report.
4. Delete `_EventToolLooksCheck` when done. Never save the place.

## Verify and finish

- Run `node tools/verify/compile.js`, `node tools/verify/localorder.js`,
  `node tools/verify/skin-wear.js` and the full suite.
- Update `wiki/systems/tools.md` (models and icons), `wiki/systems/world-events.md`
  (the event tools) and `wiki/code/assets-and-uploads.md` (the new flag and ids).
  Add a `wiki/log.md` entry.
- Commit only `ToolModelFactory.luau`, the two `MineServer` wiring hunks,
  `MineIcons.luau` and those wiki pages.
- In the report: the uploaded ids, any tool you are unsure reads as its event,
  and the list of uploads the owner must share. The owner decides on taste.
