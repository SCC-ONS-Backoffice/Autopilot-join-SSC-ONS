@echo off
setlocal

:: Verwijder het oude PowerShell-script als het bestaat
if exist "Tenant-join.ps1" (
    echo Verwijderen van oude versie van Tenant-join.ps1...
    del /f "Tenant-join.ps1" || (
        echo Fout bij het verwijderen van de oude versie van het script. Foutcode: %ERRORLEVEL%
        endlocal
        exit /b %ERRORLEVEL%
    )
)

echo Bezig met het downloaden van het nieuwste PowerShell-script...

:: Download het PowerShell-script
powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/SCC-ONS-Backoffice/Autopilot-join-SSC-ONS/main/Tenant-join.ps1' -OutFile 'Tenant-join.ps1' -UseBasicParsing; exit $LASTEXITCODE } catch { Write-Error 'Download van script mislukt.'; exit 1 }" 
set "ERRORCODE=%ERRORLEVEL%"
if %ERRORCODE% neq 0 (
    echo Fout bij het downloaden van het PowerShell-script. Foutcode: %ERRORCODE%
    endlocal
    exit /b %ERRORCODE%
)

:: Controleer of het script succesvol is gedownload
if not exist "Tenant-join.ps1" (
    echo Het gedownloade PowerShell-script werd niet gevonden.
    endlocal
    exit /b 1
)

echo PowerShell-script uitvoeren...

:: Voer het gedownloade PowerShell-script uit met omzeilde uitvoering
powershell -ExecutionPolicy Bypass -File .\Tenant-join.ps1
set "ERRORCODE=%ERRORLEVEL%"
if %ERRORCODE% neq 0 (
    echo Fout bij het uitvoeren van het PowerShell-script. Foutcode: %ERRORCODE%
    endlocal
    exit /b %ERRORCODE%
)

echo Scriptuitvoering voltooid.

:: Einde script
endlocal
exit /b 0
