#region mod manager

param(
    # List of modules to install
    [Parameter(
        HelpMessage = "List of PowerShell modules to be installed.",
        Mandatory = $true
    )]
    [String[]]
    $Modules,

    # Install mod -scope
    [Parameter(
        HelpMessage = "Scope of the mod installer. Default: CurrentUser.",
        Mandatory = $false
    )]
    [String]
    $Scope = "CurrentUser",

    # Version required to run the script - if null every version of PowerShell is good
    [Parameter(
        HelpMessage = "If true, PowerShell 5.x is required to run the script - if flase/blank every version of PowerShell is good.",
        Mandatory = $false
    )]
    [bool]
    $CompatibleVersion
)

function CheckModules {
    param (
        $Modules,
        [String]$Scope
    )
    process {

        $_installedModules = Get-InstalledModule

        foreach ($mod in $Modules) {
        
            if ($mod -eq "Az") {
                if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
                    throw 'Il modulo AzureRM è installato sulla macchina. Rimuoverlo prima di procedere.'
                }
            }

            if ($mod -eq "Az.LabServices") {
                
                Write-Host("Installazione del modulo Az.LabServices in corso...")

                $_azLabServiceLib = "https://raw.githubusercontent.com/Azure/azure-devtestlab/master/samples/ClassroomLabs/Modules/Library/Az.LabServices.psm1"

                $_client = New-Object System.Net.WebClient

                $_currentPath = Get-Location

                $_moduleFileName = "\Az.LabServices.psm1"

                if ([System.Environment]::OSVersion.Platform.Equals("Unix")) {
                    $_moduleFileName = "/Az.LabServices.psm1"
                }

                $_downloadPath = $_currentPath.Path + $_moduleFileName
        
                $_client.DownloadFile($_azLabServiceLib, $_downloadPath)

                if ([System.Environment]::OSVersion.Platform.Equals("Unix")) {
                    Import-Module ./Az.LabServices.psm1
                }
                else {
                    Import-Module .\Az.LabServices.psm1
                }

            }
            else {
                $_galleryModule = Find-Module -Name $mod

                $mod = $_installedModules | Where-Object { $_.Name -eq $mod }
            
                # if ( -not (Get-InstalledModule -Name $mod -ErrorAction silentlycontinue)) {
                #     Write-Host("Modulo $($mod) non trovato. Installazione in corso...")
                #     Install-Module -Name $mod -Scope $Scope -AllowClobber -Confirm:$false -Force
                # }

                if ([string]::IsNullOrEmpty($mod) -or [string]::IsNullOrWhiteSpace($mod)) {
                    Write-Host("Modulo $($mod) non trovato. Installazione in corso...")
                    Install-Module -Name $mod -Scope $Scope -AllowClobber -Confirm:$false -Force
                }
                else {
                    Write-Host("Modulo $($mod) trovato.")
    
                    if ($_galleryModule.Version -ne $mod.Version) {
                        Write-Host("Aggionamento del modulo $($mod) in corso...")
                        Update-Module -Name $mod -Confirm:$false -Force
                    }
                }

                Import-Module $mod
                Write-Warning("Modulo $($mod) importato correttamente")
            }
            
        }
        
    }
}

function VerifyPsVersion {
    
    process {

        Write-Host("Verifica dell'ambiente in corso, attendere...")

        if (($CompatibleVersion -eq $true) -and ($PSVersionTable.PSVersion.Major -ne 5)) {
            throw "Questo script può essere eseguito solo con la versione 5.x di PowerShell. Attualmente in uso $($PSVersionTable.PSVersion)"
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

#endregion

#region script launch

if ($Scope.Equals("CurrentUser") -or $Scope.Equals("AllUsers")) {
    InstallLocalModules -Scope $Scope -Modules $Modules
}
else {
    Write-Host("Il parametro Scope accetta solo i seguenti valori:")
    Write-Host("CurrentUser (predefinito)")
    Write-Host("AllUsers")
    throw "Paramentro Scope non corretto -> $($Scope)" 
}

#endregion
