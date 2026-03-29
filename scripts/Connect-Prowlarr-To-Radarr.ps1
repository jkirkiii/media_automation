# Connect-Prowlarr-To-Radarr.ps1
# Adds Radarr as an application in Prowlarr to sync indexers

param(
    [Parameter(Mandatory=$false)]
    [string]$ProwlarrApiKey,

    [Parameter(Mandatory=$false)]
    [string]$RadarrApiKey,

    [Parameter(Mandatory=$false)]
    [string]$ProwlarrUrl = "http://localhost:9696",

    [Parameter(Mandatory=$false)]
    [string]$RadarrUrl = "http://localhost:7878"
)

# Load config if not provided
if (-not $ProwlarrApiKey -or -not $RadarrApiKey) {
    $configPath = Join-Path $PSScriptRoot "..\config.ps1"
    if (Test-Path $configPath) {
        . $configPath
        $ProwlarrApiKey = $ProwlarrApiKey
        $RadarrApiKey = $RadarrApiKey
        Write-Host "[INFO] Loaded credentials from config.ps1" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] No API keys provided and config.ps1 not found" -ForegroundColor Red
        exit 1
    }
}

$headers = @{
    "X-Api-Key" = $ProwlarrApiKey
    "Content-Type" = "application/json"
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CONNECTING PROWLARR TO RADARR" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test Prowlarr connection
Write-Host "[1/3] Testing Prowlarr connection..." -ForegroundColor Yellow
try {
    $prowlarrStatus = Invoke-RestMethod -Uri "$ProwlarrUrl/api/v1/system/status" -Headers $headers -Method Get
    Write-Host "      Connected to Prowlarr v$($prowlarrStatus.version)" -ForegroundColor Green
} catch {
    Write-Host "      [ERROR] Cannot connect to Prowlarr" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check if Radarr app already exists
Write-Host "`n[2/3] Checking for existing Radarr application..." -ForegroundColor Yellow
try {
    $existingApps = Invoke-RestMethod -Uri "$ProwlarrUrl/api/v1/applications" -Headers $headers -Method Get
    $existingRadarr = $existingApps | Where-Object { $_.name -eq "Radarr" }

    if ($existingRadarr) {
        Write-Host "      Radarr application already exists in Prowlarr" -ForegroundColor Yellow
        Write-Host "      Application ID: $($existingRadarr.id)" -ForegroundColor Gray
        Write-Host "      Sync Level: $($existingRadarr.syncLevel)" -ForegroundColor Gray
        Write-Host "`n      Skipping creation (already configured)" -ForegroundColor Yellow
    } else {
        # Add Radarr application
        Write-Host "`n[3/3] Adding Radarr application to Prowlarr..." -ForegroundColor Yellow

        $radarrApp = @{
            name = "Radarr"
            syncLevel = "fullSync"
            fields = @(
                @{
                    name = "prowlarrUrl"
                    value = $ProwlarrUrl
                },
                @{
                    name = "baseUrl"
                    value = $RadarrUrl
                },
                @{
                    name = "apiKey"
                    value = $RadarrApiKey
                },
                @{
                    name = "syncCategories"
                    value = @(2000, 2010, 2020, 2030, 2040, 2050, 2060, 2070)  # Movie categories
                }
            )
            implementationName = "Radarr"
            implementation = "Radarr"
            configContract = "RadarrSettings"
            tags = @()
        } | ConvertTo-Json -Depth 10

        $newApp = Invoke-RestMethod -Uri "$ProwlarrUrl/api/v1/applications" -Headers $headers -Method Post -Body $radarrApp
        Write-Host "      Radarr application added successfully" -ForegroundColor Green
        Write-Host "      Application ID: $($newApp.id)" -ForegroundColor Gray

        # Trigger sync
        Write-Host "`n      Triggering indexer sync..." -ForegroundColor Yellow
        try {
            $syncCommand = @{
                name = "ApplicationSync"
            } | ConvertTo-Json

            Invoke-RestMethod -Uri "$ProwlarrUrl/api/v1/command" -Headers $headers -Method Post -Body $syncCommand | Out-Null
            Write-Host "      Sync command sent" -ForegroundColor Green
        } catch {
            Write-Host "      [WARNING] Could not trigger sync: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "      [ERROR] Failed to add Radarr application" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CONNECTION COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Verification:" -ForegroundColor Yellow
Write-Host "  1. Check Prowlarr → Settings → Apps to see Radarr listed" -ForegroundColor Gray
Write-Host "  2. Check Radarr → Settings → Indexers to see synced indexers" -ForegroundColor Gray
Write-Host "`nNext: Connect qBittorrent as download client to Radarr" -ForegroundColor Green
