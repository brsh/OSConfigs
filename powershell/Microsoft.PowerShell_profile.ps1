#goes in C:\Windows\System32\WindowsPowerShell\v1.0 (for all users on current machine)
#C:\WINDOWS\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1
$HistoryText = @'
 Maintenance Log
 Date       By   Updates (important: insert newest updates at top)
 ---------- ---- ---------------------------------------------------------------------
 2014/09/16 BDS Updated, cleaned up (adjusted ll, lla, added import of Directories module)
 2012/10/26 BDS Created (ok, assembled)
 ---------- ---- ---------------------------------------------------------------------
'@
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

Try { import-Module Directories -ErrorAction Continue }
Catch {Write-Host "`nDirectories Module not found`n" -ForegroundColor Red}

if(!$global:WindowTitlePrefix) {
    # if you're running "elevated" we want to show that ...
    If ($IsAdmin) {
       $global:WindowTitlePrefix = "PowerShell (ADMIN)"
    } else {
       $global:WindowTitlePrefix = "PowerShell"
    }
 }

$voice = New-Object -ComObject SAPI.SPVoice
$voice.Rate = -3
 
function invoke-speech
{
    param([Parameter(ValueFromPipeline=$true)][string] $say )

    process
    {
        $voice.Speak($say) | out-null;    
    }
}

new-alias -name out-voice -value invoke-speech;

function touch($file) { "" | Out-File $file -Encoding ASCII }

function Translate-FromSID
 {
  param([string]$SID)
  $objSID = New-Object System.Security.Principal.SecurityIdentifier($SID)
  $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
  Return $objUser.Value
 }

 function Translate-ToSID
 {
  param([string]$ID)
  $objID = New-Object System.Security.Principal.NTAccount($ID)
  $objSID = $objID.Translate([System.Security.Principal.SecurityIdentifier])
  Return $objSID.Value
 }

new-alias -name FromSID -value Translate-FromSID;
new-alias -name ToSID -value Translate-ToSID;


$myScriptsDir = "$($env:SystemDrive)\scripts"
$myProfileScript = $MyInvocation.MyCommand.Path
switch ($myProfileScript) {
    $profile.AllUsersAllHosts
	    {$myProfileScript = "`$profile.AllUsersAllHosts"}
	$profile.AllUsersCurrentHost
	    {$myProfileScript = "`$profile.AllUsersCurrentHost"}
	$profile.CurrentUserAllHosts
	    {$myProfileScript = "`$profile.CurrentUserAllHosts"}
	$profile.CurrentUserCurrentHost
	    {$myProfileScript = "`$profile.CurrentUserCurrentHost"}
	}


function list-profiles {
    #use to quickly check which (if any) profile slots are inuse
    $profile|gm *Host*| `
    % {$_.name}| `
    % {$p=@{}; `
    $p.name=$_; `
    $p.path=$profile.$_; `
    $p.exists=(test-path $profile.$_); 
    new-object psobject -property $p} | ft -auto
    }
New-Item -path alias:LPro -value list-profiles | out-null

function split-envpath {
  #display system path components in a human-readable format
  $p = @(get-content env:path|% {$_.split(";")})
  "Path"
  "===="
  foreach ($p1 in $p){
    if ($p1.trim() -gt ""){
      $i+=1;
      "$i : $p1"
      }
    }
  ""
  }
new-item -path alias:epath -value split-envpath |out-null

function Get-LocalDisk{
  Param ([string] $hostname="localhost")
  #Quick Local Disk check
  "***************************************************************"
  "*** $hostname : Local Disk Info"
  Get-WmiObject `
    -computer $hostname `
    -query "SELECT * from Win32_LogicalDisk WHERE DriveType=3" `
    | format-table -autosize `
      DeviceId, `
      VolumeName, `
      @{Label="FreeSpace(GB)"; Alignment="right"; Expression={"{0:N2}" -f ($_.FreeSpace/1GB)}},`
      @{Label="Size(GB)"; Alignment="right"; Expression={"{0:N2}" -f ($_.size/1GB)}} `
    | out-default
    }
New-Item -path alias:gld -value Get-LocalDisk |out-null

New-Alias which get-command

function Get-IP {ipconfig | where-object {$_ –like “*IPv4 Address*”}}
New-Alias gip Get-IP

function ping-port {
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

function Write-Trace
{
  <#
    .Synopsis
      Write a message to a log file in a format compatible with Trace32 and Config Manager logs.
    .Description
      This cmdlet takes a given message and formats that message such that it's compatible with
      the Trace32 log viewer tool used for reading/parsing System Center log files.
      
      The date and time (to the millisecond) is determined at the time that this cmdlet is called.
      Several optional arguments can be provided, to define the Component generating the log
      message, the File that is generating the message, the Thread ID, and the Context under which
      the log entry is being made.
    .Parameter Message
      The actual message to be logged.
    .Parameter Component
      The Component generating the logging event.
    .Parameter File
      The File generating the logging event.
    .Parameter Thread
      The Thread ID of the thread generating the logging event.
    .Parameter Context
    .Parameter FilePath
      The path to the log file to be generated/written to. By default this cmdlet looks for a
      variable called "WRITELOGFILEPATH" and uses whatever path is there. This variable can be
      set in the script prior to calling this cmdlet. Alternatively a path to a file may be
      provided.
    .Parameter Type
      The type of event being logged. Valid values are 1, 2 and 3. Each number corresponds to a 
      message type:
      1 - Normal messsage (default)
      2 - Warning message
      3 - Error message
  #>
  [CmdletBinding()]
  param(
    [Parameter( Mandatory = $true )]
    [string] $Message,
    [string] $Component="",
    [string] $File="",
    [string] $Thread="",
    [string] $Context="",
    [string] $FilePath=$WRITELOGFILEPATH,
    [ValidateSet(1,2,3)]
    [int] $Type=1
  )
  
  begin
  {
    $TZBias = (Get-WmiObject -Query "Select Bias from Win32_TimeZone").bias
  }
  
  process
  {
    $Time = Get-Date -Format "HH:mm:ss.fff"
    $Date = Get-Date -Format "MM-dd-yyyy"
    
    $Output  = "<![LOG[$($Message)]LOG]!><time=`"$($Time)+$($TZBias)`" date=`"$($Date)`" "
    $Output += "component=`"$($Component)`" context=`"$($Context)`" type=`"$($Type)`" "
    $Output += "thread=`"$($Thread)`" file=`"$($File)`">"
    
    Write-Verbose "$Time $Date`t$Message"
    Out-File -InputObject $Output -Append -NoClobber -Encoding Default -FilePath $FilePath
  }
}


