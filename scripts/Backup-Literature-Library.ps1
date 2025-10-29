# Backup-Literature-Library.ps1
# Creates a complete backup of the Literature library before migration

param(
    [string]$SourcePath = "A:\Media\Literature",
    [string]$BackupPath = "A:\Media\Literature.backup",
    [switch]$GenerateHashes = $false
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = "logs\literature-backup-$timestamp.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

# Create logs directory if it doesn't exist
if (-not (Test-Path "logs")) {
    New-Item -Path "logs" -ItemType Directory | Out-Null
}

Write-Log "=== LITERATURE LIBRARY BACKUP STARTED ===" "INFO"
Write-Log "Source: $SourcePath"
Write-Log "Backup: $BackupPath"
Write-Log ""

# Step 1: Verify source exists
Write-Log "Step 1: Verifying source directory..." "INFO"
if (-not (Test-Path $SourcePath)) {
    Write-Log "ERROR: Source path does not exist: $SourcePath" "ERROR"
    exit 1
}

$sourceItems = Get-ChildItem -Path $SourcePath -Recurse -File
$sourceFileCount = $sourceItems.Count
$sourceTotalSize = ($sourceItems | Measure-Object -Property Length -Sum).Sum
$sourceSizeGB = [math]::Round($sourceTotalSize / 1GB, 2)

Write-Log "Source contains $sourceFileCount files ($sourceSizeGB GB)"
Write-Log ""

# Step 2: Check if backup already exists
if (Test-Path $BackupPath) {
    Write-Host ""
    Write-Host "WARNING: Backup directory already exists: $BackupPath" -ForegroundColor Yellow
    Write-Host "This will ADD to or OVERWRITE existing backup files." -ForegroundColor Yellow
    $response = Read-Host "Continue? (yes/no)"
    if ($response -ne "yes") {
        Write-Log "Backup cancelled by user" "INFO"
        exit 0
    }
    Write-Log "User confirmed overwrite of existing backup"
} else {
    Write-Log "Step 2: Creating backup directory..." "INFO"
    New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
    Write-Log "Backup directory created"
}
Write-Log ""

# Step 3: Check available disk space
Write-Log "Step 3: Checking available disk space..." "INFO"
$backupDrive = Split-Path $BackupPath -Qualifier
$driveInfo = Get-PSDrive $backupDrive.TrimEnd(':')
$freeSpaceGB = [math]::Round($driveInfo.Free / 1GB, 2)

Write-Log "Required space: $sourceSizeGB GB"
Write-Log "Available space: $freeSpaceGB GB"

if ($freeSpaceGB -lt ($sourceSizeGB * 1.1)) {
    Write-Log "WARNING: Low disk space! Backup may fail." "WARN"
    $response = Read-Host "Continue anyway? (yes/no)"
    if ($response -ne "yes") {
        Write-Log "Backup cancelled due to low disk space" "INFO"
        exit 0
    }
} else {
    Write-Log "Sufficient disk space available"
}
Write-Log ""

# Step 4: Perform backup with progress
Write-Log "Step 4: Copying files..." "INFO"
Write-Host ""
Write-Host "Copying files from $SourcePath to $BackupPath" -ForegroundColor Cyan
Write-Host "This may take several minutes depending on library size..." -ForegroundColor Cyan
Write-Host ""

$copiedCount = 0
$errorCount = 0
$startTime = Get-Date

try {
    # Use robocopy for efficient copying with retry logic
    $robocopyArgs = @(
        $SourcePath,
        $BackupPath,
        "/E",           # Copy subdirectories including empty ones
        "/COPY:DAT",    # Copy Data, Attributes, Timestamps (not ACLs/auditing)
        "/R:3",         # Retry 3 times on failure
        "/W:5",         # Wait 5 seconds between retries
        "/MT:8",        # Multi-threaded (8 threads)
        "/NP",          # No progress % in log
        "/NDL",         # No directory list
        "/LOG+:$logFile" # Append to log file
    )

    Write-Log "Running robocopy with multi-threading..."
    $robocopyProcess = Start-Process -FilePath "robocopy" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow

    # Robocopy exit codes: 0-7 are success, 8+ are errors
    if ($robocopyProcess.ExitCode -lt 8) {
        Write-Log "Robocopy completed successfully (Exit code: $($robocopyProcess.ExitCode))"
    } else {
        Write-Log "Robocopy completed with errors (Exit code: $($robocopyProcess.ExitCode))" "WARN"
    }

} catch {
    Write-Log "Error during copy: $_" "ERROR"
    $errorCount++
}

$endTime = Get-Date
$duration = $endTime - $startTime
Write-Log ""
Write-Log "Copy completed in $($duration.ToString('mm\:ss'))"
Write-Log ""

# Step 5: Verify backup
Write-Log "Step 5: Verifying backup..." "INFO"
$backupItems = Get-ChildItem -Path $BackupPath -Recurse -File
$backupFileCount = $backupItems.Count
$backupTotalSize = ($backupItems | Measure-Object -Property Length -Sum).Sum
$backupSizeGB = [math]::Round($backupTotalSize / 1GB, 2)

Write-Log "Backup contains $backupFileCount files ($backupSizeGB GB)"

if ($backupFileCount -eq $sourceFileCount) {
    Write-Log "✓ File count matches!" "INFO"
} else {
    Write-Log "✗ File count mismatch! Source: $sourceFileCount, Backup: $backupFileCount" "WARN"
}

if ($backupTotalSize -eq $sourceTotalSize) {
    Write-Log "✓ Total size matches!" "INFO"
} else {
    $sizeDiff = [math]::Round(($sourceTotalSize - $backupTotalSize) / 1MB, 2)
    Write-Log "✗ Size mismatch! Difference: $sizeDiff MB" "WARN"
}
Write-Log ""

# Step 6: Generate file manifest
Write-Log "Step 6: Generating file manifest..." "INFO"
$manifestFile = "$BackupPath\BACKUP_MANIFEST_$timestamp.txt"

$manifest = @"
=== LITERATURE LIBRARY BACKUP MANIFEST ===
Backup Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Source Path: $SourcePath
Backup Path: $BackupPath

File Count: $backupFileCount
Total Size: $backupSizeGB GB

=== FILE LIST ===
"@

$backupItems | Sort-Object FullName | ForEach-Object {
    $relativePath = $_.FullName -replace [regex]::Escape($BackupPath), ""
    $sizeKB = [math]::Round($_.Length / 1KB, 2)
    $manifest += "`n$relativePath ($sizeKB KB)"
}

$manifest | Out-File -FilePath $manifestFile -Encoding UTF8
Write-Log "Manifest saved to: $manifestFile"
Write-Log ""

# Step 7: Optional hash generation (slow but thorough verification)
if ($GenerateHashes) {
    Write-Log "Step 7: Generating file hashes (this will take a while)..." "INFO"
    $hashFile = "$BackupPath\BACKUP_HASHES_$timestamp.csv"

    Write-Host "Generating SHA256 hashes for verification..." -ForegroundColor Cyan
    $hashData = @()
    $hashCount = 0

    foreach ($file in $backupItems) {
        try {
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
            $relativePath = $file.FullName -replace [regex]::Escape($BackupPath), ""
            $hashData += [PSCustomObject]@{
                File = $relativePath
                Size = $file.Length
                SHA256 = $hash.Hash
            }
            $hashCount++
            if ($hashCount % 10 -eq 0) {
                Write-Host "  Hashed $hashCount / $backupFileCount files..." -ForegroundColor Gray
            }
        } catch {
            Write-Log "Failed to hash file: $($file.FullName) - $_" "WARN"
        }
    }

    $hashData | Export-Csv -Path $hashFile -NoTypeInformation
    Write-Log "Hashes saved to: $hashFile"
    Write-Log ""
}

# Final summary
Write-Log "=== BACKUP COMPLETE ===" "INFO"
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host "           BACKUP COMPLETED SUCCESSFULLY                      " -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Source:      $SourcePath" -ForegroundColor Cyan
Write-Host "Backup:      $BackupPath" -ForegroundColor Cyan
Write-Host "Files:       $backupFileCount files" -ForegroundColor Cyan
Write-Host "Size:        $backupSizeGB GB" -ForegroundColor Cyan
Write-Host "Duration:    $($duration.ToString('mm\:ss'))" -ForegroundColor Cyan
Write-Host "Log:         $logFile" -ForegroundColor Cyan
Write-Host "Manifest:    $manifestFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: Do not delete the source directory until migration is complete!" -ForegroundColor Yellow
Write-Host "           Keep this backup until all torrents are verified seeding." -ForegroundColor Yellow
Write-Host ""

Write-Log "Full log available at: $logFile"
