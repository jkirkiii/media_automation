# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Plex Media Server automation project designed to transform a basic Plex server into a fully automated media management system. The project follows a phased approach detailed in `docs/project_tracker.md`.

**Current Status:** Phase 3 - Sonarr configured and operational with qBittorrent integration. Automatic TV show management active. Phase 3.5 - **COMPLETE** (2025-12-06) - Calibre and Calibre-Web fully operational with remote access, SMTP, and Send-to-Kindle functionality. Ebook library accessible locally and remotely at https://books.mnemo.info with multiple users actively using the system. Phase 3.7 - **COMPLETE** - Radarr operational for automated movie management. **Next:** Phase 3.6 - Readarr for automated ebook acquisition.

## Architecture

The repository follows the structure outlined in `docs/proposed_repo_structure.md`:

- `configs/` - Configuration templates for various services (Plex, Sonarr, Radarr, etc.)
- `scripts/` - Automation scripts for setup, maintenance, and utilities
- `templates/` - Reusable configuration templates and folder structures
- `monitoring/` - Health checks and monitoring configurations
- `data/` - Runtime data (gitignored)
- `logs/` - Application logs (gitignored)
- `docs/` - Project documentation and planning

## System Configuration

### Media Storage Structure
- **TV Shows**: `A:\Media\TV Shows\` - Final media library (hardlinked from downloads)
- **TV Downloads**: `A:\Downloads\TV\` - Active torrent seeding location
- **Movies**: `A:\Downloads\Movies\` - Prepared for Radarr (when configured)
- **Books Downloads**: `A:\Downloads\Books\` - For ebook/audiobook download seeding
- **Literature Library**: `A:\Media\Literature\` - Ebook/audiobook library (source for Calibre)
- **Calibre Library**: Managed by Calibre (location TBD)
- **Incomplete**: `A:\Downloads\Incomplete\` - qBittorrent temp download location

### Key Configuration Details
- **Hardlinks**: Enabled in Sonarr (`copyUsingHardlinks: true`) - Files exist in both download and media locations but only consume disk space once
- **qBittorrent Auto TMM**: Enabled - Category save paths work automatically
- **Sonarr Quality Profile**: Conservative HD-1080p (prefers WEBDL-1080p, cutoff at WEBDL-1080p)
- **Naming Convention**: `{Series Title} - S{season:00}E{episode:00} - {Episode Title}` (Plex standard)

### Important: Private Tracker Considerations
- Minimum seed time: 10 days (configured in qBittorrent)
- `removeCompletedDownloads: false` in Sonarr - Critical for maintaining ratio
- Future: Consider implementing Autobrr for ratio-aware automation

## Key Project Phases

1. **Phase 1**: Basic Plex server setup with expanded storage
2. **Phase 2**: Research automation tools (Sonarr, Radarr, Prowlarr, etc.)
3. **Phase 3**: Basic automation implementation
4. **Phase 4**: Advanced features and optimization

## Important Files & Documentation

### Core Documentation
- `docs/project_tracker.md` - Detailed phase breakdown and task tracking
- `docs/proposed_repo_structure.md` - Repository structure design
- `docs/Sonarr_Setup_Guide.md` - Comprehensive Sonarr setup documentation
- `docs/SONARR_SETUP_COMPLETE.md` - Current operational status
- `docs/Calibre-Web_Remote_Access_Guide.md` - Cloudflare Tunnel setup guide for remote ebook library access
- `docs/Calibre-Web_Remote_Access_COMPLETE.md` - **Completed setup documentation (operational)**
- `docs/Calibre-Web_Configuration_Decisions.md` - Configuration decisions made during setup
- `docs/Calibre-Web_Security_Checklist.md` - Security hardening checklist (optional next steps)
- `docs/Calibre_Tag_Management_Guide.md` - **Tag standardization system for 1,700+ book library**
- `.gitignore` - Configured to exclude sensitive configs, media files, and runtime data

### Configuration Files
- **Sonarr**: `C:\ProgramData\Sonarr\config.xml` (contains API key: gitignored)
- **Prowlarr**: API configuration managed via `config.ps1` (gitignored)
- **qBittorrent**: Web UI at http://localhost:8080 (credentials in config.ps1)
- **Calibre-Web**: Config at `A:\Media\Calibre-Web-Config\` (http://localhost:8083, https://books.mnemo.info)
- **Cloudflared**: Tunnel configuration at `C:\Users\rokon\.cloudflared\` (configured and operational)
- **Cloudflare Tunnel**: calibre-web-tunnel pointing to books.mnemo.info
- **Credentials**: All sensitive data stored in `config.ps1` (see Credential Management below)

## Configuration Strategy

### Credential Management
**IMPORTANT**: This project uses `config.ps1` for secure credential storage.

- **`config.ps1`**: Contains all API keys and passwords (gitignored, never committed)
- **`config.ps1.template`**: Template with placeholders (committed to git)
- **Scripts**: Automatically load credentials from `config.ps1`
- **Setup**: Copy `config.ps1.template` to `config.ps1` and fill in your credentials

See `docs/Credential_Management_Guide.md` for detailed instructions.

### File Organization
- Use template files (`.template` extension) to avoid committing sensitive data
- Separate configuration structure from sensitive values
- Runtime configurations stored in `data/configs/` (gitignored)
- Application configs in `C:\ProgramData\[AppName]\` (gitignored)

## Technology Stack

### Currently Deployed
- **Media Server**: Plex Media Server (running on Windows)
- **TV Automation**: Sonarr v4.0.15.2941 (http://localhost:8989)
- **Indexer Manager**: Prowlarr (http://localhost:9696)
- **Download Client**: qBittorrent (http://localhost:8080)
- **Ebook Management**: Calibre (desktop application) + Calibre-Web (http://localhost:8083)
- **Ebook Library**: `A:\Media\Calibre` (~70 books, standardized and organized)
- **Private Trackers**: TorrentDay, TorrentLeech, Darkpeers, MyAnonamouse

### Completed Features
- **Remote Access**: Cloudflare Tunnel (cloudflared) operational ✅
  - Domain: mnemo.info (registered via Porkbun)
  - HTTPS access at https://books.mnemo.info
  - Automatic startup via Windows Task Scheduler
  - Family/friend sharing active without exposing home IP
- **Email/Send-to-Kindle**: SMTP fully configured ✅
  - Gmail SMTP (port 587, StartTLS)
  - Send-to-Kindle functionality working on multiple devices
  - Users can email EPUBs directly to their Kindle devices
  - rokonin@gmail.com approved in Amazon Kindle settings

### Planned/Future
- **Movie Automation**: Radarr
- **Ebook Automation**: Readarr (for automated ebook acquisition)
- **Subtitle Automation**: Bazarr
- **Request Management**: Overseerr
- **Monitoring**: Tautulli
- **Orchestration**: Docker Compose (considering migration)

## Common Issues & Troubleshooting

### qBittorrent: Downloads Not Using Category Save Paths

**Symptom:** Torrents download to global save path (e.g., `A:\Media`) instead of category-specific paths (e.g., `A:\Downloads\TV`)

**Root Cause:** Automatic Torrent Management (Auto TMM) not enabled

**Solution:**
1. Run `Enable-qBittorrent-AutoTMM.ps1` to enable Auto TMM globally
2. Verify with `Debug-qBittorrent-Downloads.ps1`
3. Key setting: `auto_tmm_enabled = true` AND `torrent_changed_tmm_enabled = true`

**Why This Matters:** When Sonarr/Radarr add torrents via API with a category, qBittorrent only respects the category's save path if Auto TMM is enabled. Otherwise, it uses the global default path.

**Alternative:** If Auto TMM doesn't work, set qBittorrent's global save path to your primary download location

### Sonarr: Hardlinks vs Copies

**Current Configuration:** Hardlinks enabled (`copyUsingHardlinks: true`)

**How to Verify:**
```powershell
.\scripts\Check-Sonarr-MediaManagement.ps1
```

**Important:** Hardlinks only work when source and destination are on the same drive. Since both `A:\Downloads\TV` and `A:\Media\TV Shows` are on the A:\ drive, hardlinks work correctly.

**Benefit:** Files appear in both locations but only use disk space once. Critical for maintaining seeding ratios on private trackers.

### Private Tracker Ratio Management

**Current Protection:**
- `removeCompletedDownloads: false` in Sonarr - Files stay in qBittorrent for seeding
- Minimum seed time: 10 days in qBittorrent

**Future Enhancement:** Consider implementing [Autobrr](https://autobrr.com/) for ratio-aware automation and freeleech monitoring

**Manual Ratio Monitoring:** Currently required. Check tracker stats weekly and adjust indexer priorities in Sonarr if needed.

### Prowlarr Indexer Sync Issues

**Check Sync Status:**
```powershell
.\scripts\Verify-Sonarr-Setup.ps1
```

**Resync if Needed:**
```powershell
.\scripts\Sync-Prowlarr-Indexers.ps1
```

## Utility Scripts Reference

### Maintenance & Backup
- **`Backup-Configs.ps1`** - **Weekly backup**: Sonarr + Prowlarr + Radarr (API-triggered zip), Calibre-Web app.db, Cloudflare tunnel config. Compresses to dated archive at `A:\Backups\MediaStack\`, prunes old backups automatically.
  - `.\scripts\Backup-Configs.ps1` — normal run (uses API + config.ps1 credentials)
  - `.\scripts\Backup-Configs.ps1 -SkipApiBackups` — raw DB copy, no API needed
  - `.\scripts\Backup-Configs.ps1 -BackupRoot "D:\Backups" -KeepCount 12` — custom path/retention
- **`Schedule-WeeklyBackup.ps1`** - Registers `Backup-Configs.ps1` as a Windows Task Scheduler job (runs as SYSTEM, every Sunday 3 AM). Requires Administrator. Re-run to update schedule.
- **`Auto-CleanupOrphans.ps1`** - **Weekly automated cleanup** orchestrator. Identifies and removes hardlink-orphaned download torrents (true disk duplicates) while preserving private-tracker safety. Pipeline: disk-free gate -> -arr queue exclusion -> seeding audit dry-run -> hardlink failure analysis -> targeted removal via qBittorrent API (deleteFiles=true) -> log + email summary. Defaults: 300 GB free-space threshold, 21-day seed minimum, books/audiobooks/music categories excluded, MAM tracker (`t.myanonamouse.net`) excluded. Logs to `logs\auto_cleanup_<timestamp>.log`. Requires SMTP credentials in `config.ps1` for email reporting.
  - `.\scripts\Auto-CleanupOrphans.ps1` -- standard run (auto-skips if free space > 300 GB)
  - `.\scripts\Auto-CleanupOrphans.ps1 -Force -DryRun` -- analyze + email summary, no deletions
  - `.\scripts\Auto-CleanupOrphans.ps1 -NoEmail` -- skip email (useful for testing)
  - `.\scripts\Auto-CleanupOrphans.ps1 -FreeSpaceThresholdGB 500 -MinSeedDays 28` -- custom thresholds
- **`Schedule-WeeklyCleanup.ps1`** - Registers `Auto-CleanupOrphans.ps1` as a Windows Task Scheduler job (runs as SYSTEM, every Monday 4 AM -- 1h after the weekly backup). Requires Administrator.

### Sonarr Configuration & Management
- **`Configure-Sonarr.ps1`** - Complete Sonarr configuration via API (quality profiles, naming, root folder)
- **`Configure-Sonarr-Simple.ps1`** - Minimal essential Sonarr setup
- **`Connect-Prowlarr-To-Sonarr.ps1`** - Connect Prowlarr indexers to Sonarr
- **`Connect-qBittorrent-To-Sonarr.ps1`** - Connect qBittorrent download client to Sonarr
- **`Verify-Sonarr-Setup.ps1`** - Verify Sonarr configuration and connectivity
- **`Check-Sonarr-MediaManagement.ps1`** - Check media management settings (hardlinks, import behavior)
- **`Check-Sonarr-DownloadClient.ps1`** - Inspect download client configuration in Sonarr

### qBittorrent Configuration & Troubleshooting
**Essential for Setup:**
- **`Enable-qBittorrent-AutoTMM.ps1`** - **CRITICAL**: Enable Automatic Torrent Management (required for category save paths to work)
- **`Setup-qBittorrent-Categories-Complete.ps1`** - Complete category setup for TV/Movies/Books with Auto TMM configuration
- **`Update-qBittorrent-Category-Path.ps1`** - Update an existing category's save path

**Diagnostics:**
- **`Debug-qBittorrent-Downloads.ps1`** - Comprehensive diagnostic showing global paths, categories, and recent torrent locations
- **`Check-qBittorrent-Categories.ps1`** - Quick category configuration check
- **`Check-qBittorrent-Settings.ps1`** - Network settings, announce settings, tracker status

**Troubleshooting/Utilities:**
- **`Check-StalledUP-Trackers.ps1`** - Check tracker announce status for stalled torrents
- **`Force-Reannounce-All.ps1`** - Force reannounce to all stalledUP torrents. Auto-loads qBittorrent username AND password from `config.ps1` (no prompt). `-user`/`-password` params override. Uses `-UseBasicParsing` so it never triggers the IE-engine security prompt.
- **`Show-All-Torrents.ps1`** - Display all torrents with details

**VPN Port Forwarding (ProtonVPN) -- fully automated:**
ProtonVPN assigns a new forwarded port each session. Instead of reading it from the GUI and typing it into qBittorrent by hand (which previously caused stalled torrents and a self-inflicted WebUI ban), these scripts keep them in sync automatically via NAT-PMP (gateway `10.2.0.1`, pure PowerShell, no `natpmpc.exe`). Works with the ProtonVPN GUI app today and a bare WireGuard tunnel later without code changes -- see `docs/QBITTORRENT_VPN_BINDING.md`.
- **`Sync-VpnPort.ps1`** - Reads the live forwarded port via NAT-PMP, renews the lease, and when it differs from qBittorrent's listening port updates qBittorrent (Web API) and force-reannounces all torrents. Logs to `logs\vpn_port_sync.log`.
  - `.\scripts\Sync-VpnPort.ps1 -Once` -- single pass, prints whether the port matches (use to test)
  - `.\scripts\Sync-VpnPort.ps1` -- run forever, ~45s loop (used by the scheduled task)
- **`Schedule-VpnPortSync.ps1`** - Registers `Sync-VpnPort.ps1` as a logon-triggered Scheduled Task that runs continuously (unlimited execution time, single instance). Requires Administrator.

**Seeding Audit & Cleanup:**
- **`Audit-Seeding-Torrents.ps1`** - Reports all torrents with seed time, ratio, size, and tracker. Buckets by multiple thresholds (10/14/21/30 days), breaks down per-tracker and per-category. Flags low-ratio candidates. Optional `-ExportCsv` flag.
  - `.\scripts\Audit-Seeding-Torrents.ps1` - audit all torrents (default 10d threshold)
  - `.\scripts\Audit-Seeding-Torrents.ps1 -MinDays 14` - stricter threshold
  - `.\scripts\Audit-Seeding-Torrents.ps1 -Category tv-sonarr` - single category only
  - `.\scripts\Audit-Seeding-Torrents.ps1 -ExportCsv` - save results to `data\torrent_audit_<date>.csv`
- **`Remove-SeededTorrents.ps1`** - Removes torrents meeting the seed threshold and deletes their Downloads copies. Runs as dry run by default -- requires `-Execute` to make changes. Hardlink safety check (fsutil) confirms the Media library copy exists before deleting anything. Ebook/audiobook/music categories always skipped. Torrents failing the hardlink check are reported but never deleted.
  - `.\scripts\Remove-SeededTorrents.ps1` - dry run, shows what would be removed
  - `.\scripts\Remove-SeededTorrents.ps1 -Execute` - actually remove eligible torrents
  - `.\scripts\Remove-SeededTorrents.ps1 -MinDays 14 -Execute` - stricter threshold
  - `.\scripts\Remove-SeededTorrents.ps1 -Category tv-sonarr -Execute` - one category only

**Hardlink Failure Workflow (true-duplicate cleanup):**
Counterpart to `Remove-SeededTorrents.ps1`. While that script protects torrents whose Media copy is hardlinked (deletion would free 0 GB), the scripts below target the inverse case -- torrents whose Downloads copy is NOT linked to Media (Sonarr upgraded, replaced, or never imported them as hardlinks). These are true disk duplicates and removal frees real space.
- **`Extract-HardlinkFailures.ps1`** - Parses captured stdout from a `Remove-SeededTorrents.ps1` dry run and writes a fresh `data\hardlink_failures.txt` for the analyzer. Auto-detects newest `data\seeded_dryrun_*.txt`.
- **`Analyze-HardlinkFailures.ps1`** - Categorizes each failure as `UPGRADE_ORPHAN_EPISODE`, `SEASON_COMPLETE`, `MOVIE_FOUND` (safe to remove), `ACTIVE_SEASON` / `MISSING_SEASON` / `SHOW_NOT_IN_MEDIA` / `MOVIE_NOT_FOUND` (investigate), `BOOK_OR_OTHER` (skip), or `AMBIGUOUS` (manual review). Exports `data\hardlink_analysis_<date>.csv`. Use `-ExportCsv`.
- **`Verify-MediaTargets.ps1`** - Sanity-checks every `MediaPath` in the analysis CSV before deletion -- confirms the target file or season folder is actually on disk with playable video content.
- **`Remove-HardlinkOrphanTorrents.ps1`** - Removes torrents from qBittorrent (`deleteFiles=true`) for analyzed entries in the safe categories. Three independent safety layers: (1) re-checks video-file hardlink status at removal time, (2) refuses any `content_path` under `A:\Media`, (3) excludes configurable qB categories (default: `books`, `audiobooks`, `music`), tracker hosts (default: `t.myanonamouse.net`), and arbitrary hashes (used by the orchestrator to skip -arr queue items). Dry run by default; requires `-Execute`.
  - `.\scripts\Remove-HardlinkOrphanTorrents.ps1` -- dry run with all safety filters active
  - `.\scripts\Remove-HardlinkOrphanTorrents.ps1 -Execute` -- apply removals
  - `.\scripts\Remove-HardlinkOrphanTorrents.ps1 -ExcludeTrackers @("t.myanonamouse.net","cow.milkie.cc") -Execute` -- additional tracker guards
- **`Auto-CleanupOrphans.ps1`** (above in Maintenance & Backup) -- chains all four steps under safety gates and emails a summary.

Typical manual sequence (one-shot deep clean):
```powershell
.\scripts\Remove-SeededTorrents.ps1 -MinDays 21 *>&1 | Tee-Object data\seeded_dryrun.txt
.\scripts\Extract-HardlinkFailures.ps1 -InputFile data\seeded_dryrun.txt
.\scripts\Analyze-HardlinkFailures.ps1 -ExportCsv
.\scripts\Verify-MediaTargets.ps1
.\scripts\Remove-HardlinkOrphanTorrents.ps1            # dry run
.\scripts\Remove-HardlinkOrphanTorrents.ps1 -Execute   # apply
```

### RAR Archive Extraction
Downloads from some release groups (e.g. BRAVERY) arrive as multi-part RAR archives (`.rar` + `.r00`, `.r01`, ...) instead of plain video files. Use this script to extract before Sonarr can import.
- **`Extract-RarSeason.ps1`** - Extracts multi-part RAR archives for every episode in a season folder. Skips episodes already extracted. Requires 7-Zip (expected at `C:\Program Files\7-Zip\7z.exe`).
  - `.\scripts\Extract-RarSeason.ps1 -SeasonPath "A:\Downloads\TV\Show.S01.1080p..."` - extract all episodes
  - Re-run safely: already-extracted episodes are skipped automatically
  - After extraction, trigger Sonarr import via **Wanted -> Manual Import** or **Series -> Rescan Files**

### Media Library Management
**Active Scripts:**
- **`Quick-Delete-Empty.ps1`** - Delete empty directories in media library
- **`Force-Delete-Empty.ps1`** - Force delete empty directories (including hidden files)

**Archive (Historical cleanup scripts - use with caution):**
- Various cleanup and rename scripts in `scripts/Archive/` for one-time library organization tasks

## Best Practices & Lessons Learned

### qBittorrent Configuration
1. **Always enable Auto TMM** (`auto_tmm_enabled = true`) for category-based save paths to work
2. **Categories for organization**: Use separate categories for each *arr application:
   - `tv-sonarr` → `A:\Downloads\TV`
   - `movie-radarr` → `A:\Downloads\Movies`
   - `books` → `A:\Downloads\Books`
3. **Never remove completed downloads** in *arr apps when using private trackers - set `removeCompletedDownloads: false`

### Sonarr/Radarr Setup
1. **Use hardlinks** when downloads and media are on the same drive (saves disk space, maintains seeds)
2. **Category assignment is automatic** - Sonarr/Radarr assign their categories when sending to qBittorrent
3. **Quality profiles matter** - Set conservative cutoffs to avoid endless upgrading and ratio drain
4. **Test with manual search first** before enabling automatic episode searching

### Private Tracker Safety
1. **Set minimum seed times** in qBittorrent (10+ days recommended)
2. **Monitor ratio regularly** - No automated solution currently in place
3. **Consider freeleech priority** when configuring release profiles
4. **Buffer awareness** - Be mindful of download volume vs upload capacity

### API Keys & Security
- **All credentials managed via `config.ps1`** (gitignored, never committed)
- API keys regenerated on 2025-10-28 (old keys in git history are now invalid)
- Scripts automatically load credentials from `config.ps1` or accept parameters
- Template files (`.template`) provide secure script patterns
- See `docs/Credential_Management_Guide.md` for complete security documentation

### Development Workflow
1. **Test scripts in development** before applying to production configuration
2. **Use diagnostic scripts** (`Debug-*.ps1`) to understand current state before making changes
3. **Document configuration changes** in comments and commit messages
4. **Keep archive of working configurations** before major changes

## Next Steps for Future Development

### Short Term (Ebook & Movie Setup)
**Ebook Management (COMPLETE - 2025-12-06):**
1. ✅ Standardized library - Calibre managing organization at `A:\Media\Calibre`
2. ✅ Clean import with consistent metadata (~70 books)
3. ✅ Calibre-Web installed and configured for web-based access
4. ✅ Remote access via Cloudflare Tunnel at https://books.mnemo.info
5. ✅ Automatic startup on login via Windows Task Scheduler
6. ✅ **SMTP/Send-to-Kindle configured** - Gmail App Password, working on multiple devices
7. ✅ **User management complete** - Multiple family/friend accounts with permissions
8. ✅ **Security hardening complete** - Admin password changed, anonymous browsing disabled, proxy headers enabled
9. 📚 **Current Workflow:** Manual import (Download → qBittorrent → Calibre Desktop → Calibre-Web → Send to Kindle)
10. 🔜 **Next:** Install Readarr for automated ebook acquisition
11. 🔜 Integrate Readarr with Prowlarr (MyAnonamouse indexer already configured)

**Radarr Setup: COMPLETE ✅**
- Radarr operational at http://localhost:7878
- Connected to Prowlarr indexers and qBittorrent (`movie-radarr` category → `A:\Downloads\Movies`)
- Conservative HD-1080p quality profile, hardlinks enabled, root folder at `A:\Media\Movies`

### Medium Term
1. **Autobrr Integration** - For ratio-aware downloads and freeleech monitoring
2. **Overseerr/Jellyseerr** - User-friendly request management
3. **Monitoring Dashboard** - Tautulli or Grafana for visibility
4. **Backup Automation** - Automated config backups for all *arr apps

### Long Term Considerations
1. **Docker Migration** - Consider containerizing services for easier management
2. **Remote Access** - Secure external access setup (VPN recommended)
3. **Multiple Quality Tiers** - Different profiles for different content types
4. **Subtitle Automation** - Bazarr integration for automatic subtitle downloads

## Quick Reference Commands

### Check System Status
```powershell
# Verify Sonarr configuration
.\scripts\Verify-Sonarr-Setup.ps1

