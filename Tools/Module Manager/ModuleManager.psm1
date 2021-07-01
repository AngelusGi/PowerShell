function Get-EnvironmentInstaller {
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
                
                    Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Installazione del modulo Az.LabServices in corso..."

                    $_azLabServiceLib = "https://raw.githubusercontent.com/Azure/azure-devtestlab/master/samples/ClassroomLabs/Modules/Library/Az.LabServices.psm1"

                    $_client = New-Object System.Net.WebClient

                    $_currentPath = Get-Location

                    $_moduleFileName = "\Az.LabServices.psm1"

                    if ([System.Environment]::OSVersion.Platform.Equals("Unix")) {
                        $_moduleFileName = "/Az.LabServices.psm1"
                    }

                    $_downloadPath = $_currentPath.Path + $_moduleFileName
        
                    $_client.DownloadFile($_azLabServiceLib, $_downloadPath)

                    Import-Module -Name $_moduleFileName

                }
                else {
                    $_galleryModule = Find-Module -Name $mod

                    $mod = $_installedModules | Where-Object { $_.Name -eq $mod }
            
                    if ([string]::IsNullOrEmpty($mod) -or [string]::IsNullOrWhiteSpace($mod)) {
                        Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Modulo $($_galleryModule.Name) non trovato. Installazione in corso..."
                        Install-Module -Name $_galleryModule.Name -Scope $Scope -AllowClobber -Confirm:$false -Force
                    }
                    else {
                        Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Modulo $($mod.Name), versione $($mod.Version) trovato."
    
                        if ($_galleryModule.Version -ne $mod.Version) {
                            Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Aggionamento del modulo $($mod.Name) dalla versione $($mod.Version) alla $($_galleryModule.Version) in corso..."
                            Update-Module -Name $_galleryModule.Name -Confirm:$false -Force
                        }
                    }

                    try {
                        Write-Output "Importazione modulo $($_galleryModule.Name) in corso..."
                        Import-Module -Name $_galleryModule.Name
                        Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Modulo $($_galleryModule.Name), versione $($_galleryModule.Version) importato correttamente"
                        
                    }
                    catch {
                        Write-Error "Impossibile importare il modulo $($_galleryModule.Name) come $($Scope)"
                    }
                }
            
            }
        
        }
    }

    function VerifyPsVersion {
    
        process {

            Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Verifica dell'ambiente in corso, attendere..."

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
        Write-Error("Il parametro Scope accetta solo i seguenti valori:")
        Write-Error("CurrentUser (predefinito)")
        Write-Error("AllUsers")
        throw "Paramentro Scope non corretto -> $($Scope)" 
    }

    #endregion

}

Export-ModuleMember -Function Get-EnvironmentInstaller
