# Connect qBittorrent to Sonarr - Secure Password Entry
# This script will prompt for password securely

$qBitUsername = "murdoch137"
$SonarrUrl = "http://localhost:8989"
$SonarrApiKey = "332f7d21453b4225a85fc6852bdad7ee"
$qBitHost = "localhost"
$qBitPort = 8080

Write-Host "`n=== Connect qBittorrent to Sonarr ===`n" -ForegroundColor Cyan

# Prompt for password securely
$securePassword = Read-Host "Enter qBittorrent password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$qBitPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$headers = @{"X-Api-Key" = $SonarrApiKey; "Content-Type" = "application/json"}

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
        removeCompletedDownloads = $false
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

    try {
        $result = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/downloadclient" -Method POST -Headers $headers -Body $body
        Write-Host "`nqBittorrent connected successfully!" -ForegroundColor Green
        Write-Host "  Username: $qBitUsername" -ForegroundColor White
        Write-Host "  Category: tv-sonarr" -ForegroundColor White
        Write-Host "  Remove after import: NO (respects seeding)" -ForegroundColor Yellow
    } catch {
        Write-Host "`nError connecting qBittorrent: $_" -ForegroundColor Red
        Write-Host "Please verify:" -ForegroundColor Yellow
        Write-Host "  - qBittorrent WebUI is enabled" -ForegroundColor White
        Write-Host "  - Username and password are correct" -ForegroundColor White
        Write-Host "  - qBittorrent is running" -ForegroundColor White
    }
}

Write-Host "`n=== Next: Create tv-sonarr category in qBittorrent ===`n" -ForegroundColor Cyan
