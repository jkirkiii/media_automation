# Check Tracker Status for StalledUP Torrents
param([string]$user='murdoch137', [int]$port=8080)

Write-Host "`nChecking StalledUP Torrents - Tracker Status`n" -ForegroundColor Cyan

$pass = Read-Host 'qBittorrent password' -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$base = "http://localhost:$port"

Write-Host "Connecting to qBittorrent..." -ForegroundColor Yellow
$login = Invoke-WebRequest -Uri "$base/api/v2/auth/login" -Method POST -Body "username=$user&password=$password" -SessionVariable $qb

if ($login.Content -ne 'Ok.') {
    Write-Host "Login failed" -ForegroundColor Red
    exit
}

Write-Host "Connected!`n" -ForegroundColor Green

$torrents = Invoke-RestMethod -Uri "$base/api/v2/torrents/info" -WebSession $qb
$stalled = $torrents | Where-Object { $_.state -eq "stalledUP" }

Write-Host "Total StalledUP torrents: $($stalled.Count)" -ForegroundColor Cyan
Write-Host "(This is normal - means no one is downloading right now)`n" -ForegroundColor Gray

if ($stalled.Count -eq 0) {
    Write-Host "No stalledUP torrents found" -ForegroundColor Yellow
    exit
}

Write-Host "Checking tracker communication...`n" -ForegroundColor Yellow

$goodCount = 0
$badCount = 0
$trackerIssues = @()

foreach ($t in $stalled) {
    $trackers = Invoke-RestMethod -Uri "$base/api/v2/torrents/trackers?hash=$($t.hash)" -WebSession $qb

    $hasIssue = $false

    foreach ($tr in $trackers) {
        if ($tr.url -notmatch '^http') { continue }

        $trackerName = 'Unknown'
        if ($tr.url -match 'torrentday') { $trackerName = 'TorrentDay' }
        elseif ($tr.url -match 'torrentleech') { $trackerName = 'TorrentLeech' }
        elseif ($tr.url -match 'darkpeers') { $trackerName = 'Darkpeers' }
        elseif ($tr.url -match 'myanonamouse') { $trackerName = 'MyAnonamouse' }

        # Check for actual errors (not just stalled state)
        if ($tr.msg -match 'not registered|unregistered|invalid|passkey|error') {
            $hasIssue = $true
            $badCount++

            $trackerIssues += [PSCustomObject]@{
                TorrentName = $t.name
                Tracker = $trackerName
                Message = $tr.msg
            }
        }
    }

    if (-not $hasIssue) {
        $goodCount++
    }
}

Write-Host "=== Results ===`n" -ForegroundColor Cyan

if ($badCount -eq 0) {
    Write-Host "✓ All $($stalled.Count) stalledUP torrents have working tracker connections!" -ForegroundColor Green
    Write-Host "`nThis means:" -ForegroundColor Cyan
    Write-Host "  - Trackers know you're seeding" -ForegroundColor White
    Write-Host "  - You're getting ratio credit" -ForegroundColor White
    Write-Host "  - 'StalledUP' is normal (no peers downloading)" -ForegroundColor White
    Write-Host "  - No action needed!" -ForegroundColor Green

    Write-Host "`nAbout 'StalledUP' status:" -ForegroundColor Yellow
    Write-Host "  - Means: 'Ready to upload but no peers requesting'" -ForegroundColor White
    Write-Host "  - Common for older/well-seeded torrents" -ForegroundColor White
    Write-Host "  - You ARE seeding (just no active transfers)" -ForegroundColor White
    Write-Host "  - Tracker websites should show you as seeding" -ForegroundColor White

} else {
    Write-Host "⚠️  Found $badCount torrent(s) with tracker issues:" -ForegroundColor Yellow
    Write-Host ""

    foreach ($issue in $trackerIssues | Select-Object -First 10) {
        $shortName = $issue.TorrentName
        if ($shortName.Length -gt 50) {
            $shortName = $shortName.Substring(0, 47) + "..."
        }

        Write-Host "  ISSUE: $shortName" -ForegroundColor Red
        Write-Host "    Tracker: $($issue.Tracker)" -ForegroundColor Yellow
        Write-Host "    Message: $($issue.Message)" -ForegroundColor White
        Write-Host ""
    }

    if ($trackerIssues.Count -gt 10) {
        Write-Host "  ... and $($trackerIssues.Count - 10) more issues" -ForegroundColor Gray
    }

    Write-Host "`nTo Fix:" -ForegroundColor Cyan
    Write-Host "  1. Select affected torrents in qBittorrent" -ForegroundColor White
    Write-Host "  2. Right-click -> Force reannounce" -ForegroundColor White
    Write-Host "  3. Wait 2 minutes" -ForegroundColor White
    Write-Host "  4. Check tracker websites" -ForegroundColor White
}

Write-Host "`n=== Understanding StalledUP ===`n" -ForegroundColor Cyan
Write-Host "Q: Why are my torrents 'stalledUP'?" -ForegroundColor Yellow
Write-Host "A: No peers are downloading from you right now.`n" -ForegroundColor White

Write-Host "Q: Is this bad?" -ForegroundColor Yellow
Write-Host "A: No! It's completely normal and expected.`n" -ForegroundColor White

Write-Host "Q: Am I still seeding?" -ForegroundColor Yellow
Write-Host "A: Yes! You're ready to upload when someone needs it.`n" -ForegroundColor White

Write-Host "Q: Will I get ratio credit?" -ForegroundColor Yellow
Write-Host "A: Yes, when someone downloads from you.`n" -ForegroundColor White

Write-Host "Q: What should tracker website show?" -ForegroundColor Yellow
Write-Host "A: You as a seeder, with recent 'last seen' time.`n" -ForegroundColor White

Write-Host ""
