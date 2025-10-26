# Fix-IndividualEpisodeFolders-v2.ps1
# Fixed version that handles special characters in folder names
# Consolidates shows that have individual folders per episode

param(
    [string]$TVShowsPath = "A:\Media\TV Shows",
    [switch]$DryRun = $false
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Individual Episode Folders Cleanup v2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "*** DRY RUN MODE - NO CHANGES WILL BE MADE ***" -ForegroundColor Yellow
    Write-Host ""
}

# Define shows with individual episode folders
$showsToFix = @(
    @{Name = "Wild Wild Country (2018)"; Season = 1},
    @{Name = "The Rehearsal (2022)"; Season = 1},
    @{Name = "Mrs. Davis (2023)"; Season = 1},
    @{Name = "Party Down (2009)"; Season = 3}
)

$totalMoved = 0
$totalFoldersRemoved = 0
$totalSkipped = 0
$totalCreated = 0

foreach ($showInfo in $showsToFix) {
    $showName = $showInfo.Name
    $seasonNum = $showInfo.Season
    $showPath = Join-Path $TVShowsPath $showName

    Write-Host "Processing: $showName" -ForegroundColor Cyan
    Write-Host "----------------------------------------"

    if (-not (Test-Path -LiteralPath $showPath)) {
        Write-Host "  SKIP: Show folder not found" -ForegroundColor Yellow
        Write-Host ""
        continue
    }

    $seasonFolderName = "Season {0:D2}" -f $seasonNum
    $seasonPath = Join-Path $showPath $seasonFolderName

    # Create season folder if it doesn't exist
    if (-not (Test-Path -LiteralPath $seasonPath)) {
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would create: $seasonFolderName" -ForegroundColor Cyan
        } else {
            try {
                New-Item -Path $seasonPath -ItemType Directory -Force | Out-Null
                Write-Host "  CREATED: $seasonFolderName" -ForegroundColor Green
                $totalCreated++
            } catch {
                Write-Host "  ERROR: Failed to create season folder: $_" -ForegroundColor Red
                continue
            }
        }
    } else {
        Write-Host "  Found existing: $seasonFolderName" -ForegroundColor White
    }

    # Get all episode folders (folders with S##E## pattern)
    $episodeFolders = Get-ChildItem -LiteralPath $showPath -Directory |
                     Where-Object {
                         $_.Name -match 'S\d+E\d+' -and
                         $_.Name -ne $seasonFolderName
                     }

    Write-Host "  Found $($episodeFolders.Count) episode folder(s) to process" -ForegroundColor White
    Write-Host ""

    foreach ($episodeFolder in $episodeFolders) {
        Write-Host "    Processing: $($episodeFolder.Name)" -ForegroundColor Gray

        # Find video files in this episode folder - use -LiteralPath to handle brackets
        $videoFiles = Get-ChildItem -LiteralPath $episodeFolder.FullName -Recurse -File |
                     Where-Object { $_.Extension -match '\.(mkv|mp4|avi|m4v)$' }

        if ($videoFiles.Count -eq 0) {
            Write-Host "      No video files found" -ForegroundColor Gray
        } else {
            Write-Host "      Found $($videoFiles.Count) video file(s)" -ForegroundColor White
        }

        foreach ($file in $videoFiles) {
            $targetPath = Join-Path $seasonPath $file.Name

            if (Test-Path -LiteralPath $targetPath) {
                Write-Host "      SKIP: $($file.Name) already exists" -ForegroundColor Yellow
                $totalSkipped++
            } else {
                if ($DryRun) {
                    Write-Host "      [DRY RUN] Would move: $($file.Name)" -ForegroundColor Cyan
                    $totalMoved++
                } else {
                    try {
                        Move-Item -LiteralPath $file.FullName -Destination $targetPath -Force
                        Write-Host "      MOVED: $($file.Name)" -ForegroundColor Green
                        $totalMoved++
                    } catch {
                        Write-Host "      ERROR: Failed to move $($file.Name): $_" -ForegroundColor Red
                    }
                }
            }
        }

        # Remove empty episode folder (check again after moves)
        if (-not $DryRun) {
            Start-Sleep -Milliseconds 200  # Brief pause to ensure filesystem catches up
            $remainingFiles = Get-ChildItem -LiteralPath $episodeFolder.FullName -Recurse -File
            if ($remainingFiles.Count -eq 0) {
                try {
                    Remove-Item -LiteralPath $episodeFolder.FullName -Recurse -Force
                    Write-Host "      REMOVED: $($episodeFolder.Name)" -ForegroundColor Gray
                    $totalFoldersRemoved++
                } catch {
                    Write-Host "      WARN: Could not remove folder: $_" -ForegroundColor Yellow
                }
            } else {
                Write-Host "      KEPT: $($episodeFolder.Name) (contains $($remainingFiles.Count) file(s))" -ForegroundColor Yellow
            }
        } else {
            Write-Host "      [DRY RUN] Would remove folder after moving files" -ForegroundColor Gray
        }
    }

    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Season folders created: $totalCreated" -ForegroundColor White
Write-Host "  Files moved: $totalMoved" -ForegroundColor White
Write-Host "  Files skipped (already exist): $totalSkipped" -ForegroundColor White
Write-Host "  Episode folders removed: $totalFoldersRemoved" -ForegroundColor White

if ($DryRun) {
    Write-Host ""
    Write-Host "This was a DRY RUN - no actual changes were made" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Yellow
}

Write-Host ""
