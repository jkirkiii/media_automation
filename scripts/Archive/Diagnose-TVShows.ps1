# Diagnose-TVShows.ps1
# Analyzes TV Shows directory structure and generates a detailed CSV report
# Identifies naming issues and provides recommendations for Plex/Sonarr compliance

param(
    [string]$TVShowsPath = "A:\Media\TV Shows",
    [string]$OutputPath = ".\tv_shows_diagnostic_report.csv"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TV Shows Diagnostic Report Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if path exists
if (-not (Test-Path $TVShowsPath)) {
    Write-Host "ERROR: TV Shows path not found: $TVShowsPath" -ForegroundColor Red
    exit 1
}

Write-Host "Scanning: $TVShowsPath" -ForegroundColor Yellow
Write-Host ""

# Initialize results array
$results = @()
$showCount = 0
$issueCount = 0

# Get all show folders
$showFolders = Get-ChildItem -Path $TVShowsPath -Directory | Sort-Object Name

Write-Host "Found $($showFolders.Count) show folders. Analyzing..." -ForegroundColor Yellow
Write-Host ""

foreach ($showFolder in $showFolders) {
    $showCount++
    Write-Host "[$showCount/$($showFolders.Count)] Analyzing: $($showFolder.Name)" -ForegroundColor Cyan

    $showName = $showFolder.Name
    $showPath = $showFolder.FullName

    # Initialize analysis variables
    $hasYear = $false
    $yearMatch = ""
    $isReleaseGroupName = $false
    $seasonFolderType = "Unknown"
    $seasonCount = 0
    $fileCount = 0
    $issues = @()
    $recommendations = @()

    # Check if folder name is actually a release group name
    if ($showName -match '\.(S\d+|COMPLETE|1080p|720p|480p|2160p|WEB|WEBDL|WEBRip|BluRay|AMZN|DSNP|HULU|HBO|MAX|NF)') {
        $isReleaseGroupName = $true
        $issues += "CRITICAL: Release group name as show folder"
        $issueCount++
    }

    # Check for year in parentheses (Plex standard)
    if ($showName -match '\((\d{4})\)') {
        $hasYear = $true
        $yearMatch = $matches[1]
    } else {
        $issues += "Missing year tag in show name"
        $issueCount++
    }

    # Get season folders
    $seasonFolders = Get-ChildItem -Path $showPath -Directory -ErrorAction SilentlyContinue
    $seasonCount = $seasonFolders.Count

    if ($seasonCount -eq 0) {
        $seasonFolderType = "None (Empty show folder)"
        $issues += "No season folders or files found"
        $issueCount++
    } else {
        # Analyze season folder naming
        $standardSeasonCount = 0
        $releaseGroupCount = 0
        $episodeFolderCount = 0
        $otherCount = 0

        foreach ($seasonFolder in $seasonFolders) {
            $seasonName = $seasonFolder.Name

            # Check for standard "Season ##" format
            if ($seasonName -match '^Season \d+$') {
                $standardSeasonCount++
            }
            # Check for release group season folders (Show.Name.S##.*)
            elseif ($seasonName -match '^[^\\]+\.(S\d+)') {
                $releaseGroupCount++
            }
            # Check for individual episode folders (Show.Name.S##E##.*)
            elseif ($seasonName -match '\.(S\d+E\d+)\.') {
                $episodeFolderCount++
            }
            else {
                $otherCount++
            }
        }

        # Determine primary season folder type
        if ($standardSeasonCount -eq $seasonCount) {
            $seasonFolderType = "Standard (Season ##)"
        } elseif ($releaseGroupCount -gt 0) {
            $seasonFolderType = "Release Group Season Folders"
            $issues += "Non-standard season folder naming (release group format)"
            $issueCount++
        } elseif ($episodeFolderCount -gt 0) {
            $seasonFolderType = "Individual Episode Folders"
            $issues += "CRITICAL: Episodes in individual folders"
            $issueCount++
        } elseif ($otherCount -gt 0) {
            $seasonFolderType = "Mixed/Other"
            $issues += "Unrecognized season folder structure"
            $issueCount++
        }

        # Count total episode files
        $files = Get-ChildItem -Path $showPath -Recurse -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.Extension -match '\.(mkv|mp4|avi|m4v)$' }
        $fileCount = $files.Count

        # Check file naming patterns (sample first 3 files)
        $sampleFiles = $files | Select-Object -First 3
        $properlyNamedFiles = 0
        $totalSampled = 0

        foreach ($file in $sampleFiles) {
            $totalSampled++
            $fileName = $file.Name

            # Check for proper format: Show Name - S##E## - Episode Title.ext
            if ($fileName -match '^.+ - S\d+E\d+ - .+\.(mkv|mp4|avi|m4v)$') {
                $properlyNamedFiles++
            }
        }

        if ($totalSampled -gt 0 -and $properlyNamedFiles -lt $totalSampled) {
            $issues += "Some episode files may need renaming"
        }
    }

    # Generate recommendations
    if ($isReleaseGroupName) {
        # Try to extract actual show name
        $cleanName = $showName -replace '\.(S\d+|COMPLETE|SERIES).*$', ''
        $cleanName = $cleanName -replace '\.', ' '
        $cleanName = $cleanName -replace '\s+', ' '
        $recommendations += "Extract show name: '$cleanName'"
        $recommendations += "Research correct show name and year"
        $recommendations += "Rename to 'Show Name (Year)' format"
    }

    if (-not $hasYear -and -not $isReleaseGroupName) {
        $recommendations += "Add year tag: '$showName (YYYY)'"
    }

    if ($seasonFolderType -ne "Standard (Season ##)" -and $seasonCount -gt 0) {
        $recommendations += "Rename season folders to 'Season 01', 'Season 02', etc."
        $recommendations += "Move episode files from nested folders to season folders"
    }

    if ($seasonCount -eq 0) {
        $recommendations += "Check if show folder is empty or needs content"
    }

    # Create result object
    $result = [PSCustomObject]@{
        ShowFolder = $showName
        HasYear = $hasYear
        Year = $yearMatch
        IsReleaseGroupName = $isReleaseGroupName
        SeasonFolderType = $seasonFolderType
        SeasonFolderCount = $seasonCount
        EpisodeFileCount = $fileCount
        Issues = ($issues -join "; ")
        Recommendations = ($recommendations -join "; ")
        FullPath = $showPath
    }

    $results += $result

    # Display summary for this show
    if ($issues.Count -gt 0) {
        Write-Host "  Issues: $($issues.Count)" -ForegroundColor Red
    } else {
        Write-Host "  Status: OK" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Analysis Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Display summary statistics
$criticalIssues = ($results | Where-Object { $_.Issues -like "*CRITICAL*" }).Count
$showsWithIssues = ($results | Where-Object { $_.Issues -ne "" }).Count
$showsOK = $results.Count - $showsWithIssues

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Total Shows: $($results.Count)" -ForegroundColor White
Write-Host "  Shows OK: $showsOK" -ForegroundColor Green
Write-Host "  Shows with Issues: $showsWithIssues" -ForegroundColor Yellow
Write-Host "  Critical Issues: $criticalIssues" -ForegroundColor Red
Write-Host ""

# Export to CSV
try {
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
    Write-Host ""

    # Display most common issues
    Write-Host "Most Common Issues:" -ForegroundColor Yellow
    $allIssues = $results | Where-Object { $_.Issues -ne "" } | ForEach-Object { $_.Issues -split "; " }
    $issueGroups = $allIssues | Group-Object | Sort-Object Count -Descending | Select-Object -First 5

    foreach ($issueGroup in $issueGroups) {
        Write-Host "  [$($issueGroup.Count)] $($issueGroup.Name)" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Review the CSV report: $OutputPath" -ForegroundColor White
    Write-Host "  2. Prioritize shows with CRITICAL issues" -ForegroundColor White
    Write-Host "  3. Research correct show names and years for release group folders" -ForegroundColor White
    Write-Host "  4. Run appropriate rename scripts to fix issues" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "ERROR: Failed to export CSV: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Diagnostic complete!" -ForegroundColor Green
