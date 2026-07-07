using System;
using System.Collections.Generic;

namespace JefPreview.Core;

public enum JefStitchCommand
{
    Stitch,
    Jump,
    ColorChange,
    Stop,
    End
}

public readonly struct JefStitch
{
    public JefStitch(double x, double y, JefStitchCommand cmd)
    {
        X = x;
        Y = y;
        Command = cmd;
    }

    public double X { get; }
    public double Y { get; }
    public JefStitchCommand Command { get; }
}

public sealed class JefPattern
{
    public JefPattern(
        IReadOnlyList<uint> colors,
        IReadOnlyList<JefStitch> stitches,
        double minX, double minY, double maxX, double maxY)
    {
        Colors = colors;
        Stitches = stitches;
        MinX = minX;
        MinY = minY;
        MaxX = maxX;
        MaxY = maxY;
    }

    public IReadOnlyList<uint> Colors { get; }
    public IReadOnlyList<JefStitch> Stitches { get; }
    public double MinX { get; }
    public double MinY { get; }
    public double MaxX { get; }
    public double MaxY { get; }

    public double WidthMm => (MaxX - MinX) / 10.0;
    public double HeightMm => (MaxY - MinY) / 10.0;
}
