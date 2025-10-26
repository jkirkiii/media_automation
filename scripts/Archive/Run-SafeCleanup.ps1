# Safe Cleanup Execution - Non-Interactive
# Removes empty folders and junk files only - protects video/subtitle files
# Date: 2025-10-12

$MoviesPath = "A:\Media\Movies"
$LogPath = "A:\Media\Logs"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $LogPath "safe-cleanup_$timestamp.log"

# Create log directory if needed
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Video file extensions to PROTECT
$VideoExtensions = @("*.mkv", "*.mp4", "*.avi", "*.mov", "*.wmv", "*.flv", "*.m4v", "*.mpg", "*.mpeg", "*.webm")

# Subtitle file extensions to PROTECT
$SubtitleExtensions = @("*.srt", "*.sub", "*.idx", "*.ass", "*.ssa", "*.vtt")

# Junk file patterns to remove
$JunkPatterns = @(
    "*[TGx]*",
    "*Downloaded from*.txt",
    "*NEW upcoming*.txt",
    "*RARBG*",
    "*.nfo",
    "*.exe",
    "*.url"
)

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
        if (Get-ChildItem -Path $Path -Filter $ext -Recurse -File -ErrorAction SilentlyContinue) {
            return $true
        }
    }
    return $false
}

function Test-ContainsSubtitleFiles {
    param([string]$Path)
    foreach ($ext in $SubtitleExtensions) {
        if (Get-ChildItem -Path $Path -Filter $ext -Recurse -File -ErrorAction SilentlyContinue) {
            return $true
        }
    }
    return $false
}

Write-Log "=== SAFE CLEANUP STARTED ===" "Cyan"
Write-Log "Movies Path: $MoviesPath" "White"
Write-Log "Log File: $logFile" "White"
Write-Host ""

#==============================================================================
# STEP 1: Remove Junk Files
#==============================================================================

Write-Log "=== STEP 1: Removing Junk Files ===" "Cyan"
$junkFiles = @()
foreach ($pattern in $JunkPatterns) {
    $junkFiles += Get-ChildItem -Path $MoviesPath -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
}

if ($junkFiles.Count -gt 0) {
    Write-Log "Found $($junkFiles.Count) junk files to delete" "Yellow"

    $deletedCount = 0
    $failedCount = 0

    foreach ($file in $junkFiles) {
        try {
            Remove-Item -Path $file.FullName -Force
            $deletedCount++
            Write-Log "[DELETED] $($file.FullName)" "Green"
        } catch {
            $failedCount++
            Write-Log "[ERROR] Failed to delete: $($file.FullName) - $_" "Red"
        }
    }

    Write-Log "Junk files deleted: $deletedCount" "Green"
    if ($failedCount -gt 0) {
        Write-Log "Failed to delete: $failedCount" "Red"
    }
} else {
    Write-Log "No junk files found" "Green"
}
Write-Host ""

#==============================================================================
# STEP 2: Remove Old Empty Folders
#==============================================================================

Write-Log "=== STEP 2: Removing Old Empty Folders ===" "Cyan"

$allFolders = Get-ChildItem -Path $MoviesPath -Directory
$cleanPattern = '^[^.]+\s\(\d{4}\)$'
$oldFoldersToDelete = @()

foreach ($folder in $allFolders) {
    # Check if folder name doesn't match clean pattern
    if ($folder.Name -notmatch $cleanPattern) {
        # Check if it looks like old torrent-style naming
        if ($folder.Name -match '\.' -or
            $folder.Name -match '(720p|1080p|2160p)' -or
            $folder.Name -match '\[.*\]' -or
            $folder.Name -match '(WEBRip|BluRay|x264|x265|HEVC|GalaxyRG)') {

            # SAFETY CHECK: Does it contain video or subtitle files?
            $hasVideo = Test-ContainsVideoFiles -Path $folder.FullName
            $hasSubs = Test-ContainsSubtitleFiles -Path $folder.FullName

            if (-not $hasVideo -and -not $hasSubs) {
                $oldFoldersToDelete += $folder
            } else {
                Write-Log "[PROTECTED] Skipping (has media): $($folder.Name)" "Yellow"
            }
        }
    }
}

if ($oldFoldersToDelete.Count -gt 0) {
    Write-Log "Found $($oldFoldersToDelete.Count) old folders to delete (no media files)" "Yellow"

    $deletedCount = 0
    $failedCount = 0

    foreach ($folder in $oldFoldersToDelete) {
        # DOUBLE CHECK before deletion
        $hasVideo = Test-ContainsVideoFiles -Path $folder.FullName
        $hasSubs = Test-ContainsSubtitleFiles -Path $folder.FullName

        if ($hasVideo -or $hasSubs) {
            Write-Log "[PROTECTED] Skipping - found media files: $($folder.FullName)" "Red"
            continue
        }

        try {
            Remove-Item -Path $folder.FullName -Force -Recurse
            $deletedCount++
            Write-Log "[DELETED] $($folder.Name)" "Green"
        } catch {
            $failedCount++
            Write-Log "[ERROR] Failed to delete: $($folder.FullName) - $_" "Red"
        }
    }

    Write-Log "Old folders deleted: $deletedCount" "Green"
    if ($failedCount -gt 0) {
        Write-Log "Failed to delete: $failedCount" "Red"
    }
} else {
    Write-Log "No old folders to delete" "Green"
}
Write-Host ""

#==============================================================================
# STEP 3: Remove Empty Folders (recursive cleanup)
#==============================================================================

Write-Log "=== STEP 3: Removing Empty Folders ===" "Cyan"

$emptyFolders = Get-ChildItem -Path $MoviesPath -Directory -Recurse | Where-Object {
    $_.GetFiles().Count -eq 0 -and $_.GetDirectories().Count -eq 0
}

if ($emptyFolders.Count -gt 0) {
    Write-Log "Found $($emptyFolders.Count) empty folders" "Yellow"

    $deletedCount = 0
    $failedCount = 0

    foreach ($folder in $emptyFolders) {
        try {
            Remove-Item -Path $folder.FullName -Force -Recurse
            $deletedCount++
            Write-Log "[DELETED] $($folder.FullName)" "Green"
        } catch {
            $failedCount++
            Write-Log "[ERROR] Failed to delete: $($folder.FullName) - $_" "Red"
        }
    }

    Write-Log "Empty folders deleted: $deletedCount" "Green"
    if ($failedCount -gt 0) {
        Write-Log "Failed to delete: $failedCount" "Red"
    }
} else {
    Write-Log "No empty folders found" "Green"
}
Write-Host ""

#==============================================================================
# SUMMARY
#==============================================================================

Write-Log "=== CLEANUP COMPLETE ===" "Green"
Write-Host ""
Write-Log "Final Statistics:" "Cyan"

$finalFolders = Get-ChildItem -Path $MoviesPath -Directory
Write-Log "Total movie folders remaining: $($finalFolders.Count)" "White"

# Count clean vs old folders
$cleanFolders = $finalFolders | Where-Object { $_.Name -match $cleanPattern }
$oldFolders = $finalFolders | Where-Object { $_.Name -notmatch $cleanPattern }

Write-Log "  - Clean Plex format: $($cleanFolders.Count)" "Green"
if ($oldFolders.Count -gt 0) {
    Write-Log "  - Still needs attention: $($oldFolders.Count)" "Yellow"
}

Write-Host ""
Write-Log "Log saved to: $logFile" "Cyan"
Write-Host ""
