# Audit-Calibre-Tags.ps1
# Analyzes current tags in Calibre library and generates reports
# Helps identify cleanup opportunities before applying standard taxonomy

param(
    [string]$LibraryPath = "A:\Media\Calibre",
    [string]$OutputPath = ".\data\calibre_tag_audit",
    [switch]$StopCalibreWeb  # Automatically stop Calibre-Web if running
)

Write-Host "Calibre Tag Audit Tool" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""

# Check if Calibre-Web is running
$calibreWebRunning = Get-Process | Where-Object {$_.ProcessName -like "*cps*"}

if ($calibreWebRunning) {
    Write-Host "WARNING: Calibre-Web is currently running" -ForegroundColor Yellow
    Write-Host "The library database is locked and cannot be accessed directly." -ForegroundColor Yellow
    Write-Host ""

    if ($StopCalibreWeb) {
        Write-Host "Stopping Calibre-Web..." -ForegroundColor Yellow
        & ".\scripts\Stop-CalibreWeb-And-Tunnel.ps1"
        Start-Sleep -Seconds 2
        Write-Host "Calibre-Web stopped" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "Options:" -ForegroundColor White
        Write-Host "  1. Stop Calibre-Web manually: .\scripts\Stop-CalibreWeb-And-Tunnel.ps1" -ForegroundColor White
        Write-Host "  2. Run this script with -StopCalibreWeb flag" -ForegroundColor White
        Write-Host "  3. Press 's' to stop Calibre-Web now" -ForegroundColor White
        Write-Host "  4. Press 'q' to quit" -ForegroundColor White
        Write-Host ""
        Write-Host "Choice: " -NoNewline
        $choice = Read-Host

        if ($choice -eq 's') {
            Write-Host "Stopping Calibre-Web..." -ForegroundColor Yellow
            & ".\scripts\Stop-CalibreWeb-And-Tunnel.ps1"
            Start-Sleep -Seconds 2
            Write-Host "Calibre-Web stopped" -ForegroundColor Green
            Write-Host ""
        } else {
            Write-Host "Exiting. Please stop Calibre-Web and try again." -ForegroundColor Red
            exit 1
        }
    }
}

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

