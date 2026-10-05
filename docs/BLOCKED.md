# What "BLOCKED" means, item by item

Owner, 2026-10-04: *"give me more info on what you need for me when you say
BLOCKED — explain each in detail"*.

Fair. "BLOCKED" has been doing too much work. Each entry below says **what it
is**, **why it is yours and not mine**, **the exact sentence that unblocks it**,
and **what I will do if you say "just pick one"** — because for most of these I
have a default and the only thing stopping me is that a number nobody signed off
becomes a number everybody lives with.

Three kinds of blocked, and they are not the same thing:

| kind | what it means | can I proceed? |
|---|---|---|
| **TASTE** | A number or a name. Any value ships; the question is which one you want. | Yes, with a default, if you say so |
| **REACH** | Physically impossible from a cloud container. | No. Ever. |
| **FACT** | I need information only you have. | No |

---

# Copy-paste answers

Owner asked for *"an example/suggested answer"* per item. Here is the whole set
as one block. **Paste it back with the lines you disagree with changed, delete
the rest** — anything you leave untouched I will take as the suggested answer and
build.

```
1.  craft base      yes — TOOL_CRAFT_BASE 250 -> 150, WOOD_PICK_COIN_GROW 1.55 -> 1.40
2.  earthquake      leave EARTHQUAKE_SEC at 5
3.  oreYield key    leave the key, keep the "Blast Chance" label
4.  big suffixes    keep the formatter's (Vg Uvg Dvg), delete the §0.8 line
5.  legacy charms   keep the items, kill the three sources
6.  VIP             leave it at three seats, delete the dead "4th seat" copy
7.  gem prices      scale zone and rune prices with zone index
8.  forge bag       don't build it — the ore strip already answers it
9.  elements        regenerate the skill tree + apply the 5 swaps (docs/SKILL-TREE.md)
10. seam prompt     ANSWERED BY THE CODE: already wired. Just confirm in-game.
11. prestige+VIP+pass -> layer 1 / layer 2 / neither (currently: neither)
```

Line 11 is new and comes out of today's layering work — see below.

---

## TASTE — I have a default, say the word

### 1. `TOOL_CRAFT_BASE` 250 → 150, `WOOD_PICK_COIN_GROW` 1.55 → 1.40

**What:** 250 of one specific ore before your first forged tool, and a starter
pickaxe whose last level costs 5.8× its first.

**Why yours:** This is the first ten minutes of the game. It sets whether a new
player forges something before they get bored. I can measure the curve; I cannot
feel it.

**Unblock:** "yes to both" / "yes to craft, no to the pick" / your own numbers.

**My default if you say pick:** both, as proposed. Shape unchanged, entry price
down 40%.

---

### 2. `EARTHQUAKE_SEC = 5`

**What:** How long a block shakes. At `PROC_SHARE.quake = 0.12` a whole quake is
`0.12 × 5 = 0.60` of one swing.

**Why yours:** You gave me the 20%, the 5-block cap and "cannot stack". You never
gave me a duration — I invented 5 and have flagged it since.

**Unblock:** a number of seconds, **or** a number for what a whole quake should
be worth against one swing (I will solve for the duration).

**My default:** leave it at 5.

---

### 3. `oreYield` is named for ore quantity but means blast chance

**What:** The stat key is `oreYield`; the label is "Blast Chance". Every reader
has to know that.

**Why yours:** Renaming a key is a save migration. Low risk, non-zero.

**Unblock:** "rename it" or "leave it".

**My default:** leave it. A confusing key with a correct label costs a comment;
a bad migration costs saves.

---

### 4. Suffixes past `Nod` (10^63)

**What:** §0.8 says `q r s t …`, §0.9's formatter says `Vg Uvg Dvg`. They agree
below 10^63, and `tools/verify/bignum.js` pins them there.

**Why yours:** Purely cosmetic, purely yours.

**Unblock:** pick one.

**My default:** keep the formatter's, delete the §0.8 line.

---

### 5. The legacy 31 charms

**What:** 31 charms predating the §0.5 charm rules, reachable from a zone grant,
a gem pack and a limited.

**Why yours:** Retiring them removes content players may hold. Keeping them means
two charm systems forever.

**Unblock:** "retire them" / "keep both" / "keep the items, kill the sources".

**My default:** keep the items, kill the sources — nobody loses anything they
own, and nothing new enters the old system.

---

### 6. VIP lost a perk

**What:** VIP used to grant a fourth pet seat. It can't any more.

**Why yours:** It is a paid product. What it is worth is a business call.

**Unblock:** name a replacement perk, or "leave it at three".

**My default:** leave it at three and remove the dead copy, so nobody buys VIP
for a seat that is not there.

---

### 7. Zone and rune gem prices

**What:** Flat price tables that the ore curve will outrun — they get trivially
cheap at depth.

**Why yours:** This is the pacing of the whole mid-game.

**Unblock:** "make them scale with zone" is enough; I will fit the curve.

**My default:** scale with zone index, same shape as `rollPriceFor`.

---

### 8. The Forge BAG

