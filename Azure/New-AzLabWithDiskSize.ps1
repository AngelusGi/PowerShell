<#
.SYNOPSIS 
    This script creates a new managed Lab with extended OS disk size.

.DESCRIPTION
    It allows the creation of a managed Lab whose VMs have extended disk size. The attached Shared Image Gallery is used to import a generalized image that has expanded disk. 

.PARAMETER LabAccountResourceGroupName
    Mandatory. Resource group name of Lab Account.

.PARAMETER LabAccountName
    Mandatory. Name of Lab Account.

.PARAMETER LabName
    Mandatory. Name of Lab to create.

.PARAMETER SharedImageGalleryResourceGroupName
    Mandatory. Resource group of the SIG attached to the Lab Account.

.PARAMETER SharedImageGalleryName
    Mandatory. Name of the SIG attached to the Lab Account.

.PARAMETER Size
    Mandatory. Size for template VM.

.PARAMETER UserName
    Mandatory. User name if shared password is enabled.

.PARAMETER Password
    Mandatory. Password if shared password is enabled.

.PARAMETER LinuxRdpEnabled
    Optional. Whether enabling RDP or not for Linux-based labs.

.PARAMETER MarketplaceImageName
    Optional. The friendly marketplace image name upon which the VM will be built. These include: Win2016Datacenter, Win2012R2Datacenter, Win2012Datacenter, Win2008R2SP1, UbuntuLTS, CentOS, CoreOS, Debian, openSUSE-Leap, RHEL, SLES (Defaults to Win2016Datacenter).

.PARAMETER LabOSDiskSize
    Optional. OS Disk size for the managed VMS (defaults to 126GB).

.PARAMETER UsageQuotaInHours
    Optional. Quota of hours x users (defaults to 40)

.PARAMETER SharedPasswordEnabled
    Optional. Whether the same credentials are shared among the VMs in the lab.

.EXAMPLE
    New-AzLabWithDiskSize `
        -LabAccountResourceGroupName $LabAccountResourceGroupName `
        -LabAccountName $LabAccountName `
        -LabName "IT Infrastructure" `
        -SharedImageGalleryResourceGroupName $SharedImageGalleryResourceGroupName `
        -SharedImageGalleryName $SharedImageGalleryName `
        -Size Performance `
        -UserName vmuser `
        -Password VirtualMachineUser6.,. `
        -MarketplaceImageName "Win2019Datacenter" `
        -LabOSDiskSize 500 `
        -UsageQuotaInHours 20 `
        -SharedPasswordEnabled 

.NOTES
    Currently support only Images from the Azure Marketplace.
    Nice add: Expand the size of a lab starting from an Image in the Shared Image Gallery. E.g. professor wants to start from an already existing lab. 

