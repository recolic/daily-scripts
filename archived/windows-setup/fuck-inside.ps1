
# First, make fucking windows happy with this fucker script
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{  echo "Running as admin in $PSScriptRoot"} else{echo "NOT running as an admin!"
  Start-Process powershell -WorkingDirectory $PSScriptRoot -Verb runAs -ArgumentList "-noprofile -noexit -file $PSCommandPath"}

# Secondly, make the fucking powershell slightly better. 
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope MachinePolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope    UserPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope       Process
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope   CurrentUser
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope  LocalMachine
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
mkdir -Force "$profile.placeholder"
echo '$ConfirmPreference = "None"' >> $profile
echo '$ProgressPreference    = "Continue"' >> $profile
echo '$ErrorActionPreference = "Continue"' >> $profile
echo '$WarningPreference     = "Continue"' >> $profile
echo '$InformationPreference = "Continue"' >> $profile
echo '$VerbosePreference     = "SilentlyContinue"' >> $profile
echo '$DebugPreference       = "SilentlyContinue"' >> $profile

# Windows server only
Uninstall-WindowsFeature -Name Windows-Defender

# Good. Now we can begin fucking windows. 
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
netsh advfirewall set allprofiles state off
# corp-managed windows doesn't allow turn off firewall. Fuck it
New-NetFirewallRule -Name AllowAll -DisplayName 'AllowAll' -Enabled True -Direction Inbound -Protocol ANY -Action Allow -Profile ANY

$shitRoot = "https://recolic.cc/setup/win"

# https://stackoverflow.com/questions/38005341/the-response-content-cannot-be-parsed-because-the-internet-explorer-engine-is-no
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2

# Install some thing that the weak windows is missing. 
Invoke-WebRequest -UseBasicParsing "$shitRoot/OpenSSH-Win64.zip" -OutFile openssh.zip
Expand-Archive openssh.zip
cd openssh/OpenSSH-Win64
./install-sshd.ps1
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

Invoke-WebRequest -UseBasicParsing "$shitRoot/npp.exe" -OutFile npp.exe
./npp.exe /S

Invoke-WebRequest -UseBasicParsing "$shitRoot/7z.exe" -OutFile 7zi.exe
./7zi.exe /S

Invoke-WebRequest -UseBasicParsing "$shitRoot/msys-bash.zip" -OutFile msys-bash.zip
Expand-Archive -Path msys-bash.zip -DestinationPath C:\

$key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment', $true)
$path = $key.GetValue('Path',$null,'DoNotExpandEnvironmentNames')
$key.SetValue('Path', $path + ';C:\MinGW\msys\1.0\bin', 'ExpandString')
$key.Dispose()
# Need relogin to make effect




