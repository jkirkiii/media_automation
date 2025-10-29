# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Plex Media Server automation project designed to transform a basic Plex server into a fully automated media management system. The project follows a phased approach detailed in `docs/project_tracker.md`.

**Current Status:** Phase 3 - Sonarr configured and operational with qBittorrent integration. Automatic TV show management active. Phase 3.5 - Calibre and Calibre-Web configured and operational. Ebook library standardized and accessible via web interface.

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
- `.gitignore` - Configured to exclude sensitive configs, media files, and runtime data

### Configuration Files
- **Sonarr**: `C:\ProgramData\Sonarr\config.xml` (contains API key: gitignored)
- **Prowlarr**: API configuration managed via `config.ps1` (gitignored)
- **qBittorrent**: Web UI at http://localhost:8080 (credentials in config.ps1)
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

### Planned/Future
- **Movie Automation**: Radarr
- **Ebook Automation**: Readarr (for automated ebook acquisition)
- **Ebook Web Interface**: Calibre-Web (web-based ebook library access)
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
- **`Force-Reannounce-All.ps1`** - Force reannounce to all trackers
- **`Show-All-Torrents.ps1`** - Display all torrents with details

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
**Ebook Management (Complete - Manual Workflow Active):**
1. ✅ Standardized library - Calibre managing organization at `A:\Media\Calibre`
2. ✅ Clean import with consistent metadata (~70 books)
3. ✅ Calibre-Web installed and configured for web-based access
4. 📚 **Current Workflow:** Manual import (Download → qBittorrent → Calibre Desktop → Calibre-Web)
5. 🔜 **Next:** Install Readarr for automated ebook acquisition
6. 🔜 Integrate Readarr with Prowlarr (MyAnonamouse indexer already configured)

**Radarr Setup:**
1. Install and configure Radarr following similar pattern to Sonarr
2. Connect Radarr to Prowlarr for indexers
3. Configure `movie-radarr` category in qBittorrent download client settings
4. Set up quality profiles (consider Conservative HD-1080p similar to TV)
5. Test with manual movie search before enabling automation

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
# Start Calibre-Web
.\Start-CalibreWeb.bat
# Access at: http://localhost:8083

# Check ebook library status
.\scripts\Check-Literature-Directory.ps1

# Compare Calibre import
.\scripts\Compare-Calibre-Import.ps1
```

### Troubleshooting
```powershell
# Check tracker status
.\scripts\Check-StalledUP-Trackers.ps1 -Password "yourpassword"

# Force reannounce to trackers
.\scripts\Force-Reannounce-All.ps1 -Password "yourpassword"

# Update category save path
.\scripts\Update-qBittorrent-Category-Path.ps1 -Password "yourpassword"
```

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