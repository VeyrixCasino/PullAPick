using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

// Set medallions and rarity gems, rendered per pixel with the same lighting as
// the pack sprites (PackRender3D.cs). 2x supersampled, transparent PNG out.
// C# 5 only (Windows PowerShell 5.1).
public static class IconRender
{
    static int N;
    static float[] cR, cG, cB, cA;   // colour layer
    static float[] solid;            // what casts the drop shadow

    // Light from the upper left (y up), viewer straight on.
    const double LX = -0.45, LY = 0.62, LZ = 0.64;

    static double Clamp01(double v) { return v < 0 ? 0 : (v > 1 ? 1 : v); }

    static void Norm(ref double x, ref double y, ref double z)
    {
        double l = Math.Sqrt(x * x + y * y + z * z);
        if (l > 0) { x /= l; y /= l; z /= l; }
    }

    static void Begin(int size)
    {
        N = size * 2;
        int nn = N * N;
        cR = new float[nn]; cG = new float[nn]; cB = new float[nn]; cA = new float[nn]; solid = new float[nn];
    }

    // "Over" composite of one pixel, straight alpha.
    static void Put(int i, double r, double g, double b, double a, bool casts)
    {
        a = Clamp01(a);
        if (a <= 0) return;
        double da = cA[i], oa = a + da * (1 - a);
        cR[i] = (float)((r * a + cR[i] * da * (1 - a)) / oa);
        cG[i] = (float)((g * a + cG[i] * da * (1 - a)) / oa);
        cB[i] = (float)((b * a + cB[i] * da * (1 - a)) / oa);
        cA[i] = (float)oa;
        if (casts) solid[i] = (float)Math.Max(solid[i], a);
    }

    static void Hsv(double h, double s, double v, out double r, out double g, out double b)
    {
        h = (h % 1.0 + 1.0) % 1.0 * 6.0;
        int i = (int)Math.Floor(h);
        double f = h - i, p = v * (1 - s), q = v * (1 - s * f), t = v * (1 - s * (1 - f));
        switch (i % 6)
        {
            case 0: r = v; g = t; b = p; break;
            case 1: r = q; g = v; b = p; break;
            case 2: r = p; g = v; b = t; break;
            case 3: r = p; g = q; b = v; break;
            case 4: r = t; g = p; b = v; break;
            default: r = v; g = p; b = q; break;
        }
    }

    // Lit metal: diffuse + tinted specular + soft environment banding.
    static void Metal(double br, double bg, double bb, double nx, double ny, double nz, double phase,
        out double r, out double g, out double b)
    {
        double lx = LX, ly = LY, lz = LZ; Norm(ref lx, ref ly, ref lz);
        double ndl = Math.Max(0, nx * lx + ny * ly + nz * lz);
        double hx = lx, hy = ly, hz = lz + 1; Norm(ref hx, ref hy, ref hz);
        double ndh = Math.Max(0, nx * hx + ny * hy + nz * hz);
        double band = 0.78 + 0.3 * Math.Sin(ny * 3.2 + nx * 2.1 + phase);
        double diff = (0.32 + 0.75 * ndl) * band;
        double spec = 0.85 * Math.Pow(ndh, 28) + 0.15 * Math.Pow(ndh, 6);
        r = Clamp01(br * diff + (0.6 + 0.4 * br) * spec);
        g = Clamp01(bg * diff + (0.6 + 0.4 * bg) * spec);
        b = Clamp01(bb * diff + (0.6 + 0.4 * bb) * spec);
    }

