# PARAMETRI #

$teamNameA = "<TEAM ALIAS>"
$teamDisplayNameA = "<TEAM NAME>"

$teamNameB = "<TEAM ALIAS>"
$teamDisplayNameB = "<TEAM NAME>"

$des = "<TEAM DESCRIPTION>"
$vis = "<TEAM VISIBILITY>" # ex. "private" or "public"

$AdUser = "<ADMIN USERNAME>"
$AdPswd = ConvertTo-SecureString '<ADMIN PASSWORD>' -AsPlainText -Force
$AdminCred = New-Object System.Management.Automation.PSCredential $AdUser, $AdPswd

# FINE PARAMETRI #


Install-Module -Name MicrosoftTeams -Verbose -Force

Import-Module MicrosoftTeams -Verbose -Force

Connect-MicrosoftTeams -Credential $AdminCred


$TeamA = New-Team -MailNickname $teamNameA -DisplayName $teamDisplayNameA -Visibility $vis -Description $des

Add-TeamUser -GroupId $TeamA.GroupId -User $AdminCred.UserName

Write-Warning("*** Operazione compeltata su '" + $TeamA.DisplayName + "' ***")
Write-Host("")


$TeamB = New-Team -MailNickname $teamNameB -DisplayName $teamDisplayNameB -Visibility $vis -Description $des

Add-TeamUser -GroupId $TeamB.GroupId -User $AdminCred.UserName

Write-Warning("*** Operazione compeltata su '" + $TeamB.DisplayName + "' ***")
Write-Host("")

Write-Warning("*** Operazione compeltata ***")
