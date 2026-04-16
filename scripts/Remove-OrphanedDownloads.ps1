# Remove-OrphanedDownloads.ps1
# Deletes orphaned download files/folders for torrents that have already been
# removed from qBittorrent but whose Downloads copies were never deleted.
#
# Reads a hardlink_analysis_*.csv produced by Analyze-HardlinkFailures.ps1
# and, for each entry in a safe category, searches the Downloads directories
# for a matching file or folder and removes it.
#
# Safe categories acted on by default:
#   UPGRADE_ORPHAN_EPISODE  -- single episode confirmed in Media
#   SEASON_COMPLETE         -- season pack confirmed in Media
#   MOVIE_FOUND             -- movie confirmed in Media
#
# Usage:
#   .\scripts\Remove-OrphanedDownloads.ps1                    # dry run
#   .\scripts\Remove-OrphanedDownloads.ps1 -Execute           # delete files
#   .\scripts\Remove-OrphanedDownloads.ps1 -CsvFile data\hardlink_analysis_2026-04-13.csv
#   .\scripts\Remove-OrphanedDownloads.ps1 -Categories UPGRADE_ORPHAN_EPISODE,MOVIE_FOUND

param(
    [string]$CsvFile      = "",
    [string]$TvDownloads  = "A:\Downloads\TV",
    [string]$MovDownloads = "A:\Downloads\Movies",
    # Extra roots to scan if a name is not found in the category-specific folder.
    # Handles manually-downloaded torrents saved outside the standard paths.
    [string[]]$ExtraRoots = @("A:\Downloads"),
    [string[]]$Categories = @("UPGRADE_ORPHAN_EPISODE", "SEASON_COMPLETE", "MOVIE_FOUND"),
    [switch]$Execute
)

$DryRun   = -not $Execute
$repoRoot = Split-Path $PSScriptRoot -Parent

