# Remove-NonFiction-Tags-From-Fiction.ps1
# Removes incorrect Non-Fiction tags from books that are clearly Fiction
# This fixes the Fiction/Non-Fiction tag conflicts found in the audit

param(
    [string]$LibraryPath = "A:\Media\Calibre",
    [switch]$DryRun = $false
)

Write-Host "Fiction/Non-Fiction Tag Conflict Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

# Get all books with their tags
Write-Host "Loading library..." -ForegroundColor Yellow
$books = calibredb list --fields id,title,tags --library-path "$LibraryPath" --for-machine | ConvertFrom-Json

# Find books with both Fiction and Non-Fiction tags
$conflicts = $books | Where-Object {
    $tagString = $_.tags -join "|"
    # Has Fiction tags AND Non-Fiction tags
    ($tagString -match "^Fiction" -or $tagString -match "\|Fiction\.") -and
    ($tagString -match "^Non-Fiction\." -or $tagString -match "\|Non-Fiction\.")
}

Write-Host "Found $($conflicts.Count) books with Fiction/Non-Fiction tag conflicts" -ForegroundColor $(if ($conflicts.Count -gt 0) {"Red"} else {"Green"})
Write-Host ""

if ($conflicts.Count -eq 0) {
    Write-Host "No conflicts found. Library is clean!" -ForegroundColor Green
    exit 0
}

# Show what will be removed
$removalSummary = @{}
foreach ($book in $conflicts) {
    $nfTags = $book.tags | Where-Object {$_ -like "Non-Fiction*"}
    foreach ($tag in $nfTags) {
        if ($removalSummary.ContainsKey($tag)) {
            $removalSummary[$tag]++
        } else {
            $removalSummary[$tag] = 1
        }
    }
}

Write-Host "Non-Fiction tags to be removed:" -ForegroundColor Yellow
$removalSummary.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    Write-Host "  - $($_.Key): $($_.Value) books" -ForegroundColor White
}
Write-Host ""

if ($DryRun) {
    Write-Host "Sample books that would be affected:" -ForegroundColor Yellow
    $conflicts | Select-Object -First 10 id, title, @{Name="NonFictionTags"; Expression={($_.tags | Where-Object {$_ -like "Non-Fiction*"}) -join ", "}} |
        Format-Table -AutoSize

    Write-Host ""
    Write-Host "Run without -DryRun flag to apply changes" -ForegroundColor Cyan
    exit 0
}

# Apply changes
Write-Host "Removing Non-Fiction tags from Fiction books..." -ForegroundColor Yellow
$successCount = 0
$errorCount = 0

foreach ($book in $conflicts) {
    # Get current tags
    $fictionTags = $book.tags | Where-Object {$_ -notlike "Non-Fiction*"}

    # Create new tag list (Fiction tags only)
    $newTagList = $fictionTags -join ","

    try {
        # Update the book with only Fiction tags
        $result = calibredb set_metadata --field tags:"$newTagList" $book.id --library-path "$LibraryPath" 2>&1

        if ($LASTEXITCODE -eq 0) {
            $successCount++
            Write-Host "  OK Book $($book.id): $($book.title)" -ForegroundColor Green
        } else {
            $errorCount++
            Write-Host "  ERROR Book $($book.id): $($book.title) - $result" -ForegroundColor Red
        }
    } catch {
        $errorCount++
        Write-Host "  ERROR Book $($book.id): $($book.title) - $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Cleanup Complete!" -ForegroundColor Cyan
Write-Host "  Successfully updated: $successCount books" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "  Errors: $errorCount books" -ForegroundColor Red
}
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Run Audit-Calibre-Tags.ps1 to verify conflicts are resolved" -ForegroundColor White
Write-Host "  2. Review the consolidation report for next cleanup steps" -ForegroundColor White
