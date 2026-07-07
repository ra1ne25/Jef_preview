using System.Runtime.InteropServices;
using SharpShell.Attributes;
using SharpShell.SharpPreviewHandler;

namespace JefPreview.Shell;

[ComVisible(true)]
[Guid("C9F5A3B2-4D6E-5F70-AB1C-2D3E4F5A6B7C")]
[PreviewHandler(DisableLowILProcessIsolation = true, SurrogateHostType = SurrogateHostType.DedicatedPrevhost)]
[DisplayName("JefPreview Preview Handler")]
[ServerType(SharpShell.ServerType.ShellPreviewHander)]
[COMServerAssociation(AssociationType.ClassOfExtension, ".jef")]
public sealed class JefPreviewHandler : SharpPreviewHandler
{
    protected override PreviewHandlerControl DoPreview()
    {
        JefLog.Info($"DoPreview: SelectedFilePath={SelectedFilePath ?? "<null>"}");
        var control = new JefPreviewControl();
        control.BindPath(SelectedFilePath);
        return control;
    }
}
