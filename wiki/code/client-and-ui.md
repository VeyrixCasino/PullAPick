---
title: The client and the UI kit
type: code
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau
  - src/ReplicatedStorage/Mine/Shared/MineUI.luau
  - src/ReplicatedStorage/Mine/Shared/MineTheme.luau
  - src/ReplicatedStorage/Mine/Shared/MineHotbar.luau
  - src/ReplicatedStorage/Mine/Shared/MineBuild.luau
  - src/ReplicatedStorage/Mine/Shared/MineNotifs.luau
  - src/ReplicatedStorage/Mine/Shared/MineCelebrate.luau
  - src/ReplicatedStorage/Mine/Shared/MineAudio.luau
  - src/ReplicatedFirst/MineLoadingScreen.client.luau
  - docs/AUDIO.md
  - docs/TODO.md §0.14, §0.33
related: [server, code-map, luau-traps, rojo-and-studio, tools]
---

# The client and the UI kit

> One LocalScript draws the HUD, handles input and moves the pets. Every panel
> is a separate `*View` module mounted into one ScreenGui. Since 2026-10-05 a
> shared kit (`MineUI` and `MineTheme`) gives all of them one house style.

## `MineClient.client.luau`

- `src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau` is **12,255
  lines**. HANDOFF §2.2 says 11.9k.
- It has 176 top-level `local` lines, and several of them declare more than one
  name. It sits at the 200-register ceiling.
  - Twice it stopped compiling entirely: "Out of local registers when trying to
    allocate …". With the client dead, there was no HUD and no panels. The
    comments above `local ClientFns` and `refreshMineUiScale` record both times.
  - The workaround is the client's version of `Dig`: **`local ClientFns = {}`**,
    with about 130 `ClientFns.x` functions hung off it. New helpers go there.
    **Do not add top-level locals to this file** (its own comment says so).
- **Startup order:** `MineBuild.announce` (next section); requires, with `net` set
  to `ReplicatedStorage.Mine.Remotes.MineNet`; a fresh `MineUI` ScreenGui
  (DisplayOrder 80, `IgnoreGuiInset`) replacing any stale one; `MineUI.watch(gui)`
  and audio, each under `pcall`; HUD scaling; the views; then the
  `net.OnClientEvent` ladder.
- **Talking to the server.** Requests go out as `net:FireServer(action, payload)`.
  Replies come back through one `net.OnClientEvent:Connect(function(action, payload, extra))`,
  a 52-branch `if action == …` ladder. Names often differ from the server's side
  of the same round trip; see [server](server.md).
- **`snapshot`** is the main reply. It sets `snap`, applies settings and repaints
  the hotbar. A comment in the handler warns that the server sends about 10
  snapshots a second while digging, so nothing heavy is rebuilt per snapshot.

## Is Studio running this code? (`MineBuild`)

`MineBuild.announce` runs first and prints `MineBuild.STAMP`, which is
`"2026-10-04 traits + centred pets"` at `26036a0`. It then checks
`MineBuild.EXPECT`, a list of the modules this build needs (MineForge,
MineOrePouchView, MineTraits and others), against the live DataModel. If any is
missing it warns **"THIS STUDIO IS RUNNING OLDER CODE THAN src/"**, names what the
player loses, and gives the fix: `git pull` in the clone that `rojo serve` is
running from, then reconnect. TODO §0.14 explains why this exists: "the UI isn't
there" has twice been a sync problem, not a code bug.
`tools/verify/build-stamp.js` keeps `EXPECT` honest. More in [rojo-and-studio](rojo-and-studio.md).

## The `*View` pattern

Each panel lives in `src/ReplicatedStorage/Mine/Shared/` as `View.mount(parent, opts)`
and returns a controller: `invCtl`, `shopCtl`, `forgeCtl`, `ClientFns.hotbarCtl`.
`opts` holds callbacks, and the client wires them to `net:FireServer`. The view
**owns no state**: it renders the snapshot it is handed and reports clicks.

| view | what it is |
|---|---|
| `MineInventoryView` | the main window (packs, cards, chests, shop, passes). 7,867 lines. |
| `MineShopView` | the shop. It mounts `MineForge` (Forge tab) and `MineOrePouchView` (Ore Pouch tab). |
| `MineForgeView`, `MineTraitView`, `MineRunesView`, `MineSocketsView` | the Enchanter panes |
| `MineSkillView`, `MineZoneMapView`, `MineDepthShopView`, `MineEventsView`, `MineProfileView` | other panels |
| `MineTradeView`, `MineSocialView`, `MineGroupWheelView` | these break the rule: they call `net:FireServer` themselves (11, 11 and 1 calls) |
| `MineBenchView` | superseded by the Forge (AUDIT §5) |

