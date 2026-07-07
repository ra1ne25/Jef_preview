#Requires -Version 5.1
#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"
$Scripts = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== JefPreview reinstall ===" -ForegroundColor Cyan
& (Join-Path $Scripts "build.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& (Join-Path $Scripts "unregister.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& (Join-Path $Scripts "register.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Done." -ForegroundColor Green
