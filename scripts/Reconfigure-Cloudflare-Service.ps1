# Reconfigure-Cloudflare-Service.ps1
# Reconfigures cloudflared service to run the tunnel
# REQUIRES: Administrator privileges

Write-Host "Reconfiguring Cloudflare Tunnel Service..." -ForegroundColor Cyan

# Stop and uninstall existing service
Write-Host "Stopping existing service..." -ForegroundColor Yellow
Stop-Service cloudflared -ErrorAction SilentlyContinue

Write-Host "Uninstalling existing service..." -ForegroundColor Yellow
& "$env:USERPROFILE\.cloudflared\cloudflared.exe" service uninstall

# Reinstall with proper configuration
Write-Host "Reinstalling service with tunnel configuration..." -ForegroundColor Cyan
& "$env:USERPROFILE\.cloudflared\cloudflared.exe" --config "$env:USERPROFILE\.cloudflared\config.yml" service install

# Start the service
Write-Host "Starting cloudflared service..." -ForegroundColor Cyan
Start-Service cloudflared

# Check status
$service = Get-Service cloudflared
Write-Host "`nService Status: $($service.Status)" -ForegroundColor Green
Write-Host "Startup Type: $($service.StartType)" -ForegroundColor Green

# Wait a moment for tunnel to connect
Write-Host "`nWaiting for tunnel to connect..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check tunnel info
Write-Host "`nChecking tunnel status..." -ForegroundColor Cyan
& "C:\Users\rokon\.cloudflared\cloudflared.exe" tunnel info calibre-web-tunnel

Write-Host "`nReconfiguration complete. Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
