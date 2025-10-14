# First, make fucking windows happy with this fucker script
#if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
#{  
#  $arguments = "& '" +$myinvocation.mycommand.definition + "'"
#  Start-Process powershell -Verb runAs -ArgumentList $arguments
#  Break
#}
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
  "Running as admin in $PSScriptRoot"
}
else
{
  "NOT running as an admin!"
  Start-Process powershell -WorkingDirectory $PSScriptRoot -Verb runAs -ArgumentList "-noprofile -noexit -file $PSCommandPath"
  return "Script re-started with admin privileges in another shell. This one will now exit."
}
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope MachinePolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope    UserPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope       Process
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope   CurrentUser
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope  LocalMachine
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

# note: for win11
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f

# Good. Now we can begin fucking windows. 
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
netsh advfirewall set allprofiles state off

# Install some thing that the weak windows is missing. 
Invoke-WebRequest -UseBasicParsing https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.1.0.0p1-Beta/OpenSSH-Win64.zip -OutFile shit.zip
Expand-Archive shit.zip
cd shit/OpenSSH-Win64
./install-sshd.ps1

