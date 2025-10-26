# Fix-VampireDiaries-Seasons.ps1
# Renames irregular season folder names to standard format

param(
    [string]$ShowPath = "A:\Media\TV Shows\The Vampire Diaries (2009)",
    [switch]$DryRun = $false
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Vampire Diaries Season Folders Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "*** DRY RUN MODE - NO CHANGES WILL BE MADE ***" -ForegroundColor Yellow
    Write-Host ""
}

if (-not (Test-Path $ShowPath)) {
    Write-Host "ERROR: Show path not found: $ShowPath" -ForegroundColor Red
    exit 1
}

# Define folder renames
$renames = @(
    @{Old = "TheVampireDiariesSeason1"; New = "Season 01"},
    @{Old = "TheVampireDiariesSeason2"; New = "Season 02"},
    @{Old = "TheVampireDiariesSeason3"; New = "Season 03"}
)

$totalRenamed = 0
$totalSkipped = 0

foreach ($rename in $renames) {
    $oldPath = Join-Path $ShowPath $rename.Old
    $newPath = Join-Path $ShowPath $rename.New

    Write-Host "Processing: $($rename.Old)" -ForegroundColor Cyan

    if (-not (Test-Path $oldPath)) {
        Write-Host "  SKIP: Folder not found (may already be renamed)" -ForegroundColor Yellow
        $totalSkipped++
        continue
    }

    if (Test-Path $newPath) {
        Write-Host "  ERROR: Target folder already exists: $($rename.New)" -ForegroundColor Red
        Write-Host "    Manual merge may be required" -ForegroundColor Yellow
        $totalSkipped++
        continue
    }

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would rename:" -ForegroundColor Cyan
        Write-Host "    FROM: $($rename.Old)" -ForegroundColor Gray
        Write-Host "    TO:   $($rename.New)" -ForegroundColor Gray
    } else {
        try {
            Rename-Item -Path $oldPath -NewName $rename.New -Force
            Write-Host "  RENAMED: $($rename.Old) → $($rename.New)" -ForegroundColor Green
            $totalRenamed++
        } catch {
            Write-Host "  ERROR: Failed to rename: $_" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Folders renamed: $totalRenamed" -ForegroundColor White
Write-Host "  Folders skipped: $totalSkipped" -ForegroundColor White

if ($DryRun) {
    Write-Host ""
    Write-Host "This was a DRY RUN - no actual changes were made" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "MANUAL CHECK REQUIRED" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "The following folders may contain duplicate content:" -ForegroundColor Yellow
Write-Host "  - 'The Vampire Diaries - Season 6 Complete -ChameE'" -ForegroundColor White
Write-Host "  - 'The Vampire Diaries Season 4 (2012-2013) COMPLETE by vladtepes3176'" -ForegroundColor White
Write-Host "  - 'The Vampire Diaries Season 5 (2013-2014) COMPLETE by vladtepes3176'" -ForegroundColor White
Write-Host ""
Write-Host "Please check these folders and:" -ForegroundColor Yellow
Write-Host "  1. Compare content with renamed seasons" -ForegroundColor White
Write-Host "  2. Merge if they contain missing episodes" -ForegroundColor White
Write-Host "  3. Delete if they are complete duplicates" -ForegroundColor White
Write-Host ""
