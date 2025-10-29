# Calibre Import Analysis & Cleanup Recommendations

**Date:** 2025-10-28
**Status:** Import Complete - Needs Cleanup

---

## Import Summary

### Statistics
- **Backup files:** 83 ebook files
- **Calibre files:** 84 ebook files
- **Books with metadata:** 70 books
- **Books with covers:** 68 books
- **Not imported:** 56 files
- **Duplicates detected:** 2 books

---

## Key Findings

### 1. Most Books Were NOT Imported as Separate Entries

**What happened:** Calibre detected that many of your books with multiple formats (EPUB, MOBI, AZW3) are the same book, and **consolidated them**. This is GOOD and expected behavior!

**Example:**
```
Backup had:
  - Pride and Prejudice.epub
  - Pride and Prejudice.azw3
  - Pride and Prejudice.mobi

Calibre imported as:
  - One "Pride and Prejudice" entry with 3 formats
```

The 56 "not imported" files are mostly:
- **Alternative formats of books already imported** (e.g., MOBI when EPUB already exists)
- **Books that Calibre merged into single entries**

This is **correct behavior** and makes your library cleaner!

---

### 2. True Duplicates Found

Calibre found **2 actual duplicate books** (same book imported twice):

#### Duplicate 1: "The Foundation of Smoke and Steel" by JC Anderson
- **Entry 1:** ID 1 - `The Foundation of Smoke and Steel_ V`
- **Entry 2:** ID 63 - `The Foundation of Smoke and Steel_ V`

**Cause:** You had this book in your backup, and Calibre imported it twice (possibly from different folders or metadata confusion)

**Action:** Delete one copy (keep the one with better metadata)

#### Duplicate 2: "Mate" by Ali Hazelwood
- **Entry 1:** ID 43 - `Mate_ From the bestselling author of`
- **Entry 2:** ID 66 - `Mate_ From the bestselling author of`

**Cause:** Your backup had TWO files for this same book:
  - `Mate - Bride 02 - Ali Hazelwood (2025).epub`
  - `Mate by Ali Hazelwood.epub`

