# Connect-qBittorrent-To-Radarr.ps1
# Adds qBittorrent as a download client in Radarr

param(
    [Parameter(Mandatory=$false)]
    [string]$RadarrApiKey,

    [Parameter(Mandatory=$false)]
    [string]$qBitUsername,

    [Parameter(Mandatory=$false)]
    [string]$qBitPassword,

    [Parameter(Mandatory=$false)]
    [string]$RadarrUrl = "http://localhost:7878",

    [Parameter(Mandatory=$false)]
    [string]$qBittorrentUrl = "http://localhost:8080"
)

# Load config if not provided
if (-not $RadarrApiKey -or -not $qBitUsername -or -not $qBitPassword) {
    $configPath = Join-Path $PSScriptRoot "..\config.ps1"
    if (Test-Path $configPath) {
        . $configPath
        $RadarrApiKey = $RadarrApiKey
        $qBitUsername = $qBittorrentUsername
        $qBitPassword = $qBittorrentPassword
        Write-Host "[INFO] Loaded credentials from config.ps1" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] No credentials provided and config.ps1 not found" -ForegroundColor Red
        exit 1
    }
}

$headers = @{
    "X-Api-Key" = $RadarrApiKey
    "Content-Type" = "application/json"
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CONNECTING qBITTORRENT TO RADARR" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test Radarr connection
Write-Host "[1/3] Testing Radarr connection..." -ForegroundColor Yellow
try {
    $radarrStatus = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/system/status" -Headers $headers -Method Get
    Write-Host "      Connected to Radarr v$($radarrStatus.version)" -ForegroundColor Green
} catch {
    Write-Host "      [ERROR] Cannot connect to Radarr" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check if qBittorrent is already configured
Write-Host "`n[2/3] Checking for existing qBittorrent download client..." -ForegroundColor Yellow
try {
    $existingClients = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/downloadclient" -Headers $headers -Method Get
    $existingqBit = $existingClients | Where-Object { $_.name -eq "qBittorrent" }

    if ($existingqBit) {
        Write-Host "      qBittorrent already configured in Radarr" -ForegroundColor Yellow
        Write-Host "      Client ID: $($existingqBit.id)" -ForegroundColor Gray
        Write-Host "      Category: $($existingqBit.fields | Where-Object { $_.name -eq 'movieCategory' } | Select-Object -ExpandProperty value)" -ForegroundColor Gray
        Write-Host "`n      Skipping creation (already configured)" -ForegroundColor Yellow
    } else {
        # Add qBittorrent download client
        Write-Host "`n[3/3] Adding qBittorrent download client to Radarr..." -ForegroundColor Yellow

        $qBitClient = @{
            enable = $true
            protocol = "torrent"
            priority = 1
            removeCompletedDownloads = $false  # CRITICAL for seeding on private trackers
            removeFailedDownloads = $true
            name = "qBittorrent"
            fields = @(
                @{
                    name = "host"
                    value = "localhost"
                },
                @{
                    name = "port"
                    value = 8080
                },
                @{
                    name = "useSsl"
                    value = $false
                },
                @{
                    name = "urlBase"
                    value = ""
                },
                @{
                    name = "username"
                    value = $qBitUsername
                },
                @{
                    name = "password"
                    value = $qBitPassword
                },
                @{
                    name = "movieCategory"
                    value = "movie-radarr"
                },
                @{
                    name = "recentMoviePriority"
                    value = 0  # Last
                },
                @{
                    name = "olderMoviePriority"
                    value = 0  # Last
                },
                @{
                    name = "initialState"
                    value = 0  # Start
                },
                @{
                    name = "sequentialOrder"
                    value = $false
                },
                @{
                    name = "firstAndLast"
                    value = $false
                }
            )
            implementationName = "qBittorrent"
            implementation = "QBittorrent"
            configContract = "QBittorrentSettings"
            tags = @()
        } | ConvertTo-Json -Depth 10

        try {
            $newClient = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/downloadclient" -Headers $headers -Method Post -Body $qBitClient
            Write-Host "      qBittorrent download client added successfully" -ForegroundColor Green
            Write-Host "      Client ID: $($newClient.id)" -ForegroundColor Gray
            Write-Host "      Category: movie-radarr" -ForegroundColor Gray
            Write-Host "      Remove Completed: False (keeps seeding)" -ForegroundColor Gray
        } catch {
            Write-Host "      [ERROR] Failed to add download client" -ForegroundColor Red
            Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "      Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host "      [ERROR] Failed to check/add download client" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CONNECTION COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  - Download client: qBittorrent" -ForegroundColor Gray
Write-Host "  - Category: movie-radarr �+' A:\Downloads\Movies" -ForegroundColor Gray
Write-Host "  - Remove completed: False (keeps seeding for private trackers)" -ForegroundColor Gray

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Verify movie-radarr category exists in qBittorrent" -ForegroundColor Gray
Write-Host "  2. Test Radarr by adding a movie and searching manually" -ForegroundColor Gray
