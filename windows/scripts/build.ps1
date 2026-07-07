#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "Building JefPreview (Windows)..." -ForegroundColor Cyan
Get-Process prevhost, dllhost -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

$Out = Join-Path $Root "build"
if (Test-Path $Out) { Remove-Item $Out -Recurse -Force }

dotnet publish "$Root\src\JefPreview.Shell\JefPreview.Shell.csproj" -c Release -o $Out
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

dotnet publish "$Root\src\JefPreview.Tools\JefPreview.Tools.csproj" -c Release -o $Out
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$drawing = Get-ChildItem "$env:USERPROFILE\.nuget\packages\system.drawing.common\9.0.0\lib\net9.0\System.Drawing.Common.dll" -ErrorAction SilentlyContinue
if ($drawing) {
    Copy-Item $drawing.FullName $Out -Force
}

Write-Host ""
Write-Host "OK: $Out" -ForegroundColor Green
Write-Host ""
Write-Host "Register (run as Administrator):"
Write-Host "  .\windows\scripts\register.ps1"
Write-Host ""
Write-Host "Render test:"
Write-Host "  .\windows\build\JefPreview.Tools.exe render file.jef out.png"