# Function to run calibredb commands
function Invoke-CalibreDB {
    param([string]$Arguments)

    $calibredbPath = "calibredb"
    $fullArgs = "$Arguments --library-path `"$LibraryPath`""

    try {
        $result = Invoke-Expression "$calibredbPath $fullArgs" 2>&1

        # Check for error indicating library is locked
        if ($result -match "Another calibre program.*is running") {
            Write-Host "ERROR: Calibre library is locked by another process" -ForegroundColor Red
            Write-Host "Please ensure Calibre-Web and Calibre Desktop are closed" -ForegroundColor Red
            return $null
        }

        return $result
    } catch {
        Write-Host "Error running calibredb: $_" -ForegroundColor Red
        return $null
    }
}

Write-Host "Step 1: Extracting all tags from library..." -ForegroundColor Yellow

# Get all books with their IDs, titles, authors, and tags
$booksJson = Invoke-CalibreDB "list --fields id,title,authors,tags --for-machine"

if (-not $booksJson) {
    Write-Host "Failed to retrieve books from Calibre library" -ForegroundColor Red
    exit 1
}

# Parse JSON
$books = $booksJson | ConvertFrom-Json

Write-Host "Found $($books.Count) books in library" -ForegroundColor Green
Write-Host ""

# Analyze tags
Write-Host "Step 2: Analyzing tags..." -ForegroundColor Yellow

$tagStats = @{}
$booksWithoutTags = @()
$booksWithManyTags = @()
$allUniqueTags = @{}

foreach ($book in $books) {
    $bookTags = $book.tags

    if (-not $bookTags -or $bookTags.Count -eq 0) {
        $booksWithoutTags += $book
        continue
    }

    # Count tags per book
    if ($bookTags.Count -gt 5) {
        $booksWithManyTags += [PSCustomObject]@{
            ID = $book.id
            Title = $book.title
            Authors = $book.authors -join ", "
            TagCount = $bookTags.Count
            Tags = $bookTags -join ", "
        }
    }

    # Count tag frequency
    foreach ($tag in $bookTags) {
        if ($tagStats.ContainsKey($tag)) {
            $tagStats[$tag]++
        } else {
            $tagStats[$tag] = 1
        }
        $allUniqueTags[$tag] = $true
    }
}

Write-Host "Analysis complete!" -ForegroundColor Green
Write-Host ""

# Generate reports
Write-Host "Step 3: Generating reports..." -ForegroundColor Yellow

# Report 1: Tag frequency (sorted by count)
$tagFrequency = $tagStats.GetEnumerator() |
    Sort-Object Value -Descending |
    Select-Object @{Name="Tag"; Expression={$_.Key}},
                  @{Name="BookCount"; Expression={$_.Value}},
                  @{Name="Percentage"; Expression={[math]::Round(($_.Value / $books.Count) * 100, 2)}}

$frequencyReport = $OutputPath + "\tag_frequency.csv"
$tagFrequency | Export-Csv -Path $frequencyReport -NoTypeInformation
Write-Host "  - Tag frequency report: $frequencyReport" -ForegroundColor Green

# Report 2: Unique tags (alphabetical)
$uniqueTagsReport = $OutputPath + "\all_unique_tags.txt"
$allUniqueTags.Keys | Sort-Object | Out-File -FilePath $uniqueTagsReport
Write-Host "  - Unique tags list: $uniqueTagsReport" -ForegroundColor Green

# Report 3: Books without tags
$noTagsReport = $OutputPath + "\books_without_tags.csv"
$booksWithoutTags |
    Select-Object @{Name="ID"; Expression={$_.id}},
                  @{Name="Title"; Expression={$_.title}},
                  @{Name="Authors"; Expression={$_.authors -join ", "}} |
    Export-Csv -Path $noTagsReport -NoTypeInformation
Write-Host "  - Books without tags: $noTagsReport" -ForegroundColor Green

# Report 4: Books with too many tags (>5)
$manyTagsReport = $OutputPath + "\books_with_many_tags.csv"
$booksWithManyTags | Export-Csv -Path $manyTagsReport -NoTypeInformation
Write-Host "  - Books with >5 tags: $manyTagsReport" -ForegroundColor Green

# Report 5: Potential duplicate tags (case-insensitive, similar spelling)
$potentialDuplicates = @()
$tagList = $allUniqueTags.Keys | Sort-Object

for ($i = 0; $i -lt $tagList.Count; $i++) {
    $tag1 = $tagList[$i]
    $tag1Lower = $tag1.ToLower() -replace '[^a-z0-9]', ''

    for ($j = $i + 1; $j -lt $tagList.Count; $j++) {
        $tag2 = $tagList[$j]
        $tag2Lower = $tag2.ToLower() -replace '[^a-z0-9]', ''

        # Check for exact match (case-insensitive) or very similar
        if ($tag1Lower -eq $tag2Lower) {
            $potentialDuplicates += [PSCustomObject]@{
                Tag1 = $tag1
                Tag1Count = $tagStats[$tag1]
                Tag2 = $tag2
                Tag2Count = $tagStats[$tag2]
                Reason = "Case variation"
            }
        }
        # Check for common variations (plural, hyphen, etc.)
        elseif ($tag1Lower -eq $tag2Lower + 's' -or $tag1Lower + 's' -eq $tag2Lower) {
            $potentialDuplicates += [PSCustomObject]@{
                Tag1 = $tag1
                Tag1Count = $tagStats[$tag1]
                Tag2 = $tag2
                Tag2Count = $tagStats[$tag2]
                Reason = "Plural variation"
            }
        }
    }
}

$duplicatesReport = $OutputPath + "\potential_duplicate_tags.csv"
$potentialDuplicates | Export-Csv -Path $duplicatesReport -NoTypeInformation
Write-Host "  - Potential duplicates: $duplicatesReport" -ForegroundColor Green

# Report 6: Summary statistics
$summaryReport = $OutputPath + "\summary.txt"
$summary = @"
Calibre Library Tag Audit Summary
==================================
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Library Path: $LibraryPath

OVERVIEW
--------
Total Books: $($books.Count)
Total Unique Tags: $($allUniqueTags.Count)
Books Without Tags: $($booksWithoutTags.Count) ($([math]::Round(($booksWithoutTags.Count / $books.Count) * 100, 2))%)
Books With >5 Tags: $($booksWithManyTags.Count) ($([math]::Round(($booksWithManyTags.Count / $books.Count) * 100, 2))%)
Potential Duplicate Tags: $($potentialDuplicates.Count)

TAG STATISTICS
--------------
Average Tags Per Book: $([math]::Round(($tagStats.Values | Measure-Object -Sum).Sum / $books.Count, 2))
Most Used Tag: $($tagFrequency[0].Tag) ($($tagFrequency[0].BookCount) books)
Least Used Tags: $(($tagFrequency | Where-Object {$_.BookCount -eq 1}).Count) tags used only once

TOP 20 MOST USED TAGS
---------------------
$($tagFrequency | Select-Object -First 20 | ForEach-Object { "  $($_.Tag): $($_.BookCount) books ($($_.Percentage)%)" } | Out-String)

RECOMMENDATIONS
---------------
1. Review potential duplicate tags in: $duplicatesReport
2. Consider adding tags to $($booksWithoutTags.Count) untagged books
3. Review books with >5 tags for over-tagging
4. Compare current tags against standard taxonomy in: configs\calibre_standard_tags.txt

NEXT STEPS
----------
1. Review all reports in: $OutputPath
2. Decide on tag consolidation strategy
3. Use Create-Calibre-Tag-Mapping.ps1 to create migration rules
4. Use Update-Calibre-Tags.ps1 to apply changes
"@

$summary | Out-File -FilePath $summaryReport
Write-Host "  - Summary report: $summaryReport" -ForegroundColor Green

Write-Host ""
Write-Host "Audit Complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "  Total books: $($books.Count)" -ForegroundColor White
Write-Host "  Unique tags: $($allUniqueTags.Count)" -ForegroundColor White
Write-Host "  Books without tags: $($booksWithoutTags.Count)" -ForegroundColor Yellow
Write-Host "  Books with >5 tags: $($booksWithManyTags.Count)" -ForegroundColor Yellow
Write-Host "  Potential duplicates: $($potentialDuplicates.Count)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Review the detailed reports in: $OutputPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: Review summary.txt and potential_duplicate_tags.csv" -ForegroundColor White
