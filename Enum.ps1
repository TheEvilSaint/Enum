# Just a simple script to do some basic enumeration of a target system. 
#
# ******************************************************************
# ******************************************************************
# **                                                              **
# **                           Enum                               **
# **                    Written by: Z3R0th                        **
# **                                                              **
# **                                                              **
# ******************************************************************
# ******************************************************************

# Print the time this script was ran. Useful for knowing access times. 
$Access = Get-Date
Write-Output "[***] You ran this script on $Access [***]"

# Determine OS running on target
$ComputerName = $env:computername
$OS = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName | select caption | select-string windows)-split("=", "}", "{")[0] -replace "}"| select-string windows
If ($OS -match "10") {Write-Output "[*] You are running $OS"}
If ($OS -match " 8") {Write-Output "[*] You are running $OS"}
If ($OS -match " 7") {Write-Output "[*] You are running $OS"}
if ($OS -match "2016") {Write-Output "[*] You are running $OS"}
If ($OS -match "2012") {Write-Output "[*] You are running $OS"}
If ($OS -match "2008") {Write-Output "[*] You are running $OS"}

# Check Execution Policy on target
$Execute = Get-ExecutionPolicy
Write-Output "[*] The Execution Policy is set to $Execute"

# Look and see if there is a startup folder for the user you are
$StartUp = test-path $env:homepath\appdata\roaming\microsoft\windows\start` menu\programs\startup
If ($StartUp -eq "True") {Write-Output "[*] A Startup folder exists at $env:homepath\appdata\roaming\microsoft\windows\start` menu\programs\startup!"} Else {Write-Output "[*] There is no startup folder :c"}

# Determine if running in a 32 or 64 bit environment
If ((Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ENV:Computername).OSArchitecture -eq '64-bit') {
	$PSPath = "$($ENV:Systemroot)\SYSWOW64\WindowsPowershell\v1.0\powershell.exe"; Write-Output "[*] You are in a 64 bit machine!"} 
Else {
	$PSPath = "$PSHome\powershell.exe"; Write-Output "[*] You are in a 32 bit machine!"}

# Check if running as Administrator
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
If ($IsAdmin) {Write-Output "[*] Running with Administrator Privileges! GO HACK ALL THE THINGS!"} Else {Write-Output "[*] You're stuck in userland, better escalate!"}

# Get Principal Name
$PrincipalName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Output "[*] You are $PrincipalName"

# Get the Domain you are in
$Domain = cat env:userdomain
Write-Output "[*] You are in the $Domain domain"

# Get current IPv4 Address
$IP = (ipconfig | select-string IPv4)-split(":")[-1] | findstr [0-9].\.
Write-Output "[*] Your IP is$IP"

# Print which PowerShell Version you're currently running
$Version = $PSVersionTable.PSVersion.Major
Write-Output "[*] You are running PowerShell Version $Version"
If ($Version -eq "2"){Write-Output "[*] You should be clear to exploit"} Else {Write-Warning "[*] Switch to PowerShell Version 2 by running 'powershell -versio 2 -STA -nopr -nonin'"}

# Figure out which apartment state you're currently running
$Apartment = [System.Threading.Thread]::CurrentThread.GetApartmentState() 
#Write-Output "[*] You're running in $Apartment"
If ($Apartment -eq "STA"){Write-Output "[*] You're running in a Single Threaded Apartment State, you should be good to run Get-System"}
Else {Write-Warning "[*] You're running in a Multi-Threaded Apartment State. It's recommended you switch to Single Threaded with 'powershell.exe -STA -versio 2 -nopr -nonin'"}

# Find the Explorer Process and PID. Useful for Cobalt Strike when capturing Keystrokes and Screenshots
$Explore = get-process -name explorer | select -expand id
Write-Output "[*] The PID for Explorer is $Explore, use this with Cobalt Strike's keylogger and screenshot grabber"

# Query for currently logged in users and whether or not they are active
Write-Output "[*] The following users are currently logged in"
If ($OS -match "7") {$Current = query user | fl | out-host}
# Windows 10 use this
Else {Get-WmiObject -Class Win32_ComputerSystem | select username}

# List shares available
Write-Output "[*] The following shares are available"
PSdrive | select-object * -exclude used, free, provider, credential, currentlocation | fl

#List mapped drives
Write-Output "[*] The following drives have been mapped to the system"
Get-WmiObject -Class Win32_MappedLogicalDisk | select Name, ProviderName

# List Local Admins
Write-Output "[*] These users are also local Administrators!"
$ADSIComputer = [ADSI] ("WinNT://$ComputerName, computer")
$Group = $ADSIComputer.psbase.children.find("Administrators", "Group")
if ($OS -match "10") {$Group.psbase.invoke('members') | ForEach { $_.GetType().InvokeMember("Name", 'getproperty', $null, $_, $null) }}
Else {net localgroup Administrators}

