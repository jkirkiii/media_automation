$SonarrUrl = "http://localhost:8989"
$SonarrApiKey = "332f7d21453b4225a85fc6852bdad7ee"
$headers = @{"X-Api-Key" = $SonarrApiKey; "Content-Type" = "application/json"}

Write-Host "`n=== Setting up Quality Profile ===`n" -ForegroundColor Cyan

Write-Host "Getting existing quality profiles..." -ForegroundColor Yellow
$profiles = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/qualityprofile" -Headers $headers

$conservativeProfile = $profiles | Where-Object { $_.name -eq "Conservative HD-1080p" }

if ($conservativeProfile) {
    Write-Host "Conservative HD-1080p profile already exists" -ForegroundColor Green
    Write-Host "  ID: $($conservativeProfile.id)" -ForegroundColor White
} else {
    Write-Host "Creating Conservative HD-1080p profile..." -ForegroundColor Yellow
    
    $newProfile = @{
        name = "Conservative HD-1080p"
        upgradeAllowed = $true
        cutoff = 3
        items = @(
            @{
                id = 0
                name = "Bluray-1080p"
                quality = @{ id = 7; name = "Bluray-1080p"; source = "bluray"; resolution = 1080 }
                items = @()
                allowed = $true
            }
            @{
                id = 0
                name = "WEBDL-1080p" 
                quality = @{ id = 3; name = "WEBDL-1080p"; source = "webdl"; resolution = 1080 }
                items = @()
                allowed = $true
            }
            @{
                id = 0
                name = "WEBRip-1080p"
                quality = @{ id = 5; name = "WEBRip-1080p"; source = "webrip"; resolution = 1080 }
                items = @()
                allowed = $true
            }
            @{
                id = 0
                name = "HDTV-1080p"
                quality = @{ id = 9; name = "HDTV-1080p"; source = "tv"; resolution = 1080 }
                items = @()
                allowed = $true
            }
        )
        minFormatScore = 0
        cutoffFormatScore = 0
        formatItems = @()
    } | ConvertTo-Json -Depth 10

    try {
        $result = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/qualityprofile" -Method POST -Headers $headers -Body $newProfile
        Write-Host "Profile created successfully!" -ForegroundColor Green
        Write-Host "  ID: $($result.id)" -ForegroundColor White
    } catch {
        Write-Host "Error creating profile: $_" -ForegroundColor Red
    }
}

Write-Host "`nCurrent Quality Profiles:" -ForegroundColor Cyan
$profiles = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/qualityprofile" -Headers $headers
$profiles | ForEach-Object { 
    $cutoffName = ($_.items | Where-Object { $_.quality.id -eq $_.cutoff }).quality.name
    Write-Host "  - $($_.name) (Cutoff: $cutoffName)" -ForegroundColor White
}

Write-Host "`n=== Done ===`n" -ForegroundColor Cyan
