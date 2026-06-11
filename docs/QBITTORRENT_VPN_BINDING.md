# qBittorrent VPN Network Binding Guide

## The Problem

**Symptom**: Torrents show "Not contacted yet" on all trackers, tracker websites show you as not seeding.

**Root Cause**: qBittorrent's network interface binding changed from ProtonVPN to local network adapter, causing complete network disconnection.

---

## Why This Happens

When using ProtonVPN with qBittorrent:
1. qBittorrent binds to a specific network adapter (ProtonVPN)
2. If ProtonVPN reconnects, changes servers, or Windows updates network settings
3. The network adapter name/ID can change
4. qBittorrent becomes bound to a non-existent or wrong adapter
5. Result: "Connection Status: disconnected" and no tracker communication

---

## Quick Fix (When It Happens)

### Step 1: Check Connection Status

Run this script to verify qBittorrent is disconnected:
```powershell
.\scripts\Check-qBittorrent-Settings.ps1
```

Look for:
```
Connection Status: disconnected
```

### Step 2: Fix Network Binding

**In qBittorrent:**
1. **Tools → Options → Advanced**
2. **Network Interface** section
3. Change from "Local Network Adapter 2" (or whatever it's set to)
4. Back to **"ProtonVPN"** (or your VPN's adapter name)
5. Click **Apply** and **OK**

### Step 3: Force Reannounce

```powershell
.\scripts\Force-Reannounce-All.ps1
```

Wait 2-3 minutes, then check tracker status.

---

## Permanent Solution Options

### Option 1: Bind to VPN Adapter (Recommended for Privacy)

**Pros:**
- Only allows torrenting through VPN
- If VPN disconnects, torrenting stops (no IP leak)
- Best for privacy/security

**Cons:**
- Requires manual fix when VPN adapter changes
- qBittorrent breaks if VPN disconnects

**How to set:**
1. Tools → Options → Advanced
2. Network Interface: **ProtonVPN** (or your VPN adapter)
3. Click Apply

### Option 2: Bind to "Any Interface" (Easier but Less Secure)

**Pros:**
- Never breaks when VPN reconnects
- No manual intervention needed
- Always stays connected

**Cons:**
- Will torrent over regular internet if VPN disconnects (IP LEAK!)
- Not recommended for private trackers

**How to set:**
1. Tools → Options → Advanced
2. Network Interface: **Any interface**
3. Click Apply

### Option 3: Use Kill Switch (Best Security + Convenience)

**Best approach:**
1. Bind qBittorrent to "Any interface"
2. Enable ProtonVPN's Kill Switch
   - ProtonVPN → Settings → Connection → **Kill Switch** → Enable
3. If VPN drops, Kill Switch blocks all internet
4. No IP leaks, and no manual fixing needed

**This combines:**
- No manual intervention when VPN changes
- No IP leaks (kill switch prevents it)
- Always works when VPN is connected

---

## How to Identify the VPN Adapter

### Method 1: PowerShell
```powershell
Get-NetAdapter | Select-Object Name, InterfaceDescription, Status
```

Look for:
- **ProtonVPN** (ProtonVPN WireGuard - default protocol)
- **ProtonVPN TAP** (ProtonVPN OpenVPN)
- Status should be **Up**

### Method 2: Windows Settings
1. Settings → Network & Internet → Advanced network settings
2. Look for ProtonVPN adapters
3. Note the exact name

### Method 3: In qBittorrent
1. Tools → Options → Advanced → Network Interface
2. Click dropdown
3. All available adapters are listed

---

## Port Forwarding (ProtonVPN Advantage)

ProtonVPN supports port forwarding on P2P servers (Plus plan and above). This improves tracker reachability and seeding ratios on private trackers.

**Setup:**
1. Connect to a P2P-labeled server in ProtonVPN
2. ProtonVPN → Settings → Connection → **Port Forwarding** → Enable
3. The app displays the assigned port number
4. In qBittorrent: Tools → Options → Connection → **Listening port** → enter that port
5. Uncheck "Use random port at each startup"

> **Note:** ProtonVPN's assigned port changes each session. **This is now automated** -- see "Automated Port Sync" below. You no longer need to read the port from the GUI and type it into qBittorrent by hand.

---

## Automated Sync (Recommended -- replaces manual port AND interface maintenance)

A ProtonVPN reconnect breaks **two** things at once, and `Sync-VpnPort.ps1` now fixes both:

1. **Forwarded port rotates** -- qBittorrent's listening port goes stale.
2. **Tunnel interface renumbers** -- the friendly name stays `ProtonVPN` but the underlying
   `iftype53_NNNNN` value changes (e.g. `iftype53_32772` -> `iftype53_32768`). qBittorrent
   stays bound to the dead interface, shows **Connection status: disconnected**, and silently
   stops announcing to every tracker -- the exact "shows seeding locally but trackers don't"
   symptom this guide is about.

ProtonVPN port forwarding is driven by **NAT-PMP** against the VPN gateway (`10.2.0.1`), both
in the GUI app today and over a bare WireGuard tunnel in the future. `Sync-VpnPort.ps1` speaks
NAT-PMP directly (pure PowerShell, no `natpmpc.exe`), renews the mapping lease, and each pass
reconciles BOTH the listening port and the bound interface (resolved by the stable name
`ProtonVPN`) against reality. If either drifted it updates qBittorrent via the Web API and
force-reannounces. **While the VPN is down it leaves the binding untouched** so the real IP
cannot leak -- it resyncs automatically once the tunnel returns.

To check what's wrong at any time (read-only): `.\scripts\Diagnose-TrackerSeeding.ps1`.

**One-time setup:**
```powershell
# 1. Verify it reads the live port and matches qBittorrent
.\scripts\Sync-VpnPort.ps1 -Once

# 2. Register it to run automatically at logon (Administrator required)
.\scripts\Schedule-VpnPortSync.ps1
Start-ScheduledTask -TaskName "MediaStack VPN Port Sync"
```

**After setup there is nothing to do** when ProtonVPN rotates the port -- the loop detects
the change within ~45 seconds, updates qBittorrent, and reannounces. Activity is logged to
`logs\vpn_port_sync.log`.

**WireGuard migration:** when you move off the GUI app to a manual WireGuard tunnel, no code
changes are needed -- the gateway and NAT-PMP mechanism are identical. The script's lease
renewals (which are redundant while the GUI runs) become the thing that keeps the port alive.
You may optionally switch the scheduled task trigger from logon to startup at that point.

> Why NAT-PMP instead of scraping the GUI: the GUI exposes the port only in its UI with no
> stable file/API on Windows, and that approach would break on the WireGuard migration.
> NAT-PMP works identically in both worlds.

---

## Detection: How to Know This Is Happening

### Symptoms:
1. qBittorrent shows torrents as "seeding" or "stalledUP"
2. Tracker websites show "not seeding"
3. All trackers show "Not contacted yet"
4. Running `Check-qBittorrent-Settings.ps1` shows "Connection Status: disconnected"

### When It Typically Happens:
- After Windows updates
- After ProtonVPN reconnects or changes servers
- After VPN settings changes
- After computer restart
- After network adapter driver updates

---

## Automated Monitoring (Future Enhancement)

You could create a scheduled task that runs every 30 minutes:

```powershell
# Check-And-Fix-Network.ps1
$transferInfo = Invoke-RestMethod -Uri "http://localhost:8080/api/v2/transfer/info" -WebSession $qb

if ($transferInfo.connection_status -ne 'connected') {
    # Send notification or auto-fix
    Write-Host "qBittorrent disconnected! Needs attention."
}
```

---

## Best Practices

### Recommended Setup:

1. **Use ProtonVPN Kill Switch** (prevents IP leaks)
   - ProtonVPN → Settings → Connection → Kill Switch → Enable

2. **Bind to "Any Interface"** in qBittorrent
   - Tools → Options → Advanced → Network Interface → Any interface

3. **Enable "Only announce to all trackers"**
   - Tools → Options → BitTorrent → Privacy → Enable anonymous mode

4. **Monitor weekly**
   - Run `Check-qBittorrent-Settings.ps1` weekly
   - Verify "Connection Status: connected"

5. **Force reannounce after VPN changes**
   - If you change VPN servers
   - If you reconnect VPN
   - Run `Force-Reannounce-All.ps1`

---

## Testing Your Setup

### After Configuration:

1. **Check connection status:**
   ```powershell
   .\scripts\Check-qBittorrent-Settings.ps1
   ```
   Should show: `Connection Status: connected`

2. **Force reannounce:**
   ```powershell
   .\scripts\Force-Reannounce-All.ps1
   ```

3. **Wait 3 minutes**, then check tracker tab in qBittorrent
   - Should show "Working" status
   - Should show message like "Announce OK" or seeders/leechers count

4. **Check tracker websites**
   - TorrentDay: My Torrents
   - TorrentLeech: Profile → Torrents
   - Should show as "Seeding" with recent "Last Seen"

---

## Summary

**Root Cause**: VPN adapter changed, qBittorrent bound to wrong interface

**Quick Fix**:
1. Tools → Options → Advanced → Network Interface → ProtonVPN
2. Run `Force-Reannounce-All.ps1`

**Prevention**:
1. Bind to "Any interface"
2. Enable ProtonVPN Kill Switch
3. Monitor connection status weekly

**When to Check**:
- After VPN reconnects
- After Windows updates
- After computer restarts
- Weekly monitoring

---

## Related Scripts

- `Check-qBittorrent-Settings.ps1` - Check current network status
- `Force-Reannounce-All.ps1` - Force all torrents to contact trackers
- `Fix-qBittorrent-Network.ps1` - Auto-fix network binding (sets to "Any")

---

## Additional Resources

- qBittorrent FAQ: Network binding
- ProtonVPN Support: Kill Switch and Port Forwarding setup
- `docs/FIXING_TRACKER_SEEDING_ISSUES.md` - General tracker troubleshooting
