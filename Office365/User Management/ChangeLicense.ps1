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
            HelpMessage = "Scope of the module installation (CurrentUser or AllUsers). Default: CurrentUser",
            Mandatory = $false)]
        [ValidateSet("CurrentUser", "AllUsers")]
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
        
        Remove-Item -Path $_downloadPath -Force
        
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

PrepareEnvironment -ModulesToInstall "MSOnline"

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
