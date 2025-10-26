# Sonarr Setup Guide

**Version:** 1.0
**Date:** 2025-10-25
**Status:** Pre-Installation Planning

## Overview

This guide covers the complete setup of Sonarr for automated TV show management, integrated with your existing Prowlarr installation.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Initial Configuration](#initial-configuration)
4. [Prowlarr Integration](#prowlarr-integration)
5. [Library Setup](#library-setup)
6. [Quality Profiles](#quality-profiles)
7. [Download Client Configuration](#download-client-configuration)
8. [Testing & Verification](#testing--verification)

---

## Prerequisites

### Before Installing Sonarr

**✓ Completed:**
- [x] Prowlarr installed and configured
- [x] 4 private trackers configured in Prowlarr
- [x] TV Shows library organized in Plex standard format

**To Verify:**
- [ ] Download client installed (qBittorrent/Transmission/Deluge)
- [ ] Download client accessible via API
- [ ] Sufficient disk space for downloads and media

### System Requirements

**Minimum:**
- Windows 10 or later
- 2 GB RAM
- .NET Framework (Sonarr will install if needed)
- Web browser for UI access

**Your Environment:**
- Platform: Windows
- TV Shows Path: `A:\Media\TV Shows`
- Expected installation type: Windows Native (matching Prowlarr)

---

## Installation

### Option 1: Windows Native Installation (Recommended)

Matches your Prowlarr setup for consistency.

**Download:**
1. Visit [Sonarr Downloads](https://sonarr.tv/#downloads)
2. Download latest stable Windows installer
3. Current stable: v4.x

**Installation Steps:**
```
1. Run installer as Administrator
2. Choose installation directory
   Recommended: C:\ProgramData\Sonarr
3. Choose to install as Windows Service: YES
4. Select port (default: 8989)
5. Complete installation
```

**Post-Installation:**
- Service should auto-start
- Access web UI at: `http://localhost:8989`
- Sonarr will run on system startup

### Option 2: Docker (Alternative)

If you prefer containerization:

```yaml
# docker-compose.yml example
version: "3"
services:
  sonarr:
    image: linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Los_Angeles
    volumes:
      - ./config/sonarr:/config
      - A:\Media\TV Shows:/tv
      - [DOWNLOAD_PATH]:/downloads
    ports:
      - 8989:8989
    restart: unless-stopped
```

---

## Initial Configuration

### First-Time Setup Wizard

**1. Authentication (Optional but Recommended)**
- Settings → General → Security
- Authentication: Forms (Login Page)
- Username: [Your choice]
- Password: [Strong password]

**2. API Key Generation**
- Settings → General → Security
- API Key: Auto-generated (save this for Prowlarr integration)
- Note: `[KEEP SECRET - NOT IN REPO]`

**3. General Settings**

```yaml
Analytics: Disabled (privacy)
Updates:
  Branch: main (stable)
  Automatic: No (manual updates recommended)

Backup:
  Folder: Backups (default)
  Interval: 7 days
  Retention: 28 days
```

---

## Prowlarr Integration

### Connect Sonarr to Prowlarr

**In Prowlarr:**
1. Settings → Apps → Add Application
2. Select "Sonarr"
3. Configure:
   ```
   Name: Sonarr
   Sync Level: Full Sync
   Prowlarr Server: http://localhost:9696
   Sonarr Server: http://localhost:8989
   API Key: [Copy from Sonarr Settings → General → Security]
   ```
4. Test connection
5. Save

**Verification:**
- Prowlarr should sync all 4 indexers to Sonarr
- In Sonarr: Settings → Indexers
- Should see 4 indexers auto-populated

### Indexer Settings in Sonarr

After sync from Prowlarr:
```yaml
Indexers (Auto-synced):
  - [Private Tracker 1]
  - [Private Tracker 2]
  - [Private Tracker 3]
  - [Private Tracker 4]

Per-Indexer Settings:
  Enable RSS: Yes (for automatic new episode detection)
  Enable Interactive Search: Yes
  Enable Automatic Search: Yes
  Priority: [Adjust as needed]
  Tags: [Optional organizational tags]
```

---

## Library Setup

### Root Folders

**Add TV Shows Root Folder:**
1. Settings → Media Management → Root Folders
2. Add Root Folder: `A:\Media\TV Shows`
3. Verify path is accessible

### Media Management Settings

**Episode Naming:**
```yaml
Rename Episodes: Yes
Replace Illegal Characters: Yes

Standard Episode Format:
{Series Title} - S{season:00}E{episode:00} - {Episode Title}

Example Output:
Breaking Bad - S01E01 - Pilot.mkv

Daily Episode Format:
{Series Title} - {Air-Date} - {Episode Title}

Anime Episode Format:
{Series Title} - S{season:00}E{episode:00} - {Episode Title}
```

**Folder Structure:**
```yaml
Create Empty Series Folders: No
Delete Empty Folders: Yes

Series Folder Format:
{Series Title} ({Series Year})

Example:
Breaking Bad (2008)

Season Folder Format:
Season {season:00}

Example:
Season 01
```

**File Management:**
```yaml
Unmonitor Deleted Episodes: Yes
Propers and Repacks: Prefer and Upgrade
Analyze Video Files: No (faster imports)
Change File Date: None
Recycling Bin: [Optional - specify path if you want]
```

**Permissions (Windows):**
```yaml
Set Permissions: No (Windows handles this)
```

---

## Quality Profiles

### Default Quality Profile

Sonarr includes a default "Any" quality profile. Customize for your needs:

**Recommended Profile: "HD-1080p"**
```yaml
Name: HD-1080p
Upgrades Allowed: Yes
Upgrade Until: Bluray-1080p

Qualities (Preferred order, top = best):
  ☑ Bluray-1080p
  ☑ WEB 1080p
  ☑ WEBDL-1080p
  ☑ HDTV-1080p
  ☐ Bluray-720p
  ☐ WEB 720p
  ☐ WEBDL-720p
  ☐ HDTV-720p
  ☐ DVD
  ☐ SDTV

Cutoff: WEB 1080p (Stop upgrading once WEB quality is achieved)
```

**Optional Profile: "Any HD"**
For shows where quality is less critical:
```yaml
Name: Any HD
Upgrades Allowed: No

Qualities:
  ☑ Bluray-1080p
  ☑ WEB 1080p
  ☑ WEBDL-1080p
  ☑ HDTV-1080p
  ☑ Bluray-720p
  ☑ WEB 720p
  ☑ WEBDL-720p
  ☑ HDTV-720p

Cutoff: HDTV-720p (First match, no upgrades)
```

### Custom Formats (Advanced)

Create custom formats for specific preferences:
- Prefer certain release groups
- Avoid hardcoded subtitles
- Prefer specific codecs (x264, x265/HEVC)

_[To be configured based on your preferences]_

---

## Download Client Configuration

### Prerequisites

Verify you have a download client installed:
- [ ] qBittorrent (Recommended for private trackers)
- [ ] Transmission
- [ ] Deluge
- [ ] Other

### Adding Download Client to Sonarr

**For qBittorrent:**
1. Settings → Download Clients → Add → qBittorrent
2. Configure:
   ```
   Name: qBittorrent
   Enable: Yes
   Host: localhost (or IP if remote)
   Port: 8080 (default qBittorrent WebUI port)
   Username: [qBittorrent WebUI username]
   Password: [qBittorrent WebUI password]
   Category: tv-sonarr (creates category in qBittorrent)
   ```
3. Test connection
4. Save

**Download Client Settings:**
```yaml
Completed Download Handling:
  Enable: Yes
  Remove Completed: Yes (After import to Sonarr)

Failed Download Handling:
  Redownload Failed: Yes
  Remove Failed: Yes
```

**Important for Private Trackers:**
```yaml
In qBittorrent:
  - Enable WebUI (Tools → Options → Web UI)
  - Disable automatic torrent management for Sonarr category
  - Set appropriate seed ratio/time limits per your tracker rules

Seed Ratio Recommendations:
  - Minimum: 1.0 (or tracker requirement)
  - Maximum: [Per your preference, e.g., 2.0]
  - Seed Time: [e.g., 72 hours minimum]
```

---

## Testing & Verification

### Pre-Flight Checks

Before adding shows, verify:
- [ ] Prowlarr connection working
- [ ] All 4 indexers showing in Sonarr
- [ ] Download client connected
- [ ] Root folder accessible
- [ ] Naming format configured

### Test Workflow

**1. Manual Search Test:**
1. Series → Add New Series
2. Search for a show (e.g., "Breaking Bad")
3. Select show
4. Choose Root Folder: `A:\Media\TV Shows`
5. Quality Profile: HD-1080p
6. Monitor: All Episodes
7. Click "Search for missing episodes"
8. Check Activity → Queue to see if results found

**2. Download Test:**
1. Pick an episode from search results
2. Click download icon
3. Verify:
   - [ ] Torrent sent to download client
   - [ ] Episode shows in Activity → Queue
   - [ ] Download progressing in qBittorrent

**3. Import Test:**
1. Wait for download to complete
2. Sonarr should automatically:
   - Detect completed download
   - Rename file per your format
   - Move to `A:\Media\TV Shows\[Show Name]\Season XX\`
   - Remove from download client (if configured)
   - Mark as downloaded in Sonarr

**4. Verification:**
```
Check final file location:
A:\Media\TV Shows\Breaking Bad (2008)\Season 01\Breaking Bad - S01E01 - Pilot.mkv

Verify:
✓ Correct folder structure
✓ Proper file naming
✓ Episode marked as downloaded in Sonarr
✓ Torrent removed from client (if configured)
```

---

## Adding Your TV Shows Library

### Import Existing Library

**Option 1: Import Shows Individually**
1. Series → Add New Series
2. Search for each show by name
3. Select show
4. Root Folder: `A:\Media\TV Shows`
5. Choose: "This is an existing show on disk"
6. Monitor: "Future episodes only" (since you have existing content)
7. Add Series

**Option 2: Mass Import (Recommended)**
1. Series → Library Import
2. Select Root Folder: `A:\Media\TV Shows`
3. Sonarr will scan and detect shows
4. For each detected show:
   - Match to correct series
   - Set quality profile
   - Set monitoring options
5. Bulk import all

### Monitoring Options

For existing shows:
- **All Episodes:** Monitor everything (Sonarr will want to upgrade)
- **Future Episodes:** Only new episodes (recommended for existing library)
- **Missing Episodes:** Only episodes you don't have yet
- **Existing Episodes:** Only episodes already downloaded
- **Recent Episodes:** Recent + future episodes
- **Pilot Episode:** Just the first episode
- **First Season:** Just Season 1
- **Latest Season:** Current season only
- **None:** No monitoring (manual only)

**Recommended for Your Setup:**
```
For shows you're caught up on:
  Monitor: Future Episodes
  Search for Missing: No

For shows with gaps:
  Monitor: Missing Episodes
  Search for Missing: Yes (carefully, to avoid ratio hit)
```

---

## Post-Setup Configuration

### Calendar & RSS

**Calendar:**
- View upcoming episodes
- See what will be downloaded automatically
- Manually search for specific episodes

**RSS Sync:**
- Settings → Indexers → RSS Sync Interval: 60 minutes (default)
- Sonarr checks indexer RSS feeds for new releases

### Notifications (Optional)

Setup notifications for:
- Download completed
- Episode imported
- Health check failures

**Options:**
- Email
- Pushover
- Discord webhook
- Custom scripts

### Backup Strategy

**Sonarr Backups:**
```
Location: C:\ProgramData\Sonarr\Backups\
Frequency: Weekly (configured)
Retention: 28 days (4 weeks)

Files to backup externally:
- sonarr.db (database)
- config.xml (configuration - SENSITIVE)
```

---

## Common Issues & Troubleshooting

### Indexer Issues

**No search results:**
- Check indexer status in Prowlarr
- Verify indexer sync worked
- Check indexer logs for rate limiting

**Some indexers fail:**
- Private trackers may require re-authentication
- Check credentials in Prowlarr
- Verify tracker website is accessible

### Download Client Issues

**Episodes stuck in queue:**
- Check download client is running
- Verify network connectivity
- Check disk space
- Review download client logs

**Import failures:**
- Check file permissions
- Verify root folder path
- Check naming format matches files
- Review Sonarr logs

### Performance Issues

**Slow searches:**
- Too many indexers (4 is good, no issue expected)
- Indexer responding slowly
- Network issues

**Slow imports:**
- Large files
- Disk I/O bottleneck
- Rename/copy operations on network drives

---

## Maintenance Tasks

### Daily/Weekly
- [ ] Check Activity → Queue for stuck downloads
- [ ] Review Calendar for upcoming episodes
- [ ] Monitor disk space

### Monthly
- [ ] Review System → Status for health warnings
- [ ] Check for Sonarr updates
- [ ] Verify backup integrity
- [ ] Review and clean up failed downloads

### Quarterly
- [ ] Review quality profiles (still appropriate?)
- [ ] Audit shows being monitored
- [ ] Check indexer performance stats
- [ ] Update/rotate API keys if needed

---

## Integration with Plex

### Plex Library Scanning

**After Sonarr imports episodes:**

**Option 1: Manual Scan**
- Plex → Library → Scan Library Files

**Option 2: Automatic via Sonarr**
Settings → Connect → Add Connection → Plex Media Server
```
Host: localhost (or Plex server IP)
Port: 32400
Auth Token: [Get from Plex]

When:
  On Grab: No
  On Import: Yes (Scan library when episode imported)
  On Upgrade: Yes
  On Rename: Yes
```

---

## Next Steps After Setup

1. [ ] Complete installation of Sonarr
2. [ ] Configure initial settings (authentication, API key)
3. [ ] Connect to Prowlarr (sync indexers)
4. [ ] Configure download client
5. [ ] Set up quality profiles
6. [ ] Import existing TV shows library
7. [ ] Test complete workflow (search → download → import)
8. [ ] Configure Plex integration
9. [ ] Set up monitoring for specific shows
10. [ ] Document your configuration in this repo

---

## Documentation & Resources

- [Sonarr Wiki](https://wiki.servarr.com/sonarr)
- [Sonarr Discord](https://discord.gg/sonarr)
- [Quality Profiles Guide](https://wiki.servarr.com/sonarr/settings#quality-profiles)
- [Custom Formats](https://wiki.servarr.com/sonarr/settings#custom-formats)
- [Troubleshooting Guide](https://wiki.servarr.com/sonarr/troubleshooting)

---

## Configuration Tracking

**Document your actual setup:**

```yaml
Installation Date: [Date]
Version: [Version number]
Installation Path: [Path]
Port: 8989
API Key: [KEEP SECRET]

Connected Services:
  - Prowlarr: ✓
  - qBittorrent: [Status]
  - Plex: [Status]

Indexers Synced: 4 from Prowlarr
Quality Profile: [Your choice]
Root Folder: A:\Media\TV Shows

Shows Monitored: [Count]
```

---

**Status:** Ready to proceed with Sonarr installation
