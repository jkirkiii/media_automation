# Schedule-WeeklyCleanup.ps1
# Registers Auto-CleanupOrphans.ps1 as a weekly Windows Task Scheduler job.
# REQUIRES: Run as Administrator.
#
# Default schedule: every Monday at 4:00 AM (1h after the weekly backup).
# Re-run this script to update the schedule or thresholds.

param(
    [int]$FreeSpaceThresholdGB = 300,
    [int]$MinSeedDays          = 21,
    [string]$DayOfWeek         = "Monday",
    [string]$RunAt             = "04:00",
    [string]$TaskName          = "MediaStack-WeeklyCleanup"
)

$scriptDir  = Split-Path $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $scriptDir "Auto-CleanupOrphans.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Error "Auto-CleanupOrphans.ps1 not found at: $scriptPath"
    exit 1
}

# Build PowerShell argument string for the task
$psArgs = "-NonInteractive -ExecutionPolicy Bypass -File `"$scriptPath`" " +
          "-FreeSpaceThresholdGB $FreeSpaceThresholdGB -MinSeedDays $MinSeedDays"

$action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psArgs
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $RunAt
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 60) `
    -RunOnlyIfNetworkAvailable:$false `
    -StartWhenAvailable

# Run as SYSTEM so the task runs even when no user is logged in
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

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
    -Description "Weekly hardlink-orphan cleanup of qBittorrent downloads (Auto-CleanupOrphans.ps1)" | Out-Null

Write-Host ""
Write-Host "Task registered successfully:" -ForegroundColor Green
Write-Host "  Name           : $TaskName"                      -ForegroundColor White
Write-Host "  Schedule       : Every $DayOfWeek at $RunAt"      -ForegroundColor White
Write-Host "  Script         : $scriptPath"                    -ForegroundColor White
Write-Host "  Free threshold : $FreeSpaceThresholdGB GB"        -ForegroundColor White
Write-Host "  Min seed days  : $MinSeedDays"                    -ForegroundColor White
Write-Host ""
Write-Host "Reminders:" -ForegroundColor Yellow
Write-Host "  - SMTP credentials must be set in config.ps1 (`$SmtpServer/$SmtpUsername/$SmtpPassword/$SmtpFrom/$SmtpReportTo)" -ForegroundColor Yellow
Write-Host "  - Use a Gmail App Password (https://myaccount.google.com/apppasswords), not the account password" -ForegroundColor Yellow
Write-Host ""
Write-Host "To run immediately:  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
Write-Host "To preview a run:    .\scripts\Auto-CleanupOrphans.ps1 -Force -DryRun" -ForegroundColor Cyan
Write-Host "To remove:           Unregister-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
Write-Host ""
