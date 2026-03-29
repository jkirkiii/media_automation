# Setup-qBittorrent-Radarr-Category.ps1
# Creates or verifies the movie-radarr category in qBittorrent

param(
    [Parameter(Mandatory=$false)]
    [string]$Username,

    [Parameter(Mandatory=$false)]
    [string]$Password,

    [Parameter(Mandatory=$false)]
    [string]$qBittorrentUrl = "http://localhost:8080"
)

# Load config if not provided
if (-not $Username -or -not $Password) {
    $configPath = Join-Path $PSScriptRoot "..\config.ps1"
    if (Test-Path $configPath) {
        . $configPath
        $Username = $qBittorrentUsername
        $Password = $qBittorrentPassword
        Write-Host "[INFO] Loaded credentials from config.ps1" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] No credentials provided and config.ps1 not found" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SETTING UP qBITTORRENT MOVIE CATEGORY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Login to qBittorrent
Write-Host "[1/4] Logging into qBittorrent..." -ForegroundColor Yellow
$loginBody = @{
    username = $Username
    password = $Password
}

try {
    $loginResponse = Invoke-WebRequest -Uri "$qBittorrentUrl/api/v2/auth/login" -Method Post -Body $loginBody -SessionVariable qBitSession -UseBasicParsing

    if ($loginResponse.Content -eq "Ok.") {
        Write-Host "      Logged in successfully" -ForegroundColor Green
    } else {
        Write-Host "      [ERROR] Login failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "      [ERROR] Failed to login: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check Auto TMM status
Write-Host "`n[2/4] Checking Auto TMM (Automatic Torrent Management) status..." -ForegroundColor Yellow
try {
    $prefs = Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/app/preferences" -WebSession $qBitSession

    if ($prefs.auto_tmm_enabled -eq $true) {
        Write-Host "      Auto TMM is enabled �'" -ForegroundColor Green
    } else {
        Write-Host "      [WARNING] Auto TMM is disabled" -ForegroundColor Yellow
        Write-Host "      Category save paths won't work without Auto TMM" -ForegroundColor Yellow
        Write-Host "      Run Enable-qBittorrent-AutoTMM.ps1 to enable it" -ForegroundColor Yellow
    }
} catch {
    Write-Host "      [WARNING] Could not check Auto TMM status" -ForegroundColor Yellow
}

# Check existing categories
Write-Host "`n[3/4] Checking for existing movie-radarr category..." -ForegroundColor Yellow
try {
    $categories = Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/torrents/categories" -WebSession $qBitSession

    if ($categories.'movie-radarr') {
        Write-Host "      Category 'movie-radarr' already exists" -ForegroundColor Green
        Write-Host "      Save path: $($categories.'movie-radarr'.savePath)" -ForegroundColor Gray
    } else {
        Write-Host "      Category 'movie-radarr' not found, creating..." -ForegroundColor Yellow

        # Create category
        Write-Host "`n[4/4] Creating movie-radarr category..." -ForegroundColor Yellow

        $categoryBody = @{
            category = "movie-radarr"
            savePath = "A:\Downloads\Movies"
        }

        $createResponse = Invoke-WebRequest -Uri "$qBittorrentUrl/api/v2/torrents/createCategory" -Method Post -Body $categoryBody -WebSession $qBitSession -UseBasicParsing

        if ($createResponse.StatusCode -eq 200) {
            Write-Host "      Category created successfully" -ForegroundColor Green
            Write-Host "      Name: movie-radarr" -ForegroundColor Gray
            Write-Host "      Save path: A:\Downloads\Movies" -ForegroundColor Gray
        } else {
            Write-Host "      [ERROR] Failed to create category" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "      [ERROR] Failed to check/create category: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CATEGORY SETUP COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  - Category: movie-radarr" -ForegroundColor Gray
Write-Host "  - Save path: A:\Downloads\Movies" -ForegroundColor Gray
Write-Host "`nRadarr is now fully configured and ready to use!" -ForegroundColor Green
Write-Host "Access Radarr at: http://localhost:7878" -ForegroundColor Green
