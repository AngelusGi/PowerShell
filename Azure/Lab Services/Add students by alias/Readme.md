# Add students to Azure Lab Services by email alias


## How to use

Those parameters are <b>mandatory</b>:
* PathCSV -> path of the CSV | ex. ".\Add-Students-By-Alias.CSV"

Those parameters are <b>optional</b>:
* Delimiter -> the values' delimiter in the CSV file, if black, the default value is ","
* AzureSub -> if you have multiple Azure Subscription, please insert the <b>ID</b> or the <b>Name</b> of the one wich contains the Lab Account

Using default values the script will only add students to the lab. If you want to invite them using this script, consider to use those two optional parameters:
* SendInvitation -> if its value is "$true" the script will invite users to ALS
* WelcomeMessage -> you can use this parameter to send a custom message to users

In this folder you can find an example of the CSV used to run this script, the only <b>mandatory fields</b> are:
* Email
* LabName

<b>This script has dependecies that require to use only Windows PowerShell 5.x</b>


## Example

### How to run the script (NO INVITATION)
![How-to-run-the-script-no-invitation](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Azure/Lab%20Services/Add%20students%20by%20alias/Screenshots/How-to-run-the-script-no-invitation.png)

### How to run the script (INVITATION WITHIN A CUSTOM MESSAGE)
![How-to-run-the-script-no-invitation](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Azure/Lab%20Services/Add%20students%20by%20alias/Screenshots/How-to-run-the-script-invitation.png)

### How it works
![How-it-works](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Azure/Lab%20Services/Add%20students%20by%20alias/Screenshots/How-it-works.gif)

### Faculty view after the script execution
![Faculty-view-after](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Azure/Lab%20Services/Add%20students%20by%20alias/Screenshots/Faculty-view-after.gif)

### Student view after the script execution
![Student-view](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Azure/Lab%20Services/Add%20students%20by%20alias/Screenshots/Student-view.gif)


## Troubleshooting

### How to download the script
Please, follow [this guide](https://github.com/AngelusGi/PowerShell/tree/master/Others/How%20to%20download%20single%20file%20from%20GitHub)

### How to change execution Policy
Please, follow [this guide](https://github.com/AngelusGi/PowerShell/tree/master/Others/Resolve%20errors%20about%20Execution%20Policy)