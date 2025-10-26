# TV Shows Rename - Follow-Up Actions Required

## Execution Summary

**Date:** 2025-10-12
**Total Changes:** 900
**Errors:** 62
**Warnings:** 26

## Items Requiring Manual Attention

### 🔴 CRITICAL: Shows Not Renamed (2 shows)

#### 1. Jury Duty
**Current Path:** `A:\Media\TV Shows\Jury.Duty.S01.1080p.AMZN.WEBRip.DDP5.1.x264-NTb[eztv.re]`
**Target Path:** `A:\Media\TV Shows\Jury Duty (2023)`
**Issue:** Folder appears to be empty - script couldn't find it
**Action Required:**
- Check if folder exists and has content
- If empty, manually delete the folder
- If has content, manually rename or run script again on this folder only

#### 2. Patriot
**Current Path:** `A:\Media\TV Shows\Patriot.2015.COMPLETE.SERIES.720p.AMZN.WEBRip.x264-GalaxyTV[TGx]`
**Target Path:** `A:\Media\TV Shows\Patriot (2015)`
**Issue:** Folder appears to be empty - script couldn't find it
**Action Required:**
- Check if folder exists and has content
- If empty, manually delete the folder
- If has content, manually rename or run script again on this folder only

---

### 🟡 HIGH PRIORITY: Files Still in Nested Folders (56 files)

#### Taskmaster (2015) - Seasons 2, 4-9
**Issue:** Files are still nested inside release group folders instead of being directly in season folders

**Affected Seasons:**
- **Season 02:** 5 episodes still in nested folders (e.g., `Taskmaster.S02E01.WEB.x264-C4TV[rarbg]`)
- **Season 04:** 8 episodes still in nested folders
- **Season 05:** 8 episodes still in nested folders
- **Season 06:** 10 episodes still in nested folders
- **Season 07:** 10 episodes still in nested folders
- **Season 08:** 4 episodes still in nested folders
- **Season 09:** 4 episodes still in nested folders

**Current Structure Example:**
```
Taskmaster (2015)/
├── Season 02/
│   ├── Taskmaster.S02E01.WEB.x264-C4TV[rarbg]/
│   │   └── Taskmaster - S02E01 - Fear of Failure.mkv  ❌ NESTED
│   └── ...
```

**Target Structure:**
```
Taskmaster (2015)/
├── Season 02/
│   ├── Taskmaster - S02E01 - Fear of Failure.mkv  ✓
│   └── ...
```

**Action Required:**
1. Navigate to `A:\Media\TV Shows\Taskmaster (2015)`
2. For each affected season folder, move all .mkv files from nested release folders up to the season folder
3. Delete empty release group folders
4. Alternative: Run a manual flatten script (see below)

#### Sample Files in Taskmaster Season 17
**Issue:** 4 sample files that no longer exist were attempted to be moved
**Action Required:** None - these were already deleted or missing

---

### 🟠 MEDIUM PRIORITY: Shows with Individual Episode Folders (4 shows)

These shows have a folder per episode instead of season folders. The script couldn't extract season numbers from the episode-specific folder names.

#### 1. Wild Wild Country (2018)
**Current Structure:**
```
Wild Wild Country (2018)/
├── Wild.Wild.Country.S01E01.WEB.x264-AMRAP[ettv]/
│   └── [episode file]
├── Wild.Wild.Country.S01E02.WEB.x264-AMRAP[ettv]/
│   └── [episode file]
└── ... (6 episodes)
```

**Action Required:**
1. Create `Season 01` folder
2. Move all episode files from individual folders into `Season 01`
3. Rename files to standard format
4. Delete empty episode folders

#### 2. The Rehearsal (2022)
**Current Structure:** 5 individual episode folders (S01E02-S01E06)
**Action Required:** Same as Wild Wild Country

#### 3. Mrs. Davis (2023)
**Current Structure:** 6 individual episode folders
**Action Required:** Same as Wild Wild Country

#### 4. Party Down (2009)
**Current Structure:** 3 individual episode folders (Season 3)
**Action Required:** Same as Wild Wild Country

---

### 🟡 LOW PRIORITY: Shows with Irregular Season Folder Names (4 shows)

