# Create users and export password

## Table of contents
* [References](https://github.com/AngelusGi/PowerShell/tree/master/Office365/User%20Creation/Create%20users%20and%20export%20password#references)
* [How to use](https://github.com/AngelusGi/PowerShell/tree/master/Office365/User%20Creation/Create%20users%20and%20export%20password#how-to-use)
* [Examples](https://github.com/AngelusGi/PowerShell/tree/master/Office365/User%20Creation/Create%20users%20and%20export%20password#examples)
* [Troubleshooting](https://github.com/AngelusGi/PowerShell/tree/master/Office365/User%20Creation/Create%20users%20and%20export%20password#troubleshooting)


## References
* [Azure Active Directory PowerShell Module - MSOnline](https://docs.microsoft.com/en-us/powershell/module/msonline/?view=azureadps-1.0#msonline)
* [New-MsolUser Command](https://docs.microsoft.com/en-us/powershell/module/msonline/new-msoluser?view=azureadps-1.0)

## How to use

Those parameters are <b>mandatory</b>:
* DomainName -> domain name | ex. "contoso.com" or "contoso.onmicrosoft.com"
* PathCSV -> path of the CSV | ex. ".\csv_test.CSV"
* StaticPswd -> do you want to use the same password for all users at the first login? If yes insert $true and insert the password in "Pswd"

Those parameters are <b>optional</b>:
* Delimiter -> the values' delimiter in the CSV file, if black, the default value is ","
* Pswd -> password for all users at the first login (only if StaticPswd is $true)
* CountryCode -> the country code of the current users, the default value is "IT" (Italy)
* DataLocation -> the country code of the current data location, the default value is "EUR" (Europe)


## Example

![](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Office365/User%20Creation/Create%20users%20and%20export%20password/Screenshot/Example-Running.gif)

### How to run the script - Step 1 A - Script creates a unique complex passowrd for every single user
![How-to-run-the-script](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Office365/User%20Creation/Create%20users%20and%20export%20password/Screenshot/step1_autogenerate_pswd.png)

### How to run the script - Step 1 B - Script uses a single passowrd for all the users
![How-to-run-the-script](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Office365/User%20Creation/Create%20users%20and%20export%20password/Screenshot/step1_static_pswd.png)

### User admin credentials - Step 2
![User-admin-credentials](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Office365/User%20Creation/Create%20users%20and%20export%20password/Screenshot/step2_auth.png)

### Report PowerShell - Step 3 A
![Report-PowerShell](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Office365/User%20Creation/Create%20users%20and%20export%20password/Screenshot/step3.png)

### Report CSV (file) - Step 3 B
[Example-Report-CSV-file](https://github.com/AngelusGi/PowerShell/blob/master/Office365/User%20Creation/Create%20users%20and%20export%20password/ReportUtentiCorrettamenteCreati.csv)

### Report CSV (import in Excel) - Step 3 C
![Example-Report-Excel-1](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Office365/User%20Creation/Create%20users%20and%20export%20password/Screenshot/Report-Excel-1.png)

![Example-Report-Excel-2](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Office365/User%20Creation/Create%20users%20and%20export%20password/Screenshot/Report-Excel-2.png)

## Troubleshooting

### How to download the script
Please, follow [this guide](https://github.com/AngelusGi/PowerShell/tree/master/Others/How%20to%20download%20single%20file%20from%20GitHub)

### How to change execution Policy
Please, follow [this guide](https://github.com/AngelusGi/PowerShell/tree/master/Others/Resolve%20errors%20about%20Execution%20Policy)

### How to get the SKU License Name
Please, follow [this guide](https://github.com/AngelusGi/PowerShell/master/Others/How%20to%20get%20sku%20licenses/)