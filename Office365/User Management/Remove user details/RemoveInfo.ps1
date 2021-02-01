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
    
        $Client.DownloadFile($LibraryURL, ".\ModuleManager.ps1")

        .\ModuleManager.ps1 -Modules $Modules -CompatibleVersion $Version 

    }
    
}

# EndRegion

PrepareEnvironment -Modules "MSOnline"

try {
  
    $ok = 's'
    $stop = 'n'

    do {
        Clear-Host
        Write-Warning("Questo script eliminerà le informazioni MobilePhone, Office, PhoneNumber, Fax , City, Department, Title dai profili di tutti gli utenti.")
        $response = Read-Host("Continuare? [s/n]")
    
        Write-Output("")

        if ($response.Equals($stop)) {
            Write-Output(" *** ESECUZIONE COMPLETATA *** ")

            exit
        }
    
    } while (-not $response.Equals($ok))

    $cred = Get-Credential
    Connect-MsolService -Credential $cred

    $Users = Get-MsolUser

    $Empty = "-"
        
    foreach ($User in $Users) {

        Write-Output("Modifica in corso su: $($User.UserPrincipalName)")

        Set-MsolUser -UserPrincipalName $User.UserPrincipalName -MobilePhone $Empty -Office $Empty -PhoneNumber $Empty -Fax $Empty -City $Empty -Department $Empty -Title $Empty

        Write-Output("")

    }

}
catch {
    Write-Warning(" *** ERRORE, verificare le credenziali inserite. *** ")
    
}

Write-Output(" *** ESECUZIONE COMPLETATA *** ")
    
