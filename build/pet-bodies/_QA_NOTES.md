# Unique pet bodies — QA pass

Auditor pass over `node build/unique-pets/concept-clash.js`, a scoped Top-vs-Top
re-run of that same scan, and a static float-risk read of every
`build/pet-bodies/*Top.luau`. Read-only: no body modules were edited (none had
a one-line bug), nothing was committed. "DONE" below = has a staged `*Top.luau`
in `build/pet-bodies/` other than the four sets other agents are finishing
(Crimson Eclipse, Holo Havoc, Infernal Reign, Atlantis Rising).

**Scope note:** `concept-clash.js` scans shipped `src/.../PetBodies/*.luau`
*and* staged `build/pet-bodies/*.luau` together, with no tier filter. That
mixes two different kinds of "repeat":
- Common/Uncommon/Rare bodies are **meant** to share a label across sets (every
  set reuses the fantasy-creature vocabulary — "Mole", "Owl", "Beetle"...).
  Only an identical *concept* (not just name) across sets is worth flagging.
- Epic-and-up ("Top") bodies must be unique **by id** (enforced by
  `set-pets.js`'s `topOwner` check) but nothing enforces unique **labels** —
  that's exactly what this human pass is for.

I re-ran the scan scoped to only `*Top.luau` files and diffed exact labels: **0
exact full-label duplicates** across all 15 staged Top files. The "95 shared
nouns" in the raw script output are almost all set-specific adjective + shared
noun pairs (e.g. "Golddust Ant" vs "Tunnel Ant") — expected and fine. The four
items below are the real finds: cases where the *shape/gimmick*, not just a
noun, repeats.

## 1. Creature-repeat fix list

| # | Clash | Where | Keep | Rename / fix |
|---|---|---|---|---|
| 1 | **Geode** (identical gimmick: rock cracked open on top, crystal cluster bursting out) | `tools/gen/sets/pebblebound.json` body `pb_geode` **and** `tools/gen/sets/crystal_hollow.json` body `ch_geode` — both core bodies. | **Crystal Hollow** keeps "Geode". | **DONE:** Pebblebound `pb_geode` label → **"Split Boulder"** (id unchanged). Geometry simplified to plain cracked rock (slate chunks in the split, no glass crystal cluster). `EternalRootsTop` "Cavern Geode" left alone. |
| 2 | **Cuckoo clock** (identical build: wood case, gabled roof, round dial face, hanging pine-cone/weight pair on chains, pendulum below) | was `MosswoodTop.luau` `mw_t_cuckoo` = "Cuckoo Clock" vs `LostAndFoundTop.luau` `lf_t_cuckoo` = "Cuckoo Chalet" | **Lost & Found** keeps `lf_t_cuckoo` ("Cuckoo Chalet"). | **DONE:** Mosswood reworked to `mw_t_birdhouse` = "Mossy Birdhouse" (Legendary) — round entrance hole, tiny bird peeking out, moss/twigs/post; no dial, pendulum, or hanging weights. |
| 3 | **Spoonbill-with-a-literal-spoon-bill** | `RoyalReserveTop.luau` `rr_t_spoonbill` = "Silver Spoonbill" (DONE) vs Holo Havoc Top bird | **Royal Reserve** keeps "Silver Spoonbill". | **DONE:** Holo Havoc already fixed as **"Mirrorball Ibis"** (`hh_t_spoonbill` / `HoloHavocTop.luau`) — no spoon-bill pun. |
| 4 | **Jellyfish** (identical gimmick: glassy/see-through bell, glowing core, frilled rim, trailing tentacles) — shipped live | `atlantis_rising` `at_jellyfish` **and** `holo_havoc` `hh_jelly` — both core bodies. | **Atlantis Rising** keeps "Jellyfish". | **DONE:** Holo Havoc `hh_jelly` label → **"Prism Jelly"** (id unchanged). Bonus: Pebblebound Top `pb_t_jelly` label → **"Opal Medusa"** (was "Opal Jellyfish"; id unchanged) so it doesn't echo the jellyfish noun either. |

No other must-fix items found. I did **not** find a case of two DONE Top-tier
bodies sharing an identical full label (0 exact matches across all 15 staged
Top files) — the 63 shared-last-noun pairs from the raw scan (owl, moth,
phoenix, whale, lantern, drake...) are each a different adjective + the same
common fantasy-creature word, which matches this game's existing naming
pattern everywhere else and isn't a repeat of concept, just vocabulary. Spot
read a dozen of them (lantern x4, phoenix x5, owl x4, moth x4) — each is a
visually distinct take (wyrm-shaped vs root-shaped vs tunnel-shaped vs
prism-shaped lantern, etc.); no action needed.

## 2. Static float-risk audit (`build/pet-bodies/*Top.luau`)

Method: regex-scanned every file for (a) `CFrame.new(x,y,z)` / `CF(x,y,z)`
**position** literals (not size args — a long rod or wide panel's `Vector3`
*size* is normal and was excluded) with `|x|`, `|y|`, or `|z| > 2.2`, and (b)
`c:rod(from, to, ...)` calls where *both* endpoints sit farther than ~1.7 studs
from origin (a rod with no end near the body envelope would read as a floating
line). There is no `c:star`/sparkle-specific primitive in the kit (`c:sparkle`
exists and takes a count/radius, not a position far from the body, so it can't
float on its own) — "sparkles far from the envelope" risk in practice means a
light/glow part on a long unsupported rod, which the rod check covers.

**Result: no confirmed float-risk bugs.** 9 stray-position hits and 8
far-rod-endpoint hits came back, and all 17 checked out fine on manual read
(see samples below) — Roblox part geometry is always built as a short chain
from a known anchor in this codebase, so a truly disconnected floating part is
rare by construction. Treat the two scripts below as reusable spot-check tools
if a future body looks wrong in Studio; they were temporary and have been
deleted, not left in `build/unique-pets/`.

**Sampled (10 bodies), all tethered correctly:**

| Body | What looked risky | Why it's fine |
|---|---|---|
| ArcadeLegends `al_t_swordstone` | glow ball at y=2.22 | tip of a hilt built up in steps from y=1.20 → 1.72 → 1.97 → 2.22; fully connected |
| LostAndFound `lf_t_lighthouse` | gold ball at y=2.32 | lighthouse roof finial sitting right on a cone roof (apex ~2.26–2.3) |
| Starfront `sf_t_relay` ("Relay Tower") | glow ball at y=2.40 | tip of the mast; cone + rods climb from the body to y≈2.15 right below it |
| Starfront `sf_t_crawler` ("Crawler Platform") | red NEON ball at (−0.56, 2.3, −0.5) | sits on a 1.7-tall antenna box spanning y≈0.52–2.22, right under it |
| Dragonfall `df_t_ant` ("Golddust Ant") | leg/antenna rod chain, far endpoints | each rod's near end is at the body surface; it's a 2-segment antenna/leg, not a floater |
| Dragonfall `df_t_skullkeep` ("Dragonskull Keep") | flagpole rod y=1.88→2.14 | sits on a tower cone (apex ~1.94) directly below it |
| EternalRoots `er_t_lantern` ("Rootlamp Lantern") | wide rod spanning x=±1.30 at y≈1.7 | it's the lantern's carrying handle/bail, touching the lantern's own top (cyl top at y=1.70) |
| EternalRoots `er_t_sloth` ("Rootswing Sloth") | wide rod spanning x=±1.40 at y=1.30 | explicitly "a root across the cavern roof" per its own comment; the sloth's arm-rods reach up to y=1.16 right under it |
| EternalRoots `er_t_planet` ("Seedling Planet") | dangling-root rods | small roots off the underside of the planet sphere (body bottom ≈ −0.8); connected, just a false flag from my magnitude check misreading `r[1]`/`r[2]` array-index brackets as literal numbers |
| HoloHavoc `hh_t_giraffe` ("Balloon Giraffe") | horn-nub rod near y=2.00 | sits on top of the long balloon neck, which already reaches y≈1.56–1.82 |
| Mosswood `mw_t_beetle` ("Lichen Beetle") | 2-segment horn rod | both segments chain from the body front (z≈1.28, near the body) up and out; connected |

No action needed on any of these. If a body ever *does* look wrong in-game,
the fast repro is: regex for `CFrame.new(` / `CF(` triples with any axis over
~2.2, then manually confirm the nearest other part in that `build` function is
within ~0.5 studs of one of its endpoints.

## 3. Studio status: **BLOCKED**

Roblox Studio *is* connected (`⛏️ MINE FOR CARDS! 🃏 SEASON ONE`, one
instance), and the repo has a documented bake path:
`src/ServerStorage/PetShowcaseBuilder.luau` and raw
`PetModelFactory.build({ species = <id>, rarity = <tier>, name = <name> })`
from Studio's command bar (see `wiki/systems/pets.md` §"The display").

But that path only resolves species that `PetModelFactory` has loaded from
`src/ReplicatedStorage/Mine/Shared/PetBodies/*.luau` — the **Rojo-synced**
tree. `build/pet-bodies/` is **not** in `default.project.json` at all, so
Studio has no Instance for `RoyalReserveTop.luau` and can't see `rr_t_atomizer`,
`rr_t_staircase`, or `rr_t_mantle` to begin with. Checked whether those ids are
at least pre-registered for a future sync: they are not — none of
`tools/gen/sets/*.json`'s `topBodies` lists reference any `*_t_*` id yet
(checked `royal_reserve.json`, `holo_havoc.json`, `mosswood.json`,
`lost_and_found.json`), so this is a repo-wide pipeline stage every staged Top
file is still waiting on, not a Royal-Reserve-specific gap.

Baking a sample would require copying `RoyalReserveTop.luau` into
`src/ReplicatedStorage/Mine/Shared/PetBodies/RoyalReserve.luau` and adding
`topBodies` entries (tier, tint) to `tools/gen/sets/royal_reserve.json`, i.e.
landing someone else's in-progress art into the live tree and editing an
owner-authored config — both explicitly out of scope here ("do NOT author new
set bodies", "do NOT edit body modules unless a one-line bug"), and risky to
do while other agents are concurrently touching adjacent sets. **Skipping, as
instructed.** Unblocks once a set's Top file is merged into
`src/.../PetBodies/` and wired into its `tools/gen/sets/<key>.json`
`topBodies` list — at that point `PMF.build({ species = "rr_t_atomizer", rarity
= "Legendary", name = "<any>" })` from Studio's command bar should work
directly, or a rebuilt `PetShowcase` will show it in-place.
