function DownloadModules {
    param(
        $Software
    )

    process {
        
        $Client = New-Object System.Net.WebClient
        $currentPath = Get-Location
        
        $baseDownloadUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Azure/Lab%20Services/Setup%20Android%20Emulator/" 

        $tempPath = $currentPath.Path + "\"
        
        foreach ($script in $Software) {

            Write-Host("Download in corso di: $($script)")

            $downloadPath = $tempPath + "\" + $script

            $downloadUrl = $baseDownloadUrl + $script

            $Client.DownloadFile($downloadUrl, $downloadPath)

        }

        Write-Warning("Download completati.")

        return $tempPath
        
    }
}

function Get-RunningAsAdministrator {
    [CmdletBinding()]
    param()
    
    $isAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    Write-Verbose "Running with Administrator privileges (t/f): $isAdministrator"
    return $isAdministrator
}

function InstallSoftware {
    param (
        $SoftwareList,
        $Path
    )
    
    process {

        Set-location -Path $Path
        $programs = Get-ChildItem
        
        foreach ($program in $programs) {

            Start-Process -FilePath $program -Verb runAs
            # Start-Process -FilePath $downloadPath -Verb runAs -ArgumentList '/s', '/v"/qn"'

            Read-Host("Al termine del wizard d'installazione premere un tasto per continuare...")

        }

        Write-Warning("Installazione software completata.")

    }
}

if (Get-RunningAsAdministrator) {

    
    $components = "1-enableHyperV.ps1", "2-softwareDownloadAndInstall", "3-redirectEmulator.ps1"

    $currentPath = DownloadModules -Software $components

    InstallSoftware -SoftwareList $components -Path $currentPath
    
}
else {
    Write-Warning("Questo script deve essere eseguito come amministratore.")
}

Write-Host("*** Esecuzione script completata ***")
