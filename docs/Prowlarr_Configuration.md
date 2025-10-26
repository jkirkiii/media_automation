# Prowlarr Configuration Documentation

**Last Updated:** 2025-10-25
**Version:** Current Setup
**Installation Type:** Windows Native

## Overview

Prowlarr is configured as the central indexer manager, handling all torrent/NZB indexer connections and automatically synchronizing them with Sonarr, Radarr, and other *arr applications.

## Installation Details

- **Platform:** Windows (Native Installation)
- **Installation Path:** _[To be documented]_
- **Service Type:** Windows Service or Application
- **Web UI Port:** _[Typically 9696]_
- **API Access:** Enabled for *arr app integration

## Configured Indexers

**Total Count:** 4 private trackers

### Indexer Configuration Template

For each indexer, the following settings are configured:

```yaml
Indexer Name: [Indexer Name]
Type: Private Tracker
Protocol: Torrent
Base URL: [Tracker URL]
Authentication:
  Username: [Configured]
  Password: [Configured]
  Cookie: [If required]
  API Key: [If required]
Categories Enabled:
  - TV Shows
  - Movies
  - [Other relevant categories]
Search Capabilities:
  - Search
  - TV Search
  - Movie Search
Tags: [Any organizational tags]
Priority: [Indexer priority for search]
```

### General Indexer Settings

- **Minimum Seeders:** _[To be documented]_
- **Seed Ratio:** _[To be documented]_
- **Retention Period:** _[To be documented]_

## Application Sync Configuration

### Connected Applications

1. **Sonarr**
   - Status: To be configured
   - Sync Level: Full categories
   - API Integration: Pending setup

2. **Radarr** (Future)
   - Status: Not yet configured
   - Planned integration

### Sync Settings

```yaml
Sync Categories:
  - TV Shows → Sonarr
  - Movies → Radarr (when configured)
Auto-add New Indexers: [Yes/No]
Remove Deleted Indexers: [Yes/No]
```

## Download Client Configuration

_[To be documented based on your setup]_

Typical configuration:
- **Client Type:** qBittorrent / Transmission / Deluge
- **Connection:** Local or Remote
- **Download Path:** _[To be specified]_

## Network & Security

### Access Control
- **Authentication:** Enabled (Recommended)
- **Username:** _[Configured]_
- **Password:** _[Configured]_
- **SSL/TLS:** _[Enabled/Disabled]_

### API Key
- **API Key:** `[KEEP SECRET - NOT IN REPO]`
- **Location:** Used by Sonarr/Radarr for integration

## Backup & Recovery

### Configuration File Locations

**Windows Native Installation:**
```
C:\ProgramData\Prowlarr\
├── config.xml          # Main configuration (SENSITIVE - DO NOT COMMIT)
├── prowlarr.db         # Database file (SENSITIVE - DO NOT COMMIT)
└── Backups\            # Automated backups
```

### Backup Strategy

1. **Automated Backups:** Prowlarr creates periodic backups in the Backups folder
2. **Manual Backups:** Before major changes, manually backup:
   - `config.xml`
   - `prowlarr.db`
3. **Template Files:** This repo contains sanitized templates only

### Files to Backup (Keep Outside Repo)

- [ ] `config.xml` - Contains API keys and passwords
- [ ] `prowlarr.db` - Contains all indexer credentials
- [ ] `prowlarr.db-shm` - Database shared memory
- [ ] `prowlarr.db-wal` - Write-ahead log

## Integration with Sonarr

### Prerequisites

1. Prowlarr installed and running ✓
2. Indexers configured and tested ✓
3. Sonarr installed (Pending)
4. Download client configured (To be verified)

### Connection Setup (When Ready)

1. **In Prowlarr:**
   - Go to Settings → Apps
   - Add Sonarr application
   - Provide Sonarr URL and API key
   - Select categories to sync

2. **In Sonarr:**
   - Indexers will auto-populate from Prowlarr
   - Verify indexer connectivity
   - Test searches

### API Integration

```yaml
Prowlarr to Sonarr:
  Connection Type: API
  Prowlarr API Key: [From Prowlarr Settings]
  Sonarr URL: http://localhost:[PORT]
  Sonarr API Key: [From Sonarr Settings]
  Sync Categories: TV, TV/UHD, TV/WEB-DL, etc.
```

## Indexer Categories

### TV Shows Categories (For Sonarr)

Typical categories synchronized:
- TV/WEB-DL
- TV/WEBRip
- TV/HDTV
- TV/UHD (4K)
- TV/Documentaries (if separate)
- TV/Anime (if applicable)

### Quality Profiles

_[To be configured in Sonarr, but Prowlarr passes through quality info]_

## Troubleshooting

### Common Issues

**Indexer Connection Failures:**
- Check credentials are up to date
- Verify tracker is not down
- Check rate limits / API limits
- Verify network connectivity

**Sync Issues with Sonarr:**
- Verify API keys are correct
- Check both applications are running
- Review logs in both Prowlarr and Sonarr
- Ensure categories match

### Log Locations

```
C:\ProgramData\Prowlarr\logs\
├── prowlarr.txt        # Main log file
├── prowlarr.debug.txt  # Debug logging (if enabled)
└── prowlarr.trace.txt  # Trace logging (if enabled)
```

## Maintenance Tasks

### Regular Maintenance

- [ ] **Weekly:** Check indexer status and connectivity
- [ ] **Weekly:** Review failed searches
- [ ] **Monthly:** Update Prowlarr to latest stable version
- [ ] **Monthly:** Verify backup integrity
- [ ] **Quarterly:** Review and update indexer credentials if changed

### Health Checks

Monitor Prowlarr's built-in health check for:
- Indexer failures
- Application connection issues
- Disk space warnings
- Update availability

## Configuration Templates

### Creating Sanitized Templates

To document configuration without exposing secrets:

1. Export current settings (if Prowlarr supports it)
2. Create template files with placeholders
3. Document structure and required fields
4. Store in `configs/prowlarr/` directory

**Template Pattern:**
```json
{
  "indexer_name": "EXAMPLE_TRACKER",
  "base_url": "https://tracker.example.com",
  "username": "YOUR_USERNAME_HERE",
  "password": "YOUR_PASSWORD_HERE",
  "api_key": "YOUR_API_KEY_HERE"
}
```

## Next Steps for Sonarr Integration

1. [ ] Install Sonarr (if not already installed)
2. [ ] Configure Sonarr basic settings
3. [ ] Connect Sonarr to Prowlarr
4. [ ] Verify indexer sync
5. [ ] Configure download client in Sonarr
6. [ ] Add TV Shows library path
7. [ ] Test end-to-end: Search → Download → Import

## Additional Resources

- [Prowlarr Documentation](https://wiki.servarr.com/prowlarr)
- [Sonarr Integration Guide](https://wiki.servarr.com/prowlarr/settings#applications)
- [Private Tracker Best Practices](https://wiki.servarr.com/prowlarr/indexers)

---

## Notes

- **Security:** Never commit actual configuration files containing credentials
- **Backups:** Keep encrypted backups of actual config files separately
- **Updates:** Document any configuration changes in this file
- **API Keys:** Rotate API keys periodically for security
