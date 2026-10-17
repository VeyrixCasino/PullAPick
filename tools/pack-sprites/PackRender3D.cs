using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

// A tiny software renderer for a foil booster pack: a puffy pillow surface with
// sealed, ridged crimp ends, the cover art printed on the curved front, lit with
// diffuse + specular, then a soft drop shadow. C# 5 only (Windows PowerShell 5.1).
public static class PackRender3D
{
    const double FACEH = 1.4;   // face is 1.0 wide x 1.4 tall: the 5:7 cover maps 1:1
    const double CRIMP = 0.14;  // sealed band at each end
    const double HTOT = FACEH + 2 * CRIMP;

    static int[] cov; static int covW, covH;
    static double accR, accG, accB;
    static int styleId; // 0 plain, 1 foil, 2 silver, 3 gold
    static double cY, sY, cP, sP, cR, sR;
    static int NX, NY;
    static double[] vsx, vsy, viw, vz, vu, vt, vnx, vny, vnz;
    static float[] bR, bG, bB, bA;
    static double[] zbuf;
    // Set name printed on the top crimp: fill and outline masks over (u, band depth).
    const int MW = 1400, MH = 196;
    static float[] mFill, mLine;

    static void BuildTitleMask(string text)
    {
        mFill = null; mLine = null;
        if (string.IsNullOrEmpty(text)) return;
        using (Bitmap bm = new Bitmap(MW, MH, PixelFormat.Format32bppArgb))
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
                    RectangleF b = p.GetBounds();
                    // Sit the words in the flat lower part of the seal, clear of the teeth.
                    float sc = (float)Math.Min(MW * 0.80 / b.Width, MH * 0.40 / b.Height);
                    using (Matrix mx = new Matrix())
                    {
                        mx.Translate(MW / 2f, MH * 0.60f);
                        mx.Scale(sc, sc);
                        mx.Translate(-(b.X + b.Width / 2), -(b.Y + b.Height / 2));
                        p.Transform(mx);
                    }
                    using (Pen pen = new Pen(Color.FromArgb(255, 0, 255, 0), MH * 0.07f))
                    {
                        pen.LineJoin = LineJoin.Round;
                        g.DrawPath(pen, p);
                    }
                    using (SolidBrush br = new SolidBrush(Color.FromArgb(255, 255, 0, 0))) { g.FillPath(br, p); }
                }
            }
            int[] raw = new int[MW * MH];
            BitmapData d = bm.LockBits(new Rectangle(0, 0, MW, MH), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(d.Scan0, raw, 0, raw.Length);
            bm.UnlockBits(d);
            mFill = new float[raw.Length]; mLine = new float[raw.Length];
            for (int i = 0; i < raw.Length; i++)
            {
                int r = (raw[i] >> 16) & 255, gg = (raw[i] >> 8) & 255;
                mFill[i] = r / 255f;
                mLine[i] = Math.Max(r, gg) / 255f;
            }
        }
    }

    static double SampleMask(float[] m, double u, double v)
    {
        double fx = Clamp01(u) * (MW - 1), fy = Clamp01(v) * (MH - 1);
        int x0 = (int)fx, y0 = (int)fy, x1 = Math.Min(x0 + 1, MW - 1), y1 = Math.Min(y0 + 1, MH - 1);
        return Bi(m[y0 * MW + x0], m[y0 * MW + x1], m[y1 * MW + x0], m[y1 * MW + x1], fx - x0, fy - y0);
    }

    static double Smooth(double e0, double e1, double x)
    {
        double t = (x - e0) / (e1 - e0);
        if (t < 0) t = 0;
        if (t > 1) t = 1;
        return t * t * (3 - 2 * t);
    }

    static double Clamp01(double v) { return v < 0 ? 0 : (v > 1 ? 1 : v); }

    // Pack surface for u (0..1, left to right) and t (0..1, top to bottom).
    static void Surface(double u, double t, out double x, out double y, out double z)
    {
        y = HTOT / 2 - t * HTOT;
        double edgeDist = FACEH / 2 - Math.Abs(y);
        double body = edgeDist > 0 ? Smooth(0, 0.22, edgeDist) : 0;
        double s = 2 * u - 1;
        double across = Math.Sqrt(Math.Max(0, 1 - s * s));
        z = 0.24 * Math.Pow(across, 0.75) * body;
        // The bulge pulls the sides in a little, most where the pouch meets the seal.
        double pinch = 0.025 * body + 0.06 * body * (1 - body);
        x = s * 0.5 * (1 - pinch);
        if (edgeDist <= 0)
        {
            // Heat-seal ridges on the crimp.
            z += 0.0016 * Math.Sin(u * Math.PI * 2 * 34);
        }
        else
        {
            // Soft creases where the pillow gathers into the seal.
            double wr = Math.Exp(-Math.Pow((edgeDist - 0.07) / 0.05, 2));
            z += 0.011 * wr * Math.Sin(s * 21 + y * 9) * (0.35 + 0.65 * across);
        }
    }

    static void Rotate(double x, double y, double z, out double X, out double Y, out double Z)
    {
        double x1 = x * cY + z * sY;          // yaw about Y
        double z1 = -x * sY + z * cY;
        double y2 = y * cP - z1 * sP;          // pitch about X
        double z2 = y * sP + z1 * cP;
        X = x1 * cR - y2 * sR;                 // roll about Z
        Y = x1 * sR + y2 * cR;
        Z = z2;
    }

    static void LoadCover(string path)
    {
        using (Bitmap src = new Bitmap(path))
        using (Bitmap bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(bmp)) { g.DrawImage(src, 0, 0, src.Width, src.Height); }
            covW = bmp.Width; covH = bmp.Height;
            cov = new int[covW * covH];
            BitmapData d = bmp.LockBits(new Rectangle(0, 0, covW, covH), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(d.Scan0, cov, 0, cov.Length);
            bmp.UnlockBits(d);
        }
    }

    static void SampleCover(double u, double v, out double r, out double g, out double b)
    {
        double fx = Clamp01(u) * (covW - 1), fy = Clamp01(v) * (covH - 1);
        int x0 = (int)fx, y0 = (int)fy;
        int x1 = Math.Min(x0 + 1, covW - 1), y1 = Math.Min(y0 + 1, covH - 1);
        double ax = fx - x0, ay = fy - y0;
        int p00 = cov[y0 * covW + x0], p10 = cov[y0 * covW + x1], p01 = cov[y1 * covW + x0], p11 = cov[y1 * covW + x1];
        r = Bi(((p00 >> 16) & 255), ((p10 >> 16) & 255), ((p01 >> 16) & 255), ((p11 >> 16) & 255), ax, ay) / 255.0;
        g = Bi(((p00 >> 8) & 255), ((p10 >> 8) & 255), ((p01 >> 8) & 255), ((p11 >> 8) & 255), ax, ay) / 255.0;
        b = Bi((p00 & 255), (p10 & 255), (p01 & 255), (p11 & 255), ax, ay) / 255.0;
    }

    static double Bi(double a, double b, double c, double d, double x, double y)
    {
        return (a * (1 - x) + b * x) * (1 - y) + (c * (1 - x) + d * x) * y;
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

    static bool Shade(double u, double t, double nx, double ny, double nz, out float r, out float g, out float b)
    {
        r = g = b = 0;
        double y = HTOT / 2 - t * HTOT;
        double edgeDist = FACEH / 2 - Math.Abs(y);
        double outer = HTOT / 2 - Math.Abs(y);
        double ar = 0, ag = 0, ab = 0;
        bool metal = false, irid = false, face = edgeDist >= 0;
        double ks = 0.26, sh = 70;

        if (!face)
        {
            // Crimped teeth along the outer edge of each seal.
            double teeth = 26, ph = u * teeth - Math.Floor(u * teeth), tri = Math.Abs(ph * 2 - 1);
            if (outer < 0.042 * tri) return false;
            if (styleId >= 2) metal = true;
            else
            {
                double k = 0.8 + 0.35 * (outer / CRIMP);
                ar = accR * k; ag = accG * k; ab = accB * k;
            }
            ks = 0.4; sh = 30;
        }
        else
        {
            SampleCover(u, (FACEH / 2 - y) / FACEH, out ar, out ag, out ab);
            double border = Math.Min(Math.Min(u, 1 - u), edgeDist);
            if (edgeDist < 0.013)
            {
                if (styleId >= 2) metal = true;
                else { ar = accR * 0.45; ag = accG * 0.45; ab = accB * 0.45; }
            }
            else if (styleId == 1 && border < 0.034) irid = true;
            else if (styleId >= 2 && border < 0.02) metal = true;
        }

        if (metal)
        {
            if (styleId == 3) { ar = 0.93; ag = 0.71; ab = 0.24; } else { ar = 0.62; ag = 0.66; ab = 0.72; }
            // Fake environment reflection: banding that follows the surface normal.
            double band = 0.80 + 0.30 * Math.Sin(ny * 3.0 + nx * 2.2 + t * 5.0 + 1.3);
            ar *= band; ag *= band; ab *= band;
            ks = styleId == 3 ? 0.95 : 0.6; sh = 22;
        }
        if (irid)
        {
            double hue = 0.55 * (u + t) + 1.1 * (1 - Math.Max(0, nz));
            Hsv(hue, 0.55, 1.0, out ar, out ag, out ab);
            ks = 0.6; sh = 28;
        }

        // Set name on the top seal: white with a dark edge on theme seals,
        // dark ink on silver and gold.
        if (!face && y > 0 && mFill != null)
        {
            double bt = (HTOT / 2 - y) / CRIMP;
            double line = SampleMask(mLine, u, bt), fill = SampleMask(mFill, u, bt);
            if (line > 0.001)
            {
                double tr, tg, tb, er, eg, eb;
                if (styleId == 3) { tr = 0.30; tg = 0.17; tb = 0.02; er = 1.0; eg = 0.93; eb = 0.62; }
                else if (styleId == 2) { tr = 0.12; tg = 0.14; tb = 0.18; er = 0.95; eg = 0.97; eb = 1.0; }
                else { tr = 1.0; tg = 1.0; tb = 1.0; er = accR * 0.28; eg = accG * 0.28; eb = accB * 0.28; }
                double edge = Math.Max(0, line - fill);
                ar = ar * (1 - edge) + er * edge; ag = ag * (1 - edge) + eg * edge; ab = ab * (1 - edge) + eb * edge;
                ar = ar * (1 - fill) + tr * fill; ag = ag * (1 - fill) + tg * fill; ab = ab * (1 - fill) + tb * fill;
                ks *= 1 - 0.6 * fill;
            }
        }

        // Light from the upper left, viewer straight on.
        double lx = -0.45, ly = 0.62, lz = 0.64;
        double ll = Math.Sqrt(lx * lx + ly * ly + lz * lz); lx /= ll; ly /= ll; lz /= ll;
        double ndl = Math.Max(0, nx * lx + ny * ly + nz * lz);
        double diff = 0.4 + 0.78 * ndl;
        double hx = lx, hy = ly, hz = lz + 1;
        double hl = Math.Sqrt(hx * hx + hy * hy + hz * hz); hx /= hl; hy /= hl; hz /= hl;
        double ndh = Math.Max(0, nx * hx + ny * hy + nz * hz);
        double spec = ks * Math.Pow(ndh, sh);
        if (face && !metal) spec += 0.16 * Math.Pow(ndh, 7) + 0.22 * Math.Pow(ndh, 45);   // foil sheen and a crisp glint on the print
        double rim = 1 - 0.55 * Math.Pow(1 - Math.Max(0, nz), 1.6);
        double sr = 1, sg = 1, sb = 1;
        if (metal && styleId == 3) { sr = 1; sg = 0.88; sb = 0.55; }

        r = (float)Clamp01(ar * diff * rim + sr * spec);
        g = (float)Clamp01(ag * diff * rim + sg * spec);
        b = (float)Clamp01(ab * diff * rim + sb * spec);
        return true;
    }

    static void Tri(int a, int b, int c)
    {
        double x0 = vsx[a], y0 = vsy[a], x1 = vsx[b], y1 = vsy[b], x2 = vsx[c], y2 = vsy[c];
        double area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0);
        if (Math.Abs(area) < 1e-9) return;
        int minX = Math.Max(0, (int)Math.Floor(Math.Min(x0, Math.Min(x1, x2))));
        int maxX = Math.Min(NX - 1, (int)Math.Ceiling(Math.Max(x0, Math.Max(x1, x2))));
        int minY = Math.Max(0, (int)Math.Floor(Math.Min(y0, Math.Min(y1, y2))));
        int maxY = Math.Min(NY - 1, (int)Math.Ceiling(Math.Max(y0, Math.Max(y1, y2))));
        for (int py = minY; py <= maxY; py++)
        {
            double pyc = py + 0.5;
            for (int px = minX; px <= maxX; px++)
            {
                double pxc = px + 0.5;
                double w0 = ((x1 - pxc) * (y2 - pyc) - (x2 - pxc) * (y1 - pyc)) / area;
                double w1 = ((x2 - pxc) * (y0 - pyc) - (x0 - pxc) * (y2 - pyc)) / area;
                double w2 = 1 - w0 - w1;
                if (w0 < -1e-7 || w1 < -1e-7 || w2 < -1e-7) continue;
                // Perspective-correct interpolation.
                double iwp = w0 * viw[a] + w1 * viw[b] + w2 * viw[c];
                double p0 = w0 * viw[a] / iwp, p1 = w1 * viw[b] / iwp, p2 = w2 * viw[c] / iwp;
                double z = p0 * vz[a] + p1 * vz[b] + p2 * vz[c];
                int idx = py * NX + px;
                if (z <= zbuf[idx]) continue;
                double u = p0 * vu[a] + p1 * vu[b] + p2 * vu[c];
                double t = p0 * vt[a] + p1 * vt[b] + p2 * vt[c];
                double nx = p0 * vnx[a] + p1 * vnx[b] + p2 * vnx[c];
                double ny = p0 * vny[a] + p1 * vny[b] + p2 * vny[c];
                double nz = p0 * vnz[a] + p1 * vnz[b] + p2 * vnz[c];
                double nl = Math.Sqrt(nx * nx + ny * ny + nz * nz);
                if (nl > 0) { nx /= nl; ny /= nl; nz /= nl; }
                float r, g, bb;
                if (!Shade(u, t, nx, ny, nz, out r, out g, out bb)) continue;
                zbuf[idx] = z; bR[idx] = r; bG[idx] = g; bB[idx] = bb; bA[idx] = 1f;
            }
        }
    }

    static void BoxBlur(float[] src, int w, int h, int radius)
    {
        float[] tmp = new float[src.Length];
        for (int pass = 0; pass < 3; pass++)
        {
            for (int y = 0; y < h; y++)
            {
                double sum = 0; int row = y * w;
                for (int x = -radius; x <= radius; x++) sum += src[row + Math.Min(w - 1, Math.Max(0, x))];
                for (int x = 0; x < w; x++)
                {
                    tmp[row + x] = (float)(sum / (2 * radius + 1));
                    sum += src[row + Math.Min(w - 1, x + radius + 1)] - src[row + Math.Max(0, x - radius)];
                }
            }
            for (int x = 0; x < w; x++)
            {
                double sum = 0;
                for (int y = -radius; y <= radius; y++) sum += tmp[Math.Min(h - 1, Math.Max(0, y)) * w + x];
                for (int y = 0; y < h; y++)
                {
                    src[y * w + x] = (float)(sum / (2 * radius + 1));
                    sum += tmp[Math.Min(h - 1, y + radius + 1) * w + x] - tmp[Math.Max(0, y - radius) * w + x];
                }
            }
        }
    }

    public static void Render(string coverPath, string outPath, string style, int accentRgb, int outW, int outH,
        double yawDeg, double pitchDeg, double rollDeg, string title)
    {
        LoadCover(coverPath);
        BuildTitleMask(title);
        accR = ((accentRgb >> 16) & 255) / 255.0; accG = ((accentRgb >> 8) & 255) / 255.0; accB = (accentRgb & 255) / 255.0;
        styleId = style == "foil" ? 1 : (style == "silver" ? 2 : (style == "gold" ? 3 : 0));
        double ya = yawDeg * Math.PI / 180, pa = pitchDeg * Math.PI / 180, ra = rollDeg * Math.PI / 180;
        cY = Math.Cos(ya); sY = Math.Sin(ya); cP = Math.Cos(pa); sP = Math.Sin(pa); cR = Math.Cos(ra); sR = Math.Sin(ra);

        NX = outW * 2; NY = outH * 2;  // 2x supersampling, downscaled at the end
        double D = 4.0;

        int nu = 200, nv = 330, vc = (nu + 1) * (nv + 1);
        vsx = new double[vc]; vsy = new double[vc]; viw = new double[vc]; vz = new double[vc];
        vu = new double[vc]; vt = new double[vc]; vnx = new double[vc]; vny = new double[vc]; vnz = new double[vc];
        double e = 1e-3;
        for (int j = 0; j <= nv; j++)
        {
            for (int i = 0; i <= nu; i++)
            {
                double u = (double)i / nu, t = (double)j / nv;
                double x, y, z;
                Surface(u, t, out x, out y, out z);
                double xa, ya2, za, xb, yb, zb, xc, yc, zc, xd, yd, zd;
                Surface(Math.Min(1, u + e), t, out xa, out ya2, out za);
                Surface(Math.Max(0, u - e), t, out xb, out yb, out zb);
                Surface(u, Math.Min(1, t + e), out xc, out yc, out zc);
                Surface(u, Math.Max(0, t - e), out xd, out yd, out zd);
                double dux = xa - xb, duy = ya2 - yb, duz = za - zb;
                double dtx = xc - xd, dty = yc - yd, dtz = zc - zd;
                double nx = dty * duz - dtz * duy, ny = dtz * dux - dtx * duz, nz = dtx * duy - dty * dux;
                double nl = Math.Sqrt(nx * nx + ny * ny + nz * nz);
                if (nl > 0) { nx /= nl; ny /= nl; nz /= nl; }
                double X, Y, Z, RNX, RNY, RNZ;
                Rotate(x, y, z, out X, out Y, out Z);
                Rotate(nx, ny, nz, out RNX, out RNY, out RNZ);
                double d = D - Z;
                int k = j * (nu + 1) + i;
                // Unit projection first; fitted to the canvas below.
                vsx[k] = X / d; vsy[k] = -Y / d; viw[k] = 1.0 / d; vz[k] = Z;
                vu[k] = u; vt[k] = t; vnx[k] = RNX; vny[k] = RNY; vnz[k] = RNZ;
            }
        }

        // Fit the projected pack into the canvas, leaving room for the shadow
        // (down and right) so the pack fills the game's 5:7 slot.
        double minX = double.MaxValue, maxX = double.MinValue, minY = double.MaxValue, maxY = double.MinValue;
        for (int k = 0; k < vc; k++)
        {
            minX = Math.Min(minX, vsx[k]); maxX = Math.Max(maxX, vsx[k]);
            minY = Math.Min(minY, vsy[k]); maxY = Math.Max(maxY, vsy[k]);
        }
        double fit = Math.Min(NX * 0.90 / (maxX - minX), NY * 0.91 / (maxY - minY));
        double offX = NX * 0.5 - fit * (minX + maxX) / 2, offY = NY * 0.5 - fit * (minY + maxY) / 2;
        for (int k = 0; k < vc; k++) { vsx[k] = offX + fit * vsx[k]; vsy[k] = offY + fit * vsy[k]; }

        int nn = NX * NY;
        bR = new float[nn]; bG = new float[nn]; bB = new float[nn]; bA = new float[nn];
        zbuf = new double[nn];
        for (int i = 0; i < nn; i++) zbuf[i] = -1e9;
        for (int j = 0; j < nv; j++)
        {
            for (int i = 0; i < nu; i++)
            {
                int k00 = j * (nu + 1) + i, k10 = k00 + 1, k01 = k00 + nu + 1, k11 = k01 + 1;
                Tri(k00, k10, k11);
                Tri(k00, k11, k01);
            }
        }

        // Soft drop shadow, offset down and right.
        float[] shadow = new float[nn];
        int ox = NY * 2 / 200, oy = NY * 3 / 200;
        for (int y = 0; y < NY; y++)
            for (int x = 0; x < NX; x++)
            {
                int sx = x - ox, sy = y - oy;
                if (sx >= 0 && sy >= 0 && sx < NX && sy < NY) shadow[y * NX + x] = bA[sy * NX + sx];
            }
        BoxBlur(shadow, NX, NY, Math.Max(2, NY / 110));

        byte[] px = new byte[nn * 4];
        for (int i = 0; i < nn; i++)
        {
            double a = bA[i], sa = 0.5 * shadow[i];
            double outA = a + sa * (1 - a);
            double r = 0, g = 0, b = 0;
            if (outA > 0) { r = bR[i] * a / outA; g = bG[i] * a / outA; b = bB[i] * a / outA; }
            px[i * 4 + 0] = (byte)Math.Round(Clamp01(b) * 255);
            px[i * 4 + 1] = (byte)Math.Round(Clamp01(g) * 255);
            px[i * 4 + 2] = (byte)Math.Round(Clamp01(r) * 255);
            px[i * 4 + 3] = (byte)Math.Round(Clamp01(outA) * 255);
        }
        using (Bitmap big = new Bitmap(NX, NY, PixelFormat.Format32bppArgb))
        {
            BitmapData bd = big.LockBits(new Rectangle(0, 0, NX, NY), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(px, 0, bd.Scan0, px.Length);
            big.UnlockBits(bd);
            using (Bitmap outBmp = new Bitmap(outW, outH, PixelFormat.Format32bppArgb))
            {
                using (Graphics g = Graphics.FromImage(outBmp))
                {
                    g.Clear(Color.Transparent);
                    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                    g.CompositingQuality = CompositingQuality.HighQuality;
                    g.DrawImage(big, 0, 0, outW, outH);
                }
                outBmp.Save(outPath, ImageFormat.Png);
            }
        }
    }
}
