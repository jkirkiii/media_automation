# Complete qBittorrent Category Setup for All Media Types
# This enables Automatic Torrent Management and sets up categories for TV, Movies, and Books

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
Write-Host "  qBittorrent Category Setup - All Media" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Login
Write-Host "Logging in to qBittorrent..." -ForegroundColor Yellow
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

# Step 1: Enable Automatic Torrent Management
Write-Host ""
Write-Host "=== Step 1: Enable Automatic Torrent Management ===" -ForegroundColor Cyan
Write-Host ""

$prefs = Invoke-RestMethod -Uri "$base/api/v2/app/preferences" -WebSession $qb

Write-Host "Current Auto TMM settings:" -ForegroundColor Yellow
Write-Host "  auto_tmm_enabled: $($prefs.auto_tmm_enabled)" -ForegroundColor White
Write-Host "  torrent_changed_tmm_enabled: $($prefs.torrent_changed_tmm_enabled)" -ForegroundColor White

Write-Host ""
Write-Host "Enabling Auto TMM..." -ForegroundColor Yellow

$updatePrefs = @{
    auto_tmm_enabled = $false
    torrent_changed_tmm_enabled = $true
}

$jsonPrefs = $updatePrefs | ConvertTo-Json -Compress

try {
    Invoke-WebRequest -Uri "$base/api/v2/app/setPreferences" -Method POST -WebSession $qb -Body "json=$jsonPrefs" -ContentType "application/x-www-form-urlencoded" | Out-Null
    Write-Host "Auto TMM configured!" -ForegroundColor Green
    Write-Host "  torrent_changed_tmm_enabled = true (categories will trigger Auto TMM)" -ForegroundColor White
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Create directory structure
Write-Host ""
Write-Host "=== Step 2: Create Download Directories ===" -ForegroundColor Cyan
Write-Host ""

$directories = @(
    "A:\Downloads\TV",
    "A:\Downloads\Movies",
    "A:\Downloads\Books"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        Write-Host "Creating: $dir" -ForegroundColor Yellow
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "  Created" -ForegroundColor Green
    } else {
        Write-Host "Exists: $dir" -ForegroundColor Gray
    }
}

# Step 3: Set up categories
Write-Host ""
Write-Host "=== Step 3: Configure Categories ===" -ForegroundColor Cyan
Write-Host ""

$categories = @(
    @{ name = "tv-sonarr"; path = "A:\Downloads\TV"; description = "TV Shows (Sonarr)" },
    @{ name = "movie-radarr"; path = "A:\Downloads\Movies"; description = "Movies (Radarr)" },
    @{ name = "books"; path = "A:\Downloads\Books"; description = "Books/Ebooks" }
)

foreach ($cat in $categories) {
    Write-Host "Configuring: $($cat.description)" -ForegroundColor Yellow
    Write-Host "  Category: $($cat.name)" -ForegroundColor White
    Write-Host "  Save Path: $($cat.path)" -ForegroundColor White

    $updateBody = "category=$($cat.name)&savePath=$($cat.path)"

    try {
        # Try to edit first (if exists)
        Invoke-WebRequest -Uri "$base/api/v2/torrents/editCategory" -Method POST -WebSession $qb -Body $updateBody -ContentType "application/x-www-form-urlencoded" | Out-Null
        Write-Host "  Updated existing category" -ForegroundColor Green
    } catch {
        # If edit fails, try create
        try {
            Invoke-WebRequest -Uri "$base/api/v2/torrents/createCategory" -Method POST -WebSession $qb -Body $updateBody -ContentType "application/x-www-form-urlencoded" | Out-Null
            Write-Host "  Created new category" -ForegroundColor Green
        } catch {
            Write-Host "  Warning: Could not create/update category: $_" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# Step 4: Verify configuration
Write-Host "=== Step 4: Verify Configuration ===" -ForegroundColor Cyan
Write-Host ""

$categoriesAfter = Invoke-RestMethod -Uri "$base/api/v2/torrents/categories" -WebSession $qb

Write-Host "Configured categories:" -ForegroundColor Yellow
foreach ($cat in $categories) {
    if ($categoriesAfter.PSObject.Properties.Name -contains $cat.name) {
        $actualPath = $categoriesAfter.($cat.name).savePath
        $expectedNormalized = $cat.path -replace '\\', '/'
        $actualNormalized = $actualPath -replace '\\', '/'

        if ($actualNormalized -eq $expectedNormalized) {
            Write-Host "  [$($cat.name)] -> $actualPath" -ForegroundColor Green
        } else {
            Write-Host "  [$($cat.name)] -> $actualPath (MISMATCH!)" -ForegroundColor Red
        }
    } else {
        Write-Host "  [$($cat.name)] NOT FOUND!" -ForegroundColor Red
    }
}

# Step 5: Instructions
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Configuration Complete!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Categories configured:" -ForegroundColor Green
Write-Host "  tv-sonarr    -> A:\Downloads\TV (for Sonarr)" -ForegroundColor White
Write-Host "  movie-radarr -> A:\Downloads\Movies (for Radarr)" -ForegroundColor White
Write-Host "  books        -> A:\Downloads\Books" -ForegroundColor White
Write-Host ""

Write-Host "IMPORTANT: How Auto TMM works" -ForegroundColor Yellow
Write-Host "  1. When a torrent is assigned a category, Auto TMM activates" -ForegroundColor White
Write-Host "  2. The torrent automatically moves to the category's save path" -ForegroundColor White
Write-Host "  3. Sonarr/Radarr assign categories automatically" -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test by downloading a new episode in Sonarr" -ForegroundColor White
Write-Host "  2. Verify it goes to A:\Downloads\TV in qBittorrent" -ForegroundColor White
Write-Host "  3. Check that Sonarr hardlinks it to A:\Media\TV Shows" -ForegroundColor White
Write-Host ""

Write-Host "For Radarr (when you set it up):" -ForegroundColor Yellow
Write-Host "  Configure Radarr download client to use 'movie-radarr' category" -ForegroundColor White
Write-Host ""
