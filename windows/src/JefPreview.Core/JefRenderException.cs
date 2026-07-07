using System;

namespace JefPreview.Core;

public sealed class JefRenderException : Exception
{
    public JefRenderException(string message) : base(message) { }
}
