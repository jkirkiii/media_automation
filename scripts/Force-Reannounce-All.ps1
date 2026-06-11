# Force Reannounce All StalledUP Torrents
param([string]$user, [string]$password, [int]$port=8080)

Write-Host "`nForce Reannounce - StalledUP Torrents`n" -ForegroundColor Cyan

# Load credentials from config.ps1 (sibling of the scripts folder) unless overridden
$configPath = Join-Path $PSScriptRoot "..\config.ps1"
if (Test-Path $configPath) { . $configPath }

if (-not $user)     { $user     = $qBittorrentUsername }
if (-not $password) { $password = $qBittorrentPassword }

if (-not $user) {
    Write-Host "No username found. Set qBittorrentUsername in config.ps1 or pass -user." -ForegroundColor Red
    exit
}
if (-not $password) {
    $pass = Read-Host 'qBittorrent password' -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass)
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

$base = "http://localhost:$port"

Write-Host "Connecting to qBittorrent as '$user'..." -ForegroundColor Yellow
$login = Invoke-WebRequest -Uri "$base/api/v2/auth/login" -Method POST -Body "username=$user&password=$password" -SessionVariable qb -UseBasicParsing

if ($login.Content -ne 'Ok.') {
    Write-Host "Login failed" -ForegroundColor Red
    exit
}

Write-Host "Connected!`n" -ForegroundColor Green

$torrents = Invoke-RestMethod -Uri "$base/api/v2/torrents/info" -WebSession $qb
$stalled = $torrents | Where-Object { $_.state -eq "stalledUP" }

Write-Host "Found $($stalled.Count) stalledUP torrents" -ForegroundColor Cyan
Write-Host "Force reannouncing to all trackers...`n" -ForegroundColor Yellow

$reannounced = 0
$failed = 0

foreach ($t in $stalled) {
    try {
        $reannounceUrl = "$base/api/v2/torrents/reannounce"
        $body = "hashes=$($t.hash)"

        Invoke-WebRequest -Uri $reannounceUrl -Method POST -Body $body -WebSession $qb -UseBasicParsing -ErrorAction Stop | Out-Null

        $reannounced++

        if ($reannounced % 10 -eq 0) {
            Write-Host "  Reannounced $reannounced/$($stalled.Count)..." -ForegroundColor Gray
        }
    } catch {
        $failed++
        Write-Host "  Error on: $($t.name)" -ForegroundColor Red
        Write-Host "    Details: $($_.Exception.Message)" -ForegroundColor Yellow

        if ($failed -eq 1) {
            Write-Host "    URL tried: $reannounceUrl" -ForegroundColor Gray
            Write-Host "    Body: $body" -ForegroundColor Gray
        }
    }

    Start-Sleep -Milliseconds 100
}

Write-Host "`nSuccess: $reannounced torrents" -ForegroundColor Green
Write-Host "Failed: $failed torrents" -ForegroundColor Red

if ($reannounced -gt 0) {
    Write-Host "`nWait 2-3 minutes, then check tracker status in qBittorrent`n" -ForegroundColor Yellow
} else {
    Write-Host "`nAPI call failed - trying alternative method...`n" -ForegroundColor Yellow
    Write-Host "You can manually force reannounce in qBittorrent:" -ForegroundColor Cyan
    Write-Host "  1. Select all torrents (Ctrl+A)" -ForegroundColor White
    Write-Host "  2. Right-click -> Force reannounce (or press Ctrl+R)`n" -ForegroundColor White
}
