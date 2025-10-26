# Fixing Private Tracker Seeding Issues

**Your Issue:** Torrents show "seeding" in qBittorrent but tracker websites say "not seeding"

---

## Understanding the Problem

When qBittorrent says you're seeding but the tracker website doesn't show it, there's a communication breakdown between your client and the tracker server. The tracker hasn't received recent "announce" updates from qBittorrent confirming you're still seeding.

### Why This Matters

On private trackers:
- ⚠️ You may not get upload credit even though you're seeding
- ⚠️ Tracker may think you're a hit-and-run violator
- ⚠️ Your ratio won't improve even if uploading data
- ⚠️ Could lead to warnings or account issues

---

## Common Causes & Solutions

### 1. Tracker Hasn't Received Recent Announce (Most Common)

**Symptoms:**
- qBittorrent says "Seeding"
- Tracker website says "Not seeding" or shows old timestamp
- No error messages in qBittorrent

**Solution: Force Re-announce**

**In qBittorrent:**
1. Find the torrent
2. Right-click → **"Force reannounce"**
3. Wait 30-60 seconds
4. Check tracker website again

**What this does:**
- Forces qBittorrent to immediately contact tracker
- Updates tracker with current status
- Should show as seeding within 1-2 minutes

**If this works:** Problem solved! But investigate why announces weren't happening automatically.

---

### 2. Passkey Changed or Invalid Tracker URL

**Symptoms:**
- Error message: "Not registered with tracker"
- Error message: "Unregistered torrent"
- Error message: "Invalid passkey"

**What happened:**
- You reset your passkey on tracker website
- Tracker changed announce URLs
- Old .torrent file has outdated passkey

**Solution: Update Tracker URL**

**Step 1: Get your current announce URL**
1. Go to tracker website (TorrentDay or TorrentLeech)
2. Find your profile/settings
3. Copy your **announce URL** (looks like):
   ```
   https://tracker.torrentday.com:443/announce.php?passkey=YOUR_PASSKEY
   ```
   or
   ```
   https://tracker.torrentleech.org:443/announce.php?passkey=YOUR_PASSKEY
   ```

**Step 2: Update in qBittorrent**
1. Right-click torrent
2. **Edit trackers**
3. Find the old tracker URL
4. Replace with new URL (from Step 1)
5. Click OK
6. Right-click → **Force reannounce**

**Alternative: Re-download torrent file**
1. Go to tracker website
2. Find the torrent (search for name)
3. Download fresh .torrent file
4. In qBittorrent: Add torrent
5. Point to **existing download location**
6. qBittorrent will recheck and update tracker

---

### 3. Port Forwarding / Connectivity Issues

**Symptoms:**
- Some torrents connect, others don't
- Low peer connections
- Tracker shows you as "connectable: no"

**What's happening:**
- Tracker can't reach your qBittorrent to verify seeding
- Incoming connections blocked
- Firewall or NAT issue

**Solution: Enable Port Forwarding**

**In qBittorrent:**
1. Tools → Options → Connection
2. Enable **"Use UPnP / NAT-PMP port forwarding"**
3. Note the **Listening port** (e.g., 6881)
4. Click **Apply**

**Test connectivity:**
1. Tools → Options → Connection
2. Click **"Random port"** and restart qBittorrent
3. Or manually forward the port in your router

**If using VPN (NordVPN):**
- Some VPN servers don't support port forwarding
- Try different NordVPN server
- Or use NordVPN's P2P-optimized servers
- Check NordVPN docs for port forwarding setup

---

### 4. VPN Blocking Tracker Communication

**Symptoms:**
- Torrents were seeding fine, then stopped
- Connected to VPN and issues started
- Tracker errors: "Connection timeout"

**What's happening:**
- NordVPN may be blocking tracker announce URLs
- VPN's firewall blocking UDP announces
- Split tunneling misconfigured

**Solution: Check VPN Settings**

**In NordVPN:**
1. Open NordVPN settings
2. Check **Split Tunneling**
3. Ensure qBittorrent is routed through VPN
4. Ensure tracker URLs aren't blocked

