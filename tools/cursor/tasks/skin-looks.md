# Job: make the 18 hammer and jackhammer skin looks match the ore tools

## Why

The owner asked for hammers and jackhammers built *"extremely hq ... every tool,
every ore, all color ways"*. The ore versions (`buildHammer`, `buildJackhammer`
in `src/ReplicatedStorage/ToolModelFactory.luau`) were rebuilt to the Canva
icons. The skin looks were not: `SKIN_FORMS.hammer.<set>` and
`SKIN_FORMS.jackhammer.<set>`, 9 sets each, are only 15-38 parts. They should
read as just as finished as the ore tools. Each set has its own theme: toybox,
cursed, pharaohs_tomb, wasteland, clockwork, carnival, atomic_age, arcade and
halloween.

## Scope

Edit only the 18 `SKIN_FORMS` functions in `ToolModelFactory.luau`. Add helpers
next to them if you need to. Do not touch `buildHammer`, `buildJackhammer`,
`SKIN_PALETTES`, `buildSkinned`'s contract, or any other family.

## Rules

- **Keep the contract.**
  - Each form builds into `model` and uses its palette `P`.
  - It respects `rank`: lower ranks plainer, higher ranks richer, with the
    existing PointLight at rank 6 and above and sparkles at rank 8.
  - It shows the ore (`ore`) as an inlay.
  - The Handle, grip and weld setup that `buildSkinned` does must still work.
    The tool must sit in the hand exactly where the ore version sits.
- **Size:** the overall silhouette stays the size of the ore tool.
  - Aim for 40-80 parts per form at top rank.
  - Never go above 90 parts, since several players can hold one at once.
- **Shapes:** no `MeshType.Pyramid` or `Prism`, because Roblox no longer draws
  them.
- **Theme:** each set must read as its theme at a glance. For example:
  - toybox: chunky plastic, bolts and stickers;
  - clockwork: gears, brass and a ticking face;
  - pharaohs_tomb: gold, lapis and a scarab.
  - The hammer and jackhammer of one set should look like siblings.

## Check it in Studio (Edit mode only; do not start Play)

1. For every set, build both families with `ToolModelFactory.buildSkinned` at
   rank 1 and at the top rank, with a mid ore (for example `"gold"`). Parent
   them in a row in Workspace under a folder named `_SkinLooksCheck`.
2. Screen-capture each row from the front and from a 3/4 angle. Look for:
   - floating parts;
   - z-fighting;
   - parts poking through the handle;
   - a handle that is no longer where a hand would hold it.
3. Count the parts per model. Paste a table (set × family × rank → parts) into
   your report.
4. Delete `_SkinLooksCheck` when you are done. Never save the place.

## Verify and finish

- Run `node tools/verify/compile.js` and the full suite.
- Update `wiki/systems/skins-cases-and-temper.md` and `wiki/systems/tools.md`
  where they describe the skin looks. Add a `wiki/log.md` entry.
- Commit only `ToolModelFactory.luau` and those wiki pages.
- In the report, list any set where you are unsure the look reads as its theme.
  The owner decides on taste.
