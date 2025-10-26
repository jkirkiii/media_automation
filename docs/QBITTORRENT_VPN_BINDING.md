# qBittorrent VPN Network Binding Guide

## The Problem

**Symptom**: Torrents show "Not contacted yet" on all trackers, tracker websites show you as not seeding.

**Root Cause**: qBittorrent's network interface binding changed from NordVPN (NordLynx) to local network adapter, causing complete network disconnection.

---

## Why This Happens

When using NordVPN with qBittorrent:
1. qBittorrent binds to a specific network adapter (NordLynx)
2. If NordVPN reconnects, changes servers, or Windows updates network settings
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
4. Back to **"NordLynx"** (or your VPN's adapter name)
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
- ✅ Only allows torrenting through VPN
- ✅ If VPN disconnects, torrenting stops (no IP leak)
- ✅ Best for privacy/security

**Cons:**
- ❌ Requires manual fix when VPN adapter changes
- ❌ qBittorrent breaks if VPN disconnects

**How to set:**
1. Tools → Options → Advanced
2. Network Interface: **NordLynx** (or your VPN adapter)
3. Click Apply

### Option 2: Bind to "Any Interface" (Easier but Less Secure)

**Pros:**
- ✅ Never breaks when VPN reconnects
- ✅ No manual intervention needed
- ✅ Always stays connected

**Cons:**
- ❌ Will torrent over regular internet if VPN disconnects (IP LEAK!)
- ❌ Not recommended for private trackers

**How to set:**
1. Tools → Options → Advanced
2. Network Interface: **Any interface**
3. Click Apply

### Option 3: Use Kill Switch (Best Security + Convenience)

**Best approach:**
1. Bind qBittorrent to "Any interface"
2. Enable NordVPN's Kill Switch
   - NordVPN Settings → Kill Switch → **Enable**
3. If VPN drops, Kill Switch blocks all internet
4. No IP leaks, and no manual fixing needed

**This combines:**
- ✅ No manual intervention when VPN changes
- ✅ No IP leaks (kill switch prevents it)
- ✅ Always works when VPN is connected

---

## How to Identify the VPN Adapter

### Method 1: PowerShell
```powershell
Get-NetAdapter | Select-Object Name, InterfaceDescription, Status
```

Look for:
- **NordLynx** (NordVPN WireGuard)
- **TAP-NordVPN** (NordVPN OpenVPN)
- Status should be **Up**

### Method 2: Windows Settings
1. Settings → Network & Internet → Advanced network settings
2. Look for NordVPN adapters
3. Note the exact name

### Method 3: In qBittorrent
1. Tools → Options → Advanced → Network Interface
2. Click dropdown
3. All available adapters are listed

---

## Detection: How to Know This Is Happening

### Symptoms:
1. ✅ qBittorrent shows torrents as "seeding" or "stalledUP"
2. ✅ Tracker websites show "not seeding"
3. ✅ All trackers show "Not contacted yet"
4. ✅ Running `Check-qBittorrent-Settings.ps1` shows "Connection Status: disconnected"

### When It Typically Happens:
- After Windows updates
- After NordVPN reconnects or changes servers
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

1. **Use NordVPN Kill Switch** (prevents IP leaks)
   - NordVPN → Settings → Kill Switch → Enable

2. **Bind to "Any Interface"** in qBittorrent
   - Tools → Options → Advanced → Network Interface → Any interface

3. **Enable "Only announce to all trackers"**
   - Tools → Options → BitTorrent → Privacy → ✅ Enable anonymous mode

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
1. Tools → Options → Advanced → Network Interface → NordLynx
2. Run `Force-Reannounce-All.ps1`

**Prevention**:
1. Bind to "Any interface"
2. Enable NordVPN Kill Switch
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
- NordVPN Support: Kill Switch setup
- `docs/FIXING_TRACKER_SEEDING_ISSUES.md` - General tracker troubleshooting
