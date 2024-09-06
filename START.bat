@echo off

REM Test internet connection by pinging a reliable IP (Google DNS)
ping -n 1 8.8.8.8 >nul 2>&1
if %errorlevel% neq 0 (
    echo Geen internetverbinding gevonden. Controleer uw netwerkverbinding en probeer het opnieuw.
    pause
    exit /b 1
)

echo Internetverbinding gedetecteerd.

REM Download PowerShell script
echo Downloading PowerShell script...
powershell -Command "try {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/SCC-ONS-Backoffice/Autopilot-join-SSC-ONS/main/Tenant-join.ps1' -OutFile 'Tenant-join.ps1'} catch { Write-Host 'Fout bij het downloaden van het script.'; exit 1 }"

if not exist "Tenant-join.ps1" (
    echo Het PowerShell-script kon niet worden gedownload.
    pause
    exit /b 1
)

REM Run PowerShell script
echo Running PowerShell script...
powershell -ExecutionPolicy Bypass -File .\Tenant-join.ps1

echo Script execution complete.
pause
