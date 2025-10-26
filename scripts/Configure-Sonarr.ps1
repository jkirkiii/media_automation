# Sonarr Configuration Script
# Configures Sonarr via API based on PROJECT_CONFIGURATION.md preferences

param(
    [string]$SonarrUrl = "http://localhost:8989",
    [string]$ApiKey = "332f7d21453b4225a85fc6852bdad7ee",
    [switch]$WhatIf
)

$headers = @{
    "X-Api-Key" = $ApiKey
    "Content-Type" = "application/json"
}

function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "`n=== $Message ===" -ForegroundColor $Color
}

function Invoke-SonarrApi {
    param(
        [string]$Endpoint,
        [string]$Method = "GET",
        [object]$Body = $null
    )

    $uri = "$SonarrUrl/api/v3/$Endpoint"

    try {
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json -Depth 10
            if ($WhatIf) {
                Write-Host "[WHATIF] $Method $uri" -ForegroundColor Yellow
                Write-Host $jsonBody -ForegroundColor Gray
                return $null
            }
            $response = Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -Body $jsonBody
        } else {
            if ($WhatIf -and $Method -ne "GET") {
                Write-Host "[WHATIF] $Method $uri" -ForegroundColor Yellow
                return $null
            }
            $response = Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers
        }
        return $response
    } catch {
        Write-Host "Error calling $Endpoint : $_" -ForegroundColor Red
        return $null
    }
}

Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Sonarr Configuration Script v1.0         ║" -ForegroundColor Cyan
Write-Host "║   Based on PROJECT_CONFIGURATION.md        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan

if ($WhatIf) {
    Write-Host "`n[WHATIF MODE - No changes will be made]`n" -ForegroundColor Yellow
}

# Test connection
Write-Step "Testing Sonarr Connection"
$systemStatus = Invoke-SonarrApi -Endpoint "system/status"
if ($systemStatus) {
    Write-Host "✓ Connected to Sonarr v$($systemStatus.version)" -ForegroundColor Green
    Write-Host "  Instance: $($systemStatus.instanceName)" -ForegroundColor Gray
} else {
    Write-Host "✗ Failed to connect to Sonarr" -ForegroundColor Red
    exit 1
}

# Configure Root Folder
Write-Step "Configuring Root Folder"
$rootFolders = Invoke-SonarrApi -Endpoint "rootfolder"
$tvShowsRoot = $rootFolders | Where-Object { $_.path -eq "A:\Media\TV Shows" }

if (-not $tvShowsRoot) {
    Write-Host "Adding root folder: A:\Media\TV Shows" -ForegroundColor Yellow
    $newRoot = @{
        path = "A:\Media\TV Shows"
    }
    $result = Invoke-SonarrApi -Endpoint "rootfolder" -Method "POST" -Body $newRoot
    if ($result) {
        Write-Host "✓ Root folder added" -ForegroundColor Green
    }
} else {
    Write-Host "✓ Root folder already exists: A:\Media\TV Shows" -ForegroundColor Green
}

# Configure Quality Profile
Write-Step "Configuring Quality Profile"
$qualityProfiles = Invoke-SonarrApi -Endpoint "qualityprofile"
$hdProfile = $qualityProfiles | Where-Object { $_.name -eq "Conservative HD-1080p" }

if (-not $hdProfile) {
    Write-Host "Creating 'Conservative HD-1080p' quality profile..." -ForegroundColor Yellow

    # Get quality definitions to find IDs
    $qualityDefs = Invoke-SonarrApi -Endpoint "qualitydefinition"

    # Build quality profile for 1080p WEB-DL preference
    $newProfile = @{
        name = "Conservative HD-1080p"
        upgradeAllowed = $true
        cutoff = 3  # WEBDL-1080p
        items = @(
            @{ quality = @{ id = 9; name = "HDTV-1080p" }; allowed = $true }
            @{ quality = @{ id = 3; name = "WEBDL-1080p" }; allowed = $true }
            @{ quality = @{ id = 8; name = "Bluray-1080p" }; allowed = $true }
        )
    }

    $result = Invoke-SonarrApi -Endpoint "qualityprofile" -Method "POST" -Body $newProfile
    if ($result) {
        Write-Host "✓ Quality profile created" -ForegroundColor Green
    }
} else {
    Write-Host "✓ Quality profile 'Conservative HD-1080p' already exists" -ForegroundColor Green
}

