# Remove-EmptyEpisodeFolders.ps1
# Removes leftover episode folders that only contain non-video files

param(
    [string]$TVShowsPath = "A:\Media\TV Shows"
)

$shows = @(
    "Wild Wild Country (2018)",
    "The Rehearsal (2022)",
    "Mrs. Davis (2023)",
    "Party Down (2009)"
)

Write-Host "Removing leftover episode folders..." -ForegroundColor Cyan
Write-Host ""

$totalRemoved = 0

foreach ($showName in $shows) {
    $showPath = Join-Path $TVShowsPath $showName

    if (-not (Test-Path -LiteralPath $showPath)) {
        continue
    }

    Write-Host "Processing: $showName" -ForegroundColor Yellow

    $episodeFolders = Get-ChildItem -LiteralPath $showPath -Directory |
                     Where-Object { $_.Name -match 'S\d+E\d+' }

    foreach ($folder in $episodeFolders) {
        try {
            Remove-Item -LiteralPath $folder.FullName -Recurse -Force
            Write-Host "  Removed: $($folder.Name)" -ForegroundColor Green
            $totalRemoved++
        } catch {
            Write-Host "  Error removing $($folder.Name): $_" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Removed $totalRemoved leftover folder(s)" -ForegroundColor Green
