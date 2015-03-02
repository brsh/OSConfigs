Windows Scripts 

C:\Windows
* auto.bat		
  Set some defaults for cmd (including a "better" prompt)
  Looks best with ansicon - see ansicon.adoxa.vze.com
  Run it manually or add "/K: Auto.bat" to the shortcut (with path...)
  Or: add AutoRun as Reg_SZ (string) 
      to [HKLM] or [HKCU] \Software\Microsoft\Command Processor
      (beware that that could lead to an exploit if the file gets compromised... - protect the file)

* c.bat
  Run vbs file with cscript.exe with no logo... without having to type cscript //nologo :)

* sleep.vbs
  Pause for a few seconds