#>
[CmdletBinding()]
param(
    [parameter(Mandatory = $true, HelpMessage = "Resource group name of Lab Account", ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    $LabAccountResourceGroupName,

    [parameter(Mandatory = $true, HelpMessage = "Name of Lab Account", ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    $LabAccountName,
  
    [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "OS Disk size for the managed VMS (defaults to 126GB)")]
    [ValidateNotNullOrEmpty()]
    $LabName,

    [parameter(Mandatory = $true, HelpMessage = "Resource group of the SIG attached to the Lab Account", ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    $SharedImageGalleryResourceGroupName,

    [parameter(Mandatory = $true, HelpMessage = "Name of the SIG attached to the Lab Account", ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    $SharedImageGalleryName,

    [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Size for template VM")]
    [ValidateNotNullOrEmpty()]
    $Size,

    [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "User name if shared password is enabled")]
    [string]
    $UserName,

    [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Password if shared password is enabled")]
    [string]
    $Password,

    [parameter(mandatory = $false, ValueFromPipelineByPropertyName = $true)]
    [switch]
    $LinuxRdpEnabled = $false,

    [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, HelpMessage = "The friendly marketplace image name upon which the VM will be built. These include: Win2016Datacenter, Win2012R2Datacenter, Win2012Datacenter, Win2008R2SP1, UbuntuLTS, CentOS, CoreOS, Debian, openSUSE-Leap, RHEL, SLES (Defaults to Win2016Datacenter)")]
    [string]
    $MarketplaceImageName = "Win2016Datacenter",

    [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, HelpMessage = "Maximum number of users in lab (defaults to 5)")]
    [int]
    $LabOSDiskSize = 126,

    [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, HelpMessage = "Quota of hours x users (defaults to 40)")]
    [int]
    $UsageQuotaInHours = 40,

    [parameter(mandatory = $false, ValueFromPipelineByPropertyName = $true)]
    [switch]
    $SharedPasswordEnabled = $false
)

# ALS Module dependency
$AzLabServicesModuleName = "Az.LabServices.psm1"
$AzLabServicesModuleSource = "https://raw.githubusercontent.com/Azure/azure-devtestlab/master/samples/ClassroomLabs/Modules/Library/Az.LabServices.psm1"

$global:AzLabServicesModulePath = Join-Path -Path (Resolve-Path ./) -ChildPath $AzLabServicesModuleName

function Import-RemoteModule {
    param(
        [ValidateNotNullOrEmpty()]
        [string] $Source,
        [ValidateNotNullOrEmpty()]
        [string] $ModuleName
    )
  
    $modulePath = Join-Path -Path (Resolve-Path ./) -ChildPath $ModuleName
  
    if (Test-Path -Path $modulePath) {
        # if the file exists, delete it - just in case there's a newer version, we always download the latest
        Remove-Item -Path $modulePath
    }
  
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($Source, $modulePath)
  
    Import-Module $modulePath
}
  
function Import-AzLabServicesModule {
    Import-RemoteModule -Source $AzLabServicesModuleSource -ModuleName $AzLabServicesModuleName
}

try {

    Import-AzLabServicesModule

    $LabAccount = Get-AzLabAccount -ResourceGroupName $LabAccountResourceGroupName -LabAccountName $LabAccountName

    # Get the Shared Image Gallery attached to the Lab Account 
    $SharedImageGallery = Get-AzGallery -ResourceGroupName $SharedImageGalleryResourceGroupName -Name $SharedImageGalleryName -ErrorAction Stop

    $VmName = "vm"
    $VmResourceGroupName = $VmName + $LabAccountResourceGroupName
    $VmLocation = "westeurope" # use this default location for the temporary Azure VM

    # Create a temporary resource group where to create the starting VM
    New-AzResourceGroup -Name $VmResourceGroupName -Location $VmLocation

    # Create the base VM
    $VmLocalAdminUser = $UserName
    $VmLocalAdminSecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ($VmLocalAdminUser, $VmLocalAdminSecurePassword);

    $VnetName = $VmName + "Vnet"
    $SubnetName = $VmName + "Subnet"
    $SecurityGroupName = $VmName + "NetworkSecurityGroup"
    $PublicIpAddressName = $VmName + "PublicIpAddress"
    
    $Vm = New-AzVm `
        -ResourceGroupName $VmResourceGroupName `
        -Name $VmName `
        -Credential $Credential `
        -Location $VmLocation `
        -VirtualNetworkName $VnetName `
        -SubnetName $SubnetName `
        -SecurityGroupName $SecurityGroupName `
        -PublicIpAddressName $PublicIpAddressName `
        -Image $MarketplaceImageName `
        -OpenPorts 80, 3389 -ErrorAction Stop

    # Expand the disk
    Stop-AzVM `
        -ResourceGroupName $VmResourceGroupName `
        -Name $VmName -Force

    $VmOsDisk = Get-AzDisk -ResourceGroupName $VmResourceGroupName -DiskName $Vm.StorageProfile.OsDisk.Name
    $VmOsDisk.DiskSizeGB = $LabOSDiskSize
    Update-AzDisk -ResourceGroupName $VmResourceGroupName -Disk $VmOsDisk -DiskName $VmOsDisk.Name

    # Run remote setup on the VM:
   
    Start-AzVM -ResourceGroupName $VmResourceGroupName -Name $VmName

    # Windows
    # 1) Resize the Windows C Partition adding the new unallocated space
    # 2) Sysprep the VM. ALS currently only support Generalized Images
    $SetupVMScriptWindowsContent = @"
# Resize the Windows C Partition adding the new unallocated space
`$Partition = Get-Volume -FileSystemLabel 'Windows' | Get-Partition
`$PartitionSupportedSize = `$Partition | Get-PartitionSupportedSize
`$Partition | Resize-Partition -Size `$PartitionSupportedSize.SizeMax

# Sysprep the VM
C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown /quiet
"@

    # Linux
    # 1) Resizing the Linux Partition adding the new unallocated space depends on the actual distro and partitions.
    #    To keep things simple let's do it manually on the Template VM.
    # 2) Removing the Azure Linux Agent results in the timeout of Invoke-AzVMRunCommand. But it gets the job done. Ok until we find a better approach..
    $SetupVMScriptLinuxContent = @"
    # Resizing the Linux Partition adding the new unallocated space depends on the actual distro and partitions
    # https://docs.microsoft.com/en-us/azure/virtual-machines/linux/expand-disks#expand-a-disk-partition-and-filesystem

    # Remove the Azure Linux agent.
    sudo waagent -deprovision+user -force
"@

    $SetupVMScriptPath = "./SetupForExtendedGeneralizedVM.ps1"
    
    $IsWindowsVm = $Vm.StorageProfile.ImageReference.Offer.startswith("Windows")
    if ($IsWindowsVm) {
        $OsType = "Windows"
        $SetupVMScriptContent = $SetupVMScriptWindowsContent
        $VMRunCommandId = "RunPowerShellScript"
    }
    else {
        $OsType = "Linux"
        $SetupVMScriptContent = $SetupVMScriptLinuxContent
        $VMRunCommandId = "RunShellScript"
    }
    
    # Create a local temporary script file
    New-Item -Path $SetupVMScriptPath -ItemType File -Value $SetupVMScriptContent
    
    # Run the remote command
    Invoke-AzVMRunCommand -ResourceGroupName $VmResourceGroupName -VMName $VmName -CommandId $VMRunCommandId -ScriptPath $SetupVMScriptPath
    
    # Remove the temporary script file
    Remove-Item -Path $SetupVMScriptPath

    Stop-AzVM `
        -ResourceGroupName $VmResourceGroupName `
        -Name $VmName -Force
    # Set the status of the virtual machine to Generalized
    Set-AzVm -ResourceGroupName $VmResourceGroupName -Name $VmName -Generalized

    # Create an image snapshot for the generalized VM
    $VmImageName = $VmName + "Image"
    $VmImageConfig = New-AzImageConfig -Location $SharedImageGallery.Location -SourceVirtualMachineId $Vm.Id 
    $VmImage = New-AzImage -Image $VmImageConfig -ImageName $VmImageName -ResourceGroupName $VmResourceGroupName

    # Import the snapshot into the SIG
    $SIGImageDefinitionName = $VmName + "ImageDefinition"
    $SIGImageDefinitionPublisher = $VmName + "Publisher"
    $SIGImageDefinitionOffer = $VmName + "Offer"
    $SIGImageDefinitionSku = $VmName + "SKU"
    $SIGImageDefinition = New-AzGalleryImageDefinition `
        -GalleryName $SharedImageGallery.Name `
        -ResourceGroupName $SharedImageGallery.ResourceGroupName `
        -Location $SharedImageGallery.Location `
        -Name $SIGImageDefinitionName `
        -OsState generalized `
        -OsType $OsType `
        -Publisher $SIGImageDefinitionPublisher `
        -Offer $SIGImageDefinitionOffer `
        -Sku $SIGImageDefinitionSku
                             
    $TargetRegion = @{Name = 'West Europe'; ReplicaCount = 1 }
    New-AzGalleryImageVersion `
        -GalleryImageDefinitionName $SIGImageDefinition.Name `
        -GalleryImageVersionName '0.0.1' `
        -GalleryName $SharedImageGallery.Name `
        -ResourceGroupName $SharedImageGallery.ResourceGroupName `
        -Location $SharedImageGallery.Location `
        -TargetRegion $TargetRegion `
        -Source $VmImage.Id.ToString() `
        -PublishingProfileEndOfLifeDate '2022-01-01'

    # Lab Services uses the lowercase <sig_name>-<image_definition_name> format to identify the imported image definition
    $ALSSIGImageDefinitionName = $SharedImageGallery.Name + "-" + $SIGImageDefinition.Name
    $ALSSIGImageDefinitionName = $ALSSIGImageDefinitionName.ToLower()

    $LabSIGImage = $LabAccount | Get-AzLabAccountSharedImage | Where-Object { $_.name -like $ALSSIGImageDefinitionName }

    $NewAzLabParams = @{
        LabAccount            = $LabAccount
        LabName               = $LabName
        Image                 = $LabSIGImage
        Size                  = $Size
        UserName              = $UserName
        Password              = $Password
        LinuxRdpEnabled       = $LinuxRdpEnabled
        UsageQuotaInHours     = $UsageQuotaInHours
        SharedPasswordEnabled = $SharedPasswordEnabled
    }

    New-AzLab @NewAzLabParams
}
catch {
    $message = $error[0].Exception.Message
    if ($message) {
        Write-Host -Object "ERROR: $message" -ForegroundColor Red
    }
}
finally {

    # Remove the temporarily created resource group for the VM
    Remove-AzResourceGroup -Name $VmResourceGroupName -Force
    
    # Delete the Image Version and Definition (in order)
    Remove-AzGalleryImageVersion `
        -GalleryImageDefinitionName $SIGImageDefinition.Name `
        -GalleryImageVersionName '0.0.1' `
        -GalleryName $SharedImageGallery.Name `
        -ResourceGroupName $SharedImageGallery.ResourceGroupName -Force

    # It takes a few seconds for the image version to be released. Without this, removing image definition will fail.
    Start-Sleep -s 15
    
    Remove-AzGalleryImageDefinition `
        -GalleryName $SharedImageGallery.Name `
        -ResourceGroupName $SharedImageGallery.ResourceGroupName `
        -Name $SIGImageDefinitionName -Force

    # Make a sound to indicate we're done if running from command line.
    1..3 | ForEach-Object { [console]::beep(2500, 300) }
}