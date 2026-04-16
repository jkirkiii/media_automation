# Extract-RarSeason.ps1
# Extracts multi-part RAR archives for each episode in a season folder.
# Each episode subdirectory containing a .rar file is extracted in-place.
# Usage: .\scripts\Extract-RarSeason.ps1 -SeasonPath "A:\Downloads\TV\Hacks.S03.1080p.BluRay.x264-BRAVERY"

param(
    [Parameter(Mandatory = $true)]
    [string]$SeasonPath,

    [string]$SevenZipPath = "C:\Program Files\7-Zip\7z.exe"
)

if (-not (Test-Path $SevenZipPath)) {
    Write-Error "7-Zip not found at: $SevenZipPath"
    exit 1
}

if (-not (Test-Path $SeasonPath)) {
    Write-Error "Season path not found: $SeasonPath"
    exit 1
}

$episodeDirs = Get-ChildItem -Path $SeasonPath -Directory

if ($episodeDirs.Count -eq 0) {
    Write-Host "No episode subdirectories found in: $SeasonPath"
    exit 0
}

$successCount = 0
$failCount = 0

foreach ($dir in $episodeDirs) {
    $rarFile = Get-ChildItem -Path $dir.FullName -Filter "*.rar" | Select-Object -First 1

    if (-not $rarFile) {
        Write-Host "SKIP  $($dir.Name) -- no .rar file found"
        continue
    }

    # Check if a full video file already exists (excluding sample files)
    $existing = Get-ChildItem -Path $dir.FullName -Include "*.mkv","*.avi","*.mp4" -Recurse |
        Where-Object { $_.Name -notmatch '(?i)sample' -and $_.DirectoryName -notmatch '(?i)\\sample$' } |
        Select-Object -First 1
    if ($existing) {
        Write-Host "SKIP  $($dir.Name) -- already extracted: $($existing.Name)"
        continue
    }

    Write-Host "EXTRACTING $($dir.Name) ..."
    $result = & $SevenZipPath e "$($rarFile.FullName)" "-o$($dir.FullName)" -y 2>&1

    $videoFile = Get-ChildItem -Path $dir.FullName -Include "*.mkv","*.avi","*.mp4" -Recurse | Select-Object -First 1
    if ($videoFile) {
        Write-Host "  OK    $($videoFile.Name)"
        $successCount++
    } else {
        Write-Host "  FAIL  No video file found after extraction"
        Write-Host $result
        $failCount++
    }
}

Write-Host ""
Write-Host "Done. Extracted: $successCount  Failed: $failCount"