# Check qBittorrent download behavior
.\scripts\Debug-qBittorrent-Downloads.ps1 -Password "yourpassword"

# Check Sonarr media management settings
.\scripts\Check-Sonarr-MediaManagement.ps1
```

### Initial Setup (Reference Only - Already Completed)
```powershell
# Enable Auto TMM in qBittorrent (CRITICAL for category paths)
.\scripts\Enable-qBittorrent-AutoTMM.ps1 -Password "yourpassword"

# Set up all categories (TV, Movies, Books)
.\scripts\Setup-qBittorrent-Categories-Complete.ps1 -Password "yourpassword"

# Configure Sonarr
.\scripts\Configure-Sonarr.ps1 -ApiKey "your-api-key"

# Connect services
.\scripts\Connect-Prowlarr-To-Sonarr.ps1
.\scripts\Connect-qBittorrent-To-Sonarr.ps1 -qBitUsername "username" -qBitPassword "password"
```

### Ebook Management
```powershell
# Start Calibre-Web + Cloudflare Tunnel (recommended - auto-starts on login)
.\Start-CalibreWeb-Remote.bat
# Access at: http://localhost:8083 or https://books.mnemo.info

# Start services (PowerShell)
.\scripts\Start-CalibreWeb-With-Tunnel.ps1

