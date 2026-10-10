// The 19 sets, one row each, shared by every pack-art tool so the renderer, the
// ids file and the game module agree on names and colours.
//
//   key     MineSetPacks / MineSetPets set key (load-bearing: save data)
//   file    PascalCase prefix of the art files (art/cover-art, art/pack-sprites,
//           art/icons/sets) and of build/pack-art/ids.json
//   name    display name, as in the owner's table (docs/PETS-AND-SETS.md)
//   grade   F..SSS, same table
//   accent  seal colour on the pack sprite, and the pack's accent in the UI
//   title   printed on the sprite's top seal
module.exports = [
  { key: "pebblebound", name: "Pebblebound", grade: "F", file: "Pebblebound", accent: "#9a6b3f", title: "PEBBLEBOUND" },
  { key: "sugar_rush", name: "Sugar Rush", grade: "D", file: "SugarRush", accent: "#ff6fae", title: "SUGAR RUSH" },
  { key: "mosswood", name: "Mosswood", grade: "C", file: "Mosswood", accent: "#4e9a3c", title: "MOSSWOOD" },
  { key: "lost_and_found", name: "Lost & Found", grade: "C", file: "LostAndFound", accent: "#b9832f", title: "LOST & FOUND" },
  { key: "starfront", name: "Starfront", grade: "C", file: "Starfront", accent: "#3f78e0", title: "STARFRONT" },
  { key: "arcade_legends", name: "Arcade Legends", grade: "B", file: "ArcadeLegends", accent: "#c23cff", title: "ARCADE LEGENDS" },
  { key: "crystal_hollow", name: "Crystal Hollow", grade: "B", file: "CrystalHollow", accent: "#8a5cff", title: "CRYSTAL HOLLOW" },
  { key: "shoguns_oath", name: "Shogun's Oath", grade: "B", file: "ShogunsOath", accent: "#d6334a", title: "SHOGUN'S OATH" },
  { key: "royal_reserve", name: "Royal Reserve", grade: "B", file: "RoyalReserve", accent: "#1f7a52", title: "ROYAL RESERVE" },
  { key: "crimson_eclipse", name: "Crimson Eclipse", grade: "A", file: "CrimsonEclipse", accent: "#b0142e", title: "CRIMSON ECLIPSE" },
  { key: "holo_havoc", name: "Holo Havoc", grade: "A", file: "HoloHavoc", accent: "#8fb3ff", title: "HOLO HAVOC" },
  { key: "rainbow_road", name: "Rainbow Road", grade: "A", file: "RainbowRoad", accent: "#ff7ed4", title: "RAINBOW ROAD" },
  { key: "infernal_reign", name: "Infernal Reign", grade: "A", file: "InfernalReign", accent: "#e8501c", title: "INFERNAL REIGN" },
  { key: "atlantis_rising", name: "Atlantis Rising", grade: "A", file: "AtlantisRising", accent: "#12b5b0", title: "ATLANTIS RISING" },
  { key: "divine_relics", name: "Divine Relics", grade: "A", file: "DivineRelics", accent: "#7a62e0", title: "DIVINE RELICS" },
  { key: "dragonfall", name: "Dragonfall", grade: "S", file: "Dragonfall", accent: "#d0631c", title: "DRAGONFALL" },
  { key: "eternal_roots", name: "Eternal Roots", grade: "S", file: "EternalRoots", accent: "#1fa07c", title: "ETERNAL ROOTS" },
  { key: "mythic_menagerie", name: "Mythic Menagerie", grade: "SS", file: "MythicMenagerie", accent: "#6a46d6", title: "MYTHIC MENAGERIE" },
  { key: "chaos_theory", name: "Chaos Theory", grade: "SSS", file: "ChaosTheory", accent: "#19c8ff", title: "CHAOS THEORY" },
];
