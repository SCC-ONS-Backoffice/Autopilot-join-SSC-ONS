# Controleer of er beheerdersrechten zijn en start opnieuw met verhoogde rechten indien nodig
function Ensure-RunAsAdministrator {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        
        if (!$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Host "Dit script vereist beheerdersrechten. Probeer opnieuw te starten als beheerder..." -ForegroundColor Yellow
            $startInfo = New-Object System.Diagnostics.ProcessStartInfo "powershell"
            $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
            $startInfo.Verb = "runas"
            [System.Diagnostics.Process]::Start($startInfo) | Out-Null
            exit
        }
    } catch {
        Write-Host "`n!! FOUT: Kan bevoegdheden niet controleren of verhogen. Voer het script als beheerder uit. !!" -ForegroundColor Red
        Read-Host "`nDruk op ENTER om af te sluiten..."
        exit
    }
}

# Schakel strikte foutafhandeling in
$ErrorActionPreference = "Stop"

# Functie om te testen op een actieve internetverbinding met automatische herhaling
function Test-InternetConnection {
    param (
        [int]$retries = 3,
        [int]$delay = 5
    )

    $url = "http://www.msftconnecttest.com/connecttest.txt"
    
    for ($i = 1; $i -le $retries; $i++) {
        try {
            Write-Host "Controleren op een actieve internetverbinding... (Poging $i van $retries)" -ForegroundColor Cyan
            $request = [System.Net.WebRequest]::Create($url)
            $request.Timeout = 5000
            $request.Method = "HEAD"
            $request.GetResponse().Close()
            return $true
        } catch {
            Write-Host "Geen internetverbinding gedetecteerd. Probeer opnieuw over $delay seconden..." -ForegroundColor Yellow
            Start-Sleep -Seconds $delay
        }
    }

    Write-Host "`n!! FOUT: Geen internetverbinding gedetecteerd na meerdere pogingen. !!" -ForegroundColor Red
    return $false
}

# Functie om ervoor te zorgen dat de NuGet-pakketprovider en het script zijn geinstalleerd
# Functie om ervoor te zorgen dat de NuGet-pakketprovider en het script zijn geinstalleerd
function Ensure-Environment {
    try {
        Write-Host "`nDe omgeving instellen..." -ForegroundColor Cyan
        
        # Stel het uitvoeringsbeleid in voor de sessie
        Set-ExecutionPolicy Bypass -Scope Process -Force
        
        # Stel het beveiligingsprotocol in op TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Zorg ervoor dat de NuGet-pakketprovider is geinstalleerd
        Write-Host "Zorgen dat NuGet-pakketprovider is geinstalleerd..." -ForegroundColor Cyan
        if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -ForceBootstrap -Force -Confirm:$false
            Write-Host "NuGet-pakketprovider geinstalleerd." -ForegroundColor Green
        } else {
            Write-Host "NuGet-pakketprovider is al geinstalleerd." -ForegroundColor Green
        }

        # Stel de PSGallery repository in op Trusted
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
        Write-Host "PSGallery repository is ingesteld als Trusted." -ForegroundColor Green

        # Zorg ervoor dat het Get-WindowsAutopilotInfo-script is geinstalleerd
        Write-Host "Zorgen dat het Get-WindowsAutopilotInfo-script is geinstalleerd..." -ForegroundColor Cyan
        if (-not (Get-Command -Name Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
            Install-Script -Name Get-WindowsAutopilotInfo -Force
            Write-Host "Get-WindowsAutopilotInfo-script geinstalleerd." -ForegroundColor Green
        } else {
            Write-Host "Get-WindowsAutopilotInfo-script is al geinstalleerd." -ForegroundColor Green
        }
    } catch {
        Write-Host "`n!! FOUT: De omgeving instellen is mislukt. $($_.Exception.Message) !!" -ForegroundColor Red
        exit
    }
}

