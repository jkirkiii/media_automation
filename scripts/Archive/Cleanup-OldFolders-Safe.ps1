# SAFE Cleanup Script for Old Movie Folders
# Purpose: Remove empty folders and junk files ONLY - NEVER delete video/subtitle files
# Author: Media Library Cleanup (Enhanced for Safety)
# Date: 2025-10-12

#==============================================================================
# CONFIGURATION
#==============================================================================

$MoviesPath = "A:\Media\Movies"
$LogPath = "A:\Media\Logs"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $LogPath "cleanup-safe_$timestamp.log"

# Video file extensions to PROTECT
$VideoExtensions = @(
    "*.mkv", "*.mp4", "*.avi", "*.mov", "*.wmv",
    "*.flv", "*.m4v", "*.mpg", "*.mpeg", "*.webm",
    "*.ogv", "*.3gp", "*.ts", "*.m2ts"
)

# Subtitle file extensions to PROTECT
$SubtitleExtensions = @(
    "*.srt", "*.sub", "*.idx", "*.ass", "*.ssa",
    "*.vtt", "*.smi", "*.txt" # txt can be subs
)

# Junk file patterns to remove (NEVER includes video/subtitle files)
$JunkPatterns = @(
    "*[TGx]*",                    # TorrentGalaxy files
    "*Downloaded from*.txt",      # Torrent site ads
    "*NEW upcoming*.txt",         # Torrent site ads
    "*RARBG*",                    # RARBG files
    "*YTS*",                      # YTS images (but not video files)
    "*.nfo",                      # NFO files
    "*.exe",                      # Executables
    "*.url",                      # Website shortcuts
    "*.log",                      # Log files
    "*.db"                        # Database files
)

# NOTE: We deliberately DON'T include *.jpg, *.png in junk files
# because they might be legitimate poster/fanart for Plex

#==============================================================================
# FUNCTIONS
#==============================================================================

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $logFile -Value $logMessage
}

function Test-ContainsVideoFiles {
    param([string]$Path)

    foreach ($ext in $VideoExtensions) {
        $files = Get-ChildItem -Path $Path -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
        if ($files.Count -gt 0) {
            return $true
        }
    }
    return $false
}

function Test-ContainsSubtitleFiles {
    param([string]$Path)

    foreach ($ext in $SubtitleExtensions) {
        $files = Get-ChildItem -Path $Path -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
        if ($files.Count -gt 0) {
            return $true
        }
    }
    return $false
}

function Get-EmptyFolders {
    param([string]$Path)

    Get-ChildItem -Path $Path -Directory -Recurse | Where-Object {
        $_.GetFiles().Count -eq 0 -and $_.GetDirectories().Count -eq 0
    }
}

function Get-JunkFiles {
    param([string]$Path)

    $junkFiles = @()
    foreach ($pattern in $JunkPatterns) {
        $files = Get-ChildItem -Path $Path -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
        $junkFiles += $files
    }
    return $junkFiles
}

function Show-Statistics {
    param([string]$Path)

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Current Library Statistics" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $allFolders = Get-ChildItem -Path $Path -Directory
    $emptyFolders = Get-EmptyFolders -Path $Path
    $junkFiles = Get-JunkFiles -Path $Path

    $totalSize = ($junkFiles | Measure-Object -Property Length -Sum).Sum / 1MB

    Write-Host "Total movie folders: $($allFolders.Count)" -ForegroundColor White
    Write-Host "Empty folders: $($emptyFolders.Count)" -ForegroundColor Yellow
    Write-Host "Junk files found: $($junkFiles.Count)" -ForegroundColor Yellow
    Write-Host "Junk files size: $([math]::Round($totalSize, 2)) MB" -ForegroundColor Yellow
    Write-Host ""
}

