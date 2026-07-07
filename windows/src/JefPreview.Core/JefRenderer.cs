using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

namespace JefPreview.Core;

public enum JefBackground
{
    Transparent,
    White
}

/// <summary>Нативный рендер .jef → Bitmap. Порт Swift JefRenderer.</summary>
public static class JefRenderer
{
    public const int Supersample = 2;

    private static readonly uint[] Fallback =
    {
        0x1A76BC, 0xD83A3E, 0x34A048, 0xF0921F, 0x7E57C2, 0x009688,
    };

    public static Bitmap RenderImage(string filePath, int size, JefBackground background,
        double lineWidthMm = 2.2, bool drawJumps = false)
    {
        var pattern = JefParser.ParseFile(filePath);
        return Draw(pattern, size, background, lineWidthMm, drawJumps);
    }

    public static Bitmap RenderImage(byte[] data, int size, JefBackground background,
        double lineWidthMm = 2.2, bool drawJumps = false)
    {
        var pattern = JefParser.Parse(data);
        return Draw(pattern, size, background, lineWidthMm, drawJumps);
    }

    public static byte[] RenderPng(string filePath, int size, JefBackground background)
    {
        using var bmp = RenderImage(filePath, size, background);
        using var ms = new MemoryStream();
        bmp.Save(ms, ImageFormat.Png);
        return ms.ToArray();
    }

    private static (byte R, byte G, byte B) Rgb(uint hex) =>
        ((byte)((hex >> 16) & 0xFF), (byte)((hex >> 8) & 0xFF), (byte)(hex & 0xFF));

    private static Bitmap Draw(JefPattern pat, int size, JefBackground background,
        double lineWidthMm, bool drawJumps)
    {
        var canvas = size * Supersample;
        var cd = (double)canvas;
        var w = Math.Max(pat.MaxX - pat.MinX, 1);
        var h = Math.Max(pat.MaxY - pat.MinY, 1);
        var pad = 0.05 * cd;
        var scale = Math.Min((cd - 2 * pad) / w, (cd - 2 * pad) / h);
        var ox = (cd - w * scale) / 2 - pat.MinX * scale;
        var oy = (cd - h * scale) / 2 - pat.MinY * scale;

        PointF Px(double x, double y) =>
            new((float)(x * scale + ox), (float)(y * scale + oy));

        var pixelFormat = background == JefBackground.Transparent
            ? PixelFormat.Format32bppArgb
            : PixelFormat.Format24bppRgb;

        using var full = new Bitmap(canvas, canvas, pixelFormat);
        using (var g = Graphics.FromImage(full))
        {
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;

            if (background == JefBackground.White)
                g.Clear(Color.White);
            else
                g.Clear(Color.Transparent);

            var lw = Math.Max(1.0, Math.Round(lineWidthMm * Supersample * size / 1024.0));
            using var pen = new Pen(Color.Black, (float)lw)
            {
                StartCap = LineCap.Round,
                EndCap = LineCap.Round,
                LineJoin = LineJoin.Round
            };

            (byte R, byte G, byte B) ColorFor(int i)
            {
                if (pat.Colors.Count > 0)
                {
                    var c = pat.Colors[i % pat.Colors.Count];
                    return Rgb(c);
                }

                return Rgb(Fallback[i % Fallback.Length]);
            }

            var idx = 0;
            var seg = new List<PointF>();

            void Flush()
            {
                if (seg.Count < 2)
                {
                    seg.Clear();
                    return;
                }

                var c = ColorFor(idx);
                pen.Color = Color.FromArgb(c.R, c.G, c.B);
                g.DrawLines(pen, seg.ToArray());
                seg.Clear();
            }

            foreach (var s in pat.Stitches)
            {
                switch (s.Command)
                {
                    case JefStitchCommand.Stitch:
                        seg.Add(Px(s.X, s.Y));
                        break;
                    case JefStitchCommand.Jump:
                        if (drawJumps && seg.Count > 0)
                            seg.Add(Px(s.X, s.Y));
                        Flush();
                        seg.Add(Px(s.X, s.Y));
                        break;
                    case JefStitchCommand.ColorChange:
                        Flush();
                        idx++;
                        break;
                    case JefStitchCommand.Stop:
                        Flush();
                        break;
                    case JefStitchCommand.End:
                        Flush();
                        break;
                }
            }

            Flush();
        }
        var down = new Bitmap(size, size, pixelFormat);
        using (var g = Graphics.FromImage(down))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.DrawImage(full, new Rectangle(0, 0, size, size));
        }

        return down;
    }
}
