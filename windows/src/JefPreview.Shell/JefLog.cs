namespace JefPreview.Shell;

internal static class JefLog
{
    private static readonly string LogPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "JefPreview",
        "preview.log");

    static JefLog() => Info("JefPreview.Shell loaded");

    public static void Info(string message)
    {
        try
        {
            var dir = Path.GetDirectoryName(LogPath)!;
            Directory.CreateDirectory(dir);
            File.AppendAllText(LogPath, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}{Environment.NewLine}");
        }
        catch
        {
            try
            {
                var fallback = Path.Combine(Path.GetTempPath(), "JefPreview-preview.log");
                File.AppendAllText(fallback, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}{Environment.NewLine}");
            }
            catch
            {
                // ignore
            }
        }
    }
}
