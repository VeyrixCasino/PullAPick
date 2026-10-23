---
title: The candy house style (read before touching any UI)
type: code
status: current
verified: 2026-10-19 @ db59c60
sources:
  - src/ReplicatedStorage/Mine/Shared/MineTheme.luau
  - src/ReplicatedStorage/Mine/Shared/MineUI.luau
  - src/ReplicatedStorage/Mine/Shared/MineEventsView/init.luau
  - src/ReplicatedStorage/Mine/Shared/MineCryptView.luau
  - tools/verify/crypt-ui.js
  - src/ReplicatedStorage/Mine/Shared/MineCelebrate.luau
  - src/ReplicatedStorage/Mine/Shared/MineAudio.luau
  - src/ReplicatedStorage/Mine/Shared/MineLuckyOddsView.luau
  - src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau
  - docs/AUDIO.md
related: [client-and-ui, owner, luau-traps]
---

# The candy house style

> Owner, 2026-10-08: *"make the ui look more attractive to kids playing roblox.
> Use design, psychology, and everything you got"*. They chose a **chunky
> candy-game** look, **juicy** motion, **bigger text**, and a reach of everything.
> Every new screen, button, popup and reveal follows this page. The kit makes
> it the default: build with it and you get the look for free.

## The look in one line

The game's deep indigo is the base. On top of it go bright candy colours, a fat
dark outline on everything you can press, big bold numbers, and motion on
everything: things bounce when touched, pop when they change and pulse when
they pay out.

## The rules

1. **Build with `MineUI`, never with a raw `Instance.new` surface.**
   - Constructors: `MineUI.button`, `pill`, `panel`, `card`.
   - Shapes: `candy(inst, key)` gives a gradient fill and a fat outline.
     `candyTint(inst)` does the same but keeps the hue in `BackgroundColor3`,
     for surfaces recoloured at runtime. `outlineText(label)` gives white text
     with a dark edge.
   - In `MineClient` the kit is `ClientFns.UI`. The file is at the 200-local
     ceiling, so never add a top-level local.
2. **Colour means something.** Each `MineTheme.CANDY` key has a job:
   | key | job |
   |---|---|
   | `gold` | the primary action, coins |
   | `green` | go, claim, ready |
   | `cyan` | gems |
   | `magenta` | stardust, magic |
   | `orange` | the bag |
   | `blue` | a neutral tile |
   | `red` | close, danger |
   | `purple` | the default |

   One colour per dock button and per currency, so a kid finds "the gold one"
   without reading. Never repaint a saturated fill, because it carries meaning.
3. **Fat dark outline.** Use `T.OUTLINE`, at `STROKE_CHUNKY` (3) for buttons and
   `STROKE_THICK` (4) for panels.
4. **No gloss "bubble".** The owner rejected it on the dock: *"get rid of that
   weird bubble that takes up half the icon"* (2026-10-08). `gloss` is opt-in.
   Leave it off.
5. **Big text, few words.**
   - The floors are `TEXT_MIN` 14, `TEXT_BODY` 16 and `TEXT_TITLE` 26.
   - Numbers are the biggest thing on a widget.
   - Use white outlined text on candy fills.
   - Kids skim, so cut words before you shrink type.
6. **Juice everything.**
   - `MineUI.juice(btn)`: hover grows, press squashes.
   - `popNumber(label)`: a number's outline lights gold whenever it changes.
   - `pulse(inst)`: a loop for anything claimable. It returns a stop function.
   - `pop(frame, 0.9)`: a window springing open.
7. **One UIScale per instance.** Roblox applies only the first UIScale (measured
   2026-10-08). `pop`, `juice` and `pulse` are channels on one shared `FxScale`
   and multiply together. Never add your own UIScale to a kit-styled frame; call
   `MineUI.pop` instead. **Text never rides a scale animation.** Roblox draws
   text at whole font sizes, so an easing UIScale steps it a pixel at a time,
   which reads as the font sizes flickering (owner, 2026-10-14 and 2026-10-17).
   The kit enforces it: `pulse()` on anything that carries text runs a ring
   that ripples off its edge while the thing holds still (an outline glow if
   it holds a layout), and `popNumber()` lights the number's outline gold
   instead of popping its size. Checked by `tools/verify/text-motion.js`.
8. **What pays out always moves.** A claimable thing pulses and shows a green
   dot, and `MineNotifs` badges pop and pulse. The HUD should always show the
   player their next reward.
9. **Never in the way.**
   - Collapse in place. The QuestPanel shrinks to a "QUESTS" pill; nothing slides
     off screen behind "ear" tabs (the owner rejected those).
   - Overlays sink no input.
   - Every reveal can be skipped or sped up.
10. **Luck and reveals: big wins, honest wins.** Use
    `MineCelebrate.burst(tier)` with a tier from the **real** result. The mappers
    are `fromBand`, `fromGrade`, `fromRank` and `fromOneIn`.

    | tier | name | what it does |
    |---|---|---|
    | 0 | common | a soft pop, no overlay |
    | 1 | nice | sparkles |
    | 2 | great | confetti, rays, a title |
    | 3 | epic | a flash and a shake |
    | 4 | legendary | a rainbow title, double confetti |

    - *"slot machine wins are fine ... i just dont want alarms"* (2026-10-08).
    - There are **no fake near-misses** and **no fanfare on a dud**.
    - `suspense()` plays only when the result really is epic or better.
    - Paid random items **show odds before purchase**. See `MineLuckyOddsView`
      and the pack inspector.
11. **Sound.** `MineAudio.playWin(tier)` plays the stinger. Every slot,
    library pick and ElevenLabs prompt is in `docs/AUDIO.md`. Sounds heard
    hundreds of times an hour stay soft. **No sirens, buzzers or klaxons.**
