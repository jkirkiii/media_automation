# Check-Radarr-Language-V6.ps1
# Checks language settings in Radarr v6 (uses different API than v3)

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
Write-Host "RADARR V6 LANGUAGE SETTINGS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check language definitions
Write-Host "[1/4] Available Languages:" -ForegroundColor Yellow
try {
    $languages = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/language" -Headers $headers
    Write-Host "    Found $($languages.Count) languages" -ForegroundColor Green
    $english = $languages | Where-Object { $_.name -eq "English" }
    Write-Host "    English ID: $($english.id)" -ForegroundColor Gray
} catch {
    Write-Host "    [ERROR] Failed to get languages: $($_.Exception.Message)" -ForegroundColor Red
}

# Check quality profiles - specifically for language settings
Write-Host "`n[2/4] Quality Profile Language Settings:" -ForegroundColor Yellow
try {
    $qualityProfiles = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/qualityprofile" -Headers $headers

    foreach ($profile in $qualityProfiles) {
        Write-Host "`n  Profile: $($profile.name)" -ForegroundColor Cyan

        # Check for language property (v6 uses direct language object)
        if ($profile.language) {
            $langId = $profile.language.id
            $lang = $languages | Where-Object { $_.id -eq $langId }
            if ($lang) {
                Write-Host "    Language: $($lang.name) (ID: $langId)" -ForegroundColor $(if ($langId -lt 0) { "Red" } else { "Green" })
            } else {
                Write-Host "    Language: Any/Multiple (ID: $langId)" -ForegroundColor Red
            }
        }
    }
} catch {
    Write-Host "    [ERROR] Failed to get quality profiles: $($_.Exception.Message)" -ForegroundColor Red
}

# Check a sample movie to see language settings
Write-Host "`n[3/4] Sample Movie Language Settings:" -ForegroundColor Yellow
try {
    $movies = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/movie" -Headers $headers
    if ($movies -and $movies.Count -gt 0) {
        $sampleMovie = $movies[0]
        Write-Host "    Sample: $($sampleMovie.title)" -ForegroundColor Cyan
        Write-Host "    Quality Profile ID: $($sampleMovie.qualityProfileId)" -ForegroundColor Gray

        $movieProfile = $qualityProfiles | Where-Object { $_.id -eq $sampleMovie.qualityProfileId }
        if ($movieProfile -and $movieProfile.language) {
            $movieLang = $languages | Where-Object { $_.id -eq $movieProfile.language.id }
            Write-Host "    Effective Language: $($movieLang.name)" -ForegroundColor $(if ($movieProfile.language.id -lt 0) { "Red" } else { "Green" })
        }
    }
} catch {
    Write-Host "    [WARNING] Could not check movie settings" -ForegroundColor Yellow
}

# Check config for language filtering
Write-Host "`n[4/4] Radarr Configuration:" -ForegroundColor Yellow
try {
    $config = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/config/ui" -Headers $headers
    Write-Host "    UI Language: $($config.movieInfoLanguage)" -ForegroundColor Gray
} catch {
    Write-Host "    [WARNING] Could not get UI config" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DIAGNOSIS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$anyLanguageProfiles = $qualityProfiles | Where-Object { $_.language.id -lt 0 }
if ($anyLanguageProfiles) {
    Write-Host "[ISSUE FOUND] Quality profiles set to 'Any' language!" -ForegroundColor Red
    Write-Host "Profile(s) affected: $($anyLanguageProfiles.name -join ', ')" -ForegroundColor Yellow
    Write-Host "`nThis is why Radarr downloads German files - it accepts ANY language." -ForegroundColor Yellow
    Write-Host "`nSOLUTION:" -ForegroundColor Green
    Write-Host "  1. Go to Settings → Profiles in Radarr web UI" -ForegroundColor White
    Write-Host "  2. Edit each quality profile" -ForegroundColor White
    Write-Host "  3. Set Language to 'English' instead of 'Any'" -ForegroundColor White
    Write-Host "  4. Save changes" -ForegroundColor White
} else {
    Write-Host "[OK] Language settings look correct" -ForegroundColor Green
}
