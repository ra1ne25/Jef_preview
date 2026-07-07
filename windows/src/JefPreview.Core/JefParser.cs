using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace JefPreview.Core;

/// <summary>Нативный парсер .jef (Janome). Порт pyembroidery JefReader.</summary>
public static class JefParser
{
    /// <summary>Палитра Janome. Индекс 0 — плейсхолдер, реальные нити 1..78.</summary>
    public static readonly uint[] Palette =
    {
        0x000000, 0x000000, 0xFFFFFF, 0xFFFF17, 0xFF6600, 0x2F5933, 0x237336, 0x65C2C8,
        0xAB5A96, 0xF669A0, 0xFF0000, 0xB1704E, 0x0B2F84, 0xE4C35D, 0x481A05, 0xAC9CC7,
        0xFCF294, 0xF999B7, 0xFAB381, 0xC9A480, 0x970533, 0xA0B8CC, 0x7FC21C, 0xE5E5E5,
        0x889B9B, 0x98D6BD, 0xB2E1E3, 0x368BA0, 0x4F83AB, 0x386A91, 0x071650, 0xF999A2,
        0xF9676B, 0xE3311F, 0xE2A188, 0xB59474, 0xE4CF99, 0xFFCB00, 0xE1ADD4, 0xC3007E,
        0x80004B, 0x540571, 0xB10525, 0xCAE0C0, 0x899856, 0x5C941A, 0x003114, 0x5DAE94,
        0x4CBF8F, 0x007772, 0x595B61, 0xFFFFF2, 0xB15818, 0xCB8A07, 0x986C80, 0x98692D,
        0x4D3419, 0x4C330B, 0x33200A, 0x523A97, 0x0D217E, 0x1E77AC, 0xB2DD53, 0xF33689,
        0xDE649E, 0x984161, 0x4C5612, 0x4C881F, 0xE4DE79, 0xCB8A1A, 0xCBA21C, 0xFF9805,
        0xFCB257, 0xFFE505, 0xF0331F, 0x1A842D, 0x386CAE, 0xE3C4B4, 0xE3AC81,
    };

    public static JefPattern Parse(byte[] data)
    {
        if (data.Length < 116)
            throw new JefRenderException($"файл слишком мал ({data.Length} байт)");

        var stitchOffset = Int32Le(data, 0);
        var countColors = Int32Le(data, 24);
        if (countColors < 0 || countColors >= 10000)
            throw new JefRenderException($"некорректное число цветов: {countColors}");

        var slots = new List<uint?>();
        var p = 116;
        for (var i = 0; i < countColors; i++)
        {
            if (p + 4 > data.Length) break;
            var index = Math.Abs(Int32Le(data, p));
            p += 4;
            slots.Add(index == 0 ? null : Palette[index % Palette.Length]);
        }

        var realColors = slots.Where(c => c.HasValue).Select(c => c!.Value).ToList();

        if (stitchOffset < 0 || stitchOffset > data.Length)
            throw new JefRenderException($"некорректное смещение стежков: {stitchOffset}");

        var stitches = new List<JefStitch>();
        double x = 0, y = 0;
        var minX = double.MaxValue;
        var minY = double.MaxValue;
        var maxX = double.MinValue;
        var maxY = double.MinValue;

        void Bound()
        {
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
        }

        var pos = stitchOffset;
        var slotIdx = 1;

        while (pos + 2 <= data.Length)
        {
            var b0 = data[pos];
            var b1 = data[pos + 1];
            pos += 2;

            if (b0 != 0x80)
            {
                x += Signed8(b0);
                y += -Signed8(b1);
                Bound();
                stitches.Add(new JefStitch(x, y, JefStitchCommand.Stitch));
                continue;
            }

            var ctrl = b1;
            if (pos + 2 > data.Length) break;

            var b2 = data[pos];
            var b3 = data[pos + 1];
            pos += 2;
            var dx = (double)Signed8(b2);
            var dy = (double)-Signed8(b3);

            switch (ctrl)
            {
                case 0x02:
                    x += dx;
                    y += dy;
                    Bound();
                    stitches.Add(new JefStitch(x, y, JefStitchCommand.Jump));
                    break;
                case 0x01:
                    var isNone = slotIdx < slots.Count && slots[slotIdx] == null;
                    stitches.Add(new JefStitch(x, y, isNone ? JefStitchCommand.Stop : JefStitchCommand.ColorChange));
                    slotIdx++;
                    break;
                case 0x10:
                    goto endLoop;
                default:
                    goto endLoop;
            }
        }

        endLoop:
        stitches.Add(new JefStitch(x, y, JefStitchCommand.End));

        if (minX > maxX)
        {
            minX = 0;
            minY = 0;
            maxX = 1;
            maxY = 1;
        }

        if (stitches.Count <= 1)
            throw new JefRenderException("нет стежков");

        return new JefPattern(realColors, stitches, minX, minY, maxX, maxY);
    }

    public static JefPattern ParseFile(string path)
    {
        if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
            throw new JefRenderException($"файл не найден: {path}");

        return Parse(File.ReadAllBytes(path));
    }

    private static int Signed8(byte b) => b < 128 ? b : b - 256;

    private static int Int32Le(byte[] d, int off) =>
        d[off] | (d[off + 1] << 8) | (d[off + 2] << 16) | (d[off + 3] << 24);
}
