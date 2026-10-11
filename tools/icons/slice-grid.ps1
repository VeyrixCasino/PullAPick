<#
  slice-grid.ps1 - cut a Canva icon sheet (a grid of square cells) into one PNG per ore.

  The sheet is the transparent PNG exported from Canva: 10 columns x 9 rows of
  512 px cells, tier 1 at row 0 col 0, tier 2 at col 1, ... tier 11 at row 1 col 0.
  For every cell that has a tier in prompts.json the script
    1. clones the cell out of the sheet (32bpp ARGB),
    2. trims the fully transparent margins (alpha < -AlphaMin),
    3. centres the tool on a new transparent -Size x -Size canvas with a
       -Margin border (fraction of -Size), scaled to fit,
    4. writes <OutDir>\NN_<id>.png (NN = two-digit tier, id = ore id).
  With -Contact it also writes a dark-grey contact sheet of the results
  (10 x 9 grid of -ContactCell px tiles, tier number in each corner) for a quick look.

  Run from Windows PowerShell (a -Command with & is blocked by antivirus here):
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\icons\slice-grid.ps1 -Sheet "build\hammer-icons\sheets\hammer.png" -Family "hammer" -OutDir "art\tool-icons\hammer" -Contact "build\hammer-icons\contact-hammer.png"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\icons\slice-grid.ps1 -Sheet "build\hammer-icons\sheets\jackhammer.png" -Family "jackhammer" -OutDir "art\tool-icons\jackhammer" -Contact "build\hammer-icons\contact-jackhammer.png"
  -ContactOnly rebuilds the contact sheet from the PNGs already in -OutDir.

  GDI+ note: never LockBits the whole sheet while drawing (it crashes GDI+ on
  these big images). Each cell is cloned first and only the clone is locked.
#>
param(
  [string]$Sheet,
  [Parameter(Mandatory = $true)][string]$Family,
  [Parameter(Mandatory = $true)][string]$OutDir,
  [string]$Prompts = "build\hammer-icons\prompts.json",
  [int]$Cell = 512,
  [int]$Cols = 10,
  [int]$Rows = 9,
  [int]$Size = 512,
  [double]$Margin = 0.04,
  [int]$AlphaMin = 1,
  [string]$Contact = "",
  [int]$ContactCell = 128,
  [switch]$ContactOnly
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

Add-Type -Language CSharp -TypeDefinition @"
public static class IconTrimScan {
  // Returns {left, top, right, bottom} (inclusive) of pixels with alpha >= alphaMin, or null.
  public static int[] Bounds(byte[] px, int stride, int w, int h, int alphaMin) {
    int l = w, t = h, r = -1, b = -1;
    for (int y = 0; y < h; y++) {
      int row = y * stride;
      for (int x = 0; x < w; x++) {
        if (px[row + x * 4 + 3] >= alphaMin) {
          if (x < l) l = x;
          if (x > r) r = x;
          if (y < t) t = y;
          if (y > b) b = y;
        }
      }
    }
    if (r < 0) return null;
    return new int[] { l, t, r, b };
  }
}
"@

function Resolve-Full([string]$p) {
  if ([System.IO.Path]::IsPathRooted($p)) { return $p }
  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $p))
}

$OutDir = Resolve-Full $OutDir
$Prompts = Resolve-Full $Prompts
$ores = (Get-Content -Raw -LiteralPath $Prompts | ConvertFrom-Json).ores | Sort-Object { [int]$_.tier }
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

function Get-Name($ore) { "{0:D2}_{1}.png" -f [int]$ore.tier, $ore.id }

