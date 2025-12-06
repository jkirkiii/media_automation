# Configure-Cloudflare-Tunnel.ps1
# Configures Cloudflare Tunnel for Calibre-Web remote access

<#
.SYNOPSIS
    Configures Cloudflare Tunnel to expose Calibre-Web remotely

.DESCRIPTION
    Guides through the process of:
    - Authenticating cloudflared with Cloudflare account
    - Creating a tunnel
    - Configuring tunnel to point to Calibre-Web (localhost:8083)
    - Setting up DNS routing
    - Installing as Windows service for auto-start

.PARAMETER Domain
    Your domain name (e.g., "example.com")

.PARAMETER Subdomain
    Subdomain for Calibre-Web (default: "library")

.PARAMETER TunnelName
    Name for the tunnel (default: "calibre-web-tunnel")

.PARAMETER CalibreWebPort
    Port where Calibre-Web is running (default: 8083)

.EXAMPLE
    .\Configure-Cloudflare-Tunnel.ps1 -Domain "example.com"
    Sets up tunnel for library.example.com → localhost:8083

.EXAMPLE
    .\Configure-Cloudflare-Tunnel.ps1 -Domain "example.com" -Subdomain "books"
    Sets up tunnel for books.example.com → localhost:8083

.NOTES
    Prerequisites:
    - cloudflared must be installed (run Install-Cloudflared.ps1 first)
    - Cloudflare account with domain added
    - Domain nameservers pointed to Cloudflare

    Part of Calibre-Web Remote Access setup
    See docs/Calibre-Web_Remote_Access_Guide.md for full instructions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Your domain name (e.g., example.com)")]
    [string]$Domain,

    [Parameter(Mandatory=$false)]
    [string]$Subdomain = "library",

    [Parameter(Mandatory=$false)]
    [string]$TunnelName = "calibre-web-tunnel",

    [Parameter(Mandatory=$false)]
    [int]$CalibreWebPort = 8083
)

# Check for cloudflared
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Cloudflare Tunnel Configuration Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$cloudflaredCmd = Get-Command cloudflared -ErrorAction SilentlyContinue
if (-not $cloudflaredCmd) {
    Write-Host "✗ cloudflared not found" -ForegroundColor Red
    Write-Host "`nPlease install cloudflared first:" -ForegroundColor Yellow
    Write-Host "  Run: .\Install-Cloudflared.ps1" -ForegroundColor Cyan
    Write-Host "  Or download from: https://github.com/cloudflare/cloudflared/releases" -ForegroundColor Gray
    exit 1
}

Write-Host "✓ cloudflared found: $($cloudflaredCmd.Source)" -ForegroundColor Green

# Check if Calibre-Web is running
Write-Host "`nChecking if Calibre-Web is accessible..." -ForegroundColor Yellow

try {
    $testConnection = Test-NetConnection -ComputerName localhost -Port $CalibreWebPort -WarningAction SilentlyContinue
    if ($testConnection.TcpTestSucceeded) {
        Write-Host "✓ Calibre-Web is running on localhost:$CalibreWebPort" -ForegroundColor Green
    } else {
        Write-Host "⚠ Cannot connect to localhost:$CalibreWebPort" -ForegroundColor Yellow
        Write-Host "  Make sure Calibre-Web is running before continuing" -ForegroundColor Yellow
        $continue = Read-Host "`nContinue anyway? (y/n)"
        if ($continue -ne 'y') {
            exit 1
        }
    }
} catch {
    Write-Host "⚠ Could not test Calibre-Web connection" -ForegroundColor Yellow
}

# Configuration summary
$fullDomain = "$Subdomain.$Domain"

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Configuration Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Domain: $Domain" -ForegroundColor White
Write-Host "  Subdomain: $Subdomain" -ForegroundColor White
Write-Host "  Full URL: https://$fullDomain" -ForegroundColor Green
Write-Host "  Tunnel Name: $TunnelName" -ForegroundColor White
Write-Host "  Local Service: http://localhost:$CalibreWebPort" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Continue with this configuration? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "`nConfiguration cancelled." -ForegroundColor Yellow
    exit 0
}

