# Rename-TVShows-PlexStandard.ps1
# Comprehensive TV show renaming script for Plex/Sonarr/Radarr compliance
# Renames show folders, season folders, and episode files to standard format

param(
    [string]$TVShowsPath = "A:\Media\TV Shows",
    [string]$YearMappingFile = ".\tv_show_years.csv",
    [switch]$DryRun = $false,
    [string]$LogFile = ".\tv_rename_log.txt"
)

# Initialize
$ErrorActionPreference = "Stop"
$script:changeCount = 0
$script:errorCount = 0
$script:logEntries = @()

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "CHANGE" { "Cyan" }
        default { "White" }
    }

    Write-Host $logMessage -ForegroundColor $color
    $script:logEntries += $logMessage
}

function Get-SafeFileName {
    param([string]$Name)

    # Remove illegal characters for Windows filenames
    $illegal = '[<>:"/\\|?*]'
    $safe = $Name -replace $illegal, ''

    # Remove trailing periods and spaces
    $safe = $safe.TrimEnd('. ')

    return $safe
}

function Extract-SeasonNumber {
    param([string]$FolderName)

    # Try to extract season number from various formats
    if ($FolderName -match '\.S(\d+)[\.\s]') {
        return [int]$matches[1]
    }
    elseif ($FolderName -match 'Season[.\s]+(\d+)') {
        return [int]$matches[1]
    }
    elseif ($FolderName -match '\((\d{4})\)\s*S(\d+)') {
        return [int]$matches[2]
    }

    return $null
}

function Extract-EpisodeInfo {
    param([string]$FileName)

    # Extract S##E## pattern
    if ($FileName -match 'S(\d+)E(\d+)') {
        return @{
            Season = [int]$matches[1]
            Episode = [int]$matches[2]
            FullMatch = $matches[0]
        }
    }

    return $null
}

function Get-EpisodeTitle {
    param([string]$FileName)

    # Try to extract episode title
    # Format 1: Show Name - S01E01 - Episode Title.ext
    if ($FileName -match ' - S\d+E\d+ - (.+)\.\w+$') {
        return $matches[1]
    }

    # Format 2: Show.Name.S01E01.Episode.Title.ext
    if ($FileName -match 'S\d+E\d+\.(.+)\.\w+$') {
        $title = $matches[1]
        $title = $title -replace '\.', ' '
        $title = $title -replace '\s+', ' '
        return $title.Trim()
    }

    # Format 3: Already has a title after episode number
    if ($FileName -match 'S\d+E\d+\s*-\s*(.+)\.\w+$') {
        return $matches[1]
    }

    return "Episode"
}

function Rename-ItemSafe {
    param(
        [string]$Path,
        [string]$NewName,
        [switch]$IsDirectory = $false
    )

    try {
        $item = Get-Item $Path -ErrorAction Stop

        if ($null -eq $item) {
            Write-Log "  ERROR: Item not found: $Path" "ERROR"
            $script:errorCount++
            return $false
        }

        $parent = Split-Path $item.FullName -Parent
        $newPath = Join-Path $parent $NewName

        if ($item.FullName -eq $newPath) {
            Write-Log "  Skipping: Already named correctly" "INFO"
            return $true
        }

        if (Test-Path $newPath) {
            Write-Log "  ERROR: Target already exists: $newPath" "ERROR"
            $script:errorCount++
            return $false
        }

        if ($DryRun) {
            Write-Log "  [DRY RUN] Would rename:" "CHANGE"
            Write-Log "    FROM: $($item.FullName)" "CHANGE"
            Write-Log "    TO:   $newPath" "CHANGE"
            $script:changeCount++
            return $true
        } else {
            try {
                Rename-Item -Path $item.FullName -NewName $NewName -Force
                Write-Log "  Renamed successfully" "SUCCESS"
                $script:changeCount++
                return $true
            } catch {
                Write-Log "  ERROR: Failed to rename: $_" "ERROR"
                $script:errorCount++
                return $false
            }
        }
    } catch {
        Write-Log "  ERROR in Rename-ItemSafe: $_" "ERROR"
        $script:errorCount++
        return $false
    }
}