# Stop services
.\scripts\Stop-CalibreWeb-And-Tunnel.ps1

# Check if services are running
Get-Process | Where-Object {$_.ProcessName -like "*cps*" -or $_.ProcessName -like "*cloudflared*"}

# Check tunnel connection status
& "C:\Users\rokon\.cloudflared\cloudflared.exe" tunnel info calibre-web-tunnel

# Check ebook library status
.\scripts\Check-Literature-Directory.ps1

# Compare Calibre import
.\scripts\Compare-Calibre-Import.ps1
```

**Send-to-Kindle Features:**
- Users can send EPUB books directly to Kindle devices via email
- SMTP configured with Gmail (rokonin@gmail.com)
- Sender approved in Amazon Kindle settings
- Default subject/body work perfectly - no customization needed
- Tested and working on multiple users' devices

**Tag Management System:**
```powershell
# Initial library cleanup (one-time)
.\scripts\Audit-Calibre-Tags.ps1  # Analyze current tags
# Review reports in .\data\calibre_tag_audit\
Copy-Item .\configs\calibre_tag_mapping.ps1.template .\configs\calibre_tag_mapping.ps1
# Edit calibre_tag_mapping.ps1 based on audit results
.\scripts\Update-Calibre-Tags.ps1 -DryRun  # Test migration
.\scripts\Update-Calibre-Tags.ps1  # Apply standardization

