mkdir C:\installers\

# Install windows features
add-windowsfeature -Name RSAT
add-windowsfeature -Name FS-Data-Deduplication

Set-MpPreference -DisableRealtimeMonitoring $true

# Disable Netbios
$nicClass = Get-WmiObject -list Win32_NetworkAdapterConfiguration
$nicClass.enableWins($false, $false)

Set-SmbServerConfiguration `
    -EnableSMB1Protocol $false `
    -Confirm:$false

Set-SmbServerConfiguration `
    -RequireSecuritySignature $true `
    -EnableSecuritySignature $true `
    -EncryptData $true `
    -Confirm:$false

Set-SmbServerConfiguration -AutoShareServer $false `
    -AutoShareWorkstation $false `
    -Confirm:$false

Set-SmbServerConfiguration -ServerHidden $true `
    -AnnounceServer $false `
    -Confirm:$false

# Disable-InternetExplorerESC
# $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
# $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
# Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
# Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

# Install useful tools
Set-ExecutionPolicy Bypass -Scope Process -Force  #DevSkim: ignore DS113853
Write-Output "installing latest nuget"
Install-PackageProvider -Name NuGet  -Force -Confirm:$false
Write-Output "allow ps gallery"
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Write-Output "install chocolatey"
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))#DevSkim: ignore DS104456
choco feature enable -n allowGlobalConfirmation
$values = ('googlechrome','sysinternals','7zip.install','vscode','curl')
foreach ($value in $values) {
  Write-Output "installing $($value)"
  choco install $value -y
}

# Disk preparation
Get-Disk | Where-Object {$_.PartitionStyle -eq 'RAW' } | Initialize-Disk
get-disk -Number 2 | New-Partition -UseMaximumSize  -AssignDriveLetter | Format-Volume -FileSystem ReFS -NewFileSystemLabel "Indexes"  -AllocationUnitSize 64KB -Confirm:$false
get-disk -Number 3 | New-Partition -UseMaximumSize  -AssignDriveLetter | Format-Volume -FileSystem ReFS -NewFileSystemLabel "DDBs" -AllocationUnitSize 64KB -Confirm:$false

# Go Setup
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Win10.ps1 -include Win10.psm1 -preset Default.preset

Invoke-WebRequest -Uri "https://github.com/fjacquet/arm-cvlt-demo/raw/main/Commvault_Media_11_21.exe" -OutFile "C:\installers\Commvault_Media_11_21.exe"

# Windows updates
Install-Module PSWindowsUpdate
Import-Module -Name PSWindowsUpdate
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot