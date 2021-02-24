<#
    # $user = "<YUOR-USER-NAME>"
    # $pswd = ConvertTo-SecureString '<YOUR-PASSWORD>' -AsPlainText -Force
    # $cred = New-Object System.Management.Automation.PSCredential $Username, $Password
    # Connect-MicrosoftTeams -Credentials $cred

#>

$mod = "MicrosoftTeams"

Install-Module PowerShellGet -Force -AllowClobber

Install-Module $mod -AllowPrerelease -RequiredVersion "1.1.9-preview"

Import-Module -Name $mod | Out-Null

Connect-MicrosoftTeams

$app = Get-TeamsApp -DisplayName "Azure Lab Services"

$teams = Get-Team -Archived $false

foreach ($team in $teams) {
    $res = Get-TeamsAppInstallation -TeamId $team.GroupId -AppId $app.Id
    if ($null -eq $res) {
        Add-TeamsAppInstallation -AppId $app.Id -TeamId $team.GroupId
        Write-Host "App $($app.DisplayName) installata nel Team $($team.DisplayName)"
    }
}

Disconnect-MicrosoftTeams
