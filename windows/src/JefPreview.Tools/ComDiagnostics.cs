using System.Runtime.InteropServices;
using Microsoft.Win32;

namespace JefPreview.Tools;

internal static class ComDiagnostics
{
    private static readonly (string Name, string Clsid)[] Handlers =
    {
        ("Preview", "C9F5A3B2-4D6E-5F70-AB1C-2D3E4F5A6B7C"),
        ("Thumbnail", "B8E4F2A1-3C5D-4E6F-9A0B-1C2D3E4F5A6B"),
    };

    public static int Run()
    {
        Console.WriteLine("=== JefPreview diag ===");
        Console.WriteLine($"Comhost: {ShellRegistrar.ComHostPath}");
        Console.WriteLine($"Exists:  {File.Exists(ShellRegistrar.ComHostPath)}");
        Console.WriteLine($"Shell.dll: {File.Exists(Path.Combine(ShellRegistrar.ShellDirectory, "JefPreview.Shell.dll"))}");
        Console.WriteLine($"deps.json: {File.Exists(Path.Combine(ShellRegistrar.ShellDirectory, "JefPreview.Shell.deps.json"))}");
        Console.WriteLine($"runtimeconfig: {File.Exists(Path.Combine(ShellRegistrar.ShellDirectory, "JefPreview.Shell.runtimeconfig.json"))}");
        Console.WriteLine();

        foreach (var (name, clsid) in Handlers)
        {
            var path = $@"SOFTWARE\Classes\CLSID\{{{clsid}}}\InprocServer32";
            using var key = Registry.LocalMachine.OpenSubKey(path);
            Console.WriteLine($"{name} InprocServer32: {key?.GetValue("") ?? "<missing>"}");

            try
            {
                var type = Type.GetTypeFromCLSID(Guid.Parse(clsid), throwOnError: true);
                Console.WriteLine($"{name} Type: {type?.FullName ?? "<null>"}");
                var obj = Activator.CreateInstance(type!);
                Console.WriteLine($"{name} CreateInstance: OK ({obj.GetType().FullName})");
                if (obj is IDisposable d)
                    d.Dispose();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"{name} CreateInstance: FAIL — {ex.Message}");
            }
        }

        var log = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "JefPreview", "preview.log");
        Console.WriteLine();
        Console.WriteLine($"Log: {log}");
        Console.WriteLine(File.Exists(log) ? File.ReadAllText(log) : "(log not created yet — handler not loaded by Explorer)");
        return 0;
    }
}
