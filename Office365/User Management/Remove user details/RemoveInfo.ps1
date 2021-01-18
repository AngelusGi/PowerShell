#Rev3

# $AdUser = "ADMIN TENANT"
# $AdPswd = ConvertTo-SecureString 'ADMIN PSWD' -AsPlainText -Force
# $AdminCred = New-Object System.Management.Automation.PSCredential $AdUser, $AdPswd

# Region module manager

function CheckModules {
    param (
        $Modules,
        [String]$Scope
    )
    process {

        $installedModules = Get-InstalledModule

        foreach ($module in $Modules) {
            
            $GalleryModule = Find-Module -Name $module

            $mod = $installedModules | Where-Object { $_.Name -eq $module }
        
            if ([string]::IsNullOrEmpty($mod) -or [string]::IsNullOrWhiteSpace($mod)) {
                Write-Warning("Modulo $($module) non trovato. Installazione in corso...")
                Install-Module -Name $module -Scope $Scope -AllowClobber
            }
            else {
                Write-Warning("Modulo $($module) trovato.")

                if ($GalleryModule.Version -ne $mod.Version) {
                    Write-Warning("Aggionamento del modulo $($module) in corso...")

                    Update-Module -Name $module
                }
            }

            Import-Module -Name $module
        }
        
    }
}

function VerifyPsVersion {
    
    process {
        
        Write-Warning("Verifica dell'ambiente in corso, attendere...")

        if ($PSVersionTable.PSVersion.Major -ne 5) {
            Write-Error("Questo script può essere eseguito solo con la versione 5 di Windows PowerShell")
            exit
        }
    }
}

function InstallLocalModules {
    param (
        [String]$Scope,
        $Modules
    )

    process {

        VerifyPsVersion

        CheckModules -Modules $Modules -Scope $Scope
        
    }
    
}

# EndRegion

try {
  
    $ok = 's'
    $stop = 'n'

    do {
        Clear-Host
        Write-Warning("Questo script eliminerà le informazioni MobilePhone, Office, PhoneNumber, Fax , City, Department, Title dai profili di tutti gli utenti.")
        $response = Read-Host("Continuare? [s/n]")
    
        Write-Host("")

        if ($response.Equals($stop)) {
            Write-Host(" *** ESECUZIONE COMPLETATA *** ")

            exit
        }
    
    } while (-not $response.Equals($ok))

    InstallLocalModules -Modules "MSOnline" -Scope "CurrentUser"

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
    
