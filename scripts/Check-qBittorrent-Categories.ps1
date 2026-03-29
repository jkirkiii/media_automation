# Check qBittorrent Categories
param(
    [string]$qBitHost = "localhost",
    [int]$qBitPort = 8080,
    [string]$Username = "admin",
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$base = "http://${qBitHost}:${qBitPort}"

Write-Host ""
Write-Host "=== Checking qBittorrent Categories ===" -ForegroundColor Cyan
Write-Host ""

# Login to qBittorrent
$loginBody = "username=$Username&password=$Password"

try {
    $login = Invoke-WebRequest -Uri "$base/api/v2/auth/login" -Method POST -Body $loginBody -SessionVariable qb
    if ($login.Content -ne 'Ok.') {
        Write-Host "Login failed!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error logging in: $_" -ForegroundColor Red
    exit 1
}

# Get categories
$categories = Invoke-RestMethod -Uri "$base/api/v2/torrents/categories" -WebSession $qb

Write-Host "All categories:" -ForegroundColor Yellow
$categories | ConvertTo-Json -Depth 3

Write-Host ""
Write-Host "tv-sonarr category details:" -ForegroundColor Yellow
if ($categories.'tv-sonarr') {
    $tvSonarr = $categories.'tv-sonarr'
    Write-Host "  Save Path: '$($tvSonarr.savePath)'" -ForegroundColor White
    Write-Host "  Save Path Length: $($tvSonarr.savePath.Length)" -ForegroundColor Gray
    Write-Host "  Save Path IsNullOrEmpty: $([string]::IsNullOrEmpty($tvSonarr.savePath))" -ForegroundColor Gray
} else {
    Write-Host "  Category not found!" -ForegroundColor Red
}

Write-Host ""
