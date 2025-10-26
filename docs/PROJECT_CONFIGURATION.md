# Project Configuration & Environment Details

**Purpose:** Central reference for all project-specific configuration details
**Last Updated:** 2025-10-25

---

## System Environment

### Hardware
- **Primary Drive:** C:\
- **Media Drive:** A:\ (confirmed)
- **Download Drive:** A:\
- **Available Space on A:\:** 4.2 TB
- **Network:** [Local only or remote access planned?]

### Operating System
- **OS:** Windows 10
- **User Account Type:** Administrator
- **Network Location:** Home

### Performance Considerations
- **Expected Download Speed:** [Mbps]
- **Disk I/O Limitations:** [Any known bottlenecks?]
- **Concurrent Download Limit:** [How many simultaneous downloads?]

---

## Download Client

### Current Setup
- **Download Client:** qBittorrent
- **Version:** 5.1.2
- **Installation Type:** Windows native
- **Installation Path:** C:\Program Files\qBittorrent
- **WebUI Enabled:** Yes
- **WebUI Port:** [Typically 8080 for qBittorrent]
- **WebUI Username:** [Username]
- **WebUI Password:** [KEEP SECRET - just confirm configured]
- **API Enabled:** [If applicable]

### Download Locations
- **Incomplete Downloads:** A:\Downloads\Incomplete
- **Completed Downloads:** A:\Downloads\Complete
- **Default Category:** [tv-sonarr, movies-radarr, etc.]

### Seeding Policy (Important for Private Trackers)
- **Minimum Seed Ratio:** [e.g., 1.0, 2.0, or per tracker requirement]
- **Minimum Seed Time:** 10 days
- **Maximum Active Downloads:** [Number]
- **Maximum Active Uploads:** [Number]
- **Upload Speed Limit:** [If any]

---

## Prowlarr Details

### Installation
- **Installation Path:** C:\ProgramData\Prowlarr
- **Version:** 2.0.5.5160
- **WebUI Port:** [Typically 9696]
- **API Key:** [KEEP SECRET - just confirm you have it]

### Indexers (Private Trackers)
*Note: Do not list actual tracker names or URLs in this doc if you prefer privacy*

**Darkpeers (API):**
- **Type:** Private Tracker
- **Categories Enabled:** All
- **Priority:** 25
- **Working Status:** Active

**MyAnonamouse:**
- **Type:** Private Tracker
- **Categories Enabled:** All
- **Priority:** 25
- **Working Status:** Active

**TorrentDay:**
- **Type:** Private Tracker
- **Categories Enabled:** All
- **Priority:** 25
- **Working Status:** Active

**TorrentLeech:**
- **Type:** Private Tracker
- **Categories Enabled:** All
- **Priority:** 25
- **Working Status:** Active

### Indexer Preferences
- **Preferred Release Groups:** [Any favorites? e.g., BTN, HDB, etc.]
- **Avoid Release Groups:** [Any to avoid?]
- **Preferred Quality:** 1080p WEB-DL
- **Maximum File Size:** [Any limit per episode/movie?]
- **Minimum Seeders Required:** [Number]

---

## Media Library

### TV Shows
- **Root Path:** A:\Media\TV Shows (confirmed)
- **Total Shows:** ~30 (confirmed)
- **Total Episodes:** [Approximate count if known]
- **Total Size:** [Approximate GB/TB]
- **Shows Currently Airing:** [How many are you actively watching?]
- **Average Episode File Size:** [e.g., 1-2 GB for 1080p]

### TV Show Preferences
- **Preferred Quality:** 1080p
- **Quality vs Space Trade-off:** [Prefer quality or save space?]
- **Upgrade Existing:** [Yes - upgrade to better quality / No - keep what I have]
- **File Format Preference:** no preference
- **Subtitle Preference:** [External SRT / Embedded / Both / None]
- **Audio Preference:** [Stereo, 5.1, 7.1, any]

