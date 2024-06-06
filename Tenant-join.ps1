# Check for administrative privileges and relaunch with elevated rights if necessary
function Ensure-RunAsAdministrator {
    try {
        if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            $newProcess = New-Object System.Diagnostics.ProcessStartInfo "powershell";
            $newProcess.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"";
            $newProcess.Verb = "runas";
            [System.Diagnostics.Process]::Start($newProcess);
            exit;
        }
    } catch {
        Write-Host "`n!! ERROR: Unable to check or elevate privileges. !!" -ForegroundColor Red
        Read-Host "`nPress ENTER to exit..."
        exit
    }
}
Ensure-RunAsAdministrator

# Enable strict error handling
$ErrorActionPreference = "Stop"

# Test for an active internet connection
function Test-InternetConnection {
    try {
        $webRequest = [System.Net.WebRequest]::Create("http://www.msftconnecttest.com/connecttest.txt")
        $webRequest.Timeout = 5000
        $webResponse = $webRequest.GetResponse()
        $webResponse.Close()
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-InternetConnection)) {
    Write-Host "`n!! ERROR: No internet connection detected. Please check your network settings and try again. !!" -ForegroundColor Red
    Read-Host "`nPress ENTER to exit..."
    exit
}

try {
    # Set execution policy for the session
    Set-ExecutionPolicy Bypass -Scope Process -Force

    # Set security protocol to TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Install the necessary package provider and script
    Install-PackageProvider -Name NuGet -Force -Confirm:$false
    Install-Script -Name Get-WindowsAutopilotinfo -Force

    # Define a function to get Windows Autopilot info
    function Get-AutopilotInfo {
        param (
            [Parameter(Mandatory=$true)]
            [string] $GroupTag
        )
        Get-WindowsAutopilotInfo -Online -GroupTag $GroupTag
    }

    # Define group tags in a separate section for easy modification
    $groupTags = @{
        "1" = @{ Name = "Windows 10: Standard Laptop (personal)"; GroupTag = "AUP_W10_User_Personal"; Color = "Red" }
        "2" = @{ Name = "Windows 10: Shared Laptop (shared)"; GroupTag = "AUP_W10_Device_Shared"; Color = "Red" }
        "3" = @{ Name = "Windows 10: Admin Rights (special)"; GroupTag = "AUP_W10_User_Special"; Color = "Red" }
        "4" = @{ Name = "Windows 11: Standard Laptop (personal)"; GroupTag = "AUP_W11_User_Personal"; Color = "Green" }
        "5" = @{ Name = "Windows 11: Shared Laptop (shared)"; GroupTag = "AUP_W11_Device_Shared"; Color = "Green" }
        "6" = @{ Name = "Windows 11: Admin Rights (special)"; GroupTag = "AUP_W11_User_Special"; Color = "Green" }
    }

    # Display menu and prompt user until a valid input is received
    do {
        Clear-Host
        Write-Host "`nPlease choose an option:`n" -ForegroundColor Cyan

        foreach ($key in $groupTags.Keys | Sort-Object) {
            $groupTag = $groupTags[$key]
            Write-Host ("{0}: {1}" -f $key, $groupTag.Name) -ForegroundColor $groupTag.Color
        }

        $choice = Read-Host -Prompt 'Your choice'

        if ($groupTags.ContainsKey($choice)) {
            Get-AutopilotInfo -GroupTag $groupTags[$choice].GroupTag
            break
        } else {
            Write-Host "`n!! ERROR: Invalid input. Please try again. !!" -ForegroundColor Red
            Read-Host "`nPress ENTER to try again..."
        }
    } while ($true)

} catch {
    Write-Host "`n!! ERROR: $($_.Exception.Message) !!" -ForegroundColor Red
    Read-Host "`nPress ENTER to exit..."
}

# Pause before exiting
Read-Host "`nPress ENTER to continue..."