# Ongoing maintenance (after new imports)
.\scripts\Tag-New-Calibre-Imports.ps1  # Auto-tag books added in last 7 days
.\scripts\Tag-New-Calibre-Imports.ps1 -Interactive  # Confirm each book
```

**Tag Management Features:**
- Standardized taxonomy based on BISAC industry standards
- 3-5 tags per book (optimal for browsing)
- Hierarchical structure (e.g., Fiction.Science Fiction.Space Opera)
- Automated cleanup of duplicates and malformed tags
- Keyword-based auto-tagging for new imports
- See `docs/Calibre_Tag_Management_Guide.md` for complete documentation

### Troubleshooting
```powershell
# Check tracker status
.\scripts\Check-StalledUP-Trackers.ps1 -Password "yourpassword"

# Force reannounce to trackers
.\scripts\Force-Reannounce-All.ps1 -Password "yourpassword"

# Update category save path
.\scripts\Update-qBittorrent-Category-Path.ps1 -Password "yourpassword"
```

## PowerShell Scripting Gotchas

These issues have caused repeated failures when writing `.ps1` scripts for this project. Check these before debugging.

### 1. Bash eats `$` variables in `-Command` strings
Running `powershell -Command "... $var ..."` from bash causes bash to interpolate `$var` before PowerShell sees it.
**Fix:** Write scripts to a `.ps1` file and run with `-File`. If using `-Command`, escape every `$` as `\$`.

### 2. Pipe `|` inside string literals breaks PS5.1 parser
Using `|` inside a string that is part of a concatenation or `-f` format expression causes "Expressions are only allowed as the first element of a pipeline".
**Fix:** Never use `|` as a visual separator in display strings. Use `--`, `//`, or spaces instead.