12. **Verify in Studio, with a screenshot, before you call it done.** In the
    command bar, `require` gives you a **different module cache** from the
    game's. Watch for `MineSfx_*` sounds and `PlayerGui.MineCelebrate.Burst`
    frames instead of wrapping the module.

## The kit does most of it for you

`MineUI.watch(gui)` runs `adoptOne` on everything the views build:

- Neutral fills become theme surfaces.
- Big surfaces get the fat outline.
- Coloured buttons gain candy shading and an outline, keeping their hue.
- Buttons up to 90 × 360 get juice.

Text sizes inside the old windows were **not** raised, because their
fixed-width labels would clip. When you rewrite a window, raise its type to
the floors above. Opt out of all this with the `NoAdopt` attribute.

## Event themes (2026-10-19)

Owner: *"better bubbly ui all around, in halloween, halloween theme, and
dark/univedrsze theme in event horizon"*, on the event's own screens **and on
everything that belongs to an event wherever it shows** (its packs, its pets'
cards, its tools, its case). The main world keeps the lifted look; toning that
down is the PC session's job.

- **Palettes** (`MineTheme.EVENT_THEMES`): `halloween` (night purple-black shell,
  candy-purple bands and edge, bone-white face and type, pumpkin accent, slime
  glow) and `universe` (deep-space shell, nebula-violet bands and edge,
  star-white face, teal accent and glow). Each has the lifted roles (`SHELL`,
  `SHELL_HI`, `FACE`, `FACE_DIM`, `ON_FACE`, `ON_FACE_MUTED`, `ACCENT`, `EDGE`)
  plus `INK`, `TEXT`, `MUTED`, `GLOW`, `OUTLINE`, `CANDY` button pairs by job
  (`primary`, `secondary`, `go`, `danger`) and a corner `BADGE` (🎃 / 🌌).
  `MineTheme.LIFTED` is the main world's in the same shape. Every value is
  PROPOSED; `crypt-ui.js` checks type on shell and face reads (over 7:1).
- **Which theme:** `MineTheme.eventTheme(key)` takes a zone, event or theme name;
  `themeFor` never returns nil; `eventKeyOf(item)` names an item's event from the
  ids the game already stamps (a pet's `cardKey` home, pack ids, `eventOnly` /
  Crypt tool ids, `hallow_` charms, a pouch row's `candy`).
- **Build with it** (`MineUI`): `themePanel`, `themeCard`, `themeText`,
  `themeButton` (job `"off"` greys it and makes it inactive, so the click binder
  plays the "can't" knock), `setJob`, `tint`, `themeStroke`. Every themed
  instance records its role (`ThemeFill` / `ThemeInk` / `ThemeEdge` /
  `ThemeJob`) and is stamped adopted, so `MineUI.watch` cannot repaint a night
  shell indigo. `applyTheme(root, theme)` repaints a tree by role, skipping any
  subtree marked `ThemeLock` (the Events tab's cards keep their own palette).
  `candy()` now also takes a `{ top, bottom }` pair.
- **One helper for event items anywhere:** `MineUI.eventMark(inst, key)` puts a
  ring in the event's ACCENT-to-EDGE gradient just inside the tile's own rim
  (a child frame, so the rarity rim keeps its meaning) and the event's badge in
  a corner; `nil` removes it, so a repainted tile can call it every time.
- **Where it is on (2026-10-19):** the Events tab (both cards, the pills, the
  panel, Event Horizon's pass), the Crypt's card, the first-entry pop-up, the
  pouch's candy-ore section, the candy wallet pill, a Crypt chest's candy row,
  and event pets' cards (`paintCard`). **Not yet:** event packs in the shop
  and the inventory (`MineInventoryView` belongs to another session), Event
  Horizon's tool shelf in the old shop and the Forge hub's EVENT TOOLS, the
  hotbar, the case reel. The PC session finishes those. Crypt tools, charms
  and Trick-or-Treat prizes wait for the Crypt's next redesign (owner,
  2026-10-19).

## Checklist for a new screen

- [ ] Built from `MineUI` constructors. No raw surfaces.
- [ ] One candy colour per meaning. Fat outline on every pressable.
- [ ] Text at or above the floors. The numbers are the biggest thing.
- [ ] Buttons juiced. Claimables pulse. Numbers pop.
- [ ] It collapses or closes in place and never covers the HUD's way out.
- [ ] Any random outcome goes through `MineCelebrate` with the real tier, and
      any paid random outcome shows its odds.
- [ ] Sounds come from `MineAudio` slots.
- [ ] Seen in Studio, with a clean console and a screenshot.

## Where it lives

| piece | file |
|---|---|
| tokens: `CANDY`, `OUTLINE`, strokes, text floors; the event palettes `EVENT_THEMES`, `eventTheme`, `eventKeyOf` | `MineTheme.luau` |
| constructors, shapes, motion, `watch`/`adopt`; themed builders, `applyTheme`, `eventMark` | `MineUI.luau` |
| rarity-scaled celebrations, `skipHint`, `suspense` | `MineCelebrate.luau` |
| win stingers, music, every sound slot | `MineAudio.luau`, `docs/AUDIO.md` |
| odds sheet for paid random items | `MineLuckyOddsView.luau` |
| HUD (wallet, dock, quest panel, hotbar) | `MineClient.client.luau`, `MineHotbar.luau` |
| loading screen (inline colours: runs before the theme replicates) | `src/ReplicatedFirst/MineLoadingScreen.client.luau` |

The full history of the pass, every fix and every Studio check is in
[client-and-ui](client-and-ui.md).
