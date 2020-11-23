# How to resolve porblems about Execution Policy

Running a PowerShell script form this repository, if you recieve an error message like this
>File %USERPROFILE%\ScriptName.ps1 cannot be loaded because running
>scripts is disabled on this system. For more information, see about_Execution_Policies at
>https:/go.microsoft.com/fwlink/?LinkID=135170.

![Error-PowerShel-Execution-Policy](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Others/Resolve%20errors%20about%20Execution%20Policy/Error-PowerShel-Execution-Policy.png)


follow this procedure:
* Open PowerShell as Administrator
* Run the command <br>
<code>Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser</code>
<br>
<br>

![Resolve-Execution-Policy](https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Others/Resolve%20errors%20about%20Execution%20Policy/Resolve-Execution-Policy.gif)