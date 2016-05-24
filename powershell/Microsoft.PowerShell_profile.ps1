#goes in C:\Windows\System32\WindowsPowerShell\v1.0 (for all users on current machine)
#C:\WINDOWS\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1

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



################### Functions #########################


   ################## Inits ######################

function Import-MyModules {
    param (
        [Parameter(Position=0, Mandatory=$true)]
        [String] $Name
    )
    try {
        Import-Module $Name -ea stop -Force
    }
    Catch {
        Write-Host "`n$($Name) Module not found. Use Show-ModuleDirs to check existence.`n" -ForegroundColor Red
    }
}

function New-ProfilePSDrive {
    param (
        [Parameter(Position=0, Mandatory=$true)]
        [String] $Name,
        [Parameter(Position=1, Mandatory=$true)]
        [String] $Location,
        [Parameter(Position=2, Mandatory=$false)]
        [String] $Description = ""
    )
    $ReturnTo = $false
    #Check if the drive already exists (can't create it if it does)
    if ($(Get-PSDrive -name $Name -ea SilentlyContinue ) -ne $null) { 
        #Check if we're currently pwd'd to it or a subfolder (we'll want to leave and return to it)
        if ($pwd.Path -match "$($Name):") {
            #Temporarily move to the un-PSDrive'd location
            Set-Location $($pwd.path.Replace("$($Name):", (Get-PSDrive $Name).Root))
            $ReturnTo = $true
        }
        Remove-PSDrive -Name $Name
        
    }
    if ($Description.Length -gt 0) { $Description = "PROF: $($Description)" }
    $null = New-PSDrive -Name $Name -PSProvider FileSystem -Root $Location -Scope Global -ea SilentlyContinue -Description $Description
    if ($ReturnTo) { 
        #Return to the PSDrive'd version
        $null = Set-Location $($pwd.path.Replace((Get-PSDrive $Name).Root, "$($Name):"))
    }
}

function Get-ProfilePSDrive {
    Get-PSDrive | Where-Object { $_.Description -match "PROF:"} | ft Name, Root, Description
}

New-Alias -Name PfDrive -Value Get-ProfilePSDrive -Description "Drives created by PS Profile" -Force

function GoHome {
    <# 
    .SYNOPSIS 
        Set "home" scripts directory 
 
    .DESCRIPTION 
        Sets and/or moves to my working Scripts folder - either personal or shared - as a PSDrive called "Scripts:". Assumes personal is under the current user's profile ("My Documents\Scripts") and shared is under the root of the main hard drive ("C:\Scripts").

        This function will create the folder, if necessary - but it asks first.

        The switch parameter allows switching between personal and shared, so that the Scripts PSDrive "root" is always where I'm working that session. Defaults to local.
 
    .PARAMETER  Switch
        Switches between personal and shared

    .EXAMPLE 
        PS C:\> gohome

        Essentially "cd ~\Scripts" where ~ is either the user's home folder or the root of "C:"
         
    .EXAMPLE 
        PS C:\> gohome -switch

        Switches the Scripts PSDrive to the other location (if currently personal, switches to shared; if shared, switches to personal
    #> 
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$False)]
        [switch]$Switch = $false
    )

    $local = "$($env:USERPROFILE)\Documents\Scripts"
    $global = "$($env:SystemDrive)\Scripts"

    # first test if the Scripts PSDrive exists
    if (Test-Path scripts:) {
        $myScriptsDir = $(get-psdrive Scripts).Root
        #Test is Switch is set
        if ( $Switch ) {
            #And switch
            if ($myScriptsDir -eq $local) {
                $myScriptsDir = $global
            } 
            else {
                $myScriptsDir = $local
            }
        }
    }
    else {
        #It's new - default to local
        $myScriptsDir = $local
    }

    #Test for it and create it if necessary
    if (!(test-path $myScriptsDir)) {
        Write-Host "Creating default scripts directory ($myScriptsDir)" -back black -fore green
        New-Item -Path $myScriptsDir -Type directory -Confirm
    }
    Write-Verbose  "Scripts: is $($myScriptsDir)"
    New-ProfilePSDrive -Name Scripts -Location $myScriptsDir -Description "Default working directory for Scripts"
    Set-Location Scripts:\
}

New-Alias -name "cd~" -value GoHome -Description "Return to home directory" -Force


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


      ############# Network  ###############

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

function Test-ValidIPAddress {
    <# 
    .SYNOPSIS 
        Tests for valid IP Address
 
    .DESCRIPTION 
        Validates that the input text is in the correct format of an IP Address. Tests both IPv4 and IPv6. Can test if the ip is alive by using the -IsAlive switch.
 
    .PARAMETER  Text
        The text you expect to be IP Address
 
    .PARAMETER  IsAlive
        Test that the ip is online and accessible via ICMP
    
    .EXAMPLE
        PS C:\> Test-ValidIPv4Address 192.178.1.1

        Returns true because this is a valid IP Address in form
    #> 
    param (
        [Parameter(Position=0,Mandatory=$true)]
        [string] $Text,
        [Parameter(Position=1,Mandatory=$false)]
        [Switch] $IsAlive = $false
    )
    try {
        if ($Text -eq [System.Net.IPAddress]::Parse($Text)) {
            if ($IsAlive) {
                Test-Connection $Text -Count 1 -EA Stop -Quiet
            } else {
                $true 
            }
        }
    } Catch {
        $false
    }
}

