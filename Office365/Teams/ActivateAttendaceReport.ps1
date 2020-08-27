# Required module to install -> https://www.microsoft.com/download/details.aspx?id=39366

Import-Module SkypeOnlineConnector
$adminCred = Get-Credential
$session = New-CsOnlineSession -Credential $adminCred
Import-PSSession $session


# download report solo per chi ha programmato la riunione
Set-CsTeamsMeetingPolicy -AllowEngagementReport Enabled

# download report per tutti i relatori e partecipanti
Set-CsTeamsMeetingPolicy -Identity Global AllowEngagementReport Enabled