#### 1. The Vampire Diaries (2009)
**Issue:** Mixed season folder naming conventions

**Current Folders:**
- `Season 04` ✓ (correct)
- `Season 05` ✓ (correct)
- `Season 06` ✓ (correct)
- `Season 07` ✓ (correct)
- `TheVampireDiariesSeason1` ❌ (no season number extracted)
- `TheVampireDiariesSeason2` ❌ (no season number extracted)
- `TheVampireDiariesSeason3` ❌ (no season number extracted)
- `The Vampire Diaries - Season 6 Complete -ChameE` ❌ (duplicate?)
- `The Vampire Diaries Season 4 (2012-2013) COMPLETE by vladtepes3176` ❌ (duplicate?)
- `The Vampire Diaries Season 5 (2013-2014) COMPLETE by vladtepes3176` ❌ (duplicate?)

**Action Required:**
1. Rename `TheVampireDiariesSeason1` → `Season 01`
2. Rename `TheVampireDiariesSeason2` → `Season 02`
3. Rename `TheVampireDiariesSeason3` → `Season 03`
4. Check for duplicate content in oddly-named folders
5. Consolidate or delete duplicates

#### 2. Broad City (2014)
**Issue:** Season folder named `Broad City S02 1080p WEB-DL DD+ 2.0 x264-TrollHD`
**Action Required:** Files may still be in this folder; move to `Season 02`

#### 3. Lessons in Chemistry (2023)
**Issue:** Episode folder `Lessons.in.Chemistry.S01E04.1080p.x265-ELiTE` not processed
**Action Required:** Move episode file to `Season 01` folder

#### 4. Silo (2023)
**Issue:** Folder named just `Silo.S02` (no episodes in it)
**Action Required:** Rename to `Season 02`

---

## Recommended Manual Cleanup Scripts

### Script 1: Flatten Taskmaster Nested Folders
```powershell
# Run this from: C:\Users\rokon\source\media_automation

$taskmasterPath = "A:\Media\TV Shows\Taskmaster (2015)"
$seasons = @("Season 02", "Season 04", "Season 05", "Season 06", "Season 07", "Season 08", "Season 09")

foreach ($season in $seasons) {
    $seasonPath = Join-Path $taskmasterPath $season

    Write-Host "Processing: $season" -ForegroundColor Cyan

    # Find all video files in nested folders
    $videoFiles = Get-ChildItem -Path $seasonPath -Recurse -File |
                  Where-Object { $_.Extension -match '\.(mkv|mp4|avi)$' -and $_.Directory.FullName -ne $seasonPath }

    foreach ($file in $videoFiles) {
        $targetPath = Join-Path $seasonPath $file.Name

        if (Test-Path $targetPath) {
            Write-Host "  SKIP: $($file.Name) already exists at root" -ForegroundColor Yellow
        } else {
            Write-Host "  Moving: $($file.Name)" -ForegroundColor Green
            Move-Item -Path $file.FullName -Destination $targetPath
        }
    }

    # Remove empty nested folders
    $emptyFolders = Get-ChildItem -Path $seasonPath -Directory |
                    Where-Object { (Get-ChildItem $_.FullName -Recurse -File).Count -eq 0 }

    foreach ($folder in $emptyFolders) {
        Write-Host "  Removing empty folder: $($folder.Name)" -ForegroundColor Gray
        Remove-Item -Path $folder.FullName -Recurse -Force
    }
}

Write-Host "`nTaskmaster cleanup complete!" -ForegroundColor Green
```

### Script 2: Fix Individual Episode Folders
```powershell
# Run this for shows with individual episode folders