### Shows to Monitor Actively
*List shows you want Sonarr to automatically download new episodes for:*
- [Show name 1]
- [Show name 2]
- [Show name 3]
- [etc.]

### Shows to Keep But Not Monitor
*Shows in your library you don't want auto-downloaded:*
- [Show name 1]
- [Show name 2]
- [etc.]

---

## Movies (Future - Radarr)

### Current State
- **Root Path:** A:\Media\Movies (confirmed)
- **Total Movies:** [From archive list, appears to be 100+]
- **Total Size:** [Approximate GB/TB]
- **Radarr Status:** [Not yet installed]

### Movie Preferences
- **Preferred Quality:** 1080p
- **Upgrade Existing:** No
- **File Format Preference:** no preference
- **Collections/Franchises:** [Keep together in folders or separate?]

---

## Plex Configuration

### Plex Server
- **Installation Type:** Windows native
- **Version:** 4.147.1
- **Server Name:** Mnemosyne
- **Access:** [Local only / Remote access enabled]
- **Port:** [Typically 32400]

### Plex Libraries
- **TV Shows Library Name:** [In Plex]
- **Movies Library Name:** [In Plex]
- **Other Libraries:** [Documentaries, Music, etc.]

### Plex Scanning
- **Current Scan Method:** [Manual / Automatic / Scheduled]
- **Scan Frequency:** [How often does Plex scan for new content?]
- **Preference for Sonarr Integration:** Auto-scan after import? Yes

### Plex Users
- **Number of Users:** [Just you / Family / Friends]
- **Concurrent Streams:** [How many people watch at once typically?]
- **Remote Streaming:** [Do users stream remotely?]
- **Transcoding Needs:** [Does your server transcode often?]

---

## Automation Goals & Preferences

### Primary Goals
*Rank these from 1 (most important) to 5 (least important):*
- [1] ___ Automatically download new episodes of shows I'm watching
- [5] ___ Upgrade existing content to better quality
- [2] ___ Maintain library organization and naming standards
- [4] ___ Minimize manual intervention
- [3] ___ Optimize storage space

### Content Acquisition Strategy
- **New Shows:** Manually add when interested & Auto-add from lists
- **Episode Release Timing:** Grab immediately
- **Upgrade Strategy:** Conservative

### Storage Management
- **Storage Concerns:** Limited space - careful
- **Cleanup Strategy:** Manual review
- **Backup Strategy:** Just backup configs

---

## Network & Access

### Local Network
- **Network Type:** Wired
- **Router/Firewall:** [Any special configuration needed?]
- **VPN Usage:** For torrenting? Always
- **VPN Provider:** NordVPN

### Remote Access (If Applicable)
- **Remote Access Needed:** No
- **Services to Access Remotely:** [Plex / Sonarr / Prowlarr / All]
- **Reverse Proxy:** [Using one? Nginx, Caddy, etc.]
- **Domain Name:** [Custom domain or DuckDNS, etc.]

---

## Security & Privacy

### Authentication
- **Preference:** Local network only - no auth
- **Password Manager Used:** LastPass
- **API Key Storage:** [How do you track API keys?]

### Data Privacy
- **Tracker Privacy Concerns:** [High - very careful / Medium / Low]
- **Share Config Templates:** [OK to share sanitized configs? Yes/No]
- **Logging Preferences:** [Detailed logs for debugging / Minimal logs]

---

## Automation Behavior Preferences

### Download Behavior
- **Automatic Grabbing:** Auto-download as soon as available
- **Release Timing:** WEB-DL immediately
- **Propers/Repacks:** Auto-upgrade to proper releases? Yes
- **Daily vs Standard Shows:** [Handle news/talk shows differently?]

### Quality Cutoff
- **Good Enough Quality:** 1080p WEB-DL
- **Stop Upgrading At:** [When to stop looking for better quality?]

