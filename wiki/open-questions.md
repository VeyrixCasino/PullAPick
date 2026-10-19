---
title: Open questions, contradictions and probable bugs
type: meta
status: current
verified: 2026-10-19 @ b4aa4ed
sources:
  - docs/OPEN.md
  - docs/BLOCKED.md
  - docs/PROPOSAL.md §0
  - docs/TODO.md §0
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineBreaking.luau
related: [owner, sources-of-truth, overview, mining-and-breaking, save-data-and-migrations, traits, enchants]
---

# Open questions, contradictions and probable bugs

> Everything here is **unresolved**. It is the first place to look before
> asking the owner something, and the first place to add a question you
> cannot answer. Each entry names where the detail lives.
>
> **Bugs 1 and 2 were fixed upstream the same day** (`b19c4c2` on PR #6, which
> credits the wiki research pass). They stay in the table, struck as fixed, as a
> record of how the loop works: the wiki finds, the owner's session fixes, the
> wiki re-ingests.
>
> **Confidence labels.** *Read* means I (Claude, in the wiki-building session)
> checked the cited code myself. *Reported* means a research pass found it and I
> did not independently check it. **Nothing here has been run in Roblox.**

## Help needed: pets and pack sets (2026-10-10)

The owner asked for this note. The pet job is specified in
`docs/PETS-AND-SETS.md`. Claude needs the owner for the items below. Each one
has a default that is used if the owner says "you decide".

