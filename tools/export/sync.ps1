# Pulls the current Studio state into src/.
# 1. Run receiver.ps1 in another terminal (listens on http://localhost:34999).
# 2. Run export.luau in Studio (command bar or Studio MCP execute_luau, Edit datamodel).
# 3. Stop the receiver, then run this script.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$in = Join-Path $PSScriptRoot 'in'

foreach ($n in 'ReplicatedFirst', 'ReplicatedStorage', 'ServerScriptService', 'ServerStorage', 'StarterPlayerScripts') {
  $parts = Get-ChildItem $in -Filter "$n.rbxm.part*" | Sort-Object Name
  if (-not $parts) { throw "No export parts found for $n" }
  $fs = [IO.File]::Create("$in\$n.rbxm")
  foreach ($p in $parts) { $b = [IO.File]::ReadAllBytes($p.FullName); $fs.Write($b, 0, $b.Length) }
  $fs.Close()
  $parts | Remove-Item
}

rojo build combine.project.json -o "$in\combined.rbxm"
rojo syncback sync.project.json --input "$in\combined.rbxm" --non-interactive

# ToolModels_50 is ~80 MB and stays Studio-only.
Remove-Item ..\..\src\ReplicatedStorage\ToolModels_50.rbxm* -ErrorAction SilentlyContinue
Remove-Item $in -Recurse -Force
