# Debug qBittorrent Download Paths
param(
    [string]$qBitHost = "localhost",
    [int]$qBitPort = 8080,
    [string]$Username = "admin",
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$base = "http://${qBitHost}:${qBitPort}"

Write-Host ""
Write-Host "=== qBittorrent Download Path Diagnostic ===" -ForegroundColor Cyan
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

# Get app preferences
Write-Host ""
Write-Host "=== Global Save Path Settings ===" -ForegroundColor Yellow
$prefs = Invoke-RestMethod -Uri "$base/api/v2/app/preferences" -WebSession $qb

Write-Host "Save Path: $($prefs.save_path)" -ForegroundColor White
Write-Host "Temp Path Enabled: $($prefs.temp_path_enabled)" -ForegroundColor White
if ($prefs.temp_path_enabled) {
    Write-Host "Temp Path: $($prefs.temp_path)" -ForegroundColor White
}
Write-Host "Auto TMM (Automatic Torrent Management): $($prefs.auto_tmm_enabled)" -ForegroundColor White
Write-Host "Category Changed TMM: $($prefs.torrent_changed_tmm_enabled)" -ForegroundColor White

# Get categories
Write-Host ""
Write-Host "=== Category Configuration ===" -ForegroundColor Yellow
$categories = Invoke-RestMethod -Uri "$base/api/v2/torrents/categories" -WebSession $qb

if ($categories.'tv-sonarr') {
    Write-Host "tv-sonarr category:" -ForegroundColor White
    Write-Host "  Save Path: $($categories.'tv-sonarr'.savePath)" -ForegroundColor White
} else {
    Write-Host "tv-sonarr category not found!" -ForegroundColor Red
}

# Get recent torrents
Write-Host ""
Write-Host "=== Recent Torrents ===" -ForegroundColor Yellow
$torrents = Invoke-RestMethod -Uri "$base/api/v2/torrents/info?limit=10" -WebSession $qb

if ($torrents.Count -eq 0) {
    Write-Host "No torrents found" -ForegroundColor Gray
} else {
    foreach ($torrent in $torrents | Select-Object -First 5) {
        Write-Host ""
        Write-Host "Name: $($torrent.name)" -ForegroundColor Cyan
        Write-Host "  Category: '$($torrent.category)'" -ForegroundColor White
        Write-Host "  Save Path: $($torrent.save_path)" -ForegroundColor White
        Write-Host "  Content Path: $($torrent.content_path)" -ForegroundColor Gray
        Write-Host "  Auto TMM: $($torrent.auto_tmm)" -ForegroundColor White
        Write-Host "  State: $($torrent.state)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "=== Diagnosis ===" -ForegroundColor Yellow

if ($prefs.auto_tmm_enabled -eq $true) {
    Write-Host "ISSUE FOUND: Automatic Torrent Management is ENABLED globally" -ForegroundColor Red
    Write-Host "  This may override category save paths" -ForegroundColor Yellow
    Write-Host "  Recommendation: Disable auto_tmm_enabled or check torrent_changed_tmm_enabled" -ForegroundColor Yellow
}

$tvSonarrTorrents = $torrents | Where-Object { $_.category -eq 'tv-sonarr' }
if ($tvSonarrTorrents.Count -gt 0) {
    $wrongPath = $tvSonarrTorrents | Where-Object { $_.save_path -notlike "*Downloads*TV*" }
    if ($wrongPath.Count -gt 0) {
        Write-Host "ISSUE FOUND: Some tv-sonarr torrents are NOT in A:/Downloads/TV" -ForegroundColor Red
        Write-Host "  Count: $($wrongPath.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "GOOD: All tv-sonarr torrents are in correct location" -ForegroundColor Green
    }
}

Write-Host ""
