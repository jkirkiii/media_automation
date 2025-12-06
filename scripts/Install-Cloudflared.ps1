# Install-Cloudflared.ps1
# Installs Cloudflare Tunnel (cloudflared) for Windows

<#
.SYNOPSIS
    Installs cloudflared (Cloudflare Tunnel) on Windows

.DESCRIPTION
    Downloads and installs the latest cloudflared MSI installer for Windows.
    Verifies installation and PATH configuration.

.PARAMETER InstallPath
    Optional custom installation path. Defaults to C:\Program Files\cloudflared\

.EXAMPLE
    .\Install-Cloudflared.ps1
    Installs cloudflared to default location

.EXAMPLE
    .\Install-Cloudflared.ps1 -InstallPath "C:\Tools\cloudflared"
    Installs to custom location

.NOTES
    Requires administrator privileges
    Part of Calibre-Web Remote Access setup
    See docs/Calibre-Web_Remote_Access_Guide.md for full setup instructions
#>

[CmdletBinding()]
param(
    [string]$InstallPath = "$env:ProgramFiles\cloudflared"
)

# Requires admin
#Requires -RunAsAdministrator

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Cloudflared Installation Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if already installed
Write-Host "[1/5] Checking for existing installation..." -ForegroundColor Yellow

$existingInstall = Get-Command cloudflared -ErrorAction SilentlyContinue
if ($existingInstall) {
    Write-Host "✓ cloudflared is already installed" -ForegroundColor Green
    Write-Host "  Location: $($existingInstall.Source)" -ForegroundColor Gray

    $version = & cloudflared --version 2>&1 | Select-Object -First 1
    Write-Host "  Version: $version" -ForegroundColor Gray

    $response = Read-Host "`nReinstall? (y/n)"
    if ($response -ne 'y') {
        Write-Host "`nInstallation cancelled. Using existing installation." -ForegroundColor Yellow
        exit 0
    }
}

# Get latest release info from GitHub
Write-Host "`n[2/5] Fetching latest cloudflared release..." -ForegroundColor Yellow

try {
    $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/cloudflare/cloudflared/releases/latest" -ErrorAction Stop
    $latestVersion = $releaseInfo.tag_name

    # Find Windows AMD64 MSI asset
    $msiAsset = $releaseInfo.assets | Where-Object { $_.name -like "*windows-amd64.msi" } | Select-Object -First 1

    if (-not $msiAsset) {
        throw "Could not find Windows MSI installer in latest release"
    }

    $downloadUrl = $msiAsset.browser_download_url
    $fileName = $msiAsset.name

    Write-Host "✓ Found latest version: $latestVersion" -ForegroundColor Green
    Write-Host "  Download: $fileName" -ForegroundColor Gray

} catch {
    Write-Host "✗ Failed to fetch latest release information" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nUsing fallback direct download URL..." -ForegroundColor Yellow

    # Fallback to known URL pattern
    $downloadUrl = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.msi"
    $fileName = "cloudflared-windows-amd64.msi"
}

# Download installer
Write-Host "`n[3/5] Downloading cloudflared installer..." -ForegroundColor Yellow

$downloadPath = Join-Path $env:TEMP $fileName

try {
    # Remove existing file if present
    if (Test-Path $downloadPath) {
        Remove-Item $downloadPath -Force
    }

    Write-Host "  Downloading to: $downloadPath" -ForegroundColor Gray

    # Download with progress
    $ProgressPreference = 'SilentlyContinue'  # Faster download
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -ErrorAction Stop
    $ProgressPreference = 'Continue'

    $fileSize = (Get-Item $downloadPath).Length / 1MB
    Write-Host "✓ Downloaded successfully ($([math]::Round($fileSize, 2)) MB)" -ForegroundColor Green

} catch {
    Write-Host "✗ Failed to download installer" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPlease download manually from:" -ForegroundColor Yellow
    Write-Host "  https://github.com/cloudflare/cloudflared/releases" -ForegroundColor Cyan
    exit 1
}

# Install MSI
Write-Host "`n[4/5] Installing cloudflared..." -ForegroundColor Yellow
Write-Host "  This may take a minute..." -ForegroundColor Gray

try {
    # Run MSI installer silently
    $msiArgs = @(
        "/i", $downloadPath,
        "/quiet",
        "/norestart",
        "/L*v", (Join-Path $env:TEMP "cloudflared-install.log")
    )

    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -eq 0) {
        Write-Host "✓ Installation completed successfully" -ForegroundColor Green
    } elseif ($process.ExitCode -eq 3010) {
        Write-Host "✓ Installation completed (restart required)" -ForegroundColor Yellow
    } else {
        throw "MSI installer returned exit code: $($process.ExitCode)"
    }

} catch {
    Write-Host "✗ Installation failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nInstallation log: $(Join-Path $env:TEMP 'cloudflared-install.log')" -ForegroundColor Gray
    exit 1
} finally {
    # Cleanup downloaded installer
    if (Test-Path $downloadPath) {
        Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
    }
}

# Verify installation
Write-Host "`n[5/5] Verifying installation..." -ForegroundColor Yellow

# Refresh PATH for current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Wait a moment for PATH to update
Start-Sleep -Seconds 2

$cloudflaredCmd = Get-Command cloudflared -ErrorAction SilentlyContinue

if ($cloudflaredCmd) {
    Write-Host "✓ cloudflared is accessible in PATH" -ForegroundColor Green
    Write-Host "  Location: $($cloudflaredCmd.Source)" -ForegroundColor Gray

    # Get version
    try {
        $version = & cloudflared --version 2>&1 | Select-Object -First 1
        Write-Host "  Version: $version" -ForegroundColor Gray
    } catch {
        Write-Host "  Version: (unable to determine)" -ForegroundColor Gray
    }

} else {
    Write-Host "⚠ cloudflared not found in PATH" -ForegroundColor Yellow
    Write-Host "  You may need to restart your terminal or computer" -ForegroundColor Yellow
    Write-Host "  Expected location: C:\Program Files\cloudflared\cloudflared.exe" -ForegroundColor Gray
}

# Installation complete
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Close and reopen your terminal (to refresh PATH)" -ForegroundColor White
Write-Host "  2. Run: cloudflared --version (to verify)" -ForegroundColor White
Write-Host "  3. Run: .\Configure-Cloudflare-Tunnel.ps1 (to set up tunnel)" -ForegroundColor White
Write-Host ""
Write-Host "Documentation: docs\Calibre-Web_Remote_Access_Guide.md" -ForegroundColor Gray
Write-Host ""
