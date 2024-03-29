# Custom library to manage module dependencies
function Set-PsEvnironment {
    param(
        [Parameter(
            HelpMessage = "Modules name to install from the GitHub tool repo.",
            Mandatory = $false)]
        [ValidateSet("ModuleManager", "TerraformBackendOnAzure")]
        [string[]]
        $ModulesToInstall = "ModuleManager"
    )

    process {
        $psModuleExtension = "psm1"
    
        ## GitHub import
        foreach ($module in $ModulesToInstall) {

            $libraryUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/$($module)/$($module).$($psModuleExtension)"
            $module = "$($module).$($psModuleExtension)"

            $client = New-Object System.Net.WebClient
            $currentPath = Get-Location
            $downloadPath = Join-Path -Path $currentPath.Path -ChildPath $module
            $client.DownloadFile($libraryUrl, $downloadPath)
            
            $modToImport = Join-Path -Path $currentPath.Path -ChildPath $module -Resolve -ErrorAction Stop
            Import-Module $modToImport
            Remove-Item -Path $modToImport -Force

            Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Modulo $($module) importato correttamente."
        }

        # # Local import
        # foreach ($module in $ModulesToInstall) {
        #     $currentPath = Get-Location
        #     $module = "$($module).$($psModuleExtension)"
        #     $modToImport = Join-Path -Path $currentPath.Path -ChildPath $module -Resolve -ErrorAction Stop
        #     Import-Module $modToImport
        # }
        
    }

}

Set-PsEvnironment -ModulesToInstall "ModuleManager"

# exectues custom module
Set-EnvironmentInstaller -Modules "Az" -OnlyAbovePs6 $true
