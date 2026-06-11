# Start-CalibreWeb.ps1
# Starts Calibre-Web server

$ConfigPath = "A:\Media\Calibre-Web-Config"
$Port = 8083

Write-Host "=== STARTING CALIBRE-WEB ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration: $ConfigPath" -ForegroundColor White
Write-Host "Port: $Port" -ForegroundColor White
Write-Host ""
Write-Host "Access Calibre-Web at: http://localhost:$Port" -ForegroundColor Green
Write-Host ""
Write-Host "Default login:" -ForegroundColor Yellow
Write-Host "  Username: admin" -ForegroundColor White
Write-Host "  Password: admin123" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Change the admin password after first login!" -ForegroundColor Red
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
Write-Host ""
Write-Host "---" -ForegroundColor Gray
Write-Host ""

# Start Calibre-Web
# Use full path to cps.exe
$cpsPath = "$env:APPDATA\Python\Python313\Scripts\cps.exe"

if (Test-Path $cpsPath) {
    & $cpsPath -p "$ConfigPath"
} else {
    Write-Host "ERROR: cps.exe not found at: $cpsPath" -ForegroundColor Red
    Write-Host "Trying alternate method..." -ForegroundColor Yellow
    python -m calibreweb -p "$ConfigPath"
}
