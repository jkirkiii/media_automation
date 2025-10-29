# Ebook Library Migration Plan

## Overview
Migrating from mixed manual/Calibre organization in `A:\Media\Literature\` to clean Calibre-managed library while preserving active torrent seeding on MyAnonamouse.

**Date Created:** 2025-10-28
**Current Library Location:** `A:\Media\Literature\`
**New Library Location:** `A:\Media\Calibre\`
**Backup Location:** `A:\Media\Literature.backup\`

---

## Critical Considerations

### Torrent Seeding Preservation
**MOST IMPORTANT:** Nearly all books in `A:\Media\Literature\` are actively seeding on MyAnonamouse. We MUST preserve seeding to avoid hit-and-run violations.

**Strategy Options:**

#### Option A: Hardlink Approach (RECOMMENDED)
- Keep original files in `A:\Downloads\Books\` for seeding
- Have Calibre import books and create hardlinks (if on same drive)
- Both locations point to same physical data
- No additional disk space used
- Torrents continue seeding from `A:\Downloads\Books\`

#### Option B: Dual Location Approach
- Keep `A:\Media\Literature\` as seed location
- Create separate Calibre library at `A:\Media\Calibre\`
- Import copies into Calibre (uses more disk space)
- Update qBittorrent save paths if needed

#### Option C: Update qBittorrent Save Paths
- Move files to new Calibre structure
- Update qBittorrent save paths to point to new locations
- More complex, requires careful path updates

---

## Pre-Migration Checklist

### 1. Document Current State
- [ ] Open qBittorrent Web UI (http://localhost:8080)
- [ ] Go to "Books" category (or filter torrents)
- [ ] Export list of all book torrents (save to CSV or take screenshots)
- [ ] Note: Which torrents are in `A:\Media\Literature\` vs `A:\Downloads\Books\`
- [ ] Check current seed ratios and times

### 2. Verify Current Calibre Setup
- [ ] Open Calibre desktop application
- [ ] Check current library location (Calibre → Preferences → Adding books)
- [ ] Note if `A:\Media\Literature\` is already set as a library
- [ ] Export current Calibre metadata (if any): Library → Export catalog

### 3. Disk Space Check
```powershell
# Run this to check available space
Get-PSDrive A | Select-Object Used, Free, @{Name="FreeGB";Expression={[math]::Round($_.Free/1GB,2)}}
```
- [ ] Current Literature size: ~___ GB
- [ ] Available space on A: drive: ~___ GB
- [ ] Sufficient space for backup + new library: [ ]

---

## Migration Plan

### Phase 1: Backup and Document (CRITICAL - DO FIRST)

#### Step 1.1: Create Full Backup
```powershell
# Run the backup script (see Backup-Literature-Library.ps1)
.\scripts\Backup-Literature-Library.ps1
```

**What this does:**
- Creates `A:\Media\Literature.backup\` directory
- Copies entire Literature directory with structure preserved
- Generates file hash manifest for verification
- Creates backup log with timestamps

#### Step 1.2: Verify Backup Integrity
```powershell
# Verify all files copied correctly
.\scripts\Verify-Literature-Backup.ps1
```

**Checks:**
- File count matches
- File sizes match
- Hash verification (optional but recommended)

#### Step 1.3: Document Torrent Locations
```powershell
# Creates a report of all book torrents
.\scripts\Export-Book-Torrent-Locations.ps1 -Password "your-qbit-password"
```

**Output:** `data/ebook-torrents-$(date).csv` with:
- Torrent name
- Save path
- Category
- Size
- State
- Hash (for re-identification)

---

### Phase 2: Identify Torrent File Locations

**MANUAL STEP - VERY IMPORTANT:**

1. Open qBittorrent Web UI
2. For each book torrent, note its **Content Path**
3. Categorize torrents:
   - **Type A:** Seeding from `A:\Media\Literature\` (need to handle)
   - **Type B:** Seeding from `A:\Downloads\Books\` (already in download location, safe)

**Key Question to Answer:**
- Are most/all books seeding from `A:\Media\Literature\`?
- Or are they seeding from `A:\Downloads\Books\`?

**This determines our strategy!**

---

### Phase 3: Choose Migration Strategy

#### If most books seed from `A:\Downloads\Books\`: ✅ EASY PATH

**Strategy:** Import from downloads, leave torrents untouched

1. Create new Calibre library at `A:\Media\Calibre\`
2. Configure Calibre to import from `A:\Downloads\Books\`
3. Use "Add books" with **"Keep original files"** option (do NOT delete)
4. Calibre creates its own organized copy
5. Torrents continue seeding from `A:\Downloads\Books\` unchanged

**Advantages:**
- No risk to torrents
- Clean separation of concerns
- Downloads = seeding location
- Calibre = consumption/management location

---

#### If most books seed from `A:\Media\Literature\`: ⚠️ CAREFUL PATH

**Strategy:** Migrate torrents to download location first, then reorganize

**Step 3.1: Move Seeding Files to Download Location**
1. Pause all book torrents in qBittorrent
2. Create organized structure in `A:\Downloads\Books\`:
   ```
   A:\Downloads\Books\
   ├── Author - Book Title (original torrent format)
   └── ... (keep torrent folder structure)
   ```
3. Move files from `A:\Media\Literature\` to `A:\Downloads\Books\`
4. In qBittorrent: Right-click each torrent → Set location → `A:\Downloads\Books\[torrent-folder]`
5. Force recheck each torrent
6. Resume seeding

**Step 3.2: Then Proceed with Calibre Import**
1. Create new Calibre library at `A:\Media\Calibre\`
2. Import from `A:\Downloads\Books\` (copies into Calibre structure)
3. Now you have:
   - `A:\Downloads\Books\` = Seeding location (unchanged files)
   - `A:\Media\Calibre\` = Calibre-managed library (clean structure)

---

### Phase 4: Set Up New Calibre Library

#### Step 4.1: Create Library Directory
```powershell
New-Item -Path "A:\Media\Calibre" -ItemType Directory -Force
```

#### Step 4.2: Configure Calibre
1. Open Calibre
2. Click "Calibre Library" button (top right) → "Switch/create library"
3. Choose "Create a new, empty library"
4. Location: `A:\Media\Calibre`
5. Click "OK"

#### Step 4.3: Configure Import Settings
1. Preferences → Adding books → Adding actions
2. **IMPORTANT SETTINGS:**
   - ☑ "Add new books to library"
   - ☑ "Copy books to library folder"
   - ☐ "Delete source files after adding" (UNCHECKED for safety!)
   - ☑ "Automatically convert to EPUB"
   - ☑ "Save metadata in book files"

#### Step 4.4: Configure Metadata Sources
1. Preferences → Metadata download
2. Enable sources:
   - Google Books
   - Amazon
   - Goodreads (if available)
   - Open Library

---

### Phase 5: Import Books into Calibre

#### Step 5.1: Test Import with Single Book
1. Choose a non-critical book (one you don't care about as much)
2. Add to Calibre: "Add books" → Select file
3. Verify:
   - Book appears in Calibre
   - Metadata looks correct
   - Original file still exists in download location
   - Torrent still seeding

#### Step 5.2: Batch Import
```powershell
# Option A: Import from download location (if books are there)
# In Calibre: Add books → Choose directory → A:\Downloads\Books
# ☑ "Add books from subdirectories"