    static float[] TextMask(string text, double cx, double cy, double maxW, double maxH)
    {
        float[] m = new float[N * N];
        using (Bitmap bm = new Bitmap(N, N, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(bm))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.Clear(Color.Black);
                FontFamily ff;
                try { ff = new FontFamily("Arial Black"); } catch (ArgumentException) { ff = FontFamily.GenericSansSerif; }
                using (GraphicsPath p = new GraphicsPath())
                {
                    p.AddString(text, ff, (int)FontStyle.Regular, 100f, new PointF(0, 0), StringFormat.GenericTypographic);
                    RectangleF bnd = p.GetBounds();
                    float sc = (float)Math.Min(maxW / bnd.Width, maxH / bnd.Height);
                    using (Matrix mx = new Matrix())
                    {
                        mx.Translate((float)cx, (float)cy);
                        mx.Scale(sc, sc);
                        mx.Translate(-(bnd.X + bnd.Width / 2), -(bnd.Y + bnd.Height / 2));
                        p.Transform(mx);
                    }
                    using (SolidBrush br = new SolidBrush(Color.White)) { g.FillPath(br, p); }
                }
            }
            int[] raw = new int[N * N];
            BitmapData d = bm.LockBits(new Rectangle(0, 0, N, N), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(d.Scan0, raw, 0, raw.Length);
            bm.UnlockBits(d);
            for (int i = 0; i < raw.Length; i++) m[i] = ((raw[i] >> 16) & 255) / 255f;
        }
        return m;
    }

    static void BoxBlur(float[] src, int radius)
    {
        float[] tmp = new float[src.Length];
        for (int pass = 0; pass < 3; pass++)
        {
            for (int y = 0; y < N; y++)
            {
                double sum = 0; int row = y * N;
                for (int x = -radius; x <= radius; x++) sum += src[row + Math.Min(N - 1, Math.Max(0, x))];
                for (int x = 0; x < N; x++)
                {
                    tmp[row + x] = (float)(sum / (2 * radius + 1));
                    sum += src[row + Math.Min(N - 1, x + radius + 1)] - src[row + Math.Max(0, x - radius)];
                }
            }
            for (int x = 0; x < N; x++)
            {
                double sum = 0;
                for (int y = -radius; y <= radius; y++) sum += tmp[Math.Min(N - 1, Math.Max(0, y)) * N + x];
                for (int y = 0; y < N; y++)
                {
                    src[y * N + x] = (float)(sum / (2 * radius + 1));
                    sum += tmp[Math.Min(N - 1, y + radius + 1) * N + x] - tmp[Math.Max(0, y - radius) * N + x];
                }
            }
        }
    }

