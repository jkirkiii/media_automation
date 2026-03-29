# Calibre Tag Management - Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: "Failed to retrieve books from Calibre library"

**Cause:** Calibre-Web (or Calibre Desktop) is running and has locked the library database.

**Solution Options:**

**Option A: Let the script handle it (Recommended)**
```powershell
# The script will detect Calibre-Web and prompt you
.\scripts\Audit-Calibre-Tags.ps1

# Or automatically stop Calibre-Web
.\scripts\Audit-Calibre-Tags.ps1 -StopCalibreWeb
```

**Option B: Manually stop Calibre-Web first**
```powershell
# Stop services
.\scripts\Stop-CalibreWeb-And-Tunnel.ps1

# Run your tag script
.\scripts\Audit-Calibre-Tags.ps1

# Restart services when done
.\scripts\Start-CalibreWeb-With-Tunnel.ps1
```

**Option C: Use Calibre Desktop**
- Close Calibre Desktop if it's open
- The tag management scripts require exclusive access to the database

---

### Issue 2: "calibredb: command not found"

**Cause:** PowerShell can't find the `calibredb` executable.

**Solution:**

**Check if Calibre is installed:**
```powershell
# This should show the path to calibredb.exe
where.exe calibredb
```

**If not found, add Calibre to your PATH:**

**Temporary (current session only):**
```powershell
$env:Path += ";C:\Program Files\Calibre2\"
```

**Permanent:**
1. Open System Properties → Advanced → Environment Variables
2. Edit the "Path" variable under "System variables"
3. Add: `C:\Program Files\Calibre2\`
4. Click OK and restart PowerShell

---

### Issue 3: "No tag mappings defined"

**Cause:** You haven't created the `calibre_tag_mapping.ps1` file yet.

**Solution:**
```powershell
# Copy the template
Copy-Item .\configs\calibre_tag_mapping.ps1.template .\configs\calibre_tag_mapping.ps1

