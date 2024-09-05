# Controleer of er beheerdersrechten zijn en start opnieuw met verhoogde rechten indien nodig
function Ensure-RunAsAdministrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Dit script vereist beheerdersrechten. Probeer opnieuw te starten als beheerder..." -ForegroundColor Yellow
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
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
            $response = $request.GetResponse()
            $response.Close()
            return $true
        } catch {
            Write-Host "Geen internetverbinding gedetecteerd. Probeer opnieuw over $delay seconden..." -ForegroundColor Yellow
            Start-Sleep -Seconds $delay
        }
    }

    Write-Host "!! FOUT: Geen internetverbinding gedetecteerd na meerdere pogingen. !!" -ForegroundColor Red
    return $false
}

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
        if (-not (Get-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -Force -Confirm:$false
            Write-Host "NuGet-pakketprovider geinstalleerd." -ForegroundColor Green
        } else {
            Write-Host "NuGet-pakketprovider is al geinstalleerd." -ForegroundColor Green
        }

        # Zorg ervoor dat het Get-WindowsAutopilotInfo-script is geinstalleerd
        Write-Host "Zorgen dat het Get-WindowsAutopilotInfo-script is geinstalleerd..." -ForegroundColor Cyan
        if (-not (Get-InstalledScript -Name Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
            Install-Script -Name Get-WindowsAutopilotInfo -Force -Confirm:$false
            Write-Host "Get-WindowsAutopilotInfo-script geinstalleerd." -ForegroundColor Green
        } else {
            Write-Host "Get-WindowsAutopilotInfo-script is al geinstalleerd." -ForegroundColor Green
        }
    } catch {
        Write-Host "!! FOUT: De omgeving instellen is mislukt. $($_.Exception.Message) !!" -ForegroundColor Red
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
        Write-Host "Windows Autopilot-informatie ophalen voor GroupTag: $GroupTag" -ForegroundColor Cyan
        Get-WindowsAutopilotInfo -Online -GroupTag $GroupTag
        Write-Host "Voltooid ophalen van Autopilot-informatie." -ForegroundColor Green
    } catch {
        Write-Host "!! FOUT: Het ophalen van Autopilot-informatie is mislukt. $($_.Exception.Message) !!" -ForegroundColor Red
    }
}

# Functie om het menu weer te geven en gebruikersinvoer te verwerken
function Display-Menu {
    param (
        [hashtable]$groupTags
    )

    do {
        Clear-Host
        Write-Host "Maak een keuze:" -ForegroundColor Cyan

        foreach ($key in $groupTags.Keys | Sort-Object) {
            $groupTag = $groupTags[$key]
            Write-Host ("{0}: {1}" -f $key, $groupTag.Name) -ForegroundColor $groupTag.Color
        }

        $choice = Read-Host -Prompt 'Uw keuze'

        if ($choice -eq 'H') {
            Show-Help
        } elseif ($groupTags.ContainsKey($choice)) {
            Clear-Host
            Get-AutopilotInfo -GroupTag $groupTags[$choice].GroupTag
            break
        } else {
            Write-Host "!! FOUT: Ongeldige invoer. Voer een nummer in dat overeenkomt met uw keuze. !!" -ForegroundColor Red
            Read-Host "Druk op ENTER om opnieuw te proberen..."
        }
    } while ($true)
}

# Functie om helpinformatie weer te geven
function Show-Help {
    Clear-Host
    Write-Host "Help - Uitleg van opties:`n" -ForegroundColor Yellow
    foreach ($key in $groupTags.Keys | Sort-Object) {
        $groupTag = $groupTags[$key]
        Write-Host ("{0}: {1} - {2}" -f $key, $groupTag.Name, $groupTag.Description) -ForegroundColor $groupTag.Color
    }
    Read-Host "Druk op ENTER om terug te keren naar het hoofdmenu..."
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
    Read-Host "Druk op ENTER om af te sluiten..."
    exit
}

Ensure-Environment
Display-Menu -groupTags $groupTags

# Pauzeren voordat u afsluit
Read-Host "Druk op ENTER om af te sluiten..."
