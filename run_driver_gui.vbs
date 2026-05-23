Option Explicit

Dim shellApp, fso, baseDir, scriptPath, args
Set shellApp = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")

baseDir = fso.GetParentFolderName(WScript.ScriptFullName)
scriptPath = fso.BuildPath(baseDir, "driver_gui.ps1")

args = "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File """ & scriptPath & """"
shellApp.ShellExecute "powershell.exe", args, baseDir, "runas", 0
