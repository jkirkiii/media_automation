# Start-CalibreWeb-With-Tunnel.ps1
# Starts both Calibre-Web and Cloudflare Tunnel together
# This ensures your ebook library is accessible both locally and remotely

param(
    [switch]$HideWindows = $false
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CALIBRE-WEB + CLOUDFLARE TUNNEL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$ConfigPath = "A:\Media\Calibre-Web-Config"
$Port = 8083
$CalibreWebExe = "$env:APPDATA\Python\Python313\Scripts\cps.exe"
$CloudflaredExe = "C:\Users\rokon\.cloudflared\cloudflared.exe"
$CloudflaredConfig = "C:\Users\rokon\.cloudflared\config.yml"

Write-Host "[1/3] Checking for existing processes..." -ForegroundColor Yellow

# Kill any existing Calibre-Web or cloudflared processes
Get-Process | Where-Object {$_.ProcessName -like "*cps*" -or $_.ProcessName -like "*cloudflared*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "[2/3] Starting Calibre-Web..." -ForegroundColor Yellow

# Start Calibre-Web in background
if (Test-Path $CalibreWebExe) {
    if ($HideWindows) {
        $calibreWebProcess = Start-Process -FilePath $CalibreWebExe -ArgumentList "-p", "`"$ConfigPath`"" -WindowStyle Hidden -PassThru
    } else {
        $calibreWebProcess = Start-Process -FilePath $CalibreWebExe -ArgumentList "-p", "`"$ConfigPath`"" -PassThru
    }
    Write-Host "  [OK] Calibre-Web started (PID: $($calibreWebProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Calibre-Web not found at: $CalibreWebExe" -ForegroundColor Red
    exit 1
}

# Wait for Calibre-Web to start
Write-Host "  Waiting for Calibre-Web to initialize..." -ForegroundColor Gray
Start-Sleep -Seconds 5

Write-Host "[3/3] Starting Cloudflare Tunnel..." -ForegroundColor Yellow

# Start Cloudflare Tunnel in background
if (Test-Path $CloudflaredExe) {
    if ($HideWindows) {
        $tunnelProcess = Start-Process -FilePath $CloudflaredExe -ArgumentList "tunnel", "--config", "`"$CloudflaredConfig`"", "run" -WindowStyle Hidden -PassThru
    } else {
        $tunnelProcess = Start-Process -FilePath $CloudflaredExe -ArgumentList "tunnel", "--config", "`"$CloudflaredConfig`"", "run" -PassThru
    }
    Write-Host "  [OK] Cloudflare Tunnel started (PID: $($tunnelProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] cloudflared not found at: $CloudflaredExe" -ForegroundColor Red
    Write-Host "  Calibre-Web is running, but tunnel is not available" -ForegroundColor Yellow
}

# Wait for tunnel to connect
Write-Host "  Waiting for tunnel to connect..." -ForegroundColor Gray
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  SERVICES STARTED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your library at:" -ForegroundColor Cyan
Write-Host "  Local:  http://localhost:$Port" -ForegroundColor White
Write-Host "  Remote: https://books.mnemo.info" -ForegroundColor White
Write-Host ""
Write-Host "Login credentials (stored in config.ps1):" -ForegroundColor Yellow
Write-Host "  Username: (see config.ps1)" -ForegroundColor White
Write-Host "  Password: cMongo430!" -ForegroundColor White
Write-Host ""
Write-Host "Process IDs:" -ForegroundColor Gray
Write-Host "  Calibre-Web: $($calibreWebProcess.Id)" -ForegroundColor Gray
Write-Host "  Cloudflare Tunnel: $($tunnelProcess.Id)" -ForegroundColor Gray
Write-Host ""
Write-Host "To stop services, run:" -ForegroundColor Yellow
Write-Host "  .\Stop-CalibreWeb-And-Tunnel.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit (services will continue running)..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
