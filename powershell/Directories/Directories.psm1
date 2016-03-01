# Directories.psm1
# based on d.ps1
# Written by Bill Stewart (bill.stewart@frenchmortuary.com)
# (modified from http://windowsitpro.com/powershell/emulating-dir-command-powershell)
#
# Lists items like Cmd.exe's Dir command. I wrote this script because the
# get-childitem cmdlet lacks some of Dir's built-in functionality, and I wanted
# to quickly specify attributes and/or a sorting order without the tedium of
# constructing a where-object filter and/or sort-object hashtables.
#
# When passing parameters to the script, I recommend you use the form
# -parameter:argument (particularly with -attributes, -order, and -timefield)
# due to potential argument conflicts. For example, to list files without the
# archive attribute, you should write '-a:-a'. If you just write '-a -a',
# PowerShell's parser interprets this as the -a parameter specified twice. (You
# can also write -a '-a' or -a "-a", but -a:-a is shorter.)

#Note: These params are left over from when this was a ps1
#param ($Path,
#       $Attributes,
#       $Order,
#       $TimeField,
#       [Switch] $FullName,
#       [Switch] $Recurse,
#       [Switch] $Bare,
#       [Switch] $Q,
#       [Switch] $LiteralPath,
#       [Switch] $DefaultOutput,
#       [Switch] $Help,
#       [Switch] $Forced)

# Outputs a usage message and exits.
function usage {
  $scriptname = $SCRIPT:MYINVOCATION.MyCommand.Name

  "NAME"
  "    $scriptname"
  ""
  "SYNOPSIS"
  "    Lists items in one or more paths."
  ""
  "SYNTAX"
  "    $scriptname [-path:<String[]>] [-attributes:<String>] [-order:<String>]"
  "    [-timefield:<String>] [-fullname] [-recurse] [-bare] [-q] [-literalpath]"
  "    [-defaultoutput] [-force]"
  ""
  "PARAMETERS"
  "    -path:<String[]>"
  "        The path(s) to the item(s) to list. Without -defaultoutput, the path(s)"
  "        must be in the file system."
  ""
  "    -attributes:<String>"
  "        Displays items matching any one or more of the following attributes:"
  "            A  Files ready for archiving  L  Links (reparse points)"
  "            D  Directories                N  Normal (no other attributes)"
  "            H  Hidden files/directories   R  Read-only files/directories"
  "            I  Not content-indexed        S  System files/directories"
  "        Prefix an attribute character with '-' to exclude it. Use an empty"
  "        string ('') to include all attributes."
  ""
  "    -order:<String>"
  "        Displays items in sorted order."
  "            D  Date (oldest first)     N  Name (alphabetic)"
  "            E  Extension (alphabetic)  S  Size (smallest first)"
  "            G  Group directories"
  "        Prefix a sort order character with '-' to reverse the order. Items are"
  "        sorted in the order specified."
  ""
  "    -timefield:<String>"
  "        Controls which time field is displayed and/or used for sorting."
  "            A  Last access time  W  Last write time"
  "            C  Creation time"
  ""
  "    -fullname"
  "        Displays items' full names."
  ""
  "    -recurse"
  "        Recurse through subdirectories. Note: -recurse enables -fullname. When"
  "        using -recurse, -path must contain only directory names."
  ""
  "    -bare"
  "        Displays items' names only."
  ""
  "    -q"
  "        Displays the owner for each item."
  ""
  "    -literalpath"
  "        Specifies that paths are literal (i.e., no characters are interpreted"
  "        as wildcards)."
  ""
  "    -defaultoutput"
  "        Outputs objects instead of formatted strings."
  ""
  "    -force"
  "        Outputs all files - including hidden and system."
  #exit
}

# If $expr is True, execute $t; otherwise, execute $f.
function iif([ScriptBlock] $expr, [ScriptBlock] $t, [ScriptBlock] $f) {
  if (& $expr) {
    & $t
  } else {
    & $f
  }
}