`tools/verify/forge-snap.js` checks one specific failure. The shop passes the
Forge a hand-built **subset** of the snapshot, so any field the Forge reads but
the shop does not pass arrives as nil, and nothing errors.

## House style: `MineTheme` + `MineUI`

- **`MineTheme`** holds the palette and fonts. It was rethemed in `44a1d5f`
  (2026-10-05) from warm brown to cool indigo, with every value sampled from a
  reference screen the owner supplied.
  Tokens include GOLD (title and the one primary action), GEM (cyan: tier,
  gems), ACCENT (violet: selection, rarity) and EDGE (the lit hairline). The
  display font is BuilderSansBold. 23 files read MineTheme.
- **`MineUI`** is a set of constructors: `panel`, `card`, `tile`, `pill`, `button`,
  `icon`, `text`, `title`, `muted`, `flow`. Each one applies the same radius,
  hairline, padding and gradient. New UI should be built with these, never with
  raw `Instance.new`.
- **`MineUI.watch(gui)`** (`f4f038d`) restyles all the older views without
  rewriting them. It runs `MineUI.adopt` on everything as it is built.
  - It changes only surface colour, corner radius, the hairline and fonts.
  - It skips **saturated** fills, because those carry meaning: rarity,
    currency, affordable versus blocked.
  - It never touches layout.
  - A panel that sets the `NoAdopt` attribute opts out.
- Later passes: `e56c31a` (shop panel), `dbcd283` (custom hotbar and HUD scale-up),
  `9600e74` (quest cards, shop above the hotbar).
- Two things are called "MineUI": the module, and the ScreenGui. See [ambiguous-terms](../ambiguous-terms.md).

## The candy pass (2026-10-08)

Owner: *"make the ui look more attractive to kids playing roblox"*. They chose
a chunky candy-game look, juicy motion, bigger text, and a reach of everything.
The indigo surfaces stay as the base, with bright candy on top.

- **Theme tokens** (`MineTheme`): `CANDY` (gradient pairs gold, green, cyan,
  magenta, orange, blue, red, purple), `OUTLINE` (near-black indigo),
  `STROKE_CHUNKY` 3, `STROKE_THICK` 4. Text floors were raised:
  `TEXT_MIN` 14, `TEXT_BODY` 16, `TEXT_TITLE` 26.
- **Kit** (`MineUI`):
  - Shapes: `candy` (gradient fill + fat outline), `candyTint` (the same, but
    the hue stays in `BackgroundColor3` for surfaces recoloured at runtime),
    `outlineText`.
  - Motion: `tween`, `pop`, `popNumber`, `juice` (hover grow, press squash),
    and `pulse` (a loop that returns a stop function).
  - `button` and `pill` are now filled candy shapes.
  - The gloss highlight is **opt-in** (`gloss = true`). The owner rejected it
    on the dock: *"get rid of that weird bubble that takes up half the icon"*.
- **HUD** (`MineClient`). Every piece reaches the kit as `ClientFns.UI`, not as
  a top-level local.
  - Wallet: one candy pill per currency, numbers that pop on change.
  - Dock: one colour per button.
  - Badges: pop when they rise, and pulse.
  - Everything else: chunky outlines and bigger type.
- **One quest panel.** Owner: *"fix the quests and the ugly arrow ... make it
  all a part of the same exact ui"*.
  - `QuestPanel` holds the active quest (`questBox`) and the dailies, both
    transparent and stacked by `ClientFns.layoutQuestPanel`.
  - The panel has one header with a collapse button. Collapsing shrinks it in
    place to a "QUESTS" pill.
  - The old "ear" tabs that slid the cards off screen are deleted.
  - A phone starts collapsed, and modals collapse it.
- **Window shell.** `panel(name)` (Enchanter, Planets, Rebirth, Merge, Scrapper)
  has a header band, a red candy close button, and pops in when opened.

## Luck reveals: `MineCelebrate`

One rarity-scaled celebration for every random reveal, called with a tier.
The tier mappers take the real result:

- `fromBand` (pack DUD…GOD)
- `fromGrade` (F…SSS)
- `fromRank` (lucky blocks 1–6)
- `fromOneIn` (odds)

| tier | what the player gets |
|---|---|
| 0 common | a soft pop sound only. A dud is not a party. |
| 1 nice | a sparkle burst and a pluck |
| 2 great | + confetti, light rays, edge glow, a title, a sting |
| 3 epic | + flash, a gentle shake, a horn riff |
| 4 legendary | + rainbow title, double confetti, an orchestral sting |