function Remove-EmptyFolders {
    param([string]$Path, [bool]$WhatIf = $true)

    Write-Log "=== Scanning for Empty Folders ===" "Cyan"
    $emptyFolders = Get-EmptyFolders -Path $Path

    if ($emptyFolders.Count -eq 0) {
        Write-Log "No empty folders found!" "Green"
        return
    }

    Write-Log "Found $($emptyFolders.Count) empty folders:" "Yellow"

    foreach ($folder in $emptyFolders) {
        if ($WhatIf) {
            Write-Log "[DRY RUN] Would delete: $($folder.FullName)" "Yellow"
        } else {
            try {
                Remove-Item -Path $folder.FullName -Force -Recurse
                Write-Log "[DELETED] $($folder.FullName)" "Green"
            } catch {
                Write-Log "[ERROR] Failed to delete: $($folder.FullName) - $_" "Red"
            }
        }
    }

    Write-Host ""
}

function Remove-JunkFiles {
    param([string]$Path, [bool]$WhatIf = $true)

    Write-Log "=== Scanning for Junk Files ===" "Cyan"
    $junkFiles = Get-JunkFiles -Path $Path

    if ($junkFiles.Count -eq 0) {
        Write-Log "No junk files found!" "Green"
        return
    }

    $totalSize = ($junkFiles | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Log "Found $($junkFiles.Count) junk files ($([math]::Round($totalSize, 2)) MB):" "Yellow"

    # Group by extension for summary
    $fileGroups = $junkFiles | Group-Object Extension | Sort-Object Count -Descending
    foreach ($group in $fileGroups) {
        Write-Log "  $($group.Name): $($group.Count) files" "White"
    }
    Write-Host ""

    foreach ($file in $junkFiles) {
        if ($WhatIf) {
            Write-Log "[DRY RUN] Would delete: $($file.FullName)" "Yellow"
        } else {
            try {
                Remove-Item -Path $file.FullName -Force
                Write-Log "[DELETED] $($file.FullName)" "Green"
            } catch {
                Write-Log "[ERROR] Failed to delete: $($file.FullName) - $_" "Red"
            }
        }
    }

    Write-Host ""
}

function Find-OldFolders {
    param([string]$Path)

    Write-Log "=== Scanning for Old Naming Convention Folders ===" "Cyan"

    # Pattern for clean Plex format: "Movie Name (Year)"
    $cleanPattern = '^[^.]+\s\(\d{4}\)$'

    $allFolders = Get-ChildItem -Path $Path -Directory
    $oldFoldersEmpty = @()
    $oldFoldersWithMedia = @()
    $duplicateSets = @{}

    foreach ($folder in $allFolders) {
        # Check if folder name doesn't match clean pattern
        if ($folder.Name -notmatch $cleanPattern) {
            # Additional check: if it contains dots, release info, or brackets with quality info
            if ($folder.Name -match '\.' -or
                $folder.Name -match '(720p|1080p|2160p|4K)' -or
                $folder.Name -match '\[.*\]' -or
                $folder.Name -match '(WEBRip|BluRay|WEB-DL|x264|x265|HEVC|AMZN|GalaxyRG)') {

                # SAFETY CHECK: Does it contain video or subtitle files?
                $hasVideo = Test-ContainsVideoFiles -Path $folder.FullName
                $hasSubs = Test-ContainsSubtitleFiles -Path $folder.FullName

                if ($hasVideo -or $hasSubs) {
                    $oldFoldersWithMedia += $folder

                    # Try to extract clean name for duplicate detection
                    $cleanName = $folder.Name -replace '\.(720p|1080p|2160p).*', '' -replace '\.', ' '
                    $cleanName = $cleanName -replace '\s+', ' ' -replace '^\s+|\s+$', ''

                    if (-not $duplicateSets.ContainsKey($cleanName)) {
                        $duplicateSets[$cleanName] = @()
                    }
                    $duplicateSets[$cleanName] += $folder
                } else {
                    $oldFoldersEmpty += $folder
                }
            }
        }
    }

    # Report findings
    if ($oldFoldersEmpty.Count -gt 0) {
        Write-Log "Found $($oldFoldersEmpty.Count) old-style folders SAFE TO DELETE (no media):" "Green"
        foreach ($folder in $oldFoldersEmpty | Sort-Object Name) {
            Write-Log "  [SAFE] $($folder.Name)" "Green"
        }
        Write-Host ""
    }

    if ($oldFoldersWithMedia.Count -gt 0) {
        Write-Log "Found $($oldFoldersWithMedia.Count) old-style folders CONTAINING MEDIA (PROTECTED):" "Red"
        foreach ($folder in $oldFoldersWithMedia | Sort-Object Name) {
            $hasVideo = Test-ContainsVideoFiles -Path $folder.FullName
            $hasSubs = Test-ContainsSubtitleFiles -Path $folder.FullName
            $status = @()
            if ($hasVideo) { $status += "VIDEO" }
            if ($hasSubs) { $status += "SUBS" }
            Write-Log "  [PROTECTED - $($status -join ',')] $($folder.Name)" "Red"
        }
        Write-Host ""
        Write-Log "WARNING: These folders contain media and will NOT be deleted!" "Yellow"
        Write-Log "Run FileBot first to move these files to clean folders." "Yellow"
        Write-Host ""
    }

    # Check for potential duplicates
    $trueDuplicates = $duplicateSets.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
    if ($trueDuplicates) {
        Write-Log "=== POTENTIAL DUPLICATES DETECTED ===" "Magenta"
        foreach ($dup in $trueDuplicates) {
            Write-Log "Movie: $($dup.Key)" "Magenta"
            foreach ($folder in $dup.Value) {
                $hasVideo = Test-ContainsVideoFiles -Path $folder.FullName
                $videoMarker = if ($hasVideo) { "[HAS VIDEO]" } else { "[NO VIDEO]" }
                Write-Log "  $videoMarker $($folder.Name)" "White"
            }
            Write-Host ""
        }
    }

    return @{
        Empty = $oldFoldersEmpty
        WithMedia = $oldFoldersWithMedia
    }
}

function Remove-OldFolders {
    param([string]$Path, [bool]$WhatIf = $true)

    $oldFolders = Find-OldFolders -Path $Path

    if ($oldFolders.Empty.Count -eq 0) {
        Write-Log "No safe-to-delete old folders found!" "Green"
        return
    }

    Write-Log "=== Removing Old Folders (EMPTY ONLY) ===" "Cyan"

    foreach ($folder in $oldFolders.Empty) {
        if ($WhatIf) {
            Write-Log "[DRY RUN] Would delete folder: $($folder.FullName)" "Yellow"
        } else {
            # DOUBLE CHECK before deletion
            $hasVideo = Test-ContainsVideoFiles -Path $folder.FullName
            $hasSubs = Test-ContainsSubtitleFiles -Path $folder.FullName

            if ($hasVideo -or $hasSubs) {
                Write-Log "[PROTECTED] Skipping - found media files: $($folder.FullName)" "Red"
                continue
            }

            try {
                Remove-Item -Path $folder.FullName -Force -Recurse
                Write-Log "[DELETED] $($folder.FullName)" "Green"
            } catch {
                Write-Log "[ERROR] Failed to delete: $($folder.FullName) - $_" "Red"
            }
        }
    }

    if ($oldFolders.WithMedia.Count -gt 0) {
        Write-Host ""
        Write-Log "=== PROTECTED FOLDERS NOT DELETED ===" "Yellow"
        Write-Log "The following $($oldFolders.WithMedia.Count) folders contain media:" "Yellow"
        foreach ($folder in $oldFolders.WithMedia) {
            Write-Log "  $($folder.Name)" "White"
        }
        Write-Log "" "White"
        Write-Log "To clean these, run FileBot rename first!" "Yellow"
    }

    Write-Host ""
}

function Find-DuplicateMovies {
    param([string]$Path)

    Write-Log "=== Scanning for Duplicate Movies ===" "Cyan"

    $allFolders = Get-ChildItem -Path $Path -Directory
    $movieGroups = @{}

    foreach ($folder in $allFolders) {
        # Extract movie name and year
        if ($folder.Name -match '(.+?)\s*\((\d{4})\)') {
            $movieName = $matches[1].Trim()
            $year = $matches[2]
            $key = "$movieName|$year"

            if (-not $movieGroups.ContainsKey($key)) {
                $movieGroups[$key] = @()
            }
            $movieGroups[$key] += $folder
        }
    }

    $duplicates = $movieGroups.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

    if ($duplicates) {
        Write-Log "Found potential duplicates:" "Yellow"
        foreach ($dup in $duplicates) {
            $parts = $dup.Key -split '\|'
            Write-Log "" "White"
            Write-Log "Movie: $($parts[0]) ($($parts[1]))" "Yellow"
            foreach ($folder in $dup.Value) {
                $hasVideo = Test-ContainsVideoFiles -Path $folder.FullName
                $videoMarker = if ($hasVideo) { "[HAS VIDEO]" } else { "[NO VIDEO]" }
                Write-Log "  $videoMarker $($folder.Name)" "White"
            }
        }
    } else {
        Write-Log "No duplicates found!" "Green"
    }

    Write-Host ""
}

#==============================================================================
# MENU SYSTEM
#==============================================================================

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  SAFE Movie Library Cleanup Tool" -ForegroundColor Cyan
    Write-Host "  (Video/Subtitle Protected)" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "SAFE OPTIONS (Preview Only):" -ForegroundColor Green
    Write-Host "  1. Show Statistics" -ForegroundColor White
    Write-Host "  2. Preview - List Empty Folders" -ForegroundColor White
    Write-Host "  3. Preview - List Junk Files" -ForegroundColor White
    Write-Host "  4. Preview - List Old Naming Folders" -ForegroundColor White
    Write-Host "  5. Preview - Find Duplicate Movies" -ForegroundColor White
    Write-Host "  6. Preview - Full Cleanup Report (All Above)" -ForegroundColor White
    Write-Host ""
    Write-Host "CLEANUP OPTIONS (Makes Changes):" -ForegroundColor Red
    Write-Host "  7. Delete Empty Folders ONLY" -ForegroundColor White
    Write-Host "  8. Delete Junk Files ONLY" -ForegroundColor White
    Write-Host "  9. Delete Old Empty Folders (No Media)" -ForegroundColor White
    Write-Host "  10. FULL CLEANUP (All Above - Safe Mode)" -ForegroundColor White
    Write-Host ""
    Write-Host "UTILITIES:" -ForegroundColor Yellow
    Write-Host "  L. View Log File" -ForegroundColor White
    Write-Host "  O. Open Movies Folder" -ForegroundColor White
    Write-Host ""
    Write-Host "  Q. Quit" -ForegroundColor White
    Write-Host ""
}

