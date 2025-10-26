$SonarrUrl = "http://localhost:8989"
$ApiKey = "332f7d21453b4225a85fc6852bdad7ee"
$headers = @{"X-Api-Key" = $ApiKey; "Content-Type" = "application/json"}

Write-Host "`n=== Sonarr Configuration ===`n" -ForegroundColor Cyan

Write-Host "Testing connection..." -ForegroundColor Yellow
$status = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/system/status" -Headers $headers
Write-Host "Connected to Sonarr v$($status.version)`n" -ForegroundColor Green

Write-Host "Adding root folder..." -ForegroundColor Yellow
$rootFolders = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/rootfolder" -Headers $headers
$exists = $rootFolders | Where-Object { $_.path -eq "A:\Media\TV Shows" }
if ($exists) {
    Write-Host "Root folder already exists`n" -ForegroundColor Green
} else {
    $body = @{ path = "A:\Media\TV Shows" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$SonarrUrl/api/v3/rootfolder" -Method POST -Headers $headers -Body $body | Out-Null
    Write-Host "Root folder added`n" -ForegroundColor Green
}

Write-Host "Configuring naming..." -ForegroundColor Yellow
$naming = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/config/naming" -Headers $headers
$naming.renameEpisodes = $true
$naming.standardEpisodeFormat = "{Series Title} - S{season:00}E{episode:00} - {Episode Title}"
$naming.seriesFolderFormat = "{Series Title} ({Series Year})"
$naming.seasonFolderFormat = "Season {season:00}"
$body = $naming | ConvertTo-Json -Depth 10
Invoke-RestMethod -Uri "$SonarrUrl/api/v3/config/naming/$($naming.id)" -Method PUT -Headers $headers -Body $body | Out-Null
Write-Host "Naming configured`n" -ForegroundColor Green

Write-Host "=== Done ===" -ForegroundColor Cyan
