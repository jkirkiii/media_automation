# Set qBittorrent Category Save Paths
# This configures where qBittorrent saves downloads for specific categories

param(
    [string]$qBitHost = "localhost",
    [int]$qBitPort = 8080,
    [string]$Username = "admin",
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$base = "http://${qBitHost}:${qBitPort}"

Write-Host ""
Write-Host "=== Setting qBittorrent Category Save Paths ===" -ForegroundColor Cyan
Write-Host ""

# Login to qBittorrent
Write-Host "Logging in to qBittorrent..." -ForegroundColor Yellow
$loginBody = "username=$Username&password=$Password"

try {
    $login = Invoke-WebRequest -Uri "$base/api/v2/auth/login" -Method POST -Body $loginBody -SessionVariable qb

    if ($login.Content -ne 'Ok.') {
        Write-Host "Login failed!" -ForegroundColor Red
        exit 1
    }

    Write-Host "Successfully logged in" -ForegroundColor Green
} catch {
    Write-Host "Error logging in: $_" -ForegroundColor Red
    exit 1
}

# Get current categories
Write-Host "Current categories:" -ForegroundColor Yellow
$categories = Invoke-RestMethod -Uri "$base/api/v2/torrents/categories" -WebSession $qb

if ($categories.PSObject.Properties.Name -contains 'tv-sonarr') {
    Write-Host "  tv-sonarr: $($categories.'tv-sonarr'.savePath)" -ForegroundColor White
} else {
    Write-Host "  tv-sonarr: Not configured" -ForegroundColor Gray
}

# Check if directories exist, create if needed
Write-Host ""
Write-Host "Checking directories..." -ForegroundColor Yellow

$tvDownloadPath = "A:\Downloads\TV"
if (-not (Test-Path $tvDownloadPath)) {
    Write-Host "Creating directory: $tvDownloadPath" -ForegroundColor Yellow
    New-Item -Path $tvDownloadPath -ItemType Directory -Force | Out-Null
    Write-Host "Directory created" -ForegroundColor Green
} else {
    Write-Host "Directory exists: $tvDownloadPath" -ForegroundColor Green
}

# Set category save path for tv-sonarr
Write-Host ""
Write-Host "Configuring tv-sonarr category..." -ForegroundColor Yellow

$categoryBody = @{
    category = "tv-sonarr"
    savePath = $tvDownloadPath
}

try {
    $result = Invoke-WebRequest -Uri "$base/api/v2/torrents/createCategory" -Method POST -WebSession $qb -Body $categoryBody

    Write-Host "Category configured successfully!" -ForegroundColor Green
    Write-Host "  Category: tv-sonarr" -ForegroundColor White
    Write-Host "  Save Path: $tvDownloadPath" -ForegroundColor White
} catch {
    Write-Host "Error configuring category: $_" -ForegroundColor Red
    exit 1
}

# Verify the configuration
Write-Host ""
Write-Host "Verifying configuration..." -ForegroundColor Yellow
$categoriesAfter = Invoke-RestMethod -Uri "$base/api/v2/torrents/categories" -WebSession $qb

if ($categoriesAfter.'tv-sonarr'.savePath -eq $tvDownloadPath) {
    Write-Host "Verification successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All new torrents with category 'tv-sonarr' will download to:" -ForegroundColor Cyan
    Write-Host "  $tvDownloadPath" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Verification failed - path mismatch" -ForegroundColor Red
}

Write-Host "=== Configuration Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: Existing torrents will not be moved." -ForegroundColor Yellow
Write-Host "Only NEW downloads from Sonarr will use this path." -ForegroundColor Yellow
Write-Host ""
