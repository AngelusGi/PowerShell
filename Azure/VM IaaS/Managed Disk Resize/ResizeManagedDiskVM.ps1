# Inspired by https://devblogs.microsoft.com/premier-developer/how-to-shrink-a-managed-disk/


param(
    # Disk -> Properties -> Resource ID - eg. /subscriptions/SubscriptionID/resourceGroups/ResourceGroupName/providers/Microsoft.Compute/disks/DiskName
    [Parameter(AttributeValues)]
    [String]
    $DiskId,

    # Disk -> Properties -> Owner VM - eg. ContosoVM
    [Parameter(AttributeValues)]
    [String]
    $VmName,

    # New Size - eg. 32, 64, ...
    [Parameter(AttributeValues)]
    [int16]
    $DiskSizeGB,

    # Subscription Name - eg: Contoso
    [Parameter(AttributeValues)]
    [String]
    $AzSubscription

)

function PrepareEnvironment {

    param(
        [Parameter(
            HelpMessage = "List of modules to be installed.",
            Mandatory = $true)]
        [string[]]
        $ModulesToInstall,
        
        [Parameter(
            HelpMessage = "If true, this script has dependecies in order to be executed only on PowerShell 5.",
            Mandatory = $false)]
        [bool]
        $OnlyPowerShell5 = $false,

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

        $_moduleFileName = "\$($_customMod)"

        if ([System.Environment]::OSVersion.Platform.Equals("Unix")) {
        $_moduleFileName = "/$($_customMod)"
        }

        $_downloadPath = $_currentPath.Path + $_moduleFileName
        
        $_client.DownloadFile($_libraryUrl, $_downloadPath)

        Import-Module -Name ".$($_moduleFileName)"
        
        Get-EnvironmentInstaller -Modules $ModulesToInstall -CompatibleVersion $OnlyPowerShell5 -Scope $Scope
        
        Remove-Item -Path $_downloadPath -Force
        
    }
    
}


# Script

PrepareEnvironment -ModulesToInstall  "Az"

# Provide your Azure admin credentials
Connect-AzAccount

#Provide the subscription Id of the subscription where snapshot is created
Select-AzSubscription -Subscription $AzSubscription

# VM to resize disk of
$VM = Get-AzVm | Where-Object Name -eq $VmName

#Provide the name of your resource group where snapshot is created
$resourceGroupName = $VM.ResourceGroupName

# Get Disk from ID
$Disk = Get-AzDisk | Where-Object Id -eq $DiskId

# Get VM/Disk generation from Disk
$HyperVGen = $Disk.HyperVGeneration

# Get Disk Name from Disk
$DiskName = $Disk.Name

# Get SAS URI for the Managed disk
$SAS = Grant-AzDiskAccess -ResourceGroupName $resourceGroupName -DiskName $DiskName -Access 'Read' -DurationInSecond 600000;

#Provide the managed disk name
#$managedDiskName = "yourManagedDiskName" 

#Provide Shared Access Signature (SAS) expiry duration in seconds e.g. 3600.
#$sasExpiryDuration = "3600"

#Provide storage account name where you want to copy the snapshot - the script will create a new one temporarily
$storageAccountName = "sashrinkddisk" + ($($VmName -replace '[^a-zA-Z0-9]', '')).ToLower()

#Name of the storage container where the downloaded snapshot will be stored
$storageContainerName = $storageAccountName

#Provide the key of the storage account where you want to copy snapshot. 
#$storageAccountKey = "yourStorageAccountKey"

#Provide the name of the VHD file to which snapshot will be copied.
$destinationVHDFileName = "$($VM.StorageProfile.OsDisk.Name).vhd"

#Generate the SAS for the managed disk
#$sas = Grant-AzureRmDiskAccess -ResourceGroupName $resourceGroupName -DiskName $managedDiskName -Access Read -DurationInSecond $sasExpiryDuration

#Create the context for the storage account which will be used to copy snapshot to the storage account 
$StorageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -SkuName Standard_LRS -Location $VM.Location
$destinationContext = $StorageAccount.Context
$container = New-AzStorageContainer -Name $storageContainerName -Permission Off -Context $destinationContext

#Copy the snapshot to the storage account and wait for it to complete
Start-AzStorageBlobCopy -AbsoluteUri $SAS.AccessSAS -DestContainer $storageContainerName -DestBlob $destinationVHDFileName -DestContext $destinationContext
while (($state = Get-AzStorageBlobCopyState -Context $destinationContext -Blob $destinationVHDFileName -Container $storageContainerName).Status -ne "Success") { $state; Start-Sleep -Seconds 20 }
$state

# Revoke SAS token
Revoke-AzDiskAccess -ResourceGroupName $resourceGroupName -DiskName $DiskName

# Emtpy disk to get footer from
$emptyDiskForFooterName = "$($VM.StorageProfile.OsDisk.Name)-empty.vhd"