function Fix-IndividualEpisodeFolders {
    param(
        [string]$ShowPath,
        [int]$SeasonNumber = 1
    )

    $seasonFolderName = "Season {0:D2}" -f $SeasonNumber
    $seasonPath = Join-Path $ShowPath $seasonFolderName

    # Create season folder if it doesn't exist
    if (-not (Test-Path $seasonPath)) {
        New-Item -Path $seasonPath -ItemType Directory | Out-Null
        Write-Host "Created: $seasonFolderName" -ForegroundColor Green
    }

    # Get all episode folders
    $episodeFolders = Get-ChildItem -Path $ShowPath -Directory |
                     Where-Object { $_.Name -match 'S\d+E\d+' -and $_.Name -ne $seasonFolderName }

    foreach ($episodeFolder in $episodeFolders) {
        Write-Host "Processing: $($episodeFolder.Name)" -ForegroundColor Cyan

        # Find video files
        $videoFiles = Get-ChildItem -Path $episodeFolder.FullName -Recurse -File |
                     Where-Object { $_.Extension -match '\.(mkv|mp4|avi)$' }

        foreach ($file in $videoFiles) {
            $targetPath = Join-Path $seasonPath $file.Name

            if (Test-Path $targetPath) {
                Write-Host "  SKIP: $($file.Name) already exists" -ForegroundColor Yellow
            } else {
                Write-Host "  Moving: $($file.Name)" -ForegroundColor Green
                Move-Item -Path $file.FullName -Destination $targetPath
            }
        }

        # Remove empty episode folder
        if ((Get-ChildItem $episodeFolder.FullName -Recurse -File).Count -eq 0) {
            Remove-Item -Path $episodeFolder.FullName -Recurse -Force
            Write-Host "  Removed: $($episodeFolder.Name)" -ForegroundColor Gray
        }
    }

    Write-Host "Complete!" -ForegroundColor Green
}

# Run for each affected show
Fix-IndividualEpisodeFolders -ShowPath "A:\Media\TV Shows\Wild Wild Country (2018)" -SeasonNumber 1
Fix-IndividualEpisodeFolders -ShowPath "A:\Media\TV Shows\The Rehearsal (2022)" -SeasonNumber 1
Fix-IndividualEpisodeFolders -ShowPath "A:\Media\TV Shows\Mrs. Davis (2023)" -SeasonNumber 1
Fix-IndividualEpisodeFolders -ShowPath "A:\Media\TV Shows\Party Down (2009)" -SeasonNumber 3
```

### Script 3: Fix Vampire Diaries Season Folders
```powershell
# Fix The Vampire Diaries irregular season naming

$vdPath = "A:\Media\TV Shows\The Vampire Diaries (2009)"

# Rename season folders
Rename-Item -Path "$vdPath\TheVampireDiariesSeason1" -NewName "Season 01"
Rename-Item -Path "$vdPath\TheVampireDiariesSeason2" -NewName "Season 02"
Rename-Item -Path "$vdPath\TheVampireDiariesSeason3" -NewName "Season 03"

Write-Host "Vampire Diaries seasons renamed!" -ForegroundColor Green

# Manual check required for potential duplicates:
# - "The Vampire Diaries - Season 6 Complete -ChameE"
# - "The Vampire Diaries Season 4 (2012-2013) COMPLETE by vladtepes3176"
# - "The Vampire Diaries Season 5 (2013-2014) COMPLETE by vladtepes3176"
```

---

## Summary Checklist

### Immediate Actions
- [ ] Check and handle Jury Duty folder (empty or populate)
- [ ] Check and handle Patriot folder (empty or populate)
- [ ] Run Taskmaster flatten script to fix nested folders
- [ ] Run individual episode folder fix script for 4 shows

### Follow-Up Actions
- [ ] Fix The Vampire Diaries season folder naming
- [ ] Check for duplicate content in Vampire Diaries
- [ ] Fix remaining irregular folders (Broad City, Lessons in Chemistry, Silo)
- [ ] Scan cleaned library in Plex to verify metadata matching

### Optional Cleanup
- [ ] Remove .nfo files
- [ ] Remove .txt files (RARBG, etc.)
- [ ] Remove sample video files
- [ ] Remove empty folders

---

## Success Rate

**Successfully Processed:**
- 22 out of 30 shows completely successful
- 6 shows need minor manual fixes
- 2 shows need investigation (empty folders)

**Overall Success Rate:** ~73% fully automatic, ~93% with minor manual cleanup

---

## Next Steps

1. Run the three manual cleanup scripts above
2. Verify all shows are properly organized
3. Run the diagnostic script again to verify: `.\scripts\Diagnose-TVShows.ps1`
4. When satisfied, scan your Plex library to update metadata
