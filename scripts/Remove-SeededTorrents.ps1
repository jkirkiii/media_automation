# Remove-SeededTorrents.ps1
# Removes torrents that have met the minimum seed time from qBittorrent,
# deleting their files from the Downloads folder.
#
# Safety checks before any deletion:
#   - Seed time must meet MinDays threshold
#   - File must have hardlink count > 1 (Media copy exists)
#   - Ebook categories are skipped by default
#   - Incomplete/still-downloading torrents are always skipped
#
# Usage:
#   .\Remove-SeededTorrents.ps1                  # dry run (default, no changes)
#   .\Remove-SeededTorrents.ps1 -Execute         # actually remove torrents
#   .\Remove-SeededTorrents.ps1 -MinDays 14      # stricter threshold
#   .\Remove-SeededTorrents.ps1 -Execute -Category tv-sonarr   # one category only

param(
    [string]$qBitUrl   = "",
    [string]$Username  = "",
    [string]$Password  = "",
    [int]$MinDays      = 10,
    [string]$Category  = "",
    [switch]$Execute
)

$DryRun = -not $Execute

# ---------------------------------------------------------------------------
# Categories to always skip (low space impact, worth keeping seeded)
# ---------------------------------------------------------------------------
$SkipCategories = @("books", "audiobooks", "music")

# ---------------------------------------------------------------------------
# Load credentials
# ---------------------------------------------------------------------------
$repoRoot   = Split-Path $PSScriptRoot -Parent
$configFile = Join-Path $repoRoot "config.ps1"
if (Test-Path $configFile) {
    . $configFile
    if (-not $qBitUrl)  { $qBitUrl  = $qBittorrentUrl }
    if (-not $Username) { $Username = $qBittorrentUsername }
    if (-not $Password) { $Password = $qBittorrentPassword }
}
if (-not $qBitUrl) { $qBitUrl = "http://localhost:8080" }

# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  Remove-SeededTorrents.ps1  [DRY RUN - no changes]" -ForegroundColor Cyan
} else {
    Write-Host "  Remove-SeededTorrents.ps1  [EXECUTE MODE]" -ForegroundColor Yellow
}
Write-Host "  Threshold : >= $MinDays days seeded" -ForegroundColor Cyan
Write-Host "  Skipping  : $($SkipCategories -join ', ')" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

