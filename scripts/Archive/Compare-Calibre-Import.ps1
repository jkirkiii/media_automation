# Compare-Calibre-Import.ps1
# Compares books in backup directory with Calibre library

param(
    [string]$BackupPath = "A:\Media\Literature.backup",
    [string]$CalibreLibrary = "A:\Media\Calibre"
)

Write-Host "=== CALIBRE IMPORT COMPARISON ===" -ForegroundColor Cyan
Write-Host ""

# Get all ebook files from backup
Write-Host "Scanning backup directory..." -ForegroundColor Yellow
$backupBooks = Get-ChildItem -Path $BackupPath -Recurse -File |
    Where-Object { $_.Extension -match '\.(epub|mobi|azw3|pdf)$' } |
    Where-Object { $_.Name -notlike "*.opf" -and $_.Name -notlike "*.jpg" }

Write-Host "Found $($backupBooks.Count) ebook files in backup" -ForegroundColor Green
Write-Host ""

# Get all ebook files from Calibre
Write-Host "Scanning Calibre library..." -ForegroundColor Yellow
$calibreBooks = Get-ChildItem -Path $CalibreLibrary -Recurse -File |
    Where-Object { $_.Extension -match '\.(epub|mobi|azw3|pdf)$' }

Write-Host "Found $($calibreBooks.Count) ebook files in Calibre" -ForegroundColor Green
Write-Host ""

# Organize backup books by filename
$backupDict = @{}
foreach ($book in $backupBooks) {
    $key = "$($book.BaseName)-$($book.Extension)-$($book.Length)"
    if (-not $backupDict.ContainsKey($key)) {
        $backupDict[$key] = @()
    }
    $backupDict[$key] += $book
}

# Organize Calibre books by filename
$calibreDict = @{}
foreach ($book in $calibreBooks) {
    $key = "$($book.BaseName)-$($book.Extension)-$($book.Length)"
    if (-not $calibreDict.ContainsKey($key)) {
        $calibreDict[$key] = @()
    }
    $calibreDict[$key] += $book
}

Write-Host "=== IMPORT ANALYSIS ===" -ForegroundColor Cyan
Write-Host ""

# Count unique books vs file instances
$uniqueBackupBooks = $backupDict.Keys.Count
$uniqueCalibreBooks = $calibreDict.Keys.Count

Write-Host "Unique books in backup: $uniqueBackupBooks" -ForegroundColor White
Write-Host "Unique books in Calibre: $uniqueCalibreBooks" -ForegroundColor White
Write-Host ""

# Find books in backup but not in Calibre
Write-Host "=== BOOKS NOT IMPORTED ===" -ForegroundColor Yellow
$notImported = @()
foreach ($key in $backupDict.Keys) {
    if (-not $calibreDict.ContainsKey($key)) {
        $notImported += $backupDict[$key][0]
    }
}

if ($notImported.Count -gt 0) {
    Write-Host "Found $($notImported.Count) books that were NOT imported:" -ForegroundColor Red
    Write-Host ""
    foreach ($book in $notImported | Sort-Object FullName) {
        $relativePath = $book.FullName -replace [regex]::Escape($BackupPath + '\'), ''
        Write-Host "  - $relativePath" -ForegroundColor Red
    }
} else {
    Write-Host "[PASS] All books from backup were imported!" -ForegroundColor Green
}

Write-Host ""

# Find potential duplicates in Calibre (same file appearing multiple times)
Write-Host "=== POTENTIAL DUPLICATES IN CALIBRE ===" -ForegroundColor Yellow
$duplicates = $calibreDict.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

if ($duplicates.Count -gt 0) {
    Write-Host "Found $($duplicates.Count) potential duplicate books:" -ForegroundColor Yellow
    Write-Host ""
    foreach ($dup in $duplicates) {
        $sample = $dup.Value[0]
        Write-Host "  Book: $($sample.BaseName)" -ForegroundColor Cyan
        foreach ($instance in $dup.Value) {
            $relativePath = $instance.FullName -replace [regex]::Escape($CalibreLibrary + '\'), ''
            Write-Host "    Location: $relativePath" -ForegroundColor Gray
        }
        Write-Host ""
    }
} else {
    Write-Host "[PASS] No duplicate files detected in Calibre" -ForegroundColor Green
}

Write-Host ""

# List all books imported with their Calibre organization
Write-Host "=== CALIBRE BOOK ORGANIZATION ===" -ForegroundColor Cyan
Write-Host ""

# Group Calibre books by author folder
$authorFolders = $calibreBooks |
    ForEach-Object {
        $parts = ($_.DirectoryName -replace [regex]::Escape($CalibreLibrary + '\'), '').Split('\')
        if ($parts.Count -gt 0) { $parts[0] } else { "Unknown" }
    } |
    Group-Object |
    Sort-Object Name

Write-Host "Books organized by author:" -ForegroundColor White
foreach ($author in $authorFolders) {
    Write-Host "  $($author.Name): $($author.Count) books" -ForegroundColor White
}

Write-Host ""

# Check for books with metadata.opf (indicates Calibre processed them)
$booksWithMetadata = Get-ChildItem -Path $CalibreLibrary -Recurse -Filter "metadata.opf"
Write-Host "Books with Calibre metadata: $($booksWithMetadata.Count)" -ForegroundColor White

# Check for covers
$covers = Get-ChildItem -Path $CalibreLibrary -Recurse -Filter "cover.jpg"
Write-Host "Books with cover images: $($covers.Count)" -ForegroundColor White

Write-Host ""

# Summary
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backup files: $($backupBooks.Count)" -ForegroundColor White
Write-Host "Calibre files: $($calibreBooks.Count)" -ForegroundColor White
Write-Host "Not imported: $($notImported.Count)" -ForegroundColor $(if ($notImported.Count -gt 0) { "Red" } else { "Green" })
Write-Host "Potential duplicates: $($duplicates.Count)" -ForegroundColor $(if ($duplicates.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

# Export detailed report
$reportPath = "data\calibre-import-report-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"

# Ensure data directory exists
if (-not (Test-Path "data")) {
    New-Item -Path "data" -ItemType Directory | Out-Null
}

$report = @{
    BackupBooks = $backupBooks.Count
    CalibreBooks = $calibreBooks.Count
    UniqueBackupBooks = $uniqueBackupBooks
    UniqueCalibreBooks = $uniqueCalibreBooks
    NotImported = $notImported | ForEach-Object { $_.FullName -replace [regex]::Escape($BackupPath + '\'), '' }
    Duplicates = $duplicates | ForEach-Object {
        @{
            BookName = $_.Value[0].BaseName
            Count = $_.Value.Count
            Locations = $_.Value | ForEach-Object { $_.FullName -replace [regex]::Escape($CalibreLibrary + '\'), '' }
        }
    }
    Authors = $authorFolders | ForEach-Object { @{ Name = $_.Name; Count = $_.Count } }
}

$report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "Detailed report saved to: $reportPath" -ForegroundColor Cyan
Write-Host ""
