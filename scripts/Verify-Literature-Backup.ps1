# Verify-Literature-Backup.ps1
# Verifies backup integrity by comparing source and backup

param(
    [string]$SourcePath = "A:\Media\Literature",
    [string]$BackupPath = "A:\Media\Literature.backup",
    [switch]$CheckHashes = $false
)

$ErrorActionPreference = "Continue"

Write-Host "=== LITERATURE BACKUP VERIFICATION ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source: $SourcePath"
Write-Host "Backup: $BackupPath"
Write-Host ""

# Check paths exist
if (-not (Test-Path $SourcePath)) {
    Write-Host "ERROR: Source path does not exist!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $BackupPath)) {
    Write-Host "ERROR: Backup path does not exist!" -ForegroundColor Red
    exit 1
}

# Get file lists
Write-Host "Analyzing directories..." -ForegroundColor Yellow
$sourceFiles = Get-ChildItem -Path $SourcePath -Recurse -File | Sort-Object FullName
$backupFiles = Get-ChildItem -Path $BackupPath -Recurse -File |
    Where-Object { $_.Name -notlike "BACKUP_*" } |
    Sort-Object FullName

Write-Host ""
Write-Host "Source files: $($sourceFiles.Count)"
Write-Host "Backup files: $($backupFiles.Count)"
Write-Host ""

# Compare counts
$issues = @()

if ($sourceFiles.Count -ne $backupFiles.Count) {
    $issues += "File count mismatch: Source has $($sourceFiles.Count), Backup has $($backupFiles.Count)"
    Write-Host "[FAIL] File count mismatch!" -ForegroundColor Red
} else {
    Write-Host "[PASS] File count matches" -ForegroundColor Green
}

# Compare total sizes
$sourceSize = ($sourceFiles | Measure-Object -Property Length -Sum).Sum
$backupSize = ($backupFiles | Measure-Object -Property Length -Sum).Sum
$sourceSizeGB = [math]::Round($sourceSize / 1GB, 2)
$backupSizeGB = [math]::Round($backupSize / 1GB, 2)

Write-Host "Source size: $sourceSizeGB GB"
Write-Host "Backup size: $backupSizeGB GB"

if ($sourceSize -ne $backupSize) {
    $diff = [math]::Round(($sourceSize - $backupSize) / 1MB, 2)
    $issues += "Size mismatch: Difference of $diff MB"
    Write-Host "[FAIL] Size mismatch! Difference: $diff MB" -ForegroundColor Red
} else {
    Write-Host "[PASS] Total size matches" -ForegroundColor Green
}

Write-Host ""

# Build lookup dictionary for faster comparison
Write-Host "Building file comparison..." -ForegroundColor Yellow
$sourceDict = @{}
foreach ($file in $sourceFiles) {
    $relativePath = $file.FullName -replace [regex]::Escape($SourcePath), ""
    $sourceDict[$relativePath] = $file
}

$backupDict = @{}
foreach ($file in $backupFiles) {
    $relativePath = $file.FullName -replace [regex]::Escape($BackupPath), ""
    $backupDict[$relativePath] = $file
}

# Find missing files
Write-Host ""
Write-Host "Checking for missing files..." -ForegroundColor Yellow

$missingInBackup = @()
foreach ($key in $sourceDict.Keys) {
    if (-not $backupDict.ContainsKey($key)) {
        $missingInBackup += $key
    }
}

$extraInBackup = @()
foreach ($key in $backupDict.Keys) {
    if (-not $sourceDict.ContainsKey($key)) {
        $extraInBackup += $key
    }
}

if ($missingInBackup.Count -gt 0) {
    Write-Host "[FAIL] $($missingInBackup.Count) files missing from backup:" -ForegroundColor Red
    $missingInBackup | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    $issues += "Missing files in backup: $($missingInBackup.Count)"
} else {
    Write-Host "[PASS] No missing files in backup" -ForegroundColor Green
}

if ($extraInBackup.Count -gt 0) {
    Write-Host "[INFO] $($extraInBackup.Count) extra files in backup (not in source):" -ForegroundColor Yellow
    $extraInBackup | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

# Compare file sizes for matching files
Write-Host ""
Write-Host "Comparing file sizes..." -ForegroundColor Yellow

$sizeMismatches = @()
foreach ($key in $sourceDict.Keys) {
    if ($backupDict.ContainsKey($key)) {
        $sourceFile = $sourceDict[$key]
        $backupFile = $backupDict[$key]

        if ($sourceFile.Length -ne $backupFile.Length) {
            $sizeMismatches += [PSCustomObject]@{
                File = $key
                SourceSize = $sourceFile.Length
                BackupSize = $backupFile.Length
                Difference = $sourceFile.Length - $backupFile.Length
            }
        }
    }
}

if ($sizeMismatches.Count -gt 0) {
    Write-Host "[FAIL] $($sizeMismatches.Count) files have size mismatches:" -ForegroundColor Red
    $sizeMismatches | Format-Table -AutoSize
    $issues += "Size mismatches: $($sizeMismatches.Count)"
} else {
    Write-Host "[PASS] All file sizes match" -ForegroundColor Green
}

# Optional: Check file hashes (slow but thorough)
if ($CheckHashes) {
    Write-Host ""
    Write-Host "Checking file hashes (this will take a while)..." -ForegroundColor Yellow

    $hashMismatches = @()
    $checked = 0

    foreach ($key in $sourceDict.Keys | Select-Object -First 20) {
        if ($backupDict.ContainsKey($key)) {
            $sourceHash = (Get-FileHash -Path $sourceDict[$key].FullName -Algorithm MD5).Hash
            $backupHash = (Get-FileHash -Path $backupDict[$key].FullName -Algorithm MD5).Hash

            if ($sourceHash -ne $backupHash) {
                $hashMismatches += $key
            }

            $checked++
            Write-Host "  Checked $checked files..." -ForegroundColor Gray
        }
    }

    if ($hashMismatches.Count -gt 0) {
        Write-Host "[FAIL] $($hashMismatches.Count) files have hash mismatches:" -ForegroundColor Red
        $hashMismatches | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        $issues += "Hash mismatches: $($hashMismatches.Count)"
    } else {
        Write-Host "[PASS] All checked hashes match" -ForegroundColor Green
    }
}

# Final summary
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
if ($issues.Count -eq 0) {
    Write-Host "BACKUP VERIFICATION PASSED" -ForegroundColor Green
    Write-Host "All files successfully backed up!" -ForegroundColor Green
} else {
    Write-Host "BACKUP VERIFICATION FAILED" -ForegroundColor Red
    Write-Host "Issues found:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "DO NOT PROCEED with migration until backup issues are resolved!" -ForegroundColor Yellow
}
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