function Move-ItemSafe {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )

    if (-not (Test-Path $SourcePath)) {
        Write-Log "  ERROR: Source not found: $SourcePath" "ERROR"
        return $false
    }

    if (Test-Path $DestinationPath) {
        Write-Log "  WARN: Destination already exists: $DestinationPath" "WARN"
        return $false
    }

    if ($DryRun) {
        Write-Log "  [DRY RUN] Would move:" "CHANGE"
        Write-Log "    FROM: $SourcePath" "CHANGE"
        Write-Log "    TO:   $DestinationPath" "CHANGE"
        $script:changeCount++
        return $true
    } else {
        try {
            Move-Item -Path $SourcePath -Destination $DestinationPath -Force
            Write-Log "  Moved successfully" "SUCCESS"
            $script:changeCount++
            return $true
        } catch {
            Write-Log "  ERROR: Failed to move: $_" "ERROR"
            $script:errorCount++
            return $false
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TV Shows Plex Standard Rename Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "*** DRY RUN MODE - NO CHANGES WILL BE MADE ***" -ForegroundColor Yellow
    Write-Host ""
}

# Load year mapping
Write-Log "Loading year mapping from: $YearMappingFile"

if (-not (Test-Path $YearMappingFile)) {
    Write-Log "ERROR: Year mapping file not found: $YearMappingFile" "ERROR"
    exit 1
}

$yearMapping = @{}
$mappingData = Import-Csv $YearMappingFile

foreach ($row in $mappingData) {
    $yearMapping[$row.ShowFolder] = @{
        CorrectName = $row.CorrectName
        Year = $row.Year
    }
}

Write-Log "Loaded $($yearMapping.Count) show mappings"
Write-Log ""

# Get all show folders
$showFolders = Get-ChildItem -Path $TVShowsPath -Directory | Sort-Object Name

Write-Log "Found $($showFolders.Count) show folders to process"
Write-Log ""

$processedCount = 0

foreach ($showFolder in $showFolders) {
    $processedCount++
    Write-Log "========================================" "INFO"
    Write-Log "Processing [$processedCount/$($showFolders.Count)]: $($showFolder.Name)" "INFO"
    Write-Log "========================================" "INFO"

    $currentShowName = $showFolder.Name
    $currentShowPath = $showFolder.FullName

    # Get correct name and year from mapping
    if (-not $yearMapping.ContainsKey($currentShowName)) {
        Write-Log "WARN: No mapping found for '$currentShowName', skipping" "WARN"
        Write-Log ""
        continue
    }

    $mapping = $yearMapping[$currentShowName]
    $correctName = Get-SafeFileName $mapping.CorrectName
    $year = $mapping.Year
    $newShowName = "$correctName ($year)"
    $newShowPath = Join-Path (Split-Path $currentShowPath -Parent) $newShowName

    Write-Log "Target show name: $newShowName"

    # Step 1: Rename show folder if needed
    if ($currentShowName -ne $newShowName) {
        Write-Log "Step 1: Renaming show folder"

        if (-not (Rename-ItemSafe -Path $currentShowPath -NewName $newShowName -IsDirectory)) {
            Write-Log "Skipping this show due to error" "ERROR"
            Write-Log ""
            continue
        }

        # Update path reference (only in non-dry-run mode)
        if (-not $DryRun) {
            $currentShowPath = $newShowPath
        }
    } else {
        Write-Log "Step 1: Show folder already correctly named"
    }

    # Step 2: Process season folders
    Write-Log "Step 2: Processing season folders"

    $seasonFolders = Get-ChildItem -Path $currentShowPath -Directory -ErrorAction SilentlyContinue

    if ($seasonFolders.Count -eq 0) {
        Write-Log "  No season folders found (empty show folder)"
        Write-Log ""
        continue
    }

    foreach ($seasonFolder in $seasonFolders) {
        $seasonName = $seasonFolder.Name
        $seasonPath = $seasonFolder.FullName

        Write-Log "  Processing season folder: $seasonName"

        # Extract season number
        $seasonNum = Extract-SeasonNumber -FolderName $seasonName

        if ($null -eq $seasonNum) {
            Write-Log "    WARN: Could not extract season number from '$seasonName'" "WARN"
            continue
        }

        $standardSeasonName = "Season {0:D2}" -f $seasonNum
        Write-Log "    Detected as: $standardSeasonName"

        # Check if season folder is already in standard format
        if ($seasonName -eq $standardSeasonName) {
            Write-Log "    Already in standard format"

            # Process files in this folder
            $episodeFiles = Get-ChildItem -Path $seasonPath -File -Recurse |
                           Where-Object { $_.Extension -match '\.(mkv|mp4|avi|m4v)$' }

            foreach ($episodeFile in $episodeFiles) {
                $fileName = $episodeFile.Name
                $filePath = $episodeFile.FullName

                # Extract episode info
                $epInfo = Extract-EpisodeInfo -FileName $fileName

                if ($null -eq $epInfo) {
                    Write-Log "      WARN: Could not extract episode info from '$fileName'" "WARN"
                    continue
                }

                # Check if already in correct format
                $expectedFormat = "^$correctName - S\d+E\d+ - .+\.\w+$"
                if ($fileName -match $expectedFormat) {
                    Write-Log "      File already in standard format: $fileName"
                    continue
                }

                # Build new filename
                $epTitle = Get-EpisodeTitle -FileName $fileName
                $extension = $episodeFile.Extension
                $newFileName = "$correctName - S{0:D2}E{1:D2} - {2}$extension" -f $epInfo.Season, $epInfo.Episode, $epTitle
                $newFileName = Get-SafeFileName $newFileName

                Write-Log "      Renaming episode file:"
                Rename-ItemSafe -Path $filePath -NewName $newFileName
            }

        } else {
            # Season folder needs to be renamed
            $newSeasonPath = Join-Path $currentShowPath $standardSeasonName

            # Create new season folder if it doesn't exist
            if (-not (Test-Path $newSeasonPath)) {
                Write-Log "    Creating standard season folder: $standardSeasonName"

                if (-not $DryRun) {
                    try {
                        New-Item -Path $newSeasonPath -ItemType Directory -Force | Out-Null
                        Write-Log "    Created successfully" "SUCCESS"
                    } catch {
                        Write-Log "    ERROR: Failed to create folder: $_" "ERROR"
                        continue
                    }
                } else {
                    Write-Log "    [DRY RUN] Would create: $newSeasonPath" "CHANGE"
                }
            }

            # Move episode files from old season folder to new season folder
            $episodeFiles = Get-ChildItem -Path $seasonPath -File -Recurse |
                           Where-Object { $_.Extension -match '\.(mkv|mp4|avi|m4v)$' }

            Write-Log "    Found $($episodeFiles.Count) episode file(s) to process"

            foreach ($episodeFile in $episodeFiles) {
                $fileName = $episodeFile.Name
                $filePath = $episodeFile.FullName

                # Extract episode info
                $epInfo = Extract-EpisodeInfo -FileName $fileName

                if ($null -eq $epInfo) {
                    Write-Log "      WARN: Could not extract episode info from '$fileName'" "WARN"
                    continue
                }

                # Build new filename
                $epTitle = Get-EpisodeTitle -FileName $fileName
                $extension = $episodeFile.Extension
                $newFileName = "$correctName - S{0:D2}E{1:D2} - {2}$extension" -f $epInfo.Season, $epInfo.Episode, $epTitle
                $newFileName = Get-SafeFileName $newFileName
                $newFilePath = Join-Path $newSeasonPath $newFileName

                Write-Log "      Processing: $fileName"
                Move-ItemSafe -SourcePath $filePath -DestinationPath $newFilePath
            }

            # Remove old season folder if it's now empty (and not dry run)
            if (-not $DryRun) {
                $remainingItems = Get-ChildItem -Path $seasonPath -Recurse -Force
                if ($remainingItems.Count -eq 0) {
                    try {
                        Remove-Item -Path $seasonPath -Recurse -Force
                        Write-Log "    Removed empty old season folder" "SUCCESS"
                    } catch {
                        Write-Log "    WARN: Could not remove old folder: $_" "WARN"
                    }
                }
            }
        }
    }

    Write-Log ""
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Processing Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Summary:"
Write-Log "  Shows processed: $processedCount"
Write-Log "  Changes made: $script:changeCount"
Write-Log "  Errors encountered: $script:errorCount"

if ($DryRun) {
    Write-Log ""
    Write-Log "This was a DRY RUN - no actual changes were made" "WARN"
    Write-Log "Review the log above and run without -DryRun to apply changes" "WARN"
}

# Save log to file
Write-Log ""
Write-Log "Saving log to: $LogFile"

try {
    $script:logEntries | Out-File -FilePath $LogFile -Encoding UTF8
    Write-Log "Log saved successfully" "SUCCESS"
} catch {
    Write-Log "ERROR: Failed to save log: $_" "ERROR"
}

Write-Host ""
