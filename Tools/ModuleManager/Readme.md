# Module manager - PowerShell library

## Description

This custom module verify if the module is alredy installed, otherwise will install/update it.
It can manage GitHub hosted modules too, such as Azure Lab Services.

## How to use it

```Test-ModuleManager.ps1``` is an example thath shows how to use it.

## Parameters

### Parameter Modules

List of PowerShell modules to be installed.

### Parameter Scope

Scope of the module installation (CurrentUser or AllUsers). Default: CurrentUser.
Accepts only those two values: CurrentUser, AllUsers

### Parameter OnlyPowerShell5

If true, this script has dependecies in order to be executed only on PowerShell 5.x.

### Parameter OnlyAbovePs6

If true, this script has dependecies in order to be executed PowerShell >=6.x.
