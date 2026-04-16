# Remove-AnalyzedTorrents.ps1
# Removes torrents that were categorized as safe by Analyze-HardlinkFailures.ps1.
#
# These torrents passed the seed-time check in Remove-SeededTorrents.ps1 but were
# skipped because the hardlink check failed. The analysis confirmed that their
# episodes/movies ARE in the Media library -- just imported from a different
# (better quality) torrent. The Downloads copy is genuinely orphaned.
#
# Usage:
#   .\scripts\Remove-AnalyzedTorrents.ps1                    # dry run (default)
#   .\scripts\Remove-AnalyzedTorrents.ps1 -Execute           # actually remove
#   .\scripts\Remove-AnalyzedTorrents.ps1 -Categories UPGRADE_ORPHAN_EPISODE,MOVIE_FOUND
#   .\scripts\Remove-AnalyzedTorrents.ps1 -CsvFile data\hardlink_analysis_2026-04-12.csv

param(
    [string]$CsvFile    = "",
    [string]$qBitUrl    = "",
    [string]$Username   = "",
    [string]$Password   = "",
    # Categories to remove. Default = all three confirmed-safe categories.
    [string[]]$Categories = @("UPGRADE_ORPHAN_EPISODE", "SEASON_COMPLETE", "MOVIE_FOUND"),
    [switch]$Execute
)

$DryRun  = -not $Execute
$repoRoot = Split-Path $PSScriptRoot -Parent

# Default CSV: newest hardlink_analysis file in data\
if (-not $CsvFile) {
    $candidates = @(Get-ChildItem -Path (Join-Path $repoRoot "data") -Filter "hardlink_analysis_*.csv" -ErrorAction SilentlyContinue |
                    Sort-Object Name -Descending)
    if ($candidates) {
        $CsvFile = $candidates[0].FullName
    } else {
        Write-Host "[ERROR] No hardlink_analysis_*.csv found in data\. Run Analyze-HardlinkFailures.ps1 -ExportCsv first." -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path $CsvFile)) {
    Write-Host "[ERROR] CSV not found: $CsvFile" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Load credentials
# ---------------------------------------------------------------------------
$configFile = Join-Path $repoRoot "config.ps1"
if (Test-Path $configFile) {
    . $configFile
    if (-not $qBitUrl)  { $qBitUrl  = $qBittorrentUrl }
    if (-not $Username) { $Username = $qBittorrentUsername }
    if (-not $Password) { $Password = $qBittorrentPassword }
}
if (-not $qBitUrl) { $qBitUrl = "http://localhost:8080" }

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  Remove-AnalyzedTorrents.ps1  [DRY RUN - no changes]" -ForegroundColor Cyan
} else {
    Write-Host "  Remove-AnalyzedTorrents.ps1  [EXECUTE MODE]" -ForegroundColor Yellow
}
Write-Host "  CSV      : $CsvFile" -ForegroundColor Cyan
Write-Host "  Categories: $($Categories -join ', ')" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# Read the analysis CSV and filter to safe categories
# ---------------------------------------------------------------------------
$analyzed = Import-Csv $CsvFile
$targets  = @($analyzed | Where-Object { $Categories -contains $_.Category })

Write-Host ("[INFO] CSV has {0} total entries; {1} match the selected categories" -f $analyzed.Count, $targets.Count) -ForegroundColor Gray
Write-Host ""

if ($targets.Count -eq 0) {
    Write-Host "Nothing to remove for the selected categories." -ForegroundColor Yellow
    exit 0
}

# Show what we plan to remove, grouped by category
foreach ($cat in $Categories) {
    $group = @($targets | Where-Object { $_.Category -eq $cat })
    if ($group.Count -eq 0) { continue }
    Write-Host ("  $cat : {0} torrents" -f $group.Count) -ForegroundColor Green
}
Write-Host ""

