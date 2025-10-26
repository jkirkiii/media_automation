# Sonarr Configuration

This directory is for **actual** Sonarr configuration files (backups).

**IMPORTANT:** These files are `.gitignore`d because they contain sensitive data (API keys, passwords, etc.)

## What to Store Here

- Manual backups of `config.xml`
- Manual backups of `sonarr.db` (optional)
- Export files from Sonarr (if you create any)

## Actual File Locations

**Windows Native Installation:**
```
C:\ProgramData\Sonarr\
├── config.xml          # Main configuration
├── sonarr.db           # Database
├── sonarr.db-shm       # Database shared memory
├── sonarr.db-wal       # Write-ahead log
└── Backups\            # Automated backups
```

## Backup Process

To create a manual backup:
1. Open Sonarr Web UI
2. System → Backup
3. Click "Backup Now"
4. Copy backup from `C:\ProgramData\Sonarr\Backups\` to this folder
5. Rename with date: `sonarr_backup_2025-10-25.zip`

## Restore Process

To restore from backup:
1. Stop Sonarr service
2. Replace `config.xml` and `sonarr.db` with backup versions
3. Start Sonarr service
4. Verify configuration in Web UI

## Notes

- Never commit these files to git (they're in .gitignore)
- Keep backups encrypted separately for security
- Use templates in `templates/sonarr/` for shareable configuration examples
