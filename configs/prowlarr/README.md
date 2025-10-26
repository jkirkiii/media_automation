# Prowlarr Configuration

This directory is for **actual** Prowlarr configuration files (backups).

**IMPORTANT:** These files are `.gitignore`d because they contain sensitive data (API keys, passwords, etc.)

## What to Store Here

- Manual backups of `config.xml`
- Manual backups of `prowlarr.db` (optional)
- Export files from Prowlarr (if you create any)

## Actual File Locations

**Windows Native Installation:**
```
C:\ProgramData\Prowlarr\
├── config.xml          # Main configuration
├── prowlarr.db         # Database
├── prowlarr.db-shm     # Database shared memory
├── prowlarr.db-wal     # Write-ahead log
└── Backups\            # Automated backups
```

## Backup Process

To create a manual backup:
1. Open Prowlarr Web UI
2. System → Backup
3. Click "Backup Now"
4. Copy backup from `C:\ProgramData\Prowlarr\Backups\` to this folder
5. Rename with date: `prowlarr_backup_2025-10-25.zip`

## Restore Process

To restore from backup:
1. Stop Prowlarr service
2. Replace `config.xml` and `prowlarr.db` with backup versions
3. Start Prowlarr service
4. Verify configuration in Web UI

## Notes

- Never commit these files to git (they're in .gitignore)
- Keep backups encrypted separately for security
- Use templates in `templates/prowlarr/` for shareable configuration examples