**Action:** Delete one copy (they're the same book)

---

### 3. Author Name Inconsistencies

Calibre created some duplicate author entries due to naming variations:

| Issue | Books | Reason |
|-------|-------|--------|
| `Anderson , JC` (with comma+space) | 2 | Imported with comma formatting |
| `Christina Lauren` vs `Lauren, Christina` | 14 vs 2 | Mixed "Firstname Lastname" and "Lastname, Firstname" |
| `Maas, Sarah J_` vs `Sarah J. Maas` | 1 vs 2 | Period vs underscore |
| `Fatima Bhutto (2025)` | 1 | Year got into author name |
| `Julie McDonald (1985)` | 1 | Year got into author name |
| `McElroy, Roxanne` vs source `McElroy, Dierdra A` | 1 | Wrong first name? |

**Impact:** Makes it harder to browse by author since the same author appears multiple times

---

## Detailed Issues Breakdown

### Books Actually Missing from Import

Let me check the report to see if any books truly didn't make it into Calibre at all...

Looking at the "not imported" list, most appear to be **format variations** that Calibre consolidated. However, let me identify books that should have been imported as unique entries:

**Potentially Missing Unique Books:**
1. Anderson, JC - "The Foundation of Smoke and Steel" ✓ (imported but duplicated)
2. Asimov, Isaac - "Robots and Empire - Robot 04" (might be missing?)
3. Badurina, David - "SPACE PEW PEW" ✓ (imported)
4. Bailey, Lona - "Wicked Witch of the West" ✓ (imported)
5. Bhutto, Fatima - "Gaza The Story of a Genocide" ✓ (imported - author name has "(2025)" issue)

**Verdict:** Most books ARE in Calibre, but some have weird metadata making them hard to find.

---

## Cleanup Recommendations

### Priority 1: Fix Duplicate Books (IMMEDIATE)

**In Calibre:**

1. **Find duplicate "The Foundation of Smoke and Steel":**
   - Search: `Anderson`
   - Look for two entries with same title
   - Compare metadata and covers
   - Delete the entry with worse metadata/missing cover
   - Right-click → "Remove books" → Check "Delete permanently"

2. **Find duplicate "Mate":**
   - Search: `Hazelwood`
   - Look for two "Mate" entries
   - Keep the one that says "Bride 02" (series information)
   - Delete the generic "Mate by Ali Hazelwood"

---

### Priority 2: Fix Author Name Issues (HIGH)

#### Fix 1: Merge "Lauren, Christina" entries

**In Calibre:**
1. Search for `Christina Lauren`
2. Select all books by this author (should be 16 total - 14 + 2)
3. Click "Edit metadata" button → "Edit metadata individually"
4. For all books, set Author to: `Christina Lauren` (consistent format)
5. Click "OK"
6. Calibre will merge the author entries automatically

#### Fix 2: Fix author names with years

**Books to fix:**
- "Gaza The Story of a Genocide" - Author shows as `Fatima Bhutto (2025)`
- "Scandinavian Proverbs" - Author shows as `Julie McDonald (1985)`

**Steps:**
1. Find these books (search by title)
2. Edit metadata → Author tab
3. Change to: `Fatima Bhutto` and `Julie McDonald`
4. Move year to "Publication date" field if needed

#### Fix 3: Standardize "Maas, Sarah J"

**Choose one format** (recommend: `Sarah J. Maas`)
1. Search for `Maas`
2. Select all books by this author
3. Edit metadata → Set author to: `Sarah J. Maas` (consistent)

#### Fix 4: Fix "McElroy" first name issue

1. Search for `McElroy`
2. Check if this is Dierdra or Roxanne
3. Correct the author name based on the book ("That Perfect Stitch")

---

### Priority 3: Check for Missing Books (MEDIUM)

Some books from your backup might not have imported correctly. Let's verify:

**Books to manually check in Calibre:**

1. **Isaac Asimov - "Robots and Empire"**
   - Search: `Asimov Robots`
   - If missing: Manually add from backup

2. **Octavia Butler - "Fledgling"**
   - Search: `Butler Fledgling`
   - Verify it's there

3. **Parable Series (both books)**
   - Search: `Butler Parable`
   - Should show 2 books: "Parable of the Sower" and "Parable of the Talents"

4. **Check all your key authors:**
   - Bradbury (should have 2 books)
   - Steinbeck (should have 1-2 books)
   - McFadden (should have 2 books)

---

### Priority 4: Enhance Metadata (LOW - Optional)

**For books with weird titles:**

Many books have truncated or odd titles in Calibre. This happens when Calibre can't find good metadata.

**Fix individually:**
1. Select book with odd title
2. Click "Edit metadata" → "Download metadata"
3. Calibre searches online sources
4. Review suggestions and accept the best match
5. Repeat for books with:
   - Truncated titles (ending in "...")
   - Missing authors
   - No cover image
   - Generic/wrong metadata

**Or batch fix:**
1. Select multiple books with issues
2. Right-click → "Edit metadata" → "Download metadata and covers"
3. Review each suggestion

---

## Step-by-Step Cleanup Process

### Step 1: Remove Duplicates (10 minutes)

```
1. Open Calibre
2. Search: "Foundation of Smoke"
   → Delete duplicate entry (keep one)
3. Search: "Mate Hazelwood"
   → Delete duplicate entry (keep the "Bride 02" version)
4. Verify: Library should now have 68-69 unique books
```

### Step 2: Fix Author Names (15 minutes)

```
1. Christina Lauren:
   - Select all 16 books → Edit → Set author to "Christina Lauren"
2. Fatima Bhutto:
   - Find book → Edit → Remove "(2025)" from author
3. Julie McDonald:
   - Find book → Edit → Remove "(1985)" from author
4. Sarah J. Maas:
   - Select all books → Edit → Standardize to "Sarah J. Maas"
5. McElroy:
   - Find book → Edit → Check correct first name
```

### Step 3: Verify Key Books Present (10 minutes)

```
Search for and verify these authors have expected books:
- Octavia Butler: 4-5 unique books (Parable x2, Fledgling, etc.)
- Christina Lauren: ~8 unique books in "Beautiful" series
- John Steinbeck: 1-2 books
- Ray Bradbury: 2 books
- Isaac Asimov: At least 1 book
```

If any are missing:
1. Go to `A:\Media\Literature.backup\[Author]\[Book]`
2. In Calibre: "Add books" → Select the missing book
3. Import manually

### Step 4: Download Missing Metadata (20-30 minutes)

```
1. Look for books with:
   - No cover image (generic book icon)
   - Weird/truncated titles
   - Missing descriptions
2. Select these books (Ctrl+Click to multi-select)
3. Right-click → "Download metadata and covers"
4. Review suggestions, accept best matches
```

---

## Verification Commands

After cleanup, verify the state:

### Check Final Count

**In Calibre status bar (bottom):**
- Should show approximately **68-70 unique books**
- (Down from 84 after removing duplicates)

### Check Authors Are Clean

**In Calibre left sidebar → Authors:**
- Each author should appear ONCE
- No duplicate entries like "Christina Lauren" and "Lauren, Christina"
- No years in parentheses

### Check Series Detection

**In Calibre left sidebar → Series:**
- Should see series like:
  - Beautiful (Christina Lauren) - ~7 books
  - Parable Series (Octavia Butler) - 2 books
  - Throne of Glass (Sarah J. Maas) - 2-3 books

---

## Expected Final State

After cleanup, you should have:

- **~68-70 unique books** (some books have multiple formats counted as one book)
- **~45-48 unique authors** (no duplicates)
- **All major series detected** and organized
- **Most books with covers** (90%+)
- **Clean author names** (no years, consistent formatting)
- **No duplicate books**

---

## Re-run Comparison

After you finish cleanup, run the comparison script again to verify:

```powershell
.\scripts\Compare-Calibre-Import.ps1
```

Should show:
- Duplicates: 0
- Better author organization
- Cleaner library structure

---

## Next Steps After Cleanup

1. **Verify torrents still seeding** (do this NOW before cleanup)
2. **Complete metadata for favorite books** (add tags, ratings, series info)
3. **Install Calibre-Web** for web interface
4. **Set up Readarr** for automation
5. **Create Calibre backup routine**

---

## Notes

- The "not imported" files are mostly **expected** - Calibre consolidated formats
- The duplicates are **real issues** - need to be deleted
- The author name issues are **cosmetic** but worth fixing for browsability
- Overall the import was **successful** - just needs cleanup

**Don't delete anything from `A:\Media\Literature\` or `A:\Media\Literature.backup\` yet!**

---

**Last Updated:** 2025-10-28
**Status:** Analysis complete, ready for cleanup