- **Honest by construction.** Card packs and lucky blocks can be bought with
  credits (Robux), and the players are kids. So there are no fake near-misses
  and no fanfare on a dud. `suspense()` (a drum roll) plays only when the
  result really is epic or better.
- **Never in the way.** The overlay (DisplayOrder 130) sinks no input, and
  `cancel()` kills it when a reveal is skipped. `skipHint()` adds "TAP TO SKIP".
  Roblox's Reduced Motion setting drops the shake and the spinning rays.
- **Sound.** `MineAudio.playWin(tier)` plays the stinger. The slots, the
  library picks and the ElevenLabs prompts are in `docs/AUDIO.md`. The owner's
  rule for sound: *"slot machine wins are fine ... i just dont want alarms"*.
  The old per-reveal sounds all route into `playWin` now: `playCard` (pack
  bands), `playLuckyWin` (grade rank 1–8) and `playFound` (odds).
  `playPull` is silent, because `playCard` already fired for the same card.
- **Where it is wired:**
  - **Packs** keep their own band FX (MinePackFX) and get the new stingers.
  - **Lucky blocks** play their win at last. They had no win sound, and S and
    up add the title-and-rays overlay.
  - **The case reel** adds the overlay at S and up.
  - **S-rank chests** get the small tier-1 pluck. Every other chest stays
    silent, by the owner's request.
- **Pack navigation fixes:**
  - SKIP ALL now really skips: no per-hit hold, banner or stinger, then one
    celebration for the best hit. Its `rush = true` had been writing a global,
    because `local rush` was declared below the handler.
  - The end-of-pack hint now says what a tap does (closes), not "TAP FOR ANOTHER".

## HUD scaling

`refreshMineUiScale` sets the `MineUiScale` UIScale on the ScreenGui.

- **Touch devices** step by the screen's short side: 0.78, 0.88, 0.95, then 1.
- **Desktop** uses `clamp(short / 1080, 0.80, 1.25)`. The layout is authored
  for a 1080-tall screen.
- **Fit guard.** The tallest panel (`PANEL_H` 964) plus a 6% margin must fit
  the viewport height, and the scale never drops below 0.5.
  `tools/verify/ui-scale.js` parses this line, so keep its shape.
- The constants are declared **inside** the function on purpose. Hoisting
  them to the top level broke the client by pushing it over the 200-local limit.

## Hotbar (`MineHotbar`)

- The default Roblox Backpack is switched off
  (`SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)`), which removes the
  "grey cube".
- In its place, at most 5 square slots are drawn with MineUI and MineIcons:
  slot 1 holds the tool (VIP players get 2 tool slots), the rest hold
  consumables, and the bar is only as wide as the slots in use.
- It renders from the snapshot and reports clicks. The server's `equipOreTool`
  treats an empty uid as "unequip".
- Owner requests from 2026-10-05 are quoted in the module header.

## Notifications and layering

- **Toasts**: the server sends a `toast` event and the client shows a single
  toast label. It is the most-used event, with about 437 server call sites.
- **Badges**: `MineNotifs` draws red dots and number badges (`NotifBadge`) on
  buttons that have something to claim. `b83b150` fixed a `ClipDescendants` typo
  that threw an error on every client load.
- **Layering by DisplayOrder**:
  - HUD `MineUI`: 80.
  - The lucky-block screen (`LuckyReveal`): 95.
  - `MinePackReveal` and the case reel (`CaseSpinGui`): 120. The case reel
    moving from 110 to 120 (`bca50ca`) was the first change the owner
    confirmed in-engine (TODO §0.32). That commit's message calls it "the
    lucky screen", but the diff is `caseSpin`.
  - `MineCelebrate`: 130, above all of them, and it sinks no input.
- **Loading screen**: `src/ReplicatedFirst/MineLoadingScreen.client.luau` removes
  the default loader and shows a splash image asset.

## Other client scripts

`MineAdminClient` waits for the `AdminReady` remote; see [admin-and-debug](../systems/admin-and-debug.md).
`MineAmbience` adds client-only motion to tagged world parts. `LoadPlayerModule`
boots Roblox's PlayerModule.

## Gotchas

- "A panel is missing" is a sync question first (TODO §0.14). Check what the
  MineBuild line in the Output window says before debugging.
- START-HERE §5 says almost nothing has run in Roblox. That was written before
  the retheme. The retheme commits say they were played in Studio, with a clean
  console on load (`44a1d5f`, `f4f038d`; *taken from the commit messages, not
  re-checked*). Treat UI claims as "verified once by an agent", not as
  "confirmed by the owner".
