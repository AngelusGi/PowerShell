[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [String]
    $GroupName
)


# Region module manager

function CheckModules {
    param (
        $Modules,
        $Scope
    )
    process {

        $installedModules = Get-InstalledModule

        foreach ($module in $Modules) {
            
            $GalleryModule = Find-Module -Name $module

            $mod = $installedModules | Where-Object { $_.Name -eq $module }
        
            if ([string]::IsNullOrEmpty($mod) -or [string]::IsNullOrWhiteSpace($mod)) {
                Write-Host("Modulo $($module) non trovato. Installazione in corso...")
                Install-Module -Name $module -Scope $Scope
            }
            else {
                Write-Host("Modulo $($module) trovato.")

                if ($GalleryModule.Version -ne $mod.Version) {
                    Write-Host("Aggionamento del modulo $($module) in corso...")

                    Update-Module -Name $module
                }
            }

            Import-Module -Name $module
        }

        
    }
}

function VerifyPsVersion {
    
    process {
        
        Write-Warning("Verifica dell'ambiente in corso, attendere...")

        # if ($PSVersionTable.PSVersion.Major -ne 5) {
        #     Write-Error("Questo script può essere eseguito solo con la versione 5 di Windows PowerShell")
        #     exit
        # }
    }
}

function InstallLocalModules {
    param (
        $Scope,
        $Modules
    )

    process {

        VerifyPsVersion

        CheckModules -Modules $Modules -Scope $Scope
        
    }
    
}

# End parameters region


InstallLocalModules -Modules "azureadpreview"

$AllowGroupCreation = $False

Connect-AzureAD

$settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
if(!$settingsObjectID)
{
    $template = Get-AzureADDirectorySettingTemplate | Where-object {$_.displayname -eq "group.unified"}
    $settingsCopy = $template.CreateDirectorySetting()
    New-AzureADDirectorySetting -DirectorySetting $settingsCopy
    $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
}

$settingsCopy = Get-AzureADDirectorySetting -Id $settingsObjectID
$settingsCopy["EnableGroupCreation"] = $AllowGroupCreation

if($GroupName)
{
  $settingsCopy["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString $GroupName).objectid
}
 else {
$settingsCopy["GroupCreationAllowedGroupId"] = $GroupName
}
Set-AzureADDirectorySetting -Id $settingsObjectID -DirectorySetting $settingsCopy

(Get-AzureADDirectorySetting -Id $settingsObjectID).Values

Disconnect-AzureAD