**Test without VPN (temporarily):**
1. Disconnect NordVPN
2. Force reannounce in qBittorrent
3. Check if tracker updates
4. If yes: VPN is the issue

**If VPN is the issue:**
- Try different NordVPN server (preferably P2P server)
- Enable port forwarding in NordVPN (if supported)
- Whitelist tracker domains in VPN settings
- Check NordVPN kill switch settings

---

### 5. Tracker Temporarily Down

**Symptoms:**
- Error: "Connection timed out"
- Error: "Could not contact tracker"
- Multiple torrents from same tracker affected

**Solution:**
1. Check tracker website status
2. Check tracker's status page or forum
3. Wait and try force reannounce later
4. Not your fault - just wait it out

---

### 6. qBittorrent Not Announcing Regularly

**Symptoms:**
- Announces work when forced
- Don't work automatically
- Long gaps between announces

**Solution: Check Announce Intervals**

**In qBittorrent:**
1. Right-click torrent → **Properties**
2. Check **Trackers** tab
3. Look at **Next announce**
4. Should be 5-30 minutes

**If announces aren't happening:**
1. Tools → Options → Advanced
2. Check **"Announce to all trackers"** is enabled
3. Restart qBittorrent

---

## Step-by-Step Diagnostic Process

### Step 1: Run Diagnostic Script

```powershell
cd C:\Users\rokon\source\media_automation
.\scripts\Diagnose-Tracker-Issues.ps1
```

This will show:
- Which torrents have tracker issues
- Error messages from trackers
- qBittorrent connection settings
- VPN status

### Step 2: Force Reannounce (Try First)

**For all affected torrents:**
1. Select torrents showing the issue
2. Right-click → **Force reannounce**
3. Wait 1-2 minutes
4. Check tracker websites

**If this fixes it:** Great! But continue to Step 3 to prevent recurrence.

### Step 3: Check Tracker URLs

**For TorrentDay torrents:**
1. Go to https://torrentday.com
2. My Account → Security
3. Copy your announce URL
4. Compare with URLs in qBittorrent
5. Update if different

**For TorrentLeech torrents:**
1. Go to https://torrentleech.org
2. Profile → Keys & URLs
3. Copy announce URL
4. Compare and update

### Step 4: Test Connectivity

**Check if qBittorrent is connectable:**
1. Tools → Options → Connection
2. Note your listening port
3. Visit: https://canyouseeme.org/
4. Enter your port
5. If "closed": enable UPnP or forward port

### Step 5: Verify VPN

**Ensure VPN not blocking:**
1. Temporarily disconnect NordVPN
2. Force reannounce
3. If it works: VPN is blocking
4. Reconnect and configure VPN properly

---

## Quick Fixes Checklist

Try these in order:

- [ ] **Force reannounce** all affected torrents
- [ ] **Wait 2 minutes** and check tracker websites
- [ ] **Update passkeys** if announce URLs are old
- [ ] **Enable UPnP** in qBittorrent settings
- [ ] **Check VPN** isn't blocking trackers
- [ ] **Re-download .torrent files** from tracker website
- [ ] **Restart qBittorrent** to reset connections
- [ ] **Check tracker status** (might be temporary tracker issue)

---

## Preventing Future Issues

### Regular Maintenance

**Weekly:**
- Check tracker websites for seeding status
- Verify upload credit is increasing
- Force reannounce if any discrepancies

**Monthly:**
- Verify passkeys haven't changed
- Check qBittorrent connection settings
- Test port forwarding still works

### Best Practices

**When downloading from Sonarr:**
1. After import completes, check tracker website
2. Verify torrent shows as seeding
3. If not, force reannounce immediately

**VPN Configuration:**
1. Use NordVPN P2P servers for torrenting
2. Enable split tunneling for qBittorrent
3. Ensure kill switch doesn't block tracker announces
4. Test periodically that VPN allows tracker communication

