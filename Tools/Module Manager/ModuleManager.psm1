<#
 .Synopsis
  Module manager library on PowerShell

 .Description
  This custom module verify if the module is alredy installed, otherwise will install/update it.
  It can manage GitHub hosted modules too, such as Azure Lab Services.

 .Parameter Modules 
  List of PowerShell modules to be installed.

  .Parameter Scope 
  Scope of the module installation (CurrentUser or AllUsers). Default: CurrentUser.
  Accepts only those two values: CurrentUser, AllUsers

  .Parameter OnlyPowerShell5 
  If true, this script has dependecies in order to be executed only on PowerShell 5.x.

  .Parameter OnlyAbovePs6 
  If true, this script has dependecies in order to be executed PowerShell >=6.x.

#>

function Get-EnvironmentInstaller {
    #region mod manager
    param(
        # List of modules to install
        [Parameter(
            HelpMessage = "List of PowerShell modules to be installed.",
            Mandatory = $true
        )]
        [string[]]
        $Modules,

        # Install mod -scope
        [Parameter(
            HelpMessage = "Scope of the module installation (CurrentUser or AllUsers). Default: CurrentUser.",
            Mandatory = $false)]
        [ValidateSet("CurrentUser", "AllUsers")]
        [string]
        $Scope = "CurrentUser",

        # Version required to run the script - if null every version of PowerShell is good
        [Parameter(
            HelpMessage = "If true, this script has dependecies in order to be executed only on PowerShell 5.x.",
            Mandatory = $false)]
        [bool]
        $OnlyPowerShell5 = $false,

        [Parameter(
            HelpMessage = "If true, this script has dependecies in order to be executed PowerShell >=6.x.",
            Mandatory = $false)]
        [bool]
        $OnlyAbovePs6 = $false
    )

    function Find-ModulesToInstall {
        param (
            [Parameter(
                HelpMessage = "List of PowerShell modules to be installed.",
                Mandatory = $true
            )]
            [string[]]
            $Modules,

            [Parameter(
                HelpMessage = "Scope of the module installation (CurrentUser or AllUsers). Default: CurrentUser",
                Mandatory = $false)]
            [ValidateSet("CurrentUser", "AllUsers")]
            [string]
            $Scope = "CurrentUser"
        )

        Get-Process {

            $Modules = $Modules | Select-Object -Unique
            $_installedModules = Get-InstalledModule

            foreach ($mod in $Modules) {

                $_azLabServiceModName = "Az.LabServices"

                if ($mod -eq $_azLabServiceModName) {
                
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
                    
                    Write-Output "Importazione modulo $($_azLabServiceModName) in corso..."
                    Import-Module ".$($_moduleFileName)"

                    #if DEBUG
                    # $test = Get-Command -Module $_azLabServiceModName
                    # Write-Debug($test)
                    #endif

                    Remove-Item -Path $_downloadPath -Force
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

    function Test-PsVersion {
        Get-Process {
            Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Verifica dell'ambiente in corso, attendere..."

            if (($OnlyPowerShell5 -eq $true) -and ($PSVersionTable.PSVersion.Major -ne 5)) {
                throw "Questo script può essere eseguito solo con la versione 5.x di PowerShell. Attualmente in uso $($PSVersionTable.PSVersion)"
            }

            if (($OnlyPowerShell5 -eq $true) -and ($PSVersionTable.PSVersion.Major -le 6)) {
                throw "Questo script può essere eseguito con una versione >=6.x di PowerShell. Attualmente in uso $($PSVersionTable.PSVersion)"
            }
        }
    }

    function Install-LocalModules {
        param (
            [Parameter(
                HelpMessage = "List of PowerShell modules to be installed.",
                Mandatory = $true
            )]
            [string[]]
            $Modules,

            [Parameter(
                HelpMessage = "Scope of the module installation (CurrentUser or AllUsers). Default: CurrentUser",
                Mandatory = $false)]
            [ValidateSet("CurrentUser", "AllUsers")]
            [string]
            $Scope = "CurrentUser"
        )

        Get-Process {
            Test-PsVersion
            Find-ModulesToInstall -Modules $Modules -Scope $Scope
        }
    }

    #endregion

    #region script launch

    Install-LocalModules -Scope $Scope -Modules $Modules

    #endregion

}

Export-ModuleMember -Function Get-EnvironmentInstaller