if (-not $ContactOnly) {
  if (-not $Sheet) { throw "-Sheet is required unless -ContactOnly" }
  $Sheet = Resolve-Full $Sheet
  $sheetBmp = New-Object System.Drawing.Bitmap($Sheet)
  Write-Host ("sheet {0}x{1}" -f $sheetBmp.Width, $sheetBmp.Height)
  $box = [int][Math]::Round($Size * (1 - 2 * $Margin))
  $empty = @()
  try {
    foreach ($ore in $ores) {
      $i = [int]$ore.tier - 1
      $col = $i % $Cols
      $row = [Math]::Floor($i / $Cols)
      if ($row -ge $Rows) { throw "tier $($ore.tier) is outside the $Cols x $Rows grid" }
      $rect = New-Object System.Drawing.Rectangle(($col * $Cell), ($row * $Cell), $Cell, $Cell)
      $cellBmp = $sheetBmp.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
      try {
        $lock = New-Object System.Drawing.Rectangle(0, 0, $cellBmp.Width, $cellBmp.Height)
        $data = $cellBmp.LockBits($lock, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
          $bytes = New-Object byte[] ($data.Stride * $data.Height)
          [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
          $stride = $data.Stride
        } finally { $cellBmp.UnlockBits($data) }
        $bb = [IconTrimScan]::Bounds($bytes, $stride, $cellBmp.Width, $cellBmp.Height, $AlphaMin)
        if ($null -eq $bb) { $empty += $ore.tier; Write-Warning "tier $($ore.tier) cell is empty"; continue }
        $tw = $bb[2] - $bb[0] + 1
        $th = $bb[3] - $bb[1] + 1
        $trim = $cellBmp.Clone((New-Object System.Drawing.Rectangle($bb[0], $bb[1], $tw, $th)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
          $scale = [Math]::Min($box / $tw, $box / $th)
          $dw = [Math]::Max(1, [int][Math]::Round($tw * $scale))
          $dh = [Math]::Max(1, [int][Math]::Round($th * $scale))
          $dx = [int][Math]::Floor(($Size - $dw) / 2)
          $dy = [int][Math]::Floor(($Size - $dh) / 2)
          $out = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
          try {
            $g = [System.Drawing.Graphics]::FromImage($out)
            try {
              $g.Clear([System.Drawing.Color]::Transparent)
              $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
              $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
              $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
              $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
              $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
              $attr = New-Object System.Drawing.Imaging.ImageAttributes
              $attr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
              $dest = New-Object System.Drawing.Rectangle($dx, $dy, $dw, $dh)
              $g.DrawImage($trim, $dest, 0, 0, $tw, $th, [System.Drawing.GraphicsUnit]::Pixel, $attr)
              $attr.Dispose()
            } finally { $g.Dispose() }
            $path = Join-Path $OutDir (Get-Name $ore)
            $out.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
            Write-Host ("{0} trim {1}x{2} -> {3}x{4}" -f (Get-Name $ore), $tw, $th, $dw, $dh)
          } finally { $out.Dispose() }
        } finally { $trim.Dispose() }
      } finally { $cellBmp.Dispose() }
    }
  } finally { $sheetBmp.Dispose() }
  if ($empty.Count -gt 0) { Write-Warning ("empty cells: " + ($empty -join ", ")) }
}

if ($Contact) {
  $Contact = Resolve-Full $Contact
  $cw = $Cols * $ContactCell
  $ch = $Rows * $ContactCell
  $sheet2 = New-Object System.Drawing.Bitmap($cw, $ch, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($sheet2)
  try {
    $g.Clear([System.Drawing.Color]::FromArgb(255, 43, 43, 46))
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 220, 220, 220))
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 60, 60, 64))
    foreach ($ore in $ores) {
      $i = [int]$ore.tier - 1
      $x = ($i % $Cols) * $ContactCell
      $y = [Math]::Floor($i / $Cols) * $ContactCell
      $g.DrawRectangle($pen, $x, $y, $ContactCell - 1, $ContactCell - 1)
      $path = Join-Path $OutDir (Get-Name $ore)
      if (Test-Path -LiteralPath $path) {
        $img = New-Object System.Drawing.Bitmap($path)
        try { $g.DrawImage($img, (New-Object System.Drawing.Rectangle($x, $y, $ContactCell, $ContactCell))) } finally { $img.Dispose() }
      }
      $g.DrawString(("{0:D2}" -f [int]$ore.tier), $font, $brush, ($x + 2), ($y + 1))
    }
    $font.Dispose(); $brush.Dispose(); $pen.Dispose()
  } finally { $g.Dispose() }
  $sheet2.Save($Contact, [System.Drawing.Imaging.ImageFormat]::Png)
  $sheet2.Dispose()
  Write-Host "contact sheet -> $Contact"
}
