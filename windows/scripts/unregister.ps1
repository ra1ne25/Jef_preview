#Requires -Version 5.1
#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Tools = Join-Path $Root "build\JefPreview.Tools.exe"

if (-not (Test-Path $Tools)) {
    $Tools = Join-Path $Root "src\JefPreview.Tools\bin\Release\net9.0-windows\JefPreview.Tools.exe"
}

& $Tools unregister
