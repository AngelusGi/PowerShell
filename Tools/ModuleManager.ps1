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
                
                Write-Host("Installazione del modulo Az.LabServices in corso...")

                $LabServiceLibraryURL = "https://raw.githubusercontent.com/Azure/azure-devtestlab/master/samples/ClassroomLabs/Modules/Library/Az.LabServices.psm1"

                $Client = New-Object System.Net.WebClient

                $currentPath = Get-Location

                $downloadPath = $currentPath.Path + "\Az.LabServices.psm1"
                
                $Client.DownloadFile($LabServiceLibraryURL, $downloadPath)

                Import-Module .\Az.LabServices.psm1

            }
            else {
                $GalleryModule = Find-Module -Name $module

                $mod = $installedModules | Where-Object { $_.Name -eq $module }
            
                # if ( -not (Get-InstalledModule -Name $module -ErrorAction silentlycontinue)) {
                #     Write-Host("Modulo $($module) non trovato. Installazione in corso...")
                #     Install-Module -Name $module -Scope $Scope -AllowClobber -Confirm:$false -Force
                # }

                if ([string]::IsNullOrEmpty($mod) -or [string]::IsNullOrWhiteSpace($mod)) {
                    Write-Host("Modulo $($module) non trovato. Installazione in corso...")
                    Install-Module -Name $module -Scope $Scope -AllowClobber -Confirm:$false -Force
                }
                else {
                    Write-Host("Modulo $($module) trovato.")
    
                    if ($GalleryModule.Version -ne $mod.Version) {
                        Write-Host("Aggionamento del modulo $($module) in corso...")
    
                        Update-Module -Name $module -Confirm:$false -Force
                    }
                }

                Import-Module $module
                Write-Warning("Modulo $($module) importato correttamente")
            }
            
        }
        
    }
}

function VerifyPsVersion {
    
    process {

        $anyVersion = 0

        Write-Host("Verifica dell'ambiente in corso, attendere...")

        if ($anyVersion -ne $CompatibleVersion) {
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
    Write-Host("Il parametro Scope accetta solo i seguenti valori:")
    Write-Host("CurrentUser (predefinito)")
    Write-Host("AllUsers")
    throw "Paramentro Scope non corretto -> $($Scope)" 
}
