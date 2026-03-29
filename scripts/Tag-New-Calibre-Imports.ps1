# Tag-New-Calibre-Imports.ps1
# Automatically tags newly imported books based on metadata and patterns
# Run this after importing new books to apply standardized tags

param(
    [string]$LibraryPath = "A:\Media\Calibre",
    [string]$MappingFile = ".\configs\calibre_tag_mapping.ps1",
    [int]$DaysBack = 7,  # Process books added in last N days
    [switch]$Interactive,  # Prompt for confirmation on each book
    [switch]$DryRun,
    [switch]$StopCalibreWeb  # Automatically stop Calibre-Web if running
)

Write-Host "Calibre New Import Tagger" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Check if Calibre-Web is running
$calibreWebRunning = Get-Process | Where-Object {$_.ProcessName -like "*cps*"}

if ($calibreWebRunning -and -not $DryRun) {
    Write-Host "WARNING: Calibre-Web is currently running" -ForegroundColor Yellow
    Write-Host "The library database is locked and cannot be modified." -ForegroundColor Yellow
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

# Load mapping configuration
if (Test-Path $MappingFile) {
    Write-Host "Loading tag mappings from: $MappingFile" -ForegroundColor Yellow
    . $MappingFile
    Write-Host "Loaded tag patterns and rules" -ForegroundColor Green
} else {
    Write-Host "WARNING: Mapping file not found, using basic rules only" -ForegroundColor Yellow
}
Write-Host ""

# Function to run calibredb commands
function Invoke-CalibreDB {
    param(
        [string]$Arguments,
        [switch]$AsJson
    )

    $calibredbPath = "calibredb"
    $fullArgs = "$Arguments --library-path `"$LibraryPath`""

    try {
        $result = Invoke-Expression "$calibredbPath $fullArgs" 2>&1
        if ($AsJson -and $result) {
            return $result | ConvertFrom-Json
        }
        return $result
    } catch {
        Write-Host "Error running calibredb: $_" -ForegroundColor Red
        return $null
    }
}

# Get recently added books
Write-Host "Finding books added in the last $DaysBack days..." -ForegroundColor Yellow

$cutoffDate = (Get-Date).AddDays(-$DaysBack).ToString("yyyy-MM-dd")
$searchFilter = "timestamp:>=$cutoffDate"

$books = Invoke-CalibreDB -Arguments "list --fields id,title,authors,tags,comments,publisher,series --for-machine --search `"$searchFilter`"" -AsJson

if (-not $books -or $books.Count -eq 0) {
    Write-Host "No new books found in the last $DaysBack days" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($books.Count) recently added books" -ForegroundColor Green
Write-Host ""

# Statistics
$stats = @{
    TotalBooks = $books.Count
    BooksTagged = 0
    TagsAdded = 0
    BooksSkipped = 0
}

# Process each book
Write-Host "Processing books..." -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "[DRY RUN MODE - No changes will be made]" -ForegroundColor Cyan
}
Write-Host ""

foreach ($book in $books) {
    $bookId = $book.id
    $bookTitle = $book.title
    $bookAuthors = $book.authors -join ", "
    $currentTags = if ($book.tags) { @($book.tags) } else { @() }
    $comments = if ($book.comments) { $book.comments } else { "" }
    $series = if ($book.series) { $book.series } else { "" }

    Write-Host "[$bookId] $bookTitle" -ForegroundColor White
    Write-Host "  Authors: $bookAuthors" -ForegroundColor Gray
    Write-Host "  Current tags: $(if ($currentTags.Count -gt 0) { $currentTags -join ', ' } else { '(none)' })" -ForegroundColor Gray

    # Suggested tags
    $suggestedTags = @()

    # 1. Apply tag mappings to existing malformed tags
    $cleanedTags = @()
    foreach ($tag in $currentTags) {
        if ($script:TagMappings -and $script:TagMappings.ContainsKey($tag)) {
            $mappedTag = $script:TagMappings[$tag]
            if (-not [string]::IsNullOrWhiteSpace($mappedTag) -and $cleanedTags -notcontains $mappedTag) {
                $cleanedTags += $mappedTag
                Write-Host "  - Mapping tag: '$tag' -> '$mappedTag'" -ForegroundColor Yellow
            }
        }
        elseif ($cleanedTags -notcontains $tag) {
            $cleanedTags += $tag
        }
    }

    # 2. Suggest tags based on keywords in title/description
    if ($script:AutoTagPatterns -and $script:AutoTagPatterns.Keywords) {
        $searchText = ($bookTitle + " " + $comments).ToLower()

        foreach ($genre in $script:AutoTagPatterns.Keywords.Keys) {
            $keywords = $script:AutoTagPatterns.Keywords[$genre]

            foreach ($keyword in $keywords) {
                if ($searchText -match "\b$keyword\b") {
                    if ($suggestedTags -notcontains $genre -and $cleanedTags -notcontains $genre) {
                        $suggestedTags += $genre
                        Write-Host "  - Keyword match '$keyword' suggests: $genre" -ForegroundColor Cyan
                        break
                    }
                }
            }
        }
    }

    # 3. Suggest tags based on series
    if ($script:AutoTagPatterns -and $script:AutoTagPatterns.Series -and $series) {
        if ($script:AutoTagPatterns.Series.ContainsKey($series)) {
            $seriesTag = $script:AutoTagPatterns.Series[$series]
            if ($suggestedTags -notcontains $seriesTag -and $cleanedTags -notcontains $seriesTag) {
                $suggestedTags += $seriesTag
                Write-Host "  - Series '$series' suggests: $seriesTag" -ForegroundColor Cyan
            }
        }
    }

    # 4. Ensure we have at least a Fiction/Non-Fiction base tag
    $hasFictionTag = $cleanedTags -match "^Fiction" -or $suggestedTags -match "^Fiction"
    $hasNonFictionTag = $cleanedTags -match "^Non-Fiction" -or $suggestedTags -match "^Non-Fiction"

    if (-not $hasFictionTag -and -not $hasNonFictionTag -and $suggestedTags.Count -eq 0) {
        Write-Host "  - No genre detected - manual review recommended" -ForegroundColor Yellow
    }

    # Combine cleaned existing tags with suggestions
    $proposedTags = $cleanedTags + $suggestedTags | Select-Object -Unique

    # Check if we need to make changes
    $needsUpdate = $false

    if ($currentTags.Count -ne $proposedTags.Count) {
        $needsUpdate = $true
    } else {
        foreach ($tag in $proposedTags) {
            if ($currentTags -notcontains $tag) {
                $needsUpdate = $true
                break
            }
        }
    }

    # Apply changes
    if ($needsUpdate) {
        # Check max tags limit
        if ($script:MaxTagsPerBook -and $proposedTags.Count -gt $script:MaxTagsPerBook) {
            Write-Host "  WARNING: Proposed tags ($($proposedTags.Count)) exceeds recommended max ($script:MaxTagsPerBook)" -ForegroundColor Yellow
        }

        Write-Host "  Proposed tags: $($proposedTags -join ', ')" -ForegroundColor Green

        $shouldApply = $true

        # Interactive mode - ask for confirmation
        if ($Interactive) {
            Write-Host "  Apply these tags? (y/n/e to edit): " -NoNewline -ForegroundColor Yellow
            $response = Read-Host

            if ($response -eq 'e') {
                Write-Host "  Enter tags (comma-separated): " -NoNewline
                $manualTags = Read-Host
                $proposedTags = $manualTags -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
            elseif ($response -ne 'y') {
                $shouldApply = $false
                $stats.BooksSkipped++
                Write-Host "  Skipped" -ForegroundColor Gray
            }
        }

        if ($shouldApply) {
            if (-not $DryRun) {
                $tagsArg = $proposedTags -join ","
                try {
                    $result = Invoke-CalibreDB -Arguments "set_metadata $bookId --field tags:`"$tagsArg`""

                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✓ Tags updated" -ForegroundColor Green
                        $stats.BooksTagged++
                        $stats.TagsAdded += ($proposedTags.Count - $currentTags.Count)
                    } else {
                        Write-Host "  ERROR: Failed to update tags" -ForegroundColor Red
                    }
                } catch {
                    Write-Host "  ERROR: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "  [DRY RUN] Would update tags" -ForegroundColor Cyan
                $stats.BooksTagged++
            }
        }
    } else {
        Write-Host "  No changes needed" -ForegroundColor Gray
        $stats.BooksSkipped++
    }

    Write-Host ""
}

# Display summary
Write-Host "Tagging Complete!" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "  Books processed: $($stats.TotalBooks)" -ForegroundColor White
Write-Host "  Books tagged: $($stats.BooksTagged)" -ForegroundColor Green
Write-Host "  Books skipped: $($stats.BooksSkipped)" -ForegroundColor Gray
Write-Host "  Tags added: $($stats.TagsAdded)" -ForegroundColor Green
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN] No changes were made" -ForegroundColor Cyan
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Yellow
}

if ($stats.BooksSkipped -gt 0) {
    Write-Host "Tip: Review skipped books manually for optimal tagging" -ForegroundColor Yellow
}
Write-Host ""
