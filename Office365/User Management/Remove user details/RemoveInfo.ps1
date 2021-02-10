#Rev3

# $AdUser = "ADMIN TENANT"
# $AdPswd = ConvertTo-SecureString 'ADMIN PSWD' -AsPlainText -Force
# $AdminCred = New-Object System.Management.Automation.PSCredential $AdUser, $AdPswd

# Region module manager

function PrepareEnvironment {

    param(
        [Parameter(Mandatory = $true)]
        [String[]]
        $Modules,
        [int16]
        $Version
    )
    
    process {

        $LibraryURL = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/ModuleManager.ps1"

        $Client = New-Object System.Net.WebClient
    
        $currentPath = Get-Location

        $downloadPath = $currentPath.Path + "\ModuleManager.ps1"
        
        $Client.DownloadFile($LibraryURL, $downloadPath)

        .\ModuleManager.ps1 -Modules $Modules -CompatibleVersion $Version 

    }
    
}

# EndRegion

PrepareEnvironment -Modules "MSOnline"

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
    