| # | what I need | my default |
|---|---|---|
| ~~H1~~ | **Answered:** every pet is named separately, all 2,043 included, with about 100 new body types. | — |
| ~~H2~~ | **Answered:** +5% per zone (not 12%), and each set's pet budget is 5% above the set before it. | — |
| ~~H3~~ | **Answered:** set 17's ★★ pack is renamed "Sapwood", and Mosswood keeps "Heartwood". Set 17 itself is now **Eternal Roots** (was Worldtree). | — |
| H9 | **How big is each zone's pot?** Splitting the 322 named pets gives about 25 per zone (Event Horizon keeps its 73). Counts are in `docs/PETS-AND-SETS.md`. | About 40 per zone, so about 15 new pets per zone, roughly 150 in total. |
| H4 | **A names sheet.** I will send every new and renamed pet per zone and set for one yes/edit pass before anything is built. Names are save data, so changing them later costs aliases. | Approve in one pass, by pasting it back with edits. |
| H5 | **Is the old card content legacy?** That is the 41 `MineCards.SETS` (4,023 slots but only 207 distinct pets), the 55 `MineZonePacks` and the 19 `Mine1PacksData` card packs. X/Y and the variant odds at pack open are already confirmed old. The owner said universal packs go, but "don't nuke them" yet. | Retire them from dropping once the new pots exist. Owned cards keep working. |
| H6 | **Art uploads.** The pack and set images, and the wheel's one-image face. An agent can make the images but cannot upload to the group (35326298). | The owner uploads to the group and pastes the asset ids back. |
| H7 | **The 6-hour wheel spin** (rewards pass): do unused spins bank, and how many? | Bank up to 4 (one day's worth). |
| H8 | **One pet session at a time.** Another session rebuilt pet bodies in `PetModelFactory` (`c62fad6`, `1af78a4`). Two sessions editing that 3,500-line file collide. | Only the session the owner continues with touches it. |

## 0. LAUNCH BOARD — owner wants to ship in 4–5 days (asked 2026-10-10)

Everything below is either **blocking**, **a decision only the owner can make**,
or **cut**. Anything already fixed is out of this list entirely; see `wiki/log.md`.

### 0a. Blocking, and nobody else can do them

| # | item | why it blocks |
|---|---|---|
| 1 | **Throw the launch switch.** `/admin launch now` exists (`cc0262f`). | Until it is thrown, `seasonNow()` is pinned to `SEASON_START`: offers frozen on slot one, battle pass never counting, Event Horizon's window never opening. |
| 2 | **Merge PR #7.** `gh` is unauthenticated here. | Carried since 2026-10-07. |
| 3 | **Upload the ore and charm icons.** §7 governs; no agent can upload to a group place. | `docs/TODO.md` 796–803. |
| 4 | **Play it.** Almost nothing in this repo has run in the engine with a real player. | Every measurement is static or Studio-side. |

### 0b. Decisions only the owner can make

| # | decision | the shape of it |
|---|---|---|
| 5 | **Ship social, or cut it?** `MineSocialView` is 387 lines, complete, **mounted nowhere**, with `MineProfileView` parked beside it. Text IS filtered (`TextService:FilterStringAsync`, fails closed). | One line mounts friends, DMs, global chat and groups together. That is a moderation surface, not a bug fix. |
| 6 | ~~**Group Wheel: ship or strip?**~~ **Answered 2026-10-10: ship it, as the daily wheel** (`299dd2c`). Still open: approve its PROPOSED allowances and slice weights, and create the three Robux product ids. | See [social-quests-and-leaderboards](systems/social-quests-and-leaderboards.md). |
| 7 | **Event Horizon's roster.** It builds **138 tools for a 2-section zone** because it walks all of `Depth.SECTIONS`. Prices are capped now (`4f45483`) so nothing overflows 2^53, but **68 of 138 sit at the cap**. | Changing the count moves every event tool's breaking power through `MineBreaking.eventStrength`. |
| 8 | **A depth-scaled coin sink.** Potions fixed the early game only. | Owner picked the direction: progression-flavoured, repeatable, in the loop. |
| 9 | **Ore mastery as the endgame.** Owner chose it over ladders/endless/guilds. | Not started. Advised *after* launch — the 2-hour systems only just became visible. |

### 0c. Known-and-accepted for launch

- **Flat gem floor prices** (pack crate 200, backpack rung 1 at 100) did not
  move with `1e6 → 1e4` and are pocket change. Harmless; they make early play
  generous. The trait roll (500) and re-socketing (10) were on this list until
  they were retired with runes on 2026-10-12. The Forge's gem book
  bundle starts at the trait roll's 500 and rises ×1.15 a zone
  (`MineEnchants.bundlePrice`, PROPOSED).
- **Chests may out-faucet ore sales** — chest gems scale on their own ladder and
  are not pouch-capped. Watch it in live data rather than pre-tuning it.
- **20 of 35 tutorial steps remain unreachable** (`Intro.order` lists 15). The
  three that mattered are in (`cc0262f`); the rest grant items, and switching
  them on would pay out to every existing player on next login. On 2026-10-12
  the rune steps 8 and 9 became one enchant step 8, and the dead rune steps 11,
  23 and 26 were deleted.
- **Social orphans** — tracked by `tools/verify/orphan-verbs.js`, which fails the
  suite on any NEW orphan. (`buyCrate` was a rune crate; it was removed with
  runes on 2026-10-12.)

### 0d. Suggestions worth 30 minutes each, before launch

1. **A first-session smoke test with a blank profile.** Nothing in this repo has
   been played from zero. The intro path reads sound on paper and that is all.
2. **Turn on one leaderboard.** `LeaderboardService` is 1,747 lines and wired;
   a visible board is the cheapest "other people exist" signal a new game has.
3. **Check the Forge recipe page on a phone.** It is five cells per row at a
   scale fraction, untested at narrow widths. **The 2026-10-19 audit found why it
   will look wrong:** the Forge is shrunk twice (§0e M9).
4. **Decide the Discord/code reward values.** `LAUNCH` grants 500 gems and the
   Discord link 5,000 — both flat, both now worth very little after `1e4`.

### 0e. Launch audit of every screen, effect and tool card (2026-10-19)

Owner, 2026-10-18: *"do a deep audit of all uis, effects, tool cards etc, and determine
what needs to be done for launch, and what you need from me"*. Six read-only reviews at
`b4aa4ed` (HUD and menus; shops and Robux; Forge, tool cards and skins; effects and sounds;
client↔server wiring and visible text; pets, cards, quests, Discord and world signs). **Every
MUST-FIX row was re-read in the code by the parent agent**; SHOULD-FIX and POLISH rows are the
reviewers' evidence, spot-checked. Nothing was run in Roblox. The owner chose "list first, you
pick", then picked on 2026-10-19: see **§0e decided** below.

**MUST-FIX: a player is stuck, sees something broken, or pays for something they do not get**

| # | what the player sees | evidence | size | needs from owner |
|---|---|---|---|---|
| M1 | **The tutorial's 5th step can't be done.** Step 3 "BUY A BIGGER PICK" opens the coin pickaxe shelf, and every BUY is refused ("Tools are forged from ore now"). It clears only if the Wooden Pickaxe is levelled until it graduates, which nothing says. Quest rung 3 asks the same. | `MineServer` 3809, 3913, 3932–3946, 9999–10021; `MineConfig` 3042 (`FORGE_ONLY_FAMILIES`); `MineQuests` 29 | S | new wording |
| M2 | **The Candy Crypt is live (since 17 Oct), but candy can't be spent.** The Events tab always shows Event Horizon (first in the list, open all season), so the Crypt card and its Trick-or-Treat button never appear. Even if they did: `setState` drops `hallowOwned`, the claim button says "Claim Event Horizon" and `buyZone` grants Event Horizon. The candy total is shown nowhere. | `MineEventsView/init` 749–761, 862, 892, 938–940; `MineServer` 11590–11607, 3538; `MineConfig` 640 | M | fix it or close the Crypt |
| M3 | **Paid random buys with no odds shown** (credits, gems and tokens trace back to Robux): the Mystery Case buyer (the credit shop's main random item), the Charms Pack, the Forge's "3 random books", trader cases. The region block for paid random items skips `buyProductCredits`, `buyTraderCase` and `groupWheelSpin`. | `MineInventoryView` 1308–1450, 4637, 6735–6737; `MineForgeHub` 1335; `MineClient` 8508; `MineServer` 15005 | S each | confirm the rule applies |
| M4 | **"BUY 799 Robux" on the Founders Rig bag takes 799 credits in one tap**, with no prompt and no confirm (product id 0, so the client falls back to credits). | `MineShopView` 2458, 2678–2686; `MineConfig` 975; `MineServer` 11397 | S | product id, or credits |
| M5 | **Pet seat 4 says "GET VIP" and opens the VIP gamepass, but VIP no longer adds a seat** (3 is everyone's maximum; the VIP card itself says so). | `MineInventoryView` 2788–2824, 7074; `MineConfig` 112, 874 | S | none |
| M6 | **The Founders Pack card lists the "Founders Bag – infinite haul"; buying the pack does not give it** (tag, 3 books and +5% luck only; the bag is a separate 799-credit buy). | `MineInventoryView` 7188; `MineFounders` 31–45 | S | which way |
| M7 | **Lucky Block Week (599 credits, max 3) promises "a Lucky Block pet" that does not exist** (it writes `ownedPets.lucky_block`, which nothing reads), and pays the Heirloom, Omen and Shiny packs retired on 10-10. | `MineRotatingOffers` 35–52, 180–188 | S–M | which way |
| M8 | **Limited deals read "LIMITED TIME · NEVER COMING BACK · ends 0d 0h" from today.** The countdown uses the real clock against end dates on the season clock. The header says "40d left" (the season is 47); the home banner says "New offers in Xh" every day though offers change weekly. | `MineInventoryView` 6041, 6455; `MineRotatingOffers` 233–237 | S | none |
| M9 | **Small screens.** The Forge sizes itself from the raw screen inside a HUD that is already scaled, so it shows at about 57% on a 1280×720 laptop and about 21% on a sideways phone. The fishing window does the same. On a sideways phone the whole HUD is at half size (6–10 px text). The settings panel already does it right. | `MineForgeHub` 305–311; `MineFishingView` 199–203, 671–675; `MineClient` 162–166, 226–247, 4906 | S (double shrink), M (phone layout) | must phones work at launch? |
| M10 | **The card collection page lists the 41 retired sets, stuck at 0/N forever.** The 19 sets and zone pots that drop today can't be browsed anywhere. | `MineInventoryView` 5503–5548; `MineCards` 53; `MineSetPacks` 331–342 | M | rebuild or hide |

**SHOULD-FIX**

| # | area | what the player sees | evidence | size | needs |
|---|---|---|---|---|---|
| S1 | shop | Cart CONFIRM stays tappable while "Confirming": possible double charge | `MineInventoryView` 5685, 5726, 5975 | S | none |
| S2 | shop | Lucky Charm "599 CR" button always says "That offer moved" | `MineInventoryView` 4652–4680; `MineServer` 11388 | S | remove or sell |
| S3 | shop | Depth desk shows coin prices for gem bags and tool cards the server refuses (§1 #13) | `MineDepthShopView` 482–541 | S | none |
| S4 | shop | Founders Bag and Lucky Stack say "through Oct 31"; they run 47 days from launch | `MineRotatingOffers` 77, 112 | S | none |
| S5 | shop | Starter Bundle popup lists the wrong contents (shows once its id is set) | `MineClient` 5187–5206 | S | none |
| S6 | shop | Robux paid for a deal already at its max: "done", nothing granted (once deal ids exist) | `MineServer` 17972 | S | none |
| S7 | shop | Retired card and gear packs still buyable by a crafted request | `MinePackConfig` 1307–1310 | S | none |
| S8 | shop | A Build-a-Box of 10 of one pack costs more than its 10× button (12% vs 30% off) | `MineInventoryView` Build-a-Box | S | which discount |
| S9 | Forge | Craft price on the card is not what the server charges from ore tier 7 up (the server passes no tier, so its multiplier is always 1) | `MineServer` 16856; `MineForgeHub` 242 | S | which number |
| S10 | Forge | SCRAP promises ore and stardust the server won't pay (quotes base level 1) | `MineForgeHub` 1282; `MineServer` 16974 | S | none |
| S11 | Forge | Card damage ignores tool family, skin and finish (Stone Hammer card says 10, hits 37); "Lv 1" though new tools inherit your level | `MineForgeHub` 229, 700, 951, 1097; `MineServer` 2333–2335 | S/M | what a card shows |
| S12 | tools | 164 hammers and jackhammers show a plain pickaxe icon in the hotbar until the Canva icons are shared and `NEW_TOOL_ICONS_SHARED` is flipped; jackhammers 75–82 have no art | `MineIcons` 672, 928–962 | S | share icons |
| S13 | Forge | COIN SHOP opens the pickaxe shelf where every BUY is refused; the old shop still has Crafting, Loadout, Upgrades tabs | `MineForgeHub` 370–374; `MineShopView` 2112 | S | one Forge or two |
| S14 | skins | An ore-case "skin" lands in the temper system, not the Skins wardrobe | `MineServer` 8299 (chests use 5298) | M | skins or tempers |
| S15 | skins | Wardrobe never shows EQUIPPED; a skin's ×1.15–5.5 damage is shown nowhere; most skins, including the Season One pass skins, change no look | `MineSkinsView` 158–160, 198–230, 260; `ToolModelFactory` 1776 | S/L | stat skins or looks |
| S16 | HUD | Pop-up messages draw behind windows and replace each other instantly | `MineClient` 2409–2420 | S | none |
| S17 | HUD | The skill tree has no close button; the only exit teleports you | `MineSkillView` 900–930 | S | none |
| S18 | HUD | Windows open under Skins; "close everything" misses Skins, Trade, Fishing and the Forge | `MineClient` 2783–2811 | S | none |
| S19 | HUD | First Blacksmith visit pops the full-screen Forge while the tutorial says "HOLD on a rock" | `MineServer` 17757–17770 | S | none |
| S20 | HUD | Day-4 "Like & Favorite for a pack" popup: LIKE can't open anything, and rewarding likes may break Roblox rules | `MineClient` 1124, 1189–1196 | S | keep, change or cut |
| S21 | HUD | Coin pill overflows once you own space coins | `MineClient` 522–560, 9666 | S | one pill or two |
| S22 | HUD | Settings: the code result prints on the FRIENDS heading | `MineClient` 5011, 5036 | S | none |
| S23 | HUD | Planets map and the daily-reward card rebuild on every update (scroll lost; up to 10×/s) | `MineClient` 8168–8174, 9682 | S | none |
| S24 | effects | Gear Vault (daily wheel) shows 3 of its 5 items; each reel starts as the last stops | `MineClient` 12289, 12374; `MineGradeReveal` 1806 | S | none |
| S25 | effects | Opening many mystery cases is up to 50 back-to-back 5.4 s spins you can't leave | `MineServer` 134; `MineClient` 3969–3990 | M | skip-all or short spins |
| S26 | sound | No button makes a sound: `MineAudio.bindUiClicks` is written and never called | `MineAudio` 445 | S | on or off |
| S27 | effects | The VFX tab offers trails, shovel FX and nameplates that do nothing (only tags work) and points to a Shop → VFX tab that does not exist | `MineInventoryView` 5306–5352; `MineServer` 201 | S | hide or build |
| S28 | effects | A rare find's card prints a bumped rarity ("SHINY EPIC" for a shiny Rare) | `MineClient` 5948–5955, 6896 | S | true rarity? |
| S29 | effects | Lucky-block SKIP ALL summary leaves out books, potions and skin cases | `MineGradeReveal` 1105–1133 | S | none |
| S30 | effects | The celebration title is a fixed 900 px label and can run off a phone | `MineCelebrate` 318–323 | S | none |
| S31 | style | Text still rides scale animations (case-reel tiles, card flips, toasts, button hover, chest popup); `text-motion.js` checks only two helpers | `MineUI` 114, 207; `MineGradeReveal` 1464, 1620, 1658; `MineClient` 2499 | M | how far the rule reaches |
| S32 | pets | Every pack pet has family "Crystal" and its home's trait (see [pets](systems/pets.md)) | `MineSetPacks` 331–342; `MineCards` 451–468 | S | re-roll or by role |
| S33 | pets | Lone Wolf and Squad Bond card text ignore how many pets are out | `MineCards` 520–540 | S | none |
| S34 | pets | Pet ability lines are zeroed unless they match the held tool's Special; nothing says so | `MineEnchants` 440–470 | S | none |
| S35 | pets | The Cards tab builds a 3D model for every card on every redraw (likely lag) | `MineInventoryView` 2667–2681 | M | none |
| S36 | cards | Tap a card and it equips at once; no detail view; tiles fit 2 stat chips | `MineClient` 6954–6976 | M | detail sheet? |
| S37 | gear | Hats/Faces collection shows the 300 prototype limiteds: 67 can drop, 103 that can drop never show | `MineInventoryView` 4773, 5004–5060 | M | which list |
| S38 | Discord | Any 4–12 letter code gets "Code accepted!"; the tab promises "player markets and remote trading"; a link finished from Discord never pays its 5,000 gems | `MineDiscordLink` 46–60; `MineServer` 13690–13715 | S | is there a bot? |
| S39 | world | Lobby leaderboards promise "101+ Everyone else — 100 gems"; nothing pays any rank; ~11 rows visible | `LeaderboardService` 896, 1056–1064, 1189 | S | pay or remove |
| S40 | quests | Daily quest "Rebirth once" on day one; stale tips (cards10, sell5 "Coins buy tools", cards250, mine75k) | `MineQuests` 37, 38, 95, 106, 274, 277 | S | none |
| S41 | text | The fallback find text is "You found some crazy shit" (nothing reaches it today; it's a kids' game) | `MineServer` 9044, 12638 | S | none |

**POLISH** (one line each): shared or emoji dock icons (Trade = Pass, Skins = Enchanter; Wheel, Planets, Events emoji) and the Halloween pack showing Meadow art (needs 6 icons + 1 image) · wheel slice "3-5 packs" pays 3 · pass says "Super Lucky Block", elsewhere "Diamond" · Limited tab says "credits or Robux", only CR · Founders Bag never shows OWNED · trader header shows the raw zone id · God Pack chance not on the odds sheet · trade picker says "or coinflip" (off) · Events card says "enter from Zones" (it's Planets) · Planets offers Travel to the Crypt outside its dates · fishing can wait forever if a cast is dropped · a rare find plays two fanfares · the reel's big-win punch stacks UIScales · 14 ambience loops play at volume 0 · Event Horizon blast ignores Reduced Motion · the wheel spin is silent · no Escape or 1–5 keys · loading bar doesn't fade · World Pulse banner jargon · every card says "Normal P1" and "Crystal Kit" · Blacksmith tag "Picks, drills, bags" · "RESERVED" signs at bays without a pond · drills say "No spin-up" · every find says "Meadow \| chest find" · dead files nothing requires: `_MineHatsB64.txt` (0 bytes), `MineDepthPlazas_OLD_pre_v4`, `ServerStorage/MineParked/GroupWheel`, `MineBenchView`, `ReplicatedStorage/MineBags_NameCheck.luau`.

**Checked and clean:** admin UI and F8 are allowlist-gated; legacy TCG scripts are disabled and
`TCGUI` is empty; **all 119 client actions have a server handler** (0 dead buttons); no PROPOSED,
TODO or placeholder text a player can see; no blank asset ids on screen; every reel, pack, block,
wheel and fish result comes from the server; every reveal can be skipped and the pack reveal has a
30 s watchdog; celebrations don't stack; no per-frame leaks found; all 322 pet species have a model;
no stale dates on world signs.

**What only the owner can supply:** the answers above · share the 237 Canva tool icons in the
Creator Hub (S12) · Robux: the Founders Rig product id or "credits" (M4), which products ship, and
whether the dashboard prices are Founders R$799 and Battle Pass R$399 · optional art: 6 dock icons,
the Halloween pack image, a Candy Crypt banner · whether a Discord bot exists (S38) · sounds:
library or the ElevenLabs set (`docs/AUDIO.md`) · **one phone play test from a blank profile
through the first craft.**

#### §0e decided by the owner, 2026-10-19 (the build spec)

The owner answered every call in chat (multiple choice, plus their own words where
quoted). **Split:** the cloud session (PR #7) does the **logic and wording** fixes; the
owner's **PC session (with Studio)** does the **visual** ones and checks the cloud
session's screens in Studio. See [next-up](next-up.md) "Who owns what".

**Must-fix**

- **M1** Step 3 becomes **"FORGE your first tool"**: it opens the Forge, clears on the first
  craft (a forged tool counts), and grants enough Stone for a Stone Pickaxe (270) instead
  of coins. Quest rung 3 matches.
- **M2** **Fix the Crypt properly**, and the Crypt is redesigned (below).
- **M3** **Odds on every paid random buy**: Mystery Case, Charms Pack, the Forge's 3 random
  books, trader cases; the region block also covers credit deals, trader cases and the wheel.
- **M4** Founders Rig: **799 credits, labelled as credits, with a confirm step.**
- **M5** Pet seat 4 "GET VIP" goes (no decision needed; VIP adds no seat).
- **M6** **The Founders Pack also gives the Founders Bag.**
- **M7** Lucky Block Week: **a real existing lucky-block pet** (an Epic-ish one that fits)
  and **wild cases of about the same value** instead of the retired packs; text to match.
- **M8** Deal countdowns on the season clock; header says the real season length.
- **M9** **Phones and tablets must work at launch**: no double shrink, tall windows fit the
  screen instead of the whole HUD shrinking to half. *(PC session.)*
- **M10** **Rebuild the collection page** for today's 19 sets, 10 zone pots, Event Horizon and
  Halloween, with have / total and silhouettes. *(PC session.)*

**Should-fix with a call:** S9 **the card's craft price is right** (fix the server) · S20 the
day-4 pack is **given regardless; Favorite optional** via the real prompt · S32 **re-roll each
pet's family and trait from its name** (safe: the game is not open yet) · **the other 15, as
recommended**: S8 Box of 10 gets 30% off · S11 cards show true damage per hit, hits per
second, area, use; "Lv" is the inherited level · S13 one Forge (the old shop shows only
Bags; COIN SHOP goes) · S14 ore cases pay wardrobe skins · S15 superseded by "make skins
work" (below) · S21 the coin pill shows the zone's currency · S25 SKIP ALL for case runs ·
S26 click and "can't afford" sounds on · S27 VFX tab becomes "Tags" *(PC)* · S28 cards print
the true rarity · S31 the text-scale rule covers repeating animations *(PC)* · S36 a tap opens
a card detail sheet *(PC)* · S37 Hats/Faces shows what can drop · S38 **keep Discord**: the
owner runs the bot (`!link` in Discord, the bot writes the code through Open Cloud); show
the invite **discord.gg/Ab5ZpVdRvp** as text · S39 remove the leaderboard reward text.
S2 **remove the dead Lucky Charm row** (the Pot of Gold deal sells it; asked separately the same day).

**Day 29 of the pass:** the owner will have a new pass; if it is late, the old one pauses.

**The look.** *"better bubbly ui all around"*: **the main-world look is toned down**
(calmer, less purple) *(PC session, which owns the lifted look)*. **Events get their own
themes**: Halloween for the Candy Crypt, dark universe for Event Horizon, on the event's own
screens **and on everything that belongs to an event** wherever it shows (its packs in the
shop, its pets' cards, its tools, its case). The cloud session adds the two palettes to the
kit and uses them on the event screens it builds. **Portals more attractive** *(PC)*.
**Tool looks:** event tools get themed 3D models and icons (a Cursor job, checked in Studio).

**The Candy Crypt, redesigned** (Event Horizon unchanged for now: *"Crypt only for now"*):

| rule | the owner's call |
|---|---|
| tools in events | **Normal tools do not work in events.** Claiming the Crypt gives a free starter candy pick. |
| where Crypt tools come from | **Crypt chests and Trick-or-Treat cases.** The candy-tool shop goes. |
| Trick-or-Treat case | **tools 85%**, skin case 5%, hat 7%, Halloween pack 2.9%, bucket 0.1%; no candy back |
| candy | **3x** today's rate |
| Crypt rock | **zone 3 hardness at the top to zone 10 at the bottom**; it still sells for little |
| candy ores | **4 more** (Pop Rocks, Milk Chocolate, White Chocolate, Cotton Candy): 16 in all |
| a candy block pays | **candy AND 1 candy ore item** into the ore pouch |
| candy charms | **a new set of 6 Halloween charms**, crafted at the Forge from candy ores (deeper ore, better charm); candy find, event digging and a small normal stat; **the same power everywhere** |
| merging | **3 identical Crypt tools → Golden → Prism → Rainbow**, the pets' steps |
| after the event | tools work in the event at once; **when it ends you keep them**, and they then also work in the main world (weaker: events must pay better) and in every future event |
| telling players | **a pop-up on first entry** to each event, once, plus the same text behind an (i) on its card |
| selling ores | the pouch's SELL ALL gets **"Sell up to"** (Common / +Uncommon / +Rare / +Epic / +Legendary / Everything), remembered, asks first; and you can **tick candy ores to sell for candy** |
| skins | **one wardrobe everywhere** (event tools wear the same skins) and **"make skins work", all of it**: looks on every family (pickaxe, drill and explosive via a Cursor job), EQUIPPED and the skin's power in the wardrobe, ore-case skins into the wardrobe |


## 1. Probable bugs found while building the wiki

These are not fixed. They are in code that has never run in the engine.
Nobody has asked for fixes; ask the owner before changing any of them.

| # | what | confidence | where |
|---|---|---|---|
| 1 | **FIXED in `b19c4c2`: every forged tool had breaking power 1.** The row `equippedTool` built for a forged tool had no `oreId`, `oreTier`, `tier` or `breakingPower`, so `MineBreaking.toolBreakingPower` fell through to `SHOP_POWER[1]`. The fix commit measured it in a live session: before, every tool from Stone to Oganesson stopped at zone 1, layer 50. The row now carries `oreTier` and `oreId`, derived per swing so no migration is needed. `tools/verify/heldtool.js` pins it. This was the wiki's first catch. | *Read* in code; the commit message reports the live before/after | [mining-and-breaking](systems/mining-and-breaking.md); `MineServer.equippedTool` |
| 2 | **FIXED in `b19c4c2`: the ore-roster migrations re-ran on every load.** The v1 and v2 guards used `~=`, so a save stamped 2 re-entered v1, stamped itself back to 1, and then re-entered v2. Both guards now test `< version` (monotonic). **Not stated in the commit: whether saves already damaged by earlier re-runs were repaired.** The live log showed 0 changes, so any damage would only show on a save that held old-roster tools. | *Read* (guards); damage to saves unverified | [save-data-and-migrations](code/save-data-and-migrations.md); `MineServer` `load()` |
| 3 | **FIXED 2026-10-06: recycling paid for levels the tool never bought.** `MineConfig.toolRecycle` now takes a `baseLevel` and refunds a **differential** — `max(0, toolSpent(level) - toolSpent(baseLevel))` — so an inherited level refunds nothing. Measured in `tools/verify/economy-exploits.js`: a freshly forged tool went from 145,022 ore of profit to 0. | *Read* in code, pinned by harness | [forge-and-recycling](systems/forge-and-recycling.md) |
| 4 | **Event Horizon cannot be mined**: it counts as zone 11 (strength 1000) and event tools get breaking power 1. | *Reported* | [world-events](systems/world-events.md) |
| 5 | **FIXED 2026-10-06: depth desks paid hundreds of times too much.** `DEPTH_SELL_FRAC` (the 0.78 haircut) is deleted and `depthSellMult` is now `DEPTH_SELL_PER_SEAM 1.05 ^ (depth/500)` — a smooth curve instead of ×487.5 at seam 500 and ×12,187.5 at seam 1500. Owner asked for seams to sell for **more**, not less, so the ramp rises gently rather than being clamped down. | *Read* in code | [zones-layers-and-seams](systems/zones-layers-and-seams.md) |
| 6 | **The chest coin crash fix landed in dead code.** The `e77d84e` fix is in `rollChestLoot`, reached only by `giveDrop`, which nothing calls. Live chests use `MineZoneChests.rollCurrency`. | *Reported* | [chests-and-lucky-blocks](systems/chests-and-lucky-blocks.md) |
| 7 | **FIXED 2026-10-14: chest flagship tools never dropped.** `openChestBlock` read `rollChestTool` ~2,600 lines above a later `local function`, so the name was a nil global. Forward-declare `local rollChestTool` before `openChestBlock`, then assign with `function rollChestTool`. Pinned by `tools/verify/chest-tools.js`. | *Read*, pinned by harness | [chests-and-lucky-blocks](systems/chests-and-lucky-blocks.md); [luau-traps](code/luau-traps.md) |
| 8 | **Tutorial step 29 hands a new player SSS hats**, worth +1050% in layer 2. | *Reported* | [hats-and-faces](systems/hats-and-faces.md) |
| 9 | **`MineStats.RUNE_ONLY` silently zeroes the `blastRadius` line on all 26 pets that have one.** Runes are retired (2026-10-12), but the table is kept on purpose because `MineCards` uses it as the pet-kit stat filter. | *Reported* (count not rechecked after the 2026-10-12 calm pass) | [pets](systems/pets.md) |
| 10 | **The charm MERGE button wants 2 copies** (`math.max(2, MERGE_COST)`); the server needs 1 and the gem price is never shown. | *Reported* | [charms](systems/charms.md) |
| 11 | **24 ore charms carry `luck`**, which raises the ore-case chance that drops them. This breaks the "no reward boosts its own acquisition" rule. **24 carry the retired `backpack` stat.** | *Reported* | [charms](systems/charms.md) |
| 12 | **Meadow zone packs can never pay Mythic, Divine or Exotic** (computed from `cardOdds`). | *Reported* | [cards-and-packs](systems/cards-and-packs.md) |
| 13 | **Bag prices show in coins; the server charges gems.** Half fixed (2026-10-19 audit): the surface BAGS shelf now shows gems (`MineShopView.luau` 2338–2345, 2439–2445). The **depth desk** still shows coins and still offers tool cards the server refuses (`MineDepthShopView` 482–541, `MineDepthShop` 202). | *Read* | [ore-pouch-and-backpack](systems/ore-pouch-and-backpack.md) |
| 14 | **`tools/export/sync.ps1` deletes `tools/export/in/`** (`Remove-Item $in -Recurse -Force`). **Not a bug in the script**: that folder is a gitignored scratch directory the Studio export flow fills and consumes, and deleting it is the documented last step (the `b19c4c2` author checked and dismissed it). The only hazard was `CLAUDE.md` naming that folder as a place for Claude.ai exports. `CLAUDE.md` and the wiki now point exports at the gitignored `transcripts/` folder. | *Read* | [rojo-and-studio](code/rojo-and-studio.md); `tools/export/sync.ps1` |
| 15 | **FIXED 2026-10-06: nothing checked Luau's 200-top-level-local ceiling.** `tools/verify/compile.js` now runs `luau-compile` over all 212 files and asserts at least 4 locals of headroom in both big scripts. It found `MineServer` sitting at **0 headroom** on arrival; collapsing seven service locals into one `Svc` table bought 5 back. It has since caught the same break twice more — a `do` block for the dev-scaffolding strip (fixed by making it an IIFE, since `do` shares the main chunk's budget while an IIFE gets its own). | *Read*, pinned by harness | [luau-traps](code/luau-traps.md) |
| 16 | **`tools/start-local-agent.ps1` prints a `cd "<that path>"` hint**, which breaks the owner's no-placeholder rule, and still says "read HANDOFF". | *Reported* | [local-setup](code/local-setup.md) |
| 21 | **FIXED in `b0c2430`: family tempers did nothing on forged tools.** `boosts()` gated `p.toolTempers[fam]` on `(tier or 0) > 0`, but `equippedTool` returns look-rung `0` for forged ore tools (ore tier is not that return). Gate now accepts `row.oreTool` / `row.oreTier`. `tools/verify/layers.js` pins it. | *Read* in code | [skins-cases-and-temper](systems/skins-cases-and-temper.md); `MineServer.boosts` |

## 1b. Found 2026-10-06 to 08, measured or read, not yet decided

These were found while doing other work and are **recorded rather than fixed**,
because each moves the economy in more than one place. Measured figures are in
`docs/ore-yield-and-vein-balance.md`.

| # | what | confidence | where |
|---|---|---|---|
| 17 | **Nothing multiplies ore quantity, and the owner expects enchants to.** `MineServer` rolls ore as `math.random(lo, hi)` straight off `oreYieldFor` — no boost, enchant, luck or finder is applied, and the comment there says the finder is deliberately a *quality* stat. Owner, 2026-10-06: *"REMEMBER ESPICALLY ENDGAME ENCHANTS BUFF THAT SO KEEP IT HIGH"*. So the measured **12 million blocks for an Exotic tool is the real figure, not a pre-multiplier one**. Three options written up in the doc §4: a quantity multiplier, raising the top-rarity bands, or lifting `ORE_CHANCE` for deep zones. Each ripples: `toolCraftCost` and gem value both derive from the drop band. | *Read* in code, measured | [ores](systems/ores.md), `docs/ore-yield-and-vein-balance.md` §4 |
| 18 | **The legacy ore-pack path and the live drop path disagree about the ore finder.** Pack conversion does `each = mid * (1 + oreFind)` — a straight quantity multiplier — while the live drop deliberately does not. One of the two is wrong about the design rule. | *Read* in code | [ores](systems/ores.md), [boosts-and-stats](systems/boosts-and-stats.md) |
| 19 | **`MineDigAuth.canDigLayer` ends in an unconditional `return true`**, so every entitlement check above it is unreachable. This is deliberate for mining and was silently load-bearing for crediting; `canCreditDepth` now carries the strict half (see [zones-layers-and-seams](systems/zones-layers-and-seams.md)). **The dead checks in `canDigLayer` are still dead** — worth deciding whether they should be deleted or re-enabled, because right now they read as protection that does not exist. | *Read* in code | `MineDigAuth.canDigLayer` |
| 20 | **A 6,500-block first tool.** With stone's surface share raised to hit the owner's 1-vein-per-3,000 target, the cheapest craftable tool costs ~6,500 blocks broken (was 13,500). Not obviously wrong, but it is the first number a new player meets and nobody has signed off on it. | measured | `docs/ore-yield-and-vein-balance.md` §2 |
| 21 | **FIXED 2026-10-17: the battle pass ended a week before the offers.** `PASS_SEASON_END` was 40 days after the start while the offers and Event Horizon run 47; it is now 47 too, and `launch.js` pins the three lengths. The same change mirrors the launch stamp to clients (they never learned it, so after a launch they would have shown week one's offers and frozen countdowns) and puts the pass panel on the season clock. Owner: *"do what you think is best for the game"*. | *Read*, pinned by `launch.js` (proved to fail on the old code); not yet run in Studio | [season-and-launch](systems/season-and-launch.md) |
| 22 | **DECIDED 2026-10-17: Chest Luck scales the chest charm drop, and that stays.** `CHARM_CHEST_CHANCE × b.chestLuck`, the same multiplier every other chest reward uses (cases, skins, book bundles, packs). There is **one charm slot**, so wearing one of the five Chest Luck charms means not wearing a power charm: a trade-off, not a free loop. (My earlier note that a code comment denies this was a misreading: that comment is about the `luck` stat, which the chest roll does not use.) | *Read* | [charms](systems/charms.md) |
| 23 | **DECIDED 2026-10-18: the battle pass is 28 days from launch** (owner: *"28 days"*). `PASS_SEASON_END` is now derived from `PASS_SEASON_DAYS` (28), so the length is one number. The offers and Event Horizon stay at 47. `launch.js` pins the pass to `PASS_SEASON_DAYS` and checks it ends inside the season. | *Read* | [season-and-launch](systems/season-and-launch.md) |
| 24 | **DECIDED 2026-10-19: day 29 gets a new battle pass, and the old one pauses if it is late.** Owner: *"i'll having something ready"*, then picked the safety net: if the new track has not shipped by day 29, the old pass stops giving XP and claims and shows "Next pass coming soon", so nobody re-earns the Season One pets and skins or re-buys premium for the same rewards. Today `reconcilePass` rolls everyone to `PASS_SEASON_NEXT` ("2026-11") on the same `PASS_TRACK`, and the panel says "Next season is live" (`MineInventoryView` 7389). **The pause is not built yet**; it is queued with the launch-audit fixes (§0e). | *Read* | [season-and-launch](systems/season-and-launch.md) |

## 2. Where the owner's rules and the code disagree

| rule | what the code does | where |
|---|---|---|
| **TODO §0.13.5: "one charm per ore"** | Two per ore (164 generated). That was an agent design (TODO §6.1), never confirmed. | [charms](systems/charms.md) |
| **TODO §0.13.6: "ore case rolls … to decide whether you get a tool"** | A case never pays a tool; it pays a skin (75%) or a charm (25%). | [skins-cases-and-temper](systems/skins-cases-and-temper.md) |
| **TODO §9: "skin and temper crates cost ore only"** | Temper cases cost **temper tokens**. | same page |
| **TODO §0.13.11: "the swing gate reads `BreakPower`"** | The gate reads the tool row (`oreTier` / `oreId`, derived per swing since `b19c4c2`). Per the research pass the `BreakPower` *attribute* is not read by the gate (not rechecked). | [mining-and-breaking](systems/mining-and-breaking.md) |
| **Standing rule "no pity systems"** | PROPOSAL §0 lines 26 and 28 (**approved**) add pack pity and an Exotic floor. Neither is built. | [cards-and-packs](systems/cards-and-packs.md) |
| **PROPOSAL line 27: "trait pity: NONE"** | OPEN §12 still lists trait pity. Moot since 2026-10-12: tool traits are retired. | [traits](systems/traits.md) |
| **PROPOSAL line 37: "keep the `oreYield` key"** | It was renamed to `blastChance` in `eb973f6`, the day before. | [boosts-and-stats](systems/boosts-and-stats.md) |
| **TODO §0.7 / §0.17: runes are a gem sink and are replaced by traits; "stage 3" (retiring runes) is still to do** | The owner overrode this on 2026-10-11/12: runes, scrolls, sockets **and** tool traits are all retired, and enchants took their field. The gem sink is now the Forge's book bundle. TODO §0.17 has not been updated to say so. | [traits](systems/traits.md), [enchants](systems/enchants.md) |
| **TODO §0.21: capacity comes only from the bag ladder and pouch** | `cap(p)` still multiplies by the `backpack` boost. | [ore-pouch-and-backpack](systems/ore-pouch-and-backpack.md) |
| **PROPOSAL §0 line 13 / §F0** (`ZONE_STEP 1`, `ORE_POW 2.0`, `MAX 209`) | Code has 100 / 1.0 / 1000. | [mining-and-breaking](systems/mining-and-breaking.md) |

**Approved in PROPOSAL §0 but not built** (reported): lines 1–8 (hat, face and pet
ladders, kits), 9, 10, 12, 15, 16, 17 (craft constants, recycle curve,
`ORE_GEM_SPREAD` 1e4 vs the code's 1e6, vault prices), 23 (potion coin prices),
29 (gear sets), 30, 33 and 35.

## 3. Questions for the owner

Check `docs/BLOCKED.md` and TODO §0 first. These are not answered anywhere.
Ask them with options and a recommended default (see `CLAUDE.md`).

**Design**
- **Coins: what are they for?** Seams are free, the Forge runs on ore, tools are
  no longer sold for coins (`9733a05`), and the proposed shape (potions,
  consumables, outpost shops) is unsigned.
- **Are skins cosmetic or a power source?** Docs disagree (`ROADMAP` wrap-only
  vs TODO §0.13 / §0.19 and live `MineSkins` / `MineTemper` kits). Do not invent.
- **After the pass ends (finding 24):** close it until a new track ships (recommended),
  restart the same track for everyone, or something else?
- **One charm per ore, or two?** Is the ~24 hand-authored charm rewrite (AUDIT)
  approved? Should charms sit in a boost layer?
- **Pack pity and the Exotic floor:** build them, or keep "no pity"?
- ~~**Runes at stage 3:** migrate into traits, or refund?~~ **Answered
  2026-10-12: neither.** Runes and tool traits are retired with no refund and no
  migration (owner: *"no one has played.. ur good"*); old saves just drop the fields.
- ~~**What will "enchants" be?**~~ **Answered:** books in a tool's three slots
  ([enchants](systems/enchants.md)). The pet perks in `MineCards.TRAITS` stay
  (owner's pick, 2026-10-12); with tool traits gone, "trait" now means the pet perk.
- **Coolant and Short Fuse lost two of their sources.** Coolant (drill spin-up)
  and Short Fuse (bomb cooldown) came from runes, traits and the skill tree.
  Pets and gear cannot roll them (`MineStats.RUNE_ONLY`; zone pets are banned).
  Since 2026-10-12 only the skill tree grants them (the Water nodes give
  `coolant`, the Metal nodes give `shortFuse`; `boosts()` applies both).
  **Answered 2026-10-16:** drills are instant, and only jackhammers spin up, so
  Coolant (skill tree only) shortens a jackhammer's spin-up. Short Fuse is also
  on 2 pets in every zone (at most 10%) and on a small explosives-only enchant
  (+15% at V). See [enchants](systems/enchants.md).
- ~~**Rework the battle pass.**~~ Done 2026-10-16 to the owner's answers
  ([shops-and-monetisation](systems/shops-and-monetisation.md)). Still open: the
  PROPOSED amounts, the pass pets' and skins' names, and a look in a live server.
- **The Founders pack's 3 books** replaced its White Scroll as an assistant
  default, not an owner decision. Confirm or change it.
- ~~**Should family tempers apply to forged tools?**~~ **Answered in code
  (`b0c2430`): yes** — same `toolTempers` + `applyTemper` path as a shop rung.
  Broader cosmetic-vs-power question above is still open.
- **Is a Meadow pack with no Mythic+ intended?**

**Ship or cut** (AUDIT §5 asked for a yes that was never recorded)
- Trading, lucky blocks, leaderboards, group wheel, event pass, battle pass,
  and the social UI (`SocialView`, `ProfileView` are mounted nowhere).
- **Coins: what are they for now?** The coin shop stopped selling tools in `9733a05` (owner, 2026-10-05), which leaves backpacks as the main coin sink. Is the wooden-pick coin path reachable? It looked unreachable before that commit, and the commit says it is kept on purpose.
- Is `NewGear` meant to replace the current hat catalog? Should faces drop
  from chests?
- Product ids in `MineConfig.PRODUCTS` are all 0: set them, or cut the unsold rows.
- VIP lost a perk. What replaces it? Founders seats: per server or global?
- What happens to Event Horizon after it closes (2026-11-08 04:00 UTC)? Are the
  "Space" ores the planned Event Horizon ores?

**Numbers**
- Is the depth-desk multiplier (bug 5) intended?
- Dirt Meadow floor: 5000, or uncapped?
- Earthquake: capped at 10× a swing, or ~1.2× (the code)?
- Should gem-bought bags and item slots survive rebirth?
- Should several rebirths be allowed at once? Should rebirth affect coin value?
- What goes in the station bay behind each outpost?
- How should the recycle refund be fixed (bug 3)?

**Reach (only the owner can do these)**
- Play the branch in Studio. Nothing from the last week has run.
- Charm and ore icons: 164 ore icons (`MineOreIcons`) and the new 88 pickaxe skins (`MineIcons.ORE_PICK`, `9733a05`) are uploaded, but which account owns them is unverified (they must be group-owned). The pickaxe-to-ore matching is by colour and not final.
- Export or delete `OreShapes`. Sync `ToolBakers.OreToolBaker` back.

## 4. Stale docs and comments

Fix these as you touch them (TODO §9: "kill stale comments on sight").

- **`trap.js` no longer fails.** START-HERE §1 and §5, HANDOFF §2.4, OPEN and
  `suite.sh` (`KNOWN_FAIL="trap"`) all call it a known failure. On 2026-10-05 the
  suite ran **34 passed, 0 failed, 0 did not run**, with `trap` among the passes.
  *Read.* OPEN also says `zones.js` is red; it passes.
- Counts have drifted. START-HERE says "101 commits ahead" and "23 checks" and
  "11 need luau"; git says 86 commits ahead of `main` at the time, and the suite
  has 34 checks, 14 of which need the luau binary. MineServer is about 17,050
  lines and MineClient about 12,255 (docs say 16.7k / 14.8k and 11.9k); there
  are 212 `.luau` files (docs say 199 or 210). *Reported.*
- START-HERE §5 says only one change was ever confirmed in-engine; about 50 later
  commit messages say they were verified in Studio (for example `44a1d5f`). Treat
  "has it run in Roblox?" as **unknown per feature**, and ask the owner.
- HANDOFF §1 says `AGENT_PROMPT` and `PROMPTS` are outside the repo; they are in
  `roadmap/`. TODO §4 lists a duplicate pet module that was deleted in `f6bb23f`.
- The HP formula in `docs/depth-sheet.md`, `roadmap/NUMBERS.md` and
  `docs/live-config.md` is the old ×6 ×2 one; the code is linear ×5, and
  `tools/gen-depth-sheet.js` would write the stale formula back.
- `tools/verify/seams.js` checks a coin price ladder, but `MineDepth.seamPrice`
  returns 0 (seams are free).
- `build/ore-sheet/ASSETS.md` gives group id 7706885185; `MineConfig.GROUP_ID` is
  35326298. Ore icon art was uploaded in `f5b6c34` (164 assets) although TODO
  §6.3 and BLOCKED #11 say it is not applied. Who owns the uploads is unverified.
- `TOOL_MAX_LEVEL` is 30; OPEN and `tools/gen/upgrade-calculator.js` still say 100.
- `tools/gen-ores.js` reads the stale `docs/ore-remake.md` and only refuses
  `--write` today because 13 live ore ids have no mapping.
- `MineBuild.STAMP` is still set to 2026-10-04. `docs/rojo-connect.md` says Rojo
  was "never attached" (stale). START-HERE §7 points at BALANCE-PROPOSAL and
  leaves out PROPOSAL.

- `docs/START-HERE.md` §2 calls layer 500 the ship blocker; its own §5 and
  OPEN P0 §1 say the seam chain is wired. Line numbers in OPEN P0 §1 and HANDOFF
  are stale (`Verbs.buySeam` is near line 9540).
- `AGENTS.md` and START-HERE say Workspace exists only in the place file, but
  `WorldBuilder.build()` rebuilds `MineWorld` at boot.
- `docs/ore-remake.md` banner, `docs/decisions.md`, `docs/depth-sheet.md`,
  `roadmap/CHARMS.md`: superseded. `docs/SKILL-TREE.md` has a pre-remap roster.
- OPEN P2 says the battle pass is parked in `MineParked` (it is live) and the
  Event Horizon duplicate is still to delete (done in `f6bb23f`).
- `PRINCIPLES §8` still says "pet slots 3→8". The code has 3.
- The roadmap docs claim `gen-ores.js` has a `--force-stale` guard; that commit
  (`9932508`) is only on `origin/ore-tools-power`.
- Stale code comments: `MineCharms`, `MineGear`, `MineHats`, `MineOrePouch`,
  `MineBags`, `MineStats` (zap, earthquake, gemFind, and stat keys "migrated on
  runes"), `MineDigAuth` ("snap-back"), `MineBreaking`, `MineDepth`, the World
  Pulse comment in `MineServer`, `MinePackConfig.PACK_PRICE`, `LIMITED_DAYS`.
  (`MineTraits` and `MineRunes` were on this list until they were deleted on 2026-10-12.)
- Founders price: comments say 1000 credits / R$999; constants say 799.
  `PlaceConfig.MAIN_PLACE_ID` is not the placeId in START-HERE.
- Dead code the research passes found: `NEW_CARD_BIAS` (never read), the X/Y
  named pet roster (not wired into minting), `rollChestLoot` and `giveDrop`.

## See also

- [owner](owner.md)
- [sources-of-truth](sources-of-truth.md)
- [ambiguous-terms](ambiguous-terms.md)
- `docs/OPEN.md`, `docs/BLOCKED.md`
