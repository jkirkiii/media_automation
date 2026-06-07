# Remove-HardlinkOrphanTorrents.ps1
# Removes torrents from qBittorrent (with deleteFiles=true) for entries in
# hardlink_analysis_*.csv that are in the LIKELY SAFE categories:
#   UPGRADE_ORPHAN_EPISODE, SEASON_COMPLETE, MOVIE_FOUND
#
# These torrents have a Downloads copy that is NOT hardlinked to Media -- so
# deleting them via qB reclaims real disk space and leaves Media untouched.
#
# Safety layers:
#  1. Only acts on entries whose CSV Category is in the allowed list.
#  2. Re-runs the fsutil hardlink check at removal time. If the content_path
#     IS hardlinked (hardlinks > 1), the entry is skipped -- protects against
#     CSV staleness (e.g. Sonarr re-imported in the meantime).
#  3. Refuses to act on any torrent whose content_path starts with A:\Media\.
#
# Usage:
#   .\scripts\Remove-HardlinkOrphanTorrents.ps1                 # dry run
#   .\scripts\Remove-HardlinkOrphanTorrents.ps1 -Execute        # actually remove
#   .\scripts\Remove-HardlinkOrphanTorrents.ps1 -CsvFile path\to\hardlink_analysis_x.csv

param(
    [string]$CsvFile           = "",
    [string]$qBitUrl           = "",
    [string]$Username          = "",
    [string]$Password          = "",
    [string[]]$Categories      = @("UPGRADE_ORPHAN_EPISODE","SEASON_COMPLETE","MOVIE_FOUND"),
    [string]$MediaRoot         = "A:\Media",
    # Hard exclusions for automation safety:
    [string[]]$ExcludeQbCats   = @("books","audiobooks","music"),     # qB category names to never touch
    [string[]]$ExcludeTrackers = @("t.myanonamouse.net"),             # tracker host substrings to never touch
    [string[]]$ExcludeHashes   = @(),                                  # qB torrent hashes to skip (e.g. items in -arr queue)
    [switch]$Execute
)

$DryRun   = -not $Execute
$repoRoot = Split-Path $PSScriptRoot -Parent

# ---------------------------------------------------------------------------
# Load credentials from config.ps1 (same pattern as other scripts)
# ---------------------------------------------------------------------------
$configFile = Join-Path $repoRoot "config.ps1"
if (Test-Path $configFile) {
    . $configFile
    if (-not $qBitUrl)  { $qBitUrl  = $qBittorrentUrl }
    if (-not $Username) { $Username = $qBittorrentUsername }
    if (-not $Password) { $Password = $qBittorrentPassword }
}
if (-not $qBitUrl)  { $qBitUrl  = "http://localhost:8080" }

