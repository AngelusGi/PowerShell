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



function Set-PsEvnironment {
    param(
        [Parameter(
            HelpMessage = "Modules name to install from the GitHub tool repo.",
            Mandatory = $false)]
        [ValidateSet("ModuleManager", "TerraformBackendOnAzure")]
        [string[]]
        $ModulesToInstall = "ModuleManager"
    )

    process {
        $psModuleExtension = "psm1"
    
        foreach ($module in $ModulesToInstall) {

            $libraryUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/$($module)/$($module).$($psModuleExtension)"
            $module = "$($module).$($psModuleExtension)"

            $client = New-Object System.Net.WebClient
            $currentPath = Get-Location
            $downloadPath = Join-Path -Path $currentPath.Path -ChildPath $module
            $client.DownloadFile($libraryUrl, $downloadPath)
            
            $modToImport = Join-Path -Path $currentPath.Path -ChildPath $module -Resolve -ErrorAction Stop
            Import-Module $modToImport -Verbose
            Remove-Item -Path $modToImport -Force
        }
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
    Write-Host("Parametri:")
    Write-Host("Lencenza da rimuovere: $($OldLicense)")
    Write-Host("Nuova licenza da assegnare: $($NewLicense)")
    Write-Host("Categoria di utenti (JobTitle) a cui cambiare licenza: $($UserToChangeLicense)")
    Write-Host("***")
}

Set-PsEvnironment -PsModulesToInstall  "MSOnline"

Connect-MsolService -Credential $AdminCred

$Users = Get-MsolUser
    
foreach ($User in $Users){

    if ($User.Title -eq  $UserToChangeLicense) {
        $Upn = $User.UserPrincipalName
        Write-Host("")

        Write-Host("Modifica in corso su: '$($Upn)'")

        Set-MsolUserLicense -UserPrincipalName $Upn -AddLicenses $NewLicense -RemoveLicenses $OldLicense

        Write-Host("")
        # Write-Host("Modifica terminata su: '$($Upn)'"
    }
    

}

Write-Host(" *** OPERAZIONE COMPLETATA *** ")
