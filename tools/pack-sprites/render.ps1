# Renders the 3D booster-pack sprites (foil pouch, cover art on the front,
# set name on the top seal, tier shown by the seals).
#
#   powershell -ExecutionPolicy Bypass -File tools\pack-sprites\render.ps1
#
# With no -Jobs it renders every set (76 sprites) via jobs.js. The angle
# defaults are the ones the owner approved on 2026-10-10.
param(
    # Optional JSON array of { cover, out, style, accent, title }.
    # style: plain (1-2 star) | foil (3 star) | silver (4 star) | gold (5 star)
    [string]$Jobs,
    # 5:7 portrait, the shape of every pack slot in the game; 1024 is Roblox's max side.
    [int]$Width = 732,
    [int]$Height = 1024,
    [double]$Yaw = -11,
    [double]$Pitch = -5,
    [double]$Roll = -5
)

if (-not $Jobs) {
    $Jobs = & node (Join-Path $PSScriptRoot "jobs.js")
    if ($LASTEXITCODE -ne 0) { throw "jobs.js failed" }
}

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition (Get-Content -Raw (Join-Path $PSScriptRoot "PackRender3D.cs"))

foreach ($job in (Get-Content -Raw $Jobs | ConvertFrom-Json)) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $job.out) | Out-Null
    $accent = [Convert]::ToInt32($job.accent.TrimStart('#'), 16)
    $sw = [Diagnostics.Stopwatch]::StartNew()
    [PackRender3D]::Render($job.cover, $job.out, $job.style, $accent, $Width, $Height, $Yaw, $Pitch, $Roll, [string]$job.title)
    Write-Output ("wrote {0} in {1:n1}s" -f $job.out, $sw.Elapsed.TotalSeconds)
}
