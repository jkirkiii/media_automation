# Cleanup Script for Old Movie Folders
# Purpose: Remove empty folders and junk files after FileBot rename
# Author: Media Library Cleanup
# Date: 2025-10-08

#==============================================================================
# CONFIGURATION
#==============================================================================

$MoviesPath = "A:\Media\Movies"
$LogPath = "A:\Media\Logs"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $LogPath "cleanup_$timestamp.log"

# Junk file patterns to remove
$JunkPatterns = @(
    "*.txt",           # Readme, torrent info files
    "*.nfo",           # NFO files
    "*.jpg",           # Torrent site images
    "*.png",           # Torrent site images
    "*.exe",           # Suspicious executables
    "*.url",           # Website shortcuts
    "*RARBG*",         # RARBG files
    "*TGx*",           # TorrentGalaxy files
    "*YTS*",           # YTS images
    "*.log",           # Old log files
    "*.db"             # Database files
)

# Junk folder patterns to check
$JunkFolderNames = @(
    "Subs",            # Old subtitle folders (if empty)
    "Sample",          # Sample video folders
    "Samples",
    "Trailers",        # Trailer folders (optional - remove if you don't want them)
    "Other",           # Misc folders
    "Screenshots"
)

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
        $junkFiles += Get-ChildItem -Path $Path -Filter $pattern -Recurse -File
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
    $oldFolders = @()
    
    foreach ($folder in $allFolders) {
        # Check if folder name doesn't match clean pattern
        if ($folder.Name -notmatch $cleanPattern) {
            # Additional check: if it contains dots, release info, or brackets with quality info
            if ($folder.Name -match '\.' -or 
                $folder.Name -match '(720p|1080p|2160p|4K)' -or 
                $folder.Name -match '\[.*\]' -or
                $folder.Name -match '(WEBRip|BluRay|WEB-DL|x264|x265|HEVC)') {
                
                $oldFolders += $folder
            }
        }
    }
    
    if ($oldFolders.Count -eq 0) {
        Write-Log "No old-style folders found! Library is clean!" "Green"
        return @()
    }
    
    Write-Log "Found $($oldFolders.Count) folders with old naming:" "Yellow"
    foreach ($folder in $oldFolders | Sort-Object Name) {
        Write-Log "  - $($folder.Name)" "White"
    }
    Write-Host ""
    
    return $oldFolders
}

function Remove-OldFolders {
    param([string]$Path, [bool]$WhatIf = $true)
    
    $oldFolders = Find-OldFolders -Path $Path
    
    if ($oldFolders.Count -eq 0) {
        return
    }
    
    foreach ($folder in $oldFolders) {
        if ($WhatIf) {
            Write-Log "[DRY RUN] Would delete folder: $($folder.FullName)" "Yellow"
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

#==============================================================================
# MENU SYSTEM
#==============================================================================

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Movie Library Cleanup Tool" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "SAFE OPTIONS (Preview Only):" -ForegroundColor Green
    Write-Host "  1. Show Statistics" -ForegroundColor White
    Write-Host "  2. Preview - List Empty Folders" -ForegroundColor White
    Write-Host "  3. Preview - List Junk Files" -ForegroundColor White
    Write-Host "  4. Preview - List Old Naming Folders" -ForegroundColor White
    Write-Host "  5. Preview - Full Cleanup (All Above)" -ForegroundColor White
    Write-Host ""
    Write-Host "CLEANUP OPTIONS (Makes Changes):" -ForegroundColor Red
    Write-Host "  6. Delete Empty Folders" -ForegroundColor White
    Write-Host "  7. Delete Junk Files" -ForegroundColor White
    Write-Host "  8. Delete Old Naming Folders" -ForegroundColor White
    Write-Host "  9. FULL CLEANUP (All Above)" -ForegroundColor White
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

Write-Log "=== Movie Library Cleanup Started ===" "Cyan"
Write-Log "Movies Path: $MoviesPath" "White"
Write-Log "Log File: $logFile" "White"

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
            Write-Host "=== FULL PREVIEW ===" -ForegroundColor Cyan
            Show-Statistics -Path $MoviesPath
            Remove-EmptyFolders -Path $MoviesPath -WhatIf $true
            Remove-JunkFiles -Path $MoviesPath -WhatIf $true
            Remove-OldFolders -Path $MoviesPath -WhatIf $true
            Read-Host "Press Enter to continue"
        }
        "6" {
            $confirm = Read-Host "Delete all empty folders? (yes/no)"
            if ($confirm -eq "yes") {
                Remove-EmptyFolders -Path $MoviesPath -WhatIf $false
                Write-Host "Empty folders deleted!" -ForegroundColor Green
            }
            Read-Host "Press Enter to continue"
        }
        "7" {
            $confirm = Read-Host "Delete all junk files? (yes/no)"
            if ($confirm -eq "yes") {
                Remove-JunkFiles -Path $MoviesPath -WhatIf $false
                Write-Host "Junk files deleted!" -ForegroundColor Green
            }
            Read-Host "Press Enter to continue"
        }
        "8" {
            Write-Host ""
            Write-Host "WARNING: This will delete folders with old naming conventions!" -ForegroundColor Red
            Write-Host "Make sure FileBot successfully moved all your movies first!" -ForegroundColor Red
            Write-Host ""
            $confirm = Read-Host "Delete old naming folders? (yes/no)"
            if ($confirm -eq "yes") {
                Remove-OldFolders -Path $MoviesPath -WhatIf $false
                Write-Host "Old folders deleted!" -ForegroundColor Green
            }
            Read-Host "Press Enter to continue"
        }
        "9" {
            Write-Host ""
            Write-Host "=== FULL CLEANUP ===" -ForegroundColor Red
            Write-Host "This will delete:" -ForegroundColor Yellow
            Write-Host "  - Empty folders" -ForegroundColor White
            Write-Host "  - Junk files (txt, nfo, jpg, exe, etc.)" -ForegroundColor White
            Write-Host "  - Old naming convention folders" -ForegroundColor White
            Write-Host ""
            $confirm = Read-Host "Proceed with FULL cleanup? (yes/no)"
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