using System.Diagnostics;
using Microsoft.Win32;

namespace JefPreview.Tools;

internal static class ShellRegistrar
{
    private const string ProgId = "JefPreview.JefFile";
    private const string Extension = ".jef";
    private const string PreviewClsid = "C9F5A3B2-4D6E-5F70-AB1C-2D3E4F5A6B7C";
    private const string ThumbnailClsid = "B8E4F2A1-3C5D-4E6F-9A0B-1C2D3E4F5A6B";
    private const string PreviewHandlerKey = "8895b1c6-b41f-4c1c-a562-0d851310588d";
    private const string ThumbnailHandlerKey = "e357fccd-a995-4576-b01f-234630154e96";

    private static string ClassesRoot => @"SOFTWARE\Classes";

    public static string ShellDirectory
    {
        get
        {
            var dll = typeof(JefPreview.Shell.JefThumbnailHandler).Assembly.Location;
            return Path.GetDirectoryName(dll)
                   ?? throw new InvalidOperationException("Не удалось определить каталог JefPreview.Shell.dll");
        }
    }

    public static string ComHostPath => Path.Combine(ShellDirectory, "JefPreview.Shell.comhost.dll");

    public static void Register()
    {
        if (!File.Exists(ComHostPath))
            throw new FileNotFoundException("JefPreview.Shell.comhost.dll не найден — пересоберите проект", ComHostPath);

        if (!TryRegsvr32(unregister: false))
            Console.WriteLine("  ! regsvr32 пропущен — используется ручная регистрация COM");

        using (var ext = Registry.LocalMachine.CreateSubKey($@"{ClassesRoot}\{Extension}", true))
            ext.SetValue("", ProgId);

        // shellex на ProgID и напрямую на расширение (надёжнее для Проводника)
        RegisterShellEx($@"{ClassesRoot}\{ProgId}\shellex");
        RegisterShellEx($@"{ClassesRoot}\{Extension}\shellex");
        RegisterProgId();

        var dedicatedAppId = GetDedicatedAppId(PreviewClsid);
        RegisterDedicatedPrevhost(dedicatedAppId);

        using (var clsid = Registry.LocalMachine.CreateSubKey($@"{ClassesRoot}\CLSID\{{{PreviewClsid}}}", true))
        {
            clsid.SetValue("", "JefPreview Preview Handler");
            clsid.SetValue("AppID", $"{{{dedicatedAppId}}}");
            clsid.SetValue("DisplayName", "JefPreview Preview Handler");
            clsid.SetValue("DisableLowILProcessIsolation", 1, RegistryValueKind.DWord);
            using var inproc = clsid.OpenSubKey("InprocServer32", true)
                ?? clsid.CreateSubKey("InprocServer32", true);
            inproc.SetValue("", ComHostPath);
            inproc.SetValue("ThreadingModel", "Apartment");
        }

        using (var clsid = Registry.LocalMachine.CreateSubKey($@"{ClassesRoot}\CLSID\{{{ThumbnailClsid}}}", true))
        {
            clsid.SetValue("", "JefPreview Thumbnail Handler");
            using var inproc = clsid.OpenSubKey("InprocServer32", true)
                ?? clsid.CreateSubKey("InprocServer32", true);
            inproc.SetValue("", ComHostPath);
            inproc.SetValue("ThreadingModel", "Apartment");
        }

        using (var handlers = Registry.LocalMachine.CreateSubKey(
                   @"SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers", true))
            handlers.SetValue(PreviewClsid, "JefPreview Preview Handler");

        using (var approved = Registry.LocalMachine.CreateSubKey(
                   @"SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved", true))
        {
            approved.SetValue(PreviewClsid, "JefPreview Preview Handler");
            approved.SetValue(ThumbnailClsid, "JefPreview Thumbnail Handler");
        }
    }

    public static void Unregister()
    {
        TryRegsvr32(unregister: true);

        var dedicatedAppId = GetDedicatedAppId(PreviewClsid);
        Registry.LocalMachine.DeleteSubKeyTree($@"{ClassesRoot}\AppID\{{{dedicatedAppId}}}", false);
        Registry.LocalMachine.DeleteSubKeyTree($@"{ClassesRoot}\CLSID\{{{PreviewClsid}}}", false);
        Registry.LocalMachine.DeleteSubKeyTree($@"{ClassesRoot}\CLSID\{{{ThumbnailClsid}}}", false);
        Registry.LocalMachine.DeleteSubKeyTree($@"{ClassesRoot}\{Extension}", false);
        Registry.LocalMachine.DeleteSubKeyTree($@"{ClassesRoot}\{ProgId}", false);
        TryDelete($@"{ClassesRoot}\{Extension}\shellex\{PreviewHandlerKey}");
        TryDelete($@"{ClassesRoot}\{Extension}\shellex\{ThumbnailHandlerKey}");

        using (var handlers = Registry.LocalMachine.OpenSubKey(
                   @"SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers", true))
            handlers?.DeleteValue(PreviewClsid, false);

        using (var approved = Registry.LocalMachine.OpenSubKey(
                   @"SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved", true))
        {
            approved?.DeleteValue(PreviewClsid, false);
            approved?.DeleteValue(ThumbnailClsid, false);
        }
    }

    private static void RegisterShellEx(string shellexRoot)
    {
        using var root = Registry.LocalMachine.CreateSubKey(shellexRoot, true);
        using (var preview = root.CreateSubKey(PreviewHandlerKey, true))
            preview.SetValue("", $"{{{PreviewClsid}}}");
        using (var thumb = root.CreateSubKey(ThumbnailHandlerKey, true))
            thumb.SetValue("", $"{{{ThumbnailClsid}}}");
    }

    private static void RegisterProgId()
    {
        using var prog = Registry.LocalMachine.CreateSubKey($@"{ClassesRoot}\{ProgId}", true);
        prog.SetValue("", "Janome embroidery file (.jef)");
    }

    private static void TryDelete(string subKey)
    {
        try { Registry.LocalMachine.DeleteSubKey(subKey, false); } catch { /* ignore */ }
    }

    private static string GetDedicatedAppId(string clsid)
    {
        var guid = Guid.Parse(clsid);
        var bytes = guid.ToByteArray();
        bytes[15] = unchecked((byte)(bytes[15] + 1));
        return new Guid(bytes).ToString("D").ToUpperInvariant();
    }

    private static void RegisterDedicatedPrevhost(string appId)
    {
        using var app = Registry.LocalMachine.CreateSubKey($@"{ClassesRoot}\AppID\{{{appId}}}", true);
        app.SetValue("DllSurrogate", @"%SystemRoot%\system32\prevhost.exe", RegistryValueKind.ExpandString);
    }

    private static bool TryRegsvr32(bool unregister)
    {
        if (!File.Exists(ComHostPath))
            return false;

        try
        {
            var args = unregister ? $"/u /s \"{ComHostPath}\"" : $"/s \"{ComHostPath}\"";
            using var process = Process.Start(new ProcessStartInfo("regsvr32", args)
            {
                UseShellExecute = false,
                CreateNoWindow = true
            });
            if (process == null)
                return false;

            process.WaitForExit();
            return process.ExitCode == 0;
        }
        catch
        {
            return false;
        }
    }
}
