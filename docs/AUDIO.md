# Audio: what plays, where it lives, and how to replace it

Written 2026-10-08 with the candy UI pass. Every sound in the game is a **named
slot** in `src/ReplicatedStorage/Mine/Shared/MineAudio.luau` (`MineAudio.IDS`
for sound effects, `MineAudio.MUSIC` for songs). To swap a sound, upload the new
file and paste its `rbxassetid://` into that slot. Every place that plays it
picks up the change. You don't need any other code.

## The two rules

1. **Wins escalate with rarity, and there are no alarms.** Owner, 2026-10-08:
   *"slot machine wins are fine, maybe even encouraged ... i just dont want
   alarms"*. A legendary pull should sound huge. A common pull gets a small pop.
   Nothing may sound like a siren, buzzer, klaxon or a harsh repeating beep.
2. **Upload to the group, never a personal account** (TODO §7, group
   `35326298`). Audio uploaded to a personal account won't play for other
   players in a group game.

## What is in each slot now

All picks are Roblox's own licensed libraries (APM Music and Pro Sound Effects),
so there is no copyright risk. Each one was checked to load in Studio on 2026-10-08.

### Win stingers (new, played by `MineAudio.playWin(tier)` via `MineCelebrate`)

| slot | tier | current pick | length |
|---|---|---|---|
| `win_nice` | 1 Nice | The Little Things – Hit (APM) | 2.7s, cut to 1.4s |
| `win_great` | 2 Great | Cartoon Time Sting ×4 takes (APM) | 7–9s, cut to 2.6s |
| `win_epic` | 3 Epic | Elated In Love (APM horn riff) | 5.7s, cut to 4.2s |
| `win_legend` | 4 Legendary | 1812 Overture, sting b (APM) | 4.7s |
| `win_legend_tail` | 4 Legendary | Fanfare Sting (APM), layered under it | 6.0s, cut to 4.6s |
| `suspense` | before Epic+ only | Snare Drum Roll ×2 (APM) | cut to 1.15s |

### Music (`MineAudio.MUSIC.bright`, the daytime/surface playlist)

Added: **Planet Kids** (126s) and **Hey Kids** (105s), both APM. These are
untested picks. Listen to them in game and delete either one if it doesn't fit.
The calm underground playlist (`MUSIC.calm`) is unchanged.

### Everything else

`click`, `deny`, `equip`, `pack_*`, `lucky_*`, `sell`, `found`, `rebirth` and
the dig sounds are unchanged. See the comments beside each slot.

## ElevenLabs prompts

Use these to make replacements that fit the candy look. For sound effects, use
ElevenLabs **Sound Effects**. Set the duration and use a prompt influence of
around 0.5. Generate four or so and keep the best one. For music, use
ElevenLabs **Music**. Before you upload anything, check that your ElevenLabs
plan allows commercial use.

House sound, for every prompt: *bright, bouncy, cartoony, toy-like,
major key, clean, family-friendly, no harsh highs, no alarms or sirens.*

### Wins (most important; these are what players remember)

| slot | duration | prompt |
|---|---|---|
| `win_nice` | 1.5s | Short cheerful cartoon pluck and twinkle, a happy little "ding-ding" with a soft marimba hit, bright and friendly, game reward sound, no reverb tail |
| `win_great` | 2.5s | Playful cartoon reward sting: rising xylophone run into a bright glockenspiel chime and a soft cymbal sparkle, upbeat and bouncy, mobile game "great!" sound |
| `win_epic` | 4s | Big celebratory game win sting: punchy brass fanfare stab, rising sparkle swirl, confetti pop, kid-friendly orchestral cartoon style, joyful and triumphant, major key |
| `win_legend` | 5s | Huge legendary loot reveal: dramatic orchestral and choir swell into a triumphant brass fanfare with timpani hits, shimmering harp glissando and a magical sparkle burst, epic but cheerful, family-friendly video game jackpot moment, no alarm or siren |
| `win_legend_tail` | 4s | Coin shower and sparkle cascade: many bright coins jingling and raining down with magical twinkles, slot machine payout jingle, joyful, no bells ringing like an alarm |
| `suspense` | 1.2s | Fast exciting snare drum roll building up, cartoon game show style, ends right before a reveal, no cymbal crash at the end |

### Reveals and opening

| slot | duration | prompt |
|---|---|---|
| `pack_rise` | 0.8s | Soft magical whoosh rising upward, light sparkle shimmer, cartoon card pack lifting off |
| `pack_tear` | 0.6s | Crisp foil card pack tearing open, satisfying rip, clean and bright |
| `pack_burst` | 0.8s | Bright magical pop burst with sparkles, cards flying out, cheerful |
| `pack_sparkle` | 0.8s | Short glittering twinkle shimmer, tiny bells, magic dust |
| `lucky_rattle` | 0.3s | Wooden toy box rattling and shaking, playful and bouncy |
| `lucky_pop` | 0.8s | Cartoon box pops open with a springy boing and a sparkle |
| `flip` | 0.35s | Quick card flip swoosh, crisp paper snap |

### Interface (heard hundreds of times, so keep them tiny and soft)

| slot | duration | prompt |
|---|---|---|
| `click` | 0.12s | Tiny soft bubbly UI click, rounded and gentle, like a soft plastic toy button |
| `deny` | 0.15s | Soft low wooden "bonk", friendly no, gentle and muted, absolutely not a buzzer |
| `equip` | 0.3s | Satisfying metallic tool equip clink, short and bright |
| `found` | 0.8s | Happy gem discovery chime, bright crystal ding with a sparkle |
| `sell` | 0.7s | Cheerful coin purse jingle, coins dropping into a bag, cash register "cha-ching" but soft |
| `rebirth` | 2.4s | Magical power-up whoosh rising into a bright warm choir chord and sparkle, level up, transformation |

### Music (ElevenLabs Music, 90–150s, loopable, instrumental)

| use | prompt |
|---|---|
| Surface / lobby (`MUSIC.bright`) | Upbeat cheerful instrumental for a kids' mining adventure video game. Bouncy ukulele, marimba, light claps and glockenspiel. 118 bpm, major key, playful and sunny, catchy simple melody, no vocals, loops cleanly. |
| Underground (`MUSIC.calm`) | Calm curious instrumental for exploring a cozy cave in a kids' game. Soft plucked strings, gentle music box and warm pads, 90 bpm, relaxed and focused, slightly magical, no vocals, loops cleanly. |
| Shop / reveal screens | Light sparkly lounge loop for a game shop. Pizzicato strings, vibraphone and soft brushed drums, 105 bpm, happy and inviting, no vocals, loops cleanly. |
| Event Horizon (space event) | Bright cosmic adventure loop for a kids' space event. Sparkly synth arps, warm bass and bouncy drums, 120 bpm, wonder and excitement, no vocals, no dark or scary tones, loops cleanly. |

## How to put a new sound in

1. Generate it, then trim the silence at the start. A late start makes a click feel laggy.
2. Upload it to the **group**: Creator Hub → the Mine For Cards group → Audio.
3. Paste the id into the slot in `MineAudio.luau`, as `"rbxassetid://123..."`.
   For a slot that holds a list (like `win_great`), add it to the list.
   Several takes of one sound keep it from repeating.
4. If it's too loud or too quiet, change the slot's number in the `VOL` table
   in the same file.
