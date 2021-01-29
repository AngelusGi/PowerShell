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
    [int16]
    $CompatibleVersion = 0
)

function CheckModules {
    param (
        $Modules,
        [String]$Scope
    )
    process {

        $installedModules = Get-InstalledModule

        foreach ($module in $Modules) {
        
            if ($module -eq "Az") {
                if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
                    throw 'Il modulo AzureRM è installato sulla macchina. Rimuoverlo prima di procedere.'
                }
            }

            if ($module -eq "Az.LabServices") {
                
                Write-Warning("Installazione del modulo Az.LabServices in corso...")

                $LabServiceLibraryURL = "https://raw.githubusercontent.com/Azure/azure-devtestlab/master/samples/ClassroomLabs/Modules/Library/Az.LabServices.psm1"

                $Client = New-Object System.Net.WebClient

                $Client.DownloadFile($LabServiceLibraryURL, ".\Az.LabServices.psm1")

                Import-Module .\Az.LabServices.psm1

            } else {
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

                Import-Module $module
                Write-Output("Modulo $($module) importato correttamente")
            }

        

            
        }

       
        
    }
}

function VerifyPsVersion {
    
    process {
        
        Write-Warning("Verifica dell'ambiente in corso, attendere...")

        if (0 -ne $CompatibleVersion) {
            if ($PSVersionTable.PSVersion.Major -ne $CompatibleVersion) {
                throw "Questo script può essere eseguito solo con la versione $($CompatibleVersion) di PowerShell"
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