# Configure Naming
Write-Step "Configuring Media Management & Naming"
$namingConfig = Invoke-SonarrApi -Endpoint "config/naming"

if ($namingConfig) {
    $updated = $false

    # Standard episode format: {Series Title} - S{season:00}E{episode:00} - {Episode Title}
    if ($namingConfig.standardEpisodeFormat -ne "{Series Title} - S{season:00}E{episode:00} - {Episode Title}") {
        $namingConfig.standardEpisodeFormat = "{Series Title} - S{season:00}E{episode:00} - {Episode Title}"
        $updated = $true
    }

    # Series folder format: {Series Title} ({Series Year})
    if ($namingConfig.seriesFolderFormat -ne "{Series Title} ({Series Year})") {
        $namingConfig.seriesFolderFormat = "{Series Title} ({Series Year})"
        $updated = $true
    }

    # Season folder format: Season {season:00}
    if ($namingConfig.seasonFolderFormat -ne "Season {season:00}") {
        $namingConfig.seasonFolderFormat = "Season {season:00}"
        $updated = $true
    }

    # Enable renaming
    if ($namingConfig.renameEpisodes -ne $true) {
        $namingConfig.renameEpisodes = $true
        $updated = $true
    }

    if ($updated) {
        Write-Host "Updating naming configuration..." -ForegroundColor Yellow
        $result = Invoke-SonarrApi -Endpoint "config/naming/$($namingConfig.id)" -Method "PUT" -Body $namingConfig
        if ($result) {
            Write-Host "✓ Naming configuration updated" -ForegroundColor Green
        }
    } else {
        Write-Host "✓ Naming configuration already correct" -ForegroundColor Green
    }
}

# Configure Media Management
Write-Step "Configuring File Management Settings"
$mediaManagement = Invoke-SonarrApi -Endpoint "config/mediamanagement"

if ($mediaManagement) {
    $updated = $false

    # Enable proper handling
    if ($mediaManagement.autoRenameFolders -ne $true) {
        $mediaManagement.autoRenameFolders = $true
        $updated = $true
    }

    # Set file permissions (not needed for Windows, but good practice)
    if ($mediaManagement.fileChmod -ne "755") {
        $mediaManagement.fileChmod = "755"
        $updated = $true
    }

    if ($updated) {
        Write-Host "Updating media management settings..." -ForegroundColor Yellow
        $result = Invoke-SonarrApi -Endpoint "config/mediamanagement" -Method "PUT" -Body $mediaManagement
        if ($result) {
            Write-Host "✓ Media management updated" -ForegroundColor Green
        }
    } else {
        Write-Host "✓ Media management already configured" -ForegroundColor Green
    }
}

Write-Step "Configuration Summary"
Write-Host "✓ Root Folder: A:\Media\TV Shows" -ForegroundColor Green
Write-Host "✓ Quality Profile: Conservative HD-1080p (1080p WEB-DL cutoff)" -ForegroundColor Green
Write-Host "✓ Episode Format: {Series Title} - S{season:00}E{episode:00} - {Episode Title}" -ForegroundColor Green
Write-Host "✓ Series Format: {Series Title} ({Series Year})" -ForegroundColor Green
Write-Host "✓ Season Format: Season {season:00}" -ForegroundColor Green

Write-Step "Next Steps"
Write-Host "1. Connect qBittorrent download client" -ForegroundColor Yellow
Write-Host "2. Connect to Prowlarr (for indexers)" -ForegroundColor Yellow
Write-Host "3. Import existing TV library" -ForegroundColor Yellow
Write-Host "4. Test download workflow" -ForegroundColor Yellow

Write-Host "`n✓ Basic Sonarr configuration complete!" -ForegroundColor Green
