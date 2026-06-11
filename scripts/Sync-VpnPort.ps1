# Sync-VpnPort.ps1
# Keeps ProtonVPN's forwarded port alive and synced into qBittorrent automatically.
#
# How it works:
#   ProtonVPN port forwarding (both the GUI app today and a manual WireGuard tunnel
#   later) is driven by NAT-PMP against the VPN gateway (10.2.0.1). This script speaks
#   NAT-PMP directly over UDP (no natpmpc.exe dependency), renews the mapping lease, and
#   whenever the forwarded port differs from qBittorrent's listening port it updates
#   qBittorrent via its Web API and force-reannounces all torrents.
#
# WireGuard migration note:
#   Today the ProtonVPN GUI app renews the NAT-PMP lease for you; our renewals here are
#   harmless duplicates. After you migrate to a bare WireGuard tunnel (no GUI), THIS loop
#   becomes the thing that keeps the port alive -- the 60s lease must be renewed inside
#   that window, which is why the default interval is 45s. The gateway and protocol do
#   not change, so no code change is required for the migration.
#
# Usage:
#   .\scripts\Sync-VpnPort.ps1 -Once    # single pass, prints result (use to test)
#   .\scripts\Sync-VpnPort.ps1          # run forever (used by the scheduled task)

param(
    [string]$Gateway = '10.2.0.1',
    [int]$qBitPort = 8080,
    [int]$IntervalSeconds = 45,
    [int]$LeaseSeconds = 60,
    [switch]$Once
)

# --- Load credentials from config.ps1 (sibling of the scripts folder) ---
$configPath = Join-Path $PSScriptRoot "..\config.ps1"
if (-not (Test-Path $configPath)) { throw "config.ps1 not found at $configPath" }
. $configPath
$qbUser = $qBittorrentUsername
$qbPass = $qBittorrentPassword

# --- Logging ---
$logDir = Join-Path $PSScriptRoot "..\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logFile = Join-Path $logDir "vpn_port_sync.log"
function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $logFile -Value $line
    $color = 'Gray'
    if ($Level -eq 'WARN')   { $color = 'Yellow' }
    if ($Level -eq 'ERROR')  { $color = 'Red' }
    if ($Level -eq 'CHANGE') { $color = 'Green' }
    Write-Host $line -ForegroundColor $color
}

# --- NAT-PMP (RFC 6886) over raw UDP ---
function Request-NatPmpMapping {
    param([int]$Opcode, [int]$Lease)   # Opcode 1 = UDP, 2 = TCP
    $client = New-Object System.Net.Sockets.UdpClient
    try {
        $client.Client.ReceiveTimeout = 3000
        $client.Connect($Gateway, 5351)
        $req = New-Object byte[] 12
        $req[0] = 0                 # version
        $req[1] = [byte]$Opcode     # opcode
        # bytes 2-3 reserved, 4-5 internal port = 0 (ProtonVPN convention)
        $req[7] = 1                 # suggested external port (gateway assigns the real one)
        # bytes 8-11 = requested lease, big-endian uint32
        $req[8]  = [byte](([int]$Lease -shr 24) -band 0xFF)
        $req[9]  = [byte](([int]$Lease -shr 16) -band 0xFF)
        $req[10] = [byte](([int]$Lease -shr 8)  -band 0xFF)
        $req[11] = [byte]([int]$Lease -band 0xFF)
        [void]$client.Send($req, $req.Length)
        $remote = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
        $resp = $client.Receive([ref]$remote)
        if ($resp.Length -lt 16) { return $null }
        $result = ([int]$resp[2] -shl 8) -bor [int]$resp[3]
        if ($result -ne 0) { return $null }
        # Mapped external port = bytes 10-11. Cast to [int] BEFORE shifting:
        # [byte] -shl 8 overflows within the 8-bit type and silently yields 0.
        $mapped = ([int]$resp[10] -shl 8) -bor [int]$resp[11]
        return $mapped
    } catch {
        return $null
    } finally {
        $client.Close()
    }
}

function Get-ForwardedPort {
    param([int]$Lease)
    # Renew both protocols; ProtonVPN returns the same external port for each.
    $udp = Request-NatPmpMapping -Opcode 1 -Lease $Lease
    $tcp = Request-NatPmpMapping -Opcode 2 -Lease $Lease
    if ($tcp) { return $tcp }
    return $udp
}

# --- qBittorrent Web API ---
$script:qbSession = $null
function Connect-QBit {
    $base = "http://localhost:$qBitPort"
    Invoke-WebRequest -Uri "$base/api/v2/auth/login" -Method POST -Body "username=$qbUser&password=$qbPass" -SessionVariable qbSession -UseBasicParsing | Out-Null
    $script:qbSession = $qbSession
}
function Get-QBitPort {
    $base = "http://localhost:$qBitPort"
    $prefs = Invoke-RestMethod -Uri "$base/api/v2/app/preferences" -WebSession $script:qbSession
    return [int]$prefs.listen_port
}
function Set-QBitPort {
    param([int]$NewPort)
    $base = "http://localhost:$qBitPort"
    $json = '{"listen_port":' + $NewPort + ',"random_port":false}'
    $body = "json=" + [uri]::EscapeDataString($json)
    Invoke-WebRequest -Uri "$base/api/v2/app/setPreferences" -Method POST -Body $body -WebSession $script:qbSession -UseBasicParsing | Out-Null
}
function Invoke-QBitReannounce {
    $base = "http://localhost:$qBitPort"
    Invoke-WebRequest -Uri "$base/api/v2/torrents/reannounce?hashes=all" -Method POST -WebSession $script:qbSession -UseBasicParsing | Out-Null
}

function Sync-Once {
    $port = Get-ForwardedPort -Lease $LeaseSeconds
    if (-not $port) {
        Write-Log "NAT-PMP query failed (VPN down or port forwarding off?). Will retry." 'WARN'
        return
    }
    try {
        if (-not $script:qbSession) { Connect-QBit }
        $current = Get-QBitPort
    } catch {
        Write-Log ("qBittorrent login/query failed: " + $_.Exception.Message) 'WARN'
        $script:qbSession = $null
        return
    }
    if ($current -ne $port) {
        try {
            Set-QBitPort -NewPort $port
            Invoke-QBitReannounce
            Write-Log ("Forwarded port changed {0} -> {1}. Updated qBittorrent and reannounced all torrents." -f $current, $port) 'CHANGE'
        } catch {
            Write-Log ("Failed to update qBittorrent port to {0}: {1}" -f $port, $_.Exception.Message) 'ERROR'
            $script:qbSession = $null
        }
    } elseif ($Once) {
        Write-Log ("Forwarded port {0} already matches qBittorrent. No change." -f $port)
    }
}

Write-Log ("Sync-VpnPort starting. gateway={0} qBitPort={1} interval={2}s lease={3}s" -f $Gateway, $qBitPort, $IntervalSeconds, $LeaseSeconds)
if ($Once) {
    Sync-Once
    Write-Log "Single pass complete (-Once)."
    return
}
while ($true) {
    Sync-Once
    Start-Sleep -Seconds $IntervalSeconds
}
