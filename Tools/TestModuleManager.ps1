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
            HelpMessage = "Scope of the module installation. Default: CurrentUser",
            Mandatory = $false)]
        [string]
        $Scope = "CurrentUser"
    )
    
    process {

        $_customModName = "ModuleManager.psd1"

        $_libraryUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/$($_customModName)"

        $_client = New-Object System.Net.WebClient
    
        $_currentPath = Get-Location

        $_moduleFileName = "\$($_customModName)"

        if ([System.Environment]::OSVersion.Platform.Equals("Unix")) {
        $_moduleFileName = "/$($_customModName)"
        }

        $_downloadPath = $_currentPath.Path + $_moduleFileName
        
        $_client.DownloadFile($_libraryUrl, $_downloadPath)

        Import-Module -Name $_customModName
        
        Get-EnvironmentInstaller -Modules $ModulesToInstall -CompatibleVersion $OnlyPowerShell5 -Scope $Scope
        
        # if ([System.Environment]::OSVersion.Platform.Equals("Unix")) {
        #     pwsh "$($loc.Path)/$($_customModName) -Modules $ModulesToInstall -CompatibleVersion $OnlyPowerShell5"
        # }
        # else {
        #     .\$_customModName -Modules $ModulesToInstall -CompatibleVersion $OnlyPowerShell5
        # }

    }
    
}

PrepareEnvironment -ModulesToInstall "Az" -OnlyPowerShell5 $true
