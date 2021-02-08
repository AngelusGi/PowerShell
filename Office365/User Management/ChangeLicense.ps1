#Rev3


Param
(
    [parameter(Mandatory = $true)]
    [String]
    $OldLicense,

    [parameter(Mandatory = $true)]
    [String]
    $NewLicense,

    [parameter(Mandatory = $true)]
    [SecureString]
    $UserToChangeLicense    
)


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
    
        $Client.DownloadFile($LibraryURL, "ModuleManager.ps1")

        .\ModuleManager.ps1 -Modules $Modules -CompatibleVersion $Version 

    }
    
}


if ([string]::IsNullOrWhiteSpace($OldLicense)) {
    Write-Error("Il parametro OldLicense non può essere vuoto")
    exit
}
elseif ([string]::IsNullOrEmpty($NewLicense)) {
    Write-Error("Il parametro NewLicense non può essere vuoto")
    exit
}
elseif ([string]::IsNullOrEmpty($UserToChangeLicense)) {
    Write-Error("Il parametro UserToChangeLicense non può essere vuoto")
    exit
}
else {
    Write-Output("Parametri:")
    Write-Output("Lencenza da rimuovere: $($OldLicense)")
    Write-Output("Nuova licenza da assegnare: $($NewLicense)")
    Write-Output("Categoria di utenti (JobTitle) a cui cambiare licenza: $($UserToChangeLicense)")
    Write-Output("***")
}

PrepareEnvironment -Modules "MSOnline"

Connect-MsolService -Credential $AdminCred

$Users = Get-MsolUser
    
foreach ($User in $Users){

    if ($User.Title -eq  $UserToChangeLicense) {
        $Upn = $User.UserPrincipalName
        Write-Output("")

        Write-Output("Modifica in corso su: '$($Upn)'")

        Set-MsolUserLicense -UserPrincipalName $Upn -AddLicenses $NewLicense -RemoveLicenses $OldLicense

        Write-Output("")
        # Write-Output("Modifica terminata su: '$($Upn)'"
    }
    

}

Write-Output(" *** OPERAZIONE COMPLETATA *** ")