try {
    Invoke-WebRequest -Uri "$qBitUrl/api/v2/auth/login" `
        -Method POST `
        -Body "username=$Username&password=$Password" `
        -ContentType "application/x-www-form-urlencoded" `
        -SessionVariable qbSession `
        -UseBasicParsing `
        -ErrorAction Stop | Out-Null
    Write-Host "[OK] Connected to qBittorrent at $qBitUrl" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Cannot reach qBittorrent at $qBitUrl" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Fetch all torrents
# ---------------------------------------------------------------------------
$apiUrl   = "$qBitUrl/api/v2/torrents/info?filter=all"
if ($Category) { $apiUrl += "&category=$Category" }
$torrents = Invoke-RestMethod -Uri $apiUrl -WebSession $qbSession

$now = [int][double]::Parse((Get-Date -UFormat %s))
Write-Host ("[INFO] Fetched " + $torrents.Count + " torrents from qBittorrent") -ForegroundColor Gray
Write-Host ""

# ---------------------------------------------------------------------------
# Evaluate each torrent
# ---------------------------------------------------------------------------
$eligible    = [System.Collections.ArrayList]@()
$skipped     = [System.Collections.ArrayList]@()

foreach ($t in $torrents) {
    $seedDays = [math]::Round($t.seeding_time / 86400, 1)
    $sizeGB   = [math]::Round($t.size / 1GB, 2)

    # --- Skip: below minimum seed time
    if ($seedDays -lt $MinDays) {
        $null = $skipped.Add([PSCustomObject]@{
            Name   = $t.name; Reason = "seed time " + $seedDays + "d < " + $MinDays + "d"
            SizeGB = $sizeGB; Hash = $t.hash
        })
        continue
    }

    # --- Skip: protected categories
    if ($SkipCategories -contains $t.category) {
        $null = $skipped.Add([PSCustomObject]@{
            Name   = $t.name; Reason = "protected category (" + $t.category + ")"
            SizeGB = $sizeGB; Hash = $t.hash
        })
        continue
    }

    # --- Skip: still downloading or queued
    $activeStates = @("downloading", "stalledDL", "checkingDL", "queuedDL", "allocating", "metaDL")
    if ($activeStates -contains $t.state) {
        $null = $skipped.Add([PSCustomObject]@{
            Name   = $t.name; Reason = "active state: " + $t.state
            SizeGB = $sizeGB; Hash = $t.hash
        })
        continue
    }

    # --- Safety check: verify hardlink count on the content path
    $contentPath = $t.content_path
    if (-not $contentPath) { $contentPath = Join-Path $t.save_path $t.name }

    $hardlinkOk  = $false
    $hardlinkMsg = "path not found"

    if (Test-Path $contentPath) {
        # For single-file torrents check the file directly.
        # For multi-file torrents check all files and require ALL to be hardlinked.
        $files = Get-ChildItem -Path $contentPath -Recurse -File -ErrorAction SilentlyContinue
        if (-not $files) {
            # content_path IS the file
            $files = @(Get-Item $contentPath -ErrorAction SilentlyContinue)
        }

        if ($files) {
            $notLinked = $files | Where-Object {
                # fsutil hardlink list returns all paths; line count > 1 means hardlinked
                $links = & fsutil hardlink list $_.FullName 2>$null
                ($links | Measure-Object -Line).Lines -le 1
            }

            if ($notLinked) {
                $hardlinkMsg = "NOT hardlinked: " + (($notLinked | Select-Object -First 3 -ExpandProperty Name) -join ", ")
            } else {
                $hardlinkOk  = $true
                $hardlinkMsg = "hardlinked (" + $files.Count + " file(s))"
            }
        } else {
            $hardlinkMsg = "no files found at path"
        }
    }

    if (-not $hardlinkOk) {
        $null = $skipped.Add([PSCustomObject]@{
            Name   = $t.name
            Reason = "hardlink check FAILED - " + $hardlinkMsg
            SizeGB = $sizeGB
            Hash   = $t.hash
        })
        continue
    }

    # Passed all checks - eligible for removal
    $null = $eligible.Add([PSCustomObject]@{
        Name         = $t.name
        Category     = $t.category
        SeedDays     = $seedDays
        Ratio        = [math]::Round($t.ratio, 2)
        SizeGB       = $sizeGB
        HardlinkInfo = $hardlinkMsg
        ContentPath  = $contentPath
        Hash         = $t.hash
    })
}

# ---------------------------------------------------------------------------
# Report: skipped torrents
# ---------------------------------------------------------------------------
$skipFailed   = @($skipped | Where-Object { $_.Reason -like "hardlink check FAILED*" })
$skipOther    = @($skipped | Where-Object { $_.Reason -notlike "hardlink check FAILED*" })

if ($skipFailed.Count -gt 0) {
    Write-Host "--- SKIPPED: hardlink check failed (files may not be in Media library) ---" -ForegroundColor Red
    $skipFailed | Format-Table Name, Reason, SizeGB -AutoSize
}

Write-Host ("--- Skipped " + $skipOther.Count + " torrents (below threshold, protected category, or active) ---") -ForegroundColor DarkGray

# ---------------------------------------------------------------------------
# Report: eligible torrents
# ---------------------------------------------------------------------------
$eligibleGB = [math]::Round(($eligible | Measure-Object SizeGB -Sum).Sum, 2)

Write-Host ""
Write-Host ("--- Eligible for removal: " + $eligible.Count + " torrents   " + $eligibleGB + " GB ---") -ForegroundColor Green
Write-Host ""

if ($eligible.Count -eq 0) {
    Write-Host "Nothing to remove." -ForegroundColor Yellow
    exit 0
}

# Group by category for a quick summary
$eligible | Group-Object Category | Sort-Object { ($_.Group | Measure-Object SizeGB -Sum).Sum } -Descending |
    ForEach-Object {
        $gb = [math]::Round(($_.Group | Measure-Object SizeGB -Sum).Sum, 2)
        Write-Host ("  " + $_.Name + ": " + $_.Count + " torrents   " + $gb + " GB")
    }

Write-Host ""

if ($DryRun) {
    Write-Host "--- DRY RUN: the following would be removed ---" -ForegroundColor Yellow
    $eligible | Format-Table Name, Category, SeedDays, Ratio, SizeGB -AutoSize
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  DRY RUN complete. No changes made." -ForegroundColor Cyan
    Write-Host ("  " + $eligible.Count + " torrents   " + $eligibleGB + " GB would be freed") -ForegroundColor Cyan
    Write-Host "  Re-run with -Execute to apply." -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# ---------------------------------------------------------------------------
# Execute: remove torrents in batches
# ---------------------------------------------------------------------------
Write-Host "--- Removing torrents ---" -ForegroundColor Yellow
Write-Host ""

$removed   = 0
$failed    = 0
$freedGB   = 0.0

# Build hash list and remove in one API call per batch of 100
$batches = for ($i = 0; $i -lt $eligible.Count; $i += 100) {
    ,@($eligible[$i..([math]::Min($i + 99, $eligible.Count - 1))])
}

foreach ($batch in $batches) {
    $hashes   = ($batch | Select-Object -ExpandProperty Hash) -join "|"
    $batchGB  = [math]::Round(($batch | Measure-Object SizeGB -Sum).Sum, 2)
    $body     = "hashes=" + $hashes + "&deleteFiles=true"

    try {
        Invoke-WebRequest -Uri "$qBitUrl/api/v2/torrents/delete" `
            -Method POST `
            -Body $body `
            -ContentType "application/x-www-form-urlencoded" `
            -WebSession $qbSession `
            -UseBasicParsing `
            -ErrorAction Stop | Out-Null

        $removed  += $batch.Count
        $freedGB  += $batchGB
        Write-Host ("[OK] Removed batch of " + $batch.Count + " torrents (" + $batchGB + " GB)") -ForegroundColor Green
    } catch {
        $failed += $batch.Count
        Write-Host ("[FAIL] Batch removal failed: " + $_.Exception.Message) -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Removal complete" -ForegroundColor Cyan
Write-Host ("  Removed : " + $removed + " torrents") -ForegroundColor Green
Write-Host ("  Freed   : " + [math]::Round($freedGB, 2) + " GB (once OS reclaims blocks)") -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host ("  Failed  : " + $failed + " torrents - check qBittorrent logs") -ForegroundColor Red
}
if ($skipFailed.Count -gt 0) {
    Write-Host ("  WARNING : " + $skipFailed.Count + " torrents skipped - hardlink check failed") -ForegroundColor Yellow
    Write-Host "            Review these manually before removing." -ForegroundColor Yellow
}
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
