# This script will delete all local state files from Terraform

[CmdletBinding()]
param (
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $Path
)

$extensionsToSave = ".tf", ".md", ".ps1", ".gitignore"
$Path = ([string]::IsNullOrEmpty($Path) -or [string]::IsNullOrWhiteSpace($Path)) ? (Get-Location).Path : $Path

Write-Output "Questo script eliminarà dalla direcory corrente e le relative sub, tutti i file che non siano con estensione"
Write-Output "Path $($Path)"
Write-Output $extensionsToSave

$response = Read-Host -Prompt "Continuare? [y]es / [*]"

if ($response.ToLowerInvariant() -eq "y") {
    Write-Output "Pulizia in corso"    
    
    $folders = Get-ChildItem -Path $Path -Recurse -Directory | Where-Object { $_.Name -eq ".terraform" }
    # Get-ChildItem -Path $Path -Recurse -Directory | Where-Object { $_.Name -eq ".terraform" } | Remove-Item -Force -Confirm:$false

    if ($null -ne $folders) {

        # $folders | Remove-Item -Force -Confirm:$false
        $folders | Remove-Item -Confirm:$true
    
        Write-Warning "Cartelle rimosse:"
        
        # $folders | Select-Object PSChildName,FullName | Format-Table -AutoSize -HideTableHeaders
        $folders | Select-Object PSChildName, FullName | Format-List -GroupBy Directory
    }
    else {
        Write-Warning "Nessuna cartella da rimuovere."
    }
    
    $files = Get-ChildItem -Path $Path -Recurse -File
    
    foreach ($ext in $extensionsToSave) {
        $files = $files | Where-Object { $_.Extension -ne $ext }
    }
    
    if ($null -ne $files) {

        # $files | Remove-Item -Force -Confirm:$false
        $files | Remove-Item -Confirm:$true
    
        Write-Warning "File rimossi:"
        
        # $files | Select-Object PSChildName,FullName | Format-Table -AutoSize -HideTableHeaders
        $files | Select-Object PSChildName, FullName | Format-List -GroupBy Directory
    }
    else {
        Write-Warning "Nessun file da rimuovere."
    }
}

Write-Output "Esecuzione completata"    