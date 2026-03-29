$SonarrUrl = "http://localhost:8989"
$SonarrApiKey = ""
$headers = @{"X-Api-Key" = $SonarrApiKey}

Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Sonarr Setup Verification              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Get system status
$status = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/system/status" -Headers $headers
Write-Host "✓ Sonarr v$($status.version) - Running" -ForegroundColor Green

# Check series
$series = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/series" -Headers $headers
Write-Host "`n📺 TV Shows:" -ForegroundColor Cyan
Write-Host "   Total Shows: $($series.Count)" -ForegroundColor White

$monitored = ($series | Where-Object { $_.monitored -eq $true }).Count
$notMonitored = ($series | Where-Object { $_.monitored -eq $false }).Count
Write-Host "   Monitored: $monitored" -ForegroundColor Green
Write-Host "   Not Monitored: $notMonitored" -ForegroundColor Gray

# Check indexers
$indexers = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/indexer" -Headers $headers
Write-Host "`n🔍 Indexers:" -ForegroundColor Cyan
Write-Host "   Total: $($indexers.Count)" -ForegroundColor White
$indexers | ForEach-Object { Write-Host "   - $($_.name)" -ForegroundColor White }

# Check download client
$clients = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/downloadclient" -Headers $headers
Write-Host "`n⬇️  Download Clients:" -ForegroundColor Cyan
$clients | ForEach-Object { 
    $status = if ($_.enable) { "Enabled" } else { "Disabled" }
    Write-Host "   - $($_.name) [$status]" -ForegroundColor White
}

# Check root folders
$rootFolders = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/rootfolder" -Headers $headers
Write-Host "`n📁 Root Folders:" -ForegroundColor Cyan
$rootFolders | ForEach-Object {
    Write-Host "   - $($_.path)" -ForegroundColor White
    Write-Host "     Free Space: $([math]::Round($_.freeSpace / 1TB, 2)) TB" -ForegroundColor Gray
}

# Show monitoring status
Write-Host "`n📊 Monitoring Status:" -ForegroundColor Cyan
$futureOnly = ($series | Where-Object { $_.monitored -and $_.seasonFolder }).Count
Write-Host "   Shows set to monitor future episodes: ~$monitored" -ForegroundColor Green

# Next airing
$calendar = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/calendar?start=$(Get-Date -Format 'yyyy-MM-dd')&end=$((Get-Date).AddDays(7).ToString('yyyy-MM-dd'))" -Headers $headers
if ($calendar.Count -gt 0) {
    Write-Host "`n📅 Upcoming Episodes (Next 7 Days):" -ForegroundColor Cyan
    $calendar | Select-Object -First 5 | ForEach-Object {
        $airDate = ([DateTime]$_.airDateUtc).ToLocalTime().ToString('MM/dd HH:mm')
        Write-Host "   $airDate - $($_.series.title) - S$($_.seasonNumber.ToString('00'))E$($_.episodeNumber.ToString('00'))" -ForegroundColor White
    }
    if ($calendar.Count -gt 5) {
        Write-Host "   ... and $($calendar.Count - 5) more" -ForegroundColor Gray
    }
} else {
    Write-Host "`n📅 No upcoming episodes in next 7 days" -ForegroundColor Yellow
}

Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     Setup Complete - Ready to Use!        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════╝`n" -ForegroundColor Green
