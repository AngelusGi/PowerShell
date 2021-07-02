#region parameters

[CmdletBinding()]
param (
    # Resource name prefix
    [Parameter(
        HelpMessage = "Resource prefix (e.g. customer name). Default: MyCustomer",
        Mandatory = $false
    )]
    [string]
    $ResourcePrefix = 'MyCustomer',

    # Azure Subscription Name or Id
    [Alias("AzureSubscriptionName", "AzureSubscriptionId", "AzureSubscription")]
    [Parameter(
        HelpMessage = "Azure Subscription Name or Id",
        Mandatory = $false
    )]
    [string]
    $AzSub,

    # SKU of the Azure Storage Account
    [Alias("StorageAccountSku")]
    [Parameter(
        HelpMessage = "SKU of the Storage Account. Deafult: Standard_LRS",
        Mandatory = $false
    )]
    [string]
    $StgSku = 'Standard_LRS',

    # Resource Group Name
    [Alias("ResourceGroupName", "ResourceGroup")]
    [Parameter(
        HelpMessage = "Resource Group Name. Automatically will be added the postfix '-rg'",
        Mandatory = $false
    )]
    [string]
    $AzResGr,

    # Azure region name
    [Parameter(
        HelpMessage = "Azure region name. Default: westeurope",
        Mandatory = $false
    )]
    [string]
    $AzRegion = 'westeurope',

    # Azure Tag
    [Parameter(
        HelpMessage = "Azure Tag. Default: {
        module = Shared
        app       = MyProject
            iaac      = 'PowerShell'
        }",
        Mandatory = $false
    )]
    [hashtable]
    $AzTag = @{
        app = "MyProject"
        module = "Shared"
        iaac    = 'PowerShell'
    },

    # Stg Acc Container name
    [Parameter(
        HelpMessage = "Name of the container in the Storage Account. Default: terraform",
        Mandatory = $false
    )]
    [string]
    $TerraformContainer = 'terraform',

    # Project Name
    [Parameter(
        HelpMessage = "Project Name will be used to name the Terraform State in the container in the Storage Account. Default: pedu",
        Mandatory = $false
    )]
    [string]
    $ProjectName = 'pedu',

    # Name of the terraform main file
    [Parameter(
        HelpMessage = "Name of the main Terraform file (no extension required). Default: main",
        Mandatory = $false
    )]
    [string]
    $MainTerraformFileName = 'main'

)

#endregion

#region module manager

function PrepareEnvironment {

    param(
        [Parameter(
            HelpMessage = "List of modules to be installed.",
            Mandatory = $true)]
        [string[]]
        $ModulesToInstall,

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
        $Scope = "CurrentUser"
    )

    process {
        $_customMod = "ModuleManager.psm1"
        $_libraryUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/Module%20Manager/$($_customMod)"
        $_client = New-Object System.Net.WebClient
        $_currentPath = Get-Location
        $_downloadPath = Join-Path -Path $_currentPath.Path -ChildPath $_customMod
        $_client.DownloadFile($_libraryUrl, $_downloadPath)
        $_modToImport = Join-Path -Path $_currentPath.Path -ChildPath $_customMod -Resolve
        Import-Module $_modToImport
        Get-EnvironmentInstaller -Modules $ModulesToInstall -CompatibleVersion $OnlyPowerShell5 -Scope $Scope
        Remove-Item -Path $_modToImport -Force
    }

}

#endregion

#region custom functions

function AzureConnect {
    process {
        if ([System.Environment]::OSVersion.Platform -ne "Win32NT") {
            Connect-AzAccount -UseDeviceAuthentication
        }
        else {
            Connect-AzAccount
        }
    }
}

