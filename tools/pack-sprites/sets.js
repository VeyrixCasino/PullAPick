// The 19 sets, one row each, shared by every pack-art tool so the renderer, the
// ids file and the game module agree on names and colours.
//
//   key     MineSetPacks / MineSetPets set key (load-bearing: save data)
//   file    PascalCase prefix of the art files (art/cover-art, art/pack-sprites,
//           art/icons/sets) and of build/pack-art/ids.json
//   accent  seal colour on the pack sprite, and the pack's accent in the UI
//   title   printed on the sprite's top seal
module.exports = [
  { key: "pebblebound", file: "Pebblebound", accent: "#9a6b3f", title: "PEBBLEBOUND" },
  { key: "sugar_rush", file: "SugarRush", accent: "#ff6fae", title: "SUGAR RUSH" },
  { key: "mosswood", file: "Mosswood", accent: "#4e9a3c", title: "MOSSWOOD" },
  { key: "lost_and_found", file: "LostAndFound", accent: "#b9832f", title: "LOST & FOUND" },
  { key: "starfront", file: "Starfront", accent: "#3f78e0", title: "STARFRONT" },
  { key: "arcade_legends", file: "ArcadeLegends", accent: "#c23cff", title: "ARCADE LEGENDS" },
  { key: "crystal_hollow", file: "CrystalHollow", accent: "#8a5cff", title: "CRYSTAL HOLLOW" },
  { key: "shoguns_oath", file: "ShogunsOath", accent: "#d6334a", title: "SHOGUN'S OATH" },
  { key: "royal_reserve", file: "RoyalReserve", accent: "#1f7a52", title: "ROYAL RESERVE" },
  { key: "crimson_eclipse", file: "CrimsonEclipse", accent: "#b0142e", title: "CRIMSON ECLIPSE" },
  { key: "holo_havoc", file: "HoloHavoc", accent: "#8fb3ff", title: "HOLO HAVOC" },
  { key: "rainbow_road", file: "RainbowRoad", accent: "#ff7ed4", title: "RAINBOW ROAD" },
  { key: "infernal_reign", file: "InfernalReign", accent: "#e8501c", title: "INFERNAL REIGN" },
  { key: "atlantis_rising", file: "AtlantisRising", accent: "#12b5b0", title: "ATLANTIS RISING" },
  { key: "divine_relics", file: "DivineRelics", accent: "#7a62e0", title: "DIVINE RELICS" },
  { key: "dragonfall", file: "Dragonfall", accent: "#d0631c", title: "DRAGONFALL" },
  { key: "eternal_roots", file: "EternalRoots", accent: "#1fa07c", title: "ETERNAL ROOTS" },
  { key: "mythic_menagerie", file: "MythicMenagerie", accent: "#6a46d6", title: "MYTHIC MENAGERIE" },
  { key: "chaos_theory", file: "ChaosTheory", accent: "#19c8ff", title: "CHAOS THEORY" },
];
