# Check-Radarr-Language-Settings.ps1
# Checks current language profile configuration in Radarr

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiKey,

    [Parameter(Mandatory=$false)]
    [string]$RadarrUrl = "http://localhost:7878"
)

# Load config if not provided
if (-not $ApiKey) {
    $configPath = Join-Path $PSScriptRoot "..\config.ps1"
    if (Test-Path $configPath) {
        . $configPath
        $ApiKey = $RadarrApiKey
        Write-Host "[INFO] Loaded credentials from config.ps1" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] No API key provided" -ForegroundColor Red
        exit 1
    }
}

$headers = @{
    "X-Api-Key" = $ApiKey
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "RADARR LANGUAGE SETTINGS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check language profiles
Write-Host "[1/2] Language Profiles:" -ForegroundColor Yellow
try {
    $langProfiles = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/languageprofile" -Headers $headers

    foreach ($profile in $langProfiles) {
        Write-Host "`n  Profile: $($profile.name)" -ForegroundColor Cyan
        Write-Host "    ID: $($profile.id)" -ForegroundColor Gray
        Write-Host "    Upgrade Allowed: $($profile.upgradeAllowed)" -ForegroundColor Gray

        $languages = $profile.languages | Where-Object { $_.allowed -eq $true } | ForEach-Object { $_.language.name }
        Write-Host "    Allowed Languages: $($languages -join ', ')" -ForegroundColor Gray

        $cutoff = ($profile.languages | Where-Object { $_.language.id -eq $profile.cutoff }).language.name
        Write-Host "    Cutoff Language: $cutoff" -ForegroundColor Gray
    }
} catch {
    Write-Host "    [ERROR] Failed to get language profiles: $($_.Exception.Message)" -ForegroundColor Red
}

# Check quality profiles and their language settings
Write-Host "`n[2/2] Quality Profiles and Language Settings:" -ForegroundColor Yellow
try {
    $qualityProfiles = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/qualityprofile" -Headers $headers

    foreach ($qProfile in $qualityProfiles) {
        Write-Host "`n  Quality Profile: $($qProfile.name)" -ForegroundColor Cyan
        Write-Host "    ID: $($qProfile.id)" -ForegroundColor Gray

        # Get the language profile for this quality profile
        $langProfileId = $qProfile.language.id
        $langProfile = $langProfiles | Where-Object { $_.id -eq $langProfileId }

        if ($langProfile) {
            Write-Host "    Language Profile: $($langProfile.name)" -ForegroundColor Gray
            $allowedLangs = $langProfile.languages | Where-Object { $_.allowed -eq $true } | ForEach-Object { $_.language.name }
            Write-Host "    Allowed Languages: $($allowedLangs -join ', ')" -ForegroundColor $(if ($allowedLangs.Count -gt 1) { "Yellow" } else { "Green" })
        } else {
            Write-Host "    Language Profile: Unknown (ID: $langProfileId)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "    [ERROR] Failed to get quality profiles: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DIAGNOSIS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$anyLanguageProfile = $langProfiles | Where-Object { $_.name -eq "Any" -or ($_.languages | Where-Object { $_.allowed -eq $true }).Count -gt 1 }
if ($anyLanguageProfile) {
    Write-Host "[ISSUE FOUND] Your profiles allow multiple languages!" -ForegroundColor Red
    Write-Host "This is why Radarr is downloading German (or other language) files." -ForegroundColor Yellow
    Write-Host "`nSOLUTION: Create an English-only language profile" -ForegroundColor Green
} else {
    Write-Host "[OK] Language profiles look correct" -ForegroundColor Green
}
