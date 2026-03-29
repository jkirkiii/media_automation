# Calibre Tag Management - Quick Start

This directory contains the configuration files for the Calibre tag standardization system.

## Quick Start

### 1. Audit Your Current Tags

```powershell
.\scripts\Audit-Calibre-Tags.ps1
```

This creates reports in `.\data\calibre_tag_audit\`:
- `summary.txt` - Overview
- `potential_duplicate_tags.csv` - Tags to merge
- `tag_frequency.csv` - Most used tags
- `books_without_tags.csv` - Untagged books

### 2. Create Your Tag Mapping

```powershell
# Copy the template
Copy-Item .\configs\calibre_tag_mapping.ps1.template .\configs\calibre_tag_mapping.ps1

# Edit to add your specific mappings
notepad .\configs\calibre_tag_mapping.ps1
```

### 3. Run the Migration

```powershell
# Test first (dry run)
.\scripts\Update-Calibre-Tags.ps1 -DryRun

# Apply changes
.\scripts\Update-Calibre-Tags.ps1
```

### 4. Auto-Tag New Imports

```powershell
# After importing new books
.\scripts\Tag-New-Calibre-Imports.ps1
```

## Files in This Directory

- **`calibre_standard_tags.txt`** - Master list of standardized tags based on BISAC
- **`calibre_tag_mapping.ps1.template`** - Template for creating your mapping rules
- **`calibre_tag_mapping.ps1`** - Your custom mappings (gitignored, create from template)

## Tag Standards

**Best Practices:**
- 3-5 tags per book maximum
- Use hierarchical notation: `Fiction.Science Fiction.Space Opera`
- Be consistent (don't mix "Sci-Fi" and "Science Fiction")
- Primary genre should be first tag

**Tag Categories:**
- Fiction genres (Science Fiction, Fantasy, Mystery, etc.)
- Non-Fiction categories (Biography, History, Science, etc.)
- Audience tags (Young Adult, Children's, Adult)
- Special categories (Graphic Novel, Poetry, etc.)

See `calibre_standard_tags.txt` for the complete list.

## Full Documentation

For complete documentation, see:
**`docs/Calibre_Tag_Management_Guide.md`**

This includes:
- Detailed workflow instructions
- Script parameters and examples
- Troubleshooting guide
- Research sources and best practices