# Based on the specified attribute string, this function returns two bitmap
# values. The first bitmap contains the attributes to be included, and the
# second bitmap contains the attributes to be excluded.
function get-attributeflags($attrString) {
  # Create hash table containing the list of file system attributes.
  $attrHash = @{"A" = [System.IO.FileAttributes]::Archive;
                "D" = [System.IO.FileAttributes]::Directory;
                "H" = [System.IO.FileAttributes]::Hidden;
                "I" = [System.IO.FileAttributes]::NotContentIndexed;
                "L" = [System.IO.FileAttributes]::ReparsePoint;
                "N" = [System.IO.FileAttributes]::Normal;
                "R" = [System.IO.FileAttributes]::ReadOnly;
                "S" = [System.IO.FileAttributes]::System}

  $includeFlags = 0    # Attributes to be included
  $excludeFlags = 0    # Attributes to be excluded

  # Create a string containing a list of valid attribute characters.
  $attrChars = ""
  $attrHash.Keys | foreach-object { $attrChars += $_ }

  # Keep track of whether '-' appears before an attribute character.
  $enableFlag = $TRUE

  # Iterate the attribute string as a character array.
  foreach ($attrChar in [Char[]] $attrString) {
    switch -wildcard ($attrChar) {
      "-" {
        if ($enableFlag) {
          $enableFlag = $FALSE
        }
      }
      "[$attrChars]" {
        $flag = $attrHash["$_"]
        if ($enableFlag) {
          # Set the bit in the "include" bits.
          $includeFlags = $includeFlags -bor $flag
          # Clear the bit in the "exclude" bits.
          $excludeFlags = $excludeFlags -band (-bnot $flag)
        } else {
          $enableFlag = $TRUE
          # Set the bit in the "exclude" bits.
          $excludeFlags = $excludeFlags -bor $flag
          # Clear the bit in the "include" bits.
          $includeFlags = $includeFlags -band (-bnot $flag)
        }
      }
      default {
        # Throw an error if the attribute character is not valid.
        throw "Invalid attribute character ('$_'). Use -help for help."
      }
    }
  }

  # Output both bit flags.
  $includeFlags,$excludeFlags
}

# Outputs a list of sort-order hashtables based on the specified sort-order
# string, name field, and time field.
function get-orderlist($orderString, $nameField, $timeField) {
  $orderHash = @{"D" = $timeField;
                 "E" = "Extension";
                 "N" = $nameField;
                 "S" = "Length"}

  # Create string containing a list of valid sort-order characters.
  $orderChars = ""
  $orderHash.Keys | foreach-object { $orderChars += $_ }

  # Keep track of whether '-' appears before a sort-order character.
  $ascendingSort = $TRUE

  # Iterate the sort-order string as a character array.
  foreach ($orderChar in [Char[]] $orderString) {
    switch -wildcard ($orderChar) {
      "-" {
        if ($ascendingSort) {
          $ascendingSort = $FALSE
        }
      }
      "[$orderChars]" {
        # Output a hashtable containing the requested sort order.
        @{"Expression" = $orderHash["$_"];
          "Ascending"  = $ascendingSort}
        $ascendingSort = $TRUE
      }
      "G" {
        # Group directories: Sort by the Directory attribute.
        @{"Expression" = {($_.Attributes -band
                          [System.IO.FileAttributes]::Directory) -ne 0};
          "Ascending"  = -not $ascendingSort}
        $ascendingSort = $TRUE
      }
      default {
        throw "Invalid sort-order character ('$_'). Use -help for help."
      }
    }
  }
}

# Returns the provider name for the specified path. If the path doesn't exist,
# the function returns a blank string.
function get-providername($path) {
  $result = ""
  $pathArg = iif { $LiteralPath } { "-literalpath" } { "-path" }
  $ERRORACTIONPREFERENCE = "SilentlyContinue"
  if (invoke-expression "test-path $pathArg `$path") {
    $result = (invoke-expression ("get-item $pathArg `$path -force |" +
      " select-object -f 1")).PSProvider.Name
  }
  $result
}

