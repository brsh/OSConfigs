#goes in C:\Windows\System32\WindowsPowerShell\v1.0 (for all users on current machine)
#C:\WINDOWS\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1
$HistoryText = @'
 Maintenance Log
 Date       By  Updates (important: insert newest updates at top)
 ---------- --- ------------------------------------------------------------------------------
 2016/02/22 BDS Added the call to load the psSysInfo module; adjusted get-ip to not be get-nic
 2016/02/09 BDS Updated battery wmi call and prompt
 2016/01/26 BDS Verify . sourced profile reload and react accordingly
                ModDirs
 2016/01/25 BDS Reload profile!! Fixed battery display and added IP on prompt
 2016/01/15 BDS Updated, more cleaning, made snew dynamic, redid Prog aliases, more...
 2014/09/16 BDS Updated, cleaned up (adjusted ll, lla, added import of Directories module)
 2012/10/26 BDS Created (ok, assembled)
 ---------- ---- ------------------------------------------------------------------------------
'@

###################### Declarations #####################

$Global:IsAdmin=$False
    if( ([System.Environment]::OSVersion.Version.Major -gt 5) -and ( # Vista and ...
          new-object Security.Principal.WindowsPrincipal (
             [Security.Principal.WindowsIdentity]::GetCurrent()) # current user is admin
             ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) )
    {
      $IsAdmin = $True
    } else {
      $IsAdmin = $False
    }

if(!$global:WindowTitlePrefix) {
    # if you're running "elevated" we want to show that ...
    If ($IsAdmin) {
       $global:WindowTitlePrefix = "PowerShell (ADMIN)"
    } else {
       $global:WindowTitlePrefix = "PowerShell"
    }
 }

Set-Variable -name HomeIsLocal -value $True -Scope Global


##################### Modules ##########################

Try { 
    import-Module Directories -ErrorAction Stop
    New-Alias -name ll -value Get-DirInfo -Description "Colorized directory info" -Force
    }
Catch {
    Write-Host "`nDirectories Module not found. Use Show-ModuleDirs to check existence.`n" -ForegroundColor Red
    }

Try { 
    import-Module psSysInfo -ErrorAction Stop
    }
Catch {
    Write-Host "`npsSysInfo Module not found. Use Show-ModuleDirs to check existence.`n" -ForegroundColor Red
    }

Try { 
    import-Module psOutput -ErrorAction Stop
    }
Catch {
    Write-Host "`npsOutput Module not found. Use Show-ModuleDirs to check existence.`n" -ForegroundColor Red
    }

Try { 
    import-Module psPrompt -ErrorAction Stop
    }
Catch {
    Write-Host "`npsPrompt Module not found. Use Show-ModuleDirs to check existence.`n" -ForegroundColor Red
    }

################### Functions #########################

      ############# Converts ###############

function ConvertFrom-SID
 {
  param([string]$SID="S-1-0-0")
  $objSID = New-Object System.Security.Principal.SecurityIdentifier($SID)
  $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
  Return $objUser.Value
 }

 function ConvertTo-SID
 {
  param([string]$ID="Null SID")
  $objID = New-Object System.Security.Principal.NTAccount($ID)
  $objSID = $objID.Translate([System.Security.Principal.SecurityIdentifier])
  Return $objSID.Value
 }

new-alias -name FromSID -value ConvertFrom-SID -Description "Get UserName from SID" -Force
new-alias -name ToSID -value ConvertTo-SID -Description "Get SID from UserName" -Force

Function ConvertTo-URLEncode([string]$InText="You did not enter any text!") {
    [System.Reflection.Assembly]::LoadWithPartialName("System.web") | out-null
    [System.Web.HttpUtility]::UrlEncode($InText)
}

Function ConvertFrom-URLEncode([string]$InText="You+did+not+enter+any+text!") {
    [System.Reflection.Assembly]::LoadWithPartialName("System.web") | out-null
    [System.Web.HttpUtility]::UrlDecode($InText)
}

