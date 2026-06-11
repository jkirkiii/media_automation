# Diagnose-TrackerSeeding.ps1
# Why qBittorrent shows "seeding" but trackers don't. Read-only diagnostic.
param([int]$qBitPort = 8080)

$configPath = Join-Path $PSScriptRoot "..\config.ps1"
. $configPath
$base = "http://localhost:$qBitPort"

Invoke-WebRequest -Uri "$base/api/v2/auth/login" -Method POST -Body "username=$qBittorrentUsername&password=$qBittorrentPassword" -SessionVariable qb -UseBasicParsing | Out-Null

# --- Connection status + listen port qB believes it has ---
$info  = Invoke-RestMethod -Uri "$base/api/v2/transfer/info" -WebSession $qb
$prefs = Invoke-RestMethod -Uri "$base/api/v2/app/preferences" -WebSession $qb

Write-Host "`n=== qBittorrent network state ===" -ForegroundColor Cyan
Write-Host ("Connection status     : {0}" -f $info.connection_status)
Write-Host ("Listen port (prefs)   : {0}" -f $prefs.listen_port)
Write-Host ("Random port           : {0}" -f $prefs.random_port)
Write-Host ("UPnP/NAT-PMP           : {0}" -f $prefs.upnp)
Write-Host ("Bound interface       : '{0}'" -f $prefs.current_network_interface)
Write-Host ("Bound interface addr  : '{0}'" -f $prefs.current_interface_address)
Write-Host ("Announce to all tiers : {0}" -f $prefs.announce_to_all_tiers)
Write-Host ("Announce IP (override): '{0}'" -f $prefs.announce_ip)
Write-Host ("anonymous_mode        : {0}" -f $prefs.anonymous_mode)

# --- Compare against the live NAT-PMP forwarded port ---
function Get-NatPmpPort {
    param([int]$Opcode = 2)
    $c = New-Object System.Net.Sockets.UdpClient
    try {
        $c.Client.ReceiveTimeout = 3000
        $c.Connect('10.2.0.1', 5351)
        $req = New-Object byte[] 12
        $req[0]=0; $req[1]=[byte]$Opcode; $req[7]=1; $req[11]=60
        [void]$c.Send($req, $req.Length)
        $r = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
        $resp = $c.Receive([ref]$r)
        if ($resp.Length -lt 16) { return $null }
        if ((([int]$resp[2] -shl 8) -bor [int]$resp[3]) -ne 0) { return $null }
        return ([int]$resp[10] -shl 8) -bor [int]$resp[11]
    } catch { return $null } finally { $c.Close() }
}
$fwd = Get-NatPmpPort
Write-Host ("NAT-PMP forwarded port: {0}" -f $fwd)
if ($fwd -and $fwd -ne $prefs.listen_port) {
    Write-Host "  MISMATCH: qBittorrent listen port does not equal the forwarded port!" -ForegroundColor Red
} elseif ($fwd) {
    Write-Host "  OK: listen port matches forwarded port." -ForegroundColor Green
}

# --- Tracker announce messages across torrents ---
$torrents = Invoke-RestMethod -Uri "$base/api/v2/torrents/info" -WebSession $qb
Write-Host ("`n=== Tracker status sample (of {0} torrents) ===" -f $torrents.Count) -ForegroundColor Cyan

$msgCounts = @{}
$sample = $torrents | Select-Object -First 8
foreach ($t in $sample) {
    $trk = Invoke-RestMethod -Uri "$base/api/v2/torrents/trackers?hash=$($t.hash)" -WebSession $qb
    # status: 0 disabled, 1 not contacted, 2 working, 3 updating, 4 not working
    $real = $trk | Where-Object { $_.url -like 'http*' -or $_.url -like 'udp*' }
    foreach ($tr in $real) {
        $statusName = switch ($tr.status) { 0 {'disabled'} 1 {'not contacted'} 2 {'WORKING'} 3 {'updating'} 4 {'NOT WORKING'} default {"s$($tr.status)"} }
        $key = "$statusName :: $($tr.msg)"
        if ($msgCounts.ContainsKey($key)) { $msgCounts[$key]++ } else { $msgCounts[$key] = 1 }
    }
    $first = $real | Select-Object -First 1
    $nm = if ($t.name.Length -gt 45) { $t.name.Substring(0,45) } else { $t.name }
    $st = switch ($first.status) { 2 {'WORKING'} 4 {'NOT WORKING'} 1 {'not contacted'} 3 {'updating'} default {"s$($first.status)"} }
    Write-Host ("  [{0,-13}] {1}" -f $st, $nm)
    if ($first.msg) { Write-Host ("      msg: {0}" -f $first.msg) -ForegroundColor Yellow }
}

Write-Host "`n=== Aggregated tracker status :: message ===" -ForegroundColor Cyan
$msgCounts.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    Write-Host ("  {0,3}x  {1}" -f $_.Value, $_.Key)
}
Write-Host ""
