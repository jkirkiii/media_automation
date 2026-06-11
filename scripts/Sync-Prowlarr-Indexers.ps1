# Sync-Prowlarr-Indexers.ps1
# Triggers Prowlarr -> Sonarr application sync and reports the indexers Sonarr ends up with.
# Loads all credentials from config.ps1 (never hardcode keys here).

. (Join-Path $PSScriptRoot "..\config.ps1")

$prowlarrHeaders = @{"X-Api-Key" = $ProwlarrApiKey}
$sonarrHeaders   = @{"X-Api-Key" = $SonarrApiKey}

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
    $indexers = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/indexer" -Headers $sonarrHeaders
    Write-Host "Sonarr now has $($indexers.Count) indexers" -ForegroundColor Green

    if ($indexers.Count -gt 0) {
        Write-Host "`nIndexers:" -ForegroundColor Cyan
        $indexers | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor White }
    }
} else {
    Write-Host "Sonarr app not found in Prowlarr" -ForegroundColor Red
}
