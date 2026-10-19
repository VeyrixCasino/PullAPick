# Job: watch a case drop from a real chest

## Why

Chests and lucky blocks now pay mystery cases and skin (ore) cases into the bag.
The rules are in `wiki/systems/chests-and-lucky-blocks.md`. The code is
`MineLuckyBlocks` and `openChestBlock` / `openLuckyBlock` in
`MineServer.server.luau`, and the reveal is in `MineGradeReveal`. Nobody has
watched one land from a real chest in play.

## Steps (this job may start Play; stop it the moment you are done)

1. Studio must be open on the place and in Edit mode. If someone else is in
   Play, wait.
2. Start Play. Use the admin tools to put the test player next to chests, or
   give them a chest: read `[MineAdmin]` in `MineServer` and
   `MineAdminClient.client.luau` for what exists. Break chests until one pays a
   mystery case and one pays a skin case.
   - If that takes too long, open a lucky block instead. Its loot table also
     pays cases.
   - Do not change any odds to force a drop.
3. For each case drop, screen-capture:
   - the reveal;
   - the case tile in the bag;
   - the case opening (the CS:GO-style spin).
4. Check the console for errors (`get_console_output`).
5. Stop Play.

## Finish

- Change no code unless something is clearly broken, such as an error or a case
  that never reaches the bag. Then fix it narrowly, with a check under
  `tools/verify/` if one fits, and commit only that.
- The report needs:
  - the screenshots' descriptions;
  - what dropped from what;
  - any error lines;
  - anything that looked wrong.
