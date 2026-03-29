# Enable Automatic Torrent Management Mode in qBittorrent
# This is THE KEY setting that makes category save paths work

param(
    [string]$qBitHost = "localhost",
    [int]$qBitPort = 8080,
    [string]$Username = "admin",
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$base = "http://${qBitHost}:${qBitPort}"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Enable Auto TMM (Category Save Paths)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Login
Write-Host "Logging in..." -ForegroundColor Yellow
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
Write-Host "Current settings:" -ForegroundColor Yellow
$prefs = Invoke-RestMethod -Uri "$base/api/v2/app/preferences" -WebSession $qb

Write-Host "  auto_tmm_enabled: $($prefs.auto_tmm_enabled)" -ForegroundColor White
Write-Host "  torrent_changed_tmm_enabled: $($prefs.torrent_changed_tmm_enabled)" -ForegroundColor White

if ($prefs.PSObject.Properties.Name -contains 'disable_auto_tmm_by_default') {
    Write-Host "  disable_auto_tmm_by_default: $($prefs.disable_auto_tmm_by_default)" -ForegroundColor White
}

# The KEY setting: Set auto_tmm_enabled to TRUE
Write-Host ""
Write-Host "Enabling Automatic Torrent Management by default..." -ForegroundColor Yellow
Write-Host "  This makes NEW torrents use category save paths automatically" -ForegroundColor Gray
Write-Host ""

$updatePrefs = @{
    auto_tmm_enabled = $true
    torrent_changed_tmm_enabled = $true
}

$jsonPrefs = $updatePrefs | ConvertTo-Json -Compress

try {
    Invoke-WebRequest -Uri "$base/api/v2/app/setPreferences" -Method POST -WebSession $qb -Body "json=$jsonPrefs" -ContentType "application/x-www-form-urlencoded" | Out-Null
    Write-Host "SUCCESS! Auto TMM is now enabled." -ForegroundColor Green
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Verify
Write-Host ""
Write-Host "Verifying..." -ForegroundColor Yellow
$prefsAfter = Invoke-RestMethod -Uri "$base/api/v2/app/preferences" -WebSession $qb

Write-Host "New settings:" -ForegroundColor White
Write-Host "  auto_tmm_enabled: $($prefsAfter.auto_tmm_enabled)" -ForegroundColor $(if ($prefsAfter.auto_tmm_enabled) { "Green" } else { "Red" })
Write-Host "  torrent_changed_tmm_enabled: $($prefsAfter.torrent_changed_tmm_enabled)" -ForegroundColor $(if ($prefsAfter.torrent_changed_tmm_enabled) { "Green" } else { "Red" })

if ($prefsAfter.auto_tmm_enabled -and $prefsAfter.torrent_changed_tmm_enabled) {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "  Configuration Complete!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "What this means:" -ForegroundColor Yellow
    Write-Host "  - NEW torrents will automatically use their category's save path" -ForegroundColor White
    Write-Host "  - tv-sonarr category -> A:\Downloads\TV" -ForegroundColor White
    Write-Host "  - movie-radarr category -> A:\Downloads\Movies" -ForegroundColor White
    Write-Host "  - books category -> A:\Downloads\Books" -ForegroundColor White
    Write-Host ""
    Write-Host "Test it:" -ForegroundColor Yellow
    Write-Host "  1. Download a new episode from Sonarr" -ForegroundColor White
    Write-Host "  2. Check qBittorrent - it should go to A:\Downloads\TV" -ForegroundColor White
    Write-Host "  3. Verify Sonarr hardlinks to A:\Media\TV Shows" -ForegroundColor White
    Write-Host ""
    Write-Host "Note: Existing torrents won't move automatically." -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "WARNING: Settings may not have updated correctly!" -ForegroundColor Yellow
    Write-Host "You may need to manually set this in qBittorrent UI:" -ForegroundColor Yellow
    Write-Host "  Options -> Downloads -> Default Torrent Management Mode: Automatic" -ForegroundColor White
    Write-Host ""
}
