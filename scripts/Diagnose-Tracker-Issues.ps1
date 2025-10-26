# Diagnose Tracker Communication Issues
# Checks qBittorrent torrents for tracker announce problems

param(
    [string]$qBitHost = "localhost",
    [int]$qBitPort = 8080,
    [string]$qBitUsername = "murdoch137"
)

Write-Host "`n=== qBittorrent Tracker Diagnostics ===`n" -ForegroundColor Cyan

# Prompt for password
$securePassword = Read-Host "Enter qBittorrent password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$qBitPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$baseUrl = "http://${qBitHost}:${qBitPort}"

Write-Host "Connecting to qBittorrent..." -ForegroundColor Yellow

# Login to qBittorrent
try {
    $loginBody = "username=$qBitUsername&password=$qBitPassword"
    $loginResponse = Invoke-WebRequest -Uri "$baseUrl/api/v2/auth/login" -Method POST -Body $loginBody -SessionVariable qbtSession

    if ($loginResponse.Content -eq "Ok.") {
        Write-Host "✓ Connected to qBittorrent" -ForegroundColor Green
    } else {
        Write-Host "✗ Login failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Connection failed: $_" -ForegroundColor Red
    exit 1
}

# Get all torrents
Write-Host "`nFetching torrents..." -ForegroundColor Yellow
$torrents = (Invoke-RestMethod -Uri "$baseUrl/api/v2/torrents/info" -WebSession $qbtSession)

Write-Host "Total torrents: $($torrents.Count)" -ForegroundColor White

# Get torrents in tv-sonarr category or seeding
$seedingTorrents = $torrents | Where-Object { $_.state -match "seeding|uploading" }

Write-Host "Currently seeding: $($seedingTorrents.Count)" -ForegroundColor Green

# Analyze by tracker
Write-Host "`n=== Tracker Breakdown ===`n" -ForegroundColor Cyan

$trackerIssues = @()

foreach ($torrent in $seedingTorrents) {
    # Get tracker info for this torrent
    $trackers = (Invoke-RestMethod -Uri "$baseUrl/api/v2/torrents/trackers?hash=$($torrent.hash)" -WebSession $qbtSession)

    foreach ($tracker in $trackers) {
        if ($tracker.url -notmatch "^http" -or $tracker.url -match "dht://") {
            continue  # Skip DHT and invalid entries
        }

        # Determine tracker name
        $trackerName = "Unknown"
        if ($tracker.url -match "torrentday") { $trackerName = "TorrentDay" }
        elseif ($tracker.url -match "torrentleech") { $trackerName = "TorrentLeech" }
        elseif ($tracker.url -match "darkpeers") { $trackerName = "Darkpeers" }
        elseif ($tracker.url -match "myanonamouse") { $trackerName = "MyAnonamouse" }

        # Check tracker status
        $status = $tracker.status
        $msg = $tracker.msg

        $issue = [PSCustomObject]@{
            TorrentName = $torrent.name
            Tracker = $trackerName
            Status = $status
            Message = $msg
            LastAnnounce = if ($tracker.num_peers -ge 0) { "Success" } else { "Failed" }
            Seeders = $tracker.num_seeds
            Peers = $tracker.num_peers
        }

        # Flag issues
        if ($status -ne 2 -or $msg -match "error|failed|not registered|unregistered") {
            $trackerIssues += $issue
        }
    }
}

# Display tracker issues
if ($trackerIssues.Count -gt 0) {
    Write-Host "⚠️  Found $($trackerIssues.Count) torrents with tracker issues:" -ForegroundColor Yellow
    Write-Host ""

    $byTracker = $trackerIssues | Group-Object -Property Tracker

    foreach ($group in $byTracker) {
        Write-Host "  $($group.Name): $($group.Count) issue(s)" -ForegroundColor Red

        $group.Group | Select-Object -First 5 | ForEach-Object {
            Write-Host "    - $($_.TorrentName)" -ForegroundColor Gray
            Write-Host "      Status: $($_.Status) | Message: $($_.Message)" -ForegroundColor DarkGray
        }

        if ($group.Count -gt 5) {
            Write-Host "    ... and $($group.Count - 5) more" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
} else {
    Write-Host "✓ No tracker issues detected!" -ForegroundColor Green
}

# Check qBittorrent settings
Write-Host "`n=== qBittorrent Connection Settings ===`n" -ForegroundColor Cyan

$preferences = (Invoke-RestMethod -Uri "$baseUrl/api/v2/app/preferences" -WebSession $qbtSession)

Write-Host "Listening Port: $($preferences.listen_port)" -ForegroundColor White

if ($preferences.upnp) {
    Write-Host "UPnP: Enabled ✓" -ForegroundColor Green
} else {
    Write-Host "UPnP: Disabled (may cause connectivity issues)" -ForegroundColor Yellow
}

if ($preferences.random_port) {
    Write-Host "Random Port: Enabled" -ForegroundColor White
} else {
    Write-Host "Random Port: Disabled (using fixed port)" -ForegroundColor White
}

Write-Host "`nConnection Protocol: $($preferences.connection_protocol)" -ForegroundColor White

# Check if VPN is affecting connection
Write-Host "`n=== VPN Status ===`n" -ForegroundColor Cyan

try {
    $publicIP = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json").ip
    Write-Host "Public IP: $publicIP" -ForegroundColor White

    # Simple VPN check (NordVPN IPs usually don't match local ISP)
    if ($publicIP -match "^192\.168\.|^10\.|^172\.") {
        Write-Host "⚠️  Showing local IP - VPN may not be active!" -ForegroundColor Red
    } else {
        Write-Host "✓ Using external IP (VPN likely active)" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not check public IP" -ForegroundColor Yellow
}

# Recommendations
Write-Host "`n=== Common Solutions ===`n" -ForegroundColor Cyan

Write-Host "1. Force Re-announce:" -ForegroundColor Yellow
Write-Host "   - Right-click torrent in qBittorrent" -ForegroundColor White
Write-Host "   - Select 'Force reannounce'" -ForegroundColor White
Write-Host "   - Wait 1-2 minutes and check tracker website" -ForegroundColor White

Write-Host "`n2. Update Tracker URL (if passkey changed):" -ForegroundColor Yellow
Write-Host "   - Go to tracker website" -ForegroundColor White
Write-Host "   - Get your current announce URL (with passkey)" -ForegroundColor White
Write-Host "   - Right-click torrent → Edit trackers" -ForegroundColor White
Write-Host "   - Replace old URL with new one" -ForegroundColor White

Write-Host "`n3. Check Port Forwarding:" -ForegroundColor Yellow
Write-Host "   - Tools → Options → Connection" -ForegroundColor White
Write-Host "   - Enable 'Use UPnP / NAT-PMP'" -ForegroundColor White
Write-Host "   - Or forward port manually in router" -ForegroundColor White

Write-Host "`n4. Verify VPN Split Tunneling:" -ForegroundColor Yellow
Write-Host "   - NordVPN settings" -ForegroundColor White
Write-Host "   - Ensure qBittorrent is routing through VPN" -ForegroundColor White
Write-Host "   - Ensure tracker communication is allowed" -ForegroundColor White

Write-Host "`n5. Re-download .torrent file:" -ForegroundColor Yellow
Write-Host "   - If 'Not registered' error" -ForegroundColor White
Write-Host "   - Download fresh .torrent from tracker" -ForegroundColor White
Write-Host "   - Right-click → Set location to existing files" -ForegroundColor White
Write-Host "   - qBittorrent will recheck and update tracker" -ForegroundColor White

Write-Host ""
