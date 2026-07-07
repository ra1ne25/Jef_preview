#Requires -Version 5.1
<#
.SYNOPSIS
  Сборка дистрибутива и EXE-инсталлятора (Inno Setup 6).

  COM hosting не поддерживает self-contained — нужен .NET 9 Desktop Runtime на машине пользователя.
  Инсталлятор проверяет наличие runtime и предлагает скачать при отсутствии.

.PARAMETER Version
  Версия установщика (по умолчанию 1.0.0).

.EXAMPLE
  .\windows\scripts\package.ps1
  .\windows\scripts\package.ps1 -Version 1.0.1
#>
param(
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Staging = Join-Path $Root "build\installer-staging"
$Dist = Join-Path $Root "dist"
$Iss = Join-Path $Root "installer\JefPreview.iss"

Write-Host "=== JefPreview package $Version ===" -ForegroundColor Cyan

Get-Process prevhost, dllhost -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 300

if (Test-Path $Staging) { Remove-Item $Staging -Recurse -Force }
New-Item -ItemType Directory -Path $Staging -Force | Out-Null
New-Item -ItemType Directory -Path $Dist -Force | Out-Null

$publishArgs = @("-c", "Release", "-o", $Staging)

Write-Host "Publishing Shell..." -ForegroundColor Yellow
dotnet publish (Join-Path $Root "src\JefPreview.Shell\JefPreview.Shell.csproj") @publishArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Publishing Tools..." -ForegroundColor Yellow
dotnet publish (Join-Path $Root "src\JefPreview.Tools\JefPreview.Tools.csproj") @publishArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$drawing = Get-ChildItem "$env:USERPROFILE\.nuget\packages\system.drawing.common\9.0.0\lib\net9.0\System.Drawing.Common.dll" -ErrorAction SilentlyContinue
if ($drawing) {
    Copy-Item $drawing.FullName $Staging -Force
}

Get-ChildItem $Staging -Filter "*.pdb" -Recurse | Remove-Item -Force

$sizeMb = [math]::Round((Get-ChildItem $Staging -Recurse | Measure-Object Length -Sum).Sum / 1MB, 1)
Write-Host "Staging: $Staging ($sizeMb MB)" -ForegroundColor Green

$iscc = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $iscc) {
    Write-Host ""
    Write-Host "Inno Setup 6 not found. Install:" -ForegroundColor Yellow
    Write-Host "  winget install JRSoftware.InnoSetup"
    Write-Host ""
    Write-Host "Then run:" -ForegroundColor Yellow
    Write-Host "  & `"`$env:ProgramFiles(x86)\Inno Setup 6\ISCC.exe`" `"$Iss`" /DMyAppVersion=$Version"
    Write-Host ""
    Write-Host "Staging folder is ready for manual packaging." -ForegroundColor Cyan
    exit 0
}

Write-Host "Compiling installer with Inno Setup..." -ForegroundColor Yellow
& $iscc $Iss "/DMyAppVersion=$Version"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$setup = Get-ChildItem $Dist -Filter "JefPreview-$Version-win-x64-setup.exe" | Select-Object -First 1
if ($setup) {
    Write-Host ""
    Write-Host "OK: $($setup.FullName)" -ForegroundColor Green
    Write-Host "Size: $([math]::Round($setup.Length / 1MB, 1)) MB"
}
