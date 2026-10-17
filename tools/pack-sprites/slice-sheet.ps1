# Cuts a Canva cover sheet (3200x5900: 3 columns x up to 4 rows of 1000x1400
# covers with 100px gaps, one set per row) into art/cover-art/{Set}Coverart{1,2,3}.png.
#
#   powershell -ExecutionPolicy Bypass -Command "& 'tools\pack-sprites\slice-sheet.ps1' -Sheet 'page.png' -OutDir 'art\cover-art' -Sets 'SetA','SetB'"
#
# Pass -Sets as a real list (-Command form above); with -File, PowerShell
# glues 'A,B' into one name.
param(
    [Parameter(Mandatory = $true)][string]$Sheet,
    [Parameter(Mandatory = $true)][string]$OutDir,
    [Parameter(Mandatory = $true)][string[]]$Sets
)

Add-Type -AssemblyName System.Drawing

# Row-major slots: 3 columns x up to 4 rows, 1000x1400 each, 100px gaps.
$lefts = @(0, 1100, 2200)
$tops = @(0, 1500, 3000, 4500)

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$img = [System.Drawing.Bitmap]::FromFile($Sheet)
try {
    for ($r = 0; $r -lt $Sets.Count; $r++) {
        for ($c = 0; $c -lt 3; $c++) {
            $rect = New-Object System.Drawing.Rectangle($lefts[$c], $tops[$r], 1000, 1400)
            $crop = $img.Clone($rect, $img.PixelFormat)
            $name = "{0}Coverart{1}.png" -f $Sets[$r], ($c + 1)
            $crop.Save((Join-Path $OutDir $name), [System.Drawing.Imaging.ImageFormat]::Png)
            $crop.Dispose()
        }
    }
}
finally {
    $img.Dispose()
}
