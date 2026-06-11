# Schedule-VpnPortSync.ps1
# Registers Sync-VpnPort.ps1 as a Windows Scheduled Task that starts at logon and
# runs continuously, keeping qBittorrent's listening port in sync with ProtonVPN's
# NAT-PMP forwarded port. Re-run to update the registration.
#
# Requires Administrator (for RunLevel Highest).
#
# Trigger choice: AtLogOn (run as the current user). The ProtonVPN GUI app also starts
# at logon, so the VPN tunnel is up around the same time; the loop tolerates the gateway
# being briefly unreachable and retries. After migrating to a system-level WireGuard
# service you may switch this to -AtStartup; the script itself needs no changes.

param(
    [string]$TaskName = "MediaStack VPN Port Sync"
)

$ErrorActionPreference = 'Stop'

# Confirm we are elevated
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell -> Run as administrator, then re-run." -ForegroundColor Yellow
    exit 1
}

$scriptPath = Join-Path $PSScriptRoot "Sync-VpnPort.ps1"
if (-not (Test-Path $scriptPath)) { throw "Sync-VpnPort.ps1 not found next to this script." }

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument ("-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"{0}`"" -f $scriptPath)

$trigger = New-ScheduledTaskTrigger -AtLogOn

# Run as the interactive user, highest privileges. ExecutionTimeLimit 0 = unlimited
# (the loop runs forever). IgnoreNew = never start a second copy.
$principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Seconds 0) -MultipleInstances IgnoreNew `
    -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed existing task '$TaskName' (will re-register)." -ForegroundColor Gray
}

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null

Write-Host "Registered scheduled task: $TaskName" -ForegroundColor Green
Write-Host "  Trigger : at logon"
Write-Host "  Runs    : $scriptPath"
Write-Host "  Logs    : logs\vpn_port_sync.log"
Write-Host ""
Write-Host "Start it now without waiting for next logon:" -ForegroundColor Cyan
Write-Host "  Start-ScheduledTask -TaskName `"$TaskName`""
Write-Host ""
Write-Host "Check status / stop:" -ForegroundColor Cyan
Write-Host "  Get-ScheduledTask -TaskName `"$TaskName`""
Write-Host "  Stop-ScheduledTask  -TaskName `"$TaskName`""
