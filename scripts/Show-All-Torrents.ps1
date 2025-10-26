# Show All qBittorrent Torrents and Their States
param([string]$user='murdoch137', [int]$port=8080)

Write-Host "`nqBittorrent - All Torrents Status`n" -ForegroundColor Cyan

$pass = Read-Host 'qBittorrent password' -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$base = "http://localhost:$port"

Write-Host "Connecting to qBittorrent..." -ForegroundColor Yellow
$login = Invoke-WebRequest -Uri "$base/api/v2/auth/login" -Method POST -Body "username=$user&password=$password" -SessionVariable qb

if ($login.Content -ne 'Ok.') {
    Write-Host "Login failed - check password" -ForegroundColor Red
    exit
}

Write-Host "Connected!`n" -ForegroundColor Green

$torrents = Invoke-RestMethod -Uri "$base/api/v2/torrents/info" -WebSession $qb

Write-Host "Total torrents in qBittorrent: $($torrents.Count)`n" -ForegroundColor Cyan

if ($torrents.Count -eq 0) {
    Write-Host "No torrents found in qBittorrent" -ForegroundColor Yellow
    Write-Host "`nThis could mean:" -ForegroundColor Cyan
    Write-Host "  - qBittorrent is empty (no torrents added)" -ForegroundColor White
    Write-Host "  - Wrong qBittorrent instance" -ForegroundColor White
    Write-Host "  - Torrents in different category/filter" -ForegroundColor White
    exit
}

# Group by state
$byState = $torrents | Group-Object -Property state | Sort-Object Count -Descending

Write-Host "Torrents by State:" -ForegroundColor Cyan
foreach ($group in $byState) {
    $stateName = $group.Name
    $count = $group.Count

    $color = switch ($stateName) {
        "uploading" { "Green" }
        "stalledUP" { "Green" }
        "pausedUP" { "Yellow" }
        "queuedUP" { "Yellow" }
        "checkingUP" { "Cyan" }
        "downloading" { "Cyan" }
        "stalledDL" { "Yellow" }
        "pausedDL" { "Yellow" }
        "error" { "Red" }
        "missingFiles" { "Red" }
        default { "White" }
    }

    Write-Host "  $stateName : $count" -ForegroundColor $color
}

# Show sample torrents
Write-Host "`nSample Torrents (first 10):" -ForegroundColor Cyan
$torrents | Select-Object -First 10 | ForEach-Object {
    $shortName = $_.name
    if ($shortName.Length -gt 60) {
        $shortName = $shortName.Substring(0, 57) + "..."
    }

    $color = if ($_.state -match "UP|seeding|uploading") { "Green" }
             elseif ($_.state -match "paused") { "Yellow" }
             elseif ($_.state -match "error") { "Red" }
             else { "White" }

    Write-Host "  [$($_.state)] $shortName" -ForegroundColor $color
}

if ($torrents.Count -gt 10) {
    Write-Host "  ... and $($torrents.Count - 10) more" -ForegroundColor Gray
}

# Check for TV category
$tvTorrents = $torrents | Where-Object { $_.category -eq "tv-sonarr" }
Write-Host "`nTV-Sonarr category: $($tvTorrents.Count) torrents" -ForegroundColor Cyan

# Identify what might be "seeding"
$potentialSeeders = $torrents | Where-Object {
    $_.state -match "uploading|stalledUP|queuedUP|pausedUP|checkingUP"
}

Write-Host "`nPotentially seeding (any upload-related state): $($potentialSeeders.Count)" -ForegroundColor Cyan

if ($potentialSeeders.Count -gt 0) {
    Write-Host "`nSeeding/Upload States Found:" -ForegroundColor Yellow
    $potentialSeeders | Group-Object -Property state | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White
    }
}

# Check paused torrents
$paused = $torrents | Where-Object { $_.state -match "paused" }
if ($paused.Count -gt 0) {
    Write-Host "`n⚠️  Found $($paused.Count) paused torrents" -ForegroundColor Yellow
    Write-Host "These might be showing as 'not seeding' on tracker websites" -ForegroundColor Yellow
    Write-Host "To resume: Select in qBittorrent -> Right-click -> Start" -ForegroundColor White
}

Write-Host ""
