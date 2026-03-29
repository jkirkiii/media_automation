# Fix qBittorrent to Respect Category Save Paths
param(
    [string]$qBitHost = "localhost",
    [int]$qBitPort = 8080,
    [string]$Username = "admin",
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$base = "http://${qBitHost}:${qBitPort}"

Write-Host ""
Write-Host "=== Fixing qBittorrent Category Behavior ===" -ForegroundColor Cyan
Write-Host ""

# Login
$loginBody = "username=$Username&password=$Password"
try {
    $login = Invoke-WebRequest -Uri "$base/api/v2/auth/login" -Method POST -Body $loginBody -SessionVariable qb
    if ($login.Content -ne 'Ok.') {
        Write-Host "Login failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Logged in successfully" -ForegroundColor Green
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Get current preferences
Write-Host ""
Write-Host "Getting current preferences..." -ForegroundColor Yellow
$prefs = Invoke-RestMethod -Uri "$base/api/v2/app/preferences" -WebSession $qb

Write-Host "Current settings:" -ForegroundColor White
Write-Host "  Save Path: $($prefs.save_path)" -ForegroundColor Gray
Write-Host "  Auto TMM: $($prefs.auto_tmm_enabled)" -ForegroundColor Gray
Write-Host "  Category Changed TMM: $($prefs.torrent_changed_tmm_enabled)" -ForegroundColor Gray
Write-Host "  Create Subfolder Enabled: $($prefs.create_subfolder_enabled)" -ForegroundColor Gray

# Update preferences
Write-Host ""
Write-Host "Updating preferences to respect category paths..." -ForegroundColor Yellow

$updatePrefs = @{
    auto_tmm_enabled = $false
    torrent_changed_tmm_enabled = $false
    create_subfolder_enabled = $false
}

$updateBody = ($updatePrefs.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&'

try {
    $result = Invoke-WebRequest -Uri "$base/api/v2/app/setPreferences" -Method POST -WebSession $qb -Body "json=$([System.Web.HttpUtility]::UrlEncode(($updatePrefs | ConvertTo-Json -Compress)))" -ContentType "application/x-www-form-urlencoded"

    Write-Host "Preferences updated successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error updating preferences: $_" -ForegroundColor Red
    exit 1
}

# Verify
Write-Host ""
Write-Host "Verifying changes..." -ForegroundColor Yellow
$prefsAfter = Invoke-RestMethod -Uri "$base/api/v2/app/preferences" -WebSession $qb

Write-Host "New settings:" -ForegroundColor White
Write-Host "  Auto TMM: $($prefsAfter.auto_tmm_enabled)" -ForegroundColor White
Write-Host "  Category Changed TMM: $($prefsAfter.torrent_changed_tmm_enabled)" -ForegroundColor White
Write-Host "  Create Subfolder: $($prefsAfter.create_subfolder_enabled)" -ForegroundColor White

if ($prefsAfter.auto_tmm_enabled -eq $false -and $prefsAfter.torrent_changed_tmm_enabled -eq $false) {
    Write-Host ""
    Write-Host "SUCCESS! qBittorrent will now respect category save paths." -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT: Test by downloading a NEW episode from Sonarr." -ForegroundColor Yellow
    Write-Host "Existing torrents will stay in their current locations." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "WARNING: Settings may not have updated correctly." -ForegroundColor Yellow
}

Write-Host ""
