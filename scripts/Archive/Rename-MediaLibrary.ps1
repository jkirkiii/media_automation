# FileBot Rename Script for Plex Media Library
# Author: Media Library Standardization
# Date: 2025-10-08
# Purpose: Rename movies and TV shows to Plex/Radarr/Sonarr standards

#==============================================================================
# CONFIGURATION
#==============================================================================

# Paths
$FileBot = "C:\Program Files\FileBot\filebot.exe"
$MoviesPath = "A:\Media\Movies"
$TVShowsPath = "A:\Media\TV Shows"  # Update if different
$TestPath = "A:\Media\TEST_RENAME"
$LogPath = "A:\Media\Logs"

# Output paths (where files will be organized)
$MoviesOutput = "A:\Media\Movies"
$TVShowsOutput = "A:\Media\TV Shows"
$TestOutput = "A:\Media\TEST_RENAME"

# Create log directory if it doesn't exist
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Timestamp for log files
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

#==============================================================================
# FUNCTIONS
#==============================================================================

function Run-FileBot-Test {
    param(
        [string]$Path,
        [string]$OutputPath,
        [string]$Type,  # "movies" or "tv"
        [string]$LogFile
    )
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "DRY RUN - Testing $Type Rename" -ForegroundColor Cyan
    Write-Host "Input:  $Path" -ForegroundColor Cyan
    Write-Host "Output: $OutputPath" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Type -eq "movies") {
        $format = "{n} ({y})/{n} ({y}) [{vf}]"
        $db = "TheMovieDB"
    } else {
        $format = "{n}/Season {s00}/{n} - {s00e00} - {t} [{vf}]"
        $db = "TheTVDB"
    }
    
    Write-Host "Format: $format" -ForegroundColor Yellow
    Write-Host ""
    
    & $FileBot `
        -rename $Path `
        -r `
        --output $OutputPath `
        --db $db `
        --format $format `
        --action TEST `
        --conflict auto `
        -non-strict `
        --log-file $LogFile
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Dry run complete! Review the output above." -ForegroundColor Green
    Write-Host "Log saved to: $LogFile" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
}

function Run-FileBot-Rename {
    param(
        [string]$Path,
        [string]$OutputPath,
        [string]$Type,  # "movies" or "tv"
        [string]$LogFile
    )
    
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "PRODUCTION RUN - Renaming $Type" -ForegroundColor Red
    Write-Host "Input:  $Path" -ForegroundColor Red
    Write-Host "Output: $OutputPath" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    
    if ($Type -eq "movies") {
        $format = "{n} ({y})/{n} ({y}) [{vf}]"
        $db = "TheMovieDB"
    } else {
        $format = "{n}/Season {s00}/{n} - {s00e00} - {t} [{vf}]"
        $db = "TheTVDB"
    }
    
    Write-Host "Format: $format" -ForegroundColor Yellow
    Write-Host ""
    
    # Ask for confirmation
    $confirmation = Read-Host "Are you sure you want to rename files at $Path? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }
    
    & $FileBot `
        -rename $Path `
        -r `
        --output $OutputPath `
        --db $db `
        --format $format `
        --action MOVE `
        --conflict auto `
        -non-strict `
        --log-file $LogFile
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Rename complete!" -ForegroundColor Green
    Write-Host "Log saved to: $LogFile" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
}

#==============================================================================
# MENU SYSTEM
#==============================================================================

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  FileBot Media Library Renamer" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "TEST RUNS (Safe - No Changes Made):" -ForegroundColor Green
    Write-Host "  1. Test Movies (TEST_RENAME folder)" -ForegroundColor White
    Write-Host "  2. Test TV Shows (TEST_RENAME folder)" -ForegroundColor White
    Write-Host "  3. Test Movies (Full Library)" -ForegroundColor White
    Write-Host "  4. Test TV Shows (Full Library)" -ForegroundColor White
    Write-Host ""
    Write-Host "PRODUCTION RUNS (Makes Changes):" -ForegroundColor Red
    Write-Host "  5. Rename Movies (Full Library)" -ForegroundColor White
    Write-Host "  6. Rename TV Shows (Full Library)" -ForegroundColor White
    Write-Host ""
    Write-Host "UTILITIES:" -ForegroundColor Yellow
    Write-Host "  7. View Last Log File" -ForegroundColor White
    Write-Host "  8. Open Log Folder" -ForegroundColor White
    Write-Host ""
    Write-Host "  Q. Quit" -ForegroundColor White
    Write-Host ""
}

#==============================================================================
# MAIN SCRIPT
#==============================================================================

# Check if FileBot exists
if (-not (Test-Path $FileBot)) {
    Write-Host "ERROR: FileBot not found at $FileBot" -ForegroundColor Red
    Write-Host "Please install FileBot or update the path in this script." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Enter your choice"
    
    switch ($choice) {
        "1" {
            $logFile = Join-Path $LogPath "test-movies-sample_$timestamp.log"
            Run-FileBot-Test -Path $TestPath -OutputPath $TestOutput -Type "movies" -LogFile $logFile
            Read-Host "Press Enter to continue"
        }
        "2" {
            $logFile = Join-Path $LogPath "test-tv-sample_$timestamp.log"
            Run-FileBot-Test -Path $TestPath -OutputPath $TestOutput -Type "tv" -LogFile $logFile
            Read-Host "Press Enter to continue"
        }
        "3" {
            $logFile = Join-Path $LogPath "test-movies-full_$timestamp.log"
            Run-FileBot-Test -Path $MoviesPath -OutputPath $MoviesOutput -Type "movies" -LogFile $logFile
            Read-Host "Press Enter to continue"
        }
        "4" {
            $logFile = Join-Path $LogPath "test-tv-full_$timestamp.log"
            Run-FileBot-Test -Path $TVShowsPath -OutputPath $TVShowsOutput -Type "tv" -LogFile $logFile
            Read-Host "Press Enter to continue"
        }
        "5" {
            $logFile = Join-Path $LogPath "rename-movies_$timestamp.log"
            Run-FileBot-Rename -Path $MoviesPath -OutputPath $MoviesOutput -Type "movies" -LogFile $logFile
            Read-Host "Press Enter to continue"
        }
        "6" {
            $logFile = Join-Path $LogPath "rename-tv_$timestamp.log"
            Run-FileBot-Rename -Path $TVShowsPath -OutputPath $TVShowsOutput -Type "tv" -LogFile $logFile
            Read-Host "Press Enter to continue"
        }
        "7" {
            $latestLog = Get-ChildItem $LogPath -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($latestLog) {
                Get-Content $latestLog.FullName | Out-Host
            } else {
                Write-Host "No log files found." -ForegroundColor Yellow
            }
            Read-Host "Press Enter to continue"
        }
        "8" {
            Start-Process $LogPath
        }
        "Q" {
            Write-Host "Exiting..." -ForegroundColor Green
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($choice -ne "Q")