function GetUpperLevelPath {
    process {
        $_separator = ([System.Environment]::OSVersion.Platform -ne "Win32NT") ? "/" : "\"
        
        $_path = (Get-Location).Path
        $_pos = $_path.ToString().LastIndexOf($_separator)

        $_upperLevel = $_path.ToString().Substring(0, $_pos)
        
        if (-not (Test-Path -Path $_upperLevel)) {
            throw "Path non esite $($_upperLevel)"
        }
        
        return $_upperLevel
    }
    
}

function EnsureCustomerPath {
    process {
        $_actualPath = GetUpperLevelPath
        $_baseOutputPath = Join-Path -Path $_actualPath -ChildPath "customers"
        $_customerPath = Join-Path -Path $_baseOutputPath -ChildPath $ResourcePrefix.ToLowerInvariant()
        $_pathList = $_baseOutputPath, $_customerPath

        foreach ($path in $_pathList) {
            if (-not (Test-Path $path)) {
                New-Item -Path $path -ItemType Directory
            }
        }

        $_finalCustomerPath = (Join-Path -Path $_baseOutputPath -ChildPath $ResourcePrefix.ToLowerInvariant() -Resolve).ToString()

        return $_finalCustomerPath
    }
    
}

function PrepareCustomerFolder {
    param (

        [Parameter(Mandatory = $true)]
        [string]
        $CustomerPath
    )

    process {

        
        $_currentPath = (Get-Location).Path
        
        $_fileNameToCopy = "main.tf", "outputs.tf", "providers.tf"
        $_toCopy = New-Object -TypeName 'System.Collections.ArrayList';

        $_childDirs = Get-ChildItem -Path $_currentPath -Directory | Where-Object { $_.Name -eq "modules" }

        if ($null -eq $_childDirs) {
            Write-Error "Questo script deve essere eseguito nel percorso dove e' presente la cartella 'modules'."
            + "`nPredefinito -> 'PowerShell\Tools\Manage Terraform Backend on Azure\'"

            throw "percorso d'esecuzione non corretto!"
        }

        $_toCopy.Add($_childDirs)

        $_childrenFiles = Get-ChildItem -Path $_currentPath -File
        foreach ($fileToCopy in $_fileNameToCopy) {
            $_toCopy.Add(
                ($_childrenFiles | Where-Object { $_.Name -eq $fileToCopy })
            )
        }

        foreach ($element in $_toCopy) {
            Copy-Item -Path $element.FullName -Destination $CustomerPath
        }

    }
    
}

function ExportCustomerTerraform {
    param (
        [Parameter(
            Mandatory = $true
        )]
        [string]
        $MainTerraformFileName,

        [Parameter(
            Mandatory = $true
        )]
        $StorageAccount,
        
        [Parameter(
            Mandatory = $true
        )]
        $StorageContainer
    )

    process {

        $_outputPath = EnsureCustomerPath
        
        if ($_outputPath.GetType().Name -eq "String") {
            PrepareCustomerFolder -CustomerPath $_outputPath
        } else {
            $_outputPath = $_outputPath[$_outputPath.Count - 1]
            PrepareCustomerFolder -CustomerPath $_outputPath
        }

        $_terraformFileOutput = Join-Path -Path $_outputPath -ChildPath "$($MainTerraformFileName).tf" -Resolve

        $_terraformOutput = GetTerraformOutput -StorageAccount $StorageAccount -StorageContainer $StorageContainer

        Add-Content -Path "$($CustomerPath)$($_terraformFileOutput)" -Value $_terraformOutput
        
        Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Il seguente snippet per configurare il backend di Terraform è stato salvato nel file $($MainTerraformFileName) al seguente percorso"
        Write-Host -ForegroundColor Green -BackgroundColor Black -Object "$($_customerPath)$($_terraformFileOutput)"
        $_terraformOutput
    }
    
}

