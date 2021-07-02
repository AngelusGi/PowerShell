# How to get sku licenses

Follow this procedure:

* Open PowerShell (actually Windows Powershell aka v.5) as Administrator

* Run the following commands

```PowerShell
Install-Module MSOnline -Scope CurrentUser

Import-Module MSOnline

Connect-MSolservice

Get-MsolAccountSku
```

Here a video recording:

![How-to-get-SKU](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Others/How%20to%20get%20sku%20licenses/How-to-get-SKU.gif)
