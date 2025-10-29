# Ebook Library Migration - Quick Start Guide

**READ THE FULL PLAN FIRST:** See `Ebook_Library_Migration_Plan.md` for complete details.

This is a condensed checklist for executing the migration.

---

## Pre-Flight Checklist

Before starting, ensure:

- [ ] You have read the full migration plan
- [ ] qBittorrent is running and torrents are seeding
- [ ] Calibre is installed and updated to latest version
- [ ] At least 100GB free space on A: drive (for backup + new library)
- [ ] No other major disk operations running

---

## Step 1: Document Current Torrent State (15 minutes)

**CRITICAL:** You need to know where your books are seeding from!

1. **Open qBittorrent Web UI:** http://localhost:8080

2. **Identify book torrents:**
   - Look for torrents in the "books" category
   - Or search for torrents with paths containing "Literature" or "Books"

3. **For each book torrent, note:**
   - ❓ Is it seeding from `A:\Media\Literature\`?
   - ❓ Or is it seeding from `A:\Downloads\Books\`?

4. **Decision point:**
   ```
   If MOST books seed from A:\Downloads\Books:
   → Follow "EASY PATH" (no torrent moves needed)

   If MOST books seed from A:\Media\Literature:
   → Follow "CAREFUL PATH" (need to move torrents first)
   ```

**Write down your answer:** _______________________

---

## Step 2: Create Backup (30-60 minutes)

**Run the backup script:**

```powershell
cd C:\Users\rokon\source\media_automation
.\scripts\Backup-Literature-Library.ps1
```

**What this does:**
- Copies `A:\Media\Literature\` → `A:\Media\Literature.backup\`
- Creates file manifest
- Logs everything

**Wait for completion.** Do not proceed until you see "BACKUP COMPLETED SUCCESSFULLY"

---

## Step 3: Verify Backup (5 minutes)

```powershell
.\scripts\Verify-Literature-Backup.ps1
```

**Check the output:**
- ✓ File count matches
- ✓ Total size matches
- ✓ No missing files

**If verification fails:** Stop and investigate before proceeding!

---

## Step 4: Choose Your Path

### EASY PATH (books already in Downloads folder)

Skip to **Step 5** - no torrent moves needed!

### CAREFUL PATH (books in Literature folder)

**You need to move seeding files to Downloads first.**

⚠️ **WARNING:** This is complex and risky. Consider these options:

**Option A: Leave torrents alone (recommended)**
- Keep files in `A:\Media\Literature\` for seeding
- Import COPIES into Calibre library (uses extra disk space)
- Pro: No risk to torrents
- Con: Files exist in two places

**Option B: Move torrents to Downloads**
- Requires pausing, moving, and relocating each torrent
- High risk of breaking seeding
- Only do this if you're comfortable with qBittorrent's "Set location" feature

**If choosing Option B:**
1. Pause all book torrents
2. For each torrent:
   - Move files from `A:\Media\Literature\[Author]\[Book]` to `A:\Downloads\Books\[Author] - [Book]\`
   - Right-click torrent → "Set location" → Browse to new path
   - Right-click → "Force recheck"
3. Resume when all rechecks complete

**I recommend Option A for safety.** Continue to Step 5.

---

## Step 5: Create New Calibre Library (10 minutes)

1. **Open Calibre desktop application**

2. **Create new library:**
   - Click "Calibre Library" button (top-right corner)
   - Choose "Switch/create library"
   - Select "Create an empty library at the specified location"
   - Location: `A:\Media\Calibre`
   - Click "OK"

3. **Configure import settings:**
   - Preferences → Adding books
   - Under "Adding actions":
     - ☑ "Copy books to library folder" (CHECK THIS!)
     - ☐ "Delete source files after adding" (UNCHECK THIS!)
   - Click "Apply" → "OK"

---

## Step 6: Test Import (10 minutes)

**Before batch importing, test with ONE book:**

1. Choose a single, non-critical book from your collection
2. In Calibre: Click "Add books" button
3. Browse to the book file (in Downloads or Literature.backup)
4. Select it and click "Open"
5. Calibre imports and organizes it

**Verify:**
- [ ] Book appears in Calibre with correct title/author
- [ ] Book file exists in `A:\Media\Calibre\[Author]\[Book]\`
- [ ] Original file still exists in its original location
- [ ] If seeding from that file: Torrent still shows "Seeding" in qBittorrent

**If test fails:** Stop and troubleshoot before batch import!

---

## Step 7: Batch Import (2-4 hours)

**Now import your entire library:**

1. **In Calibre:** Click "Add books" button

2. **Choose source:**
   - If books in `A:\Downloads\Books\`: Select that folder
   - If books in `A:\Media\Literature\`: Use `A:\Media\Literature.backup\` (safer)

3. **Import settings:**
   - ☑ Check "Add books from subdirectories"
   - Click "OK"

4. **Wait for import:**
   - Calibre shows progress bar
   - May take 2-4 hours depending on collection size
   - Don't close Calibre during this process

5. **Review import results:**
   - Calibre shows import log
   - Note any errors or skipped files
   - Check duplicate detection results

---

## Step 8: Metadata Enhancement (1-2 hours)

**Make your library beautiful:**

1. **Auto-download metadata:**
   - Select all books (Ctrl+A)
   - Right-click → "Edit metadata" → "Download metadata"
   - Calibre fetches covers, descriptions, series info
   - Review and accept suggestions

2. **Fix series organization:**
   - Look for books you know are in series
   - Right-click → "Edit metadata" → "Series" tab
   - Enter series name and book number

3. **Remove duplicate formats (optional):**
   - Find books with multiple formats
   - Decide which to keep (EPUB is most universal)
   - Right-click → "Remove books" → Choose formats to remove

---

## Step 9: Verify Torrents Still Seeding (CRITICAL - 15 minutes)

**DO NOT SKIP THIS STEP!**

1. **Open qBittorrent Web UI**

2. **Check all book torrents:**
   - State should be "Seeding" (not "Missing files" or "Error")
   - Upload stats should continue increasing
   - No red/orange icons

3. **If any show "Missing files":**
   - Right-click → "Set location"
   - Browse to correct path (likely still in original location)
   - Right-click → "Force recheck"
   - Wait for recheck, should resume seeding

4. **Monitor for 24 hours:**
   - Check qBittorrent tomorrow
   - Verify uploads continuing
   - If any issues, check file locations

---

## Step 10: Celebrate & Document (15 minutes)

**You did it!** 🎉

Now document what you did:

1. Open `docs/Ebook_Library_Migration_Plan.md`
2. Scroll to "Notes & Lessons Learned" section
3. Add notes about:
   - Which path you followed (Easy or Careful)
   - Any issues encountered
   - How you resolved them
   - Total time taken
   - What you'd do differently next time

---

## Post-Migration Checklist

Within the next week:

- [ ] All torrents still seeding after 7 days
- [ ] Calibre library browsable and searchable
- [ ] All expected books present in Calibre
- [ ] Metadata looks good (covers, descriptions)
- [ ] Series organized correctly

**Once verified for 2 weeks:**
- [ ] Consider installing Calibre-Web
- [ ] Research Readarr for automation
- [ ] Set up backup schedule for Calibre library

---

## If Something Goes Wrong

**STOP. DO NOT PANIC. DO NOT DELETE ANYTHING.**

1. **Your backup is safe at:** `A:\Media\Literature.backup\`

2. **To restore:**
   ```powershell
   # This copies backup back to original location
   Copy-Item "A:\Media\Literature.backup\*" "A:\Media\Literature\" -Recurse -Force
   ```

3. **Fix torrents:**
   - Open qBittorrent
   - Right-click each book torrent → "Set location" → Point to `A:\Media\Literature\`
   - Right-click → "Force recheck"
   - Wait for rechecks to complete

4. **Ask for help:**
   - Document what went wrong
   - What step you were on
   - What error messages you saw

---

## Time Budget

- Documentation & backup: 1-2 hours
- Calibre setup: 30 minutes
- Import: 2-4 hours
- Metadata enhancement: 1-2 hours
- Verification: 30 minutes

**Total: 5-9 hours** (can be spread across multiple days)

---

## Success Criteria

You're done when:

- ✓ All books in Calibre with good metadata
- ✓ All torrents still seeding
- ✓ No "missing files" errors in qBittorrent
- ✓ Backup safely stored
- ✓ You understand where everything is

---

## Next Steps After This Migration

1. **Install Calibre-Web** for web-based access
2. **Research Readarr** for automated ebook downloads
3. **Set up backup automation** for Calibre library
4. **Integrate with Prowlarr** (MyAnonamouse already configured)

---

**Questions or stuck?** Refer back to the detailed plan: `Ebook_Library_Migration_Plan.md`

**Good luck!** 📚
