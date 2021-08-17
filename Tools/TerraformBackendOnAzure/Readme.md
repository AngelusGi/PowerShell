# Script tool: TerraformBackendOnAzure

## Description

This script will configure the ```main.tf``` file in order to store Terraform states on Azure blob storage.

In this folder you can find the main module ```TerraformBackendOnAzure``` within two submodule:

* ```ConfigureTerraformBackend```

* ```ExportTerraformBackendConfig```

## How to use it

```Test-TerraformBackendOnAzure.ps1``` in the folder ```TestScript``` is an example that shows how to use it.
This script is tested to be executed both on Windows or Linux or WSL, the only requirement is to have installed PowerShell >= 6.x [how to do it](https://docs.microsoft.com/powershell/scripting/install/installing-powershell)

To use it as is configured in this repo, please use at least this paramenter:

```PowerShell
prepareTerraformBackend.ps1 -MainFilePath ".\main.tf"
```

After script execution you will see an ```Output``` folder within a new ```main.tf``` file within the configuration to store Terraform backend on Azure.
As shown in the next screenshot.

![Output folder - screenshot example](.\Screenshot\output-screenshot.png)

Whitin an output like this:

![Main terraform within backend configuration - screenshot example](.\Screenshot\terraform-screenshot.png)

## Parameters

### Other parameters

#### Parameter ResourcePrefix

Resource prefix (e.g. project name).
**Default**: TfBackend

#### Parameter MainFilePath

Path from wich will be imported the output ```main.tf``` without the backend configuration.
**Default**: script execution folder.

#### Parameter OutputFilePath

Path where will be saved the output ```main.tf``` within the backend configuration.
**Default**: in the script execution folder will be created a new ```Output``` folder.

### Azure parameters

#### Parameter AzSub

Azure Subscription Name or Id.

#### Parameter AzRegion

Azure region name.
**Default**: westeurope.

#### Parameter AzTag

Azure Tag.
**Default**: {
    app = 'TerraformBackend'
    iac = 'PowerShell'
    }

#### Parameter AzResGroup

Resource Group Name.
Automatically will be added the postfix '-rg' to the ResourcePrefix parameter.
**Default**: TfBackend-rg

#### Parameter AzStorageAccount

Storage Account Name.
Automatically will be added the postfix 'stg' to the ResourcePrefix parameter.
**Default**: tfbackend1234stg

#### Parameter AzStgSku

SKU of the Storage Account.
**Default**: Standard_LRS

#### Parameter TerraformContainer

Name of the container in the Storage Account.
**Default**: terraformstate

#### Parameter AzKeyVault

Key Vault Name.
Automatically will be added the postfix '-kv' to the ResourcePrefix parameter.
**Default**: TfBackend1234-kv

#### Parameter AzKvSku

SKU of the Key Vault.
**Default**: Standard

### Terraform parameters

#### Parameter MainTerraformFileName

Name of the main Terraform file (no extension required).
**Default**: main