    // Composite everything over a soft drop shadow, downscale, save.
    static void Finish(string outPath, int size, double shadowStrength)
    {
        float[] sh = new float[N * N];
        int ox = N / 90, oy = N / 60;
        for (int y = 0; y < N; y++)
            for (int x = 0; x < N; x++)
            {
                int sx = x - ox, sy = y - oy;
                if (sx >= 0 && sy >= 0 && sx < N && sy < N) sh[y * N + x] = solid[sy * N + sx];
            }
        BoxBlur(sh, Math.Max(2, N / 80));
        byte[] px = new byte[N * N * 4];
        for (int i = 0; i < N * N; i++)
        {
            double a = cA[i], sa = shadowStrength * sh[i];
            double oa = a + sa * (1 - a);
            double r = 0, g = 0, b = 0;
            if (oa > 0) { r = cR[i] * a / oa; g = cG[i] * a / oa; b = cB[i] * a / oa; }
            px[i * 4] = (byte)Math.Round(Clamp01(b) * 255);
            px[i * 4 + 1] = (byte)Math.Round(Clamp01(g) * 255);
            px[i * 4 + 2] = (byte)Math.Round(Clamp01(r) * 255);
            px[i * 4 + 3] = (byte)Math.Round(Clamp01(oa) * 255);
        }
        using (Bitmap big = new Bitmap(N, N, PixelFormat.Format32bppArgb))
        {
            BitmapData bd = big.LockBits(new Rectangle(0, 0, N, N), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(px, 0, bd.Scan0, px.Length);
            big.UnlockBits(bd);
            using (Bitmap outBmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
            {
                using (Graphics g = Graphics.FromImage(outBmp))
                {
                    g.Clear(Color.Transparent);
                    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                    g.CompositingQuality = CompositingQuality.HighQuality;
                    g.DrawImage(big, 0, 0, size, size);
                }
                outBmp.Save(outPath, ImageFormat.Png);
            }
        }
    }

    // ------------------------------------------------------------------
    // Set medallion: 5-star cover under a glass dome, in a grade-coloured ring.
    // ------------------------------------------------------------------

    static void GradeMetal(string grade, double theta, double t, out double r, out double g, out double b)
    {
        switch (grade)
        {
            case "F": r = 0.52; g = 0.55; b = 0.59; break;   // iron
            case "D": r = 0.60; g = 0.47; b = 0.30; break;   // bronze
            case "C": r = 0.48; g = 0.62; b = 0.80; break;   // steel blue
            case "B": r = 0.64; g = 0.48; b = 0.86; break;   // amethyst
            case "A": r = 0.88; g = 0.52; b = 0.27; break;   // copper
            case "S": r = 0.94; g = 0.74; b = 0.26; break;   // gold
            case "SS": r = 0.98; g = 0.84; b = 0.38; break;  // bright gold
            default:                                          // SSS: iridescent
                Hsv(theta / (2 * Math.PI) + t * 0.25, 0.55, 1.0, out r, out g, out b); break;
        }
    }

    public static void SetMedallion(string coverPath, string outPath, string grade, int size)
    {
        Begin(size);
        int[] cov; int cw, ch;
        using (Bitmap src = new Bitmap(coverPath))
        using (Bitmap bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(bmp)) { g.DrawImage(src, 0, 0, src.Width, src.Height); }
            cw = bmp.Width; ch = bmp.Height; cov = new int[cw * ch];
            BitmapData d = bmp.LockBits(new Rectangle(0, 0, cw, ch), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(d.Scan0, cov, 0, cov.Length);
            bmp.UnlockBits(d);
        }

        double cx = N * 0.5, cy = N * 0.46;
        double rArt = N * 0.33, rRing = N * 0.41;
        bool prestige = grade == "S" || grade == "SS" || grade == "SSS";
        int studs = grade == "SS" ? 4 : (grade == "SSS" ? 8 : 0);

        // Glow behind the top grades.
        if (prestige)
        {
            for (int y = 0; y < N; y++)
                for (int x = 0; x < N; x++)
                {
                    double dx = x + 0.5 - cx, dy = y + 0.5 - cy, rr = Math.Sqrt(dx * dx + dy * dy);
                    if (rr < rRing) continue;
                    double th = Math.Atan2(-dy, dx);
                    double gr, gg, gb;
                    GradeMetal(grade, th, 0.5, out gr, out gg, out gb);
                    double fall = Math.Exp(-Math.Pow((rr - rRing) / (N * 0.05), 2));
                    double a = (grade == "S" ? 0.35 : 0.55) * fall;
                    Put(y * N + x, Math.Min(1, gr * 1.15), Math.Min(1, gg * 1.15), Math.Min(1, gb * 1.15), a, false);
                }
        }

        // The crop: a square from the cover, a little above centre where the subject sits.
        double side = cw, top = (ch - cw) * 0.38;
        for (int y = 0; y < N; y++)
        {
            for (int x = 0; x < N; x++)
            {
                double dx = x + 0.5 - cx, dy = y + 0.5 - cy, rr = Math.Sqrt(dx * dx + dy * dy);
                int i = y * N + x;
                if (rr <= rArt + 1)
                {
                    double u = dx / rArt, v = dy / rArt;
                    double sx = Clamp01(0.5 + 0.5 * u) * (side - 1), sy = top + Clamp01(0.5 + 0.5 * v) * (side - 1);
                    int px = (int)sx, py = Math.Min(ch - 1, (int)sy);
                    int p = cov[py * cw + px];
                    double ar = ((p >> 16) & 255) / 255.0, ag = ((p >> 8) & 255) / 255.0, ab = (p & 255) / 255.0;
                    // Glass dome: vignette plus a curved highlight.
                    double rn = rr / rArt;
                    double vig = 1 - 0.38 * Math.Pow(rn, 3);
                    double nx = u * 0.55, ny = -v * 0.55, nz = 1; Norm(ref nx, ref ny, ref nz);
                    double lx = LX, ly = LY, lz = LZ; Norm(ref lx, ref ly, ref lz);
                    double hx = lx, hy = ly, hz = lz + 1; Norm(ref hx, ref hy, ref hz);
                    double ndh = Math.Max(0, nx * hx + ny * hy + nz * hz);
                    double spec = 0.45 * Math.Pow(ndh, 60) + 0.10 * Math.Pow(ndh, 8);
                    double a = Clamp01(rArt + 1 - rr);
                    Put(i, Clamp01(ar * vig + spec), Clamp01(ag * vig + spec), Clamp01(ab * vig + spec), a, true);
                }
                if (rr > rArt - 1 && rr <= rRing + 1)
                {
                    // Torus profile across the ring.
                    double tt = Clamp01((rr - rArt) / (rRing - rArt));
                    double ang = (tt * 2 - 1) * Math.PI / 2 * 0.9;
                    double ux = dx / rr, uy = -dy / rr;
                    double nx = Math.Sin(ang) * ux, ny = Math.Sin(ang) * uy, nz = Math.Cos(ang);
                    double th = Math.Atan2(uy, ux);
                    double br, bg, bb;
                    GradeMetal(grade, th, tt, out br, out bg, out bb);
                    // Engraved notches around the ring.
                    double notch = (th / (2 * Math.PI) * 48) % 1.0;
                    if (notch < 0) notch += 1;
                    if (notch < 0.08 && tt > 0.25 && tt < 0.75) { br *= 0.62; bg *= 0.62; bb *= 0.62; }
                    double r, g, b;
                    Metal(br, bg, bb, nx, ny, nz, 1.1, out r, out g, out b);
                    double a = Math.Min(Clamp01(rr - (rArt - 1)), Clamp01(rRing + 1 - rr));
                    Put(i, r, g, b, a, true);
                }
            }
        }

        // Studs on the ring for SS and SSS.
        if (studs > 0)
        {
            double sr = (rRing - rArt) * 0.42, mid = (rArt + rRing) / 2;
            for (int k = 0; k < studs; k++)
            {
                double ang = Math.PI / 4 + k * 2 * Math.PI / studs;
                double scx = cx + Math.Cos(ang) * mid, scy = cy - Math.Sin(ang) * mid;
                double gr, gg, gb;
                if (grade == "SSS") Hsv(k / (double)studs, 0.7, 1.0, out gr, out gg, out gb);
                else { gr = 0.9; gg = 0.97; gb = 1.0; }
                for (int y = (int)(scy - sr - 2); y <= (int)(scy + sr + 2); y++)
                    for (int x = (int)(scx - sr - 2); x <= (int)(scx + sr + 2); x++)
                    {
                        if (x < 0 || y < 0 || x >= N || y >= N) continue;
                        double dx = x + 0.5 - scx, dy = y + 0.5 - scy, rr = Math.Sqrt(dx * dx + dy * dy);
                        if (rr > sr + 1) continue;
                        double u = dx / sr, v = -dy / sr;
                        double nz = Math.Sqrt(Math.Max(0.05, 1 - u * u - v * v));
                        double nx = u, ny = v; Norm(ref nx, ref ny, ref nz);
                        double r, g, b;
                        Metal(gr, gg, gb, nx, ny, nz, 0.4 + k, out r, out g, out b);
                        Put(y * N + x, r, g, b, Clamp01(sr + 1 - rr), true);
                    }
            }
        }

        // Grade plaque at the bottom of the ring, with the letters raised on it.
        double pw = N * (0.13 + 0.065 * grade.Length), ph = N * 0.12, pr = ph * 0.32;
        double pcx = cx, pcy = cy + rRing * 0.98;
        double bevel = ph * 0.2;
        for (int y = (int)(pcy - ph); y <= (int)(pcy + ph); y++)
            for (int x = (int)(pcx - pw); x <= (int)(pcx + pw); x++)
            {
                if (x < 0 || y < 0 || x >= N || y >= N) continue;
                // Signed distance to a rounded rectangle.
                double qx = Math.Abs(x + 0.5 - pcx) - (pw / 2 - pr), qy = Math.Abs(y + 0.5 - pcy) - (ph / 2 - pr);
                double ox = Math.Max(qx, 0), oy = Math.Max(qy, 0);
                double dist = Math.Sqrt(ox * ox + oy * oy) + Math.Min(Math.Max(qx, qy), 0) - pr;
                if (dist > 1) continue;
                double inside = -dist;
                double nx = 0, ny = 0, nz = 1;
                if (inside < bevel)
                {
                    // Bevel normal points outward from the plaque centre.
                    double gx = (x + 0.5 - pcx) / (pw / 2), gy = -(y + 0.5 - pcy) / (ph / 2);
                    double k = 1 - inside / bevel;
                    nx = gx * k * 0.9; ny = gy * k * 0.9; nz = 1; Norm(ref nx, ref ny, ref nz);
                }
                double br, bg, bb;
                GradeMetal(grade, Math.Atan2(-(y - pcy), x - pcx) + (x - pcx) / pw * 3, 0.5, out br, out bg, out bb);
                double r, g, b;
                Metal(br, bg, bb, nx, ny, nz, 2.0, out r, out g, out b);
                Put(y * N + x, r, g, b, Clamp01(1 - dist), true);
            }
        float[] txt = TextMask(grade, pcx, pcy, pw * 0.72, ph * 0.66);
        bool lightInk = grade == "F";
        for (int i = 0; i < N * N; i++)
        {
            if (txt[i] <= 0.002) continue;
            // A dark drop under the letters, then the ink itself.
            int below = i + N * Math.Max(1, N / 400);
            if (below < N * N) Put(below, 0, 0, 0, txt[i] * 0.35, false);
            if (lightInk) Put(i, 0.97, 0.97, 0.98, txt[i], false);
            else Put(i, 0.10, 0.07, 0.04, txt[i], false);
        }

        Finish(outPath, size, 0.5);
    }

    // ------------------------------------------------------------------
    // Rarity gem: tier 0 (Common) .. 7 (Exotic), fancier at each step.
    // ------------------------------------------------------------------

    public static void RarityGem(string outPath, int tier, int rgb, int size)
    {
        Begin(size);
        double baseR = ((rgb >> 16) & 255) / 255.0, baseG = ((rgb >> 8) & 255) / 255.0, baseB = (rgb & 255) / 255.0;
        double cx = N * 0.5, cy = N * 0.5, R0 = N * 0.30;
        // Divine and Exotic stay brilliant cuts; their rays and halo carry the rank.
        bool cabochon = tier == 0, star = false;
        int n = tier == 1 ? 6 : tier == 2 ? 8 : tier == 3 ? 10 : tier == 4 ? 12 : tier == 5 ? 14 : 16;
        double s = 2 * Math.PI / n;
        double tableR = star ? 0.34 : 0.46;
        bool bezel = tier >= 4;

        // Behind the gem: glow (Mythic up) and light rays (Divine, Exotic).
        if (tier >= 5)
        {
            for (int y = 0; y < N; y++)
                for (int x = 0; x < N; x++)
                {
                    double dx = x + 0.5 - cx, dy = y + 0.5 - cy, rr = Math.Sqrt(dx * dx + dy * dy);
                    double th = Math.Atan2(-dy, dx);
                    double gr = baseR, gg = baseG, gb = baseB;
                    if (tier == 7) Hsv(th / (2 * Math.PI), 0.75, 1.0, out gr, out gg, out gb);
                    double glow = 0.55 * Math.Exp(-Math.Pow(Math.Max(0, rr - R0 * 0.8) / (N * 0.09), 2));
                    double rays = 0;
                    if (tier >= 6)
                    {
                        int count = tier == 7 ? 12 : 8;
                        rays = Math.Pow(Math.Max(0, Math.Cos(th * count / 2)), 18) * Math.Exp(-Math.Max(0, rr - R0) / (N * 0.12));
                        rays *= rr < R0 * 0.5 ? 0 : 0.85;
                    }
                    double a = Clamp01(glow + rays);
                    if (a > 0.003) Put(y * N + x, Math.Min(1, gr * 1.1 + 0.15), Math.Min(1, gg * 1.1 + 0.15), Math.Min(1, gb * 1.1 + 0.15), a, false);
                }
        }

        double lx = LX, ly = LY, lz = LZ; Norm(ref lx, ref ly, ref lz);
        double l2x = 0.5, l2y = -0.5, l2z = 0.7; Norm(ref l2x, ref l2y, ref l2z);   // "refracted" light from below
        double hx = lx, hy = ly, hz = lz + 1; Norm(ref hx, ref hy, ref hz);

        for (int y = 0; y < N; y++)
        {
            for (int x = 0; x < N; x++)
            {
                double dx = x + 0.5 - cx, Y = -(y + 0.5 - cy), rr = Math.Sqrt(dx * dx + Y * Y);
                double th = Math.Atan2(Y, dx); if (th < 0) th += 2 * Math.PI;
                double sec = th % s, frac = sec / s;
                double Rth;
                if (cabochon) Rth = R0;
                else if (star)
                {
                    double w = 1 - Math.Abs(frac * 2 - 1);
                    double rin = tier == 7 ? 0.5 : 0.58;
                    Rth = R0 * (rin + (1.12 - rin) * w);
                }
                else Rth = R0 * Math.Cos(Math.PI / n) / Math.Cos(sec - s / 2);
                double bez = bezel ? N * 0.028 : 0;
                if (rr > Rth + bez + 1) continue;
                int i = y * N + x;

                if (rr > Rth)
                {
                    // Gold bezel around the girdle (Legendary up).
                    double tt = Clamp01((rr - Rth) / bez);
                    double ang = (tt * 2 - 1) * Math.PI / 2 * 0.9;
                    double ux = dx / rr, uy = Y / rr;
                    double r, g, b;
                    Metal(0.95, 0.75, 0.28, Math.Sin(ang) * ux, Math.Sin(ang) * uy, Math.Cos(ang), 0.7, out r, out g, out b);
                    Put(i, r, g, b, Clamp01(Rth + bez + 1 - rr), true);
                    continue;
                }

                double rn = rr / Rth;
                double nx, ny, nz;
                int facet = 0;
                if (cabochon)
                {
                    nz = Math.Sqrt(Math.Max(0.02, 1 - 0.85 * rn * rn));
                    nx = dx / R0 * 0.92; ny = Y / R0 * 0.92;
                }
                else if (rn < tableR)
                {
                    nx = 0; ny = 0; nz = 1;
                }
                else
                {
                    int k = (int)(th / s);
                    int half = frac < 0.5 ? 0 : 1;
                    bool outer = rn > (tableR + 1) / 2;
                    facet = k * 4 + half * 2 + (outer ? 1 : 0);
                    double phi = (k + 0.25 + 0.5 * half) * s;
                    double tilt = outer ? 0.95 : 0.5;
                    nx = Math.Sin(tilt) * Math.Cos(phi); ny = Math.Sin(tilt) * Math.Sin(phi); nz = Math.Cos(tilt);
                }
                Norm(ref nx, ref ny, ref nz);

                double gr = baseR, gg = baseG, gb = baseB;
                if (tier == 7 && facet % 4 == 1)
                {
                    // Fire: the odd outer facet throws a flash of another colour.
                    double fr, fg, fb;
                    Hsv(facet * 0.137, 0.7, 1.0, out fr, out fg, out fb);
                    gr = gr * 0.55 + fr * 0.45; gg = gg * 0.55 + fg * 0.45; gb = gb * 0.55 + fb * 0.45;
                }

                double ndl = Math.Max(0, nx * lx + ny * ly + nz * lz);
                double ndl2 = Math.Max(0, nx * l2x + ny * l2y + nz * l2z);
                double ndh = Math.Max(0, nx * hx + ny * hy + nz * hz);
                double body = cabochon ? (0.35 + 0.75 * ndl) : (0.22 + 0.55 * ndl + 0.45 * ndl2);
                if (!cabochon && rn < tableR) body = 0.75 + 0.35 * (1 - rn / tableR) * (0.5 - (dx - Y) / (2 * Rth));
                double spec = cabochon ? (0.55 * Math.Pow(ndh, 40) + 0.12 * Math.Pow(ndh, 6))
                                       : (0.9 * Math.Pow(ndh, 70) + 0.22 * Math.Pow(ndh, 10));
                double r2 = gr * body + spec, g2 = gg * body + spec, b2 = gb * body + spec;
                if (cabochon)
                {
                    // A little stone texture for the plain Common.
                    double speck = Math.Sin(x * 0.37) * Math.Sin(y * 0.29) * Math.Sin((x + y) * 0.11);
                    r2 += 0.04 * speck; g2 += 0.04 * speck; b2 += 0.04 * speck;
                }
                else
                {
                    // Dark facet edges and girdle.
                    double edgeA = Math.Min(sec, s - sec) * rr;
                    double edgeR = Math.Abs(rn - tableR) * Rth;
                    double edgeO = Math.Abs(rn - (tableR + 1) / 2) * Rth;
                    double line = Math.Min(edgeA, Math.Min(edgeR, edgeO));
                    if (rn > tableR - 0.01 && line < N * 0.003) { r2 *= 0.62; g2 *= 0.62; b2 *= 0.62; }
                    if (rn > 0.965) { r2 *= 0.7; g2 *= 0.7; b2 *= 0.7; }
                }
                Put(i, Clamp01(r2), Clamp01(g2), Clamp01(b2), Clamp01(Rth + 1 - rr), true);
            }
        }

        // Sparkle glints from Epic up.
        if (tier >= 3)
        {
            int glints = tier >= 6 ? 3 : (tier >= 4 ? 2 : 1);
            double[] gx = { -0.42, 0.38, 0.05 }, gy = { 0.42, -0.30, 0.62 };
            for (int k = 0; k < glints; k++)
            {
                double scx = cx + gx[k] * R0, scy = cy - gy[k] * R0, len = N * (k == 0 ? 0.09 : 0.06), wid = N * 0.006;
                for (int y = (int)(scy - len); y <= (int)(scy + len); y++)
                    for (int x = (int)(scx - len); x <= (int)(scx + len); x++)
                    {
                        if (x < 0 || y < 0 || x >= N || y >= N) continue;
                        double dx = Math.Abs(x + 0.5 - scx), dy = Math.Abs(y + 0.5 - scy);
                        double a = Math.Exp(-dx / wid) * Math.Exp(-dy / len * 3) + Math.Exp(-dy / wid) * Math.Exp(-dx / len * 3);
                        a += 0.6 * Math.Exp(-(dx * dx + dy * dy) / (wid * wid * 9));
                        if (a > 0.01) Put(y * N + x, 1, 1, 1, Clamp01(a), false);
                    }
            }
        }

        Finish(outPath, size, 0.45);
    }
}
