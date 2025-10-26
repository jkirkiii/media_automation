# Simple Tracker Status Check
# Focuses on just showing tracker communication issues

param(
    [string]$qBitHost = "localhost",
    [int]$qBitPort = 8080,
    [string]$qBitUsername = "murdoch137"
)

Write-Host "`n=== Simple Tracker Status Check ===`n" -ForegroundColor Cyan

# Prompt for password
$securePassword = Read-Host "Enter qBittorrent password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$qBitPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$baseUrl = "http://${qBitHost}:${qBitPort}"

# Login
Write-Host "Connecting to qBittorrent at $baseUrl..." -ForegroundColor Yellow

try {
    $loginBody = "username=$qBitUsername&password=$qBitPassword"
    $loginResponse = Invoke-WebRequest -Uri "$baseUrl/api/v2/auth/login" -Method POST -Body $loginBody -SessionVariable qbtSession -ErrorAction Stop

    if ($loginResponse.Content -eq "Ok.") {
        Write-Host "✓ Connected successfully`n" -ForegroundColor Green
    } else {
        Write-Host "✗ Login failed - check username/password" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPossible issues:" -ForegroundColor Yellow
    Write-Host "  - qBittorrent not running" -ForegroundColor White
    Write-Host "  - WebUI not enabled (Tools → Options → Web UI)" -ForegroundColor White
    Write-Host "  - Wrong port (default is 8080)" -ForegroundColor White
    Write-Host "  - Wrong username/password" -ForegroundColor White
    exit 1
}

# Get torrents
Write-Host "Fetching torrent list..." -ForegroundColor Yellow

try {
    $torrents = Invoke-RestMethod -Uri "$baseUrl/api/v2/torrents/info" -WebSession $qbtSession
    Write-Host "✓ Found $($torrents.Count) total torrents`n" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to get torrents: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Filter seeding torrents
$seedingTorrents = $torrents | Where-Object { $_.state -match "seeding|uploading" }
Write-Host "Currently seeding: $($seedingTorrents.Count) torrents`n" -ForegroundColor Cyan

if ($seedingTorrents.Count -eq 0) {
    Write-Host "No torrents currently seeding." -ForegroundColor Yellow
    exit 0
}

# Check each seeding torrent's tracker status
Write-Host "=== Checking Tracker Status ===`n" -ForegroundColor Cyan

$issueCount = 0
$trackerStats = @{}

foreach ($torrent in $seedingTorrents) {
    try {
        $trackers = Invoke-RestMethod -Uri "$baseUrl/api/v2/torrents/trackers?hash=$($torrent.hash)" -WebSession $qbtSession

        $hasIssue = $false
        $trackerInfo = @()

        foreach ($tracker in $trackers) {
            # Skip DHT and other non-HTTP trackers
            if ($tracker.url -notmatch "^https?://") {
                continue
            }

            # Identify tracker
            $trackerName = "Unknown"
            if ($tracker.url -match "torrentday") { $trackerName = "TorrentDay" }
            elseif ($tracker.url -match "torrentleech") { $trackerName = "TorrentLeech" }
            elseif ($tracker.url -match "darkpeers") { $trackerName = "Darkpeers" }
            elseif ($tracker.url -match "myanonamouse") { $trackerName = "MyAnonamouse" }

            # Check for issues
            # Status: 0=disabled, 1=not contacted, 2=working, 3=updating, 4=not working
            if ($tracker.status -eq 4 -or $tracker.msg -match "error|failed|not registered|unregistered|invalid") {
                $hasIssue = $true
                $issueCount++

                # Track issues by tracker
                if (-not $trackerStats.ContainsKey($trackerName)) {
                    $trackerStats[$trackerName] = @{ Working = 0; Issues = 0 }
                }
                $trackerStats[$trackerName].Issues++

                Write-Host "⚠️  ISSUE: $($torrent.name -replace '^(.{50}).*','$1...')" -ForegroundColor Red
                Write-Host "   Tracker: $trackerName" -ForegroundColor Yellow
                Write-Host "   Status: $($tracker.status)" -ForegroundColor White
                Write-Host "   Message: $($tracker.msg)" -ForegroundColor White
                Write-Host ""
            } else {
                # Working tracker
                if (-not $trackerStats.ContainsKey($trackerName)) {
                    $trackerStats[$trackerName] = @{ Working = 0; Issues = 0 }
                }
                $trackerStats[$trackerName].Working++
            }
        }
    } catch {
        Write-Host "Error checking torrent: $($torrent.name)" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n=== Summary ===`n" -ForegroundColor Cyan

if ($issueCount -eq 0) {
    Write-Host "✓ All seeding torrents have working tracker connections!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Found $issueCount torrent(s) with tracker issues" -ForegroundColor Yellow
}

Write-Host "`nTracker Status:" -ForegroundColor Cyan
foreach ($tracker in $trackerStats.Keys | Sort-Object) {
    $working = $trackerStats[$tracker].Working
    $issues = $trackerStats[$tracker].Issues
    $total = $working + $issues

    if ($issues -gt 0) {
        Write-Host "  $tracker : $working working, $issues with issues (out of $total)" -ForegroundColor Yellow
    } else {
        Write-Host "  $tracker : $working working, $issues issues ✓" -ForegroundColor Green
    }
}

# Recommendations
if ($issueCount -gt 0) {
    Write-Host "`n=== Recommended Actions ===`n" -ForegroundColor Cyan

    Write-Host "1. Force Reannounce (Try This First):" -ForegroundColor Yellow
    Write-Host "   - In qBittorrent, select all torrents with issues" -ForegroundColor White
    Write-Host "   - Right-click → 'Force reannounce'" -ForegroundColor White
    Write-Host "   - Wait 2 minutes and check tracker websites" -ForegroundColor White

    Write-Host "`n2. If 'Not registered' or 'Invalid passkey' error:" -ForegroundColor Yellow
    Write-Host "   - Go to tracker website" -ForegroundColor White
    Write-Host "   - Get fresh announce URL from your profile" -ForegroundColor White
    Write-Host "   - Right-click torrent → Edit trackers → Update URL" -ForegroundColor White

    Write-Host "`n3. If errors persist:" -ForegroundColor Yellow
    Write-Host "   - See: docs/FIXING_TRACKER_SEEDING_ISSUES.md" -ForegroundColor White
    Write-Host "   - Check tracker website status" -ForegroundColor White
    Write-Host "   - Verify VPN isn't blocking tracker communication" -ForegroundColor White
}

Write-Host ""
