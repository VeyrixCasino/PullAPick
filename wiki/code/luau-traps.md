---
title: Luau and workflow traps
type: code
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - docs/START-HERE.md §4, §5
  - docs/HANDOFF.md §2.3
  - docs/TODO.md §9
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau
  - tools/verify/config-refs.js
  - tools/verify/dmg-live.js
  - tools/verify/bignum.js
related: [server, client-and-ui, verify-suite, save-data-and-migrations, rojo-and-studio]
---

# Luau and workflow traps

> Each of these has already cost this project real time (START-HERE §4: "They
> are not hypothetical"). Read them before you edit MineServer or MineClient.

## 1. The 200-local ceiling

- **What happens.** Luau allows 200 local registers per function, and a script's
  top level counts as one function. Past the limit, the **whole script fails to
  compile** with "Out of local registers when trying to allocate X: exceeded
  limit 200". For the client that means no HUD and no panels at all. For the
  server it means the game does nothing.
- **Where we stand.**
  - `MineServer` has 197 top-level `local` lines.
  - `MineClient` has 176 lines, but several declare more than one name. It once
    hit 207, and later broke again when two constants were hoisted (see the
    comment above `refreshMineUiScale`).
- **What to do instead:**
  - Hang new things off a table that already exists: `Dig.x` on the server,
    `ClientFns.x` on the client, `Const` for scalars.
  - Put one-off setup in a `do … end` block.
  - Declare constants **inside** the function that uses them.
  - Require rarely-used modules inline.
- **Counting is unreliable.** A local holding a never-reassigned constant is
  folded away by the compiler and takes no register. Tested here: 205
  `local vN = N` lines compile, while 205 `local vN = {}` lines fail.
- **`syntax.sh` will not catch it.** It runs `luau-analyze`, which accepted the
  205-table file. To check, run
  `.luau-bin/luau-compile --binary src/ServerScriptService/Mine/MineServer.server.luau`.
  Both scripts compile at `26036a0`. No check in the suite does this; it is a gap.

## 2. The global-read trap (the worst one)

A `local` that is used **above** the line that declares it compiles as a
**global read**. At runtime it is nil, with no error and no warning:

```lua
local function craft() p.oreToolEquipped = uid end   -- uid is a nil global here
local uid = row.uid                                    -- declared too late
```

- **Cost so far.** The load comment in MineServer says it has bitten that file
  four times (`shortNum`, `invCtl`, `vipSeatsLeft`, `SET_IDS`). Other examples:
  crafting a tool silently unequipped it, and a tap-to-close button did nothing
  (START-HERE §4.2, HANDOFF §2.3).
- **Fixes:**
  - Forward-declare the local, then assign it later. `local syncFoundLedger --
    forward` and `local paintCard -- defined below` are examples.
  - Or use a table field (`Dig.x`). A field is looked up when it is called.
  - `load()` uses literal numbers rather than `Intro.*`, because `Intro` is
    assigned further down the chunk.
- **The rule.** When something is mysteriously nil, check declaration order
  first. `tools/verify/dmg-live.js` exists to *execute* code in real file order,
  instead of arguing about it.

## 3. Standalone `luau` is not Roblox

Checked against `.luau-bin/luau` at `26036a0`:

- `os.exit` is **nil**. Decide a check's exit code in JS from its output.
  `tools/verify/bignum.js` explains why. `dmg-live.js` still calls it, and only
  fails correctly because calling nil errors.
- There are **no infix bitwise operators**. `a ~ b` is a parse error; use
  `bit32.bxor`.
- `Random`, `Color3`, `Enum` and `Instance` do not exist. Harnesses stub them,
  for example `Random = { new = … }` in `tools/verify/charms.js`.

## 4. Keys stored in saves are DATA

- **Stat keys.** Names like `blastChance` are stored on runes and gear. Renaming
  one is a migration, not a refactor. That is why `fossilFind` keeps its name.
- **Ore ids** are stored twice: `p.ores[id]` and `"<id>_ore_pack"`.

Details: [save-data-and-migrations](save-data-and-migrations.md).

## 5. Silent nils are this codebase's failure mode

- **Missing config fields.** A missing `MineConfig` field is nil until something
  calls it. A merge once dropped about 10 symbols that are used on every grant
  and craft. `tools/verify/config-refs.js` exists because of this.
- **Partial snapshots.** The shop hands the Forge a hand-built subset of the
  snapshot. A field it leaves out reads as nil, then falls back through
  `tonumber(x) or 1` and shows a plausible, wrong number (`forge-snap.js`).
- **Typo'd properties error only at runtime.** `ClipDescendants` (missing the
  `s`) threw on every client load until `b83b150`.
- **Infinite waits.** `WaitForChild` with no timeout yields forever, which is why
  MineServer creates the `Admin*` remotes early.
- **Studio capability errors.** Some property writes are refused in Studio.
  `workspace.FallenPartsDestroyHeight` is wrapped in `pcall` because an
  unguarded failure took the whole server down.

## 6. Verify regexes must strip comments

- Four checks once matched the agent's own explanatory comments, and passed or
  failed for the wrong reason (START-HERE §4.5).
- Strip comments first, as `config-refs.js` does.
- Put a floor under negative assertions. A `x.length === 0` passes when the
  regex finds nothing ([verify-suite](verify-suite.md)).

## 7. The two sides of a round trip have different names

- The server fires `seamGate` and the client fires back `buySeam`. Likewise
  `openElevator` comes back as `rideElevator`.
- One grep therefore finds half a chain and looks like proof that it is unwired.
  The seam purchase was wrongly called the ship blocker this way (START-HERE §5).
- **Grep both names** ([server](server.md)).

## 8. Two editors, one file, and drifting line numbers

- Studio and Cursor edit the same scripts at the same time (TODO §9). **Anchor
  every edit on unique text, never on a line number**, and re-read the file
  before committing.
- Line numbers quoted in docs drift fast. HANDOFF §2.8 gives `seamGate` at
  MineServer:6406; at `26036a0` it is at 6676. Cite symbols, not lines.

## 9. "It's missing in Studio" usually means stale Studio

A disconnected Studio keeps running old scripts with no warning. Check the
`MineBuild` line in the Output window before debugging
([rojo-and-studio](rojo-and-studio.md), TODO §0.14).
