$SonarrUrl = "http://localhost:8989"
$SonarrApiKey = "332f7d21453b4225a85fc6852bdad7ee"
$headers = @{"X-Api-Key" = $SonarrApiKey; "Content-Type" = "application/json"}

Write-Host "`n=== Configuring HD-1080p Profile ===`n" -ForegroundColor Cyan

$profiles = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/qualityprofile" -Headers $headers
$hd1080p = $profiles | Where-Object { $_.name -eq "HD-1080p" }

if ($hd1080p) {
    Write-Host "Found HD-1080p profile (ID: $($hd1080p.id))" -ForegroundColor Green
    Write-Host "`nCurrent settings:" -ForegroundColor Cyan
    Write-Host "  Upgrade Allowed: $($hd1080p.upgradeAllowed)" -ForegroundColor White
    Write-Host "  Cutoff: $($hd1080p.cutoff)" -ForegroundColor White
    
    Write-Host "`nConfiguring for conservative 1080p WEB-DL preference..." -ForegroundColor Yellow
    
    # Set cutoff to WEBDL-1080p (ID 3)
    $hd1080p.upgradeAllowed = $true
    $hd1080p.cutoff = 3  # WEBDL-1080p
    
    # Ensure 1080p qualities are enabled, 720p and below disabled
    foreach ($item in $hd1080p.items) {
        if ($item.quality) {
            $qualityName = $item.quality.name
            $resolution = $item.quality.resolution
            
            # Enable all 1080p, disable everything else
            if ($resolution -eq 1080) {
                $item.allowed = $true
                Write-Host "  Enabled: $qualityName" -ForegroundColor Green
            } else {
                $item.allowed = $false
                Write-Host "  Disabled: $qualityName" -ForegroundColor Gray
            }
        }
    }
    
    $body = $hd1080p | ConvertTo-Json -Depth 10
    
    try {
        Invoke-RestMethod -Uri "$SonarrUrl/api/v3/qualityprofile/$($hd1080p.id)" -Method PUT -Headers $headers -Body $body | Out-Null
        Write-Host "`nProfile configured successfully!" -ForegroundColor Green
        Write-Host "  Strategy: Conservative" -ForegroundColor White
        Write-Host "  Preferred: 1080p WEB-DL" -ForegroundColor White
        Write-Host "  Cutoff: WEBDL-1080p (stops upgrading here)" -ForegroundColor White
        Write-Host "  Will upgrade: HDTV/WEBRip to WEB-DL, but not WEB-DL to Bluray" -ForegroundColor Yellow
    } catch {
        Write-Host "Error updating profile: $_" -ForegroundColor Red
    }
} else {
    Write-Host "HD-1080p profile not found" -ForegroundColor Red
}

Write-Host "`n=== Done ===`n" -ForegroundColor Cyan
