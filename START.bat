@echo off

REM Test internetverbinding door te pingen naar een betrouwbaar IP (Google DNS)
ping -n 1 8.8.8.8 >nul 2>&1
if %errorlevel% neq 0 (
    echo Geen internetverbinding gevonden. Controleer uw netwerkverbinding en probeer het opnieuw.
    pause
    exit /b 1
)

echo Internetverbinding gedetecteerd.

REM Verwijder bestaand PowerShell-script indien aanwezig
if exist "Tenant-join.ps1" del /f /q "Tenant-join.ps1"

REM Download PowerShell-script
echo Bezig met downloaden van PowerShell-script...
powershell -Command "try {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/SCC-ONS-Backoffice/Autopilot-join-SSC-ONS/main/Tenant-join.ps1' -Headers @{'Cache-Control'='no-cache'; 'Pragma'='no-cache'} -OutFile 'Tenant-join.ps1'} catch { Write-Host 'Fout bij het downloaden van het script.'; exit 1 }"

if not exist "Tenant-join.ps1" (
    echo Het PowerShell-script kon niet worden gedownload.
    pause
    exit /b 1
)

REM Voer PowerShell-script uit
echo Bezig met uitvoeren van PowerShell-script...
powershell -ExecutionPolicy Bypass -File .\Tenant-join.ps1
