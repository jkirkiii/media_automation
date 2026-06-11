# Fix-Missing-Torrent-Files.ps1
# Helps identify and restore missing torrent files

param(
    [string]$OriginalLocation = "A:\Media\Literature",
    [string]$BackupLocation = "A:\Media\Literature.backup"
)

Write-Host "=== MISSING TORRENT FILES DIAGNOSTIC ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script will help you identify which files are missing and where to find them." -ForegroundColor Yellow
Write-Host ""

Write-Host "INSTRUCTIONS:" -ForegroundColor Cyan
Write-Host "1. Open qBittorrent Web UI (http://localhost:8080)"
Write-Host "2. Filter for torrents with 'Missing files' or 'Error' state"
Write-Host "3. For each missing torrent, note the torrent name and content path"
Write-Host ""
Write-Host "Then we'll help you restore them." -ForegroundColor Yellow
Write-Host ""

# Check if original and backup locations exist
$originalExists = Test-Path $OriginalLocation
$backupExists = Test-Path $BackupLocation

Write-Host "Location Status:" -ForegroundColor White
Write-Host "  Original (seeding): $OriginalLocation - $(if ($originalExists) { '[EXISTS]' } else { '[MISSING]' })" -ForegroundColor $(if ($originalExists) { 'Green' } else { 'Red' })
Write-Host "  Backup: $BackupLocation - $(if ($backupExists) { '[EXISTS]' } else { '[MISSING]' })" -ForegroundColor $(if ($backupExists) { 'Green' } else { 'Red' })
Write-Host ""

if (-not $originalExists -and -not $backupExists) {
    Write-Host "ERROR: Both original and backup locations are missing!" -ForegroundColor Red
    Write-Host "Cannot proceed without source files." -ForegroundColor Red
    exit 1
}

# Function to find a file in both locations
function Find-BookFile {
    param(
        [string]$FileName
    )

    $results = @()

    # Search in original location
    if ($originalExists) {
        $originalFiles = Get-ChildItem -Path $OriginalLocation -Recurse -File -Filter $FileName -ErrorAction SilentlyContinue
        foreach ($file in $originalFiles) {
            $results += [PSCustomObject]@{
                Location = "Original"
                FullPath = $file.FullName
                Size = $file.Length
                Modified = $file.LastWriteTime
            }
        }
    }

    # Search in backup location
    if ($backupExists) {
        $backupFiles = Get-ChildItem -Path $BackupLocation -Recurse -File -Filter $FileName -ErrorAction SilentlyContinue
        foreach ($file in $backupFiles) {
            $results += [PSCustomObject]@{
                Location = "Backup"
                FullPath = $file.FullPath
                Size = $file.Length
                Modified = $file.LastWriteTime
            }
        }
    }

    return $results
}

# Interactive mode: Ask user for missing torrent details
Write-Host "=== MISSING TORRENT INVESTIGATION ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please provide information about each missing torrent." -ForegroundColor Yellow
Write-Host ""

$missingTorrents = @()

for ($i = 1; $i -le 5; $i++) {
    Write-Host "Missing Torrent #$i" -ForegroundColor Cyan
    Write-Host "----------------" -ForegroundColor Gray

    $torrentName = Read-Host "  Enter torrent name (or press Enter to skip)"

    if ([string]::IsNullOrWhiteSpace($torrentName)) {
        Write-Host "  Skipped." -ForegroundColor Gray
        Write-Host ""
        continue
    }

    $expectedPath = Read-Host "  Enter expected content path (from qBittorrent)"

    $missingTorrents += [PSCustomObject]@{
        Number = $i
        Name = $torrentName
        ExpectedPath = $expectedPath
    }

    Write-Host ""
}

