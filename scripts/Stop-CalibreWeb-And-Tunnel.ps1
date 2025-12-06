# Stop-CalibreWeb-And-Tunnel.ps1
# Stops both Calibre-Web and Cloudflare Tunnel

Write-Host "Stopping Calibre-Web and Cloudflare Tunnel..." -ForegroundColor Yellow
Write-Host ""

# Stop Calibre-Web
$calibreWebProcesses = Get-Process | Where-Object {$_.ProcessName -like "*cps*"}
if ($calibreWebProcesses) {
    $calibreWebProcesses | Stop-Process -Force
    Write-Host "[OK] Calibre-Web stopped" -ForegroundColor Green
} else {
    Write-Host "  Calibre-Web was not running" -ForegroundColor Gray
}

# Stop Cloudflare Tunnel
$tunnelProcesses = Get-Process | Where-Object {$_.ProcessName -like "*cloudflared*"}
if ($tunnelProcesses) {
    $tunnelProcesses | Stop-Process -Force
    Write-Host "[OK] Cloudflare Tunnel stopped" -ForegroundColor Green
} else {
    Write-Host "  Cloudflare Tunnel was not running" -ForegroundColor Gray
}

Write-Host ""
Write-Host "All services stopped." -ForegroundColor Cyan