# Check whether or not SMBv1 is enabled or disabled. 
$SMBCheck = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Lanmanserver\Parameters" -Name SMB1 | Select-Object "SMB1")
if ( $SMBCheck -match "0" ) {Write-Host "SMBv1 is currently disabled"} Else {Write-Host "SMBv1 is enabled!"}

# Gather installed hotfixes
#Write-Output "[*] Looking for possible exploits, this could take some time"
#$Hotfix = Get-HotFix | Select-Object * -exclude installedon, __path, __genus, __class, __superclass, __dynasty, __relpath, __property_count, __derivation, __server, __namespace, caption, csname, fixcomments, installdate, installedby, name, servicepackineffect, scope, path, options, classpath, properties, systemproperties, qualifiers, site, container, description, status | sort | ft -auto
#$Hotfix > $env:APPDATA\Microsoft\Windows\Updates.txt
# Eventually I want to add in more exploits to check against.
# List of KB's to check against 
#echo "KB3136041" > $env:APPDATA\Microsoft\Windows\Win32Logs.txt
#echo "KB3155533" >> $env:APPDATA\Microsoft\Windows\Win32Logs.txt
#echo "KB3143141" >> $env:APPDATA\Microsoft\Windows\Win32Logs.txt
#echo "KB3041836" >> $env:APPDATA\Microsoft\Windows\Win32Logs.txt
#echo "KB3057191" >> $env:APPDATA\Microsoft\Windows\Win32Logs.txt
#echo "KB3011443" >> $env:APPDATA\Microsoft\Windows\Win32Logs.txt
#echo "KB3000869" >> $env:APPDATA\Microsoft\Windows\Win32Logs.txt
#echo "KB3000061" >> $env:APPDATA\Microsoft\Windows\Win32Logs.txt
#echo "KB2989935" >> $env:APPDATA\Microsoft\Windows\Win32Logs.txt
#echo "KB2850851" >> $env:APPDATA\Microsoft\Windows\Win32Logs.txt
#echo "KB2909210" >> $env:APPDATA\Microsoft\Windows\Win32Logs.txt
# Compare the list of Hotfixes currently installed against the list of KB's for known exploits. This will find which ones are on both lists and export that data to a new text file. 
#$Compare = diff (get-content $env:APPDATA\Microsoft\Windows\Updates.txt ) (get-content $env:APPDATA\Microsoft\Windows\Win32Logs.txt) -includeequal | select-string === | foreach-object {$_-replace("@{InputObject=", "")} | foreach-object {$_-replace("; SideIndicator===}", "")} > $env:APPDATA\Microsoft\Windows\WinUpdate.txt
# With the new text file we will compare that with our known KB's and exclude all of the matches. For the KB's that don't match it means we might be able to use those exploits on target if my logic is right.
#$PossibleSploit = diff (get-content $env:APPDATA\Microsoft\Windows\Win32Logs.txt) (get-content $env:APPDATA\Microsoft\Windows\WinUpdate.txt) | ft InputObject -hide > $env:APPDATA\Microsoft\Windows\Updater.txt
#$Compare
#$PossibleSploit
#foreach($line in get-content $env:APPDATA\Microsoft\Windows\Updater.txt){
#    if($line -match "KB3136041") {Write-Output "[*] You might be able to use MS_16_016_Webdav [*]"}
#    if($line -match "KB3155533") {Write-Output "[*] You might be able to use MS16_051_vbscript [*]"} 
#    if($line -match "KB3143141") {Write-Output "[*] You might be able to use MS16_032_secondary_logon_handle_privesc [*]"}
#    if($line -match "KB3041836") {Write-Output "[*] You might be able to use MS15_020_shortcut_icon_dllloader [*]"}
#   if($line -match "KB3057191") {Write-Output "[*] You might be able to use MS15_051_client_copy_image [*]"}
#    if($line -match "KB3011443") {Write-Output "[*] You might be able to use MS14_064_ole_code_execution [*]"}
#    if($line -match "KB3000869") {Write-Output "[*] You might be able to use MS14_060_sandworm [*]"}
#    if($line -match "KB3000061") {Write-Output "[*] You might be able to use MS14_058_track_popup_menu [*]"}
#    if($line -match "KB2989935") {Write-Output "[*] You might be able to use MS14_070_tcpip_ioctl [*]"}
#    if($line -match "KB2850851") {Write-Output "[*] You might be able to use MS13_053_schlamperei [*]"}
#}
# Time to clean up any trace we wrote to disk. Even if the user is watching that particular folder they shouldn't see anything due to how fast the data is being processed. Also, the data doesn't go to the recycle bin as this is done via command line.
#rm $env:APPDATA\Microsoft\Windows\Updates.txt
#rm $env:APPDATA\Microsoft\Windows\Win32Logs.txt
#rm $env:APPDATA\Microsoft\Windows\Updater.txt
#rm $env:APPDATA\Microsoft\Windows\WinUpdate.txt
