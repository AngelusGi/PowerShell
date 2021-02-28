
function DownloadSoftware {
    param (
        
    )
    
    process {
        
        $Client = New-Object System.Net.WebClient
        $currentPath = Get-Location

        $tempFolder = "TempDownload"
        New-Item -Path $currentPath -Name $tempFolder -ItemType Directory

        $tempPath = $currentPath.Path + "\" + $tempFolder
        
        foreach ($nameSetup in $SoftwareList.Keys) {

            Write-Host("Download in corso di: $($nameSetup)")

            $downloadPath = $tempPath + "\" + $nameSetup

            $Client.DownloadFile($SoftwareList.$nameSetup, $downloadPath)

            Write-Host("Percorso > $($downloadPath)")

            Write-Host("Download di $($nameSetup) completato.")

        }

        Write-Warning("Download completati.")

        return $tempPath
        
    }
}

function CleanResources {
    param (
        $Path
    )
    
    process {

        Read-Host("Verrranno rimossi i file d'installazione, premere un tasto per continuare...")

        Remove-item $Path -recurse
        Write-Host("Percorso temporaneo rimosso > $($Path)")

    }
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


$softwares = @{
    "SetupForNestedVirtualization.ps1"           = "https://raw.githubusercontent.com/Azure/azure-devtestlab/master/samples/ClassroomLabs/Scripts/HyperV/SetupForNestedVirtualization.ps1";
    "jre-8u281-windows-x64.exe"                  = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=244068_89d678f2be164786b292527658ca1605";
    "vs_emulatorsetup.exe"                       = "https://go.microsoft.com/fwlink/?LinkID=809030";
    "android-studio-ide-201.7042882-windows.exe" = "https://redirector.gvt1.com/edgedl/android/studio/install/4.1.2.0/android-studio-ide-201.7042882-windows.exe"

}


$path = DownloadSoftware -SoftwareList $softwares
InstallSoftware -SoftwareList $softwares -Path $path
CleanResources -Path $path
