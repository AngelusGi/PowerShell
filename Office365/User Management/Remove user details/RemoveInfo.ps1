#Rev3

# $AdUser = "ADMIN TENANT"
# $AdPswd = ConvertTo-SecureString 'ADMIN PSWD' -AsPlainText -Force
# $AdminCred = New-Object System.Management.Automation.PSCredential $AdUser, $AdPswd

# Region module manager

function PrepareEnvironment {

    param(
        [Parameter(
            HelpMessage = "List of modules to be installed.",
            Mandatory = $true)]
        [string[]]
        $ModulesToInstall,
        
        [Parameter(
            HelpMessage = "If true, this script has dependecies in order to be executed only on PowerShell 5.",
            Mandatory = $false)]
        [bool]
        $OnlyPowerShell5 = $false,

        [Parameter(
            HelpMessage = "Scope of the module installation. Default: CurrentUser",
            Mandatory = $false)]
        [string]
        $Scope = "CurrentUser"
    )
    
    process {

        $_customMod = "ModuleManager.psm1"

        $_libraryUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/Module%20Manager/$($_customMod)"

        $_client = New-Object System.Net.WebClient
    
        $_currentPath = Get-Location

        $_moduleFileName = "\$($_customMod)"

        if ([System.Environment]::OSVersion.Platform.Equals("Unix")) {
        $_moduleFileName = "/$($_customMod)"
        }

        $_downloadPath = $_currentPath.Path + $_moduleFileName
        
        $_client.DownloadFile($_libraryUrl, $_downloadPath)

        Import-Module -Name ".$($_moduleFileName)"
        
        Get-EnvironmentInstaller -Modules $ModulesToInstall -CompatibleVersion $OnlyPowerShell5 -Scope $Scope
        
    }
    
}

# EndRegion

PrepareEnvironment -ModulesToInstall  "MSOnline"

try {

    Set-Variable ok -Value 's' -Option ReadOnly
    Set-Variable stop -Value 'n' -Option ReadOnly

    do {
        Clear-Host
        Write-Warning("Questo script eliminerà le informazioni MobilePhone, Office, PhoneNumber, Fax , City, Department, Title dai profili di tutti gli utenti.")
        $response = Read-Host("Continuare? [$($ok)/$($stop)]")
    
        Write-Host("")

        if ($response.Equals($stop)) {
            Write-Host(" *** ESECUZIONE COMPLETATA *** ")

            exit
        }
    
    } while (-not $response.Equals($ok))

    $cred = Get-Credential
    Connect-MsolService -Credential $cred

    $Users = Get-MsolUser

    $Empty = "-"
        
    foreach ($User in $Users) {

        Write-Host("Modifica in corso su: $($User.UserPrincipalName)")

        Set-MsolUser -UserPrincipalName $User.UserPrincipalName -MobilePhone $Empty -Office $Empty -PhoneNumber $Empty -Fax $Empty -City $Empty -Department $Empty -Title $Empty

        Write-Host("")

    }

}
catch {
    Write-Warning(" *** ERRORE, verificare le credenziali inserite. *** ")
    
}

Write-Host(" *** ESECUZIONE COMPLETATA *** ")
    
