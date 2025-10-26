# Fix-Taskmaster-NestedFolders.ps1
# Flattens nested episode files in Taskmaster season folders
# Moves files from release group folders directly into season folders

param(
    [string]$ShowPath = "A:\Media\TV Shows\Taskmaster (2015)",
    [switch]$DryRun = $false
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Taskmaster Nested Folders Cleanup" -ForegroundColor Cyan
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

$seasons = @("Season 02", "Season 04", "Season 05", "Season 06", "Season 07", "Season 08", "Season 09")
$totalMoved = 0
$totalFoldersRemoved = 0
$totalSkipped = 0

foreach ($season in $seasons) {
    $seasonPath = Join-Path $ShowPath $season

    if (-not (Test-Path $seasonPath)) {
        Write-Host "[$season] Skipping - folder not found" -ForegroundColor Yellow
        continue
    }

    Write-Host "Processing: $season" -ForegroundColor Cyan
    Write-Host "----------------------------------------"

    # Find all video files in nested folders (not directly in season folder)
    $videoFiles = Get-ChildItem -Path $seasonPath -Recurse -File |
                  Where-Object {
                      $_.Extension -match '\.(mkv|mp4|avi|m4v)$' -and
                      $_.Directory.FullName -ne $seasonPath
                  }

    Write-Host "  Found $($videoFiles.Count) nested file(s)" -ForegroundColor White

    foreach ($file in $videoFiles) {
        $targetPath = Join-Path $seasonPath $file.Name
        $relativeSource = $file.FullName.Replace("$seasonPath\", "")

        if (Test-Path $targetPath) {
            Write-Host "  SKIP: $($file.Name) already exists at root" -ForegroundColor Yellow
            $totalSkipped++
        } else {
            if ($DryRun) {
                Write-Host "  [DRY RUN] Would move:" -ForegroundColor Cyan
                Write-Host "    FROM: $relativeSource" -ForegroundColor Gray
                Write-Host "    TO:   $($file.Name)" -ForegroundColor Gray
            } else {
                try {
                    Move-Item -Path $file.FullName -Destination $targetPath -Force
                    Write-Host "  MOVED: $($file.Name)" -ForegroundColor Green
                    $totalMoved++
                } catch {
                    Write-Host "  ERROR: Failed to move $($file.Name): $_" -ForegroundColor Red
                }
            }
        }
    }

    # Remove empty nested folders
    $nestedFolders = Get-ChildItem -Path $seasonPath -Directory

    foreach ($folder in $nestedFolders) {
        $remainingFiles = Get-ChildItem -Path $folder.FullName -Recurse -File

        if ($remainingFiles.Count -eq 0) {
            if ($DryRun) {
                Write-Host "  [DRY RUN] Would remove empty folder: $($folder.Name)" -ForegroundColor Gray
            } else {
                try {
                    Remove-Item -Path $folder.FullName -Recurse -Force
                    Write-Host "  REMOVED: $($folder.Name)" -ForegroundColor Gray
                    $totalFoldersRemoved++
                } catch {
                    Write-Host "  WARN: Could not remove $($folder.Name): $_" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "  KEPT: $($folder.Name) (contains $($remainingFiles.Count) file(s))" -ForegroundColor Yellow
        }
    }

    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Files moved: $totalMoved" -ForegroundColor White
Write-Host "  Files skipped (already exist): $totalSkipped" -ForegroundColor White
Write-Host "  Empty folders removed: $totalFoldersRemoved" -ForegroundColor White

if ($DryRun) {
    Write-Host ""
    Write-Host "This was a DRY RUN - no actual changes were made" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Yellow
}

Write-Host ""
