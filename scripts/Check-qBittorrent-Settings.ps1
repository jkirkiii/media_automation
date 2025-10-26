# Check qBittorrent Network and Announce Settings
param([string]$user='murdoch137', [int]$port=8080)

Write-Host "`nqBittorrent Settings Check`n" -ForegroundColor Cyan

$pass = Read-Host 'qBittorrent password' -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$base = "http://localhost:$port"

$login = Invoke-WebRequest -Uri "$base/api/v2/auth/login" -Method POST -Body "username=$user&password=$password" -SessionVariable qb

if ($login.Content -ne 'Ok.') {
    Write-Host "Login failed" -ForegroundColor Red
    exit
}

Write-Host "Connected!`n" -ForegroundColor Green

# Get app preferences
$prefs = Invoke-RestMethod -Uri "$base/api/v2/app/preferences" -WebSession $qb

Write-Host "=== Network Settings ===" -ForegroundColor Cyan
Write-Host "Listen Port: $($prefs.listen_port)" -ForegroundColor White
Write-Host "UPnP Enabled: $($prefs.upnp)" -ForegroundColor White
$portType = if ($prefs.random_port) { 'Random' } else { 'Fixed' }
Write-Host "Connection Port: $portType" -ForegroundColor White

Write-Host "`n=== Announce Settings ===" -ForegroundColor Cyan
Write-Host "Max Active Downloads: $($prefs.max_active_downloads)" -ForegroundColor White
Write-Host "Max Active Uploads: $($prefs.max_active_uploads)" -ForegroundColor White
Write-Host "Max Active Torrents: $($prefs.max_active_torrents)" -ForegroundColor White

Write-Host "`n=== Proxy/VPN Settings ===" -ForegroundColor Cyan
$proxyType = if ($prefs.proxy_type -eq 0) { 'None' } else { $prefs.proxy_type }
Write-Host "Proxy Type: $proxyType" -ForegroundColor White

if ($prefs.proxy_type -ne 0) {
    Write-Host "Proxy IP: $($prefs.proxy_ip)" -ForegroundColor Yellow
    Write-Host "Proxy Port: $($prefs.proxy_port)" -ForegroundColor Yellow
}

Write-Host "`n=== Application Info ===" -ForegroundColor Cyan
$appInfo = Invoke-RestMethod -Uri "$base/api/v2/app/version" -WebSession $qb
Write-Host "qBittorrent Version: $appInfo" -ForegroundColor White

# Get transfer info
$transferInfo = Invoke-RestMethod -Uri "$base/api/v2/transfer/info" -WebSession $qb

Write-Host "`n=== Current Transfer Status ===" -ForegroundColor Cyan
Write-Host "Download Speed: $([math]::Round($transferInfo.dl_info_speed / 1MB, 2)) MB/s" -ForegroundColor White
Write-Host "Upload Speed: $([math]::Round($transferInfo.up_info_speed / 1MB, 2)) MB/s" -ForegroundColor White
Write-Host "Connection Status: $($transferInfo.connection_status)" -ForegroundColor $(if ($transferInfo.connection_status -eq 'connected') { 'Green' } else { 'Yellow' })

Write-Host "`n=== Recent Tracker Activity ===" -ForegroundColor Cyan

$torrents = Invoke-RestMethod -Uri "$base/api/v2/torrents/info" -WebSession $qb
$recentTorrent = $torrents | Select-Object -First 1

if ($recentTorrent) {
    $trackers = Invoke-RestMethod -Uri "$base/api/v2/torrents/trackers?hash=$($recentTorrent.hash)" -WebSession $qb

    foreach ($tracker in $trackers) {
        if ($tracker.url -match '^http') {
            $trackerName = 'Unknown'
            if ($tracker.url -match 'torrentday') { $trackerName = 'TorrentDay' }
            elseif ($tracker.url -match 'torrentleech') { $trackerName = 'TorrentLeech' }
            elseif ($tracker.url -match 'darkpeers') { $trackerName = 'Darkpeers' }
            elseif ($tracker.url -match 'myanonamouse') { $trackerName = 'MyAnonamouse' }

            $statusText = switch ($tracker.status) {
                0 { "Disabled" }
                1 { "Not contacted" }
                2 { "Working" }
                3 { "Updating" }
                4 { "Not working" }
                default { "Unknown ($($tracker.status))" }
            }

            $color = if ($tracker.status -eq 2) { 'Green' } elseif ($tracker.status -eq 1) { 'Yellow' } else { 'Red' }

            Write-Host "$trackerName : $statusText" -ForegroundColor $color
            if ($tracker.msg) {
                Write-Host "  Message: $($tracker.msg)" -ForegroundColor Gray
            }
        }
    }
}

Write-Host ""
