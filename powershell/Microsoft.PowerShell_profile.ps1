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

 if ($PSVersionTable.PSVersion -ge '3.0') {
    #OMG! The Best (accidental) Discovery I've Ever Made!
    #Why is AutoSize not True by default?!!??!
    $PSDefaultParameterValues.Add("Format-Table:AutoSize", {if ($host.Name -eq 'ConsoleHost'){$true}})


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
        $myScriptsDir = $global
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
Set-Variable -name isDotSourced -value $False -Scope 0
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
  Search files for specified keywords

.DESCRIPTION 
    The Find-InTextFile function performs a keyword search on text files. By default,
    the function searches the current folder for files that include the plain text keyword.
    The keyword can be a regular expression if you use the -RegEx switch.
    
    The default view shows the file, line number, and a truncated excerpt of the line.
    To see the entire line of text, use the "-List" switch. 

.EXAMPLE 
    C:\> Find-InTextFile -Keyword foreach -include "*.ps1"
    
    Searches all *.ps1 files from the root of C:\ containing the word "foreach" 

.EXAMPLE
    C:\> Find-InTextFile -path c:\Scripts -keyword alias -Exclude "*.ps?1","*.ps1"

    Searches C:\Scripts for "alias" - but ignores all .ps1 and .psm1, .psd1, etc. files

.EXAMPLE 
    C:\> Find-InTextFile -Keyword ^alias -include "*.*" -regex
    
    Searches all files for lines that start with the word alias

.EXAMPLE 
    C:\> Find-InTextFile -KeyWord "^\s+[Ww]rite" -Recurse -RegEx
    
    Searches all files for lines that start with any number of spaces followed by the word Write or write

.PARAMETER <Path> 
    By default, the path will use your present working directory ($pwd)

.PARAMETER <Recurse> 
    Search subdirectories as well (default is to search only the current folder)

.PARAMETER <Include> 
    The value for this parameter filters by file name; by default it's "*.*" (all files)

.PARAMETER <Keyword> 
    This is the text for which to search. The value can be "plain" text or (with the -RegEx parameter) a regular expression 

.PARAMETER <List> 
    The default output is via Format-Table, which truncates the line with the found text. This switch will use Format-List with the full text of the line visible.

.PARAMETER <CaseSensitive>
    Performs a case sensitive search (KeyWord is different than Keyword or keyword) - of course, Regular Expressions handle case differently....

.PARAMETER <RegEx>
    The keyword is a regular expression and should be treated as such

.PARAMETER <Shorten>
    Tries to shrink the paths and text to fit more in the width of the screen (by replacing the path root with '.' and trimming spaces from text)
#> 
    PARAM( 
        [ValidateScript({ 
            If (Test-Path -Path $_.ToString() -PathType Container) { 
                $true 
            } 
            else { 
                Throw "$_ is not a valid destination folder. Enter in 'c:\directory' format" 
            } 
        })] 
        [String[]] $Path = $pwd, 
        [Alias('Filter')] 
        [String] $Include = "*.*", 
        [String[]] $Exclude,
        [Alias('Text','SearchTerm')]
        [String] $KeyWord = (Read-Host "Please enter the text for which to search: "),
        [Switch] $List,
        [Alias('Subfolders')]
        [Switch] $Recurse = $false,
        [Switch] $CaseSensitive = $false,
        [Alias('IsRegEx','RegularExpression')]
        [Switch] $RegEx = $false,
        [Switch] $NoTotals = $false,
        [Switch] $Shorten = $false
    )
    #Eesh - Get-ChildItem prefers * in the path if you actually want to find items w/out rescurse....
    $Path = (resolve-path $Path).ProviderPath
    $WorkingPath = "$($Path)*"

    if (-not $NoTotals) { Write-Host "`nSearch Root: $Path" }


    $gciParams = @{}
    $gciParams.Path = $WorkingPath
    $gciParams.Filter = $Include
    $gciParams.Recurse = $Recurse
    $gciParams.ErrorAction = 'SilentlyContinue'
    if ($exclude) { $gciParams.Exclude = $Exclude }

    $ssParams = @{}
    $ssParams.Pattern = $KeyWord
    $ssParams.CaseSensitive = $CaseSensitive
    $ssParams.SimpleMatch = -not $RegEx

    Get-ChildItem @gciParams | sort Directory,CreationTime  -Unique | 
        Select-String @ssParams -OutVariable RetVal | Out-Null 

    if ($List) {  
        $RetVal | Format-List -Property Path,LineNumber,Line  
    }  
    else {
        if ($shorten) {
            $pathFormat = @{Expression={$_.Path.ToString().Replace($path,".\")};Label="File"}
            $lineFormat = @{Expression={$_.Line.ToString().Trim()};Label="Text"}
        }
        else {
            $pathFormat = @{Expression={$_.Path};Label="File"}
            $lineFormat = @{Expression={$_.Line};Label="Text"}
    }
        $noFormat = @{Expression={$_.LineNumber};Label="Line"}
        $RetVal | Format-Table -Property $pathFormat,$noFormat,$lineFormat -AutoSize
        if (-not $NoTotals) { Write-Host "Found $($RetVal.Count) results in $(($RetVal | sort Path -unique).Count) files" }
    }
}

New-Alias -name findin -value Find-InTextFile -Description "Search files for specified keywords" -Force

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
        "primal | PrimalScript.exe | c:\progra*\sapien*",
        "sublime | sublime_text.exe | c:\progra*\Sublime*"
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

function Get-Calendar {
    <# 
    .SYNOPSIS 
        Gets a monthly calendar
 
    .DESCRIPTION 
        Returns a monthly calendar for the Month and Year specified (defaults to the current month). Similar to the Linux/Unix cal command.
 
    .PARAMETER Month
        The month (1-12) to return

    .PARAMETER Year
        The Year (1921 or later) to return

    .EXAMPLE
        PS C:\> Get-Calendar

        Returns the calendar
    
    .EXAMPLE
        PS C:\> Get-Calendar -month 4

        Returns the calendar for April of the current year

    .EXAMPLE
        PS C:\> Get-Calendar -month 3 -year 1971

        Returns the calendar for March, 1971
    #> 
  param(
    [Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true)]
    [ValidateRange(1,12)]
    [Int32]$Month = (Get-Date -UFormat %m),
    
    [Parameter(Mandatory=$false,Position=1,ValueFromPipeline=$true)]
    [ValidateScript({$_ -ge 1921})]
    [Int32]$Year = (Get-Date -UFormat %Y)
  )
  
  begin {
    $arr = @()
    $cal = [Globalization.CultureInfo]::CurrentCulture.Calendar
  }

  process {
    function GenArray  {
        param (
            [int]$Total,
            [int]$Start = 1,
            [char]$Character
        )
        $retval = @()
        $Start..$Total | ForEach-Object {
            if ($Character) {
                $retval += [String](($Character.ToString().PadLeft(2)))
            }
            else {
                $retval += [String](($_.ToString().PadLeft(2)))
            }
        }
        $retval
    }
    function WriteHead{
        $Days = 0..6 | ForEach-Object { ([Globalization.DatetimeFormatInfo]::CurrentInfo.AbbreviatedDayNames[$_]).ToString().SubString(0, 2) }
        Write-Host $Days[0..6]
    }

    $FirstDayOfMonth = [Int32]$cal.GetDayOfWeek([DateTime]([String]$Month + ".1." + [String]$Year))
    if ($FirstDayOfMonth -ne 0) {
        #Month starts on a day other than Sunday
        #Fill in some spaces...
        $Hold = 7 # - $FirstDayOfMonth
        $arr += GenArray -Start (7 - $FirstDayOfMonth + 1) -Total $Hold -Character " "
    }
        
    $LastMonth = $arr.Length
    $arr += GenArray $cal.GetDaysInMonth($Year, $Month)

    #And the start of the next next month
    $NextNextMonthStart = $arr.Length
    if ([Bool]($NextNextMonthStart % 7)) {
        $Year = (get-date).AddMonths(1).ToString("yyyy")
        $Month = (get-date).AddMonths(1).ToString("MM")
        $arr += GenArray (7 - ($NextNextMonthStart % 7)) -Character " "
    }
  }
  end {
    $SubCount = 0
    WriteHead
    for ($i = 0; $i -lt $arr.Length; $i+=1) {
        $subcount += 1
        
        #Now actually output the Date Number
        Write-host $arr[$i] -NoNewline
        Write-Host " " -NoNewline
        #And end the line if we're at the end of a week
        if ($SubCount -eq 7) {
            $SubCount = 0
            write-host ""
        }
    }
  }
}

set-alias -name cal -value Get-Calendar -Description "Show current month calendar" -Force

function Get-CurrentCalendar {
    <# 
    .SYNOPSIS 
        Get the previous, current, and next month
 
    .DESCRIPTION 
        Outputs a month calendar of the last, current, and next month with today's date highlighted.
 
    .EXAMPLE
        PS C:\> Get-CurrentCalendar

        Returns the calendar
    #> 
    function GenArray  {
        param (
            [int]$End,
            [int]$Start = 1
        )
        $retval = @()
        $Start..$End | ForEach-Object {
            $retval += [String](($_.ToString().PadLeft(2)))
        }
        $retval
    }
    function WriteHead {
        $Days = 0..6 | ForEach-Object { ([Globalization.DatetimeFormatInfo]::CurrentInfo.AbbreviatedDayNames[$_]).ToString().SubString(0, 2) }
        Write-Host $Days[0..6] -ForegroundColor Green -BackgroundColor Black
    }
    
    $arr = @()
    $cal = [Globalization.CultureInfo]::CurrentCulture.Calendar
    
    $ColorBackDefault = $host.ui.RawUI.BackgroundColor
    $ColorForeFurthest = [System.ConsoleColor]"DarkGray"
    $ColorBackFurthest = $ColorBackDefault
    $ColorForeNotCurrent = [System.ConsoleColor]"DarkCyan"
    $ColorBackNotCurrent = $ColorBackDefault
    $ColorForeToday = [System.ConsoleColor]"Yellow"
    $ColorBackToday = [System.ConsoleColor]"Black"
    $ColorForeCurrentPast = [System.ConsoleColor]"Gray"
    $ColorBackCurrentPast = $ColorBackDefault
    $ColorForeCurrentNext = [System.ConsoleColor]"White"
    $ColorBackCurrentNext = $ColorBackDefault
    
    ##Assemble the Calendar by putting months together
    #Previous Month
    $Year = (get-date).AddMonths(-1).ToString("yyyy")
    $Month = (get-date).AddMonths(-1).ToString("MM")
    
    #On what day does the first of this month fall?
    $FirstDayOfMonth = [Int32]$cal.GetDayOfWeek([DateTime]([String]$Month + ".1." + [String]$Year))
    if ($FirstDayOfMonth -ne 0) {
        #Month starts on a day other than Sunday
        #Fill in the end of the previous previous month
        $HoldYear = (get-date).AddMonths(-2).ToString("yyyy")
        $HoldMonth = (get-date).AddMonths(-2).ToString("MM")
        $Hold = [int]$cal.GetDaysInMonth($HoldYear, $HoldMonth)
        $arr += GenArray -Start ($Hold - $FirstDayOfMonth + 1) -End $Hold
    }
        
    $LastMonth = $arr.Length
    $arr += GenArray -End $cal.GetDaysInMonth($Year, $Month)
    
    #Current Month
    $Year = (get-date).ToString("yyyy")
    $Month = (get-date).ToString("MM")
    
    $CurrMonthStart = $arr.Length
    $arr += GenArray -End $cal.GetDaysInMonth($Year, $Month)
    
    #Next Month
    $Year = (get-date).AddMonths(1).ToString("yyyy")
    $Month = (get-date).AddMonths(1).ToString("MM")
    
    $NextMonthStart = $arr.Length
    $arr += GenArray -End $cal.GetDaysInMonth($Year, $Month)
    
    #And the start of the next next month, if necessary
    $NextNextMonthStart = $arr.Length
    if ([Bool]($NextNextMonthStart % 7)) {
        $Year = (get-date).AddMonths(2).ToString("yyyy")
        $Month = (get-date).AddMonths(2).ToString("MM")
        $arr += GenArray -End (7 - ($NextNextMonthStart % 7))
    }
    
    #Put it all together for output with color
    $SubCount = 0
    write-host "" (get-date -u "%a - %b %d, %Y")
    WriteHead
    for ($i = 0; $i -lt $arr.Length; $i+=1) {
        $subcount += 1
        if ((($LastMonth -gt 0) -and ($i -lt $LastMonth)) -or ($i -ge $NextNextMonthStart)) {
            #Set Color for the oldest and "futurist" months in the list
            $Color = $ColorForeFurthest
            $ColorBack = $ColorBackFurthest
        }
        elseif (($i -lt $CurrMonthStart) -or ($i -ge $NextMonthStart)) {
            #Set Color for Last Month and Next Month
            $Color = $ColorForeNotCurrent
            $ColorBack = $ColorBackNotCurrent
        }
        else {
            #We are in current month - test for today and color it, plus the previous and upcoming days
            $TodaysDate = (get-date -UFormat %d).ToString().PadLeft(2)
            Switch ($arr[$i]) {
                { $_ -eq $TodaysDate } { $Color = $ColorForeToday; $ColorBack = $ColorBackToday; break }
                { $_ -lt $TodaysDate } { $Color = $ColorForeCurrentPast; $ColorBack = $ColorBackCurrentPast; break }
                default { $Color = $ColorForeCurrentNext; $ColorBack = $ColorBackCurrentNext; break }
            }
        }
        #Now actually output the Date Number
        Write-host $arr[$i] -NoNewline -ForegroundColor $Color -BackgroundColor $ColorBack
        Write-Host " " -NoNewline
        #And end the line if we're at the end of a week
        if ($SubCount -eq 7) {
            $SubCount = 0
            write-host ""
        }
    }
    WriteHead
}

set-alias -name curcal -value Get-CurrentCalendar -Description "Show last, current, and next months" -Force


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

## GitHub
if ((Test-Path $env:LOCALAPPDATA\GitHub\shell.ps1) -and ($env:github_git -eq $null)) { 
    #Ok, we have GitHub - let's make a profile psdrive
    New-ProfilePSDrive -name GitHome -Location $env:LOCALAPPDATA\GitHub -Description "Git program and source files"
    #Now I'll parse github's shell.ps1 - pulling out only the code I want
    ##   Anything that sets and environment variable (match $env at the start of a line)
    ##       But not the editor (notmatch EDITOR)
    ##       But not posh_git (notmach posh_git)
    ##   And add the variables needed for the Path statment (match $pGitPath, $appPath, $msBuildPath)
    #and run it as a script expression
    [String]$ShellCodeToRun = ""
    Get-Content $env:LOCALAPPDATA\GitHub\shell.ps1 | Where-Object { 
        (
            (($_.ToString().Trim() -match "^.env") `
            -and ($_ -notmatch "EDITOR") `
            -and ($_ -notmatch "posh_git")) `
            -or ($_.ToString().Trim() -match "^.pGitPath|^.appPath|^.msBuildPath") 
        )
    } | ForEach-Object { $ShellCodeToRun += $_ + ";" }
    if ($ShellCodeToRun.Length -gt 0) { 
        Try {
            Invoke-Expression $ShellCodeToRun 
        }
        Catch {
            write-host "Could not initialize Git!" -ForegroundColor Red -BackgroundColor Black
        }
    }
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
else { 
    #I hate littering the field with random variables
    remove-item variable:\isDotSourced 
}

