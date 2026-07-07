using JefPreview.Core;
using JefPreview.Tools;

if (!OperatingSystem.IsWindows())
{
    Console.Error.WriteLine("JefPreview.Tools поддерживается только на Windows.");
    return 1;
}

if (args.Length == 0)
{
    PrintUsage();
    return 1;
}

var command = args[0].ToLowerInvariant();
return command switch
{
    "register" => RegisterHandlers(),
    "unregister" => UnregisterHandlers(),
    "render" => RenderFile(args),
    "diag" => ComDiagnostics.Run(),
    _ => PrintUsage()
};

static int RegisterHandlers()
{
    try
    {
        ShellRegistrar.Register();
        Console.WriteLine($"  COM host: {ShellRegistrar.ComHostPath}");
        Console.WriteLine("  + .jef preview and thumbnail handlers");
        Console.WriteLine("JefPreview зарегистрирован. Перезапустите Проводник (explorer.exe).");
        return 0;
    }
    catch (Exception ex)
    {
        Console.Error.WriteLine($"Ошибка регистрации: {ex.Message}");
        Console.Error.WriteLine("Запустите от имени администратора.");
        return 1;
    }
}

static int UnregisterHandlers()
{
    try
    {
        ShellRegistrar.Unregister();
        Console.WriteLine("JefPreview удалён из реестра.");
        return 0;
    }
    catch (Exception ex)
    {
        Console.Error.WriteLine($"Ошибка: {ex.Message}");
        return 1;
    }
}

static int RenderFile(string[] args)
{
    if (args.Length < 3)
    {
        Console.Error.WriteLine("Использование: render <input.jef> <output.png> [size]");
        return 1;
    }

    var input = args[1];
    var output = args[2];
    var size = args.Length > 3 && int.TryParse(args[3], out var s) ? s : 512;

    try
    {
        var png = JefRenderer.RenderPng(input, size, JefBackground.White);
        var outPath = Path.GetFullPath(output);
        File.WriteAllBytes(outPath, png);
        Console.WriteLine($"OK: {outPath} ({png.Length} bytes)");
        return 0;
    }
    catch (Exception ex)
    {
        Console.Error.WriteLine(ex.Message);
        return 1;
    }
}

static int PrintUsage()
{
    Console.WriteLine("""
        JefPreview.Tools — утилита для Windows

        register              зарегистрировать shell extension (от админа)
        unregister            удалить регистрацию
        diag                  проверить COM и реестр
        render <in> <out> [n] отрендерить .jef в PNG (тест без Проводника)
        """);
    return 1;
}
