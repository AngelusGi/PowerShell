# Custom roles for Azure Lab Services

## Table of contents

* [Reference](https://github.com/AngelusGi/PowerShell/tree/master/Azure/Lab%20Services/Custom%20Permission#reference)
* [How to use](https://github.com/AngelusGi/PowerShell/tree/master/Azure/Lab%20Services/Custom%20Permission#how-to-use)
* [Available custom roles](https://github.com/AngelusGi/PowerShell/tree/master/Azure/Lab%20Services/Custom%20Permission#available-custom-roles)
* [Example](https://github.com/AngelusGi/PowerShell/tree/master/Azure/Lab%20Services/Custom%20Permission#example)
* [Troubleshooting](https://github.com/AngelusGi/PowerShell/tree/master/Azure/Lab%20Services/Custom%20Permission#troubleshooting)

## Reference

To get more details, please visit the related [blog post published on Microsoft Tech Community](https://techcommunity.microsoft.com/t5/azure-lab-services/use-custom-role-to-tailor-teachers-lab-management-permissions/ba-p/2113016) and the related [Microsoft Docs about roles in Azure Lab Services](https://docs.microsoft.com/en-us/azure/lab-services/administrator-guide#manage-identity).

## How to use

Modify a custom role adding your Azure Subscription ID to this role and uplaod it to Access Control (IAM) of your Azure Sub.
After this, assign this custom role to an Azure Lab Service faculty or administrator as usual.

## Available custom roles

* AzLabService-ScheduleManager -> this role can manage **only schedule** related stuff (or tab)
* AzLabService-UserManager -> this role can manage **only users** related stuff (or tab)
* AzLabService-UserManagerAndScheduleManager -> this role can manage **only schedule and student** related stuff (or tab)

* AzLabService-TemplateAdministrator -> This user can read all the settings in Azure Lab Services and can **modify only the template tab and VM**. This user can export the VM image in the Shared Image Gallery attached to the Lab Account (if exists).

## Example

### How to use it

![How-to-use-it](https://github.com/AngelusGi/PowerShell/blob/master/Azure/Lab%20Services/Custom%20Permission/Screenshot/How-to-use-it.gif?raw=true)

### Expected result

![Expected-result](https://github.com/AngelusGi/PowerShell/blob/master/Azure/Lab%20Services/Custom%20Permission/Screenshot/Expected-Result.gif?raw=true)

## Troubleshooting

### How to download the file

Please, follow [this guide](https://github.com/AngelusGi/PowerShell/tree/master/Others/How%20to%20download%20single%20file%20from%20GitHub)
