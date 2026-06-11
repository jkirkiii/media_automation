# Check-Literature-Directory.ps1
# Quick check of what's still in the original Literature directory

param(
    [string]$LiteraturePath = "A:\Media\Literature"
)

Write-Host "=== LITERATURE DIRECTORY STATUS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Checking: $LiteraturePath" -ForegroundColor White
Write-Host ""

if (-not (Test-Path $LiteraturePath)) {
    Write-Host "ERROR: Directory does not exist!" -ForegroundColor Red
    exit 1
}

# Get all ebook files
$ebookFiles = Get-ChildItem -Path $LiteraturePath -Recurse -File |
    Where-Object { $_.Extension -match '\.(epub|mobi|azw3|pdf)$' }

Write-Host "Total ebook files: $($ebookFiles.Count)" -ForegroundColor Green
Write-Host "Total size: $([math]::Round(($ebookFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB" -ForegroundColor Green
Write-Host ""

# Group by directory to show which books are still there
Write-Host "=== FILES BY AUTHOR/DIRECTORY ===" -ForegroundColor Cyan
Write-Host ""

$grouped = $ebookFiles | Group-Object DirectoryName | Sort-Object Name

foreach ($group in $grouped) {
    $relativePath = $group.Name -replace [regex]::Escape($LiteraturePath + '\'), ''
    Write-Host "$relativePath" -ForegroundColor Yellow
    foreach ($file in $group.Group) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        Write-Host "  - $($file.Name) ($sizeMB MB)" -ForegroundColor White
    }
    Write-Host ""
}

# List all files with full paths for reference
Write-Host "=== FULL FILE LIST (for qBittorrent reference) ===" -ForegroundColor Cyan
Write-Host ""

foreach ($file in $ebookFiles | Sort-Object FullName) {
    Write-Host $file.FullName -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== INSTRUCTIONS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Compare this list with the 'Content Path' in qBittorrent for your missing torrents." -ForegroundColor Yellow
Write-Host ""
Write-Host "If a torrent expects a file that IS in this list:" -ForegroundColor White
Write-Host "  → The file exists, qBittorrent just lost track" -ForegroundColor Gray
Write-Host "  → Solution: Right-click torrent → 'Force recheck'" -ForegroundColor Green
Write-Host ""
Write-Host "If a torrent expects a file that is NOT in this list:" -ForegroundColor White
Write-Host "  → The file might have been deleted or moved" -ForegroundColor Gray
Write-Host "  → Solution: Copy from backup (A:\Media\Literature.backup)" -ForegroundColor Green
Write-Host ""