# Step 1: Authenticate with Cloudflare
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Step 1: Authenticate with Cloudflare" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$certPath = Join-Path $env:USERPROFILE ".cloudflared\cert.pem"

if (Test-Path $certPath) {
    Write-Host "✓ Found existing authentication certificate" -ForegroundColor Green
    Write-Host "  Location: $certPath" -ForegroundColor Gray

    $reauth = Read-Host "`nRe-authenticate? (y/n)"
    if ($reauth -eq 'y') {
        Write-Host "`nOpening browser for authentication..." -ForegroundColor Yellow
        Write-Host "  1. Log into your Cloudflare account" -ForegroundColor White
        Write-Host "  2. Select your domain: $Domain" -ForegroundColor White
        Write-Host "  3. Click 'Authorize'" -ForegroundColor White
        Write-Host ""

        & cloudflared tunnel login
    }
} else {
    Write-Host "Opening browser for authentication..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "In the browser window that opens:" -ForegroundColor Cyan
    Write-Host "  1. Log into your Cloudflare account" -ForegroundColor White
    Write-Host "  2. Select your domain: $Domain" -ForegroundColor White
    Write-Host "  3. Click 'Authorize'" -ForegroundColor White
    Write-Host ""
    Write-Host "Press any key when ready..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    & cloudflared tunnel login

    if (-not (Test-Path $certPath)) {
        Write-Host "`n✗ Authentication failed - certificate not found" -ForegroundColor Red
        exit 1
    }

    Write-Host "`n✓ Authentication successful" -ForegroundColor Green
}

# Step 2: Create tunnel
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Step 2: Create Tunnel" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if tunnel already exists
$existingTunnels = & cloudflared tunnel list 2>&1 | Select-String -Pattern $TunnelName

if ($existingTunnels) {
    Write-Host "⚠ Tunnel '$TunnelName' already exists" -ForegroundColor Yellow
    $recreate = Read-Host "Delete and recreate? (y/n)"

    if ($recreate -eq 'y') {
        Write-Host "Deleting existing tunnel..." -ForegroundColor Yellow
        & cloudflared tunnel delete $TunnelName
        Start-Sleep -Seconds 2

        Write-Host "Creating new tunnel..." -ForegroundColor Yellow
        & cloudflared tunnel create $TunnelName
    } else {
        Write-Host "Using existing tunnel." -ForegroundColor Green
    }
} else {
    Write-Host "Creating tunnel: $TunnelName" -ForegroundColor Yellow
    & cloudflared tunnel create $TunnelName
}

# Get tunnel ID
$tunnelInfo = & cloudflared tunnel list 2>&1 | Select-String -Pattern $TunnelName
if ($tunnelInfo) {
    # Extract tunnel ID (first column)
    $tunnelId = ($tunnelInfo -split '\s+')[0]
    Write-Host "`n✓ Tunnel created successfully" -ForegroundColor Green
    Write-Host "  Tunnel ID: $tunnelId" -ForegroundColor Gray
} else {
    Write-Host "`n✗ Failed to create tunnel" -ForegroundColor Red
    exit 1
}

# Step 3: Create configuration file
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Step 3: Create Configuration File" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$configDir = Join-Path $env:USERPROFILE ".cloudflared"
$configPath = Join-Path $configDir "config.yml"
$credentialsPath = Join-Path $configDir "$tunnelId.json"

if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$configContent = @"
tunnel: $tunnelId
credentials-file: $credentialsPath

ingress:
  - hostname: $fullDomain
    service: http://localhost:$CalibreWebPort
  - service: http_status:404
"@

if (Test-Path $configPath) {
    $backup = "${configPath}.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $configPath $backup
    Write-Host "  Backed up existing config to: $backup" -ForegroundColor Gray
}

$configContent | Set-Content $configPath -Encoding UTF8

Write-Host "✓ Configuration file created" -ForegroundColor Green
Write-Host "  Location: $configPath" -ForegroundColor Gray
Write-Host ""
Write-Host "  Configuration:" -ForegroundColor Cyan
Write-Host "    Tunnel ID: $tunnelId" -ForegroundColor White
Write-Host "    Hostname: $fullDomain" -ForegroundColor White
Write-Host "    Service: http://localhost:$CalibreWebPort" -ForegroundColor White