New-Alias -name isIP -Value Test-ValidIPAddress -Description "Tests for valid IP Address" -force


function Test-ValidMACAddress {
    <# 
    .SYNOPSIS 
        Returns true if valid MAC Address
 
    .DESCRIPTION 
        Validates that the input text is in the correct format of a MAC Address.
 
    .PARAMETER  Text
        The text you expect to be a MAC Address
 
    .EXAMPLE
        PS C:\> Test-ValidMACAddress 82-E4-52-1c-C1-39

        Returns true because this is a valid MAC Address
    #> 
    param (
        [Parameter(Position=0,Mandatory=$true)]
        [string] $Text
    )
    $Text -match "^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$"
}

New-Alias -name isMAC -Value Test-ValidMACAddress -Description "Returns true if valid MAC Address" -force


function Test-ValidEmail {
    <# 
    .SYNOPSIS 
        Returns true if valid email
 
    .DESCRIPTION 
        Validates that the input text is in the correct format for email (something@somewhere.domain). Does NOT test that the email address works (can receive/send mail).
 
    .PARAMETER  Text
        The text you expect to be an email address
 
    .EXAMPLE
        PS C:\> Test-ValidEmail me@here.com

        Returns true because this is a valid email address in form (if not in function)
    #> 
    param (
        [Parameter(Position=0,Mandatory=$true)]
        [string] $Text
    )
    $Text -match "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$"
}

New-Alias -name isEmail -Value Test-ValidEmail -Description "Returns true if valid email" -force


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


      ######################################


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
    #$ToIgnore = "prompt", "PSConsoleHostReadline"
    $ToIgnore = $Global:SnewToIgnore
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
            #Set the Skip to false so we don't skip the processing
            $Skip = $false
            #Now, test if we should test for ignored functions or modules
            #and set Skip as appropriate
            if ($ProcessIgnore) { 
                #if ($ToIgnore -contains $_.Name) { $Skip = $True} 
                if ($ToIgnore.Contains($_.Name)) { $Skip = $True} 
                if ($ToIgnore.Contains($_.Source)) { $Skip = $True} 
            }
        
            #Now, based on whether we skip or not
            If (-not $Skip) {
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
            #We have some redundant copies in an Updates folder causing problems... this ignores them
            if (-not $file.Fullname.Contains("Updates")) {
                if (!(test-path Alias:\$name)) {
                    set-alias -name $name -value $file.Fullname -Description $file.ProductName -scope Global
                }
                #Otherwise, (alias exists) create a new alias with the product version 
                else {
                    try {
                        $name += $file.Version.split(".")[0].trim()
                        #But only 1 for each additional major version (so 14.533 and 14.255 will only create 1 alias)
                        if (!(test-path Alias:\$name)){
                            set-alias -name $name -value $file.Fullname -Description $file.ProductName -scope Global
                        }
                    } 
                    Catch { 
                        #Nothing to do here...
                    }
                }
             }
        }
    }
}


#####################  Actual Work  #####################

#(Attempt to) Keep duplicates out of History
Set-PSReadLineOption –HistoryNoDuplicates:$True

#Modules
Import-MyModules Directories
Import-MyModules psSysInfo
Import-MyModules psOutput
Import-MyModules psPrompt

#PSDrives
New-ProfilePSDrive -name Profile -Location $env:USERPROFILE -Description "Home Directory"
New-ProfilePSDrive -name Documents -Location $env:USERPROFILE\Documents -Description "User Documents folder"
New-ProfilePSDrive -name Downloads -Location $env:USERPROFILE\Downloads -Description "User Downloads folder"
New-ProfilePSDrive -name GitHub -Location $env:USERPROFILE\Documents\GitHub -Description "Git master directories"
New-ProfilePSDrive -name PSHome -Location $PSHome -Description "Powershell program folder"

if (Get-Service VMTools -ea SilentlyContinue) {
    New-ProfilePSDrive -name VMHost -Location "\\vmware-host\Shared Folders\$env:username\scripts" -Description "VMHost scripts"
}

#(re)Load any Tool-related scripts, modules, components, etc.
## Git
if (Test-Path $env:LOCALAPPDATA\GitHub\shell.ps1) { 
    . (Resolve-Path "$env:LOCALAPPDATA\GitHub\shell.ps1") 
    New-ProfilePSDrive -name GitHome -Location $env:LOCALAPPDATA\GitHub -Description "Git program and source files"
    if (Test-Path $env:github_posh_git\posh-git.psm1) { Import-MyModules $env:github_posh_git\posh-git }
}


#Only do these next items the first time (initial load)...
if (!($isDotSourced)) { 
    #Create the "standard" aliases for programs
    Set-ProgramAliases
    
    #ShowHeader
    $Global:SnewToIgnore = "prompt", "PSConsoleHostReadline", "posh-git"
    Get-NewCommands
    
    GoHome
}

