# Calibre Tag Management System

**Purpose:** Standardized tag taxonomy and automated tools for managing ~1,700 ebook library

**Created:** 2025-12-06
**Status:** Ready for initial audit and migration

---

## Overview

This system provides:
1. **Standardized tag taxonomy** based on BISAC industry standards
2. **Audit tools** to analyze your existing tags
3. **Migration tools** to clean up and standardize tags
4. **Ongoing maintenance** for new imports

---

## Quick Start

### Step 1: Audit Your Current Tags

Run the audit script to see what you're working with:

```powershell
.\scripts\Audit-Calibre-Tags.ps1
```

**What it does:**
- Analyzes all 1,700+ books
- Generates reports on tag usage, duplicates, and problems
- Creates CSV files in `.\data\calibre_tag_audit\`

**Review these files:**
- `summary.txt` - Overview statistics
- `tag_frequency.csv` - Which tags are most used
- `potential_duplicate_tags.csv` - Tags that should probably be merged
- `books_without_tags.csv` - Books needing tags
- `books_with_many_tags.csv` - Over-tagged books (>5 tags)

### Step 2: Create Your Tag Mapping

Based on audit results, create your mapping file:

```powershell
# Copy the template
Copy-Item .\configs\calibre_tag_mapping.ps1.template .\configs\calibre_tag_mapping.ps1

# Edit the file to add your specific tag mappings
notepad .\configs\calibre_tag_mapping.ps1
```

**Example mappings:**
```powershell
$script:TagMappings = @{
    "Sci-Fi"     = "Fiction.Science Fiction"
    "SciFi"      = "Fiction.Science Fiction"
    "SF"         = "Fiction.Science Fiction"
    "Mysteries"  = "Fiction.Mystery"
    "Biography"  = "Non-Fiction.Biography & Memoir"
    "untagged"   = ""  # Remove this tag
}
```

### Step 3: Test Your Migration (Dry Run)

Test the migration without making changes:

```powershell
.\scripts\Update-Calibre-Tags.ps1 -DryRun
```

This shows you exactly what would change without touching your library.

### Step 4: Run the Migration

When you're confident, run it for real:

```powershell
.\scripts\Update-Calibre-Tags.ps1
```

**Safety features:**
- Automatic backup of `metadata.db` before changes
- Change log saved to `.\data\calibre_tag_updates_[timestamp].csv`
- Can limit scope with `-Filter` parameter

### Step 5: Ongoing Maintenance

After importing new books, run the auto-tagger:

```powershell
# Tag books added in last 7 days
.\scripts\Tag-New-Calibre-Imports.ps1

# Interactive mode - confirm each book
.\scripts\Tag-New-Calibre-Imports.ps1 -Interactive

# Only process last 3 days
.\scripts\Tag-New-Calibre-Imports.ps1 -DaysBack 3
```

---

## Tag Taxonomy

The standardized taxonomy is defined in `configs\calibre_standard_tags.txt`

### Key Principles

**From Industry Research:**
- **3-5 tags maximum** per book (sweet spot)
- **Consistent vocabulary** (never mix "Sci-Fi" and "Science Fiction")
- **Hierarchical structure** using periods (e.g., `Fiction.Science Fiction.Space Opera`)
- **Primary genre first** - most important tag should be first

### Tag Categories

#### Fiction Genres
```
Fiction
Fiction.Science Fiction
Fiction.Science Fiction.Space Opera
Fiction.Science Fiction.Cyberpunk
Fiction.Science Fiction.Time Travel
Fiction.Science Fiction.Dystopian
Fiction.Science Fiction.Hard SF
Fiction.Science Fiction.Military SF

Fiction.Fantasy
Fiction.Fantasy.Epic
Fiction.Fantasy.Urban
Fiction.Fantasy.Dark