# ---------------------------------------------------------------------------
# Locate CSV -- default to newest hardlink_analysis file in data\
# ---------------------------------------------------------------------------
if (-not $CsvFile) {
    $candidates = @(Get-ChildItem -Path (Join-Path $repoRoot "data") `
                    -Filter "hardlink_analysis_*.csv" -ErrorAction SilentlyContinue |
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
# Header
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  Remove-OrphanedDownloads.ps1  [DRY RUN - no changes]" -ForegroundColor Cyan
} else {
    Write-Host "  Remove-OrphanedDownloads.ps1  [EXECUTE MODE]" -ForegroundColor Yellow
}
Write-Host "  CSV       : $CsvFile" -ForegroundColor Cyan
Write-Host "  TV root   : $TvDownloads" -ForegroundColor Cyan
Write-Host "  Movie root: $MovDownloads" -ForegroundColor Cyan
Write-Host "  Categories: $($Categories -join ', ')" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# Load CSV and filter to safe categories
# ---------------------------------------------------------------------------
$analyzed = Import-Csv $CsvFile
$targets  = @($analyzed | Where-Object { $Categories -contains $_.Category })

Write-Host ("[INFO] CSV has {0} total entries; {1} in selected categories" -f $analyzed.Count, $targets.Count) -ForegroundColor Gray
Write-Host ""

if ($targets.Count -eq 0) {
    Write-Host "Nothing to process for the selected categories." -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------------------------------------
# Build ordered list of roots to probe for each entry type
# TV entries  -> TvDownloads first, then ExtraRoots
# Movie entries -> MovDownloads first, then ExtraRoots
# ---------------------------------------------------------------------------
function Get-SearchRoots([string]$entryType) {
    $tv  = @($TvDownloads)  + $ExtraRoots
    $mov = @($MovDownloads) + $ExtraRoots
    if ($entryType -eq "MOVIE") { return $mov } else { return $tv }
}

# ---------------------------------------------------------------------------
# For a given torrent Name, find the file or folder on disk.
# The torrent name may be:
#   (a) a folder   -> Root\Name\
#   (b) a bare file -> Root\Name   (if Name already has an extension)
#   (c) nothing found
# Returns the full path of the item found, or $null.
# ---------------------------------------------------------------------------
function Find-DownloadItem([string]$name, [string[]]$roots) {
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }

        # Exact match as a directory
        $dirPath = Join-Path $root $name
        if (Test-Path -Path $dirPath -PathType Container) { return $dirPath }

        # Exact match as a file (torrent name already has extension, e.g. .mkv)
        if (Test-Path -Path $dirPath -PathType Leaf) { return $dirPath }

        # The torrent name may lack an extension; check for a file with same base name
        $files = @(Get-ChildItem -Path $root -Filter "$name.*" -File -ErrorAction SilentlyContinue)
        if ($files.Count -gt 0) { return $files[0].FullName }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Match every target to a path on disk
# ---------------------------------------------------------------------------
$toRemove  = [System.Collections.ArrayList]@()
$notOnDisk = [System.Collections.ArrayList]@()

foreach ($row in $targets) {
    $roots = Get-SearchRoots $row.Type
    $path  = Find-DownloadItem $row.Name $roots

    if ($path) {
        $item = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
        $sizeGB = 0.0
        if ($item) {
            if ($item.PSIsContainer) {
                $sizeGB = [math]::Round(
                    (Get-ChildItem -LiteralPath $path -Recurse -File -ErrorAction SilentlyContinue |
                     Measure-Object Length -Sum).Sum / 1GB, 3)
            } else {
                $sizeGB = [math]::Round($item.Length / 1GB, 3)
            }
        }
        $null = $toRemove.Add([PSCustomObject]@{
            Name     = $row.Name
            Category = $row.Category
            Path     = $path
            IsDir    = $item.PSIsContainer
            SizeGB   = $sizeGB
        })
    } else {
        $null = $notOnDisk.Add($row.Name)
    }
}

# ---------------------------------------------------------------------------
# Report what was not found on disk (already deleted or never downloaded)
# ---------------------------------------------------------------------------
if ($notOnDisk.Count -gt 0) {
    Write-Host ("--- {0} entries not found on disk (already deleted?) ---" -f $notOnDisk.Count) -ForegroundColor DarkYellow
    foreach ($n in $notOnDisk) {
        Write-Host ("  $n") -ForegroundColor DarkGray
    }
    Write-Host ""
}

$totalGB = [math]::Round(($toRemove | Measure-Object SizeGB -Sum).Sum, 2)

Write-Host ("{0} items found on disk ready for removal ({1} GB)" -f $toRemove.Count, $totalGB) -ForegroundColor Green
Write-Host ""

if ($toRemove.Count -eq 0) {
    Write-Host "Nothing left to remove." -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------------------------------------
# Dry-run: just list what would be deleted
# ---------------------------------------------------------------------------
if ($DryRun) {
    Write-Host "--- DRY RUN: the following would be deleted ---" -ForegroundColor Yellow
    Write-Host ""

    $byCategory = $toRemove | Group-Object Category
    foreach ($grp in $byCategory) {
        $grpGB = [math]::Round(($grp.Group | Measure-Object SizeGB -Sum).Sum, 2)
        Write-Host ("  $($grp.Name) ({0} items, {1} GB)" -f $grp.Count, $grpGB) -ForegroundColor Green
        foreach ($r in ($grp.Group | Sort-Object Name)) {
            $label = $r.Name
            if ($label.Length -gt 80) { $label = $label.Substring(0, 77) + "..." }
            $typeTag = if ($r.IsDir) { "[DIR] " } else { "[FILE]" }
            Write-Host ("    $typeTag $label  ($($r.SizeGB) GB)") -ForegroundColor White
        }
        Write-Host ""
    }

    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  DRY RUN complete. No changes made." -ForegroundColor Cyan
    Write-Host ("  {0} items would be removed ({1} GB)" -f $toRemove.Count, $totalGB) -ForegroundColor Cyan
    Write-Host "  Re-run with -Execute to apply." -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# ---------------------------------------------------------------------------
# Execute: remove each item
# ---------------------------------------------------------------------------
Write-Host "--- Removing orphaned downloads ---" -ForegroundColor Yellow
Write-Host ""

$removed = 0
$failed  = 0
$freedGB = 0.0

foreach ($r in $toRemove) {
    try {
        if ($r.IsDir) {
            Remove-Item -LiteralPath $r.Path -Recurse -Force -ErrorAction Stop
        } else {
            Remove-Item -LiteralPath $r.Path -Force -ErrorAction Stop
        }
        $removed++
        $freedGB += $r.SizeGB
        Write-Host ("[OK] $($r.Name)  ($($r.SizeGB) GB)") -ForegroundColor Green
    } catch {
        $failed++
        Write-Host ("[FAIL] $($r.Name) -- $($_.Exception.Message)") -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Removal complete" -ForegroundColor Cyan
Write-Host ("  Removed : {0} items" -f $removed) -ForegroundColor Green
Write-Host ("  Freed   : {0} GB" -f [math]::Round($freedGB, 2)) -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host ("  Failed  : {0} items" -f $failed) -ForegroundColor Red
}
if ($notOnDisk.Count -gt 0) {
    Write-Host ("  Skipped : {0} items not found on disk" -f $notOnDisk.Count) -ForegroundColor DarkYellow
}
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
