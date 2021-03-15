function LinkVsAndroid {
    param (
        
    )
    process {

        Write-Warning "This scirpt will interact with the default Android SDK Path."

        $androidSdkPath = Resolve-Path $(Join-Path "$($env:APPDATA)" "../Local/Android/Sdk")

        $registryKeyPath = "HKLM:Software\WOW6432NODE\Android Sdk Tools"
        New-Item -Path $registryKeyPath
        New-ItemProperty -Path $registryKeyPath -Name Path -PropertyType String -Value $androidSdkPath
    }
    
}

LinkVsAndroid