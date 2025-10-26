# Connect qBittorrent to Sonarr
# Usage: .\Connect-qBittorrent-To-Sonarr.ps1 -qBitUsername "admin" -qBitPassword "yourpassword"

param(
    [Parameter(Mandatory=$true)]
    [string]$qBitUsername,

    [Parameter(Mandatory=$true)]
    [string]$qBitPassword,

    [string]$qBitHost = "localhost",
    [int]$qBitPort = 8080,
    [string]$SonarrUrl = "http://localhost:8989",
    [string]$SonarrApiKey = "332f7d21453b4225a85fc6852bdad7ee"
)

$headers = @{"X-Api-Key" = $SonarrApiKey; "Content-Type" = "application/json"}

Write-Host "`n=== Connecting qBittorrent to Sonarr ===`n" -ForegroundColor Cyan

Write-Host "Checking existing download clients..." -ForegroundColor Yellow
$clients = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/downloadclient" -Headers $headers
$qbitClient = $clients | Where-Object { $_.name -eq "qBittorrent" }

if ($qbitClient) {
    Write-Host "qBittorrent already connected" -ForegroundColor Green
} else {
    Write-Host "Adding qBittorrent..." -ForegroundColor Yellow

    $body = @{
        enable = $true
        protocol = "torrent"
        priority = 1
        removeCompletedDownloads = $false  # CRITICAL: Don't remove for seeding!
        removeFailedDownloads = $true
        name = "qBittorrent"
        fields = @(
            @{ name = "host"; value = $qBitHost }
            @{ name = "port"; value = $qBitPort }
            @{ name = "useSsl"; value = $false }
            @{ name = "urlBase"; value = "" }
            @{ name = "username"; value = $qBitUsername }
            @{ name = "password"; value = $qBitPassword }
            @{ name = "tvCategory"; value = "tv-sonarr" }
            @{ name = "tvImportedCategory"; value = "" }
            @{ name = "recentTvPriority"; value = 0 }
            @{ name = "olderTvPriority"; value = 0 }
            @{ name = "initialState"; value = 0 }
            @{ name = "sequentialOrder"; value = $false }
            @{ name = "firstAndLast"; value = $false }
        )
        implementationName = "qBittorrent"
        implementation = "QBittorrent"
        configContract = "QBittorrentSettings"
        tags = @()
    } | ConvertTo-Json -Depth 10

    $result = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/downloadclient" -Method POST -Headers $headers -Body $body
    Write-Host "qBittorrent connected!" -ForegroundColor Green
    Write-Host "  Category: tv-sonarr" -ForegroundColor White
    Write-Host "  Remove after import: NO (for seeding)" -ForegroundColor Yellow
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
Write-Host "`nIMPORTANT: Create 'tv-sonarr' category in qBittorrent if it doesn't exist!" -ForegroundColor Yellow
