$SonarrUrl = "http://localhost:8989"
$SonarrApiKey = "332f7d21453b4225a85fc6852bdad7ee"
$headers = @{"X-Api-Key" = $SonarrApiKey}

Write-Host "`n=== Sonarr Setup Verification ===`n" -ForegroundColor Cyan

$status = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/system/status" -Headers $headers
Write-Host "Sonarr v$($status.version) - Running" -ForegroundColor Green

$series = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/series" -Headers $headers
Write-Host "`nTV Shows Imported: $($series.Count)" -ForegroundColor Cyan
$monitored = ($series | Where-Object { $_.monitored -eq $true }).Count
Write-Host "  Monitored for new episodes: $monitored" -ForegroundColor Green
Write-Host "  Library only: $($series.Count - $monitored)" -ForegroundColor Gray

$indexers = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/indexer" -Headers $headers
Write-Host "`nIndexers: $($indexers.Count)" -ForegroundColor Cyan
$indexers | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor White }

$clients = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/downloadclient" -Headers $headers
Write-Host "`nDownload Clients: $($clients.Count)" -ForegroundColor Cyan
$clients | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor White }

$rootFolders = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/rootfolder" -Headers $headers
Write-Host "`nRoot Folder:" -ForegroundColor Cyan
$rootFolders | ForEach-Object {
    Write-Host "  $($_.path)" -ForegroundColor White
    Write-Host "  Free: $([math]::Round($_.freeSpace / 1TB, 2)) TB" -ForegroundColor Gray
}

$calendar = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/calendar?start=$(Get-Date -Format 'yyyy-MM-dd')&end=$((Get-Date).AddDays(7).ToString('yyyy-MM-dd'))" -Headers $headers
Write-Host "`nUpcoming Episodes (Next 7 Days): $($calendar.Count)" -ForegroundColor Cyan
if ($calendar.Count -gt 0) {
    $calendar | Select-Object -First 5 | ForEach-Object {
        $airDate = ([DateTime]$_.airDateUtc).ToLocalTime().ToString('MM/dd HH:mm')
        Write-Host "  $airDate - $($_.series.title) S$($_.seasonNumber.ToString('00'))E$($_.episodeNumber.ToString('00'))" -ForegroundColor White
    }
}

Write-Host "`n=== Setup Complete! ===`n" -ForegroundColor Green
