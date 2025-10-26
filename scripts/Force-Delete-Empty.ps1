# Force Delete Empty Folders - Using CMD rmdir
# Run as Administrator
# Uses native Windows rmdir which is more aggressive than PowerShell Remove-Item

$MoviesPath = "A:\Media\Movies"
$LogPath = "A:\Media\Logs"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $LogPath "force-delete_$timestamp.log"

if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "=== FORCE DELETE CLEANUP STARTED ===" "Cyan"
Write-Log "Using CMD rmdir for more aggressive deletion" "Yellow"
Write-Host ""

# Step 1: Delete junk files first using del command
Write-Log "=== STEP 1: Force Delete Junk Files ===" "Cyan"

$junkPatterns = @(
    "[TGx]*.txt",
    "*Downloaded from*.txt",
    "*NEW upcoming*.txt",
    "RARBG*.txt",
    "RARBG*.exe",
    "*.nfo"
)

$deletedFiles = 0
$failedFiles = 0

foreach ($pattern in $junkPatterns) {
    $searchPath = Join-Path $MoviesPath $pattern
    Write-Log "Searching for: $pattern" "Gray"

    # Use cmd del command
    $output = cmd /c "del /s /q /f `"$searchPath`" 2>&1"

    if ($output -match "Could Not Find") {
        Write-Log "  No files found for pattern: $pattern" "Gray"
    } else {
        Write-Log "  Deleted files matching: $pattern" "Green"
        $deletedFiles++
    }
}

Write-Log "Junk file deletion complete" "Green"
Write-Host ""

# Step 2: Delete empty torrent folders
Write-Log "=== STEP 2: Force Delete Empty Torrent Folders ===" "Cyan"

$foldersToDelete = @(
    "Alien (1979) [Theactrical] [Remastered]",
    "American.Fiction.2023.720p.AMZN.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "An American Tail Fievel Goes West (1991) [720p] [BluRay] [YTS.MX]",
    "Anyone.But.You.2023.720p.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "Ashes In The Snow (2018) [WEBRip] [720p] [YTS.AM]",
    "Barbie.2023.1080p.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Beauty And The Beast (2017) [YTS.AG]",
    "Beetlejuice.Beetlejuice.2024.1080p.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Belladonna Of Sadness (1973) [BluRay] [1080p] [YTS.LT]",
    "Blink.Twice.2024.720p.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "Bottoms.2023.1080p.AMZN.WEBRip.DDP5.1.x265.10bit-GalaxyRG265[TGx]",
    "Clue (1985) [BluRay] [720p] [YTS.AM]",
    "Deadpool.and.Wolverine.2024.1080p.AMZN.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Dinosour (2000) [1080p]",
    "Dream.Scenario.2023.1080p.AMZN.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Drop.Dead.Gorgeous.1999.720p.BluRay.999MB.HQ.x265.10bit-GalaxyRG[TGx]",
    "Freaky Friday (2003) [BluRay] [720p] [YTS.AM]",
    "Game Night (2018) [BluRay] [720p] [YTS.AM]",
    "Joy.Ride.2023.1080p.AMZN.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Mafia.Mamma.2023.720p.AMZN.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "Mean.Girls.2024.720p.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "Mystery.Men.1999.REMASTERED.720p.BluRay.999MB.HQ.x265.10bit-GalaxyRG[TGx]",
    "No.Men.Beyond.This.Point.2015.DVDRip.x264-RedBlade[PRiME]",
    "Past.Lives.2023.1080p.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Pineapple Express UNRATED (2008) [1080p]",
    "Pirates Of The Caribbean Dead Men Tell No Tales (2017) [YTS.AG]",
    "Poor.Things.2023.720p.WEBRip.900MB.x264-GalaxyRG[TGx]",
    "Rumours.2024.1080p.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Samsara (2011) [BluRay] [720p] [YTS.AM]",
    "Scrambled.2024.720p.AMZN.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "Showgirls.1995.720p.BluRay.999MB.HQ.x265.10bit-GalaxyRG[TGx]",
    "Speak.no.Evil.2024.1080p.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Stargate (1994) [Extended]",
    "The Birdcage (1996) [BluRay] [1080p] [YTS.AM]",
    "The Hunger Games (2012) [1080p]",
    "The Hunger Games Mockingjay   Part 1 (2014) [1080p]",
    "The Land Before Time (1988) [BluRay] [720p] [YTS.AM]",
    "The.End.We.Start.From.2023.720p.AMZN.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "The.Fall.Guy.2024.1080p.AMZN.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "The.Holdovers.2023.720p.WEBRip.900MB.x264-GalaxyRG[TGx]",
    "The.Substance.2024.720p.WEBRip.900MB.x264-GalaxyRG[TGx]",
    "Trap.2024.720p.AMZN.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "Walk Hard The Dewey Cox Story (2007) [BluRay] [720p] [YTS.AM]",
    "What We Do in the Shadows (2014) [1080p]"
)

$deletedFolders = 0
$skippedFolders = 0
$failedFolders = 0

foreach ($folderName in $foldersToDelete) {
    $fullPath = Join-Path $MoviesPath $folderName

    if (Test-Path $fullPath) {
        # Safety check for video files
        $videoFiles = Get-ChildItem -Path $fullPath -Include *.mkv,*.mp4,*.avi,*.mov,*.wmv -Recurse -File -ErrorAction SilentlyContinue

        if ($videoFiles.Count -gt 0) {
            Write-Log "[PROTECTED - HAS VIDEO] $folderName" "Red"
            $skippedFolders++
            continue
        }

        # Use CMD rmdir with /s (subdirs) and /q (quiet)
        Write-Log "Deleting: $folderName" "Yellow"

        $cmdOutput = cmd /c "rmdir /s /q `"$fullPath`" 2>&1"

        # Check if deletion worked
        if (Test-Path $fullPath) {
            Write-Log "[FAILED] Still exists: $folderName" "Red"
            Write-Log "  CMD Output: $cmdOutput" "Gray"

            # Try alternative method - take ownership first
            Write-Log "  Trying with takeown..." "Yellow"
            takeown /F $fullPath /R /D Y 2>&1 | Out-Null
            icacls $fullPath /grant "${env:USERNAME}:(OI)(CI)F" /T 2>&1 | Out-Null

            $cmdOutput = cmd /c "rmdir /s /q `"$fullPath`" 2>&1"

            if (Test-Path $fullPath) {
                Write-Log "[STILL FAILED] $folderName" "Red"
                $failedFolders++
            } else {
                Write-Log "[DELETED - with takeown] $folderName" "Green"
                $deletedFolders++
            }
        } else {
            Write-Log "[DELETED] $folderName" "Green"
            $deletedFolders++
        }
    }
}

Write-Host ""
Write-Log "=== SUMMARY ===" "Cyan"
Write-Log "Folders deleted: $deletedFolders" "Green"
Write-Log "Folders skipped (had video): $skippedFolders" "Yellow"
Write-Log "Folders failed to delete: $failedFolders" "Red"
Write-Host ""

# Verify final state
$remainingFolders = (Get-ChildItem -Path $MoviesPath -Directory).Count
Write-Log "Total movie folders remaining: $remainingFolders" "White"

Write-Host ""
Write-Log "Log file: $logFile" "Cyan"

if ($failedFolders -gt 0) {
    Write-Host ""
    Write-Log "=== TROUBLESHOOTING FAILED DELETIONS ===" "Red"
    Write-Log "1. Close Windows Explorer windows showing A:\Media\Movies" "Yellow"
    Write-Log "2. Close Plex or any media players" "Yellow"
    Write-Log "3. Run this script again" "Yellow"
    Write-Log "4. Or manually delete the failed folders in Windows Explorer" "Yellow"
}
