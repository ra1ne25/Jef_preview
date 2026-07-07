using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using JefPreview.Core;
using SharpShell.Attributes;
using SharpShell.SharpThumbnailHandler;

namespace JefPreview.Shell;

[ComVisible(true)]
[Guid("B8E4F2A1-3C5D-4E6F-9A0B-1C2D3E4F5A6B")]
[DisplayName("JefPreview Thumbnail Handler")]
[ServerType(SharpShell.ServerType.ShellThumbnailHandler)]
[COMServerAssociation(AssociationType.ClassOfExtension, ".jef")]
public sealed class JefThumbnailHandler : SharpThumbnailHandler
{
    protected override Bitmap GetThumbnailImage(uint width)
    {
        try
        {
            byte[] data;
            using (var ms = new MemoryStream())
            {
                SelectedItemStream.CopyTo(ms);
                data = ms.ToArray();
            }

            var side = Math.Max((int)width, 64);
            return JefRenderer.RenderImage(data, side, JefBackground.Transparent);
        }
        catch (Exception ex)
        {
            JefPreview.Shell.JefLog.Info($"GetThumbnailImage: {ex.Message}");
            return new Bitmap(1, 1, System.Drawing.Imaging.PixelFormat.Format32bppArgb);
        }
    }
}