# ---------------------------------------------------------------------------
# Connect to qBittorrent
# ---------------------------------------------------------------------------
try {
    Invoke-WebRequest -Uri "$qBitUrl/api/v2/auth/login" `
        -Method POST `
        -Body "username=$Username&password=$Password" `
        -ContentType "application/x-www-form-urlencoded" `
        -SessionVariable qbSession `
        -UseBasicParsing `
        -ErrorAction Stop | Out-Null
    Write-Host "[OK] Connected to qBittorrent at $qBitUrl" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Cannot reach qBittorrent: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Fetch all torrents from qBittorrent and build a name -> hash lookup
# ---------------------------------------------------------------------------
$allTorrents = Invoke-RestMethod -Uri "$qBitUrl/api/v2/torrents/info?filter=all" -WebSession $qbSession
Write-Host ("[INFO] qBittorrent has {0} torrents total" -f $allTorrents.Count) -ForegroundColor Gray
Write-Host ""

$nameToHash = @{}
foreach ($t in $allTorrents) {
    # Use the first match if duplicate names exist (edge case)
    if (-not $nameToHash.ContainsKey($t.name)) {
        $nameToHash[$t.name] = $t.hash
    }
}

# ---------------------------------------------------------------------------
# Match CSV entries to qBittorrent hashes
# ---------------------------------------------------------------------------
$matched   = [System.Collections.ArrayList]@()
$notFound  = [System.Collections.ArrayList]@()

foreach ($row in $targets) {
    $hash = $nameToHash[$row.Name]
    if ($hash) {
        $null = $matched.Add([PSCustomObject]@{
            Name     = $row.Name
            Category = $row.Category
            Notes    = $row.Notes
            Hash     = $hash
        })
    } else {
        $null = $notFound.Add($row.Name)
    }
}

if ($notFound.Count -gt 0) {
    Write-Host ("--- {0} CSV entries not found in qBittorrent (already removed?) ---" -f $notFound.Count) -ForegroundColor DarkYellow
    foreach ($n in $notFound) {
        Write-Host ("  $n") -ForegroundColor DarkGray
    }
    Write-Host ""
}

Write-Host ("{0} torrents matched in qBittorrent and ready for removal" -f $matched.Count) -ForegroundColor Green

# Compute a rough size estimate from qBittorrent data
$sizeGB = [math]::Round(
    ($allTorrents | Where-Object { $matched.Hash -contains $_.hash } |
     Measure-Object size -Sum).Sum / 1GB, 2)
Write-Host ("Estimated space to free: {0} GB (once OS reclaims blocks)" -f $sizeGB) -ForegroundColor Green
Write-Host ""

if ($matched.Count -eq 0) {
    Write-Host "Nothing left to remove." -ForegroundColor Yellow
    exit 0
}

if ($DryRun) {
    Write-Host "--- DRY RUN: the following would be removed ---" -ForegroundColor Yellow
    $matched | Format-Table -Property Name, Category -AutoSize
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  DRY RUN complete. No changes made." -ForegroundColor Cyan
    Write-Host ("  {0} torrents would be removed ({1} GB)" -f $matched.Count, $sizeGB) -ForegroundColor Cyan
    Write-Host "  Re-run with -Execute to apply." -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# ---------------------------------------------------------------------------
# Execute: remove in batches of 100
# ---------------------------------------------------------------------------
Write-Host "--- Removing torrents ---" -ForegroundColor Yellow
Write-Host ""

$removed = 0
$failed  = 0
$freedGB = 0.0

for ($i = 0; $i -lt $matched.Count; $i += 100) {
    $batch   = $matched[$i..([math]::Min($i + 99, $matched.Count - 1))]
    $hashes  = ($batch | Select-Object -ExpandProperty Hash) -join "|"
    $batchGB = [math]::Round(
        ($allTorrents | Where-Object { ($batch | Select-Object -ExpandProperty Hash) -contains $_.hash } |
         Measure-Object size -Sum).Sum / 1GB, 2)
    $body    = "hashes=" + $hashes + "&deleteFiles=true"

    try {
        Invoke-WebRequest -Uri "$qBitUrl/api/v2/torrents/delete" `
            -Method POST `
            -Body $body `
            -ContentType "application/x-www-form-urlencoded" `
            -WebSession $qbSession `
            -UseBasicParsing `
            -ErrorAction Stop | Out-Null

        $removed += $batch.Count
        $freedGB += $batchGB
        Write-Host ("[OK] Removed batch of {0} torrents ({1} GB)" -f $batch.Count, $batchGB) -ForegroundColor Green
    } catch {
        $failed += $batch.Count
        Write-Host ("[FAIL] Batch removal failed: $($_.Exception.Message)") -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Removal complete" -ForegroundColor Cyan
Write-Host ("  Removed : {0} torrents" -f $removed) -ForegroundColor Green
Write-Host ("  Freed   : {0} GB (once OS reclaims blocks)" -f [math]::Round($freedGB, 2)) -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host ("  Failed  : {0} torrents" -f $failed) -ForegroundColor Red
}
if ($notFound.Count -gt 0) {
    Write-Host ("  Skipped : {0} torrents (not in qBittorrent, likely already removed)" -f $notFound.Count) -ForegroundColor DarkYellow
}
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
