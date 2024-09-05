@echo off

REM Test internet connection
ping -n 1 google.com >nul 2>&1
if %errorlevel% neq 0 (
    echo Geen internetverbinding gevonden. Controleer uw netwerkverbinding en probeer het opnieuw.
    exit /b 1
)

echo Internetverbinding gedetecteerd.

echo Downloading PowerShell script...
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/SCC-ONS-Backoffice/Autopilot-join-SSC-ONS/main/Tenant-join.ps1' -OutFile 'Tenant-join.ps1'"

echo Running PowerShell script...
powershell -ExecutionPolicy Bypass -File .\Tenant-join.ps1

echo Script execution complete.
