# Custom roles for Azure Lab Services

## Reference
To get more details, please visit the related [blog post published on Microsoft Tech Community](https://techcommunity.microsoft.com/t5/azure-lab-services/use-custom-role-to-tailor-teachers-lab-management-permissions/ba-p/2113016) and the related [Microsoft Docs about roles in Azure Lab Services](https://docs.microsoft.com/en-us/azure/lab-services/administrator-guide#manage-identity).

## How to use
Modify a custom role adding your Azure Subscription ID to this role and uplaod it to Access Control (IAM) of your Azure Sub.
After this, assign this custom role to an Azure Lab Service faculty or administrator as usual.

## Available custom roles:
- AzLabService-ScheduleManager -> this role can manage <b>only schedule</b> related stuff (or tab)
- AzLabService-UserManager -> this role can manage <b>only users</b> related stuff (or tab)
- AzLabService-UserManagerAndScheduleManager -> this role can manage <b>only schedule and student</b> related stuff (or tab)

## Example

### How to use it
![How-to-use-it](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Azure/Lab%20Services/Custom%20Permission/Screenshots/How-to-use-it.gif)

### Expected result
![Expected-result](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Azure/Lab%20Services/Custom%20Permission/Screenshots/Expected-Result.gif)

## Troubleshooting

### How to download the script
Please, follow [this guide](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Others/How%20to%20download%20single%20file%20from%20GitHub)

### How to change execution Policy
Please, follow [this guide](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Others/Resolve%20errors%20about%20Execution%20Policy)
