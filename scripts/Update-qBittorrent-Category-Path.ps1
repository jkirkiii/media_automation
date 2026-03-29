# Update qBittorrent Category Save Path
# This updates an existing category's save path

param(
    [string]$qBitHost = "localhost",
    [int]$qBitPort = 8080,
    [string]$Username = "admin",
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$base = "http://${qBitHost}:${qBitPort}"

Write-Host ""
Write-Host "=== Updating qBittorrent Category Save Path ===" -ForegroundColor Cyan
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
Write-Host ""
Write-Host "Current categories:" -ForegroundColor Yellow
$categories = Invoke-RestMethod -Uri "$base/api/v2/torrents/categories" -WebSession $qb

if ($categories.PSObject.Properties.Name -contains 'tv-sonarr') {
    $currentPath = $categories.'tv-sonarr'.savePath
    if ([string]::IsNullOrEmpty($currentPath)) {
        Write-Host "  tv-sonarr: (no save path configured)" -ForegroundColor Gray
    } else {
        Write-Host "  tv-sonarr: $currentPath" -ForegroundColor White
    }
} else {
    Write-Host "ERROR: tv-sonarr category does not exist!" -ForegroundColor Red
    Write-Host "Please create it in qBittorrent first." -ForegroundColor Yellow
    exit 1
}

# Check if directory exists, create if needed
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

# Update category save path using editCategory endpoint
Write-Host ""
Write-Host "Updating tv-sonarr category save path..." -ForegroundColor Yellow

$updateBody = "category=tv-sonarr&savePath=$tvDownloadPath"

try {
    $result = Invoke-WebRequest -Uri "$base/api/v2/torrents/editCategory" -Method POST -WebSession $qb -Body $updateBody -ContentType "application/x-www-form-urlencoded"

    Write-Host "Category updated successfully!" -ForegroundColor Green
    Write-Host "  Category: tv-sonarr" -ForegroundColor White
    Write-Host "  Save Path: $tvDownloadPath" -ForegroundColor White
} catch {
    Write-Host "Error updating category: $_" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    exit 1
}

# Verify the configuration
Write-Host ""
Write-Host "Verifying configuration..." -ForegroundColor Yellow
$categoriesAfter = Invoke-RestMethod -Uri "$base/api/v2/torrents/categories" -WebSession $qb

$actualPath = $categoriesAfter.'tv-sonarr'.savePath
$expectedPathNormalized = $tvDownloadPath -replace '\\', '/'
$actualPathNormalized = $actualPath -replace '\\', '/'

if ($actualPathNormalized -eq $expectedPathNormalized) {
    Write-Host "Verification successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All new torrents with category 'tv-sonarr' will download to:" -ForegroundColor Cyan
    Write-Host "  $actualPath" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Verification failed - path mismatch" -ForegroundColor Red
    Write-Host "Expected: $tvDownloadPath" -ForegroundColor Yellow
    Write-Host "Actual: $actualPath" -ForegroundColor Yellow
}

Write-Host "=== Configuration Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: Existing torrents will not be moved." -ForegroundColor Yellow
Write-Host "Only NEW downloads from Sonarr will use this path." -ForegroundColor Yellow
Write-Host ""
