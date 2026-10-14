# Kid-friendly review — Epic+ unique-body pet names

Date: 2026-10-13  
Branch: `claude/vigilant-fermi-aucqjy`  
Scope: species labels in `*Top.luau` / `*Extra.luau` plus generated “looks like” strings in `docs/SET-PETS.md` for **CE, HH, IR, AT, MM, CT, RR, MW, PB** (and RR/MW/PB Extras).  
Bar: Roblox kids game — no gore, sexual innuendo, scary-extreme, drugs, weapons-as-violence celebration, hate. Mild gothic/fantasy OK when set-themed (blood moon, crimson, infernal). Flag only clear problems.

## Verdict

**none flagged** — no clear-bad renames recommended; no PetBodies / JSON label edits made.

Automated scan found no sexual slang, gore celebration, drugs, hate, or weapons-as-violence wording in Epic+ labels or generated looks-like strings for the target sets. “murder-holes” appears only in **comments** inside `InfernalReignTop.luau` (castle architecture term), not as a player-facing label.

## 1. Flagged names

none flagged

## 2. Borderline-but-OK (checked and left)

| set | species id | label / example generated | why left |
|---|---|---|---|
| CE | `ce_t_diadem` | Bloodmoon Diadem → e.g. Haloed Bloodmoon Diadem | Set theme (Crimson Eclipse); mild gothic |
| CE | `ce_t_coronet` | Sanguine Coronet → Lunar/Sanguine combos | “Sanguine” = crimson/blood-tone luxury; set-themed |
| CE | `ce_t_kinkajou` | Velvet Kinkajou | Real rainforest mammal (not “kink”); cute Epic body |
| CE | `ce_t_basilisk` | Velvet Basilisk | Mythic serpent; cartoon pet, no gore |
| CE | `ce_t_thurible` / `ce_t_monstrance` | Swinging Thurible, Haloed Monstrance | Liturgical objects; non-violent |
| HH | `hh_t_laser` | Laser Narwhal | Disco/optics joke, not weapon celebration |
| HH | `hh_t_hatchetfish` | Silver Hatchetfish | Real fish species name |
| HH | `hh_t_caustic` | Caustic Pool → Brilliant Caustic Pool | Optics “caustic” (light patterns), not chemical burn |
| HH | `hh_t_mercury` | Mercury Slug | Shiny-metal gag; not drug/poison celebration |
| IR | `ir_t_hellbound` | Hellbound Chariot → Radiant Hellbound Chariot | Matches Infernal Reign / Hellbound pack line; mild fantasy |
| IR | `ir_t_brimstone` etc. | Brimstone Geyser, Infernal Citadel, Slagclaw Wolverine | Set forge/volcano fantasy; no gore verbs |
| AT | `at_t_ossuary` | Deep Ossuary → Coral Deep Ossuary | Bone-repository word is obscure; ruin fantasy, not gore art |
| AT | `at_t_siren` | Coral Siren → Pearled Coral Siren | Mythology merfolk; not sexual |
| AT | `at_t_lamprey` | Abyss Lamprey → Coral Abyss Lamprey | Real deep-sea animal; “ew” biology, not violence |
| AT | tint “Siren Violet” | Siren Violet *base bodies* (Commons) | Color name; fine |
| AT | trident / panoply / Poseidon | Reef Trident, Orichalcum Panoply, Tide Poseidon | Myth props/armor, not “celebrate shooting” |
| MM | `mm_t_manticore` / `mm_t_minotaur` | Spiketail Manticore, Labyrinth Minotaur | Standard kid fantasy bestiary |
| MM | `mm_t_baku` | Dreamfeast Baku | Eats nightmares (helpful myth); not predation gore |
| MM | `mm_t_titanroost` | Titanbone Titanroost → Titan Titanbone Titanroost | “Bone” as titan skeleton roost; mild; awkward double “Titan” is naming quality, not safety |
| CT | void / tear / singularity | Void Portal, Reality Tear, Singularity Pit | Sci-fi glitch theme; not scary-extreme |
| RR | `rr_t_paradise` | Paradise Dancer → Jewelled Paradise Dancer | Comment: bird of paradise mid-dance; not exotic-dancer innuendo |
| RR | `rr_t_gavel` | Auction Gavel | Auction tool, not court violence |
| RR Extra | `rr_e_lipstick` | Lipstick (Common–Rare) | Toy makeup; out of Epic+ but checked — OK |
| PB | `pb_t_canary` | Cage Canary | Mining canary trope; slightly sad cage image, still mild |
| PB | `pb_t_medusa` | Opal Medusa | Myth head; crystal pet, no snakes-as-gore |
| MW | — | Mosswood Epic+ forest critters / Sasquatch / dragon | Clean; no flags |
| RR | — | Rainbow Road Epic+ spectrum animals | Clean; no flags |

## 3. Renames / files changed

None. No `PetBodies` or `tools/gen/sets/*.json` label edits.  
`node tools/gen/set-pets.js --check` not required (no label changes).

### Optional soft renames (not applied — owner taste only)

If a later pass wants softer wording without changing set identity:

| current | softer option | note |
|---|---|---|
| Hellbound Chariot | Emberbound Chariot / Cinder Chariot | Only if “Hell*” ever trips a filter |
| Deep Ossuary | Deep Reliquary / Coral Catacomb | If bone-vault word feels too death-adjacent |
| Caustic Pool | Light Caustic / Caustic Lens | If parents misread as chemical |

### Out of scope note (packs, not pet bodies)

Infernal Reign **pack** titles in `SET-PETS.md` include Hellbound · Demonforge · Ninth Circle. Not unique-body labels; separate pack-name pass if desired.

### Quality nit (not kid-safety)

Crimson Eclipse generated string **Velvet Velvet Basilisk** (tint “Velvet” + body “Velvet Basilisk”) — duplicate word; generator/tint issue, not a safety flag.

## Coverage checklist

| module | Epic+ labels reviewed |
|---|---|
| CrimsonEclipseTop | yes (48) |
| HoloHavocTop + Extra | yes |
| InfernalReignTop | yes |
| AtlantisRisingTop | yes |
| MythicMenagerieTop | yes |
| ChaosTheoryTop | yes |
| RainbowRoadTop + Extra | yes |
| MosswoodTop + Extra | yes |
| PebbleboundTop + Extra | yes |
| RoyalReserveTop + Extra | yes |
| SET-PETS.md Epic+ looks-like for those sets | yes |
