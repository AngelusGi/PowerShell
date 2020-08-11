# Install-Module -Name MicrosoftTeams -Verbose -Force

Import-Module MicrosoftTeams -Verbose -Force

$credentials = Get-Credential
Write-Host($credentials.UserName)
Connect-MicrosoftTeams -Credential $credentials

# $tenant = Connect-AzureAD -TenantDomain "eduscuola.cloud"

# Write-Host($tenant.TenantId)

# Connect-MicrosoftTeams -TenantId $tenant.TenantId

$teamNameA = "TestGuest1"
$teamDisplayNameA = "Test Teams CSV 1"

$teamNameB = "TestGuest2"
$teamDisplayNameB = "Test Teams CSV 2"

$des = "Team test ammissione"
$vis = "private"

$TeamA = New-Team -MailNickname $teamNameA -displayname $teamDisplayNameA -Visibility $vis -Description $des


$TeamB = New-Team -MailNickname $teamNameB -displayname $teamDisplayNameB -Visibility $vis -Description $des

Add-TeamUser -GroupId $TeamA.GroupId -User $credentials.UserName
Add-TeamUser -GroupId $TeamB.GroupId -User $credentials.UserName

Write-Warning("*** Operazione compeltata su " + $TeamA.MailNickname + " ***")
Write-Host("")
Write-Warning("*** Operazione compeltata su " + $TeamB.MailNickname + " ***")
Write-Host("")
Write-Host("")
