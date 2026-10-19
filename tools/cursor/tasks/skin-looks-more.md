# Job: give pickaxe, drill and explosive skins a look, for every skin set

## Why

The owner asked to *"make skins work, all of it"*, including **looks on every
family** (2026-10-19, `wiki/open-questions.md` "§0e decided"). Today only
hammers and jackhammers have skin forms (`SKIN_FORMS.hammer.<set>` and
`SKIN_FORMS.jackhammer.<set>` in `src/ReplicatedStorage/ToolModelFactory.luau`,
9 sets each). For a pickaxe, drill or explosive, `ToolModelFactory.buildSkinned`
returns nil and the plain ore tool is built, so those skins change the tool's
numbers but not how it looks. Every screen says so with a "stats only" label.

The Season One Pass set (`season_one_pass`: Gemfire, Geode Heart, Deepgold Seam,
The Motherlode) has no entry in `SKIN_PALETTES` at all, so it has no look on any
family, hammers and jackhammers included.

There are 10 sets in `MineSkins.SETS`: toybox, cursed, pharaohs_tomb, wasteland,
clockwork, carnival, atomic_age, arcade, halloween and season_one_pass. The job
is **32 forms and 1 palette**:

- `SKIN_FORMS.pickaxe.<set>`, `SKIN_FORMS.drill.<set>` and
  `SKIN_FORMS.explosive.<set>` for all 10 sets (30 forms);
- `SKIN_FORMS.hammer.season_one_pass` and `SKIN_FORMS.jackhammer.season_one_pass`
  (2 forms);
- `SKIN_PALETTES.season_one_pass`.

## Scope

Edit only `ToolModelFactory.luau`:

- add `pickaxe`, `drill` and `explosive` tables to `SKIN_FORMS` (it is declared
  as `{ hammer = {}, jackhammer = {} }`) and the 32 form functions;
- add `SKIN_PALETTES.season_one_pass`;
- add helpers next to the forms if you need them, for example a pick haft, a
  drill body or a bomb body that put the Handle exactly where `buildPickaxe`,
  `buildDrill` and `buildExplosive` put theirs (the way `skinHaft` and
  `skinBody` do for the hammer and the jackhammer).

Do not touch `buildPickaxe`, `buildDrill`, `buildExplosive`, `buildHammer`,
`buildJackhammer`, the 18 existing forms, the 9 existing palettes,
`buildSkinned`'s contract, `hasSkinForm`, or any other file.

**Nothing else needs wiring.** The game already builds a form wherever one
exists, and the screens read `ToolModelFactory.hasSkinForm`, so the moment a
family has a form for a set the "stats only" label goes away by itself:

- the tool in hand: `givePickaxe` in `MineServer`, through `row.skinId`
  (the skin `equippedTool` put on the held tool, on any tool with a family,
  event tools included);
- a thrown explosive stuck to the rock: `flingCharge` in `MineServer`;
- the Forge hub's 3D stage for a tool you own (`MineForgeHub`, `s.show`).

**Precedence to know about (do not change it; report what you see).** In
`givePickaxe` a tool with a named model in `ToolModels_50` (some chest Secrets,
the pass's Lunar picks, zone-shop tools) keeps that model, and the skin form is
built only on the procedural branch. Forged tools and event tools always take
the procedural branch, so they show the form.

## Rules

- **Keep the contract.**
  - Each form is `function(model, P, rank, ore)`: it builds into `model`, uses
    its palette `P` (`main`, `second`, `trim`, `glow`, `mat`, `trimMat`) and
    returns the Handle part.
  - It respects `rank` (1 at F to 8 at SSS): lower ranks plainer, higher ranks
    richer, with `skinExtras`' PointLight at rank 6 and above and sparkles at
    rank 8.
  - It shows the ore (`ore`, the ore's colour, may be nil for an event tool)
    as an inlay. `skinExtras` already does this; call it.
  - The Handle, grip and weld setup that `buildSkinned` does must still work.
    The tool must sit in the hand exactly where the ore version of the same
    family sits (`GRIPS`, `SCALE`).
- **Explosives are thrown.** The same form is anchored to a wall by
  `flingCharge`. It has to read as a bomb in the hand and stuck to rock.
- **Size:** the silhouette stays the size of the ore tool of that family.
  - Aim for 40-80 parts per form at top rank.
  - Never go above 90 parts, since several players can hold one at once.
- **Shapes:** no `MeshType.Pyramid` or `Prism`, because Roblox no longer draws
  them (`wiki/code/luau-traps.md` §10).
- **Theme:** each set must read as its theme at a glance, and the five
  families of one set should look like siblings of the hammer and jackhammer
  forms already there. For example:
  - toybox: chunky plastic, bolts and stickers (the toybox hammer is a mallet,
    its jackhammer a pogo stick);
  - cursed: grave iron, bone and red cloth;
  - pharaohs_tomb: gold, lapis and a scarab;
  - halloween: pumpkin orange, grave grey, wax and cobwebs;
  - season_one_pass: the pass's own story, gems in raw rock: a fire-gem
    (Gemfire), a split geode (Geode Heart), a gold seam (Deepgold Seam), a
    mother-lode crystal cluster (The Motherlode).
- **The Season One Pass palette is a taste call.** PROPOSED (2026-10-19), use
  it unless it reads badly, and say which you used: main deep amethyst
  (96, 52, 160), second quartz white (232, 226, 244), trim seam gold
  (240, 188, 60), glow (255, 132, 214), mat Glass, trimMat Foil.

## Check it in Studio (Edit mode only; do not start Play)

1. For every set, build the pickaxe, drill and explosive (and the hammer and
   jackhammer for season_one_pass) with `ToolModelFactory.buildSkinned` at
   rank 1 and at the top rank, with a mid ore look (for example
   `ToolModelFactory.oreLook` of `"gold"`) and with no look at all (an event
   tool has no ore). Parent them in a row in Workspace under a folder named
   `_SkinLooksCheck`.
2. Screen-capture each row from the front and from a 3/4 angle. Look for:
   - floating parts;
   - z-fighting;
   - parts poking through the handle;
   - a handle that is no longer where a hand would hold it.
3. Count the parts per model. Paste a table (set x family x rank -> parts)
   into your report.
4. Delete `_SkinLooksCheck` when you are done. Never save the place.

## Verify and finish

- Run `node tools/verify/compile.js`, `node tools/verify/skin-wear.js` and the
  full suite.
- Update `wiki/systems/skins-cases-and-temper.md` and `wiki/systems/tools.md`
  where they say pickaxe, drill and explosive skins have no look. Add a
  `wiki/log.md` entry.
- Commit only `ToolModelFactory.luau` and those wiki pages.
- In the report, list any set where you are unsure the look reads as its theme,
  and the palette you used for the pass set. The owner decides on taste.