Function Show-NewCommands {
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Write-host ""
Write-Host "** New Declarations **" -fore yellow
Write-Host "Name                 Alias      Description".padright(80) -back yellow -fore black
Write-Host "Show-NewCommands     snew       Show this list " -fore yellow
Write-Host "List-Profiles        lpro       List profile files/paths " -fore yellow
Write-Host "Split-Envpath        epath      Display the path env var " -fore yellow
Write-Host "Get-LocalDisk        gld        Display local disk info " -fore yellow
Write-Host "CountDown            CntDn      Pause a script and display countdown " -fore yellow
Write-Host "Touch                           Create new, empty file " -fore yellow
Write-Host "NewTimestampedFile   ntf        Create new, empty file with timestamped name " -fore yellow
write-host "Export-PSCredential  ecred      Export credentials to file " -fore yellow
write-host "Import-PSCredential  icred      Import credentials from file " -fore yellow
write-host "Get-ChildItem        ll         Linux-style dir list with color " -fore yellow
write-host "Get-Command          which      Just a rename... " -fore yellow
write-host "Get-IP               gip        Display IPv4" -fore Yellow
write-host "Translate-FromSID    FromSID    Get UserName from SID " -fore yellow
write-host "Translate-FromSID    ToSID      Get SID from UserName" -fore Yellow
write-host "Ping-Port                       Test if a port is open (default=80)" -fore Yellow
write-host "Write-Trace                     Write to a log file in Trace32-format" -fore Yellow
write-host "Get-DirInfo          ll         Linux-style dir list with color" -fore yellow
write-host "Get-WifiNetwork                 List nearby Wifi networks" -fore yellow

Write-Host ""
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
}

New-Alias snew Show-NewCommands
New-Alias ll Get-DirInfo

#ShowHeader
if (!(test-path $myScriptsDir)){
    write-host "creating default scripts directory ($myScriptsDir)" -back black -fore green
    new-item -path $myScriptsDir -type directory
	}
Set-Location $myScriptsDir | out-null

Show-NewCommands

$PgmAliasList = (
#	"primal |c:\Program Files\SAPIEN Technologies, Inc\PrimalScript 2012\PrimalScript.exe",
    "excel  |c:\Program Files\Microsoft Office\Office14\EXCEL.EXE; `
	         c:\program files (x86)\Microsoft Office\Office14\EXCEL.EXE"
#	"oo3    |c:\Program Files (x86)\OpenOffice.org 3\program\soffice.exe; `
#	         c:\Program Files\OpenOffice.org 3\program\soffice.exe"
	)
write-host "Setting up Program Aliases...`n" -foreground green
write-host "  Alias       Path"
write-host "  ==========  ======================================="

foreach ($alias in $PgmAliasList) {
	$name = $alias.split("|")[0].trim()
	write-host "  $($name.padright(12))" -nonewline
	if (!(test-path Alias:\$name)){
		$pgmPaths = $alias.split("|")[1].split(";")
		$pathOk = $false
		foreach ($pgmPath in $pgmPaths) {
			if (Test-Path $pgmPath.trim()){
				Set-Alias $name $pgmPath.trim() -scope Global
				Write-Host $pgmPath.trim() # -background black -foreground green
				$pathOk = $true
				break
				}
			}
			if (!$pathOk) {
				Write-Host "No valid path found" -foreground red
				}
		}
	else {
		$x = Get-Alias $name 
		Write-Host "Already defined ($($x.definition))" -foreground yellow
		}
	}
