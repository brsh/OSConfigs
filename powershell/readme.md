This contains some of my powershell init stuff, including my profile and my offshoot of a colorful dir lister (similar to ls --color:auto in linux).

### My PowerShell profile 

Containing what I consider to be handy scripts and loading my "preferred" modules and settings. For example, it sets up my PSDrives, checks if I'm running "as admin", and sets up aliases to the microsoft office apps (for easy start up).

**Note: PowerShell x86 and x64 store these files in different locs. These are for x64
```
C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1
```

It includes the following functions/aliases:

Command                   | Alias       | Description
-------                   | -----       | -----------
Find-Commands             | which       | Lists/finds commands with specified text
Find-Files                | find        | Search multiple folders for files
Find-InTextFile           | grep        | Grep with GSAR abilities
Get-LoadedModuleFunctions | glmf        | List functions from loaded modules
Get-ModuleDirs            | moddirs     | List the module directories
Get-NewCommands           | snew        | Show this list
Get-ProfilePSDrive        | PfDrive     | Drives created by PS Profile
Get-Profiles              | Profs       | List PowerShell profile files/paths
Get-SplitEnvPath          | ePath       | Display the path environment var
Get-WifiNetworks          | wifi        | List available wifi networks
GoHome                    | cd~         | Return to home directory
New-File                  | touch       | Create an empty file
New-TimestampedFile       | ntf         | Create a new file w/timestamped filename
Read-Profiles             | re-Profs    | Reload profile files (must . source)
Set-CountDown             | tminus      | Pause with a countdown timer
Test-Port                 | pp          | Test a TCP connection on the specified port
Test-ValidEmail           | isEmail     | Returns true if valid email
Test-ValidIPAddress       | isIP        | Tests for valid IP Address
Test-ValidMACAddress      | isMAC       | Returns true if valid MAC Address




### Modules
```
Location:
Machine-specific:	C:\Windows\System32\WindowsPowerShell\v1.0\Modules
User-specific:		C:\Users\username\Documents\WindowsPowerShell\Modules
 ```

Commands (without brackets: `import-module {Name}`
 
*Directories
..*Get-DirInfo     		Power dir for powershell (colors, sorting...); autoimported via profile above