New-Alias -name "URLEncode" -Value ConvertTo-URLEncode -Description "URL encode a string" -Force
New-Alias -name "URLDecode" -Value ConvertFrom-URLEncode -Description "URL decode a string" -Force

Function ConvertTo-Fahrenheit([decimal]$celsius) {
    $((1.8 * $celsius) + 32 )
} 

Function ConvertTo-Celsius($fahrenheit) {
    $( (($fahrenheit - 32)/9)*5 )
}

New-Alias -name "ToF" -Value ConvertTo-Fahrenheit -Description "Convert degrees C to F" -Force
New-Alias -name "ToC" -Value ConvertTo-Celsius -Description "Convert degrees F to C" -Force



      #############   Info   ###############

function Get-ModuleDirs {
# Enum the module directories
    write-host "PowerShell Module Directories: " -fore White
    ($env:PSModulePath).Split(";") | ForEach-Object { write-host "   "$_ -fore "yellow" }
}

New-Alias -Name moddirs -Value Get-ModuleDirs -Description "List the module directories" -force

function Get-Profiles {
    #use to quickly check which (if any) profile slots are inuse
    $profile| Get-Member *Host*| `
    ForEach-Object {$_.name}| `
    ForEach-Object {$p=@{}; `
    $p.name=$_; `
    $p.path=$profile.$_; `
    $p.exists=(test-path $profile.$_); 
    new-object -TypeName psobject -property $p} | Format-Table -auto
    }
New-Alias -name Profs -value Get-Profiles -Description "List PowerShell profile files/paths" -Force

function Read-Profiles {
#Reload all profiles - helpful when editing/testing profiles
Set-Variable -name isDotSourced -value $False -Scope Global
$isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!($isDotSourced)) { write-host "You must dot source this function" -fore Red; write-host "`t. Load-Profiles`n`t. re-Profs" -ForegroundColor "Yellow"; return "" }
    @(
        $Profile.AllUsersAllHosts,
        $Profile.AllUsersCurrentHost,
        $Profile.CurrentUserAllHosts,
        $Profile.CurrentUserCurrentHost
    ) | ForEach-Object {
        if(Test-Path $_){
            Write-Host "Loading $_"
            . $_
        }
    } 
}

New-Alias -name re-Profs -value Read-Profiles -Description "Reload profile files (must . source)" -Force

function Get-SplitEnvPath {
  #display system path components in a human-readable format
  $p = @(get-content env:path| ForEach-Object {$_.split(";")})
  "Path"
  "===="
  ForEach ($p1 in $p){
    if ($p1.trim() -gt ""){
      $i+=1;
      "$i : $p1"
      }
    }
  ""
  }
new-alias -name ePath -value Get-SplitEnvPath -Description "Display the path environment var" -Force

      #############   Find   ###############

Function Find-Files{
#Find-Files -Locations "\\Server1\c$\Temp", "\\Server1\c$\Test1" -SearchFor "Install.cmd"
    Param([String[]]$Locations, $SearchFor)

    Begin { }

    Process {
        $Files = @()
        ForEach ($Location in $Locations) {
            if (test-path $Location) {
                $Files += Get-ChildItem -Path $Location -Filter $SearchFor -Recurse -ErrorAction SilentlyContinue
           }
        }
    }

    End { return $Files }
}

New-Alias -name find -Value Find-Files -Description "Search multiple folders for files" -Force

function Find-InTextFile { 
    <# 
    .SYNOPSIS 
        Performs a find (or replace) on a string in a text file or files. 
    .EXAMPLE 
        PS> Find-InTextFile -FilePath 'C:\MyFile.txt' -Find 'water' -Replace 'wine' 
     
        Replaces all instances of the string 'water' into the string 'wine' in 
        'C:\MyFile.txt'. 
    .EXAMPLE 
        PS> Find-InTextFile -FilePath 'C:\MyFile.txt' -Find 'water' 
     
        Finds all instances of the string 'water' in the file 'C:\MyFile.txt'. 
    .PARAMETER FilePath 
        The file path of the text file you'd like to perform a find/replace on. 
    .PARAMETER Find 
        The string you'd like to replace. 
    .PARAMETER Replace 
        The string you'd like to replace your 'Find' string with. 
    .PARAMETER NewFilePath 
        If a new file with the replaced the string needs to be created instead of replacing 
        the contents of the existing file use this param to create a new file. 
    .PARAMETER Force 
        If the NewFilePath param is used using this param will overwrite any file that 
        exists in NewFilePath. 
    #> 
    [CmdletBinding(DefaultParameterSetName = 'NewFile')] 
    [OutputType()] 
    param ( 
        [Parameter(Mandatory = $true,Position=1)] 
        [ValidateScript({Test-Path -Path $_ -PathType 'Leaf'})] 
        [string[]]$FilePath, 
        [Parameter(Mandatory = $true,Position=2)] 
        [string]$Find, 
        [Parameter()] 
        [string]$Replace, 
        [Parameter(ParameterSetName = 'NewFile')] 
        [ValidateScript({ Test-Path -Path ($_ | Split-Path -Parent) -PathType 'Container' })] 
        [string]$NewFilePath, 
        [Parameter(ParameterSetName = 'NewFile')] 
        [switch]$Force 
    ) 
    begin { 
        $Find = [regex]::Escape($Find) 
    } 
    process { 
        try { 
            ForEach ($File in $FilePath) { 
                if ($Replace) { 
                    if ($NewFilePath) { 
                        if ((Test-Path -Path $NewFilePath -PathType 'Leaf') -and $Force.IsPresent) { 
                            Remove-Item -Path $NewFilePath -Force 
                            (Get-Content $File) -replace $Find, $Replace | Add-Content -Path $NewFilePath -Force 
                        } elseif ((Test-Path -Path $NewFilePath -PathType 'Leaf') -and !$Force.IsPresent) { 
                            Write-Warning "The file at '$NewFilePath' already exists and the -Force param was not used" 
                        } else { 
                            (Get-Content $File) -replace $Find, $Replace | Add-Content -Path $NewFilePath -Force 
                        } 
                    } else { 
                        (Get-Content $File) -replace $Find, $Replace | Add-Content -Path "$File.tmp" -Force 
                        Remove-Item -Path $File 
                        Rename-Item -Path "$File.tmp" -NewName $File 
                    } 
                } else { 
                    Select-String -Path $File -Pattern $Find 
                } 
            } 
        } catch { 
            Write-Error $_.Exception.Message 
        } 
    } 
}

New-Alias -name grep -value Find-InTextFile -Description "Grep with GSAR abilities" -Force

function Find-Commands { get-command $args"*" }
New-Alias -name which -value Find-Commands -Description "Lists/finds commands with specified text" -Force

      ############# Create   ###############

function New-File($file) { "" | Out-File $file -Encoding ASCII }

New-Alias -name touch -value New-File -Description "Create an empty file" -Force

function New-TimestampedFile() {
Param
  (
  [string]$Folder="",
  [string]$Prefix="temp",
  [string]$Type="log",
    [switch]$Help
  )
    $HelpInfo = @'

    Function : NewTimestampedFile
    By       : xb90 at http://poshtips.com
    Date     : 02/23/2011 
    Purpose  : Creates a unique timestamp-signature text file.
    Usage    : NewTempFile [-Help][-folder <text>][-prefix <text>][-type <text>]
               where      
                      -Help       displays this help
                      -Folder     specify a subfolder or complete path
                                  where the new file will be created
                      -Prefix     a text string that will be used as the 
                                  the new file prefix (default=TEMP)
                      -Type       the filetype to use (default=LOG)
    Details  : This function will create a new file and any folder (if specified)
               and return the name of the file.
               If no parameters are passed, a default file will be created in the
               current directory. Example:
                                           temp_20110223-164621-0882.log
'@    
    if ($help){
        write-host $HelpInfo
        return
        }
  
  #create the folder (if needed) if it does not already exist
  if ($folder -ne "") {
    if (!(test-path $folder)) {
      write-host "creating new folder `"$folder`"..." -back black -fore yellow
      new-item $folder -type directory | out-null
      }
    if (!($folder.endswith("\"))) {
      $folder += "\"
      }
    }

  #generate a unique file name (with path included)
  $x = get-date
  $TempFile=[string]::format("{0}_{1}{2:d2}{3:d2}-{4:d2}{5:d2}{6:d2}-{7:d4}.{8}",
    $Prefix,
    $x.year,$x.month,$x.day,$x.hour,$x.minute,$x.second,$x.millisecond,
    $Type)
  $TempFilePath=[string]::format("{0}{1}",$folder,$TempFile)
    
  #create the new file
  if (!(test-path $TempFilePath)) {
    new-item -path $TempFilePath -type file | out-null
    }
  else {
    throw "File `"$TempFilePath`" Already Exists! (Really weird, since this is a timestamp!)"
    }

  return $TempFilePath
}
New-Alias -Name ntf -value New-TimestampedFile -Description "Create a new file w/timestamped filename" -Force

      #############    Get   ###############

Function Get-AddressToName($addr) {
    [system.net.dns]::GetHostByAddress($addr)
}

Function Get-NameToAddress($addr) {
    [system.net.dns]::GetHostByName($addr)
}

New-Alias -name "n2a" -value Get-NameToAddress -Description "Get IP Address from DNS by Host Name" -Force
New-Alias -name "a2n" -value Get-AddressToName -Description "Get Host Name from DNS by IP Address" -Force


      ######################################

function Test-Port {
Param([string]$srv,$port=80,$timeout=3000,[switch]$verbose)
 
# Does a TCP connection on specified port (80 by default)
$ErrorActionPreference = "SilentlyContinue"
# Create TCP Client
$tcpclient = new-Object system.Net.Sockets.TcpClient
# Tell TCP Client to connect to machine on Port
$iar = $tcpclient.BeginConnect($srv,$port,$null,$null)
# Set the wait time
$wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
# Check to see if the connection is done
if(!$wait)
{
    # Close the connection and report timeout
    $tcpclient.Close()
    if($verbose){Write-Host "Connection Timeout"}
    Return "Dead"
}
else
{
    # Close the connection and report the error if there is one
    $error.Clear()
    $tcpclient.EndConnect($iar) | out-Null
    if(!$?){if($verbose){write-host $error[0]};$failed = $true}
    $tcpclient.Close()
}
 
# Return $true if connection Establish else $False
if($failed){return "Failed"}else{return "Alive"}
}
New-Alias -name pp -Value Test-Port -Description "Test a TCP connection on the specified port" -Force


function Get-WifiNetworks {
    #Note try : Get-WifiNetwork | select index, ssid, signal, 'radio type' | sort signal -desc | ft -auto
    #Doesn't work without the Wireless AutoConfig Service (wlansvc) running... 
    #Might someday work on fixing that...
 end {
    if ($(get-service | where-object { $_.Name -eq "wlansvc" }).Status -eq "Running") { 
        netsh wlan sh net mode=bssid | ForEach-Object -process {
            if ($_ -match '^SSID (\d+) : (.*)$') {
                $current = @{}
                $networks += $current
                $current.Index = $matches[1].trim()
                $current.SSID = $matches[2].trim()
            } 
            else {
                if ($_ -match '^\s+(.*)\s+:\s+(.*)\s*$') {
                    $current[$matches[1].trim()] = $matches[2].trim()
                }
            }
        } -begin { $networks = @() } -end { $networks | ForEach-Object { new-object psobject -property $_ } }
     }
     else {
        write-Host "Wireless AutoConfig Service (wlansvc) is not running."
    }
 }
}

New-Alias -name wifi -value Get-WifiNetworks -Description "List available wifi networks" -Force

function Export-PSCredential {
    param ( 
        #$Credential = (Get-Credential), 
        $Credential = "", 
        $Path = "credentials.enc.xml",
        [switch]$Help)
        
    $HelpInfo = @'

    Function : Export-PSCredential
    Date     : 02/24/2011 
    Purpose  : Exports user credentials to an encoded XML file. Resulting file 
               can be imported using function: Import-PSCredential
    Usage    : Export-PSCredential [-Credential <[domain\]username>][-Path <filename>][-Help]
               where      
                  -Credential specify the user account for which we will create a credential file
                              password will be collected interactively
                  -Path       specify the file to which credential information will be written.
                              if omitted, the file will be "credentials.enc.xml" in the current
                              working directory.
                  -Help       displays this help information
    Note     : Import-PSCredential can be used to decode this file into a PSCredential object and
               MUST BE executed using the same user account that was used to create the encoded file.
               
'@    

    if ($help){
        write-host $HelpInfo
        return
        }
    $Credential = (Get-Credential $credential)
    # Look at the object type of the $Credential parameter to determine how to handle it
    switch ( $Credential.GetType().Name ) {
        # It is a credential, so continue
        PSCredential { continue }
        # It is a string, so use that as the username and prompt for the password
        String { $Credential = Get-Credential -credential $Credential }
        # In all other caess, throw an error and exit
        default { Throw "You must specify a credential object to export to disk." }
        }
    # Create temporary object to be serialized to disk
    $export = "" | Select-Object Username, EncryptedPassword
    # Give object a type name which can be identified later
    $export.PSObject.TypeNames.Insert(0,’ExportedPSCredential’)
    $export.Username = $Credential.Username
    # Encrypt SecureString password using Data Protection API
    # Only the current user account can decrypt this cipher
    $export.EncryptedPassword = $Credential.Password | ConvertFrom-SecureString
    # Export using the Export-Clixml cmdlet
    $export | Export-Clixml $Path
    Write-Host -foregroundcolor Green "Credentials saved to: " -noNewLine
    # Return FileInfo object referring to saved credentials
    Get-Item $Path
  }
New-Alias -Name ecred -value Export-PSCredential -Description "Export user credentials" -Force

function Import-PSCredential {
    param ( $Path = "credentials.enc.xml",
    [switch]$Help)
        
    $HelpInfo = @'

    Function : Import-PSCredential
    Date     : 02/24/2011 
    Purpose  : Imports user credentials from an encoded XML file. 
    Usage    : $cred = Import-PSCredential [-Path <filename>][-Help]
               where   
                  $cred       will contain a PSCredential object upon successful completion               
                  -Path       specify the file from which credentials will be read
                              if omitted, the file will be "credentials.enc.xml" in the current
                              working directory.
                  -Help       displays this help information
    Note     : Credentials can only be decoded by the same user account that was used to 
               create the encoded XML file
               
'@    

    if ($help){
        write-host $HelpInfo
        return
        }

    # Import credential file
        $import = Import-Clixml $Path
        # Test for valid import
        if ( !$import.UserName -or !$import.EncryptedPassword ) {
            Throw "Input is not a valid ExportedPSCredential object, exiting."
          }
        $Username = $import.Username
        # Decrypt the password and store as a SecureString object for safekeeping
        $SecurePass = $import.EncryptedPassword | ConvertTo-SecureString
        # Build the new credential object
        $Credential = New-Object System.Management.Automation.PSCredential $Username, $SecurePass
        Write-Output $Credential
  }
New-Alias -Name icred -value Import-PSCredential -Description "Import user credentials" -Force

function Get-LoadedModuleFunctions {
    param(
        [Parameter(Mandatory=$false)]
        [alias("get","list")]
        [switch] $GetList,
    
        [Parameter(Position=0,Mandatory=$false)]
        [string] $Module = "ALL"
    )

    #An array to skip certain default functions (I load prompt; MS loads readline)
    #BUT, we only want to ignore these if we're looking at the "All" (or general) listing
    $ToIgnore = "prompt", "PSConsoleHostReadline"
    $ProcessIgnore = $true

    #Pull all the script modules currently loaded
    $list = get-Module | Where-Object { $_.ModuleType -match "Script" }

    #If we're looking for the list, just give it and exit
    #This is redundant functionality to get-module, really, but handy to have in the functioin
    if ($GetList) { $list | ft -AutoSize Name,ModuleType,Version; break }

    #Check if we're looking for somthing specific or all modules
    #if specific, we want to limit the $list to that object and process ALL functions, even the generally ignored items
    if ($Module -notmatch "ALL") { $list = $list | Where-Object { $_.Name -eq "$Module" }; $ProcessIgnore = $false }

    #Now, let's process the modules and get their functions!
    $list | ForEach-Object {
        #Quick holder for the module name
        $which = $_.Name

        #Cycle through the functions which exist in the module
        Get-Command -Type function | Where-Object { $_.Source -match "$which" } | ForEach-Object {
            #Set the Don'tSkip to true so we don't skip the processing
            $DontSkip = $True
            #Now, test if we should test for ignored functionsl
            #   and if an ignored function is found, we double-negative Don'tSkip is false, so skip is true
            if ($ProcessIgnore) { if ($ToIgnore -contains $_.Name) { $DontSkip = $false} }
        
            #Now, based on whether we skip or not (don'tskip or do???)
            If ($DontSkip) {
                #Create the infohash for the object with the info we want
                $InfoHash =  @{
                    Alias = $(get-alias -definition $_.Name -ea SilentlyContinue)
                    Command = $_.Name
                    Description = $(Get-help $_.Name).Synopsis
                    Module = $_.Source
                    HelpURI = $_.HelpUri
                    Version = $_.Version
                }
                $InfoStack = New-Object -TypeName PSObject -Property $InfoHash

                #Add a (hopefully) unique object type name
                $InfoStack.PSTypeNames.Insert(0,"Cmd.Information")

                #Sets the "default properties" when outputting the variable... but really for setting the order
                $defaultProperties = @('Command', 'Alias', 'Module', 'Description')
                $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
                $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
                $InfoStack | Add-Member MemberSet PSStandardMembers $PSStandardMembers

                #And output
                $InfoStack
            }
        }
    }
}

New-Alias -name glmf -Value Get-LoadedModuleFunctions -Description "List functions from loaded modules" -force

Function Get-NewCommands {
    # Displays a list of aliases that have descriptions
    # Each alias in this file is created with descriptions,
    # Hence, this shows the list of aliases in this file
    # (maybe more!)
    $CommandWidth=25
    $AliasWidth=12

    $retval = Get-Alias | where-object { $_.Description } 
    
    $retval | Sort-Object ResolvedCommandName -unique | `
        format-table @{Expression={$_.ResolvedCommandName};Label="Command";width=$CommandWidth},@{Expression={$_.Name};Label="Alias";width=$AliasWidth},@{Expression={$_.Description};Label="Description"} 

    Get-LoadedModuleFunctions -Module all | sort command | `
        format-table @{Expression={$_.Command};Label="Command";width=$CommandWidth},@{Expression={$_.Alias};Label="Alias";width=$AliasWidth}, @{Expression={$_.Module};Label="Module";width=15}, Description 
}

New-Alias -name snew -value Get-NewCommands -Description "Show this list" -Force

function Set-CountDown() {
    param(
    [int]$hours=0, 
    [int]$minutes=0, 
    [int]$seconds=0,
    [switch]$help)
    $HelpInfo = @'

    Function : CountDown
    By       : xb90 at http://poshtips.com
    Date     : 02/22/2011 
    Purpose  : Pauses a script for the specified period of time and displays
               a count-down timer to indicate the time remaining.
    Usage    : Countdown [-Help][-hours n][-minutes n][seconds n]
               where      
                      -Help       displays this help
                      -Hours n    specify the number of hours (default=0)
                      -Minutes n  specify the number of minutes (default=0)
                      -Seconds n  specify the number of seconds (default=0)     

'@ 

    if ($help -or (!$hours -and !$minutes -and !$seconds)){
        write-host $HelpInfo
        return
        }
    $startTime = get-date
    $endTime = $startTime.addHours($hours)
    $endTime = $endTime.addMinutes($minutes)
    $endTime = $endTime.addSeconds($seconds)
    $timeSpan = new-timespan $startTime $endTime
    write-host $([string]::format("`nScript paused for {0:#0}:{1:00}:{2:00}",$hours,$minutes,$seconds)) -backgroundcolor black -foregroundcolor yellow
    while ($timeSpan -gt 0) {
        $timeSpan = new-timespan $(get-date) $endTime
        write-host "`r".padright(40," ") -nonewline
        write-host "`r" -nonewline
        write-host $([string]::Format("`rTime Remaining: {0:d2}:{1:d2}:{2:d2}", `
            $timeSpan.hours, `
            $timeSpan.minutes, `
            $timeSpan.seconds)) `
            -nonewline -backgroundcolor black -foregroundcolor yellow
        Start-Sleep 1
        }
    write-host ""
    }

set-alias -name tminus -value Set-CountDown -Description "Pause with a countdown timer" -Force

Function Set-ProgramAliases {
#Create aliases for a list of applications
#Searches directory for multiple versions
#Adds aliases for each version...

    # The list is in 
    #     "alias | program | path"
    # format
    # Separator is the pipe | symbol
    # Each line ends in a comma if it's not the end...
    #    kinda,
    #    like,
    #    this
    $PgmList = (
        "word | winword.exe | c:\progra*\micro*office*",
        "excel | excel.exe | c:\progra*\micro*office*",
        "primal | PrimalScript.exe | c:\progra*\sapien*"
    )

    #Now, cycle through each item and search for the correct path(s)
    ForEach ($item in $PgmList) {
        $name = $item.split("|")[0].trim()
        $found = Find-Files $item.split("|")[2].trim() $item.split("|")[1].trim() | Add-Member -MemberType ScriptProperty -Name ProductName -value { $this.VersionInfo.ProductName } -PassThru | Add-Member -MemberType ScriptProperty -Name Version -value { $this.VersionInfo.ProductVersion } -PassThru | Sort-Object -property @{Expression={$_.Version};Ascending=$False} 
        #Now, if amything was found, test if the alias exists
        #Create it if it doesn't
        ForEach ($file in $found) {
            if (!(test-path Alias:\$name)){
                set-alias -name $name -value $file.Fullname -Description $file.ProductName -scope Global
            }
            #Otherwise, (alias exists) create a new alias with the product version 
            else {
                $name += $file.Version.split(".")[0].trim()
                #But only 1 for each additional major version (so 14.533 and 14.255 will only create 1 alias)
                if (!(test-path Alias:\$name)){
                    set-alias -name $name -value $file.Fullname -Description $file.ProductName -scope Global
                }
            }
        }
    }
}

function GoHome {
###[CmdletBinding( SupportsShouldProcess=$true, ConfirmImpact='High')]
    param( 
        [Parameter(Mandatory=$False,Position=1)]
        [switch]$Local = $HomeIsLocal 
        )

        Set-Variable -name HomeIsLocal -value $Local -Scope Global


    if ( $HomeIsLocal ) {
        $myScriptsDir = "$($env:USERPROFILE)\Documents\Scripts"
    }
    else {
        $myScriptsDir = "$($env:SystemDrive)\Scripts"
    }

    if (!(test-path $myScriptsDir)){
        write-host "creating default scripts directory ($myScriptsDir)" -back black -fore green
        new-item -path $myScriptsDir -type directory -Confirm
   	}
    Set-Location $myScriptsDir | out-null

}

New-Alias -name "cd~" -value GoHome -Description "Return to home directory (-Local)" -Force

#####################  Actual Work  #####################

if (!($isDotSourced)) { 
    #ShowHeader
    Get-NewCommands
    
    #Create the "standard" aliases for programs
    Set-ProgramAliases

    GoHome
}
