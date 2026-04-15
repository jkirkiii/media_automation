# Sonarr Setup - Complete!

**Date:** 2025-10-25
**Status:** ✅ Fully Operational

---

## Summary

Sonarr has been successfully installed, configured, and is now managing your TV show library with automated downloads.

---

## System Status

### Installation Details
- **Version:** Sonarr v4.0.15.2941
- **Installation Type:** Windows Native Service
- **Port:** 8989
- **Access URL:** http://localhost:8989
- **API Key:** (stored in config.xml — see config.ps1)

### Library Status
- **Root Folder:** A:\Media\TV Shows
- **Free Space:** 4.21 TB
- **Total Shows:** 31 imported
- **Monitored:** 27 shows (will auto-download new episodes)
- **Library Only:** 4 shows (organized but not monitored)

### Connected Services

**Prowlarr Integration:**
- ✅ Connected successfully
- ✅ 3 indexers synced:
  - Darkpeers (API)
  - TorrentDay
  - TorrentLeech
- Note: MyAnonamouse may not have TV categories enabled

**Download Client:**
- ✅ qBittorrent connected
- Port: 8080
- Username: (see config.ps1)
- Category: tv-sonarr
- **Remove after import:** NO (respects 10-day seed requirement)

**Plex Server:**
- Server: Mnemosyne
- Integration: To be configured (optional)
- Auto-scan: Can be enabled after testing

---

## Configuration Summary

