# Custom library to manage module dependencies
function Set-PsEvnironment {
    param(
        [Alias ("PowerShellModules", "PowerShellLibrary")]
        [Parameter(
            HelpMessage = "List of modules to be installed.",
            Mandatory = $true)]
        [string[]]
        $PsModulesToInstall,

        [Parameter(
            HelpMessage = "If true, this script has dependecies in order to be executed only on PowerShell 5.x.",
            Mandatory = $false)]
        [bool]
        $OnlyPowerShell5 = $false,

        [Parameter(
            HelpMessage = "If true, this script has dependecies in order to be executed PowerShell >=6.x.",
            Mandatory = $false)]
        [bool]
        $OnlyAbovePs6 = $false,

        [Parameter(
            HelpMessage = "Scope of the module installation. Default: CurrentUser",
            Mandatory = $false)]
        [string]
        $Scope = "CurrentUser",

        [Parameter(
            HelpMessage = "Modules name to install from the GitHub tool repo.",
            Mandatory = $false)]
        [ValidateSet("ModuleManager", "TerraformBackendOnAzure")]
        [string[]]
        $ModulesToInstall = "ModuleManager"
    )
    
    Get-process {
        $psModuleExtension = "psm1"
    
        foreach ($module in $ModulesToInstall) {

            $folder = ($ModulesToInstall -eq "ModuleManager") ? "Module%20Manager" : "Manage%20Terraform%20Backend%20on%20Azure" 
            $libraryUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/$($folder)/$($ModulesToInstall).$($psModuleExtension)"

            $client = New-Object System.Net.WebClient
            $currentPath = Get-Location
            $downloadPath = Join-Path -Path $currentPath.Path -ChildPath $module
            $client.DownloadFile($libraryUrl, $downloadPath)
            
            $modToImport = Join-Path -Path $currentPath.Path -ChildPath $module -Resolve -ErrorAction Stop
            Import-Module $modToImport
            Remove-Item -Path $modToImport -Force
        }
    }
}

Set-PsEvnironment -ModulesToInstall "Az"
# Set-PsEvnironment -ModulesToInstall "Az" -OnlyPowerShell5 $true
# Set-PsEvnironment -ModulesToInstall "Az" -OnlyAbovePs6 $true
