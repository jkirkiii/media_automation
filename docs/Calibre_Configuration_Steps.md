# Calibre Configuration - Step-by-Step Guide

**Status:** Ready to configure
**New Library Location:** `A:\Media\Calibre`
**Backup Location:** `A:\Media\Literature.backup`

---

## Step 2: Configure Calibre to Use New Library

### Open Calibre and Switch Library

1. **Launch Calibre** desktop application

2. **Switch to new library:**
   - Look for the **"Calibre Library"** button in the top-right corner of the toolbar
   - Click it → Select **"Switch/create library"**
   - In the dialog, choose **"Create a new, empty library at a specified location"**
   - Click **"..."** to browse
   - Navigate to: `A:\Media\Calibre`
   - Click **"Select Folder"**
   - Click **"OK"**

3. **Calibre will restart** and show an empty library

**✓ Checkpoint:** You should see an empty Calibre window with "0 books" in the status bar

---

## Step 3: Configure Import Preferences

### Critical Settings to Prevent Data Loss

1. **Open Preferences:**
   - Click **"Preferences"** button (or press `Ctrl+P`)
   - Or: Menu → Preferences → Preferences

2. **Navigate to "Adding books":**
   - In the left sidebar under **"Adding books"**
   - Click on **"Adding books"**

3. **Configure these settings:**

   **Under "Automatic processing":**
   - ☑ **Check:** "Copy books to library folder when adding"
   - ☐ **UNCHECK:** "Delete source files after adding to library" (CRITICAL!)

   **Why this matters:**
   - "Copy books" ensures Calibre creates its own organized copy
   - "Don't delete" means your backup stays safe
   - Your original `A:\Media\Literature\` files (for seeding) remain untouched

4. **File format handling:**
   - Under "Saving to disk" section
   - ☑ Check: "Save metadata in separate OPF file"
   - This keeps metadata separate from ebook files

5. **Click "Apply"** then **"OK"**

**✓ Checkpoint:** Settings saved, ready to import

---

## Step 4: Configure Metadata Sources (Recommended)

This makes Calibre automatically fetch book covers, descriptions, and series info.

1. **Open Preferences** (`Ctrl+P`)

2. **Navigate to "Sharing" → "Metadata download"**

3. **Enable these sources** (check the boxes):
   - ☑ Google
   - ☑ Amazon.com
   - ☑ Open Library
   - ☑ Goodreads (if available)
   - ☑ Big Book Search

4. **Configure download settings:**
   - Under "Configure download metadata"
   - ☑ Check: "Download cover thumbnails"
   - ☑ Check: "Download series information"

5. **Click "Apply"** → **"OK"**

**✓ Checkpoint:** Metadata sources configured

---

## Step 5: Test Import with Single Book

**IMPORTANT:** Test with one book before batch importing!

### Choose a Test Book

Pick a non-critical book from your collection. Good choices:
- A standalone novel (not part of a series you care about)
- Something you already have metadata for
- Preferably an EPUB (most compatible)

### Import the Test Book

1. **In Calibre:** Click the **"Add books"** button (top-left, green plus icon)

2. **Browse to your backup:**
   - Navigate to `A:\Media\Literature.backup\`
   - Find a single book file (e.g., `Bradbury, Ray\Dandelion Wine - Ray Bradbury (1957).azw3`)
   - Select it
   - Click **"Open"**

3. **Watch the import process:**
   - Calibre shows a job in the bottom-right corner
   - Wait for "Job completed" message

4. **Verify the import:**
   - The book should appear in your library
   - Click on it to see details
   - Check if cover, title, author are correct

### Verification Checklist

After import, verify these things:

- [ ] Book appears in Calibre library
- [ ] Title and author are correct (or can be edited)
- [ ] Cover image present (or can be downloaded)
- [ ] File exists in `A:\Media\Calibre\[Author]\[Title]\` directory
- [ ] Original file still exists in `A:\Media\Literature.backup\[location]`
- [ ] **CRITICAL:** Original file still exists in `A:\Media\Literature\` (seeding location!)

### Check the Seeding File

1. Open Windows Explorer
2. Navigate to where that book is in `A:\Media\Literature\`
3. Verify the file is still there and unchanged
4. Open qBittorrent and check if the torrent is still "Seeding" (not "Missing files")

**If test fails:** Stop and troubleshoot before batch import!

**If test passes:** Proceed to Step 6!

---

## Step 6: Batch Import All Books

Now that you've tested, import everything!

### Import from Backup Directory

1. **In Calibre:** Click **"Add books"** button

2. **Select entire backup folder:**
   - Navigate to `A:\Media\Literature.backup\`
   - **Don't select individual files!** Instead:
   - At the bottom of the file dialog, click the **"Choose a directory"** button
   - Or select the `Literature.backup` folder itself
   - Click **"Select Folder"**

3. **Configure import options:**
   - A dialog appears: "Add books from directory"
   - ☑ **Check:** "Add books from subdirectories"
   - ☑ **Check:** "Ignore duplicate books" (if any)
   - Click **"OK"**

4. **Wait for import:**
   - This will take 30-60 minutes for 113 files
   - Watch the job progress in bottom-right corner
   - Calibre shows: "Added book X of Y"
   - **Do not close Calibre during this process!**

5. **Review import log:**
   - When complete, click "Jobs" in bottom-right
   - Review any errors or warnings
   - Note: Some warnings are normal (e.g., "Could not find metadata")

### What Calibre Does During Import

- **Detects book metadata** from filename and embedded info
- **Organizes into standard structure:** `Author/Book Title (ID)/filename.ext`
- **Consolidates formats:** If you have EPUB + MOBI of same book, Calibre groups them
- **Creates thumbnails** for covers
- **Generates internal database** for searching

---

## Step 7: Review Import Results

### Check Statistics

1. **Look at status bar** (bottom-left):
   - Should show ~100+ books (might be less if duplicates were merged)
   - Expected: 90-110 books (depending on duplicates)

2. **Check for import errors:**
   - Click "Jobs" (bottom-right)
   - Look for any red error messages
   - Common issues:
     - Corrupt files (skip these for now)
     - Duplicate detections (Calibre handles automatically)

### Spot Check Books

Browse your library and spot-check a few books:

1. **Authors appear correctly?**
   - Look at the "Authors" list on the left sidebar
   - Should see: Bradbury, Ray; Butler, Octavia E; etc.

2. **Series detected?**
   - Click "Series" in left sidebar
   - Series books should be grouped (e.g., "Parable Series")

3. **Covers present?**
   - Most books should have cover images
   - Some might have generic covers (can fix later)

---

## Step 8: Enhance Metadata (Optional but Recommended)

Make your library beautiful with proper metadata.

### Auto-Download Metadata for All Books

1. **Select all books:**
   - Click in the book list
   - Press `Ctrl+A` (selects all)

2. **Download metadata:**
   - Right-click → **"Edit metadata"** → **"Download metadata and covers"**
   - Or: Press `Ctrl+D`

3. **Configure download:**
   - In the dialog, ensure all sources are checked
   - Click **"OK"**

4. **Review suggestions:**
   - Calibre shows matches for each book
   - Click through and accept/reject suggestions
   - This takes 15-30 minutes for 100+ books
   - **Tip:** You can click "Apply to all" if confident

### What Gets Updated

- **Covers:** Professional book covers replace generic ones
- **Descriptions:** Full book summaries added
- **Series info:** Series name and number detected
- **Tags/Genres:** Fiction, Fantasy, Mystery, etc.
- **Publication dates:** Original and edition dates
- **ISBNs:** International book numbers

---

## Step 9: Verify Torrents Still Seeding (CRITICAL!)

**DO NOT SKIP THIS STEP!**

### Check qBittorrent

1. **Open qBittorrent Web UI:** http://localhost:8080

2. **Filter for book torrents:**
   - Look at the "books" category
   - Or search for torrents with "Literature" in the path

3. **Verify each torrent:**
   - State should be **"Seeding"** (green checkmark)
   - NOT "Missing files" or "Error"
   - NOT "Paused" (unless you paused it)

4. **Check a few file locations:**
   - Right-click a torrent → "Open destination folder"
   - Should open to `A:\Media\Literature\[Author]\[Book]\`
   - Files should be present and unchanged

### If Any Torrents Show "Missing Files"

**Don't panic!** This is fixable:

1. Right-click the torrent → **"Set location"**
2. Browse to `A:\Media\Literature\[appropriate folder]`
3. Click **"OK"**
4. Right-click → **"Force recheck"**
5. Wait for recheck to complete
6. Should resume seeding

### Monitor for 24 Hours

- Check qBittorrent tomorrow
- Verify torrents are still seeding
- Check that upload stats are increasing
- If stable for 24h, migration is successful!

---

## Step 10: Cleanup (Do NOT Do Yet!)

**Wait at least 2 weeks before cleanup!**

Only after verifying:
- [ ] Calibre library is complete and usable
- [ ] All torrents seeding for 2+ weeks without issues
- [ ] You're happy with the organization
- [ ] Backup is still safe at `A:\Media\Literature.backup`

**Then** you can consider:
1. Archiving or removing old `A:\Media\Literature\` structure
2. Keep backup for 30+ days as safety net

---

## Troubleshooting

### "Calibre won't import some books"

- **Cause:** Corrupt files or unsupported formats
- **Solution:** Note which files failed, try re-downloading or use Calibre's "Convert books" to fix

### "Metadata download fails"

- **Cause:** Network issues or rate limiting
- **Solution:** Try again later, or manually edit metadata

### "Duplicate books detected"

- **Cause:** Same book in different formats or folders
- **Solution:** Calibre automatically merges formats - this is good!

### "Series not detected"

- **Cause:** Filenames don't have series info, or metadata sources don't know the series
- **Solution:** Manually edit metadata → Series tab → Enter series name and number

### "Torrent shows 'Missing files'"

- **Cause:** qBittorrent lost track of file location
- **Solution:** Set location → Force recheck (see Step 9 above)

---

## Success Criteria

Migration is complete when:

- ✓ All books imported into Calibre
- ✓ Metadata looks good (covers, descriptions)
- ✓ Series organized properly
- ✓ All torrents still seeding
- ✓ No "missing files" errors in qBittorrent
- ✓ Calibre library searchable and browsable

---

## Next Steps After Migration

Once everything is stable:

1. **Install Calibre-Web** for web-based access
2. **Research Readarr** for automated ebook downloads
3. **Set up automated Calibre backups**
4. **Connect Readarr to Prowlarr** (MyAnonamouse indexer)
5. **Create download workflow:** Readarr → qBittorrent → Calibre

---

**Good luck with your migration!** 📚

Take your time, test thoroughly, and don't hesitate to stop if something doesn't look right.