# Option B: Import from backup (if downloads location doesn't have them)
# In Calibre: Add books → Choose directory → A:\Media\Literature.backup
# ☑ "Add books from subdirectories"
```

**Calibre will:**
- Detect duplicate formats and consolidate
- Fetch metadata automatically
- Organize into its standard structure
- Create cover thumbnails

#### Step 5.3: Review Import Results
1. Check for import errors (Calibre shows them)
2. Verify book count matches expectations
3. Look for duplicate entries
4. Check that series information is detected

---

### Phase 6: Metadata Cleanup

#### Step 6.1: Auto-Fetch Metadata
1. Select all books (Ctrl+A)
2. Right-click → "Edit metadata" → "Download metadata"
3. Review suggestions, accept/reject
4. Calibre will add:
   - Proper covers
   - Descriptions
   - Series information
   - Publication dates
   - Tags/genres

#### Step 6.2: Series Organization
1. Books with series (e.g., "Parable of the Sower") should auto-detect
2. If not: Right-click → Edit metadata → Series tab
3. Enter series name and number

#### Step 6.3: Format Consolidation
1. Check for books with multiple formats
2. Decide which formats to keep (EPUB is most universal)
3. Remove redundant formats if desired

---

### Phase 7: Verify Torrents Still Seeding

**CRITICAL VERIFICATION STEP:**

1. Open qBittorrent
2. Check all book torrents
3. Verify:
   - [ ] State = "Seeding" (not "Missing files")
   - [ ] Files still exist at expected locations
   - [ ] Upload stats continuing to increase
   - [ ] No errors in torrent status

**If any torrents show "Missing files":**
1. Right-click → "Set location"
2. Browse to correct location
3. Click "OK"
4. Right-click → "Force recheck"
5. Wait for recheck to complete
6. Should resume seeding

---

### Phase 8: Configure Calibre-Web (Future)

**After Calibre library is clean:**

1. Install Calibre-Web (Docker or Windows)
2. Point to `A:\Media\Calibre\` library
3. Configure user access
4. Test web interface

---

### Phase 9: Cleanup (Only After Everything Verified)

**DO NOT DO THIS UNTIL:**
- [ ] New Calibre library is complete
- [ ] All books imported successfully
- [ ] All torrents verified seeding
- [ ] Backup verified and stored safely
- [ ] At least 2 weeks of successful operation

**Then:**
1. Review `A:\Media\Literature\` (old location)
2. If truly no longer needed, archive or delete
3. Keep backup for 30 days minimum

---

## Rollback Plan

**If anything goes wrong:**

1. **Stop immediately**
2. **Do not delete anything**
3. **Restore from backup:**
   ```powershell
   # Copy backup back to original location
   Copy-Item "A:\Media\Literature.backup\*" "A:\Media\Literature\" -Recurse -Force
   ```
4. **Verify torrents:**
   - Check qBittorrent
   - Force recheck all book torrents
   - Verify seeding resumes

---

## Expected Timeline

- **Phase 1-3 (Planning & Backup):** 1-2 hours
- **Phase 4 (Calibre Setup):** 30 minutes
- **Phase 5 (Import):** 2-4 hours (depending on collection size)
- **Phase 6 (Metadata Cleanup):** 1-3 hours
- **Phase 7 (Verification):** 30 minutes
- **Total:** ~5-10 hours spread across multiple sessions

---

## Success Criteria

Migration is successful when:

- [ ] All books imported into Calibre with correct metadata
- [ ] No duplicate books (formats consolidated)
- [ ] Series information correct
- [ ] All book covers present
- [ ] All torrents still seeding (no "missing files" errors)
- [ ] Seed ratios continuing to increase
- [ ] Backup verified and safe
- [ ] Calibre library browsable and searchable
- [ ] Ready for Calibre-Web integration

---

## Next Steps After Migration

1. **Configure Readarr** for automated ebook acquisition
2. **Install Calibre-Web** for web-based library access
3. **Set up automated backups** of Calibre library
4. **Document import workflow** for future books
5. **Consider Readarr → Calibre automation** pipeline

---

## Notes & Lessons Learned

(To be filled in during migration)

- What worked well:
- What was challenging:
- Changes to plan:
- Recommendations for future:

---

**Last Updated:** 2025-10-28
**Status:** Planning Phase - Ready for Execution
