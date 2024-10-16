Dit script bestaat uit een Batch bestand en powershell bestand.\
**Zet START.bat op een USBtje. Dit script haalt altijd de laatste tenant-join.ps1 op van deze github repro.**

## Beschikbare tags in tenant-join.ps1:
|Naam                                      |Tag                  |
|------------------------------------------|---------------------|
|Windows 10: Gedeelde Laptop (gedeeld)     |AUP_W10_Device_Shared|
|Windows 10: Beheerdersrechten (speciaal)  |AUP_W10_User_Special |
|Windows 10: Standaard Laptop (persoonlijk)|AUP_W10_User_Personal|
|Windows 11: Gedeelde Laptop (gedeeld)     |AUP_W11_Device_Shared|
|Windows 11: Beheerdersrechten (speciaal)  |AUP_W11_User_Special |
|Windows 11: Standaard Laptop (persoonlijk)|AUP_W11_User_Personal|

## **Werking Start.bat:**
Dit batchscript controleert of er internet is door naar Google DNS te pingen. 
Als er geen verbinding is, geeft het een foutmelding en stopt die.
Als er verbinding is, verwijdert het een bestaand PowerShell-script (Tenant-join.ps1), downloadt het een nieuwe versie van dit script van een opgegeven URL, en voert het uit. 
Als de download mislukt, stopt het met een foutmelding.

## **Werking tenant-join.ps1**
Dit PowerShell-script controleert en voert verschillende taken uit:

_**Beheerdersrechten controleren:**_
De functie Ensure-RunAsAdministrator controleert of het script met beheerdersrechten draait. Als dat niet zo is, probeert het zichzelf opnieuw te starten met verhoogde rechten.

_**Internetverbinding controleren:**_
De functie Test-InternetConnection controleert of er een werkende internetverbinding is door verbinding te maken met een specifieke URL. Bij falen probeert het dit meerdere keren.

_**Omgeving instellen:**_
Ensure-Environment stelt de PowerShell-omgeving in, installeert de NuGet-pakketprovider indien nodig, en controleert of het script Get-WindowsAutopilotInfo beschikbaar is.

_**Autopilot-informatie ophalen:**_
Get-AutopilotInfo haalt Windows Autopilot-informatie op voor een specifieke GroupTag.

_**Menu weergeven:**_
Display-Menu toont een menu waarin de gebruiker een keuze kan maken op basis van de beschikbare GroupTags. Het voert de bijbehorende actie uit op basis van de keuze.

Het script zorgt dus voor verhoogde rechten, een actieve internetverbinding, een correcte setup van de omgeving, en geeft vervolgens de mogelijkheid om Windows Autopilot-informatie op te halen.
