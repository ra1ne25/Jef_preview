using System.Drawing;
using System.IO;
using System.Windows.Forms;
using JefPreview.Core;
using SharpShell.SharpPreviewHandler;

namespace JefPreview.Shell;

internal sealed class JefPreviewControl : PreviewHandlerControl
{
    private readonly PictureBox _picture = new()
    {
        Dock = DockStyle.Fill,
        SizeMode = PictureBoxSizeMode.Zoom,
        BackColor = Color.White
    };

    private string? _path;
    private int _renderGeneration;

    public JefPreviewControl()
    {
        Dock = DockStyle.Fill;
        Controls.Add(_picture);
        Load += (_, _) => StartRender();
    }

    public void BindPath(string? path)
    {
        _path = path;
        JefLog.Info($"BindPath: {path ?? "<null>"}");
    }

    protected override void OnLayout(LayoutEventArgs levent)
    {
        // SharpShell задаёт Bounds с ненулевым Left/Top при SetRect — ломает resize.
        if (Parent != null)
        {
            var size = Parent.ClientSize;
            if (size.Width > 0 && size.Height > 0)
            {
                if (Location != Point.Empty)
                    Location = Point.Empty;
                if (Size != size)
                    Size = size;
            }
        }

        base.OnLayout(levent);
    }

    protected override void OnResize(EventArgs e)
    {
        try
        {
            base.OnResize(e);
        }
        catch (Exception ex)
        {
            JefLog.Info($"OnResize error: {ex.Message}");
        }
    }

    private void StartRender()
    {
        if (string.IsNullOrWhiteSpace(_path))
        {
            JefLog.Info("StartRender: empty path");
            return;
        }

        if (!File.Exists(_path))
        {
            JefLog.Info($"StartRender: not found: {_path}");
            return;
        }

        var path = _path;
        var generation = Interlocked.Increment(ref _renderGeneration);
        JefLog.Info($"StartRender: {path}");

        Task.Run(() =>
        {
            try
            {
                var bmp = JefRenderer.RenderImage(path, 1200, JefBackground.White);
                if (generation != Volatile.Read(ref _renderGeneration))
                {
                    bmp.Dispose();
                    return;
                }

                if (IsDisposed || !IsHandleCreated)
                {
                    bmp.Dispose();
                    return;
                }

                BeginInvoke(() =>
                {
                    if (IsDisposed || generation != _renderGeneration)
                    {
                        bmp.Dispose();
                        return;
                    }

                    _picture.Image?.Dispose();
                    _picture.Image = bmp;
                    JefLog.Info($"StartRender OK: {bmp.Width}x{bmp.Height}");
                });
            }
            catch (Exception ex)
            {
                JefLog.Info($"StartRender error: {ex}");
            }
        });
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            Interlocked.Increment(ref _renderGeneration);
            _picture.Image?.Dispose();
        }

        base.Dispose(disposing);
    }
}
