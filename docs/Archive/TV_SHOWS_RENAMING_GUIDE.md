# TV Shows Renaming Guide

## Overview

You now have a complete system for analyzing and renaming your TV shows library to Plex/Sonarr/Radarr standards.

## Created Files

### 1. Diagnostic Script
**File:** `scripts/Diagnose-TVShows.ps1`

Analyzes your TV shows library and generates a detailed CSV report.

**Usage:**
```powershell
.\scripts\Diagnose-TVShows.ps1 -TVShowsPath "A:\Media\TV Shows" -OutputPath ".\tv_diagnostic.csv"
```

**Output:** CSV file with issues and recommendations for each show

### 2. Year Mapping File
**File:** `tv_show_years.csv`

Maps current show folder names to correct names and years. **IMPORTANT**: Review and edit this file before running the rename script to ensure accuracy.

**Format:**
```csv
ShowFolder,CorrectName,Year
Adventure Time,Adventure Time,2010
Futurama,Futurama,1999
```

### 3. Rename Script
**File:** `scripts/Rename-TVShows-PlexStandard.ps1`

Comprehensive renaming script that handles:
- Show folder naming (adds year tags)
- Season folder standardization
- Episode file organization and renaming

**Usage (DRY RUN - recommended first):**
```powershell
.\scripts\Rename-TVShows-PlexStandard.ps1 `
    -TVShowsPath "A:\Media\TV Shows" `
    -YearMappingFile ".\tv_show_years.csv" `
    -DryRun `
    -LogFile ".\dry_run_log.txt"
```

**Usage (ACTUAL EXECUTION):**
```powershell
.\scripts\Rename-TVShows-PlexStandard.ps1 `
    -TVShowsPath "A:\Media\TV Shows" `
    -YearMappingFile ".\tv_show_years.csv" `
    -LogFile ".\rename_log.txt"
```

## Plex/Automation Standard Format

### Show Folders
```
Show Name (Year)/
```
Example: `Adventure Time (2010)/`

### Season Folders
```
Season 01/
Season 02/
```

### Episode Files
```
Show Name - S##E## - Episode Title.ext
```
Example: `Adventure Time - S01E01 - Slumber Party Panic.mkv`

## Current Status (Dry Run Results)

### Summary
- **Total Shows:** 30
- **Planned Changes:** 900
- **Errors:** 6 (minor issues with shows that have individual episode folders)

### What the Script Will Do

1. **Rename Show Folders** (30 shows)
   - Add year tags to all show names
   - Fix release group names (Jury Duty, Patriot, The Last of Us)

2. **Standardize Season Folders** (15+ shows)
   - Convert `Adventure.Time.S01.1080p.MAX.WEB-DL...` → `Season 01`
   - Convert `Futurama.S01.1080p.DSNP.WEB-DL...` → `Season 01`
   - Convert `Season 1` → `Season 01` (pad with zero)

3. **Move and Rename Episode Files** (800+ files)
   - Move from nested release folders into proper season folders
   - Standardize naming to "Show Name - S##E## - Episode Title.ext"
   - Clean release metadata from filenames

## Example Transformation

**Before:**
```
Futurama/
├── Futurama.S01.1080p.DSNP.WEB-DL.AAC2.0.H.264-Yassmiso/
│   ├── Futurama.S01E01.1080p.DSNP.WEB-DL.AAC2.0.H.264.mkv
│   ├── Futurama.S01E02.1080p.DSNP.WEB-DL.AAC2.0.H.264.mkv
│   └── ...
```

**After:**
```
Futurama (1999)/
├── Season 01/
│   ├── Futurama - S01E01 - Space Pilot 3000.mkv
│   ├── Futurama - S01E02 - The Series Has Landed.mkv
│   └── ...
```

## Recommended Workflow

### Step 1: Review Year Mapping
Open `tv_show_years.csv` and verify:
- Show names are correct (check for colons, special characters)
- Years are accurate
- Critical shows (Jury Duty, Patriot, The Last of Us) have proper names

### Step 2: Run Dry-Run
```powershell
cd C:\Users\rokon\source\media_automation

.\scripts\Rename-TVShows-PlexStandard.ps1 `
    -TVShowsPath "A:\Media\TV Shows" `
    -YearMappingFile ".\tv_show_years.csv" `
    -DryRun `
    -LogFile ".\dry_run_log.txt"
```

### Step 3: Review Dry-Run Log
Check the log file for:
- Planned changes look correct
- No unexpected errors
- File paths are accurate

### Step 4: Execute Rename
Once satisfied with dry-run results:
```powershell
.\scripts\Rename-TVShows-PlexStandard.ps1 `
    -TVShowsPath "A:\Media\TV Shows" `
    -YearMappingFile ".\tv_show_years.csv" `
    -LogFile ".\rename_execution_log.txt"
```

### Step 5: Cleanup Empty Folders
After renaming, manually check for and remove empty release group folders.

## Known Issues

### Shows with Individual Episode Folders
Some shows (e.g., The Rehearsal, Wild Wild Country) have individual folders per episode instead of season folders. The script will warn about these. You may need to:
1. Manually consolidate episodes into season folders, OR
2. Handle these shows separately

### Empty Show Folders
10 shows currently have no content. These will be renamed but remain empty:
- Adventure Time Distant Lands
- Families Like Ours
- Hunting Wives
- Louis Theroux Interviews
- Mo
- OMG Fashun
- The Daily Show
- (and 3 critical folders that are empty)

Consider deleting these or populating them with content before running automation tools.

## After Renaming

Your library will be ready for:
- **Plex** - Optimal metadata matching and organization
- **Sonarr** - Automatic TV show management
- **Radarr** - (for movies, separate workflow)
- **Bazarr** - Subtitle management

## Safety Features

- **Dry-Run Mode:** Preview all changes before executing
- **Detailed Logging:** Every action is logged
- **Error Handling:** Skips problematic items and continues
- **Path Validation:** Checks for existing files before renaming
- **No Destructive Operations:** Only renames and moves, never deletes video files

## Support Files Generated

- `tv_shows_diagnostic_report.csv` - Initial analysis
- `tv_rename_dryrun_log.txt` - Dry-run preview log
- `dry_run_output.txt` - Console output from dry-run
- `tv_rename_log.txt` - Actual execution log (when run)

## Next Steps After Successful Rename

1. Scan library in Plex to update metadata
2. Configure Sonarr to monitor your TV Shows folder
3. Set up Prowlarr for indexer management
4. Consider Bazarr for automated subtitle downloads
5. Clean up any remaining junk files (.nfo, .txt, samples, etc.)