**What:** A second panel inside the Forge for cards / packs / runes / gear. I
built the ore pouch strip; the rest I stopped on.

**Why yours:** I do not know what it is *for*. A bag that shows everything is the
inventory screen with extra steps.

**Unblock:** one sentence on what you want to DO in it.

**My default:** do not build it. The ore strip already answers "what can I
afford", which was the real question.

---

### 8b. Which layer prestige, VIP and the event pass belong to  *(new today)*

**What:** You named the layers as *skills + skins + tools + enchantments* (layer
1) and *equipment + pets* (layer 2). Prestige luck, the VIP luck bonus and the
event-pass bonuses were in neither list.

**Why yours:** Right now they apply outside both layers, exactly as they always
have. Moving them into layer 1 makes them part of the base everything multiplies
— which would make every rebirth worth substantially more than it is today. That
is a rebirth-curve change, not a refactor.

**Unblock:** "layer 1", "layer 2", or "leave them outside".

**Copy-paste answer:** `11. prestige+VIP+pass -> neither (leave outside)`

**My default:** leave them outside. It is what ships today, and it is the only
option that changes nobody's power.

---

## FACT — I need information only you have

### 9. The skill tree — ~~the element roster~~  *(I was wrong about this one)*

**What I said:** "the element list does not exist in this repo in a form I can
read."

**What is true:** it has been here all along as `MineSkillData.ENERGIES` — ten
elements, 36° apart, 75 nodes, each with a verb and a primary/secondary/tertiary
stat. I was looking for the word "element" and the file says "energy".

**What is actually blocked** is bigger than the roster, and it is in
`docs/SKILL-TREE.md`:

- Fire's primary stat was never applied by the server — **fixed**, 9 nodes' worth.
- The ten roads are **not** equal any more: Grass is **2.44×** Water, against a
  file whose stated purpose is that all ten are 1.00×. The tree is generated and
  the generator is not in the repo; the weights it baked against have moved.
- Space's primary is `echo`, a retired stat.
- All five stats I built this week are on no element.

**Unblock:** `docs/SKILL-TREE.md` ends with three yes/no lines.

**My default:** regenerate. A 2.44× spread on a tree built to be even is worse
than the one-time rebalance of fixing it.

---

### 10. Seam purchase — **CLEARED, was never a blocker**

**CORRECTED 2026-10-05: it is wired end to end — see `docs/OPEN.md` P0 item 1.**

**What it used to say:** `Verbs.buySeam` is live and nothing fires it, so every player stops
at layer 500. `MineDepthPlazas` owns the prompt geometry, `MineDepth.seamPrice`
gives the figure.

**Why yours:** Only partly — I can wire the prompt. What I cannot do is place it
in the world, because the plaza geometry lives in the place file, not in `src/`.

**Unblock:** either tell me to wire the prompt to existing plaza geometry and
name the part, or do the placement in Studio and I will wire the rest.

**This one actually blocks launch.** Everything else is polish.

---

## REACH — impossible from here, no matter what you say

### 11. Ore and charm icons
Art lives on your drive (`C:\Users\uybuv\Downloads\oreicons`). I cannot read your
disk. The 164 generated charm icons are superseded — you did not like them. The
`ids.json → MineCharmIcons.luau` wiring is built and waiting for whatever art
arrives. **Commit the PNGs to the repo and I will wire them in the same hour.**

### 12. Asset uploads
No agent in this container can upload to Roblox. §7 governs: group `35326298`,
never the personal account, `mfc_<feature>_<name>_vN` naming.

### 13. Rojo syncback
Must run in Studio, on your machine. `docs/rojo-connect.md` has the steps.

### 14. `ToolBakers.OreToolBaker` syncback
`src/ServerStorage/OreToolBaker.luau` holds an 82-row roster of its own that may
disagree with `MineConfig.ORES`. Nothing requires it, so it breaks nothing — but
I cannot tell which roster is the real one without the Studio-side state.

---

## Now unblocked by you (2026-10-04)

- ~~**Hat/pet/face boost budget**~~ — moot. Gear is being deleted, not nerfed.
- ~~**Gear powers pets**~~ — you said get rid of it.
- ~~**Craft cost**~~ — you gave the rule: ore drop amount, ore rarity,
  progression depth.
- ~~**Enchant rarity**~~ — Exotic 1/1000, Exotic V 1/5000, levels 1–5 uniform,
  price flat across rebirths.
- ~~**Nerf zap/blast, "almost no effect should do full pickaxe damage"**~~ —
  shipped as the proc damage/chance split (`96b34d0`).

## Broken, not blocked — mine to fix, just not urgent

**`OreBalanceSim`** reads five `MineConfig` symbols the `c59bec5` merge removed
(`ORE_BAND_WEIGHT`, `ZONE_ORE_SHIFT`, `ORE_EXOTIC_HOME_ZONE`/`OFF_ZONE`,
`abbrev`). It is the offline ore-balance sim and nothing requires it, so the game
is fine. It matters the day `ORE_GEM_SPREAD` comes off deferral. I will fix it
then, or sooner if you want it.
