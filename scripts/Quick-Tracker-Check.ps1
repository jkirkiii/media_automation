# Quick qBittorrent Tracker Status Check
param([string]$user='murdoch137', [int]$port=8080)

Write-Host "`nqBittorrent Tracker Check`n" -ForegroundColor Cyan

$pass = Read-Host 'qBittorrent password' -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$base = "http://localhost:$port"

Write-Host "Connecting..." -ForegroundColor Yellow
$login = Invoke-WebRequest -Uri "$base/api/v2/auth/login" -Method POST -Body "username=$user&password=$password" -SessionVariable qb

if ($login.Content -ne 'Ok.') {
    Write-Host "Login failed - check password" -ForegroundColor Red
    exit
}

Write-Host "Connected!`n" -ForegroundColor Green

$torrents = Invoke-RestMethod -Uri "$base/api/v2/torrents/info" -WebSession $qb
$seeding = $torrents | Where-Object { $_.state -match 'seeding|uploading' }

Write-Host "Total torrents: $($torrents.Count)" -ForegroundColor White
Write-Host "Currently seeding: $($seeding.Count)`n" -ForegroundColor Green

if ($seeding.Count -eq 0) {
    Write-Host "No torrents seeding" -ForegroundColor Yellow
    exit
}

Write-Host "Checking trackers...`n" -ForegroundColor Cyan

$issues = 0
$trackerCounts = @{}

foreach ($t in $seeding) {
    $trackers = Invoke-RestMethod -Uri "$base/api/v2/torrents/trackers?hash=$($t.hash)" -WebSession $qb

    foreach ($tr in $trackers) {
        if ($tr.url -notmatch '^http') { continue }

        $name = 'Unknown'
        if ($tr.url -match 'torrentday') { $name = 'TorrentDay' }
        elseif ($tr.url -match 'torrentleech') { $name = 'TorrentLeech' }
        elseif ($tr.url -match 'darkpeers') { $name = 'Darkpeers' }
        elseif ($tr.url -match 'myanonamouse') { $name = 'MyAnonamouse' }

        if (-not $trackerCounts.ContainsKey($name)) {
            $trackerCounts[$name] = @{Good=0; Bad=0}
        }

        if ($tr.msg -match 'error|failed|not registered|invalid|unregistered') {
            $issues++
            $trackerCounts[$name].Bad++

            $shortName = $t.name
            if ($shortName.Length -gt 50) {
                $shortName = $shortName.Substring(0, 47) + "..."
            }

            Write-Host "ISSUE: $shortName" -ForegroundColor Red
            Write-Host "  Tracker: $name" -ForegroundColor Yellow
            Write-Host "  Status: $($tr.status)" -ForegroundColor White
            Write-Host "  Message: $($tr.msg)`n" -ForegroundColor White
        } else {
            $trackerCounts[$name].Good++
        }
    }
}

Write-Host "`n=== Summary ===`n" -ForegroundColor Cyan

foreach ($tracker in $trackerCounts.Keys | Sort-Object) {
    $good = $trackerCounts[$tracker].Good
    $bad = $trackerCounts[$tracker].Bad

    if ($bad -gt 0) {
        Write-Host "$tracker : $good OK, $bad issues" -ForegroundColor Yellow
    } else {
        Write-Host "$tracker : $good OK" -ForegroundColor Green
    }
}

if ($issues -eq 0) {
    Write-Host "`nNo tracker issues found!" -ForegroundColor Green
} else {
    Write-Host "`nFound $issues issue(s)" -ForegroundColor Yellow
    Write-Host "`nTo fix:" -ForegroundColor Cyan
    Write-Host "1. In qBittorrent, select affected torrents" -ForegroundColor White
    Write-Host "2. Right-click -> Force reannounce" -ForegroundColor White
    Write-Host "3. Wait 2 minutes and check tracker websites" -ForegroundColor White
}

Write-Host ""
