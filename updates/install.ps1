# Daps Working Drawing Auto for Revit - quick installer (no .exe, so Windows SmartScreen won't block it)
# Run in PowerShell:
#   irm https://raw.githubusercontent.com/DA2028/daps-revit-working-drawing-auto/main/updates/install.ps1 | iex
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$feed = "https://raw.githubusercontent.com/DA2028/daps-revit-working-drawing-auto/main/updates"
$version = (Invoke-WebRequest -UseBasicParsing "$feed/version.txt").Content.Trim()
Write-Host "Daps Working Drawing Auto v$version" -ForegroundColor Cyan

$addin = @'
<?xml version="1.0" encoding="utf-8"?>
<RevitAddIns>
  <AddIn Type="Application">
    <Name>Daps Working Drawing Auto for Revit</Name>
    <Assembly>RevitWorkingDrawingPlugin.dll</Assembly>
    <AddInId>8D92A1E4-4B76-4C19-9F1A-6E7D5C4B3A21</AddInId>
    <FullClassName>RevitWorkingDrawingPlugin.App</FullClassName>
    <VendorId>DAPS</VendorId>
    <VendorDescription>Daps Working Drawing Auto for Revit - Created by Daps</VendorDescription>
  </AddIn>
</RevitAddIns>
'@

$count = 0
foreach ($y in "2021", "2022", "2023", "2024") {
    if (-not (Test-Path "C:\Program Files\Autodesk\Revit $y")) { continue }
    $dir = Join-Path $env:APPDATA "Autodesk\Revit\Addins\$y"
    New-Item -ItemType Directory -Force $dir | Out-Null
    $dll = Join-Path $dir "RevitWorkingDrawingPlugin.dll"
    $tmp = "$dll.download"
    Invoke-WebRequest -UseBasicParsing "$feed/$y/RevitWorkingDrawingPlugin.dll" -OutFile $tmp
    $want = (Invoke-WebRequest -UseBasicParsing "$feed/$y/RevitWorkingDrawingPlugin.dll.sha256").Content.Trim()
    if ((Get-FileHash $tmp -Algorithm SHA256).Hash -ne $want.ToUpper()) { Remove-Item $tmp; throw "Download check failed for Revit $y. Try again." }
    if (Test-Path $dll) { try { Remove-Item $dll } catch { Rename-Item $dll ("RevitWorkingDrawingPlugin.dll.old-" + (Get-Date).Ticks) } }
    Move-Item $tmp $dll
    [IO.File]::WriteAllText((Join-Path $dir "RevitWorkingDrawingPlugin.addin"), $addin)
    Write-Host "  Installed for Revit $y" -ForegroundColor Green
    $count++
}

if ($count -eq 0) { Write-Host "No Revit 2021-2024 found in C:\Program Files\Autodesk." -ForegroundColor Yellow }
else { Write-Host "`nDone! Open (or restart) Revit and look for the 'Daps Working Drawing Auto' tab. Updates install automatically." -ForegroundColor Cyan }
