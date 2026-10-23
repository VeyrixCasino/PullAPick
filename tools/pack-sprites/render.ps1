# Renders the 3D booster-pack sprites (foil pouch, cover art on the front,
# tier shown by the seals).
#
#   powershell -ExecutionPolicy Bypass -File tools\pack-sprites\render.ps1
#
# The top seal is BLANK by default (owner, 2026-10-19: the set name baked onto
# the crinkled top "comes off"). -Title prints each set's name there again, the
# way the 2026-10-10 sprites were made:
#
#   powershell -ExecutionPolicy Bypass -File tools\pack-sprites\render.ps1 -Title
#
# With no -Jobs it renders every set (57 sprites: 19 sets x 3 covers) via
# jobs.js. The angle defaults are the ones the owner approved on 2026-10-10.
param(
    # Optional JSON array of { cover, out, style, accent, title }.
    # style: plain (1-2 star) | foil (3 star) | silver (4 star) | gold (5 star)
    [string]$Jobs,
    # 5:7 portrait, the shape of every pack slot in the game; 1024 is Roblox's max side.
    [int]$Width = 732,
    [int]$Height = 1024,
    [double]$Yaw = -11,
    [double]$Pitch = -5,
    [double]$Roll = -5,
    # Print the set name on the top seal. Off by default since 2026-10-19.
    [switch]$Title
)

if (-not $Jobs) {
    $Jobs = & node (Join-Path $PSScriptRoot "jobs.js")
    if ($LASTEXITCODE -ne 0) { throw "jobs.js failed" }
}

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition (Get-Content -Raw (Join-Path $PSScriptRoot "PackRender3D.cs"))

foreach ($job in (Get-Content -Raw $Jobs | ConvertFrom-Json)) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $job.out) | Out-Null
    $accent = [Convert]::ToInt32($job.accent.TrimStart('#'), 16)
    # PowerShell names are case-insensitive, so this cannot be called $title:
    # that IS the -Title switch. An empty string leaves the seal blank.
    $sealText = ""
    if ($Title) { $sealText = [string]$job.title }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    [PackRender3D]::Render($job.cover, $job.out, $job.style, $accent, $Width, $Height, $Yaw, $Pitch, $Roll, $sealText)
    Write-Output ("wrote {0} in {1:n1}s" -f $job.out, $sw.Elapsed.TotalSeconds)
}
