# Configure-Radarr.ps1
# Configures Radarr with quality profiles, root folder, and media management settings
# Based on the proven Sonarr setup pattern

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiKey,

    [Parameter(Mandatory=$false)]
    [string]$RadarrUrl = "http://localhost:7878"
)

# Load config if API key not provided
if (-not $ApiKey) {
    $configPath = Join-Path $PSScriptRoot "..\config.ps1"
    if (Test-Path $configPath) {
        . $configPath
        $ApiKey = $RadarrApiKey
        $RadarrUrl = $RadarrUrl
        Write-Host "[INFO] Loaded credentials from config.ps1" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] No API key provided and config.ps1 not found" -ForegroundColor Red
        exit 1
    }
}

$headers = @{
    "X-Api-Key" = $ApiKey
    "Content-Type" = "application/json"
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "RADARR CONFIGURATION SCRIPT" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test connection
Write-Host "[1/6] Testing connection to Radarr..." -ForegroundColor Yellow
try {
    $systemStatus = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/system/status" -Headers $headers -Method Get
    Write-Host "      Connected to Radarr v$($systemStatus.version)" -ForegroundColor Green
} catch {
    Write-Host "      [ERROR] Cannot connect to Radarr at $RadarrUrl" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Configure Root Folder
Write-Host "`n[2/6] Configuring root folder..." -ForegroundColor Yellow
$rootFolderPath = "A:\Media\Movies"

try {
    # Check if root folder already exists
    $existingRootFolders = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/rootfolder" -Headers $headers -Method Get
    $existingFolder = $existingRootFolders | Where-Object { $_.path -eq $rootFolderPath }

    if ($existingFolder) {
        Write-Host "      Root folder already exists: $rootFolderPath" -ForegroundColor Green
    } else {
        $rootFolderBody = @{
            path = $rootFolderPath
        } | ConvertTo-Json

        $newRootFolder = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/rootfolder" -Headers $headers -Method Post -Body $rootFolderBody
        Write-Host "      Created root folder: $rootFolderPath" -ForegroundColor Green
    }
} catch {
    Write-Host "      [WARNING] Failed to configure root folder: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Configure Quality Profile
Write-Host "`n[3/6] Configuring quality profile 'Conservative HD-1080p'..." -ForegroundColor Yellow

try {
    # Get existing quality profiles
    $qualityProfiles = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/qualityprofile" -Headers $headers -Method Get

    # Check if our profile already exists
    $existingProfile = $qualityProfiles | Where-Object { $_.name -eq "Conservative HD-1080p" }

    if ($existingProfile) {
        Write-Host "      Quality profile 'Conservative HD-1080p' already exists" -ForegroundColor Green
    } else {
        # Get quality definitions to build the profile
        $qualityDefinitions = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/qualitydefinition" -Headers $headers -Method Get

        # Create Conservative HD-1080p profile
        # Preferred: WEBDL-1080p, Cutoff: WEBDL-1080p
        # Allowed: Bluray-1080p, WEBDL-1080p, WEBRip-1080p, HDTV-1080p

        $profileBody = @{
            name = "Conservative HD-1080p"
            upgradeAllowed = $true
            cutoff = 4  # WEBDL-1080p quality ID
            items = @(
                @{ quality = @{ id = 7 }; allowed = $true }   # Bluray-1080p
                @{ quality = @{ id = 4 }; allowed = $true }   # WEBDL-1080p (PREFERRED)
                @{ quality = @{ id = 5 }; allowed = $true }   # WEBRip-1080p
                @{ quality = @{ id = 9 }; allowed = $true }   # HDTV-1080p
                @{ quality = @{ id = 6 }; allowed = $false }  # Bluray-720p (disabled)
                @{ quality = @{ id = 2 }; allowed = $false }  # WEBDL-720p (disabled)
                @{ quality = @{ id = 3 }; allowed = $false }  # WEBRip-720p (disabled)
                @{ quality = @{ id = 8 }; allowed = $false }  # HDTV-720p (disabled)
            )
            minFormatScore = 0
            cutoffFormatScore = 0
            formatItems = @()
            language = @{ id = 1 }  # English
        } | ConvertTo-Json -Depth 10

        $newProfile = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/qualityprofile" -Headers $headers -Method Post -Body $profileBody
        Write-Host "      Created quality profile: Conservative HD-1080p" -ForegroundColor Green
    }
} catch {
    Write-Host "      [WARNING] Failed to create quality profile: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "      You can create this manually in the UI" -ForegroundColor Yellow
}

# Configure Media Management
Write-Host "`n[4/6] Configuring media management settings..." -ForegroundColor Yellow

try {
    # Get current config
    $mediaManagement = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/config/mediamanagement" -Headers $headers -Method Get

    # Update settings for hardlinks and naming
    $mediaManagement.autoRenameFolders = $true
    $mediaManagement.pathsDefaultStatic = $false
    $mediaManagement.fileDate = "none"
    $mediaManagement.recycleBin = ""
    $mediaManagement.recycleBinCleanupDays = 7
    $mediaManagement.downloadPropersAndRepacks = "preferAndUpgrade"
    $mediaManagement.createEmptyMovieFolders = $false
    $mediaManagement.deleteEmptyFolders = $true
    $mediaManagement.autoUnmonitorPreviouslyDownloadedMovies = $false
    $mediaManagement.skipFreeSpaceCheckWhenImporting = $false
    $mediaManagement.minimumFreeSpaceWhenImporting = 500
    $mediaManagement.copyUsingHardlinks = $true  # CRITICAL for seeding
    $mediaManagement.importExtraFiles = $false
    $mediaManagement.enableMediaInfo = $true
    $mediaManagement.chmodFolder = "755"

    # Naming format: {Movie Title} ({Release Year}) - {Quality Full}
    $mediaManagement.renameMovies = $true
    $mediaManagement.replaceIllegalCharacters = $true
    $mediaManagement.colonReplacementFormat = "delete"
    $mediaManagement.standardMovieFormat = "{Movie Title} ({Release Year}) - {Quality Full}"
    $mediaManagement.movieFolderFormat = "{Movie Title} ({Release Year})"

    $updateBody = $mediaManagement | ConvertTo-Json -Depth 10
    $updated = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/config/mediamanagement" -Headers $headers -Method Put -Body $updateBody

    Write-Host "      Media management configured:" -ForegroundColor Green
    Write-Host "        - Hardlinks enabled: $($updated.copyUsingHardlinks)" -ForegroundColor Gray
    Write-Host "        - Rename movies: $($updated.renameMovies)" -ForegroundColor Gray
    Write-Host "        - Movie format: $($updated.standardMovieFormat)" -ForegroundColor Gray
    Write-Host "        - Folder format: $($updated.movieFolderFormat)" -ForegroundColor Gray
} catch {
    Write-Host "      [WARNING] Failed to configure media management: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Configure Download Client settings
Write-Host "`n[5/6] Configuring download client settings..." -ForegroundColor Yellow

try {
    $downloadClientConfig = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/config/downloadclient" -Headers $headers -Method Get

    # Enable completed download handling
    $downloadClientConfig.enableCompletedDownloadHandling = $true
    $downloadClientConfig.autoRedownloadFailed = $true
    $downloadClientConfig.removeFailedDownloads = $true

    $updateBody = $downloadClientConfig | ConvertTo-Json -Depth 10
    $updated = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/config/downloadclient" -Headers $headers -Method Put -Body $updateBody

    Write-Host "      Download client settings configured:" -ForegroundColor Green
    Write-Host "        - Completed download handling: $($updated.enableCompletedDownloadHandling)" -ForegroundColor Gray
    Write-Host "        - Auto redownload failed: $($updated.autoRedownloadFailed)" -ForegroundColor Gray
} catch {
    Write-Host "      [WARNING] Failed to configure download client settings: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Configure Indexer settings
Write-Host "`n[6/6] Configuring indexer settings..." -ForegroundColor Yellow

try {
    $indexerConfig = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/config/indexer" -Headers $headers -Method Get

    $indexerConfig.minimumAge = 0
    $indexerConfig.retention = 0
    $indexerConfig.maximumSize = 0
    $indexerConfig.rssSyncInterval = 60

    $updateBody = $indexerConfig | ConvertTo-Json -Depth 10
    $updated = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/config/indexer" -Headers $headers -Method Put -Body $updateBody

    Write-Host "      Indexer settings configured:" -ForegroundColor Green
    Write-Host "        - RSS sync interval: $($updated.rssSyncInterval) minutes" -ForegroundColor Gray
} catch {
    Write-Host "      [WARNING] Failed to configure indexer settings: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "RADARR CONFIGURATION COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Connect Radarr to Prowlarr for indexers" -ForegroundColor Gray
Write-Host "  2. Add qBittorrent as download client" -ForegroundColor Gray
Write-Host "  3. Test with a manual movie search" -ForegroundColor Gray
Write-Host "`nRadarr is accessible at: $RadarrUrl" -ForegroundColor Green