# Empty disk URI
#$EmptyDiskURI = $container.CloudBlobContainer.Uri.AbsoluteUri + "/" + $emptydiskforfooter

$diskConfig = New-AzDiskConfig -Location $VM.Location -CreateOption Empty -DiskSizeGB $DiskSizeGB -HyperVGeneration $HyperVGen

$dataDisk = New-AzDisk -ResourceGroupName $resourceGroupName -DiskName $emptyDiskForFooterName -Disk $diskConfig

$VM = Add-AzVMDataDisk -VM $VM -Name $emptyDiskForFooterName -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun 63

Update-AzVM -ResourceGroupName $resourceGroupName -VM $VM

$VM | Stop-AzVM -Force


# Get SAS token for the empty disk
$SAS = Grant-AzDiskAccess -ResourceGroupName $resourceGroupName -DiskName $emptyDiskForFooterName -Access 'Read' -DurationInSecond 600000;

# Copy the empty disk to blob storage
Write-Host("Starting: copy the empty disk to blob storage")
Start-AzStorageBlobCopy -AbsoluteUri $SAS.AccessSAS -DestContainer $storageContainerName -DestBlob $emptyDiskForFooterName -DestContext $destinationContext
while (($state = Get-AzStorageBlobCopyState -Context $destinationContext -Blob $emptyDiskForFooterName -Container $storageContainerName).Status -ne "Success") { $state; Start-Sleep -Seconds 20 }
$state

# Revoke SAS token
Revoke-AzDiskAccess -ResourceGroupName $resourceGroupName -DiskName $emptyDiskForFooterName

# Remove temp empty disk
Remove-AzVMDataDisk -VM $VM -DataDiskNames $emptyDiskForFooterName
Update-AzVM -ResourceGroupName $resourceGroupName -VM $VM

# Delete temp disk
Remove-AzDisk -ResourceGroupName $resourceGroupName -DiskName $emptyDiskForFooterName -Force;

# Get the blobs
$emptyDiskblob = Get-AzStorageBlob -Context $destinationContext -Container $storageContainerName -Blob $emptyDiskForFooterName
$osdisk = Get-AzStorageBlob -Context $destinationContext -Container $storageContainerName -Blob $destinationVHDFileName

$footer = New-Object -TypeName byte[] -ArgumentList 512
write-output "Get footer of empty disk"

$downloaded = $emptyDiskblob.ICloudBlob.DownloadRangeToByteArray($footer, 0, $emptyDiskblob.Length - 512, 512)

$osDisk.ICloudBlob.Resize($emptyDiskblob.Length)
$footerStream = New-Object -TypeName System.IO.MemoryStream -ArgumentList (, $footer)
write-output "Write footer of empty disk to OSDisk"
$osDisk.ICloudBlob.WritePages($footerStream, $emptyDiskblob.Length - 512)

Write-Host -InputObject "Removing empty disk blobs"
$emptyDiskblob | Remove-AzStorageBlob -Force


#Provide the name of the Managed Disk
$NewDiskName = "$DiskName" + "-new"

#Provide the storage type for the Managed Disk. PremiumLRS or StandardLRS.
$accountType = "Premium_LRS"

# Get the new disk URI
$vhdUri = $osdisk.ICloudBlob.Uri.AbsoluteUri

# Specify the disk options
$diskConfig = New-AzDiskConfig -AccountType $accountType -Location $VM.location -DiskSizeGB $DiskSizeGB -SourceUri $vhdUri -CreateOption Import -StorageAccountId $StorageAccount.Id -HyperVGeneration $HyperVGen

#Create Managed disk
$NewManagedDisk = New-AzDisk -DiskName $NewDiskName -Disk $diskConfig -ResourceGroupName $resourceGroupName

$VM | Stop-AzVM -Force

# Set the VM configuration to point to the new disk  
Set-AzVMOSDisk -VM $VM -ManagedDiskId $NewManagedDisk.Id -Name $NewManagedDisk.Name

# Update the VM with the new OS disk
Update-AzVM -ResourceGroupName $resourceGroupName -VM $VM

Write-Host("Starting VM: $VM")
$VM | Start-AzVM
Write-Host("Completed start VM: $VM")

start-sleep 180
# Please check the VM is running before proceeding with the below tidy-up steps

# Delete old Managed Disk
Write-Host("Remove Old Disk: $DiskName")
Remove-AzDisk -ResourceGroupName $resourceGroupName -DiskName $DiskName -Force;

# Delete old blob storage
Write-Host("Remove Old blob storage: $osdisk")
$osdisk | Remove-AzStorageBlob -Force

# Delete temp storage account
Write-Host("Remove temp storage account: $StorageAccount")
$StorageAccount | Remove-AzStorageAccount -Force

Write-Host(" *** OPERATION COMPLETE *** ")
