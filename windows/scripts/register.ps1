#Requires -Version 5.1
#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Tools = Join-Path $Root "build\JefPreview.Tools.exe"
$Comhost = Join-Path $Root "build\JefPreview.Shell.comhost.dll"

if (-not (Test-Path $Tools)) {
    $Tools = Join-Path $Root "src\JefPreview.Tools\bin\Release\net9.0-windows\JefPreview.Tools.exe"
}

if (-not (Test-Path $Tools)) {
    Write-Error "Run .\windows\scripts\build.ps1 first"
}

Write-Host "Stopping preview host processes..." -ForegroundColor Yellow
Get-Process prevhost, dllhost -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 800

if (Test-Path $Comhost) {
    Write-Host "Registering COM host (regsvr32)..." -ForegroundColor Yellow
    $p = Start-Process -FilePath "$env:SystemRoot\System32\regsvr32.exe" -ArgumentList "/s `"$Comhost`"" -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0) {
        Write-Host "  ! regsvr32 exit code $($p.ExitCode) - continuing with manual registration" -ForegroundColor Yellow
    }
}

& $Tools register
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "COM diagnostics:" -ForegroundColor Cyan
& $Tools diag

Write-Host ""
Write-Host "Restarting Explorer..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
Start-Process explorer

Write-Host ""
Write-Host "Log: $env:LOCALAPPDATA\JefPreview\preview.log"
