# Fix qBittorrent Network Connection
param([string]$user='murdoch137', [int]$port=8080)

Write-Host "`nqBittorrent Network Fix`n" -ForegroundColor Cyan

$pass = Read-Host 'qBittorrent password' -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$base = "http://localhost:$port"

$login = Invoke-WebRequest -Uri "$base/api/v2/auth/login" -Method POST -Body "username=$user&password=$password" -SessionVariable qb

if ($login.Content -ne 'Ok.') {
    Write-Host "Login failed" -ForegroundColor Red
    exit
}

Write-Host "Connected to qBittorrent API`n" -ForegroundColor Green

# Get current preferences
$prefs = Invoke-RestMethod -Uri "$base/api/v2/app/preferences" -WebSession $qb

Write-Host "Current Network Interface: $($prefs.current_network_interface)" -ForegroundColor Yellow
Write-Host "Current Interface Address: $($prefs.current_interface_address)" -ForegroundColor Yellow

Write-Host "`nAttempting to reset network interface to 'Any'...`n" -ForegroundColor Cyan

# Set network interface to "Any" (empty string means any interface)
$newPrefs = @{
    current_network_interface = ""
    listen_on_ipv6 = $true
}

try {
    Invoke-RestMethod -Uri "$base/api/v2/app/setPreferences" -Method POST -Body "json=$($newPrefs | ConvertTo-Json -Compress)" -WebSession $qb
    Write-Host "Network interface set to 'Any'" -ForegroundColor Green

    Write-Host "`nWaiting 5 seconds for qBittorrent to reconnect..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5

    # Check connection status
    $transferInfo = Invoke-RestMethod -Uri "$base/api/v2/transfer/info" -WebSession $qb

    Write-Host "`nConnection Status: $($transferInfo.connection_status)" -ForegroundColor $(if ($transferInfo.connection_status -eq 'connected') { 'Green' } else { 'Red' })

    if ($transferInfo.connection_status -eq 'connected') {
        Write-Host "`nSuccess! qBittorrent is now connected." -ForegroundColor Green
        Write-Host "`nNext steps:" -ForegroundColor Cyan
        Write-Host "  1. Run Force-Reannounce-All.ps1 again" -ForegroundColor White
        Write-Host "  2. Wait 2-3 minutes" -ForegroundColor White
        Write-Host "  3. Check tracker status in qBittorrent" -ForegroundColor White
    } else {
        Write-Host "`nStill disconnected. Additional troubleshooting needed." -ForegroundColor Yellow
        Write-Host "`nPossible causes:" -ForegroundColor Cyan
        Write-Host "  - NordVPN blocking qBittorrent" -ForegroundColor White
        Write-Host "  - Firewall blocking connections" -ForegroundColor White
        Write-Host "  - Port forwarding issues" -ForegroundColor White
        Write-Host "`nTry:" -ForegroundColor Cyan
        Write-Host "  1. Restart qBittorrent completely" -ForegroundColor White
        Write-Host "  2. Check Windows Firewall settings" -ForegroundColor White
        Write-Host "  3. Verify NordVPN allows P2P on this server" -ForegroundColor White
    }

} catch {
    Write-Host "Error setting preferences: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
