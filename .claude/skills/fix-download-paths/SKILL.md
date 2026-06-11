---
name: fix-download-paths
description: Fix qBittorrent saving downloads to the wrong folder -- torrents landing in the global save path (e.g. A:\Media) instead of their category path (A:\Downloads\TV, \Movies, \Books). Use when the user reports downloads in the wrong place, Sonarr/Radarr imports failing on path, or new categories not respecting save paths. Root cause is almost always Auto-TMM being off.
---

# Fix qBittorrent download paths (Auto-TMM)

**Symptom:** torrents download to the global save path instead of the
category-specific path. **Root cause:** Automatic Torrent Management (Auto-TMM) is
not enabled, so qBittorrent ignores the category save path that Sonarr/Radarr send
via the API.

Scripts are in `scripts\` and load credentials from `config.ps1`. Run from repo root.

## Step 1 — Diagnose (read-only)

```powershell
.\scripts\Debug-qBittorrent-Downloads.ps1
```

This prints the global save path, every category's save path, and where recent
torrents actually landed. Confirm the problem: recent torrents under the global
path / `A:\Media` rather than `A:\Downloads\<Category>`.

You can also list category definitions directly:

```powershell
.\scripts\Check-qBittorrent-Categories.ps1
```

## Step 2 — Fix

The core fix is enabling Auto-TMM globally (the key settings are
`auto_tmm_enabled = true` AND `torrent_changed_tmm_enabled = true`):

```powershell
.\scripts\Enable-qBittorrent-AutoTMM.ps1
```

If a specific category's save path is wrong (not just Auto-TMM off), correct it:

```powershell
.\scripts\Update-qBittorrent-Category-Path.ps1
```

Expected category -> path mapping:
- `tv-sonarr`   -> `A:\Downloads\TV`
- `movie-radarr`-> `A:\Downloads\Movies`
- `books`       -> `A:\Downloads\Books`

## Step 3 — Verify

```powershell
.\scripts\Debug-qBittorrent-Downloads.ps1
```

Confirm Auto-TMM is on and a newly added (or rechecked) torrent resolves to its
category path.

## Notes

- Existing misplaced torrents won't move themselves -- toggling a torrent's TMM
  (or using the category-path update) re-homes it; new torrents will be correct
  once Auto-TMM is on.
- Hardlinks only work within the same drive; keep downloads and Media both on
  `A:\` so Sonarr/Radarr can hardlink on import (saves space, preserves seeds).
- If paths look right but imports still fail, the issue is likely elsewhere
  (tracker/seeding) -- consider `/diagnose-seeding` instead.