Fiction.Mystery
Fiction.Thriller
Fiction.Horror
Fiction.Romance
Fiction.Historical
Fiction.Literary
... (see full list in configs/calibre_standard_tags.txt)
```

#### Non-Fiction Categories
```
Non-Fiction
Non-Fiction.Biography & Memoir
Non-Fiction.History
Non-Fiction.Science & Technology
Non-Fiction.Business & Economics
Non-Fiction.Self-Help & Psychology
Non-Fiction.Politics & Social Sciences
... (see full list in configs/calibre_standard_tags.txt)
```

#### Audience Tags (Optional)
```
Young Adult
Middle Grade
Children's
Adult
```

#### Special Categories
```
Graphic Novel
Poetry
Drama
Short Stories
Anthology
```

---

## Best Practices

### Tagging Philosophy

**DO:**
- ✅ Use 3-5 tags per book
- ✅ Be consistent with vocabulary
- ✅ Use hierarchical tags for subcategories
- ✅ Start with broad genre, add specific subgenres
- ✅ Review and consolidate tags monthly

**DON'T:**
- ❌ Over-tag (>5 tags makes browsing harder)
- ❌ Mix similar tags (Sci-Fi vs Science Fiction)
- ❌ Use format tags (epub, ebook, etc.)
- ❌ Use status tags like "to-read" (use custom columns instead)

### Tag Hierarchy in Calibre

Enable hierarchical tag browsing:
1. Open Calibre Desktop
2. Go to **Preferences → Look & feel → Tag browser**
3. Add tag hierarchy separator: `.` (period)
4. Tags like `Fiction.Science Fiction.Space Opera` will show as nested tree

### Calibre-Web Browsing

With standardized tags, users can:
- Browse by broad genres (Fiction, Non-Fiction)
- Drill down into subgenres (Science Fiction → Space Opera)
- Filter by multiple tags
- Find similar books easily

---

## Scripts Reference

### Audit-Calibre-Tags.ps1

**Purpose:** Analyze existing tag usage

**Parameters:**
- `-LibraryPath` - Path to Calibre library (default: `A:\Media\Calibre`)
- `-OutputPath` - Where to save reports (default: `.\data\calibre_tag_audit`)

**Output:**
- `summary.txt` - Statistics and overview
- `tag_frequency.csv` - Tag usage counts
- `all_unique_tags.txt` - Every unique tag in library
- `potential_duplicate_tags.csv` - Similar tags to merge
- `books_without_tags.csv` - Untagged books
- `books_with_many_tags.csv` - Over-tagged books

**When to run:** Before initial migration, then monthly for maintenance

---

### Update-Calibre-Tags.ps1

**Purpose:** Apply tag mapping rules to standardize library

**Parameters:**
- `-LibraryPath` - Path to Calibre library (default: `A:\Media\Calibre`)
- `-MappingFile` - Tag mapping config (default: `.\configs\calibre_tag_mapping.ps1`)
- `-DryRun` - Test without making changes
- `-NoBackup` - Skip backup (not recommended)
- `-Filter` - Calibredb search expression to limit scope

**Examples:**
```powershell
# Dry run - see what would change
.\scripts\Update-Calibre-Tags.ps1 -DryRun

# Full migration
.\scripts\Update-Calibre-Tags.ps1

# Only update Science Fiction books
.\scripts\Update-Calibre-Tags.ps1 -Filter "tags:Sci-Fi OR tags:SciFi"

# Skip backup (faster, but risky)
.\scripts\Update-Calibre-Tags.ps1 -NoBackup
```

**Safety:**
- Creates backup of `metadata.db` before changes
- Logs all changes to CSV file
- Can be run multiple times safely

**When to run:** After creating mapping file, then as needed for corrections

---

### Tag-New-Calibre-Imports.ps1

**Purpose:** Automatically tag newly imported books

**Parameters:**
- `-LibraryPath` - Path to Calibre library (default: `A:\Media\Calibre`)
- `-MappingFile` - Tag mapping config (default: `.\configs\calibre_tag_mapping.ps1`)
- `-DaysBack` - Process books added in last N days (default: 7)
- `-Interactive` - Confirm each book before tagging
- `-DryRun` - Test without making changes

**How it works:**
1. Finds books added recently (last 7 days)
2. Cleans up malformed existing tags using mappings
3. Suggests tags based on keywords in title/description
4. Suggests tags based on series
5. Applies changes (or prompts in interactive mode)

**Examples:**
```powershell
# Tag books added in last week
.\scripts\Tag-New-Calibre-Imports.ps1

# Interactive mode - confirm each book
.\scripts\Tag-New-Calibre-Imports.ps1 -Interactive

# Only process last 3 days
.\scripts\Tag-New-Calibre-Imports.ps1 -DaysBack 3

# Test what would happen
.\scripts\Tag-New-Calibre-Imports.ps1 -DryRun
```

**When to run:** After importing new books (weekly or after each import batch)

---

## Workflow

### Initial Library Cleanup (One-Time)

```powershell
# 1. Audit current state
.\scripts\Audit-Calibre-Tags.ps1

# 2. Review reports and create mapping
notepad .\data\calibre_tag_audit\summary.txt
notepad .\data\calibre_tag_audit\potential_duplicate_tags.csv
Copy-Item .\configs\calibre_tag_mapping.ps1.template .\configs\calibre_tag_mapping.ps1
notepad .\configs\calibre_tag_mapping.ps1

# 3. Test migration
.\scripts\Update-Calibre-Tags.ps1 -DryRun

# 4. Run migration
.\scripts\Update-Calibre-Tags.ps1

# 5. Verify results in Calibre/Calibre-Web
```

### Ongoing Maintenance (Weekly)

```powershell
# Tag new imports
.\scripts\Tag-New-Calibre-Imports.ps1

