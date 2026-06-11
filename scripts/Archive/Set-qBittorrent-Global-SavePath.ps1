# Set qBittorrent Global Save Path
param(
    [string]$qBitHost = "localhost",
    [int]$qBitPort = 8080,
    [string]$Username = "admin",
    [Parameter(Mandatory=$true)]
    [string]$Password,
    [string]$NewSavePath = "A:\Downloads\TV"
)

$base = "http://${qBitHost}:${qBitPort}"

Write-Host ""
Write-Host "=== Setting qBittorrent Global Save Path ===" -ForegroundColor Cyan
Write-Host ""

# Login
$loginBody = "username=$Username&password=$Password"
try {
    $login = Invoke-WebRequest -Uri "$base/api/v2/auth/login" -Method POST -Body $loginBody -SessionVariable qb
    if ($login.Content -ne 'Ok.') {
        Write-Host "Login failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Logged in successfully" -ForegroundColor Green
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Get current preferences
Write-Host ""
Write-Host "Current settings:" -ForegroundColor Yellow
$prefs = Invoke-RestMethod -Uri "$base/api/v2/app/preferences" -WebSession $qb
Write-Host "  Global Save Path: $($prefs.save_path)" -ForegroundColor White
Write-Host "  Temp Path: $($prefs.temp_path)" -ForegroundColor White

# Create directory if needed
if (-not (Test-Path $NewSavePath)) {
    Write-Host ""
    Write-Host "Creating directory: $NewSavePath" -ForegroundColor Yellow
    New-Item -Path $NewSavePath -ItemType Directory -Force | Out-Null
    Write-Host "Directory created" -ForegroundColor Green
}

# Update save path
Write-Host ""
Write-Host "Updating global save path to: $NewSavePath" -ForegroundColor Yellow

$updatePrefs = @{
    save_path = $NewSavePath
}

$jsonPrefs = $updatePrefs | ConvertTo-Json -Compress

try {
    $result = Invoke-WebRequest -Uri "$base/api/v2/app/setPreferences" -Method POST -WebSession $qb -Body "json=$jsonPrefs" -ContentType "application/x-www-form-urlencoded"

    Write-Host "Global save path updated!" -ForegroundColor Green
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Verify
Write-Host ""
Write-Host "Verifying..." -ForegroundColor Yellow
$prefsAfter = Invoke-RestMethod -Uri "$base/api/v2/app/preferences" -WebSession $qb

$actualPath = $prefsAfter.save_path
$expectedNormalized = $NewSavePath -replace '\\', '/'
$actualNormalized = $actualPath -replace '\\', '/'

if ($actualNormalized -eq $expectedNormalized) {
    Write-Host "SUCCESS! Global save path is now: $actualPath" -ForegroundColor Green
} else {
    Write-Host "WARNING: Path may not have updated correctly" -ForegroundColor Yellow
    Write-Host "  Expected: $NewSavePath" -ForegroundColor Yellow
    Write-Host "  Actual: $actualPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "IMPORTANT: Test with a new download from Sonarr." -ForegroundColor Yellow
Write-Host ""
