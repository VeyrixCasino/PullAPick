# Cuts the two Canva case sheets (3200x5900, transparent, 3 columns x 4 rows of
# 1000x1400 slots with 100px gaps) into art/case-art/{Name}Case.png: each box
# trimmed to its own pixels, then centred on a 732x1024 transparent canvas, the
# same canvas as the pack sprites, so a case and a pack sit the same size in
# the UI.
#
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tools\pack-sprites\slice-cases.ps1" -Sheet "art\case-art\_sheets\CasesA-3200x5900.png" -OutDir "art\case-art" -Names "Pebblebound,SugarRush"
#
# -Names is in slot order, row by row. With -File PowerShell passes "A,B" as
# one string, so the script splits it on commas itself.
param(
    [Parameter(Mandatory = $true)][string]$Sheet,
    [Parameter(Mandatory = $true)][string]$OutDir,
    [Parameter(Mandatory = $true)][string[]]$Names,
    [int]$Width = 732,
    [int]$Height = 1024,
    [double]$Margin = 0.04
)

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class CaseSlicer
{
    // The bounding box of every pixel with alpha above the threshold.
    static Rectangle Opaque(Bitmap bmp, Rectangle area, int threshold)
    {
        BitmapData data = bmp.LockBits(area, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        int stride = data.Stride;
        byte[] px = new byte[stride * area.Height];
        Marshal.Copy(data.Scan0, px, 0, px.Length);
        bmp.UnlockBits(data);
        int minX = area.Width, minY = area.Height, maxX = -1, maxY = -1;
        for (int y = 0; y < area.Height; y++)
        {
            int row = y * stride;
            for (int x = 0; x < area.Width; x++)
            {
                if (px[row + x * 4 + 3] > threshold)
                {
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                }
            }
        }
        if (maxX < 0) return Rectangle.Empty;
        return new Rectangle(area.X + minX, area.Y + minY, maxX - minX + 1, maxY - minY + 1);
    }

    // Works on a copy of the one slot: GDI+ drawing straight out of the whole
    // 3200x5900 sheet threw an access violation partway through a page.
    public static string Cut(Bitmap whole, Rectangle slot, string outPath, int outW, int outH, double margin)
    {
        using (Bitmap sheet = whole.Clone(slot, PixelFormat.Format32bppArgb))
        {
            return CutPart(sheet, outPath, outW, outH, margin);
        }
    }

    static string CutPart(Bitmap sheet, string outPath, int outW, int outH, double margin)
    {
        Rectangle box = Opaque(sheet, new Rectangle(0, 0, sheet.Width, sheet.Height), 8);
        if (box.IsEmpty) return "EMPTY";
        double room = 1.0 - 2.0 * margin;
        double k = Math.Min(outW * room / box.Width, outH * room / box.Height);
        int w = (int)Math.Round(box.Width * k), h = (int)Math.Round(box.Height * k);
        using (Bitmap outBmp = new Bitmap(outW, outH, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(outBmp))
        {
            g.Clear(Color.Transparent);
            g.CompositingMode = CompositingMode.SourceOver;
            g.CompositingQuality = CompositingQuality.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            Rectangle dest = new Rectangle((outW - w) / 2, (outH - h) / 2, w, h);
            using (ImageAttributes attrs = new ImageAttributes())
            {
                attrs.SetWrapMode(WrapMode.TileFlipXY);
                g.DrawImage(sheet, dest, box.X, box.Y, box.Width, box.Height, GraphicsUnit.Pixel, attrs);
            }
            outBmp.Save(outPath, ImageFormat.Png);
        }
        return box.Width + "x" + box.Height + " -> " + w + "x" + h;
    }
}
"@

$Names = @($Names | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
$lefts = @(0, 1100, 2200)
$tops = @(0, 1500, 3000, 4500)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$img = New-Object System.Drawing.Bitmap((Resolve-Path $Sheet).Path)
try {
    for ($i = 0; $i -lt $Names.Count; $i++) {
        $slot = New-Object System.Drawing.Rectangle($lefts[$i % 3], $tops[[math]::Floor($i / 3)], 1000, 1400)
        $out = Join-Path (Resolve-Path $OutDir).Path ("{0}Case.png" -f $Names[$i])
        $info = [CaseSlicer]::Cut($img, $slot, $out, $Width, $Height, $Margin)
        Write-Output ("{0}Case.png  {1}" -f $Names[$i], $info)
    }
}
finally {
    $img.Dispose()
}
