# Verify-Cloudflare-Tunnel.ps1
# Verifies Cloudflare Tunnel configuration and status

<#
.SYNOPSIS
    Verifies Cloudflare Tunnel setup for Calibre-Web

.DESCRIPTION
    Checks:
    - cloudflared installation and version
    - Tunnel exists and is configured
    - Windows service status
    - DNS configuration
    - Tunnel connectivity
    - Calibre-Web accessibility

.PARAMETER TunnelName
    Name of the tunnel to verify (default: "calibre-web-tunnel")

.PARAMETER Domain
    Full domain name to check (e.g., "library.example.com")

.EXAMPLE
    .\Verify-Cloudflare-Tunnel.ps1
    Verifies default tunnel

.EXAMPLE
    .\Verify-Cloudflare-Tunnel.ps1 -TunnelName "my-tunnel" -Domain "books.example.com"
    Verifies specific tunnel and domain

.NOTES
    Part of Calibre-Web Remote Access setup
    See docs/Calibre-Web_Remote_Access_Guide.md for troubleshooting
#>

[CmdletBinding()]
param(
    [string]$TunnelName = "calibre-web-tunnel",
    [string]$Domain = $null
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Cloudflare Tunnel Verification" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$allChecks = @()

# Check 1: cloudflared installation
Write-Host "[1/7] Checking cloudflared installation..." -ForegroundColor Yellow

$cloudflaredCmd = Get-Command cloudflared -ErrorAction SilentlyContinue
if ($cloudflaredCmd) {
    Write-Host "  ✓ cloudflared is installed" -ForegroundColor Green
    Write-Host "    Location: $($cloudflaredCmd.Source)" -ForegroundColor Gray

    try {
        $version = & cloudflared --version 2>&1 | Select-Object -First 1
        Write-Host "    Version: $version" -ForegroundColor Gray
        $allChecks += @{Name="Installation"; Status="PASS"}
    } catch {
        Write-Host "    ⚠ Could not determine version" -ForegroundColor Yellow
        $allChecks += @{Name="Installation"; Status="WARN"}
    }
} else {
    Write-Host "  ✗ cloudflared not found" -ForegroundColor Red
    Write-Host "    Install with: .\Install-Cloudflared.ps1" -ForegroundColor Gray
    $allChecks += @{Name="Installation"; Status="FAIL"}
}

# Check 2: Authentication certificate
Write-Host "`n[2/7] Checking authentication..." -ForegroundColor Yellow

$certPath = Join-Path $env:USERPROFILE ".cloudflared\cert.pem"
if (Test-Path $certPath) {
    Write-Host "  ✓ Authentication certificate found" -ForegroundColor Green
    Write-Host "    Location: $certPath" -ForegroundColor Gray
    $allChecks += @{Name="Authentication"; Status="PASS"}
} else {
    Write-Host "  ✗ Authentication certificate not found" -ForegroundColor Red
    Write-Host "    Run: cloudflared tunnel login" -ForegroundColor Gray
    $allChecks += @{Name="Authentication"; Status="FAIL"}
}

# Check 3: Tunnel exists
Write-Host "`n[3/7] Checking tunnel configuration..." -ForegroundColor Yellow

try {
    $tunnels = & cloudflared tunnel list 2>&1
    $tunnelInfo = $tunnels | Select-String -Pattern $TunnelName

    if ($tunnelInfo) {
        $tunnelId = ($tunnelInfo -split '\s+')[0]
        Write-Host "  ✓ Tunnel found: $TunnelName" -ForegroundColor Green
        Write-Host "    Tunnel ID: $tunnelId" -ForegroundColor Gray

        # Check for credentials file
        $credentialsPath = Join-Path $env:USERPROFILE ".cloudflared\$tunnelId.json"
        if (Test-Path $credentialsPath) {
            Write-Host "    ✓ Credentials file exists" -ForegroundColor Green
        } else {
            Write-Host "    ⚠ Credentials file not found: $credentialsPath" -ForegroundColor Yellow
        }

        $allChecks += @{Name="Tunnel Config"; Status="PASS"}
    } else {
        Write-Host "  ✗ Tunnel '$TunnelName' not found" -ForegroundColor Red
        Write-Host "    Create with: cloudflared tunnel create $TunnelName" -ForegroundColor Gray
        $allChecks += @{Name="Tunnel Config"; Status="FAIL"}
    }
} catch {
    Write-Host "  ✗ Could not list tunnels" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
    $allChecks += @{Name="Tunnel Config"; Status="FAIL"}
}

# Check 4: Configuration file
Write-Host "`n[4/7] Checking configuration file..." -ForegroundColor Yellow

$configPath = Join-Path $env:USERPROFILE ".cloudflared\config.yml"
if (Test-Path $configPath) {
    Write-Host "  ✓ Configuration file found" -ForegroundColor Green
    Write-Host "    Location: $configPath" -ForegroundColor Gray

    # Parse config
    $config = Get-Content $configPath -Raw
    if ($config -match "tunnel:\s*([a-f0-9-]+)") {
        Write-Host "    Tunnel ID: $($matches[1])" -ForegroundColor Gray
    }
    if ($config -match "hostname:\s*(.+)") {
        $hostname = $matches[1].Trim()
        Write-Host "    Hostname: $hostname" -ForegroundColor Gray
        if (-not $Domain) {
            $Domain = $hostname
        }
    }
    if ($config -match "service:\s*http://localhost:(\d+)") {
        Write-Host "    Service: http://localhost:$($matches[1])" -ForegroundColor Gray
    }

    $allChecks += @{Name="Config File"; Status="PASS"}
} else {
    Write-Host "  ✗ Configuration file not found" -ForegroundColor Red
    Write-Host "    Expected: $configPath" -ForegroundColor Gray
    Write-Host "    Run: .\Configure-Cloudflare-Tunnel.ps1" -ForegroundColor Gray
    $allChecks += @{Name="Config File"; Status="FAIL"}
}

# Check 5: Windows service
Write-Host "`n[5/7] Checking Windows service..." -ForegroundColor Yellow

$service = Get-Service cloudflared -ErrorAction SilentlyContinue
if ($service) {
    if ($service.Status -eq 'Running') {
        Write-Host "  ✓ Service is running" -ForegroundColor Green
        Write-Host "    Status: $($service.Status)" -ForegroundColor Gray
        Write-Host "    Startup Type: $($service.StartType)" -ForegroundColor Gray
        $allChecks += @{Name="Service Status"; Status="PASS"}
    } else {
        Write-Host "  ⚠ Service exists but not running" -ForegroundColor Yellow
        Write-Host "    Status: $($service.Status)" -ForegroundColor Gray
        Write-Host "    Start with: Start-Service cloudflared" -ForegroundColor Gray
        $allChecks += @{Name="Service Status"; Status="WARN"}
    }
} else {
    Write-Host "  ⚠ Service not installed" -ForegroundColor Yellow
    Write-Host "    Tunnel must be run manually: cloudflared tunnel run $TunnelName" -ForegroundColor Gray
    Write-Host "    Or install service: cloudflared service install" -ForegroundColor Gray
    $allChecks += @{Name="Service Status"; Status="WARN"}
}

# Check 6: DNS resolution
if ($Domain) {
    Write-Host "`n[6/7] Checking DNS resolution..." -ForegroundColor Yellow

    try {
        $dnsResult = Resolve-DnsName $Domain -Type CNAME -ErrorAction Stop
        if ($dnsResult) {
            Write-Host "  ✓ DNS record exists for $Domain" -ForegroundColor Green
            Write-Host "    Type: CNAME" -ForegroundColor Gray
            Write-Host "    Target: $($dnsResult.NameHost)" -ForegroundColor Gray
            $allChecks += @{Name="DNS Resolution"; Status="PASS"}
        }
    } catch {
        Write-Host "  ✗ DNS resolution failed for $Domain" -ForegroundColor Red
        Write-Host "    This may take up to 24-48 hours after nameserver change" -ForegroundColor Gray
        Write-Host "    Or run: cloudflared tunnel route dns $TunnelName $Domain" -ForegroundColor Gray
        $allChecks += @{Name="DNS Resolution"; Status="FAIL"}
    }
} else {
    Write-Host "`n[6/7] Skipping DNS check (no domain specified)" -ForegroundColor Gray
    $allChecks += @{Name="DNS Resolution"; Status="SKIP"}
}

# Check 7: Calibre-Web accessibility
Write-Host "`n[7/7] Checking Calibre-Web..." -ForegroundColor Yellow

try {
    $testConnection = Test-NetConnection -ComputerName localhost -Port 8083 -WarningAction SilentlyContinue
    if ($testConnection.TcpTestSucceeded) {
        Write-Host "  ✓ Calibre-Web is accessible on localhost:8083" -ForegroundColor Green
        $allChecks += @{Name="Calibre-Web"; Status="PASS"}
    } else {
        Write-Host "  ✗ Cannot connect to Calibre-Web on localhost:8083" -ForegroundColor Red
        Write-Host "    Make sure Calibre-Web is running" -ForegroundColor Gray
        Write-Host "    Start with: .\Start-CalibreWeb.bat" -ForegroundColor Gray
        $allChecks += @{Name="Calibre-Web"; Status="FAIL"}
    }
} catch {
    Write-Host "  ⚠ Could not test Calibre-Web connection" -ForegroundColor Yellow
    $allChecks += @{Name="Calibre-Web"; Status="WARN"}
}

# Summary
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Verification Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$passCount = ($allChecks | Where-Object { $_.Status -eq "PASS" }).Count
$warnCount = ($allChecks | Where-Object { $_.Status -eq "WARN" }).Count
$failCount = ($allChecks | Where-Object { $_.Status -eq "FAIL" }).Count
$skipCount = ($allChecks | Where-Object { $_.Status -eq "SKIP" }).Count
$totalCount = $allChecks.Count

foreach ($check in $allChecks) {
    $statusColor = switch ($check.Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
        "SKIP" { "Gray" }
    }
    $statusSymbol = switch ($check.Status) {
        "PASS" { "✓" }
        "WARN" { "⚠" }
        "FAIL" { "✗" }
        "SKIP" { "-" }
    }

    Write-Host "  $statusSymbol $($check.Name): " -NoNewline
    Write-Host $check.Status -ForegroundColor $statusColor
}

Write-Host ""
Write-Host "  Total Checks: $totalCount" -ForegroundColor White
Write-Host "  Passed: $passCount" -ForegroundColor Green
if ($warnCount -gt 0) { Write-Host "  Warnings: $warnCount" -ForegroundColor Yellow }
if ($failCount -gt 0) { Write-Host "  Failed: $failCount" -ForegroundColor Red }
if ($skipCount -gt 0) { Write-Host "  Skipped: $skipCount" -ForegroundColor Gray }

# Overall status
Write-Host ""
if ($failCount -eq 0 -and $warnCount -eq 0) {
    Write-Host "✓ All checks passed! Tunnel is fully configured and operational." -ForegroundColor Green
    if ($Domain) {
        Write-Host "`nYour Calibre-Web should be accessible at: https://$Domain" -ForegroundColor Cyan
    }
} elseif ($failCount -eq 0) {
    Write-Host "⚠ Configuration mostly complete with warnings" -ForegroundColor Yellow
    Write-Host "  Review warnings above and address if needed" -ForegroundColor Yellow
} else {
    Write-Host "✗ Configuration incomplete - please fix failed checks above" -ForegroundColor Red
    Write-Host "`nTroubleshooting:" -ForegroundColor Cyan
    Write-Host "  Documentation: docs\Calibre-Web_Remote_Access_Guide.md" -ForegroundColor Gray
    Write-Host "  Section: Troubleshooting" -ForegroundColor Gray
}

Write-Host ""