write-host ""

function get-uptime {
        $WMIHash = @{
            ComputerName = "."
            ErrorAction = 'Stop'
            Query= "SELECT LastBootUpTime FROM Win32_OperatingSystem"
            NameSpace='Root\CimV2'
        }
        $wmi = Get-WmiObject @WMIHash
        $retval = (Get-Date) - $($wmi.ConvertToDateTime($wmi.LastBootUpTime))
        return $retval
}

function get-battery {
    $charge = get-wmiobject Win32_Battery
    return $charge    
}

function prompt {
    # Make sure Windows and .Net know where we are (they can only handle the FileSystem)
    [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
    # Also, put the path in the title ... (don't restrict this to the FileSystem
    $Host.UI.RawUI.WindowTitle = "{0} - {1} ({2})" -f $global:WindowTitlePrefix,$pwd.Path,$pwd.Provider.Name

    $uppity = (get-uptime)

    $battstat = ""
    $batt = (get-battery)
    switch ($batt.BatteryStatus) {
        1 { $battstat = "-"; break }
        2 { $battstat = "AC"; break }
        3 { $battstat = "="; break }
        4 { $battstat = "_"; break }
        5 { $battstat = "!"; break }
        6 { $battstat = "+"; break }
    }

    
    #Battery
    If (($battstat -ne "") -and ($battstat -ne "AC")) {
        Write-Host "`n[" -Fore "White" -NoNewLine
        Write-Host "$battstat" -Fore "Green" -NoNewLine
        Write-Host "$($batt.EstimatedChargeRemaining)" -Fore "Green" -NoNewLine
        Write-Host "] " -Fore "White" -NoNewLine
    }

    #Uptime
    Write-Host "`n[up " -Fore "White" -NoNewLine
    Write-Host "$($uppity.days)" -Fore "Green" -NoNewLine
    Write-Host "d " -Fore "White" -NoNewLine
    Write-Host "$($uppity.hours)" -Fore "Green" -NoNewLine
    Write-Host "h:" -Fore "White" -NoNewLine
    Write-Host "$($uppity.minutes)" -Fore "Green" -NoNewLine
    Write-Host "m:" -Fore "White" -NoNewLine
    Write-Host "$($uppity.seconds)" -Fore "Green" -NoNewLine
    Write-Host "s] " -Fore "White" -NoNewLine

    #Day and Time
    Write-Host "`n[" -Fore "White" -NoNewLine
    Write-Host "$((get-date).ToString('ddd')) " -Fore "Green" -NoNewLine
    Write-Host "$((get-date).ToShortTimeString().ToLower())" -Fore "Yellow" -NoNewLine
    Write-Host "] " -Fore "White" -NoNewLine
    
    #Username @ machine
    Write-Host "[" -Fore "White" -NoNewLine
    Write-Host "$env:username" -Fore "Green" -NoNewLine
    Write-Host "@" -Fore "White" -NoNewLine
    Write-Host "$(($env:computername).ToLower())" -Fore "Magenta" -NoNewLine

    if($IsAdmin) { Write-Host " as ADMIN" -Fore "Red" -NoNewLine }
    Write-Host "] " -Fore "White" -NoNewLine

    #Current Directory
    Write-Host "[" -Fore "White" -NoNewLine
    Write-Host "$pwd" -ForegroundColor "Cyan" -NoNewLine
    Write-Host "] " -Fore "White" 
    Write-Host ">" -NoNewLine -Fore "Yellow"
    
    return " "
 }

 function Get-WifiNetwork {
    #Note try : Get-WifiNetwork | select index, ssid, signal, 'radio type' | sort signal -desc | ft -auto
 end {
  netsh wlan sh net mode=bssid | % -process {
    if ($_ -match '^SSID (\d+) : (.*)$') {
        $current = @{}
        $networks += $current
        $current.Index = $matches[1].trim()
        $current.SSID = $matches[2].trim()
    } else {
        if ($_ -match '^\s+(.*)\s+:\s+(.*)\s*$') {
            $current[$matches[1].trim()] = $matches[2].trim()
        }
    }
  } -begin { $networks = @() } -end { $networks|% { new-object psobject -property $_ } }
 }
}

function CountDown() {
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
        sleep 1
        }
    write-host ""
    }
new-item -path alias:CntDn -value CountDown |out-null

function NewTimestampedFile() {
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
    throw "File `"$TempFilePath`" Already Exists!"
    }

  return $TempFilePath
}
new-item -path alias:ntf -value NewTimestampedFile |out-null

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
new-item -path alias:ecred -value Export-PSCredential |out-null

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
new-item -path alias:icred -value Import-PSCredential |out-null
