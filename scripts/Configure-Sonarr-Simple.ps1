# Simple Sonarr Configuration Script
# Configures essential settings via API

$SonarrUrl = "http://localhost:8989"
$ApiKey = "332f7d21453b4225a85fc6852bdad7ee"

$headers = @{
    "X-Api-Key" = $ApiKey
    "Content-Type" = "application/json"
}

Write-Host "`n=== Sonarr Configuration Script ===`n" -ForegroundColor Cyan

# Test connection
Write-Host "Testing connection..." -ForegroundColor Yellow
try {
    $status = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/system/status" -Headers $headers
    Write-Host "✓ Connected to Sonarr v$($status.version)" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to connect: $_" -ForegroundColor Red
    exit 1
}

# Add root folder
Write-Host "`nConfiguring root folder..." -ForegroundColor Yellow
try {
    $rootFolders = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/rootfolder" -Headers $headers
    $exists = $rootFolders | Where-Object { $_.path -eq "A:\Media\TV Shows" }

    if ($exists) {
        Write-Host "✓ Root folder already exists" -ForegroundColor Green
    } else {
        $body = @{ path = "A:\Media\TV Shows" } | ConvertTo-Json
        Invoke-RestMethod -Uri "$SonarrUrl/api/v3/rootfolder" -Method POST -Headers $headers -Body $body | Out-Null
        Write-Host "✓ Added root folder: A:\Media\TV Shows" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Error with root folder: $_" -ForegroundColor Red
}

# Configure naming
Write-Host "`nConfiguring naming format..." -ForegroundColor Yellow
try {
    $naming = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/config/naming" -Headers $headers

    $naming.renameEpisodes = $true
    $naming.standardEpisodeFormat = "{Series Title} - S{season:00}E{episode:00} - {Episode Title}"
    $naming.seriesFolderFormat = "{Series Title} ({Series Year})"
    $naming.seasonFolderFormat = "Season {season:00}"

    $body = $naming | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Uri "$SonarrUrl/api/v3/config/naming/$($naming.id)" -Method PUT -Headers $headers -Body $body | Out-Null
    Write-Host "✓ Naming configuration updated" -ForegroundColor Green
} catch {
    Write-Host "✗ Error configuring naming: $_" -ForegroundColor Red
}

Write-Host "`n=== Configuration Complete ===`n" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure qBittorrent download client" -ForegroundColor White
Write-Host "2. Connect to Prowlarr for indexers" -ForegroundColor White
Write-Host "3. Create/verify quality profile" -ForegroundColor White
Write-Host "4. Import TV library" -ForegroundColor White
