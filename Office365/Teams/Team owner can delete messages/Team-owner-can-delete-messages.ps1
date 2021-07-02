[CmdletBinding()]
param (

)


# Region module manager
function ExitSessions {

    process {
        Disconnect-MicrosoftTeams -Confirm:$false
    }
    
}


function PrepareEnvironment {

    param(
        [Parameter(Mandatory = $true)]
        [String[]]
        $Modules,
        [int16]
        $Version
    )
    
    process {

        $LibraryURL = 'https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/ModuleManager.ps1'

        $Client = New-Object System.Net.WebClient
    
        $currentPath = Get-Location

        $downloadPath = $currentPath.Path + '\ModuleManager.ps1'
        
        $Client.DownloadFile($LibraryURL, $downloadPath)

        .\ModuleManager.ps1 -Modules $Modules -CompatibleVersion $Version 

    }
    
}


# End parameters region

PrepareEnvironment -ModulesToInstall 'MicrosoftTeams'

$data = Connect-MicrosoftTeams

Write-Warning('Applicazione policy in corso, attendere...')
Set-CsTeamsMessagingPolicy -Tenant $data.Tenant.Id –AllowOwnerDeleteMessage $true

Write-Host('La policy `AllowOwnerDeleteMessage` e` stata applicata correttamente.')
Write-Host('Le policy applicate nel tenant sono le seguenti:')

Get-CsTeamsMessagingPolicy

ExitSessions

Write-Host('Esecuzione script completata.')
