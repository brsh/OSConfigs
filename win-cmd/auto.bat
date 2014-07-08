@echo off
::Various macros
doskey ls=dir /og /x $*
doskey cat=type $* $B more
doskey home=cd /d %USERPROFILE%
doskey cd~=cd /d %USERPROFILE%
doskey ..=cd ..
doskey history=doskey /history
doskey mv=move $*
doskey cp=copy $*
doskey rm=del $*

::Tests if running as admin 
::(needs a command that a reg user can't run; at will be replaced someday...)
%SystemRoot%\system32\net.exe session >nul 2>&1
IF %errorlevel% == 0 (
	:: We are admin
	set IsAdmin=$Sas$SAdmin
	if EXIST %WINDIR%\ansicon.exe (
		set IsAdmin=$E[1;31m$Sas$SAdmin
	)
)

::Set the prompt
::The time portion ($T) includes miliseconds and seconds - $H backspaces them out
if EXIST %WINDIR%\ansicon.exe (
	prompt $e[1;37m[$e[1;33m$T$H$H$H$H$H$H$e[1;37m]$S[$e[1;32m%username%%IsAdmin%$e[1;37m]$S[$e[1;36m$P$e[1;37m]$_$G$e[0m$s
) ELSE (
	prompt [$T$H$H$H$H$H$H]$S[%username%%IsAdmin%]$S[$P]$_$G$S
)