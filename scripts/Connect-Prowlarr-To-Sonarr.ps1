$ProwlarrUrl = "http://localhost:9696"
$ProwlarrApiKey = "44e45c10103a4ba6959d0430c12cb73a"
$SonarrUrl = "http://localhost:8989"
$SonarrApiKey = "332f7d21453b4225a85fc6852bdad7ee"

$headers = @{"X-Api-Key" = $ProwlarrApiKey; "Content-Type" = "application/json"}

Write-Host "`n=== Connecting Prowlarr to Sonarr ===`n" -ForegroundColor Cyan

Write-Host "Checking existing apps in Prowlarr..." -ForegroundColor Yellow
$apps = Invoke-RestMethod -Uri "$ProwlarrUrl/api/v1/applications" -Headers $headers
$sonarrApp = $apps | Where-Object { $_.name -eq "Sonarr" }

if ($sonarrApp) {
    Write-Host "Sonarr already connected to Prowlarr" -ForegroundColor Green
} else {
    Write-Host "Adding Sonarr to Prowlarr..." -ForegroundColor Yellow

    $body = @{
        name = "Sonarr"
        syncLevel = "fullSync"
        implementation = "Sonarr"
        configContract = "SonarrSettings"
        fields = @(
            @{ name = "prowlarrUrl"; value = $ProwlarrUrl }
            @{ name = "baseUrl"; value = $SonarrUrl }
            @{ name = "apiKey"; value = $SonarrApiKey }
            @{ name = "syncCategories"; value = @(5000, 5030, 5040, 5045) }
        )
        tags = @()
    } | ConvertTo-Json -Depth 10

    Invoke-RestMethod -Uri "$ProwlarrUrl/api/v1/applications" -Method POST -Headers $headers -Body $body | Out-Null
    Write-Host "Sonarr connected to Prowlarr!" -ForegroundColor Green
}

Write-Host "`nVerifying indexers synced to Sonarr..." -ForegroundColor Yellow
$sonarrHeaders = @{"X-Api-Key" = $SonarrApiKey}
$indexers = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/indexer" -Headers $sonarrHeaders
Write-Host "Sonarr now has $($indexers.Count) indexers" -ForegroundColor Green

Write-Host "`n=== Done ===" -ForegroundColor Cyan