function GetTerraformOutput {
    param (
        [Parameter(
            Mandatory = $true
        )]
        $StorageAccount,
        
        [Parameter(
            Mandatory = $true
        )]
        $StorageContainer
    )

    process {
        $_terraformFileName = $ResourcePrefix.ToLowerInvariant() + "-" + $ProjectName

        $_terraformOutput =
        "terraform {`n`tbackend ""azurerm"" {`n`t`tresource_group_name = ""$($StorageAccount.ResourceGroupName)""`n`t`tstorage_account_name = ""$($StorageAccount.StorageAccountName)""`n`t`tcontainer_name = ""$($StorageContainer.Name)""`n`t`tkey = ""$($_terraformFileName).tfsta""`n`t}`n}`n"

        return $_terraformOutput
    }
    
}

#endregion

#region script body

PrepareEnvironment -Modules "Az" -OnlyAbovePs6 $true

if ([string]::IsNullOrWhiteSpace($AzSub)) {
    AzureConnect
    $actualAz = Get-AzContext
}
else {
    AzureConnect
    $actualAz = Set-AzContext -Subscription $AzSub
}

Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Sottoscrizione attualmente in uso:"
Write-Host -ForegroundColor Green -BackgroundColor Black -Object $actualAz.Name

$AzTag["project"] = "$($ProjectName)"

if ($null -eq $AzResGr) {
    $_rgName = $AzResGr + $ResourcePrefix.ToLowerInvariant()
}
else {
    $_rgName = $ResourcePrefix.ToLowerInvariant() + "-rg"
}

$_rg = Get-AzResourceGroup -Name $_rgName -ErrorAction SilentlyContinue

if ($null -eq $_rg) {
    Write-Warning "Il resource group $($_rgName) indicato non esiste, creazione in corso..."
    $_rg = New-AzResourceGroup -Name $_rgName -Location $AzRegion -Tag $AzTag
}

Write-Output $_rg

$_stgName = $ResourcePrefix.ToLowerInvariant() + "stg"

$_stgNameAvailable = Get-AzStorageAccountNameAvailability -Name $_stgName

if ($_stgNameAvailable.NameAvailable -eq $true) {
    Write-Warning "Lo storage account $($_stgName) indicato non esiste nel gruppo di risorse $($_rg.ResourceGroupName), creazione in corso..."
    $_newStgAcc = New-AzStorageAccount -Name $_stgName -ResourceGroupName $_rg.ResourceGroupName -SkuName $StgSku -Location $_rg.Location -AccessTier Hot -Kind BlobStorage;
}
elseif ($_stgNameAvailable.NameAvailable -eq $false) {

    try {
        $_newStgAcc = Get-AzStorageAccount -ResourceGroupName $_rg.ResourceGroupName -Name $_stgName
    }
    catch {
        Write-Error "Il nome per lo strage account non è disponibile: $($_stgName)"
        exit
    }

}
else {
    Write-Error "Errore: $($_stgNameAvailable.Message)"
}

$_newStgAcc | Select-Object StorageAccountName, Kind, AccessTier, EnableHttpsTrafficOnly, Tags, ProvisioningState

$_stgKeys = Get-AzStorageAccountKey -ResourceGroupName $_newStgAcc.ResourceGroupName -Name $_newStgAcc.StorageAccountName
$_stgKey = $_stgKeys | Where-Object { $_.KeyName -match "key1" }

$_stgContext = New-AzStorageContext -StorageAccountName $_newStgAcc.StorageAccountName -StorageAccountKey $_stgKey.Value -Protocol Https

$_stgContainer = Get-AzStorageContainer -Name $TerraformContainer -Context $_stgContext -ErrorAction SilentlyContinue

if ($null -eq $_stgContainer) {
    Write-Warning "Il container $($TerraformContainer) indicato non esiste nello storage account $($_stgContext.StorageAccountName), creazione in corso..."
    $_stgContainer = New-AzStorageContainer -Name $TerraformContainer -Context $_stgContext
}

$_stgContainer

ExportCustomerTerraform -MainTerraformFileName $MainTerraformFileName -StorageAccount $_newStgAcc -StorageContainer $_stgContainer

Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Account Azure disconnesso."
Disconnect-AzAccount

#endregion