# Monthly: re-audit and consolidate
.\scripts\Audit-Calibre-Tags.ps1
# Review for new duplicates/issues
```

---

## Advanced Usage

### Custom Tag Detection Patterns

Edit `configs\calibre_tag_mapping.ps1` to add keyword detection:

```powershell
$script:AutoTagPatterns = @{
    Keywords = @{
        "Fiction.Science Fiction" = @("space", "alien", "robot", "cyberpunk")
        "Fiction.Fantasy"         = @("magic", "wizard", "dragon", "elf")
        "Fiction.Mystery"         = @("detective", "murder", "clue")
    }

    Series = @{
        "The Expanse" = "Fiction.Science Fiction.Space Opera"
        "Harry Potter" = "Fiction.Fantasy"
    }
}
```

### Batch Processing by Genre

Process specific genres separately:

```powershell
# Only update Science Fiction books
.\scripts\Update-Calibre-Tags.ps1 -Filter "tags:Sci-Fi OR tags:SciFi OR tags:SF"

# Only update recent imports
.\scripts\Update-Calibre-Tags.ps1 -Filter "timestamp:>=2025-12-01"
```

### Integration with Calibre Desktop

Open Calibre Desktop and:
1. Use **Tag Browser** to see hierarchical tags
2. Right-click tags to **Merge** duplicates manually
3. Use **Edit Metadata in Bulk** for manual corrections
4. Scripts work alongside manual edits

---

## Troubleshooting

### Common Issue: "Failed to retrieve books from Calibre library"

**Cause:** Calibre-Web is running and has the database locked.

**Quick Fix:**
```powershell
# Option 1: Let script handle it (it will prompt you)
.\scripts\Audit-Calibre-Tags.ps1

# Option 2: Automatically stop Calibre-Web
.\scripts\Audit-Calibre-Tags.ps1 -StopCalibreWeb

# Option 3: Stop manually first
.\scripts\Stop-CalibreWeb-And-Tunnel.ps1
.\scripts\Audit-Calibre-Tags.ps1
.\scripts\Start-CalibreWeb-With-Tunnel.ps1
```

### Complete Troubleshooting Guide

For all other issues, see the complete troubleshooting guide:
**`docs/Calibre_Tag_Troubleshooting.md`**

This includes solutions for:
- "calibredb not found" errors
- Permission issues
- Slow performance on large libraries
- Changes not showing in Calibre-Web
- Backup/restore procedures
- Emergency recovery

---

## Research & Sources

This system is based on:

### Industry Standards
- **BISAC Subject Codes** - Book Industry Study Group's standard taxonomy used by Amazon, Barnes & Noble, publishers
- Hierarchical structure, 3-category max recommendation

### Best Practices (from Calibre community)
- **3-5 tags per book** is optimal
- **Hierarchical organization** using custom columns or period notation
- **Consistent vocabulary** prevents fragmentation
- **Tag browser navigation** better than folder structures
- **Monthly maintenance** keeps library clean

### Sources:
- [BISAC Subject Codes - Book Industry Study Group](https://www.bisg.org/BISAC-Subject-Codes-main)
- [Managing subgroups of books — calibre documentation](https://manual.calibre-ebook.com/sub_groups.html)
- [How to effectively manage ebooks using Calibre - Stack Exchange](https://ebooks.stackexchange.com/questions/6081/how-to-effectively-manage-ebooks-using-calibre)
- [Best Practices For Tagging Novels In Calibre Libraries - GoodNovel](https://www.goodnovel.com/qa/best-practices-tagging-novels-calibre-libraries)
- [calibredb documentation](https://manual.calibre-ebook.com/generated/en/calibredb.html)

---

## Next Steps

### Immediate (For Initial Cleanup)
1. ✅ Run `Audit-Calibre-Tags.ps1` to understand current state
2. ✅ Review `summary.txt` and `potential_duplicate_tags.csv`
3. ✅ Create `calibre_tag_mapping.ps1` based on findings
4. ✅ Run `Update-Calibre-Tags.ps1 -DryRun` to test
5. ✅ Run full migration when satisfied

### Short Term (Ongoing Workflow)
1. Run `Tag-New-Calibre-Imports.ps1` after each import session
2. Review tag browser in Calibre-Web weekly
3. Make manual corrections as needed in Calibre Desktop

### Long Term (Optimization)
1. Enable hierarchical tag display in Calibre-Web
2. Create Virtual Libraries based on tag groups
3. Add custom columns for reading status, mood, etc.
4. Consider integration with Readarr when configured (Phase 3.6)

---

## File Reference

### Configuration Files
- `configs/calibre_standard_tags.txt` - Master taxonomy list
- `configs/calibre_tag_mapping.ps1.template` - Template for mapping rules
- `configs/calibre_tag_mapping.ps1` - Your custom mappings (gitignored)

### Scripts
- `scripts/Audit-Calibre-Tags.ps1` - Analyze current tags
- `scripts/Update-Calibre-Tags.ps1` - Apply standardization
- `scripts/Tag-New-Calibre-Imports.ps1` - Auto-tag new imports

### Output/Logs
- `data/calibre_tag_audit/` - Audit reports
- `data/calibre_tag_updates_[timestamp].csv` - Change logs

### Documentation
- `docs/Calibre_Tag_Management_Guide.md` - This file
- `docs/Calibre-Web_Configuration_Decisions.md` - User access/permissions

---

**Last Updated:** 2025-12-06
**System Status:** Ready for deployment
**Next Phase:** Initial audit and migration of 1,700 book library
