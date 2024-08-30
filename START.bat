@echo off
setlocal

echo Downloading PowerShell script...

:: Download the PowerShell script
powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/SCC-ONS-Backoffice/Autopilot-join-SSC-ONS/main/Tenant-join.ps1' -OutFile 'Tenant-join.ps1'; exit $LASTEXITCODE } catch { Write-Error 'Failed to download script.'; exit 1 }"
if %ERRORLEVEL% neq 0 (
    echo Failed to download the PowerShell script.
    exit /b %ERRORLEVEL%
)

echo Running PowerShell script...

:: Execute the downloaded PowerShell script with bypassed execution policy
powershell -ExecutionPolicy Bypass -File .\Tenant-join.ps1
if %ERRORLEVEL% neq 0 (
    echo PowerShell script execution failed.
    exit /b %ERRORLEVEL%
)

echo Script execution complete.

:: End script
endlocal
exit /b 0
