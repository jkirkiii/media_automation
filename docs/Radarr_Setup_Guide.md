# Radarr Setup Guide

**Version:** 1.0
**Date:** 2026-01-03
**Status:** Ready for Installation

## Overview

This guide covers the complete setup of Radarr for automated movie management, integrated with your existing Prowlarr and qBittorrent installations. This follows the same proven pattern as your successful Sonarr deployment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Initial Configuration](#initial-configuration)
4. [Prowlarr Integration](#prowlarr-integration)
5. [Library Setup](#library-setup)
6. [Quality Profiles](#quality-profiles)
7. [Download Client Configuration](#download-client-configuration)
8. [Testing & Verification](#testing--verification)
9. [Importing Existing Movies](#importing-existing-movies)

---

## Prerequisites

### Before Installing Radarr

**✓ Completed:**
- [x] Prowlarr installed and configured
- [x] 3 private trackers configured in Prowlarr (Darkpeers, TorrentDay, TorrentLeech)
- [x] qBittorrent installed with Auto TMM enabled
- [x] Sonarr working successfully (proven automation pattern)
- [x] `A:\Media\Movies` directory exists
- [x] `A:\Downloads\Movies` directory exists

**To Verify:**
- [ ] qBittorrent Auto TMM enabled
- [ ] Sufficient disk space (4.21 TB available)
- [ ] Existing movies ready for import

### System Requirements

**Minimum:**
- Windows 10 or later
- 2 GB RAM
- .NET Framework (Radarr will install if needed)
- Web browser for UI access

**Your Environment:**
- Platform: Windows 11
- Movies Path: `A:\Media\Movies`
- Downloads Path: `A:\Downloads\Movies`
- Installation type: Windows Native (matching Sonarr/Prowlarr)
- Available Space: 4.21 TB

---

## Installation

### Windows Native Installation (Recommended)

Matches your Sonarr and Prowlarr setup for consistency.

**Download:**
1. Visit [Radarr Downloads](https://radarr.video/#downloads)
2. Download latest stable Windows installer
3. Current stable: v5.x

**Installation Steps:**
```
1. Run installer as Administrator
2. Choose installation directory
   Recommended: C:\ProgramData\Radarr
3. Choose to install as Windows Service: YES
4. Select port: 7878 (default - different from Sonarr's 8989)
5. Complete installation
```

**Post-Installation:**
- Service should auto-start
- Access web UI at: `http://localhost:7878`
- Radarr will run on system startup

**Download Link:**
- Direct download: https://radarr.video/#downloads
- Choose: "Windows (x64) - Installer"

---

## Initial Configuration

### First-Time Setup Wizard

**1. Authentication (Recommended)**
Settings → General → Security
- Authentication: Forms (Login Page)
- Authentication Required: Enabled
- Username: [Your choice - use same as Sonarr for consistency]
- Password: [Strong password - use same as Sonarr for consistency]

**2. API Key Generation**
Settings → General → Security
- API Key: Auto-generated (save this for Prowlarr integration)
- **IMPORTANT:** Store in `config.ps1` (will be created)
- Note: `[KEEP SECRET - NOT IN REPO]`

**3. General Settings**

```yaml
Analytics: Disabled (privacy)
Updates:
  Branch: master (stable)
  Automatic: No (manual updates recommended)

Backup:
  Folder: Backups (default)
  Interval: 7 days
  Retention: 28 days

Log Level: Info (or Debug for troubleshooting)
```

---

## Prowlarr Integration

### Connect Radarr to Prowlarr

**In Prowlarr:**
1. Settings → Apps → Add Application
2. Select "Radarr"
3. Configure:
   ```
   Name: Radarr
   Sync Level: Full Sync
   Tags: [Leave empty for all indexers]
   Prowlarr Server: http://localhost:9696
   Radarr Server: http://localhost:7878
   API Key: [Copy from Radarr Settings → General → Security]
   ```
4. Test connection
5. Save

**Verification:**
- Prowlarr should sync all 3 indexers to Radarr
- In Radarr: Settings → Indexers
- Should see 3 indexers auto-populated:
  - Darkpeers
  - TorrentDay
  - TorrentLeech

### Indexer Settings in Radarr

After sync from Prowlarr:
```yaml
Indexers (Auto-synced):
  - Darkpeers (API)
  - TorrentDay
  - TorrentLeech

Per-Indexer Settings:
  Enable RSS: Yes (for automatic new movie detection)
  Enable Interactive Search: Yes
  Enable Automatic Search: Yes
  Priority: [Default is fine, adjust if needed]
  Tags: [Optional organizational tags]
```

---

## Library Setup

### Root Folders

**Add Movies Root Folder:**
1. Settings → Media Management → Root Folders
2. Add Root Folder: `A:\Media\Movies`
3. Verify path is accessible
4. Check free space shows correctly

### Media Management Settings

**Movie Naming:**
```yaml
Rename Movies: Yes
Replace Illegal Characters: Yes

Standard Movie Format:
{Movie Title} ({Release Year}) - {Quality Full}

Example Output:
The Matrix (1999) - Bluray-1080p.mkv

Movie Folder Format:
{Movie Title} ({Release Year})

Example:
The Matrix (1999)/
```

**Folder Structure:**
```yaml
Create Empty Movie Folders: No (only create when movie downloads)
Delete Empty Folders: Yes (cleanup after movie removal)
Skip Free Space Check: No (verify space before download)
Minimum Free Space: 500 MB (safety buffer)

Use Hardlinks instead of Copy: Yes (saves space, keeps seeding working)
Import Extra Files: No (just the movie file)
```

**File Management:**
```yaml
Unmonitor Deleted Movies: Yes
Propers and Repacks: Prefer and Upgrade
Analyze Video Files: No (faster imports)
Change File Date: None
Recycling Bin: [Optional - specify path if you want undelete capability]
```

**Permissions (Windows):**
```yaml
Set Permissions: No (Windows handles this)
```

---

## Quality Profiles

### Conservative HD-1080p Profile

Matching your proven Sonarr configuration:

**Create Quality Profile:**
Settings → Profiles → Quality Profiles → Add

```yaml
Name: Conservative HD-1080p
Upgrades Allowed: Yes
Upgrade Until: Bluray-1080p

Quality Priority (Top = Best):
  ☑ Bluray-1080p (allowed, won't actively seek)
  ☑ WEBDL-1080p (PREFERRED)
  ☑ WEBRip-1080p (acceptable, will upgrade to WEB-DL)
  ☑ HDTV-1080p (acceptable, will upgrade to WEB-DL)
  ☐ Bluray-720p (disabled)
  ☐ WEBDL-720p (disabled)
  ☐ WEBRip-720p (disabled)
  ☐ HDTV-720p (disabled)
  ☐ DVD (disabled)
  ☐ SDTV (disabled)

Cutoff: WEBDL-1080p
(Stop upgrading once WEB-DL 1080p is achieved)

Language: English (or your preference)

Minimum Size: 0 MB (no minimum)
Maximum Size: [Optional - e.g., 15000 MB = 15 GB to avoid massive files]
```

**Quality Philosophy:**
- **Conservative approach:** Don't endlessly upgrade
- **WEB-DL preferred:** Best quality-to-ratio balance
- **HDTV/WEBRip acceptable:** Will upgrade to WEB-DL if found
- **Bluray allowed but not sought:** Won't waste ratio chasing Blurays
- **No 720p or lower:** HD-only library

### Optional: Any HD Profile

For less critical movies or testing:
```yaml
Name: Any HD
Upgrades Allowed: No
Upgrade Until: [First match]

Qualities:
  ☑ Bluray-1080p
  ☑ WEBDL-1080p
  ☑ WEBRip-1080p
  ☑ HDTV-1080p
  ☑ Bluray-720p
  ☑ WEBDL-720p
  ☑ WEBRip-720p
  ☑ HDTV-720p

Cutoff: HDTV-720p (First match, no upgrades)
```

---

## Download Client Configuration

### Add qBittorrent to Radarr

**Prerequisites:**
1. Verify qBittorrent is running
2. Verify Web UI accessible at `http://localhost:8080`
3. Have qBittorrent credentials ready (from `config.ps1`)

**Adding Download Client:**
1. Settings → Download Clients → Add → qBittorrent
2. Configure:
   ```
   Name: qBittorrent
   Enable: Yes

   Host: localhost
   Port: 8080

   Username: [qBittorrent WebUI username from config.ps1]
   Password: [qBittorrent WebUI password from config.ps1]

   Category: movie-radarr
   Post-Import Category: [Leave empty]
   Recent Priority: Last
   Older Priority: Last
   Initial State: Start

   Remove Completed: No (CRITICAL for seeding!)
   Remove Failed: Yes
   ```
3. Test connection
4. Save

**Download Client Settings:**
Settings → Download Clients → Completed Download Handling
```yaml
Enable: Yes (Radarr monitors for completed downloads)
Redownload Failed: Yes (retry if download fails)
Remove Failed Downloads: Yes (cleanup failed attempts)
```

**Important for Private Trackers:**
```yaml
In qBittorrent:
  - Auto TMM: Enabled (verified ✓)
  - Category: movie-radarr → A:\Downloads\Movies
  - Minimum Seed Time: 10 days (configured)
  - Remove Completed: NO in Radarr (keeps seeding active)
```

### Create qBittorrent Category

**Option 1: Automatic (when Radarr connects)**
- Radarr will create `movie-radarr` category automatically
- You may need to set the save path manually afterward

**Option 2: Pre-create with Script**
We'll create a script: `Setup-qBittorrent-Radarr-Category.ps1`

**Manual Method:**
1. Open qBittorrent Web UI: http://localhost:8080
2. Tools → Options → Downloads
3. Verify Auto TMM is enabled
4. Create category `movie-radarr` → `A:\Downloads\Movies`

---

## Testing & Verification

### Pre-Flight Checks

Before adding movies, verify:
- [ ] Radarr web UI accessible at http://localhost:7878
- [ ] Prowlarr connection working
- [ ] All 3 indexers showing in Radarr
- [ ] Download client (qBittorrent) connected
- [ ] Root folder `A:\Media\Movies` accessible
- [ ] Naming format configured
- [ ] Quality profile created

### Test Workflow

**1. Manual Search Test:**
1. Movies → Add New Movie
2. Search for a movie (e.g., "The Matrix")
3. Select movie from search results
4. Choose:
   - Root Folder: `A:\Media\Movies`
   - Monitor: Yes
   - Quality Profile: Conservative HD-1080p
   - Search on Add: No (we'll do manual search first)
5. Add Movie
6. Click movie → Search button (magnifying glass)
7. Check if results appear from indexers

**2. Download Test:**
1. From search results, pick a release
2. Preferred: 1080p WEB-DL from trusted source
3. Click download icon (cloud with arrow)
4. Verify:
   - [ ] Torrent sent to qBittorrent
   - [ ] Movie shows in Activity → Queue in Radarr
   - [ ] Download progressing in qBittorrent
   - [ ] Category is `movie-radarr`
   - [ ] Download location is `A:\Downloads\Movies`

**3. Import Test:**
1. Wait for download to complete
2. Radarr should automatically:
   - Detect completed download
   - Rename file per your format
   - Move/hardlink to `A:\Media\Movies\[Movie Title (Year)]\`
   - Keep original in downloads for seeding
   - Mark as downloaded in Radarr

**4. Verification:**
```
Check final file location:
A:\Media\Movies\The Matrix (1999)\The Matrix (1999) - Bluray-1080p.mkv

Verify:
✓ Correct folder structure
✓ Proper file naming
✓ Movie marked as downloaded in Radarr
✓ Torrent still seeding in qBittorrent (at A:\Downloads\Movies\)
✓ File is hardlinked (exists in both locations, uses space only once)
```

---

## Importing Existing Movies

### Preparation

**Before Importing:**
1. Check your existing movies in `A:\Media\Movies`
2. Note current naming/folder structure
3. Backup important files if needed
4. Radarr will rename files to match your naming format

### Import Methods

**Option 1: Library Import (Recommended for Bulk)**
1. Movies → Library Import
2. Select Root Folder: `A:\Media\Movies`
3. Radarr will scan and detect movies
4. For each detected movie:
   - Radarr attempts to match to database (TMDb)
   - Verify match is correct
   - Set quality profile: Conservative HD-1080p
   - Set monitoring: Yes (for auto-download of upgrades if wanted)
5. Import Selected Movies

**Option 2: Manual Import (Better Control)**
1. Movies → Manual Import
2. Select folder: `A:\Media\Movies`
3. Review each movie:
   - Confirm correct match
   - Choose quality profile
   - Set monitoring preference
4. Import individually

### Monitoring Options for Existing Movies

**For movies you already have:**
- **Monitor Movie:** Yes (Radarr will look for upgrades based on quality profile)
- **Monitor Movie:** No (Keep in library, but don't auto-upgrade)

**Recommended Approach:**
```yaml
For movies you're happy with quality:
  Monitor: No (don't waste ratio re-downloading)
  Minimum Availability: Released (for any future manual searches)

For movies with poor quality you want upgraded:
  Monitor: Yes
  Search for Movie: No (manual search safer for ratio)
  Minimum Availability: Released
```

### Post-Import

**After importing:**
1. Review Movies → Library
2. Check that movies are properly matched
3. Verify file paths are correct
4. Fix any unmatched movies manually
5. Disable monitoring on movies you don't want upgraded

---

## Automation Settings

### Automatic Search Settings

Settings → Indexers → Options

```yaml
Minimum Age: 0 (download immediately when available)
Retention: 0 (not using Usenet)
Maximum Size: 0 (no limit, or set e.g., 15000 for 15 GB max)
RSS Sync Interval: 60 minutes (check for new movies hourly)
```

### Lists (Optional)

Radarr can auto-add movies from lists (IMDb, Trakt, etc.)

**For now:** Skip lists, manually add movies as desired
**Later:** Can configure if you want auto-adding from watchlists

---

## Post-Setup Configuration

### Calendar

**View upcoming releases:**
- Movies → Calendar
- See movies that will be released soon
- Manually add if interested

### Wanted

**Missing Movies:**
- Movies → Wanted → Missing
- Shows monitored movies not yet downloaded
- Can manually search from here

### Notifications (Optional)

Setup notifications for:
- Movie grabbed
- Movie imported
- Health check failures

**Options:**
- Email
- Discord webhook
- Custom scripts

### Backup Strategy

**Radarr Backups:**
```
Location: C:\ProgramData\Radarr\Backups\
Frequency: Weekly (configured)
Retention: 28 days

Important files:
- radarr.db (database)
- config.xml (configuration - contains API key - SENSITIVE)

Store in secure location, exclude from git
```

---

## Common Issues & Troubleshooting

### Indexer Issues

**No search results:**
- Check indexer status in Prowlarr
- Verify indexer sync worked (Settings → Indexers in Radarr)
- Check indexer logs for rate limiting
- Verify movie exists on trackers (not all trackers have all movies)

**Some indexers fail:**
- Private trackers may require re-authentication
- Check credentials in Prowlarr
- Test indexer in Prowlarr first

### Download Client Issues

**Movies stuck in queue:**
- Check qBittorrent is running
- Verify network connectivity (VPN if needed)
- Check disk space on A:\
- Review qBittorrent logs
- Check tracker status in qBittorrent

**Import failures:**
- Check file permissions
- Verify root folder path accessible
- Check naming format matches files
- Review Radarr logs: System → Logs
- Verify hardlinks work (same drive: A:\ for both downloads and media)

### Quality Profile Issues

**Wrong quality downloading:**
- Review quality profile cutoff setting
- Check release priority
- Verify upgrade settings

**Files too large:**
- Set maximum size in quality profile (e.g., 15000 MB)
- Check quality definitions: Settings → Quality

---

## Maintenance Tasks

### Weekly
- [ ] Check Activity → Queue for stuck downloads
- [ ] Review Calendar for interesting upcoming releases
- [ ] Check qBittorrent for torrents meeting 10-day seed requirement
- [ ] Clean up completed downloads from `A:\Downloads\Movies`

### Monthly
- [ ] Check System → Status for health warnings
- [ ] Verify disk space (keep > 500 GB free)
- [ ] Review monitored movies (still want upgrades?)
- [ ] Check for Radarr updates

### Quarterly
- [ ] Review quality profiles (still appropriate?)
- [ ] Audit movies being monitored
- [ ] Check indexer performance: System → Status → Health
- [ ] Update/rotate API keys if needed

---

## Integration with Plex

### Plex Library Scanning

**After Radarr imports movies:**

**Option 1: Manual Scan**
- Plex → Movies Library → Scan Library Files

**Option 2: Automatic via Radarr (Recommended)**
Settings → Connect → Add Connection → Plex Media Server
```
Host: localhost (or Plex server IP)
Port: 32400
Auth Token: [Get from Plex]

Notifications:
  On Grab: No
  On Import: Yes (update Plex when movie imported)
  On Upgrade: Yes
  On Rename: Yes
  On Movie Delete: Yes

Update Library: Yes
```

---

## Next Steps After Setup

**Immediate Tasks:**
1. [ ] Download and install Radarr
2. [ ] Configure initial settings (auth, API key)
3. [ ] Connect to Prowlarr (sync indexers)
4. [ ] Add qBittorrent download client
5. [ ] Create quality profile
6. [ ] Set up root folder and naming
7. [ ] Test with ONE movie first
8. [ ] Import existing movies
9. [ ] Configure Plex integration
10. [ ] Document configuration

**Future Enhancements:**
- [ ] Configure lists for auto-adding (IMDb, Trakt)
- [ ] Set up notifications (Discord, email)
- [ ] Fine-tune quality profiles based on experience
- [ ] Consider custom formats for preferred release groups

---

## Documentation & Resources

**Official Resources:**
- [Radarr Wiki](https://wiki.servarr.com/radarr)
- [Radarr Discord](https://discord.gg/radarr)
- [Quality Settings Guide](https://wiki.servarr.com/radarr/settings#quality-profiles)
- [Custom Formats Guide](https://trash-guides.info/Radarr/Radarr-setup-custom-formats/)

**Your Project Docs:**
- This guide: `docs/Radarr_Setup_Guide.md`
- Sonarr reference: `docs/Sonarr_Setup_Guide.md` (similar patterns)
- Project tracker: `docs/project_tracker.md`
- Credentials: `config.ps1` (gitignored)

---

## Configuration Tracking Template

**Document your actual setup:**

```yaml
Installation Date: [Date]
Version: [Version number]
Installation Path: C:\ProgramData\Radarr
Port: 7878
Access URL: http://localhost:7878
API Key: [STORED IN config.ps1 - KEEP SECRET]

Connected Services:
  - Prowlarr: [Status]
  - qBittorrent: [Status]
  - Plex: [Status]

Indexers Synced: [Count] from Prowlarr
Quality Profile: Conservative HD-1080p
Root Folder: A:\Media\Movies
Download Path: A:\Downloads\Movies

Movies in Library: [Count]
Monitored Movies: [Count]
Free Space: [Space]
```

---

**Status:** Ready to begin installation

**Next Step:** Download and install Radarr from https://radarr.video/#downloads