function Format-FileSize() {
param ([decimal]$Type)
 if ($Type -ge 1PB) {[string]::Format("{0:N1} PB", $Type / 1PB)}
 elseif ($Type -ge 1TB) {[string]::Format("{0:N1} TB", $Type / 1TB)}
 elseif ($Type -ge 1GB) {[string]::Format("{0:N1} GB", $Type / 1GB)}
 elseIf ($Type -ge 1MB) {[string]::Format("{0:N1} MB", $Type / 1MB)}
 elseIf ($Type -ge 1KB) {[string]::Format("{0:N1} KB", $Type / 1KB)}
 elseIf ($Type -gt -1) {[string]::Format("{0:N1}  B", $Type)}
else {""}
}

function Try-GetACL() {
param ([string]$sWhere)
$result = ""
try {
  $result = $((get-acl $sWhere -erroraction SilentlyContinue).Owner)
}
catch [Exception]{
  $result = "Permissions Error"
}
  $result
}

function Get-DirInfo {
    <# 
    .SYNOPSIS 
        Linux-style dir list in C*O*L*O*R
    .DESCRIPTION 
        Output a linux-style directory listing - the key piece with this function is file coloring. This version recolors lines based on the type of file. 
    .EXAMPLE 
        PS> Get-DirInfo -help 
    #> 
param ($Path,
       $Attributes,
       $Order,
       $TimeField,
       [Switch] $FullName,
       [Switch] $Recurse,
       [Switch] $Bare,
       [Switch] $Q,
       [Switch] $LiteralPath,
       [Switch] $DefaultOutput,
       [Switch] $Help,
       [Switch] $Forced)


  # Display the usage message if -help exists.
  if ($Help) {
    usage
    break
  }

  # If -path is missing, assume the current location.
  if ($Path -eq $NULL) {
    $Path = (get-location).Path
  }

  # Use -literalpath if requested; otherwise, just use -path.
  $pathArg = iif { $LiteralPath } { "-literalpath" } { "-path" }

  # If -attributes exists, retrieve the bitmap values.
  if ($Attributes -ne $NULL) {
    $attrInclude,$attrExclude = get-attributeflags $Attributes
  }

  # If -timefield exists, make sure it's valid. LastWriteTime is the default.
  if ($TimeField -ne $NULL) {
    switch -wildcard ($TimeField) {
      "A*" { $TimeField = "LastAccessTime" ; $TimeHeader = "Last Access    " }
      "C*" { $TimeField = "CreationTime" ; $TimeHeader = "Created      " }
      "W*" { $TimeField = "LastWriteTime" ; $TimeHeader = "Modified     " }
      default {
        throw "Invalid time field ('$TimeField'). Use -help for help."
      }
    }
  } else {
    $TimeField = "LastWriteTime" ; $TimeHeader = "Modified     "
  }

  # Use the FullName property if requested or if using -recurse.
  $nameField = iif { $FullName -or $Recurse } { "FullName" } { "Name" }

  # If -order exists, retrieve the sort order.
  if ($Order -ne $NULL) {
    $Order = get-orderlist $Order $nameField $TimeField
  }

  # Create the pipeline for the get-childitem cmdlet.
  $pipeline = ""

  # Add -recurse if requested.
  if ($Recurse) {
    $pipeline += " -recurse"
  }

  # Add -force if requested.
  if ($Forced) {
    $pipeline += " -force"
  }

  # If -attributes exists, use -force.
  if ($Attributes -ne $NULL) {
    if (! $Forced) { $pipeline += " -force" }
    # If any attributes were specified, pipe to a where-object scriptblock.
    if (($attrInclude -ne 0) -or ($attrExclude -ne 0)) {
      $pipeline += " | where-object { "
      if (($attrInclude -ne 0) -and ($attrExclude -ne 0)) {
        $pipeline += "((`$_.Attributes -band $attrInclude) -eq $attrInclude) -and " +
                     "((`$_.Attributes -band $attrExclude) -eq 0)"
      } elseif ($attrInclude -ne 0) {
        $pipeline += "(`$_.Attributes -band $attrInclude) -eq $attrInclude"
      } else {
        $pipeline += "(`$_.Attributes -band $attrExclude) -eq 0"
      }
    $pipeline += " }"
    }
  }

  # Pipe to sort-object if needed.
  if ($Order -ne $NULL) {
    $pipeline += " | sort-object `$Order"
  }

  # If -defaultoutput exists, execute the expression and return.
  if ($DefaultOutput) {
    invoke-expression "get-childitem $pathArg `$Path $pipeline"
    return
  }

  $fore = $Host.UI.RawUI.ForegroundColor
  $back = $Host.UI.RawUI.BackgroundColor
  $hiddenback = 'DarkGray'


  # Create the formatted string expression.
  $formatStr = "`"{0,5} |{1,10} {2,9} |{3,11}"
  $formatStr += iif { -not $Q } { " | {4}" } { " | {4,-30}| {5}" }
  $formatStr += "`" -f `$_.Mode.ToString().ToUpper()," +
    "`$_.$TimeField.ToString('MM/dd/yy')," +
    "`$_.$TimeField.ToString('t').ToLower()," +
    "`$(if ((`$_.Attributes -band [System.IO.FileAttributes]::Directory) -eq 0) { `$(format-filesize `$_.Length) } )"
  if ($Q) {
    $formatStr += ",`$(try-getacl `$_.FullName)"
  }
  $formatStr += ",`$_.$nameField"

# Create the formated header
$headStr = "`"`n{0,5} {1,21}  {2,11}"
  $headStr += iif { -not $Q } { "  {3}" } { "   {3,-30} {4}" }
  $headStr += "`" -f 'DARHSL'," +
    "`$TimeHeader," +
    "'Size   '"
  if ($Q) {
    $headStr += ",'Owner'"
  }
  $headStr += ", ' Name'"

# Create the formated header's line separators
$lineStr = "`"{0,5}-{1,21}-{2,11}"
  $lineStr += iif { -not $Q } { "--{3}" } { "--{3,-30}-{4}" }
  $lineStr += "`" -f '------'," +
    "'|--------------------'," +
    "'|----------'"
  if ($Q) {
    $lineStr += ",'|------------------------------'"
  }
  $lineStr += ",'|---------------------------'"

  # Initialize the counters.
  $dirCount = $fileCount = $sizeTotal = 0

 $regex_opts = ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
      -bor [System.Text.RegularExpressions.RegexOptions]::Compiled)

  $compressed = New-Object System.Text.RegularExpressions.Regex(
      '\.(zip|tar|gz|rar|cab)$', $regex_opts)
  $executable = New-Object System.Text.RegularExpressions.Regex(
      '\.(exe|com|bat|cmd|py|pl|ps1|psm1|vbs|rb|reg|dll|msh|sh|msi|wsf)$', $regex_opts)
  $text_files = New-Object System.Text.RegularExpressions.Regex(
      '\.(txt|cfg|conf|ini|csv|log|log1|log2|log3|log4|xml|config|md|inf)$', $regex_opts)
  $office_files = New-Object System.Text.RegularExpressions.Regex(
      '\.(doc|docx|xls|xlsx|xlt|xltx|dot|dotx|accdb|accde|accdc|accdr|accdt|adp|docm|dotm|laccdb|mdb|ldf|mde|mdt|mpd|mpp|mpt|ost|pst|one|onepkg|pot|potx|potm|pps|ppsm|ppsx|ppt|pptm|pptx|pub|vsd|vss|vsx|vtx|xlm)$', $regex_opts)
  $image_files = New-Object System.Text.RegularExpressions.Regex(
      '\.(jpg|raw|nef|png|gif|pcx|bmp|pdn|jpeg|jpe|jfif|tif|tiff|tga)$', $regex_opts)
  $media_files = New-Object System.Text.RegularExpressions.Regex(
      '\.(wav|vob|mkv|mp3|asf|avi|divx|flv|m2ts|m4v|mov|mp4|mp4v|mpeg|mpeg4|mts|ogg|ogm|ogv|wmv|wma|wtv)$', $regex_opts)

  #Catch Control-C
  #(We don't want the screen colors to be "broken" by the dir colors)
  [console]::TreatControlCAsInput = $true

 
  # Iterate each path. Paths must be in the file system.
  foreach ($item in $Path) {
    switch (get-providername $item) {
      "FileSystem" {

        if (-not $Bare) {
          invoke-expression $headStr
          invoke-expression $lineStr
        }
        invoke-expression "get-childitem $pathArg `$item $pipeline" | foreach-object {

      if ($_.GetType().Name -eq 'DirectoryInfo') {
        $Host.UI.RawUI.ForegroundColor = 'Yellow'
      } elseif ($compressed.IsMatch($_.Name)) {
        $Host.UI.RawUI.ForegroundColor = 'DarkCyan'
      } elseif ($office_files.IsMatch($_.Name)) {
        $Host.UI.RawUI.ForegroundColor = 'Green'
      } elseif ($executable.IsMatch($_.Name)) {
        $Host.UI.RawUI.ForegroundColor = 'Red'
      } elseif ($text_files.IsMatch($_.Name)) {
        $Host.UI.RawUI.ForegroundColor = 'Cyan'
      } elseif ($image_files.IsMatch($_.Name)) {
        $Host.UI.RawUI.ForegroundColor = 'DarkGreen'
      } elseif ($media_files.IsMatch($_.Name)) {
        $Host.UI.RawUI.ForegroundColor = 'Gray'
      } else {
        $Host.UI.RawUI.ForegroundColor = 'White'
      }
      #Wish I knew how to make this work better :(
      #Line goes black, sure, but so does part of the next line :(
      #if ($_.Mode.Contains("h")) {  
      #      $Host.UI.RawUI.BackgroundColor = 'Black'
      #}  else {
      #      $Host.UI.RawUI.BackgroundColor = $back
      #}

          if (-not $Bare) {
            invoke-expression $formatStr
            if (($_.Attributes -band [System.IO.FileAttributes]::Directory) -eq 0) {
              $fileCount += 1
              $sizeTotal += $_.Length
            } else {
              $dirCount += 1
            }
          } else {
            $_.$nameField
          }
    $Host.UI.RawUI.ForegroundColor = $fore
    $Host.UI.RawUI.BackgroundColor = $back

    #Check for Control-C
      if ($Host.UI.RawUI.KeyAvailable -and (3 -eq [int]$Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho").Character))
      {
        $Host.UI.RawUI.ForegroundColor = $fore
        $Host.UI.RawUI.BackgroundColor = $back
        break;
      }

        }
      }
      "" {
        write-error "Cannot find path '$item' because it does not exist."
      }
      default {
        write-error "The path '$item' is not in the file system."
      }
    }
  }

  #Catch Control-C
  [console]::TreatControlCAsInput = $false
  
  # Output footer information when not using -bare.
  if (-not $Bare) {
    if (($fileCount -gt 0) -or ($dirCount -gt 0)) {
      invoke-expression $lineStr
      "{0,16:N0} file(s) {1,15}`n{2,16:N0} dir(s)" -f
        $fileCount,$(format-filesize $sizeTotal),$dirCount
    }
  }
}

New-Alias -name ll -value Get-DirInfo -Description "Colorized directory info" -Force

Export-ModuleMember -Function Get-DirInfo
Export-ModuleMember -Alias ll


###################################################
## END - Cleanup
 
#region Module Cleanup
$ExecutionContext.SessionState.Module.OnRemove = {
    # cleanup when unloading module (if any)
    dir alias: | Where-Object { $_.Source -match "Directories" } | Remove-Item
    dir function: | Where-Object { $_.Source -match "Directories" } | Remove-Item
}
#endregion Module Cleanup