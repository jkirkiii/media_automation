# Quick Preview Test - Non-Interactive
# Shows what the cleanup script will do WITHOUT making changes

$MoviesPath = "A:\Media\Movies"

# Video file extensions
$VideoExtensions = @("*.mkv", "*.mp4", "*.avi", "*.mov", "*.wmv", "*.flv", "*.m4v", "*.mpg", "*.mpeg", "*.webm")

# Check if folder contains video files
function Test-ContainsVideoFiles {
    param([string]$Path)
    foreach ($ext in $VideoExtensions) {
        if (Get-ChildItem -Path $Path -Filter $ext -Recurse -File -ErrorAction SilentlyContinue) {
            return $true
        }
    }
    return $false
}

Write-Host "=== CLEANUP PREVIEW FOR A:\Media\Movies ===" -ForegroundColor Cyan
Write-Host ""

# Find all folders
$allFolders = Get-ChildItem -Path $MoviesPath -Directory
$cleanPattern = '^[^.]+\s\(\d{4}\)$'

$cleanFolders = @()
$oldFoldersWithVideo = @()
$oldFoldersEmpty = @()

Write-Host "Analyzing $($allFolders.Count) folders..." -ForegroundColor Yellow
Write-Host ""

foreach ($folder in $allFolders) {
    if ($folder.Name -match $cleanPattern) {
        $cleanFolders += $folder
    } else {
        # Check if it looks like old torrent-style naming
        if ($folder.Name -match '\.' -or
            $folder.Name -match '(720p|1080p|2160p)' -or
            $folder.Name -match '\[.*\]' -or
            $folder.Name -match '(WEBRip|BluRay|x264|x265|HEVC|GalaxyRG)') {

            $hasVideo = Test-ContainsVideoFiles -Path $folder.FullName

            if ($hasVideo) {
                $oldFoldersWithVideo += $folder
            } else {
                $oldFoldersEmpty += $folder
            }
        }
    }
}

# Report results
Write-Host "========================================" -ForegroundColor Green
Write-Host "SUMMARY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Clean Plex folders (no action needed): $($cleanFolders.Count)" -ForegroundColor Green
Write-Host "Old-style folders WITH video (protected): $($oldFoldersWithVideo.Count)" -ForegroundColor Yellow
Write-Host "Old-style folders WITHOUT video (safe to delete): $($oldFoldersEmpty.Count)" -ForegroundColor Red
Write-Host ""

if ($oldFoldersWithVideo.Count -gt 0) {
    Write-Host "=== OLD FOLDERS WITH VIDEO (WILL NOT DELETE) ===" -ForegroundColor Yellow
    foreach ($folder in $oldFoldersWithVideo | Sort-Object Name | Select-Object -First 20) {
        Write-Host "  [PROTECTED] $($folder.Name)" -ForegroundColor Yellow
    }
    if ($oldFoldersWithVideo.Count -gt 20) {
        Write-Host "  ... and $($oldFoldersWithVideo.Count - 20) more" -ForegroundColor Gray
    }
    Write-Host ""
}

if ($oldFoldersEmpty.Count -gt 0) {
    Write-Host "=== OLD FOLDERS WITHOUT VIDEO (SAFE TO DELETE) ===" -ForegroundColor Red
    foreach ($folder in $oldFoldersEmpty | Sort-Object Name) {
        Write-Host "  [CAN DELETE] $($folder.Name)" -ForegroundColor Red
    }
    Write-Host ""
}

# Check for junk files
Write-Host "=== JUNK FILES ===" -ForegroundColor Cyan
$junkPatterns = @("*[TGx]*", "*Downloaded from*.txt", "*NEW upcoming*.txt")
$junkFiles = @()
foreach ($pattern in $junkPatterns) {
    $junkFiles += Get-ChildItem -Path $MoviesPath -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
}
Write-Host "Junk files to delete: $($junkFiles.Count)" -ForegroundColor Yellow
if ($junkFiles.Count -gt 0 -and $junkFiles.Count -le 50) {
    foreach ($file in $junkFiles) {
        Write-Host "  $($file.FullName)" -ForegroundColor Gray
    }
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($oldFoldersWithVideo.Count -gt 0) {
    Write-Host "1. Run FileBot to rename the $($oldFoldersWithVideo.Count) protected folders" -ForegroundColor Yellow
    Write-Host "   Use: Rename-MediaLibrary.ps1" -ForegroundColor White
}

if ($oldFoldersEmpty.Count -gt 0 -or $junkFiles.Count -gt 0) {
    Write-Host "2. Run safe cleanup to remove $($oldFoldersEmpty.Count) empty folders and $($junkFiles.Count) junk files" -ForegroundColor Yellow
    Write-Host "   Use: Cleanup-OldFolders-Safe.ps1" -ForegroundColor White
}

Write-Host ""
