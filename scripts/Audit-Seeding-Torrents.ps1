# Audit-Seeding-Torrents.ps1
# Reports all seeding torrents with time seeded, ratio, size, and tracker.
# Buckets results by multiple seed-time thresholds so you can apply the
# correct minimum for each tracker before removing anything.
#
# Usage:
#   .\Audit-Seeding-Torrents.ps1
#   .\Audit-Seeding-Torrents.ps1 -MinDays 14          # change default threshold
#   .\Audit-Seeding-Torrents.ps1 -ExportCsv           # also save a CSV report
#   .\Audit-Seeding-Torrents.ps1 -Category tv-sonarr  # filter by category

param(
    [string]$qBitUrl   = "",
    [string]$Username  = "",
    [string]$Password  = "",
    [int]$MinDays      = 10,
    [string]$Category  = "",        # leave blank for all categories
    [switch]$ExportCsv
)

# ---------------------------------------------------------------------------
# Load credentials
# ---------------------------------------------------------------------------
$repoRoot   = Split-Path $PSScriptRoot -Parent
$configFile = Join-Path $repoRoot "config.ps1"
if (Test-Path $configFile) {
    . $configFile
    if (-not $qBitUrl)  { $qBitUrl  = $qBittorrentUrl }
    if (-not $Username) { $Username = $qBittorrentUsername }
    if (-not $Password) { $Password = $qBittorrentPassword }
}
if (-not $qBitUrl)  { $qBitUrl  = "http://localhost:8080" }

# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------
try {
    Invoke-WebRequest -Uri "$qBitUrl/api/v2/auth/login" `
        -Method POST `
        -Body "username=$Username&password=$Password" `
        -ContentType "application/x-www-form-urlencoded" `
        -SessionVariable qbSession `
        -UseBasicParsing `
        -ErrorAction Stop | Out-Null
} catch {
    Write-Host "[ERROR] Cannot reach qBittorrent at $qBitUrl" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
# $qbSession is now populated by -SessionVariable

# ---------------------------------------------------------------------------
# Fetch torrent list
# ---------------------------------------------------------------------------
$apiUrl = "$qBitUrl/api/v2/torrents/info?filter=all"
if ($Category) { $apiUrl += "&category=$Category" }

$torrents = Invoke-RestMethod -Uri $apiUrl -WebSession $qbSession

$now = [int][double]::Parse((Get-Date -UFormat %s))

# ---------------------------------------------------------------------------
# Build enriched objects
# ---------------------------------------------------------------------------
$thresholds = @(10, 14, 21, 30)   # days - covers most private tracker minimums

$enriched = foreach ($t in $torrents) {
    # seeding_time is seconds actively seeding (more reliable than wall-clock)
    $seedDays   = [math]::Round($t.seeding_time / 86400, 1)
    $addedDays  = [math]::Round(($now - $t.added_on) / 86400, 1)
    $sizeMB     = [math]::Round($t.size / 1MB, 0)
    $sizeGB     = [math]::Round($t.size / 1GB, 2)

    # Derive a short tracker hostname for readability
    $trackerHost = ""
    if ($t.tracker) {
        try { $trackerHost = ([System.Uri]$t.tracker).Host -replace "^www\.",""  }
        catch { $trackerHost = $t.tracker }
    }

    # Flag which thresholds this torrent has met
    $metThresholds = ($thresholds | Where-Object { $seedDays -ge $_ }) -join ", "
    if (-not $metThresholds) { $metThresholds = "none" }

    [PSCustomObject]@{
        Name            = $t.name
        Category        = $t.category
        State           = $t.state
        "SeedDays"      = $seedDays
        "AddedDaysAgo"  = $addedDays
        "Ratio"         = [math]::Round($t.ratio, 2)
        "SizeGB"        = $sizeGB
        Tracker         = $trackerHost
        "MetThresholds" = $metThresholds
        Hash            = $t.hash
    }
}

# ---------------------------------------------------------------------------
# Summary header
# ---------------------------------------------------------------------------
$total      = $enriched.Count
$totalSizeGB= [math]::Round(($enriched | Measure-Object SizeGB -Sum).Sum, 2)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  qBittorrent Seeding Audit" -ForegroundColor Cyan
Write-Host ("  " + (Get-Date -Format 'yyyy-MM-dd HH:mm') + "   " + $total + " torrents   " + $totalSizeGB + " GB total") -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Bucket breakdown
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Seed-time bucket summary:" -ForegroundColor Yellow
Write-Host "  (seeding_time = time actively seeding, not wall-clock since add)" -ForegroundColor DarkGray

foreach ($days in $thresholds) {
    $bucket     = @($enriched | Where-Object { $_.SeedDays -ge $days })
    $bucketGB   = [math]::Round(($bucket | Measure-Object SizeGB -Sum).Sum, 2)
    $pct        = if ($total -gt 0) { [math]::Round($bucket.Count / $total * 100) } else { 0 }
    Write-Host ("  >= {0,2} days : {1,4} torrents  ({2}%)   {3} GB" -f `
        $days, $bucket.Count, $pct, $bucketGB) -ForegroundColor White
}

$under10    = @($enriched | Where-Object { $_.SeedDays -lt 10 })
$under10GB  = [math]::Round(($under10 | Measure-Object SizeGB -Sum).Sum, 2)
Write-Host ("  <  10 days : {0,4} torrents          {1} GB  (do not remove)" -f `
    $under10.Count, $under10GB) -ForegroundColor DarkGray

# ---------------------------------------------------------------------------
# Per-tracker breakdown
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Per-tracker breakdown:" -ForegroundColor Yellow
$enriched | Group-Object Tracker | Sort-Object Count -Descending | ForEach-Object {
    $grp     = $_.Group
    $grpGB   = [math]::Round(($grp | Measure-Object SizeGB -Sum).Sum, 2)
    $met10   = @($grp | Where-Object { $_.SeedDays -ge 10  }).Count
    $met14   = @($grp | Where-Object { $_.SeedDays -ge 14  }).Count
    $met30   = @($grp | Where-Object { $_.SeedDays -ge 30  }).Count
    $avgRatio= [math]::Round(($grp | Measure-Object Ratio -Average).Average, 2)
    Write-Host ""
    Write-Host ("  {0}" -f $_.Name) -ForegroundColor Cyan
    Write-Host ("    Torrents : {0}   |   Total size : {1} GB   |   Avg ratio : {2}" -f `
        $_.Count, $grpGB, $avgRatio)
    Write-Host ("    Met >= 10d: {0}   |   >= 14d: {1}   |   >= 30d: {2}" -f $met10, $met14, $met30)
}

# ---------------------------------------------------------------------------
# Category breakdown
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Per-category breakdown:" -ForegroundColor Yellow
$enriched | Group-Object Category | Sort-Object { ($_.Group | Measure-Object SizeGB -Sum).Sum } -Descending | ForEach-Object {
    $grp    = $_.Group
    $grpGB  = [math]::Round(($grp | Measure-Object SizeGB -Sum).Sum, 2)
    $met10  = @($grp | Where-Object { $_.SeedDays -ge 10 }).Count
    Write-Host ("  {0,-20}  {1,4} torrents   {2,8} GB   {3} met 10d" -f `
        $_.Name, $_.Count, $grpGB, $met10)
}

# ---------------------------------------------------------------------------
# Torrents NOT yet meeting the minimum threshold (do not remove)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- Torrents BELOW 10-day threshold (do not remove) ---" -ForegroundColor Red
$notReady = @($enriched | Where-Object { $_.SeedDays -lt 10 } | Sort-Object SeedDays)
if ($notReady.Count -eq 0) {
    Write-Host "  None - all torrents have met the 10-day minimum." -ForegroundColor Green
} else {
    $notReady | Format-Table Name, Category, SeedDays, AddedDaysAgo, Ratio, SizeGB, Tracker -AutoSize
}

# ---------------------------------------------------------------------------
# Torrents meeting >= MinDays (candidates for removal)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host ("--- Torrents meeting >= $MinDays days (eligible for removal) ---") -ForegroundColor Green
$ready = @($enriched | Where-Object { $_.SeedDays -ge $MinDays } | Sort-Object SeedDays -Descending)
if ($ready.Count -eq 0) {
    Write-Host "  None meet the $MinDays day threshold yet." -ForegroundColor Yellow
} else {
    $readyGB = [math]::Round(($ready | Measure-Object SizeGB -Sum).Sum, 2)
    Write-Host ("  " + $ready.Count + " torrents   " + $readyGB + " GB potentially reclaimable") -ForegroundColor Green
    Write-Host "  (hardlinked files in Media\ will be unaffected)" -ForegroundColor DarkGray
    Write-Host ""
    $ready | Format-Table Name, Category, SeedDays, Ratio, SizeGB, Tracker -AutoSize
}

# ---------------------------------------------------------------------------
# Low-ratio alert (may want to keep seeding regardless of time)
# ---------------------------------------------------------------------------
$lowRatio = @($enriched | Where-Object { $_.SeedDays -ge $MinDays -and $_.Ratio -lt 1.0 })
if ($lowRatio.Count -gt 0) {
    Write-Host ""
    Write-Host ("--- Low-ratio alert (>= " + $MinDays + "d but ratio below 1.0 - consider keeping) ---") -ForegroundColor Yellow
    $lowRatio | Format-Table Name, Category, SeedDays, Ratio, SizeGB, Tracker -AutoSize
}

# ---------------------------------------------------------------------------
# CSV export
# ---------------------------------------------------------------------------
if ($ExportCsv) {
    $csvPath = Join-Path (Split-Path $PSScriptRoot -Parent) "data\torrent_audit_$(Get-Date -Format 'yyyy-MM-dd').csv"
    $enriched | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host ""
    Write-Host "[OK] CSV exported to: $csvPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Done. Review above before removing anything." -ForegroundColor Cyan
Write-Host "  Use -MinDays 14 (or 21/30) to change the threshold." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
