# Renders the set medallions (19) and rarity gems (8), 512x512 transparent PNGs.
#
#   powershell -ExecutionPolicy Bypass -File tools\pack-sprites\icons.ps1
#
# Set icons:    art/icons/sets/{Set}SetIcon.png   (5-star cover, ring = set grade)
# Rarity icons: art/icons/rarity/Rarity_{Name}.png (colours from MineCards.RARITY_COLOR)
param([int]$Size = 512)

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$art = Join-Path $root "art"
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition (Get-Content -Raw (Join-Path $PSScriptRoot "IconRender.cs"))

# [file prefix, grade] in set order (grades: docs/PETS-AND-SETS.md and the owner's 2026-10-10 swap).
$sets = @(
    @("Pebblebound", "F"), @("SugarRush", "D"), @("Mosswood", "C"), @("LostAndFound", "C"),
    @("Starfront", "C"), @("ArcadeLegends", "B"), @("CrystalHollow", "B"), @("ShogunsOath", "B"),
    @("RoyalReserve", "B"), @("CrimsonEclipse", "A"), @("HoloHavoc", "A"), @("RainbowRoad", "A"),
    @("InfernalReign", "A"), @("AtlantisRising", "A"), @("DivineRelics", "A"), @("Dragonfall", "S"),
    @("EternalRoots", "S"), @("MythicMenagerie", "SS"), @("ChaosTheory", "SSS")
)
$setDir = Join-Path $art "icons\sets"
New-Item -ItemType Directory -Force -Path $setDir | Out-Null
foreach ($s in $sets) {
    $cover = Join-Path $art ("cover-art\{0}Coverart3.png" -f $s[0])
    $out = Join-Path $setDir ("{0}SetIcon.png" -f $s[0])
    [IconRender]::SetMedallion($cover, $out, $s[1], $Size)
    Write-Output ("wrote " + $out)
}

# Same colours as MineCards.RARITY_COLOR.
$rarities = @(
    @("Common", "aaaaaa"), @("Uncommon", "55ff7f"), @("Rare", "55aaff"), @("Epic", "aa55ff"),
    @("Legendary", "ffaa00"), @("Mythic", "55dcff"), @("Divine", "fff5a0"), @("Exotic", "ff3737")
)
$rarDir = Join-Path $art "icons\rarity"
New-Item -ItemType Directory -Force -Path $rarDir | Out-Null
for ($i = 0; $i -lt $rarities.Count; $i++) {
    $out = Join-Path $rarDir ("Rarity_{0}.png" -f $rarities[$i][0])
    [IconRender]::RarityGem($out, $i, [Convert]::ToInt32($rarities[$i][1], 16), $Size)
    Write-Output ("wrote " + $out)
}
