---
name: deep-clean-torrents
description: Reclaim disk space by removing hardlink-orphaned download torrents (true disk duplicates) while preserving private-tracker seeding ratio. Use when the user wants to free space on A:\, clean up old downloads, remove fully-seeded torrents, or do a "deep clean" of the Downloads folder. Distinguishes the routine automated path from the manual stage-by-stage path.
---

# Deep-clean torrents (hardlink-orphan cleanup)

Goal: delete download-folder torrents whose copy is NOT hardlinked into the Media
library (Sonarr/Radarr upgraded or replaced them, so the Downloads copy is a real
duplicate) -- while never touching torrents still hardlinked to Media or still
needed for seeding ratio on private trackers.

All scripts are in `scripts\` and load credentials from `config.ps1`. Run from the
repo root. **Safety guarantees baked into the scripts:** books/audiobooks/music
categories are always skipped, MAM tracker is excluded, anything under `A:\Media`
is refused, and every removal re-checks hardlink status at delete time.

## First decide: routine or manual?

- **Routine / "just free some space"** -> use the orchestrator. It chains every
  step below under safety gates and emails a summary. This is what the weekly
  scheduled task runs.
  ```powershell
  .\scripts\Auto-CleanupOrphans.ps1 -Force -DryRun   # analyze + email, no deletions
  .\scripts\Auto-CleanupOrphans.ps1 -Force           # apply (drop -Force to honor the 300GB free-space skip gate)
  ```
  Confirm the dry-run summary with the user before the real run.

- **Deep clean / wants to inspect each stage** -> run the manual sequence below.
  Use this when investigating what's eligible, tuning thresholds, or when the
  user wants eyes on each step.

## Manual stage-by-stage sequence

```powershell
# 1. Dry-run removal of seeded torrents; capture output for the analyzer
.\scripts\Remove-SeededTorrents.ps1 -MinDays 21 *>&1 | Tee-Object data\seeded_dryrun.txt

# 2. Extract the hardlink-failure list (torrents whose Downloads copy is NOT linked to Media)
.\scripts\Extract-HardlinkFailures.ps1 -InputFile data\seeded_dryrun.txt

# 3. Categorize each failure (UPGRADE_ORPHAN / SEASON_COMPLETE / MOVIE_FOUND = safe; others = investigate)
.\scripts\Analyze-HardlinkFailures.ps1 -ExportCsv

# 4. Sanity-check that each removal target actually has a playable file in Media
.\scripts\Verify-MediaTargets.ps1

# 5. Dry run the removal -- review what it WOULD delete
.\scripts\Remove-HardlinkOrphanTorrents.ps1

# 6. Apply only after reviewing the dry run
.\scripts\Remove-HardlinkOrphanTorrents.ps1 -Execute
```

## Guidance when driving this

- **Always show the user the dry-run / analysis output and get confirmation
  before any `-Execute` run.** Deletions free real disk and remove torrents from
  qBittorrent (`deleteFiles=true`).
- The complement is `Remove-SeededTorrents.ps1` itself, which protects torrents
  whose Media copy IS hardlinked (deleting them would free 0 GB). The orphan
  scripts target the inverse case.
- Default threshold is 21 seed-days; raise `-MinDays` to be more conservative.
- Entries flagged `AMBIGUOUS`, `ACTIVE_SEASON`, `MISSING_SEASON`,
  `SHOW_NOT_IN_MEDIA`, or `MOVIE_NOT_FOUND` are NOT auto-removed -- surface them
  for manual review rather than forcing deletion.
- See `CLAUDE.md` -> "Hardlink Failure Workflow" for the full description of each
  script's safety layers.
