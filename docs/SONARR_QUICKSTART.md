# Sonarr Quick Start Guide

**Date:** 2025-10-25
**Status:** Ready to Install

## Pre-Installation Checklist

**✓ Completed:**
- [x] Prowlarr installed and configured (Windows native)
- [x] 4 private tracker indexers configured in Prowlarr
- [x] TV Shows library organized at `A:\Media\TV Shows`
- [x] Documentation created for setup process

**⏳ Before Installing Sonarr:**
- [ ] Verify Prowlarr is running and accessible at `http://localhost:9696`
- [ ] Verify download client is installed and running (qBittorrent recommended)
- [ ] Note Prowlarr API key (Settings → General → Security)
- [ ] Confirm disk space available for downloads

---

## Installation Steps

### 1. Download Sonarr

1. Visit: https://sonarr.tv/#downloads
2. Download: **Windows Installer** (latest stable v4.x)
3. Save installer to Downloads folder

### 2. Install Sonarr

```powershell
# Run installer as Administrator
# Installation options:
- Installation directory: C:\ProgramData\Sonarr (default)
- Install as Windows Service: YES
- Port: 8989 (default)
- Start after installation: YES
```

### 3. Initial Access

1. Open browser: `http://localhost:8989`
2. Should see Sonarr welcome screen
3. If prompted for authentication setup:
   - Authentication: Forms (Login Page)
   - Username: [your choice]
   - Password: [strong password]

### 4. Get Sonarr API Key

1. Settings → General → Security
2. Copy the API Key (you'll need this for Prowlarr)

---

## Quick Configuration (Essential Settings)

### Connect to Prowlarr

**In Prowlarr (http://localhost:9696):**
1. Settings → Apps → Add Application
2. Select "Sonarr"
3. Fill in:
   - Name: `Sonarr`
   - Sync Level: `Full Sync`
   - Prowlarr Server: `http://localhost:9696`
   - Sonarr Server: `http://localhost:8989`
   - API Key: [Sonarr API key from step 4]
4. Test → Save

**Verify:**
- In Sonarr: Settings → Indexers
- Should see 4 indexers auto-populated

### Add Download Client

**In Sonarr:**
1. Settings → Download Clients → Add
2. Select your download client (e.g., qBittorrent)
3. Configure:
   - Host: `localhost`
   - Port: [your download client port, typically 8080 for qBittorrent]
   - Username/Password: [your download client credentials]
   - Category: `tv-sonarr`
4. Test → Save

### Configure Media Management

**In Sonarr:**
1. Settings → Media Management
2. **Root Folders:**
   - Add Root Folder: `A:\Media\TV Shows`
3. **Episode Naming:**
   - Rename Episodes: ✓ YES
   - Standard Episode Format:
     ```
     {Series Title} - S{season:00}E{episode:00} - {Episode Title}
     ```
   - Series Folder Format:
     ```
     {Series Title} ({Series Year})
     ```
   - Season Folder Format:
     ```
     Season {season:00}
     ```

### Set Quality Profile

**In Sonarr:**
1. Settings → Profiles
2. Edit "HD-1080p" profile (or use default "Any")
3. Adjust quality preferences as needed
4. Set cutoff quality

---

## Import Existing TV Shows

### Option 1: Mass Import (Recommended)

1. Series → Library Import
2. Select folder: `A:\Media\TV Shows`
3. Sonarr will scan and detect your existing shows
4. For each show:
   - Verify match is correct
   - Quality Profile: `HD-1080p` (or your preference)
   - Monitor: `Future Episodes` (recommended for existing library)
   - Search for missing: `No` (initially)
5. Import All

### Option 2: Add Shows Individually

1. Series → Add New Series
2. Search for show by name
3. Select show
4. Root Folder: `A:\Media\TV Shows`
5. Monitor: `Future Episodes`
6. Quality Profile: `HD-1080p`
7. Add Series

---

## Test the Workflow

### Complete End-to-End Test

1. **Search for a show:**
   - Series → Add New Series
   - Search: "Breaking Bad" (or any show)

2. **Add and search:**
   - Select the show
   - Monitor: `Latest Season` (for testing)
   - Click "Search for monitored episodes"

3. **Verify search results:**
   - Activity → Queue
   - Should see search results from your indexers

4. **Download an episode:**
   - Click download icon on a result
   - Verify it appears in download client

5. **Wait for import:**
   - Once download completes, Sonarr should:
     - Rename file
     - Move to correct location
     - Mark as downloaded

6. **Verify final location:**
   ```
   A:\Media\TV Shows\Breaking Bad (2008)\Season 01\Breaking Bad - S01E01 - Pilot.mkv
   ```

---

## Post-Setup Tasks

### Immediate

- [ ] Import your existing TV shows library
- [ ] Configure Plex connection (Settings → Connect → Plex)
- [ ] Set up monitoring preferences for each show
- [ ] Test a complete download workflow

### Optional

- [ ] Configure notifications (Discord, email, etc.)
- [ ] Set up custom quality profiles
- [ ] Configure custom formats (advanced)
- [ ] Set up calendar monitoring

### Backup

- [ ] Create initial Sonarr backup (System → Backup → Backup Now)
- [ ] Copy backup to `configs/sonarr/` folder
- [ ] Document your actual configuration

---

## Configuration Documentation

After setup, document your actual configuration:

```yaml
Installation Date: __________
Sonarr Version: __________
Port: 8989
API Key: [KEEP SECRET]

Prowlarr Integration: ✓ Connected
Download Client: __________
Download Client Status: __________

Root Folder: A:\Media\TV Shows
Quality Profile: __________
Naming Format: Standard (Plex compatible)

Shows Imported: __________
Shows Monitored: __________
```

---

## Troubleshooting Quick Reference

### Indexers Not Showing in Sonarr
- Check Prowlarr connection in Settings → Apps
- Verify API keys are correct
- Test connection in Prowlarr

### No Search Results
- Check indexer status in Prowlarr
- Verify indexers are enabled in Sonarr
- Check logs: System → Logs

### Download Not Starting
- Verify download client is running
- Check download client connection in Sonarr
- Review download client logs

### Import Failed
- Check file naming format
- Verify root folder path
- Check file permissions
- Review logs in System → Logs

---

## Next Steps After Setup

1. Complete the test workflow successfully
2. Import your existing library
3. Configure show-specific settings
4. Set up automated monitoring
5. Consider Radarr for movies (similar process)

---

## Documentation References

- **Full Guide:** `docs/Sonarr_Setup_Guide.md`
- **Prowlarr Config:** `docs/Prowlarr_Configuration.md`
- **Templates:** `templates/sonarr/`

## Official Resources

- Sonarr Wiki: https://wiki.servarr.com/sonarr
- Sonarr Discord: https://discord.gg/sonarr
- Prowlarr Integration: https://wiki.servarr.com/prowlarr/settings#applications

---

**Ready to install? Follow the steps above and refer to the full setup guide for detailed explanations!**