### 3. Non-ASCII characters cause cascading parse errors
PowerShell 5.1 reads `.ps1` files as Windows-1252 by default (no BOM). The UTF-8 bytes for an em-dash (`—`, U+2014) include byte `0x94`, which is a right curly-quote in Windows-1252 — PS5.1 treats it as a string terminator, causing "missing terminator" errors many lines later.
**Fix:** Keep all `.ps1` files pure ASCII. Use `--` instead of `—`, straight quotes instead of curly quotes. Diagnose with:
```powershell
$text = [System.IO.File]::ReadAllText('script.ps1')
($text -split '\n') | ForEach-Object -Begin { $i=0 } -Process {
    $i++; $j=0
    $_.ToCharArray() | ForEach-Object { $j++; if ([int]$_ -gt 127) { Write-Host "Line $i char $j : U+$([int]$_.ToString('X4'))" } }
}
```

### 4. Pre-creating a WebRequestSession conflicts with `-SessionVariable`
Using `New-Object Microsoft.PowerShell.Commands.WebRequestSession` before passing `-SessionVariable session` causes a null reference exception.
**Fix:** Remove the `New-Object` line. Let `-SessionVariable` create the variable, then reference it with `$` in later calls:
```powershell
Invoke-WebRequest -Uri $loginUrl -SessionVariable qbSession | Out-Null
Invoke-RestMethod -Uri $apiUrl -WebSession $qbSession
```