**qBittorrent Settings:**
1. Keep UPnP enabled
2. Don't change listening port frequently
3. Enable "Announce to all trackers"
4. Set reasonable announce intervals

---

## Tracker-Specific Notes

### TorrentDay

**Common issues:**
- Passkey resets when you change password
- Strict about announcing intervals
- May show "not seeding" for first 5 minutes

**Solutions:**
- Always force reannounce after password changes
- Wait 5 minutes before panicking
- Check "My Torrents" page for accurate status

### TorrentLeech

**Common issues:**
- Very strict about hit-and-runs
- Requires announces every 30 minutes
- May prune old torrents from database

**Solutions:**
- Ensure announces are working regularly
- Don't stop/start torrents frequently
- Re-download .torrent if "not registered" error

### Darkpeers

**Common issues:**
- API-based tracker (different announce method)
- May not show real-time seeding status
- Website updates slower than actual seeding

**Solutions:**
- API tracker URLs look different
- Check API key in announce URL
- Website may lag 5-10 minutes

### MyAnonamouse

**Common issues:**
- Very strict ratio requirements
- Specific announce URL format
- Requires "freeleech" tokens for some content

**Solutions:**
- Use correct announce URL from profile
- Check if using ebook-specific tracker URLs
- Verify category matches (books vs audiobooks)

---

## When to Contact Tracker Support

Contact tracker support if:

- ✅ You've force reannounced multiple times
- ✅ Passkey is correct and up to date
- ✅ qBittorrent is connectable (port forwarded)
- ✅ VPN isn't blocking
- ✅ Issue persists for 24+ hours
- ✅ Multiple torrents from same tracker affected

**What to include in support request:**
- Your username
- Torrent name/ID
- Error message from qBittorrent
- Screenshot of tracker tab in qBittorrent
- Confirmation you've force reannounced
- Your announce URL (hide passkey for security)

---

## Emergency: Hit-and-Run Warning

If you receive hit-and-run warning due to this issue:

1. **Don't panic** - explain the technical issue
2. **Force reannounce immediately** on all affected torrents
3. **Screenshot** qBittorrent showing you're seeding
4. **Contact tracker support** with evidence
5. **Continue seeding** - most trackers are understanding

**Most trackers will:**
- Remove warning if you explain and fix issue
- Give grace period if you've been good member
- Understand technical issues vs intentional violations

---

## Testing Your Fix

After applying fixes:

1. **Force reannounce** all affected torrents
2. **Wait 2-3 minutes**
3. **Check tracker websites:**
   - TorrentDay: My Torrents
   - TorrentLeech: Profile → Torrents
4. **Verify status shows "Seeding"**
5. **Check upload stats** are increasing
6. **Monitor for 24 hours** to ensure it sticks

---

## Advanced: Checking Tracker Communication

**View qBittorrent logs:**
1. View → Log
2. Filter for "announce"
3. Look for errors or failures

**Check announce timestamps:**
1. Right-click torrent → Properties
2. Trackers tab
3. Check "Last announce" time
4. Should be recent (within last 30 min)

**Manual announce test:**
1. Copy announce URL from qBittorrent
2. Replace `announce.php` with `scrape.php`
3. Paste in browser (won't work, but check error)
4. Should NOT say "invalid passkey"

---

## Summary

**Most common cause:** Tracker hasn't received recent announce
**Easiest fix:** Force reannounce in qBittorrent
**If that doesn't work:** Update passkey/tracker URL
**Prevention:** Enable UPnP, check VPN settings, monitor regularly

**Remember:** Private trackers are strict, but most issues are technical and fixable. Don't panic - just troubleshoot methodically!

---

## Quick Reference Commands

### Run diagnostics:
```powershell
.\scripts\Diagnose-Tracker-Issues.ps1
```

### Get your current announce URLs:
- **TorrentDay:** Profile → Security
- **TorrentLeech:** Profile → Keys & URLs
- **Darkpeers:** Profile → API
- **MyAnonamouse:** Profile → Settings

### Force reannounce in qBittorrent:
Right-click → Force reannounce (or Ctrl+R)
