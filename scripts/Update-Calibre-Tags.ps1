# Update-Calibre-Tags.ps1
# Applies tag mapping rules to migrate existing tags to standardized taxonomy
# Supports dry-run mode and creates backup before applying changes

param(
    [string]$LibraryPath = "A:\Media\Calibre",
    [string]$MappingFile = ".\configs\calibre_tag_mapping.ps1",
    [switch]$DryRun,
    [switch]$NoBackup,
    [int]$BatchSize = 50,
    [string]$Filter = "",  # Optional: calibredb search expression to limit scope
    [switch]$StopCalibreWeb  # Automatically stop Calibre-Web if running
)

Write-Host "Calibre Tag Update Tool" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
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

# Check if mapping file exists
if (-not (Test-Path $MappingFile)) {
    Write-Host "ERROR: Mapping file not found: $MappingFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please create the mapping file by copying the template:" -ForegroundColor Yellow
    Write-Host "  Copy-Item .\configs\calibre_tag_mapping.ps1.template .\configs\calibre_tag_mapping.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "Then edit calibre_tag_mapping.ps1 to define your tag mappings" -ForegroundColor Yellow
    exit 1
}

# Load mapping configuration
Write-Host "Loading tag mappings from: $MappingFile" -ForegroundColor Yellow
. $MappingFile

if (-not $script:TagMappings) {
    Write-Host "ERROR: No tag mappings defined in $MappingFile" -ForegroundColor Red
    exit 1
}

Write-Host "Loaded $($script:TagMappings.Count) tag mapping rules" -ForegroundColor Green
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

# Backup metadata.db before making changes
if (-not $NoBackup -and -not $DryRun) {
    Write-Host "Creating backup of metadata.db..." -ForegroundColor Yellow
    $backupPath = "$LibraryPath\metadata.db.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    try {
        Copy-Item "$LibraryPath\metadata.db" $backupPath -Force
        Write-Host "Backup created: $backupPath" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "WARNING: Failed to create backup: $_" -ForegroundColor Red
        Write-Host "Continue anyway? (y/n): " -NoNewline
        $response = Read-Host
        if ($response -ne 'y') {
            exit 1
        }
    }
}

# Get books to process
Write-Host "Retrieving books from library..." -ForegroundColor Yellow

$searchArgs = "list --fields id,title,authors,tags --for-machine"
if ($Filter) {
    $searchArgs += " --search `"$Filter`""
}

$books = Invoke-CalibreDB -Arguments $searchArgs -AsJson

if (-not $books) {
    Write-Host "No books found in library" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($books.Count) books to process" -ForegroundColor Green
Write-Host ""

# Statistics
$stats = @{
    TotalBooks = $books.Count
    BooksModified = 0
    TagsRemoved = 0
    TagsAdded = 0
    TagsRenamed = 0
    Errors = 0
}

# Process books
Write-Host "Processing books..." -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "[DRY RUN MODE - No changes will be made]" -ForegroundColor Cyan
}
Write-Host ""

$progressCount = 0
$changes = @()

foreach ($book in $books) {
    $progressCount++

    if ($progressCount % 50 -eq 0) {
        Write-Host "  Progress: $progressCount / $($books.Count)" -ForegroundColor Gray
    }

    $bookId = $book.id
    $bookTitle = $book.title
    $bookAuthors = $book.authors -join ", "
    $currentTags = $book.tags

    if (-not $currentTags -or $currentTags.Count -eq 0) {
        continue  # Skip books without tags
    }

    # Calculate new tags based on mappings
    $newTags = @()
    $modified = $false
    $bookChanges = @()

    foreach ($tag in $currentTags) {
        if ($script:TagMappings.ContainsKey($tag)) {
            $newTag = $script:TagMappings[$tag]

            if ([string]::IsNullOrWhiteSpace($newTag)) {
                # Tag should be removed
                $bookChanges += "  - REMOVE: '$tag'"
                $stats.TagsRemoved++
                $modified = $true
            }
            elseif ($newTag -ne $tag) {
                # Tag should be renamed
                $bookChanges += "  - RENAME: '$tag' -> '$newTag'"
                if ($newTags -notcontains $newTag) {
                    $newTags += $newTag
                }
                $stats.TagsRenamed++
                $modified = $true
            }
            else {
                # Keep tag as-is
                if ($newTags -notcontains $tag) {
                    $newTags += $tag
                }
            }
        }
        else {
            # No mapping - keep original tag
            if ($newTags -notcontains $tag) {
                $newTags += $tag
            }
        }
    }

    # Apply changes if book was modified
    if ($modified) {
        $stats.BooksModified++

        $changeRecord = [PSCustomObject]@{
            ID = $bookId
            Title = $bookTitle
            Authors = $bookAuthors
            OldTags = ($currentTags -join ", ")
            NewTags = ($newTags -join ", ")
            Changes = ($bookChanges -join "`n")
        }
        $changes += $changeRecord

        Write-Host "[$bookId] $bookTitle by $bookAuthors" -ForegroundColor White
        foreach ($change in $bookChanges) {
            Write-Host $change -ForegroundColor Yellow
        }

        # Apply changes to Calibre (unless dry run)
        if (-not $DryRun) {
            $tagsArg = if ($newTags.Count -gt 0) { $newTags -join "," } else { "" }

            try {
                $result = Invoke-CalibreDB -Arguments "set_metadata $bookId --field tags:`"$tagsArg`""

                if ($LASTEXITCODE -ne 0) {
                    Write-Host "    ERROR: Failed to update book $bookId" -ForegroundColor Red
                    $stats.Errors++
                }
            } catch {
                Write-Host "    ERROR: $_" -ForegroundColor Red
                $stats.Errors++
            }
        }
        Write-Host ""
    }
}

# Save change log
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$changeLogPath = ".\data\calibre_tag_updates_$timestamp.csv"

if (-not (Test-Path ".\data")) {
    New-Item -ItemType Directory -Path ".\data" -Force | Out-Null
}

$changes | Export-Csv -Path $changeLogPath -NoTypeInformation
Write-Host "Change log saved to: $changeLogPath" -ForegroundColor Green
Write-Host ""

# Display summary
Write-Host "Update Complete!" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "  Total books processed: $($stats.TotalBooks)" -ForegroundColor White
Write-Host "  Books modified: $($stats.BooksModified)" -ForegroundColor $(if ($stats.BooksModified -gt 0) { "Green" } else { "Gray" })
Write-Host "  Tags removed: $($stats.TagsRemoved)" -ForegroundColor $(if ($stats.TagsRemoved -gt 0) { "Yellow" } else { "Gray" })
Write-Host "  Tags renamed: $($stats.TagsRenamed)" -ForegroundColor $(if ($stats.TagsRenamed -gt 0) { "Yellow" } else { "Gray" })
Write-Host "  Errors: $($stats.Errors)" -ForegroundColor $(if ($stats.Errors -gt 0) { "Red" } else { "Gray" })
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN] No changes were made to the library" -ForegroundColor Cyan
    Write-Host "Run without -DryRun to apply these changes" -ForegroundColor Yellow
}
else {
    Write-Host "Changes have been applied to the Calibre library" -ForegroundColor Green
    if (-not $NoBackup) {
        Write-Host "Backup available at: $backupPath" -ForegroundColor Green
    }
}
Write-Host ""
