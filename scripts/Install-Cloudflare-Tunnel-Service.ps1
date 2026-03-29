# Install-Cloudflare-Tunnel-Service.ps1
# Installs cloudflared tunnel as a Windows service
# REQUIRES: Administrator privileges

Write-Host "Installing Cloudflare Tunnel as Windows Service..." -ForegroundColor Cyan

# Install the service
& "$env:USERPROFILE\.cloudflared\cloudflared.exe" service install

if ($LASTEXITCODE -eq 0)
{
    Write-Host "Service installed successfully" -ForegroundColor Green

    # Start the service
    Write-Host "Starting cloudflared service..." -ForegroundColor Cyan
    Start-Service cloudflared

    if ($?)
    {
        Write-Host "Service started successfully" -ForegroundColor Green

        # Check service status
        $service = Get-Service cloudflared
        Write-Host "Service Status: $($service.Status)" -ForegroundColor Yellow
        Write-Host "Startup Type: $($service.StartType)" -ForegroundColor Yellow
    }
}

Write-Host "Installation complete. Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