if ($missingTorrents.Count -eq 0) {
    Write-Host "No torrents provided. Exiting." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "=== SEARCHING FOR MISSING FILES ===" -ForegroundColor Cyan
Write-Host ""

foreach ($torrent in $missingTorrents) {
    Write-Host "Torrent #$($torrent.Number): $($torrent.Name)" -ForegroundColor Yellow
    Write-Host "Expected location: $($torrent.ExpectedPath)" -ForegroundColor Gray
    Write-Host ""

    # Extract filename from path
    $expectedFile = Split-Path $torrent.ExpectedPath -Leaf

    Write-Host "  Searching for: $expectedFile" -ForegroundColor White

    # Search in both locations
    $originalMatches = @()
    $backupMatches = @()

    if ($originalExists) {
        $originalMatches = Get-ChildItem -Path $OriginalLocation -Recurse -File -Filter $expectedFile -ErrorAction SilentlyContinue
    }

    if ($backupExists) {
        $backupMatches = Get-ChildItem -Path $BackupLocation -Recurse -File -Filter $expectedFile -ErrorAction SilentlyContinue
    }

    if ($originalMatches.Count -eq 0 -and $backupMatches.Count -eq 0) {
        Write-Host "  [NOT FOUND] File not found in original or backup!" -ForegroundColor Red
        Write-Host "  This file may have been deleted or renamed." -ForegroundColor Red
        Write-Host ""
        continue
    }

    # Show matches from original location
    if ($originalMatches.Count -gt 0) {
        Write-Host "  [FOUND IN ORIGINAL]" -ForegroundColor Green
        foreach ($match in $originalMatches) {
            $relativePath = $match.FullName -replace [regex]::Escape($OriginalLocation + '\'), ''
            Write-Host "    Location: $relativePath" -ForegroundColor Green
            Write-Host "    Full path: $($match.FullName)" -ForegroundColor Gray
            Write-Host "    Size: $([math]::Round($match.Length/1MB, 2)) MB" -ForegroundColor Gray
        }
    }

    # Show matches from backup location
    if ($backupMatches.Count -gt 0) {
        Write-Host "  [FOUND IN BACKUP]" -ForegroundColor Cyan
        foreach ($match in $backupMatches) {
            $relativePath = $match.FullName -replace [regex]::Escape($BackupLocation + '\'), ''
            Write-Host "    Location: $relativePath" -ForegroundColor Cyan
            Write-Host "    Full path: $($match.FullName)" -ForegroundColor Gray
            Write-Host "    Size: $([math]::Round($match.Length/1MB, 2)) MB" -ForegroundColor Gray
        }
    }

    Write-Host ""

    # Recommendation
    if ($originalMatches.Count -gt 0) {
        $match = $originalMatches[0]
        $actualPath = $match.FullName

        # Compare expected vs actual path
        if ($actualPath -eq $torrent.ExpectedPath) {
            Write-Host "  [INFO] File exists at expected location but qBittorrent lost track." -ForegroundColor Yellow
            Write-Host "  ACTION: In qBittorrent, right-click torrent → 'Force recheck'" -ForegroundColor Yellow
        } else {
            Write-Host "  [INFO] File exists but in different location." -ForegroundColor Yellow
            Write-Host "  OPTION 1: Move file back to expected location" -ForegroundColor White
            Write-Host "    Expected: $($torrent.ExpectedPath)" -ForegroundColor Gray
            Write-Host "    Actual: $actualPath" -ForegroundColor Gray
            Write-Host ""
            Write-Host "  OPTION 2: Update qBittorrent torrent location" -ForegroundColor White
            Write-Host "    In qBittorrent: Right-click → 'Set location' → Point to: $(Split-Path $actualPath -Parent)" -ForegroundColor Gray
        }
    } elseif ($backupMatches.Count -gt 0) {
        $match = $backupMatches[0]
        Write-Host "  [INFO] File only found in backup (not in original seeding location)." -ForegroundColor Yellow
        Write-Host "  ACTION: Copy file from backup to original location" -ForegroundColor Yellow
        Write-Host "    From: $($match.FullName)" -ForegroundColor Gray
        Write-Host "    To: $($torrent.ExpectedPath)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Would you like to copy it now? (yes/no)" -ForegroundColor Cyan
        $response = Read-Host "  "

        if ($response -eq "yes") {
            $destDir = Split-Path $torrent.ExpectedPath -Parent

            # Create destination directory if it doesn't exist
            if (-not (Test-Path $destDir)) {
                Write-Host "    Creating directory: $destDir" -ForegroundColor Gray
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }

            try {
                Write-Host "    Copying file..." -ForegroundColor Gray
                Copy-Item -Path $match.FullName -Destination $torrent.ExpectedPath -Force
                Write-Host "    [SUCCESS] File copied!" -ForegroundColor Green
                Write-Host "    Now run Force Recheck in qBittorrent" -ForegroundColor Yellow
            } catch {
                Write-Host "    [ERROR] Failed to copy: $_" -ForegroundColor Red
            }
        }
    }

    Write-Host ""
    Write-Host "---" -ForegroundColor Gray
    Write-Host ""
}

# Summary
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. For files found in original location:" -ForegroundColor White
Write-Host "   → Right-click torrent in qBittorrent → 'Force recheck'" -ForegroundColor Gray
Write-Host ""
Write-Host "2. For files in wrong location:" -ForegroundColor White
Write-Host "   → Either move file back, or update torrent location" -ForegroundColor Gray
Write-Host ""
Write-Host "3. For files only in backup:" -ForegroundColor White
Write-Host "   → Copy from backup to original location" -ForegroundColor Gray
Write-Host "   → Then force recheck in qBittorrent" -ForegroundColor Gray
Write-Host ""
Write-Host "4. After fixing all torrents:" -ForegroundColor White
Write-Host "   → Verify all show 'Seeding' status" -ForegroundColor Gray
Write-Host "   → Monitor for 24 hours to ensure stability" -ForegroundColor Gray
Write-Host ""