# Step 4: Set up DNS routing
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Step 4: Configure DNS Routing" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Creating DNS record for $fullDomain..." -ForegroundColor Yellow

try {
    & cloudflared tunnel route dns $TunnelName $fullDomain 2>&1 | Out-Null

    Write-Host "✓ DNS record created successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Verify in Cloudflare Dashboard:" -ForegroundColor Cyan
    Write-Host "    Dashboard → DNS → Records" -ForegroundColor White
    Write-Host "    Look for CNAME record: $Subdomain" -ForegroundColor White

} catch {
    Write-Host "⚠ DNS routing command completed with warnings" -ForegroundColor Yellow
    Write-Host "  You may need to manually verify the DNS record in Cloudflare Dashboard" -ForegroundColor Yellow
}

# Step 5: Test tunnel (optional)
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Step 5: Test Tunnel" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$test = Read-Host "Test tunnel now? This will run the tunnel in the foreground. (y/n)"

if ($test -eq 'y') {
    Write-Host "`nStarting tunnel in test mode..." -ForegroundColor Yellow
    Write-Host "  Press Ctrl+C to stop the test" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Once started, try accessing: https://$fullDomain" -ForegroundColor Cyan
    Write-Host ""

    & cloudflared tunnel run $TunnelName

    Write-Host "`nTest stopped." -ForegroundColor Yellow
}

# Step 6: Install as Windows service
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Step 6: Install as Windows Service" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$installService = Read-Host "Install cloudflared as a Windows service for auto-start? (y/n)"

if ($installService -eq 'y') {
    Write-Host "`nInstalling Windows service..." -ForegroundColor Yellow

    try {
        # Check if service already exists
        $existingService = Get-Service cloudflared -ErrorAction SilentlyContinue

        if ($existingService) {
            Write-Host "  Stopping existing service..." -ForegroundColor Gray
            Stop-Service cloudflared -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2

            Write-Host "  Removing existing service..." -ForegroundColor Gray
            & cloudflared service uninstall
            Start-Sleep -Seconds 2
        }

        # Install service
        & cloudflared service install

        Write-Host "`n✓ Service installed successfully" -ForegroundColor Green

        # Start service
        Write-Host "  Starting service..." -ForegroundColor Gray
        Start-Service cloudflared

        # Verify service
        Start-Sleep -Seconds 3
        $service = Get-Service cloudflared

        if ($service.Status -eq 'Running') {
            Write-Host "✓ Service is running" -ForegroundColor Green
            Write-Host "  Status: $($service.Status)" -ForegroundColor Gray
            Write-Host "  Startup Type: $($service.StartType)" -ForegroundColor Gray
        } else {
            Write-Host "⚠ Service installed but not running" -ForegroundColor Yellow
            Write-Host "  Try: Start-Service cloudflared" -ForegroundColor Gray
        }

    } catch {
        Write-Host "✗ Failed to install service" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`n  Try running as Administrator" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nService installation skipped." -ForegroundColor Yellow
    Write-Host "  To run tunnel manually: cloudflared tunnel run $TunnelName" -ForegroundColor Gray
}

# Final summary
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Configuration Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your Calibre-Web library should now be accessible at:" -ForegroundColor Cyan
Write-Host "  https://$fullDomain" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Test external access from mobile/different network" -ForegroundColor White
Write-Host "  2. Harden Calibre-Web security (change admin password)" -ForegroundColor White
Write-Host "  3. Create user accounts for family/friends" -ForegroundColor White
Write-Host "  4. Configure user permissions" -ForegroundColor White
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "  Setup Guide: docs\Calibre-Web_Remote_Access_Guide.md" -ForegroundColor Gray
Write-Host "  Configuration Decisions: docs\Calibre-Web_Configuration_Decisions.md" -ForegroundColor Gray
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  Check service status: Get-Service cloudflared" -ForegroundColor Gray
Write-Host "  View tunnel info: cloudflared tunnel info $TunnelName" -ForegroundColor Gray
Write-Host "  List tunnels: cloudflared tunnel list" -ForegroundColor Gray
Write-Host ""
