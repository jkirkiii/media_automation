---
name: tag-new-books
description: Apply the standardized Calibre tag taxonomy to newly imported books, or run a full library-wide tag cleanup. Use when the user has added/imported books to Calibre, mentions tagging, asks to clean up tags, or wants new books categorized consistently (BISAC-based, 3-5 tags per book).
---

# Calibre tag management

The library (~2,370 books at `A:\Media\Calibre`) uses a standardized, BISAC-based
taxonomy: 3-5 tags per book, hierarchical (e.g. `Fiction.Science Fiction.Space
Opera`). Scripts are in `scripts\`; full reference is
`docs\Calibre_Tag_Management_Guide.md`.

## Routine: tag recently imported books

This is the common case -- run after importing new books into Calibre.

```powershell
# Auto-tag books added in the last 7 days (keyword/metadata based)
.\scripts\Tag-New-Calibre-Imports.ps1

# Same, but confirm each book interactively (use when the user wants control)
.\scripts\Tag-New-Calibre-Imports.ps1 -Interactive
```

Prefer `-Interactive` when the import is small or the user wants to review
assignments; use the plain run for bulk imports.

## One-time / periodic: full library tag cleanup

Use only when standardizing the whole library or after a large messy import --
not for routine new-book tagging.

```powershell
# 1. Analyze current tags; reports land in .\data\calibre_tag_audit\
.\scripts\Audit-Calibre-Tags.ps1

# 2. (first time only) create the mapping file from the template, then edit it
#    based on the audit before running the migration:
#    Copy-Item .\configs\calibre_tag_mapping.ps1.template .\configs\calibre_tag_mapping.ps1

# 3. Dry run the migration -- always review before applying
.\scripts\Update-Calibre-Tags.ps1 -DryRun

# 4. Apply (creates a backup before changing anything)
.\scripts\Update-Calibre-Tags.ps1
```

## Guidance when driving this

- For the full-library path, **always run `-DryRun` first and show the user the
  proposed changes** before applying.
- `configs\calibre_tag_mapping.ps1` is gitignored -- if it doesn't exist yet,
  copy it from the `.template` and tailor it from the audit output.
- Aim for 3-5 tags per book; flag books that come out with 0 or 10+ tags as
  needing manual attention.
- Calibre-Web must not be mid-write during a bulk tag update; if errors mention a
  locked database, stop Calibre-Web first (`Stop-CalibreWeb-And-Tunnel.ps1`).