# ---------------------------------------------------------------------------
# Locate CSV
# ---------------------------------------------------------------------------
if (-not $CsvFile) {
    $cands = @(Get-ChildItem (Join-Path $repoRoot "data") -Filter "hardlink_analysis_*.csv" -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
    if ($cands) { $CsvFile = $cands[0].FullName }
}
if (-not (Test-Path $CsvFile)) {
    Write-Host "[ERROR] No hardlink_analysis CSV found." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  Remove-HardlinkOrphanTorrents.ps1  [DRY RUN]" -ForegroundColor Cyan
} else {
    Write-Host "  Remove-HardlinkOrphanTorrents.ps1  [EXECUTE]" -ForegroundColor Yellow
}
Write-Host "  CSV       : $CsvFile" -ForegroundColor Cyan
Write-Host "  qBit URL  : $qBitUrl" -ForegroundColor Cyan
Write-Host "  Categories: $($Categories -join ', ')" -ForegroundColor Cyan
Write-Host "  Media root: $MediaRoot (refused as content_path)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# Login to qBittorrent
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

# ---------------------------------------------------------------------------
# Fetch torrent list
# ---------------------------------------------------------------------------
$torrents = Invoke-RestMethod -Uri "$qBitUrl/api/v2/torrents/info" -WebSession $qbSession -UseBasicParsing

# Index by name for quick lookup
$byName = @{}
foreach ($t in $torrents) {
    if (-not $byName.ContainsKey($t.name)) {
        $byName[$t.name] = @($t)
    } else {
        $byName[$t.name] += $t
    }
}

# ---------------------------------------------------------------------------
# Load + filter CSV
# ---------------------------------------------------------------------------
$rows = Import-Csv $CsvFile | Where-Object { $Categories -contains $_.Category }
Write-Host "[INFO] $($rows.Count) entries in selected categories" -ForegroundColor Gray
Write-Host ""

# ---------------------------------------------------------------------------
# Match + safety-check each row
# ---------------------------------------------------------------------------
$toRemove   = New-Object System.Collections.Generic.List[object]
$notInQB    = New-Object System.Collections.Generic.List[string]
$nowLinked  = New-Object System.Collections.Generic.List[object]
$inMedia    = New-Object System.Collections.Generic.List[object]
$catBlocked = New-Object System.Collections.Generic.List[object]
$trkBlocked = New-Object System.Collections.Generic.List[object]
$arrQueued  = New-Object System.Collections.Generic.List[object]

# Per-torrent tracker lookup is one extra API call. Cache results.
$trackerCache = @{}
function Get-TorrentTrackers($hash) {
    if ($trackerCache.ContainsKey($hash)) { return $trackerCache[$hash] }
    try {
        $trks = Invoke-RestMethod -Uri "$qBitUrl/api/v2/torrents/trackers?hash=$hash" -WebSession $qbSession -UseBasicParsing
        $hosts = @($trks | ForEach-Object {
            try { ([uri]$_.url).Host } catch { $null }
        } | Where-Object { $_ })
        $trackerCache[$hash] = $hosts
        return $hosts
    } catch {
        $trackerCache[$hash] = @()
        return @()
    }
}

foreach ($r in $rows) {
    if (-not $byName.ContainsKey($r.Name)) {
        $notInQB.Add($r.Name) | Out-Null
        continue
    }
    foreach ($t in $byName[$r.Name]) {
        $contentPath = $t.content_path
        $sizeGB      = [math]::Round($t.size / 1GB, 3)

        # Safety 0a: refuse anything whose qB category is in the exclusion set
        if ($t.category -and ($ExcludeQbCats -contains $t.category)) {
            $catBlocked.Add([PSCustomObject]@{ Name=$r.Name; Category=$t.category; SizeGB=$sizeGB }) | Out-Null
            continue
        }

        # Safety 0b: refuse anything whose hash is in the -arr queue
        if ($ExcludeHashes -contains $t.hash) {
            $arrQueued.Add([PSCustomObject]@{ Name=$r.Name; SizeGB=$sizeGB }) | Out-Null
            continue
        }

        # Safety 0c: refuse anything announcing to a blocked tracker host
        if ($ExcludeTrackers.Count -gt 0) {
            $hosts = Get-TorrentTrackers $t.hash
            $blocked = $false
            foreach ($h in $hosts) {
                foreach ($needle in $ExcludeTrackers) {
                    if ($h -and $needle -and $h.ToLower().Contains($needle.ToLower())) { $blocked = $true; break }
                }
                if ($blocked) { break }
            }
            if ($blocked) {
                $trkBlocked.Add([PSCustomObject]@{ Name=$r.Name; Trackers=($hosts -join ', '); SizeGB=$sizeGB }) | Out-Null
                continue
            }
        }

        # Safety 1: refuse anything whose content_path lives under the Media root
        if ($contentPath -and $contentPath.ToLower().StartsWith($MediaRoot.ToLower())) {
            $inMedia.Add([PSCustomObject]@{ Name=$r.Name; ContentPath=$contentPath; SizeGB=$sizeGB }) | Out-Null
            continue
        }

        # Safety 2: re-check hardlink status -- if Sonarr/Radarr re-imported since
        # the analysis ran, the file may now be a hardlink and removal would
        # still leave Media intact, but it also means our "duplicate" claim is
        # stale. Skip to be safe.
        $stillOrphan = $true
        if ($contentPath -and (Test-Path -LiteralPath $contentPath)) {
            if (Test-Path -LiteralPath $contentPath -PathType Container) {
                $files = Get-ChildItem -LiteralPath $contentPath -Recurse -File -ErrorAction SilentlyContinue
                $videoFiles = $files | Where-Object { '.mkv','.mp4','.avi','.m4v','.mov','.wmv','.iso','.ts','.m2ts' -contains $_.Extension.ToLower() }
                if ($videoFiles) {
                    $allLinked = $true
                    foreach ($f in $videoFiles) {
                        $links = & fsutil hardlink list $f.FullName 2>$null
                        if (@($links).Count -le 1) { $allLinked = $false; break }
                    }
                    if ($allLinked) { $stillOrphan = $false }
                }
            } else {
                $links = & fsutil hardlink list $contentPath 2>$null
                if (@($links).Count -gt 1) { $stillOrphan = $false }
            }
        }

        if (-not $stillOrphan) {
            $nowLinked.Add([PSCustomObject]@{ Name=$r.Name; ContentPath=$contentPath; SizeGB=$sizeGB }) | Out-Null
            continue
        }

        $toRemove.Add([PSCustomObject]@{
            Name        = $r.Name
            Category    = $r.Category
            Hash        = $t.hash
            ContentPath = $contentPath
            SizeGB      = $sizeGB
        }) | Out-Null
    }
}

# ---------------------------------------------------------------------------
# Report skipped items
# ---------------------------------------------------------------------------
if ($notInQB.Count -gt 0) {
    Write-Host "--- $($notInQB.Count) CSV entries not in qBittorrent (already removed?) ---" -ForegroundColor DarkYellow
    foreach ($n in $notInQB) { Write-Host "  $n" -ForegroundColor DarkGray }
    Write-Host ""
}
if ($catBlocked.Count -gt 0) {
    Write-Host "--- $($catBlocked.Count) entries SKIPPED: qB category is protected ---" -ForegroundColor Yellow
    $catBlocked | Format-Table Name, Category, SizeGB -AutoSize | Out-String | Write-Host
}
if ($trkBlocked.Count -gt 0) {
    Write-Host "--- $($trkBlocked.Count) entries SKIPPED: tracker is on no-touch list ---" -ForegroundColor Yellow
    $trkBlocked | Format-Table Name, Trackers, SizeGB -AutoSize | Out-String | Write-Host
}
if ($arrQueued.Count -gt 0) {
    Write-Host "--- $($arrQueued.Count) entries SKIPPED: currently in Sonarr/Radarr queue ---" -ForegroundColor Yellow
    $arrQueued | Format-Table Name, SizeGB -AutoSize | Out-String | Write-Host
}
if ($inMedia.Count -gt 0) {
    Write-Host "--- $($inMedia.Count) entries REFUSED: content_path is inside Media root ---" -ForegroundColor Red
    $inMedia | Format-Table Name, ContentPath, SizeGB -AutoSize | Out-String | Write-Host
}
if ($nowLinked.Count -gt 0) {
    Write-Host "--- $($nowLinked.Count) entries SKIPPED: now hardlinked (analysis is stale) ---" -ForegroundColor Yellow
    $nowLinked | Format-Table Name, ContentPath, SizeGB -AutoSize | Out-String | Write-Host
}

$totalGB = [math]::Round(($toRemove | Measure-Object SizeGB -Sum).Sum, 2)
Write-Host "--- $($toRemove.Count) torrents eligible for removal ($totalGB GB) ---" -ForegroundColor Green
Write-Host ""

if ($toRemove.Count -eq 0) {
    Write-Host "Nothing to remove." -ForegroundColor Yellow
    exit 0
}

# Group summary
$toRemove | Group-Object Category | Sort-Object { ($_.Group | Measure-Object SizeGB -Sum).Sum } -Descending |
    ForEach-Object {
        $gb = [math]::Round(($_.Group | Measure-Object SizeGB -Sum).Sum, 2)
        Write-Host "  $($_.Name): $($_.Count) torrents   $gb GB"
    }
Write-Host ""

if ($DryRun) {
    Write-Host "--- DRY RUN: the following would be removed ---" -ForegroundColor Yellow
    $toRemove | Sort-Object Category, Name | Format-Table Name, Category, SizeGB -AutoSize
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  DRY RUN complete. No changes made." -ForegroundColor Cyan
    Write-Host "  $($toRemove.Count) torrents   $totalGB GB would be freed" -ForegroundColor Cyan
    Write-Host "  Re-run with -Execute to apply." -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    exit 0
}

# ---------------------------------------------------------------------------
# Execute: remove in batches of 100
# ---------------------------------------------------------------------------
Write-Host "--- Removing torrents (deleteFiles=true) ---" -ForegroundColor Yellow
Write-Host ""

$removed = 0
$failed  = 0
$freedGB = 0.0

$removeList = @($toRemove)
for ($i = 0; $i -lt $removeList.Count; $i += 100) {
    $end       = [math]::Min($i + 99, $removeList.Count - 1)
    $batch     = @($removeList[$i..$end])
    $batchN    = $batch.Count
    $hashes    = ($batch | Select-Object -ExpandProperty Hash) -join "|"
    $batchGB   = [math]::Round(($batch | Measure-Object SizeGB -Sum).Sum, 2)
    $body      = "hashes=$hashes&deleteFiles=true"

    try {
        Invoke-WebRequest -Uri "$qBitUrl/api/v2/torrents/delete" `
            -Method POST `
            -Body $body `
            -ContentType "application/x-www-form-urlencoded" `
            -WebSession $qbSession `
            -UseBasicParsing `
            -ErrorAction Stop | Out-Null
        $removed += $batchN
        $freedGB += $batchGB
        Write-Host "[OK] Removed batch of $batchN torrents ($batchGB GB)" -ForegroundColor Green
    } catch {
        $failed += $batchN
        Write-Host "[FAIL] Batch failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Removal complete" -ForegroundColor Cyan
Write-Host "  Removed : $removed torrents" -ForegroundColor Green
Write-Host "  Freed   : $([math]::Round($freedGB,2)) GB (once OS reclaims blocks)" -ForegroundColor Green
if ($failed -gt 0) { Write-Host "  Failed  : $failed torrents" -ForegroundColor Red }
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
