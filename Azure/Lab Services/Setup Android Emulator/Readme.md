# Setup Android Emulator

## Table of contents
* [Reference](https://github.com/AngelusGi/PowerShell/tree/master/Azure/Lab%20Services/Setup%20Android%20Emulator#reference)
* [How to use](https://github.com/AngelusGi/PowerShell/tree/master/Azure/Lab%20Services/Setup%20Android%20Emulator#how-to-use)
* [How to configure](https://github.com/AngelusGi/PowerShell/tree/master/Azure/Lab%20Services/Setup%20Android%20Emulator#how-to-configure)
* [Example](https://github.com/AngelusGi/PowerShell/tree/master/Azure/Lab%20Services/Setup%20Android%20Emulator#example)
* [Troubleshooting](https://github.com/AngelusGi/PowerShell/tree/master/Azure/Lab%20Services/Setup%20Android%20Emulator#troubleshooting)

## Reference
* [Azure VMs that support nested virtualization](https://azure.microsoft.com/blog/nested-virtualization-in-azure/)
* [Azure Lab Services VMs that support nested virtualization](https://docs.microsoft.com/azure/lab-services/administrator-guide#vm-sizing)


## How to use
This script works only on [Azure](https://azure.microsoft.com/blog/nested-virtualization-in-azure/) (and [Azure Lab Services VMs](https://docs.microsoft.com/azure/lab-services/administrator-guide#vm-sizing)) supports nested virtualization.
Run this script <b>as administrator</b>.
After the scrpt end the execution, please <b>reboot the VM</b>.
After the system reboot configure Android Studio as referred in the "[How to configure]()" part.


## How to configure
In tool setting of Android Studio please set: 
* <b>"Program"</b> as
<code>C:\Program Files (x86)\Microsoft Emulator Manager\1.0\emulatorcmd.exe</code>

* <b>"Arguments"</b> as
<code>C:\Program Files (x86)\Microsoft Emulator Manager\1.0</code>

* <b>"Working Directory"</b> as
<code>/sku:Android launch /id:"YOUR-ID"</code>

To obtaion <b>"YOUR-ID"</b> run this <b>PowerShell</b> comand in the VM where you have runned the script in this repository.
<code>emulatorcmd.exe /sku:Android list /type:device</code>

### Settings window
![Android Studio External Tools](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Azure/Lab%20Services/Setup%20Android%20Emulator/Screenshot/AndroidStudio-ExternalTools-Configuration.png)

### Video guide
![How to configure](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Azure/Lab%20Services/Setup%20Android%20Emulator/Screenshot/How-to-configure.gif)


## Example

![Expected-result](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Azure/Lab%20Services/Setup%20Android%20Emulator/Screenshot/Expected-result.gif)


## Troubleshooting

### How to download the script
Please, follow [this guide](https://github.com/AngelusGi/PowerShell/tree/master/Others/How%20to%20download%20single%20file%20from%20GitHub)

### How to change execution Policy
Please, follow [this guide](https://github.com/AngelusGi/PowerShell/tree/master/Others/Resolve%20errors%20about%20Execution%20Policy)