### 5. `[byte] -shl` overflows within the 8-bit type and silently yields 0
When assembling a multi-byte integer from a `byte[]` (e.g. parsing a NAT-PMP response), shifting a `[byte]` left by 8 or more bits drops the shifted bits because the operand stays a byte: `[byte]0xEF -shl 8` is `0`, not `61184`. You silently read only the low byte (e.g. port `61391` parses as `207`).
**Fix:** Cast each byte to `[int]` (or `[uint32]` for wider fields) before shifting:
```powershell
$port = ([int]$resp[10] -shl 8) -bor [int]$resp[11]   # correct
```
Diagnose by dumping the raw hex and hand-computing one value. Used in `scripts\Sync-VpnPort.ps1`.

---

## Resources & External Documentation

### Official Documentation
- [Sonarr Wiki](https://wiki.servarr.com/sonarr)
- [Radarr Wiki](https://wiki.servarr.com/radarr)
- [Prowlarr Wiki](https://wiki.servarr.com/prowlarr)
- [qBittorrent Web API](https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1))

### Community Guides
- [TRaSH Guides](https://trash-guides.info/) - Excellent quality profiles and configurations
- [Servarr Wiki](https://wiki.servarr.com/) - Official *arr application documentation
- [qBittorrent Category Setup](https://trash-guides.info/Downloaders/qBittorrent/How-to-add-categories/)

### Tools for Future Consideration
- [Autobrr](https://autobrr.com/) - Ratio-aware automation for private trackers
- [Bazarr](https://www.bazarr.media/) - Subtitle automation
- [Overseerr](https://overseerr.dev/) - Request management
- [Tautulli](https://tautulli.com/) - Plex monitoring
- [Readarr](https://readarr.com/) - Ebook and audiobook automation (like Sonarr for books)
- [Calibre-Web](https://github.com/janeczku/calibre-web) - Web interface for Calibre library
- [LazyLibrarian](https://lazylibrarian.gitlab.io/) - Alternative ebook automation tool