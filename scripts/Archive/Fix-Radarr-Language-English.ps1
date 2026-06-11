# Fix-Radarr-Language-English.ps1
# Sets all Radarr quality profiles to English language

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
    "Content-Type" = "application/json"
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "FIX RADARR LANGUAGE TO ENGLISH" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Get English language ID
Write-Host "[1/3] Getting language IDs..." -ForegroundColor Yellow
try {
    $languages = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/language" -Headers $headers
    $english = $languages | Where-Object { $_.name -eq "English" }

    if ($english) {
        Write-Host "    English language ID: $($english.id)" -ForegroundColor Green
    } else {
        Write-Host "    [ERROR] Could not find English language" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "    [ERROR] Failed to get languages: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get all quality profiles
Write-Host "`n[2/3] Getting quality profiles..." -ForegroundColor Yellow
try {
    $qualityProfiles = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/qualityprofile" -Headers $headers
    Write-Host "    Found $($qualityProfiles.Count) quality profiles" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to get quality profiles: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Update each profile to use English
Write-Host "`n[3/3] Updating quality profiles to English..." -ForegroundColor Yellow
$updatedCount = 0

foreach ($profile in $qualityProfiles) {
    try {
        # Check current language
        $currentLangId = $profile.language.id

        if ($currentLangId -eq $english.id) {
            Write-Host "    [$($profile.name)] Already set to English, skipping" -ForegroundColor Gray
        } else {
            # Update language to English
            $profile.language = @{
                id = $english.id
                name = $english.name
            }

            # Convert to JSON and update
            $body = $profile | ConvertTo-Json -Depth 10

            $updated = Invoke-RestMethod -Uri "$RadarrUrl/api/v3/qualityprofile/$($profile.id)" -Headers $headers -Method Put -Body $body

            Write-Host "    [$($profile.name)] Updated: Original/Any -> English" -ForegroundColor Green
            $updatedCount++
        }
    } catch {
        Write-Host "    [$($profile.name)] [ERROR] Failed to update: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "LANGUAGE FIX COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Profiles updated: $updatedCount" -ForegroundColor Green
Write-Host "  Language: English (ID: $($english.id))" -ForegroundColor Green

Write-Host "`nWhat this means:" -ForegroundColor Yellow
Write-Host "  - Radarr will now ONLY download English movies" -ForegroundColor White
Write-Host "  - German, French, etc. releases will be filtered out" -ForegroundColor White
Write-Host "  - Existing movies are unaffected" -ForegroundColor White
Write-Host "  - New searches will respect this language filter" -ForegroundColor White

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Delete the German 'Materialists' download from Radarr" -ForegroundColor White
Write-Host "  2. Search again - it should now find English releases" -ForegroundColor White
Write-Host "  3. All future movies will default to English" -ForegroundColor White
