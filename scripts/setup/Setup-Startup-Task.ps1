# Setup-Startup-Task.ps1
# Creates a Windows Task Scheduler task to auto-start Calibre-Web + Tunnel on login
# REQUIRES: Administrator privileges

$TaskName = "Start-CalibreWeb-Remote"
$ScriptPath = "C:\Users\rokon\source\media_automation\scripts\Start-CalibreWeb-With-Tunnel.ps1"
$UserName = $env:USERNAME

Write-Host "Creating Windows Startup Task..." -ForegroundColor Cyan
Write-Host ""

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Task '$TaskName' already exists. Removing..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create the task action (what to run)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`" -HideWindows"

# Create the task trigger (when to run)
$trigger = New-ScheduledTaskTrigger -AtLogon -User $UserName

# Create task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Create the principal (who runs it)
$principal = New-ScheduledTaskPrincipal -UserId $UserName -LogonType Interactive -RunLevel Highest

# Register the task
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Auto-start Calibre-Web and Cloudflare Tunnel on login"

Write-Host "[OK] Startup task created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Task Details:" -ForegroundColor Cyan
Write-Host "  Name: $TaskName" -ForegroundColor White
Write-Host "  Trigger: At user login ($UserName)" -ForegroundColor White
Write-Host "  Action: Start Calibre-Web + Cloudflare Tunnel" -ForegroundColor White
Write-Host ""
Write-Host "The services will now start automatically when you log in to Windows." -ForegroundColor Yellow
Write-Host ""
Write-Host "To disable auto-start:" -ForegroundColor Gray
Write-Host "  Disable-ScheduledTask -TaskName 'Start-CalibreWeb-Remote'" -ForegroundColor White
Write-Host ""
Write-Host "To remove auto-start completely:" -ForegroundColor Gray
Write-Host "  Unregister-ScheduledTask -TaskName 'Start-CalibreWeb-Remote' -Confirm:`$false" -ForegroundColor White
Write-Host ""
