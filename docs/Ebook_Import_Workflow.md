# Ebook Import Workflow - Manual & Automated

**Current Setup:**
- Calibre Library: `A:\Media\Calibre`
- Downloads: `A:\Downloads\Books`
- Calibre-Web: http://localhost:8083

---

## Current Workflow (Manual - For Now)

### Step-by-Step: Adding Books via Torrent

#### 1. Download the Book Torrent

**In qBittorrent:**
- Add torrent (magnet link or .torrent file)
- **Important:** Make sure it's assigned to the `books` category
  - This automatically saves to `A:\Downloads\Books\` (if Auto TMM is enabled)
- Let it download and seed

**Result:** Book file lands in `A:\Downloads\Books\[torrent-folder]\`

---

#### 2. Import into Calibre Desktop

**Option A: Manual Import (Recommended for now)**

1. **Close Calibre-Web** (IMPORTANT! Calibre desktop and Calibre-Web can't run simultaneously)
   - Close the terminal window running Calibre-Web

2. **Open Calibre Desktop Application**

3. **Add Books:**
   - Click "Add books" button (top-left, green plus icon)
   - Browse to `A:\Downloads\Books\[torrent-folder]\`
   - Select the ebook file(s)
   - Click "Open"

4. **Calibre processes the book:**
   - Copies file to `A:\Media\Calibre\[Author]\[Book]\`
   - **Leaves original in Downloads** (for seeding!)
   - Fetches metadata automatically
   - Adds to database

5. **Close Calibre Desktop**

6. **Restart Calibre-Web**
   - Run `Start-CalibreWeb.bat`
   - Book immediately appears in Calibre-Web

**Option B: Drag and Drop**
- Open Calibre desktop
- Drag ebook file from Downloads folder directly into Calibre window
- Same result as Option A

---

**Option C: Calibre "Add from Directory" (Batch Import)**

If you have multiple books downloaded:

1. Close Calibre-Web
2. Open Calibre Desktop
3. Click "Add books" → Choose directory
4. Navigate to `A:\Downloads\Books\`
5. Check "Add books from subdirectories"
6. Click "Select Folder"
7. Calibre imports all ebooks found

---

### What Happens During Import

**Calibre:**
1. **Copies** file from `A:\Downloads\Books\` → `A:\Media\Calibre\[Author]\[Title]\`
2. **Does NOT delete** original (good for seeding!)
3. **Renames** to Calibre's naming scheme
4. **Fetches metadata** (cover, description, series info)
5. **Updates database** (`metadata.db`)

**Your Downloads folder:**
- Original file **stays there** for seeding
- qBittorrent keeps seeding from `A:\Downloads\Books\`
- No impact on your ratios

---

## Calibre Folder Monitoring (Auto-Import)

**Can Calibre monitor a folder? YES!** But with caveats...

### How Calibre Auto-Add Works

**Setup:**
1. Open Calibre Desktop
2. Preferences → Adding books → "Automatic Adding"
3. Set "Auto-add path" to: `A:\Downloads\Books\`
4. Configure options:
   - "Delete after adding": **NO** (keep for seeding!)
   - "Check for duplicates": Yes
   - "Process subdirectories": Yes

**How it works:**
- Calibre watches the folder while it's running
- When new ebook appears, auto-imports it
- Processes just like manual import

### The Problem with Auto-Add

**⚠️ Big Issue:** Calibre Desktop must be **always running** for auto-add to work.

**Conflicts:**
- Calibre Desktop and Calibre-Web **cannot run simultaneously**
- They both access the same `metadata.db` database
- Running both = database corruption risk

**Verdict:** Auto-add with Calibre Desktop is **not practical** for your use case.

---

## Calibre-Web Auto-Refresh

**Does Calibre-Web update automatically when books are added? YES!**

### How Calibre-Web Refresh Works

**When you add books via Calibre Desktop:**
1. Close Calibre-Web
2. Add books in Calibre Desktop
3. Close Calibre Desktop
4. Restart Calibre-Web
5. **Books appear immediately** in Calibre-Web

**Calibre-Web reads the database:**
- No manual "refresh" needed in the UI
- Database is re-read on startup
- Changes from Calibre Desktop are automatically visible

**Can you keep Calibre-Web running?**
- Not while Calibre Desktop is open (conflict!)
- Must close one to use the other

---

## Recommended Manual Workflow

**For now, while adding books manually:**

### Quick Process

1. **Download torrents** → Books land in `A:\Downloads\Books\`
2. **Batch collect** - let several books download over a few days
3. **Once a week:**
   - Stop Calibre-Web (`Ctrl+C` in terminal)
   - Open Calibre Desktop
   - Import all new books from `A:\Downloads\Books\`
   - Download metadata for new books
   - Close Calibre Desktop
   - Restart Calibre-Web
4. **Read via Calibre-Web** the rest of the week

**Why this works:**
- Minimal switching between Calibre Desktop and Calibre-Web
- Books still seed from Downloads folder
- Clean separation of duties

---

## Future Automated Workflow (with Readarr)

This is where things get **really good**!

### The Dream Setup

```
Prowlarr (indexers) → Readarr (automation) → qBittorrent (download)
                          ↓
                   Calibre (import)
                          ↓
                   Calibre-Web (read)
