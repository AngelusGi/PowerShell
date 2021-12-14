
function Set-TerraformFolder {
    param (
        # Parameter main.tf file path as output
        [Parameter(
            HelpMessage = "Path where will be saved the output Main.tf within the backend configuration. Default: script execution folder.",
            Mandatory = $false
        )]
        [string]
        $OutputFilePath,
        
        # Name of the terraform main file
        [Parameter(
            HelpMessage = "Name of the main Terraform file (no extension required). Default: main",
            Mandatory = $false
        )]
        [string]
        $MainTerraformFileName = 'main',

        [Parameter(
            HelpMessage = "Snippet to add to the terraform main file",
            Mandatory = $true
        )]
        [string]
        $TerraformSnippet
    )

    process {
        Export-Terraform -MainTerraformFileName $MainTerraformFileName -TerraformSnippet $TerraformSnippet -OutputFilePath $OutputFilePath

    }

}

# Accountable of the exporting all terraform related operations
function Export-Terraform {
    [CmdletBinding()]
    param (
        # Parameter main.tf file path as output
        [Parameter(
            HelpMessage = "Path where will be saved the output Main.tf within the backend configuration. Default: script execution folder.",
            Mandatory = $false
        )]
        [string]
        $OutputFilePath,

        # Name of the terraform main file
        [Parameter(
            HelpMessage = "Name of the main Terraform file (no extension required). Default: main",
            Mandatory = $false
        )]
        [string]
        $MainTerraformFileName = 'main',

        [Parameter(
            HelpMessage = "Snippet to add to the terraform main file",
            Mandatory = $true
        )]
        [string]
        $TerraformSnippet
    )
    
    process {

        if ($MainTerraformFileName -contains ".tf") {
            $mainTfName = $MainTerraformFileName
        }
        else {
            $mainTfName = "$($MainTerraformFileName).tf"
        }

        Write-Host "mainTfName -> $mainTfName" 
        Write-Host "MainTerraformFileName -> $MainTerraformFileName"

        if ([string]::IsNullOrEmpty($OutputFilePath) -or [string]::IsNullOrWhiteSpace($OutputFilePath) ) {
            $terraformFileOutput = (Get-Location).Path
        }
        else {
            $terraformFileOutput = $OutputFilePath 
        }

        Write-Host "terraformFileOutput -> $terraformFileOutput" 
        Write-Host "OutputFilePath -> $OutputFilePath"

        try {
            $terraformPath = Join-Path -Path $terraformFileOutput -ChildPath $mainTfName -Resolve
        }
        catch {
            Write-Error "file $($mainTfName) or path $($terraformFileOutput) does not exists."
        }

        # Adds terraform snippet to the main file
        Add-Content -Path $terraformPath -Value $TerraformSnippet

        Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Il seguente snippet per configurare il backend di Terraform è stato salvato nel file $($MainTerraformFileName) al seguente percorso"
        Write-Host -ForegroundColor Green -BackgroundColor Black -Object "$($terraformFileOutput)"
        $TerraformSnippet
    }
    
}


Export-ModuleMember -Function Set-TerraformFolder