### Episode Monitoring
- **Backfill Old Seasons:** Yes - get missing episodes
- **Specials Handling:** Include specials
- **Anime Handling:** Not applicable

---

## Known Issues or Constraints

### Current Challenges
- [Any current issues with your setup?]
- [Known limitations (bandwidth, storage, etc.)?]
- [Problematic shows or trackers?]

### Things to Avoid
- [Don't want to re-download existing content unless necessary]
- [Don't want to exceed X GB downloads per day]
- [Other constraints]

---

## Future Plans

### Short Term (Next Month)
- [ ] Get Sonarr working and stable
- [ ] Import existing TV library
- [ ] Configure monitoring for active shows
- [ ] [Other goals]

### Medium Term (3-6 Months)
- [ ] Add Radarr for movies
- [ ] Consider Bazarr for subtitles
- [ ] [Other plans]

### Long Term
- [ ] Implement media health check system (from PRD)
- [ ] Consider other media types (audiobooks, etc.)
- [ ] [Other ideas]

---

## Notification Preferences

### Where to Send Notifications
- **Preferred Method:** Email
- **Email Address:** rokonin@gmail.com
- **Discord Webhook:** [If using Discord]

### What to Get Notified About
- [ ] New episode downloaded
- [ ] Episode imported successfully
- [ ] Download failed
- [ ] Health check warnings
- [ ] Indexer failures
- [ ] Upgrade available
- [ ] Other: [specify]

---

## Daily Routine & Usage Patterns

### When Do You Watch?
- **Typical Viewing Time:** [Evenings / Weekends / Varies]
- **Binge Watcher or Episode-by-Episode:** [Preference]
- **New vs Catalog:** [Watch new releases or explore catalog?]

### Download Timing Preferences
- **When to Download:** Anytime
- **Bandwidth Limits:** [During certain hours?]
- **Computer Always On:** Yes

---

## Special Requirements

### Specific Show Handling
- **Shows with Complex Numbering:** [Anime, Daily shows, etc.]
- **Multi-Part Episodes:** [How to handle?]
- **Different Quality for Different Shows:** [Some 4K, some 720p?]

### Regional Considerations
- **Time Zone:** [For episode air times]
- **Regional Naming:** [UK vs US naming conventions?]
- **Language Preferences:** [English only / Dual audio / Other]

---

## Questions for Discussion

### Configuration Decisions Needed
1. **Quality Profile Strategy:**
   - One profile for all shows

2. **Monitoring Strategy:**
   - Monitor all existing shows for upgrades

3. **Storage Strategy:**
   - Keep downloads after import

4. **Upgrade Strategy:**
   conservative approach

5. **Download Client Categories:**
   - Separate categories for different qualities/priorities?

---

## Fill-In Template

**For quick reference, key values to document:**

```yaml
# System
OS_Version:
Media_Drive_Free_Space:
Download_Drive:

# Download Client
Client_Name:
Client_Port:
Client_Download_Path:
Seed_Ratio_Policy:

# Prowlarr
Prowlarr_Port:
Indexer_Count: 4
All_Indexers_Working: Yes/No

# Quality Preferences
TV_Preferred_Quality:
TV_Cutoff_Quality:
Upgrade_Existing_Content: Yes/No
File_Format_Preference:

# Active Shows
Shows_To_Monitor: [list]
Shows_To_Ignore: [list]

# Notifications
Notification_Method:
Notification_Events: [list]

# Download Timing
Download_Immediately: Yes/No
Preferred_Download_Time:
Bandwidth_Limits: Yes/No
```

---

## How to Use This Document

1. **Before Sonarr Installation:** Fill in as much as you can
2. **During Setup:** Reference for configuration decisions
3. **After Setup:** Document actual configuration for future reference
4. **Ongoing:** Update as your preferences or setup changes

---

**Note:** Information marked [KEEP SECRET] should NOT be filled in this document if committing to git. Store sensitive data securely in password manager or separate encrypted file.
