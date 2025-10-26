$SonarrUrl = "http://localhost:8989"
$SonarrApiKey = "332f7d21453b4225a85fc6852bdad7ee"
$headers = @{"X-Api-Key" = $SonarrApiKey}

Write-Host "`n=== Missing Episodes Report ===`n" -ForegroundColor Cyan

# Get all series
$series = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/series" -Headers $headers

# Get episodes marked as missing
$wanted = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/wanted/missing?pageSize=100" -Headers $headers

Write-Host "Total Series: $($series.Count)" -ForegroundColor White
Write-Host "Total Missing Episodes: $($wanted.totalRecords)" -ForegroundColor Yellow

if ($wanted.totalRecords -gt 0) {
    Write-Host "`nShows with Missing Episodes:" -ForegroundColor Cyan
    
    $missingByShow = $wanted.records | Group-Object -Property { $_.series.title } | Sort-Object Count -Descending
    
    foreach ($show in $missingByShow) {
        Write-Host "`n  $($show.Name) - $($show.Count) missing episodes" -ForegroundColor Yellow
        
        # Show first 5 missing episodes for this show
        $episodes = $show.Group | Select-Object -First 5
        foreach ($ep in $episodes) {
            Write-Host "    S$($ep.seasonNumber.ToString('00'))E$($ep.episodeNumber.ToString('00')) - $($ep.title)" -ForegroundColor Gray
        }
        
        if ($show.Count -gt 5) {
            Write-Host "    ... and $($show.Count - 5) more" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "`n=== How to Handle Missing Episodes ===" -ForegroundColor Cyan
    Write-Host "`nOption 1: Search Manually (Conservative)" -ForegroundColor Green
    Write-Host "  1. Go to http://localhost:8989" -ForegroundColor White
    Write-Host "  2. Series -> Click on show" -ForegroundColor White
    Write-Host "  3. Click season or episode" -ForegroundColor White
    Write-Host "  4. Click search icon" -ForegroundColor White
    Write-Host "  5. Review results and download manually" -ForegroundColor White
    
    Write-Host "`nOption 2: Automatic Search for Show (Aggressive)" -ForegroundColor Yellow
    Write-Host "  1. Go to show page" -ForegroundColor White
    Write-Host "  2. Click 'Search Monitored' button" -ForegroundColor White
    Write-Host "  3. Sonarr will search and auto-download ALL missing" -ForegroundColor White
    Write-Host "  WARNING: May trigger many downloads at once!" -ForegroundColor Red
    
    Write-Host "`nOption 3: Use Wanted -> Missing Page" -ForegroundColor Green
    Write-Host "  1. Go to Wanted -> Missing" -ForegroundColor White
    Write-Host "  2. See all missing episodes across all shows" -ForegroundColor White
    Write-Host "  3. Search individual episodes or batches" -ForegroundColor White
    
    Write-Host "`nRecommendation:" -ForegroundColor Cyan
    Write-Host "  - For shows you care about: Manual search specific episodes" -ForegroundColor White
    Write-Host "  - For complete series: Use 'Search Monitored' carefully" -ForegroundColor White
    Write-Host "  - Monitor your ratio before mass downloads!" -ForegroundColor Yellow
    
} else {
    Write-Host "`nNo missing episodes detected!" -ForegroundColor Green
    Write-Host "All monitored episodes are present." -ForegroundColor White
}

Write-Host "`n=== Recent Activity ===`n" -ForegroundColor Cyan

# Check recent history
$history = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/history?pageSize=10" -Headers $headers

if ($history.records.Count -gt 0) {
    Write-Host "Last 10 actions:" -ForegroundColor White
    foreach ($record in $history.records) {
        $date = ([DateTime]$record.date).ToLocalTime().ToString('MM/dd HH:mm')
        $eventType = $record.eventType
        $seriesTitle = $record.series.title
        $episode = "S$($record.episode.seasonNumber.ToString('00'))E$($record.episode.episodeNumber.ToString('00'))"
        
        $color = switch ($eventType) {
            "grabbed" { "Yellow" }
            "downloadFolderImported" { "Green" }
            "downloadFailed" { "Red" }
            default { "White" }
        }
        
        Write-Host "  [$date] $eventType - $seriesTitle $episode" -ForegroundColor $color
    }
} else {
    Write-Host "No recent activity" -ForegroundColor Gray
}

Write-Host "`n=== Current Queue ===`n" -ForegroundColor Cyan

# Check download queue
$queue = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/queue" -Headers $headers

if ($queue.records.Count -gt 0) {
    Write-Host "Active downloads: $($queue.records.Count)" -ForegroundColor Yellow
    foreach ($item in $queue.records) {
        $progress = [math]::Round($item.sizeleft / $item.size * 100, 1)
        Write-Host "  $($item.series.title) - S$($item.episode.seasonNumber.ToString('00'))E$($item.episode.episodeNumber.ToString('00'))" -ForegroundColor White
        Write-Host "    Status: $($item.status) - $progress% remaining" -ForegroundColor Gray
    }
} else {
    Write-Host "No active downloads" -ForegroundColor Green
}

Write-Host ""