```

### How Readarr Changes Everything

**Readarr is like Sonarr, but for books:**
- You add an author or book you want
- Readarr searches Prowlarr indexers (MyAnonamouse!)
- Finds best release
- Sends to qBittorrent (`books` category)
- **Automatically imports to Calibre** when download completes
- Book appears in Calibre-Web

### Readarr Integration with Calibre

**Two Methods:**

#### Method 1: Readarr → Calibre Direct Import
- Readarr connects to Calibre Content Server
- Imports books directly after download
- **Requires:** Calibre Content Server running (not Calibre-Web)

#### Method 2: Readarr → Folder → Calibre Auto-Import
- Readarr moves completed books to a folder
- Calibre watches that folder (auto-add)
- **Still has the "Calibre must be running" problem**

### The Best Automated Solution

**Use Readarr with Calibre-Web import plugin:**

There's a **Calibre-Web import** feature that can:
- Watch a folder for new books
- Import them while Calibre-Web is running
- No need for Calibre Desktop to be open

**Setup:**
1. Enable "Upload" feature in Calibre-Web
2. Readarr moves completed books to import folder
3. Calibre-Web imports automatically
4. Books appear in library

---

## Readarr Setup Overview (Future)

When you're ready for automation, here's the plan:

### Phase 1: Install Readarr
- Download from readarr.com
- Similar to Sonarr installation
- Windows service or Docker

### Phase 2: Connect to Services
- **Prowlarr:** Add Readarr as an app (like you did with Sonarr)
- **qBittorrent:** Add as download client
- **Calibre:** Choose integration method

### Phase 3: Configure
- Set up root folder for ebooks
- Configure quality profiles (EPUB preferred, MOBI acceptable, etc.)
- Set up metadata settings

### Phase 4: Start Adding Books
- Add authors you want to follow
- Add specific books you want
- Readarr monitors and grabs them automatically

---

## Comparison: Manual vs Automated

| Aspect | Manual (Now) | Automated (Readarr) |
|--------|-------------|---------------------|
| **Effort** | You search and download | Readarr searches for you |
| **Torrents** | You add manually to qBittorrent | Readarr adds automatically |
| **Import** | You import to Calibre | Automatic import |
| **New Books** | You must remember to check | Readarr monitors for new releases |
| **Series** | You track manually | Readarr tracks series automatically |
| **Quality** | You choose | Readarr finds best quality |
| **Time** | 5-10 min per book | Zero time - fully automatic |

---

## My Recommendation

### For Now (Manual Phase)

**Workflow:**
1. Download books via qBittorrent to `A:\Downloads\Books\`
2. Once or twice a week:
   - Close Calibre-Web
   - Open Calibre Desktop
   - Import new books
   - Close Calibre Desktop
   - Restart Calibre-Web
3. Read via Calibre-Web during the week

**Why this works:**
- Simple and safe
- No conflicts
- Books still seed properly
- You maintain control

---

### Soon (Automated Phase)

**When to set up Readarr:**
- After you're comfortable with the manual workflow
- When you want to start following authors automatically
- When you're adding 5+ books per week

**Benefits of waiting:**
- Learn how Calibre works first
- Understand your preferences
- Set up quality profiles properly
- Avoid complexity while learning

**Timeline suggestion:**
- Manual workflow: 1-2 weeks
- Install Readarr: After you're comfortable
- Full automation: Takes 1-2 hours to set up

---

## Quick Reference Commands

### Manual Import Process

```powershell
# Stop Calibre-Web
# (Ctrl+C in the terminal window)

# Open Calibre Desktop
# Import books from A:\Downloads\Books

# After import, restart Calibre-Web
.\Start-CalibreWeb.bat
```

### Check Download Location

```powershell
# See what's in your downloads folder
Get-ChildItem A:\Downloads\Books -Recurse -File | Where-Object { $_.Extension -match '\.(epub|mobi|azw3|pdf)$' }
```

---

## Troubleshooting

### "Database is locked" error
- **Cause:** Calibre Desktop and Calibre-Web both open
- **Solution:** Close one of them, only run one at a time

### Books not appearing in Calibre-Web
- **Cause:** Database not refreshed
- **Solution:** Restart Calibre-Web (close and reopen)

### Original files deleted from Downloads
- **Cause:** "Delete after adding" enabled in Calibre
- **Solution:** Preferences → Adding books → Uncheck "Delete source files"

### Can't seed torrents after import
- **Cause:** Files moved instead of copied
- **Solution:** Check qBittorrent, files should still be in `A:\Downloads\Books\`

---

## Next Steps

1. **Try the manual workflow** with a few books
2. **Get comfortable** with Calibre Desktop import process
3. **Use Calibre-Web** for daily reading
4. **When ready:** Set up Readarr for automation

---

**Want to set up Readarr now?** Let me know and I can guide you through it!

**Last Updated:** 2025-10-28
**Status:** Manual workflow documented, ready for use
