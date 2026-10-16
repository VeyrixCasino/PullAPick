---
title: The candy house style (read before touching any UI)
type: code
status: current
verified: 2026-10-10 @ 591434a
sources:
  - src/ReplicatedStorage/Mine/Shared/MineTheme.luau
  - src/ReplicatedStorage/Mine/Shared/MineUI.luau
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
   - `popNumber(label)`: a number pops whenever it changes.
   - `pulse(inst)`: a loop for anything claimable. It returns a stop function.
   - `pop(frame, 0.9)`: a window springing open.
7. **One UIScale per instance.** Roblox applies only the first UIScale (measured
   2026-10-08). `pop`, `juice` and `pulse` are channels on one shared `FxScale`
   and multiply together. Never add your own UIScale to a kit-styled frame; call
   `MineUI.pop` instead.
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
| tokens: `CANDY`, `OUTLINE`, strokes, text floors | `MineTheme.luau` |
| constructors, shapes, motion, `watch`/`adopt` | `MineUI.luau` |
| rarity-scaled celebrations, `skipHint`, `suspense` | `MineCelebrate.luau` |
| win stingers, music, every sound slot | `MineAudio.luau`, `docs/AUDIO.md` |
| odds sheet for paid random items | `MineLuckyOddsView.luau` |
| HUD (wallet, dock, quest panel, hotbar) | `MineClient.client.luau`, `MineHotbar.luau` |
| loading screen (inline colours: runs before the theme replicates) | `src/ReplicatedFirst/MineLoadingScreen.client.luau` |

The full history of the pass, every fix and every Studio check is in
[client-and-ui](client-and-ui.md).
