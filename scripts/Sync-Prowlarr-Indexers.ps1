$ProwlarrUrl = "http://localhost:9696"
$ProwlarrApiKey = "44e45c10103a4ba6959d0430c12cb73a"
$SonarrApiKey = "332f7d21453b4225a85fc6852bdad7ee"

$prowlarrHeaders = @{"X-Api-Key" = $ProwlarrApiKey}
$sonarrHeaders = @{"X-Api-Key" = $SonarrApiKey}

Write-Host "`nGetting Sonarr app ID from Prowlarr..." -ForegroundColor Yellow
$apps = Invoke-RestMethod -Uri "$ProwlarrUrl/api/v1/applications" -Headers $prowlarrHeaders
$sonarrApp = $apps | Where-Object { $_.name -eq "Sonarr" }

if ($sonarrApp) {
    Write-Host "Found Sonarr app (ID: $($sonarrApp.id))" -ForegroundColor Green

    Write-Host "Triggering sync..." -ForegroundColor Yellow
    $body = @{ name = "ApplicationSync"; applicationIds = @($sonarrApp.id) } | ConvertTo-Json
    Invoke-RestMethod -Uri "$ProwlarrUrl/api/v1/command" -Method POST -Headers $prowlarrHeaders -Body $body | Out-Null

    Start-Sleep -Seconds 3

    Write-Host "Checking indexers in Sonarr..." -ForegroundColor Yellow
    $indexers = Invoke-RestMethod -Uri "http://localhost:8989/api/v3/indexer" -Headers $sonarrHeaders
    Write-Host "Sonarr now has $($indexers.Count) indexers" -ForegroundColor Green

    if ($indexers.Count -gt 0) {
        Write-Host "`nIndexers:" -ForegroundColor Cyan
        $indexers | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor White }
    }
} else {
    Write-Host "Sonarr app not found in Prowlarr" -ForegroundColor Red
}