# Functie om Windows Autopilot-informatie op te halen op basis van GroupTag
function Get-AutopilotInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string] $GroupTag
    )

    try {
        Write-Host "`nWindows Autopilot-informatie ophalen voor GroupTag: $GroupTag" -ForegroundColor Cyan
        Get-WindowsAutopilotInfo -Online -GroupTag $GroupTag
        Write-Host "`nVoltooid ophalen van Autopilot-informatie." -ForegroundColor Green
    } catch {
        Write-Host "`n!! FOUT: Het ophalen van Autopilot-informatie is mislukt. $($_.Exception.Message) !!" -ForegroundColor Red
    }
}

# Functie om het menu weer te geven en gebruikersinvoer te verwerken
function Display-Menu {
    param (
        [hashtable]$groupTags
    )

    do {
        Clear-Host
        Write-Host "`nMaak een keuze:`n" -ForegroundColor Cyan

        foreach ($key in $groupTags.Keys | Sort-Object) {
            $groupTag = $groupTags[$key]
            Write-Host ("{0}: {1}" -f $key, $groupTag.Name) -ForegroundColor $groupTag.Color
        }

        $choice = Read-Host -Prompt 'Uw keuze'

        if ($choice -eq 'H') {
            Show-Help
        } elseif ($groupTags.ContainsKey($choice)) {
            Get-AutopilotInfo -GroupTag $groupTags[$choice].GroupTag
            break
        } else {
            Write-Host "`n!! FOUT: Ongeldige invoer. Voer een nummer in dat overeenkomt met uw keuze. !!" -ForegroundColor Red
            Read-Host "`nDruk op ENTER om opnieuw te proberen..."
        }
    } while ($true)
}

# Functie om helpinformatie weer te geven
function Show-Help {
    Clear-Host
    Write-Host "`nHelp - Uitleg van opties:`n" -ForegroundColor Yellow
    foreach ($key in $groupTags.Keys | Sort-Object) {
        $groupTag = $groupTags[$key]
        Write-Host ("{0}: {1} - {2}" -f $key, $groupTag.Name, $groupTag.Description) -ForegroundColor $groupTag.Color
    }
    Read-Host "`nDruk op ENTER om terug te keren naar het hoofdmenu..."
}

# Groeptags definieren in een apart gedeelte voor eenvoudige aanpassing
$groupTags = @{
    "1" = @{ Name = "Windows 10: Standaard Laptop (persoonlijk)"; GroupTag = "AUP_W10_User_Personal"; Color = "Red"; Description = "Autopilot-instelling voor een persoonlijke gebruiker" }
    "2" = @{ Name = "Windows 10: Gedeelde Laptop (gedeeld)"; GroupTag = "AUP_W10_Device_Shared"; Color = "Red"; Description = "Autopilot-instelling voor gedeelde apparaten" }
    "3" = @{ Name = "Windows 10: Beheerdersrechten (speciaal)"; GroupTag = "AUP_W10_User_Special"; Color = "Red"; Description = "Autopilot-instelling voor beheerdersgebruikers" }
    "4" = @{ Name = "Windows 11: Standaard Laptop (persoonlijk)"; GroupTag = "AUP_W11_User_Personal"; Color = "Green"; Description = "Autopilot-instelling voor een persoonlijke gebruiker" }
    "5" = @{ Name = "Windows 11: Gedeelde Laptop (gedeeld)"; GroupTag = "AUP_W11_Device_Shared"; Color = "Green"; Description = "Autopilot-instelling voor gedeelde apparaten" }
    "6" = @{ Name = "Windows 11: Beheerdersrechten (speciaal)"; GroupTag = "AUP_W11_User_Special"; Color = "Green"; Description = "Autopilot-instelling voor beheerdersgebruikers" }
    "H" = @{ Name = "Help - Uitleg van opties"; GroupTag = ""; Color = "Yellow"; Description = "Toont dit helpmenu" }
}

# Hoofdscriptuitvoering
Ensure-RunAsAdministrator

if (-not (Test-InternetConnection)) {
    Read-Host "`nDruk op ENTER om af te sluiten..."
    exit
}

Ensure-Environment
Display-Menu -groupTags $groupTags

# Pauzeren voordat u afsluit
Read-Host "`nDruk op ENTER om door te gaan..."
