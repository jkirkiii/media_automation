# Schedule-WeeklyBackup.ps1
# Registers Backup-Configs.ps1 as a weekly Windows Task Scheduler job.
# REQUIRES: Run as Administrator
#
# Default schedule: every Sunday at 3:00 AM
# Re-run this script to update the schedule or backup path.

param(
    [string]$BackupRoot  = "A:\Backups\MediaStack",
    [int]$KeepCount      = 10,
    [string]$DayOfWeek   = "Sunday",
    [string]$RunAt       = "03:00",
    [string]$TaskName    = "MediaStack-WeeklyBackup"
)

$scriptDir  = Split-Path $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $scriptDir "Backup-Configs.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Error "Backup-Configs.ps1 not found at: $scriptPath"
    exit 1
}

# Build the PowerShell argument string
$psArgs = "-NonInteractive -ExecutionPolicy Bypass -File `"$scriptPath`" " +
          "-BackupRoot `"$BackupRoot`" -KeepCount $KeepCount"

$action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psArgs
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $RunAt
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
    -RunOnlyIfNetworkAvailable:$false `
    -StartWhenAvailable  # run on next opportunity if machine was off

# Run as SYSTEM so it works even when no user is logged in
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

# Remove existing task if present
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed existing task: $TaskName" -ForegroundColor Yellow
}

Register-ScheduledTask `
    -TaskName  $TaskName `
    -Action    $action `
    -Trigger   $trigger `
    -Settings  $settings `
    -Principal $principal `
    -Description "Weekly backup of Sonarr, Prowlarr, Calibre-Web, and Cloudflare Tunnel configs" | Out-Null

Write-Host ""
Write-Host "Task registered successfully:" -ForegroundColor Green
Write-Host "  Name     : $TaskName"      -ForegroundColor White
Write-Host "  Schedule : Every $DayOfWeek at $RunAt" -ForegroundColor White
Write-Host "  Script   : $scriptPath"   -ForegroundColor White
Write-Host "  Dest     : $BackupRoot"   -ForegroundColor White
Write-Host "  Keep     : $KeepCount backups" -ForegroundColor White
Write-Host ""
Write-Host "To run immediately:  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
Write-Host "To remove:           Unregister-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
Write-Host ""
