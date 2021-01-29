# Region module manager

param(
    # List of modules to install
    [Parameter(Mandatory = $true)]
    [String[]]
    $Modules,

    # Install module -scope
    [Parameter()]
    [String]
    $Scope = "CurrentUser",

    # Version required to run the script - if null every version of PowerShell is good
    [Parameter()]
    [String]
    $CompatibleVersion = $null
)

function CheckModules {
    param (
        $Modules,
        [String]$Scope
    )
    process {

        if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
            Write-Error -Message ('Il modulo AzureRM è installato sulla macchina. Rimuoverlo prima di procedere.')
            Break
        }

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
        }

       
        
    }
}

function VerifyPsVersion {
    
    process {
        
        Write-Warning("Verifica dell'ambiente in corso, attendere...")

        if ($null -ne $CompatibleVersion) {
            if ($PSVersionTable.PSVersion.Major -ne $CompatibleVersion) {
                Write-Error("Questo script può essere eseguito solo con la versione $($CompatibleVersion) di PowerShell")
                exit
            }
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

if ($Scope -eq "CurrentUser" -or $Scope -eq "AllUsers") {
    InstallLocalModules -Scope $Scope -Modules $Modules
}
else {
    Write-Warning("Il parametro Scope accetta solo i seguenti valori:")
    Write-Warning("CurrentUser (predefinito)")
    Write-Warning("AllUsers")
    throw "Paramentro Scope non corretto -> $($Scope)" 
}