#==============================================================================
# MAIN SCRIPT
#==============================================================================

# Create log directory if needed
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Verify movies path exists
if (-not (Test-Path $MoviesPath)) {
    Write-Host "ERROR: Movies path not found: $MoviesPath" -ForegroundColor Red
    Write-Host "Please update the `$MoviesPath variable in the script." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Write-Log "=== SAFE Movie Library Cleanup Started ===" "Cyan"
Write-Log "Movies Path: $MoviesPath" "White"
Write-Log "Log File: $logFile" "White"
Write-Log "Video files are PROTECTED from deletion" "Green"
Write-Log "Subtitle files are PROTECTED from deletion" "Green"

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Enter your choice"

    switch ($choice.ToUpper()) {
        "1" {
            Show-Statistics -Path $MoviesPath
            Read-Host "Press Enter to continue"
        }
        "2" {
            Remove-EmptyFolders -Path $MoviesPath -WhatIf $true
            Read-Host "Press Enter to continue"
        }
        "3" {
            Remove-JunkFiles -Path $MoviesPath -WhatIf $true
            Read-Host "Press Enter to continue"
        }
        "4" {
            $oldFolders = Find-OldFolders -Path $MoviesPath
            Read-Host "Press Enter to continue"
        }
        "5" {
            Find-DuplicateMovies -Path $MoviesPath
            Read-Host "Press Enter to continue"
        }
        "6" {
            Write-Host "=== FULL PREVIEW ===" -ForegroundColor Cyan
            Show-Statistics -Path $MoviesPath
            Remove-EmptyFolders -Path $MoviesPath -WhatIf $true
            Remove-JunkFiles -Path $MoviesPath -WhatIf $true
            Find-OldFolders -Path $MoviesPath | Out-Null
            Find-DuplicateMovies -Path $MoviesPath
            Read-Host "Press Enter to continue"
        }
        "7" {
            $confirm = Read-Host "Delete all empty folders? (yes/no)"
            if ($confirm -eq "yes") {
                Remove-EmptyFolders -Path $MoviesPath -WhatIf $false
                Write-Host "Empty folders deleted!" -ForegroundColor Green
            }
            Read-Host "Press Enter to continue"
        }
        "8" {
            $confirm = Read-Host "Delete all junk files? (yes/no)"
            if ($confirm -eq "yes") {
                Remove-JunkFiles -Path $MoviesPath -WhatIf $false
                Write-Host "Junk files deleted!" -ForegroundColor Green
            }
            Read-Host "Press Enter to continue"
        }
        "9" {
            Write-Host ""
            Write-Host "This will ONLY delete old-style folders with NO video/subtitle files." -ForegroundColor Yellow
            Write-Host "Folders with media are automatically protected." -ForegroundColor Green
            Write-Host ""
            $confirm = Read-Host "Delete safe old folders? (yes/no)"
            if ($confirm -eq "yes") {
                Remove-OldFolders -Path $MoviesPath -WhatIf $false
                Write-Host "Safe cleanup complete!" -ForegroundColor Green
            }
            Read-Host "Press Enter to continue"
        }
        "10" {
            Write-Host ""
            Write-Host "=== FULL SAFE CLEANUP ===" -ForegroundColor Green
            Write-Host "This will delete:" -ForegroundColor Yellow
            Write-Host "  - Empty folders" -ForegroundColor White
            Write-Host "  - Junk files (txt, nfo, exe, etc.)" -ForegroundColor White
            Write-Host "  - Old naming folders WITHOUT video/subs" -ForegroundColor White
            Write-Host ""
            Write-Host "This will NOT delete:" -ForegroundColor Green
            Write-Host "  - Any folder with video files" -ForegroundColor White
            Write-Host "  - Any folder with subtitle files" -ForegroundColor White
            Write-Host ""
            $confirm = Read-Host "Proceed with SAFE cleanup? (yes/no)"
            if ($confirm -eq "yes") {
                Remove-JunkFiles -Path $MoviesPath -WhatIf $false
                Remove-OldFolders -Path $MoviesPath -WhatIf $false
                Remove-EmptyFolders -Path $MoviesPath -WhatIf $false
                Write-Host ""
                Write-Host "=== CLEANUP COMPLETE ===" -ForegroundColor Green
                Show-Statistics -Path $MoviesPath
            }
            Read-Host "Press Enter to continue"
        }
        "L" {
            if (Test-Path $logFile) {
                Get-Content $logFile | Out-Host
            } else {
                Write-Host "Log file not found yet." -ForegroundColor Yellow
            }
            Read-Host "Press Enter to continue"
        }
        "O" {
            Start-Process $MoviesPath
        }
        "Q" {
            Write-Log "=== Cleanup Session Ended ===" "Cyan"
            Write-Host "Exiting..." -ForegroundColor Green
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($choice.ToUpper() -ne "Q")

Write-Host ""
Write-Host "Log saved to: $logFile" -ForegroundColor Green