### Quality Profile: HD-1080p
- **Preferred Quality:** 1080p WEB-DL
- **Strategy:** Conservative
- **Upgrade Allowed:** Yes (conservative)
- **Cutoff:** WEBDL-1080p (stop upgrading once achieved)
- **Allowed Qualities:**
  - ✓ HDTV-1080p (will upgrade to WEB-DL)
  - ✓ WEBRip-1080p (will upgrade to WEB-DL)
  - ✓ WEBDL-1080p (PREFERRED - stops here)
  - ✓ Bluray-1080p (allowed but won't actively seek)
  - ✗ 720p and below (disabled)

### Naming Format (Plex Standard)
- **Episodes:** `{Series Title} - S{season:00}E{episode:00} - {Episode Title}`
  - Example: `Breaking Bad - S01E01 - Pilot.mkv`
- **Series Folders:** `{Series Title} ({Series Year})`
  - Example: `Breaking Bad (2008)`
- **Season Folders:** `Season {season:00}`
  - Example: `Season 01`

### Automation Behavior
Based on PROJECT_CONFIGURATION.md preferences:

**For Monitored Shows:**
- Auto-download new episodes immediately when released
- Prefer 1080p WEB-DL quality
- Auto-upgrade propers/repacks
- Include specials
- Download immediately (don't wait for Bluray)

**For Existing Library:**
- Keep what you have (don't re-download)
- Only get new episodes going forward
- Respect conservative upgrade strategy

**Seeding:**
- Files remain in qBittorrent after import
- Manual removal after meeting 10-day/ratio requirements
- Downloads stored in: A:\Downloads\Complete
- Media files copied to: A:\Media\TV Shows\

---

## Upcoming Episodes (Next 7 Days)

Sonarr detected 4 upcoming episodes that will auto-download:
- 10/29 17:00 - S49E06
- 10/29 17:30 - S05E05
- 10/30 00:00 - S02E02
- 10/30 14:00 - S20E08

---

## How It Works

### Automatic Workflow

1. **RSS Monitoring:**
   - Sonarr checks indexers every 60 minutes for new releases
   - Monitors calendar for upcoming episode air dates

2. **Search & Grab:**
   - When episode airs, searches all 3 indexers
   - Selects best quality match (1080p WEB-DL preferred)
   - Sends to qBittorrent with tv-sonarr category

3. **Download:**
   - qBittorrent downloads to A:\Downloads\Incomplete
   - Moves to A:\Downloads\Complete when done
   - Continues seeding

4. **Import:**
   - Sonarr detects completed download
   - Renames per naming format
   - Copies to A:\Media\TV Shows\[Show]\[Season]\
   - Original stays in downloads for seeding
   - Updates Sonarr status to "Downloaded"

5. **Cleanup:**
   - You manually remove from qBittorrent after seed requirements met
   - Periodically clean A:\Downloads\Complete

---

## Daily Usage

### Check Calendar
- View: http://localhost:8989 → Calendar
- See what's airing and what's downloading

### Monitor Activity
- View: http://localhost:8989 → Activity → Queue
- See active downloads and imports

### Add New Shows
1. Series → Add New Series
2. Search for show
3. Select show
4. Choose:
   - **Monitor:** All Episodes (for new shows) or Future Episodes (for ongoing)
   - **Quality Profile:** HD-1080p
   - **Search for missing:** Only if you want to backfill old episodes
5. Add Series

### Manual Search (If Needed)
1. Go to show page
2. Click season or episode
3. Click magnifying glass icon
4. Select release manually
5. Download

---

## Maintenance Tasks

### Weekly
- [ ] Check Activity → Queue for stuck downloads
- [ ] Review Calendar for upcoming episodes
- [ ] Check qBittorrent for torrents meeting seed requirements
- [ ] Clean up old downloads from A:\Downloads\Complete

### Monthly
- [ ] Check System → Status for health warnings
- [ ] Verify 4.2 TB free space on A:\
- [ ] Review and adjust monitored shows if needed
- [ ] Check for Sonarr updates

### As Needed
- [ ] Add new shows when interested
- [ ] Adjust monitoring for shows (Future Episodes vs None)
- [ ] Manual search if auto-grab fails

---

## Troubleshooting

### Episode Didn't Auto-Download
**Check:**
1. Activity → Queue - Is it there?
2. Series → [Show] - Is it monitored?
3. Calendar - Did the episode air yet?
4. System → Logs - Any errors?

**Solutions:**
- Manual search: Click episode → Search icon
- Check indexers: Settings → Indexers (all enabled?)
- Verify Prowlarr connection: Settings → Apps

### Download Stuck
**Check:**
1. qBittorrent - Is it downloading?
2. VPN - Is ProtonVPN connected?
3. Activity → Queue - Any warnings?

**Solutions:**
- Check qBittorrent for errors
- Verify VPN connection
- Check tracker status in qBittorrent

### Import Failed
**Check:**
1. Activity → History - What's the error?
2. File naming - Does it match expected format?
3. Disk space - Enough free on A:\?

**Solutions:**
- Check logs in System → Logs
- Verify qBittorrent completed download
- Manual import: Activity → Manual Import

### Indexer Failures
**Check Prowlarr:**
1. http://localhost:9696
2. Indexers - All green?
3. System → Tasks - Recent sync?

**Solutions:**
- Test indexer in Prowlarr
- Sync apps: Settings → Apps → Test
- Check tracker credentials

---

## Scripts Reference

All scripts located in: `C:\Users\rokon\source\media_automation\scripts\`

### Verification
```powershell
.\Verify-Setup.ps1
```
Shows current status, shows, indexers, upcoming episodes

### Re-sync Indexers
```powershell
.\Sync-Prowlarr-Indexers.ps1
```
Forces Prowlarr to re-sync indexers to Sonarr

### Reconfigure Components (if needed)
```powershell
.\Configure-Sonarr-API.ps1        # Root folder, naming
.\Connect-Prowlarr-To-Sonarr.ps1  # Prowlarr connection
.\Connect-qBittorrent.ps1         # Download client
```

---

## Next Steps

### Immediate
- [x] Sonarr installed and configured
- [x] Library imported
- [x] Automation ready
- [ ] **Wait for first auto-download to test!**
- [ ] Configure Plex integration (optional)
- [ ] Set up email notifications (optional)

### Future Enhancements
- [ ] Configure Plex connection for auto-library updates
- [ ] Set up email/Discord notifications
- [ ] Fine-tune quality profiles if needed
- [ ] Consider Bazarr for subtitles
- [ ] Plan Radarr installation for movies (similar process)
- [ ] Implement media health check system (from PRD)

---

## Important Reminders

### Seeding Requirements
⚠️ **CRITICAL:** Do not remove torrents from qBittorrent until:
- Minimum 10 days seeding time met
- OR tracker-specific ratio requirements met
- Sonarr is configured to NOT auto-remove (verified ✓)

### Storage Management
- Current free space: 4.21 TB
- Monitor to keep at least 500 GB free
- Clean up old downloads periodically
- Average episode size: ~1-2 GB for 1080p WEB-DL

### Tracker Health
- Monitor ratio on all 4 trackers
- Download buffer before mass downloads
- Respect tracker rules and limits

---

## Support Resources

### Documentation
- Sonarr Wiki: https://wiki.servarr.com/sonarr
- This Repo: `docs/Sonarr_Setup_Guide.md` (comprehensive)
- Quick Start: `docs/SONARR_QUICKSTART.md`
- Config Reference: `docs/PROJECT_CONFIGURATION.md`

### Community
- Sonarr Discord: https://discord.gg/sonarr
- Sonarr Reddit: r/sonarr

### Configuration Files
- Sonarr Config: `C:\ProgramData\Sonarr\config.xml`
- Database: `C:\ProgramData\Sonarr\sonarr.db`
- Backups: `C:\ProgramData\Sonarr\Backups\` (automatic)

---

## Success Metrics

### What's Working
✅ 31 shows imported and organized
✅ 27 shows actively monitored
✅ 3 indexers providing search results
✅ qBittorrent ready for downloads
✅ 4 episodes scheduled for next 7 days
✅ Conservative upgrade strategy configured
✅ 10-day seed requirement respected
✅ 4.21 TB storage available

### Next Milestone
🎯 **First successful auto-download and import!**

When an episode airs and auto-downloads, you'll see:
1. Notification in Activity → Queue
2. Download progress in qBittorrent
3. Automatic import to TV Shows folder
4. Renamed file in perfect Plex format
5. Episode marked as downloaded in Sonarr
6. Ready to watch in Plex!

---

**Sonarr Setup Status:** ✅ **COMPLETE AND OPERATIONAL**

Congratulations! Your TV show automation is now live. Sit back and let Sonarr handle your TV downloads automatically!