# Edit it to add your mappings
notepad .\configs\calibre_tag_mapping.ps1
```

**At minimum, the file should contain:**
```powershell
$script:TagMappings = @{
    # Add your mappings here
    "Sci-Fi" = "Fiction.Science Fiction"
}
```

---

### Issue 4: Scripts run but make no changes

**Possible Causes:**

1. **Dry-run mode is enabled**
   - Remove the `-DryRun` flag when you're ready to apply changes

2. **No books match the filter**
   - Check your `-Filter` parameter
   - Run without filter to process all books

3. **Tags already match mappings**
   - Your library might already be clean!
   - Check the audit report to see current tag status

---

### Issue 5: "Access denied" or permission errors

**Cause:** PowerShell doesn't have permission to modify the Calibre library.

**Solutions:**

1. **Run PowerShell as Administrator:**
   - Right-click PowerShell
   - Select "Run as Administrator"

2. **Check file permissions:**
   ```powershell
   # Check if you can write to the library
   Test-Path "A:\Media\Calibre" -PathType Container
   ```

3. **Ensure library isn't on read-only drive:**
   - Check drive A:\ properties

---

### Issue 6: Changes don't show in Calibre-Web

**Cause:** Calibre-Web caches metadata and needs to be restarted.

**Solution:**
```powershell
# Restart Calibre-Web to pick up changes
.\scripts\Stop-CalibreWeb-And-Tunnel.ps1
.\scripts\Start-CalibreWeb-With-Tunnel.ps1
```

Or use the web interface:
1. Log into Calibre-Web as admin
2. Go to Admin → Configuration → Basic Configuration
3. Click "Reconnect to the database"

---

### Issue 7: Tags appear but not hierarchically

**Cause:** Calibre isn't configured to show hierarchical tags.

**Solution (Calibre Desktop):**
1. Open Calibre Desktop
2. **Preferences → Look & feel → Tag browser**
3. Under "Categories to partition", find "tags"
4. Set "Partition method" to "partition by value"
5. Set "Value to partition on" to `.` (period)
6. Click Apply and restart Calibre

**Solution (Calibre-Web):**
- Calibre-Web doesn't natively support hierarchical tag display
- Tags will still work for filtering, just shown as flat list
- Consider using the tag search/filter features instead

---

### Issue 8: Audit script shows 0 books

**Possible Causes:**

1. **Wrong library path:**
   ```powershell
   # Verify your library location
   dir "A:\Media\Calibre\metadata.db"

   # If in different location, specify:
   .\scripts\Audit-Calibre-Tags.ps1 -LibraryPath "D:\Your\Path\Here"
   ```

2. **Empty library:**
   ```powershell
   # Check if library has books
   calibredb list --library-path "A:\Media\Calibre"
   ```

---

### Issue 9: Script is very slow on large library

**Expected Performance:**
- ~1,700 books should take 2-5 minutes for audit
- Tag updates: ~30-60 seconds per 100 books

**Optimization Tips:**

1. **Use filters to process in batches:**
   ```powershell
   # Only process Science Fiction books
   .\scripts\Update-Calibre-Tags.ps1 -Filter "tags:Sci-Fi"
   ```

2. **Process new imports separately:**
   ```powershell
   # Only recent additions
   .\scripts\Tag-New-Calibre-Imports.ps1 -DaysBack 7
   ```

3. **Close other applications:**
   - Close Calibre Desktop
   - Stop Calibre-Web
   - Reduce disk I/O from other programs

---

### Issue 10: Backup failed

**Cause:** Not enough disk space or permission issues.

**Solutions:**

1. **Check disk space:**
   ```powershell
   # Check free space on A:\
   Get-PSDrive A | Select-Object Used,Free
   ```

2. **Skip backup (not recommended):**
   ```powershell
   .\scripts\Update-Calibre-Tags.ps1 -NoBackup
   ```

3. **Manual backup first:**
   ```powershell
   # Create manual backup
   Copy-Item "A:\Media\Calibre\metadata.db" "A:\Media\Calibre\metadata.db.backup"

   # Then run script with -NoBackup
   .\scripts\Update-Calibre-Tags.ps1 -NoBackup
   ```

---

## Verification Commands

**Check if Calibre-Web is running:**
```powershell
Get-Process | Where-Object {$_.ProcessName -like "*cps*"}
```

**Test calibredb connection:**
```powershell
calibredb list --library-path "A:\Media\Calibre" --fields id,title --limit 5
```

**Check library size:**
```powershell
calibredb list --library-path "A:\Media\Calibre" --for-machine | ConvertFrom-Json | Measure-Object
```

**View recent changes:**
```powershell
# Check latest change log
dir .\data\calibre_tag_updates_*.csv | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

---

## Getting Help

### Debug Mode

For more detailed error information:
```powershell
# Run with verbose output
$VerbosePreference = "Continue"
.\scripts\Audit-Calibre-Tags.ps1
```

### Check Script Versions

All scripts should have been created on 2025-12-06. If you're getting errors, ensure you have the latest versions:

```powershell
# Check script modification dates
dir .\scripts\*Calibre-Tag*.ps1 | Select-Object Name, LastWriteTime
```

### Manual Database Query

If scripts fail, you can query the database directly with Calibre Desktop:
1. Open Calibre Desktop
2. Use the search bar to filter books
3. Select books and use "Edit metadata in bulk" to modify tags manually

---

## Best Practices to Avoid Issues

1. **Always run audit first** before making changes
2. **Use dry-run mode** to preview changes
3. **Stop Calibre-Web** before running tag scripts
4. **Don't run multiple scripts simultaneously**
5. **Keep backups** of `metadata.db` before major changes
6. **Test on small batch** before processing entire library

---

## Emergency Recovery

If something goes wrong:

**Restore from backup:**
```powershell
# Stop Calibre-Web
.\scripts\Stop-CalibreWeb-And-Tunnel.ps1

# Find latest backup
dir "A:\Media\Calibre\metadata.db.backup-*" | Sort-Object LastWriteTime -Descending

# Restore (replace timestamp)
Copy-Item "A:\Media\Calibre\metadata.db.backup-20251206-153045" "A:\Media\Calibre\metadata.db" -Force

# Restart Calibre-Web
.\scripts\Start-CalibreWeb-With-Tunnel.ps1
```

**Undo tag changes:**
- There's no automatic undo
- Use the change log CSV to see what was changed
- Restore from backup or manually fix in Calibre Desktop

---

**Last Updated:** 2025-12-06
