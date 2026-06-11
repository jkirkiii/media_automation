# Scripts Reference

Complete catalog of the active automation scripts. For project-wide conventions,
storage paths, private-tracker safety rules, and the PowerShell gotchas, see
[`../CLAUDE.md`](../CLAUDE.md). For a human overview of the whole project, see
[`../README.md`](../README.md).

**All scripts load credentials from `config.ps1`** (gitignored). Run them from the
repo root, e.g. `.\scripts\Backup-Configs.ps1`.

## Folder layout

- `scripts\` -- active tools you'd run again (cataloged below)
- `scripts\setup\` -- one-time installers/configurators kept for disaster recovery:
  `Install-CalibreWeb`, `Install-Cloudflared`, `Configure-Cloudflare-Tunnel`,
  `Verify-Cloudflare-Tunnel`, `Setup-Startup-Task`
- `scripts\Archive\` -- superseded, one-off, or problem-solved scripts retained for
  history. **Do not run blindly** -- many target conditions that no longer exist.

## Slash-command skills (`.claude\skills\`)

Situational runbooks Claude loads on demand (or you invoke directly):

| Skill | Use when |
|---|---|
| `/diagnose-seeding` | qB shows "seeding" but trackers don't credit you (often post-ProtonVPN reconnect) |
| `/deep-clean-torrents` | Reclaim disk by removing hardlink-orphan downloads |
| `/tag-new-books` | Apply the standardized Calibre taxonomy to new imports / full-library cleanup |
| `/fix-download-paths` | qB saving downloads to the wrong folder (Auto-TMM) |

The skills wrap the scripts below with the correct sequence and safety checks --
prefer them for those workflows.

---

## Maintenance & Backup

- **`Backup-Configs.ps1`** -- Weekly backup: Sonarr + Prowlarr + Radarr (API-triggered zip), Calibre-Web app.db, Cloudflare tunnel config. Compresses to a dated archive at `A:\Backups\MediaStack\`, prunes old backups automatically.
  - `.\scripts\Backup-Configs.ps1` -- normal run (uses API + config.ps1 credentials)
  - `.\scripts\Backup-Configs.ps1 -SkipApiBackups` -- raw DB copy, no API needed
  - `.\scripts\Backup-Configs.ps1 -BackupRoot "D:\Backups" -KeepCount 12` -- custom path/retention
- **`Schedule-WeeklyBackup.ps1`** -- Registers `Backup-Configs.ps1` as a Task Scheduler job (SYSTEM, every Sunday 3 AM). Requires Administrator. Re-run to update schedule.
- **`Auto-CleanupOrphans.ps1`** -- Weekly cleanup orchestrator. Removes hardlink-orphaned download torrents (true disk duplicates) while preserving private-tracker safety. Pipeline: disk-free gate -> -arr queue exclusion -> seeding audit dry-run -> hardlink failure analysis -> targeted removal via qBittorrent API (deleteFiles=true) -> log + email summary. Defaults: 300 GB free-space threshold, 21-day seed minimum, books/audiobooks/music excluded, MAM tracker excluded. Logs to `logs\auto_cleanup_<timestamp>.log`. Needs SMTP creds in `config.ps1` for email.
  - `.\scripts\Auto-CleanupOrphans.ps1` -- standard run (auto-skips if free space > 300 GB)
  - `.\scripts\Auto-CleanupOrphans.ps1 -Force -DryRun` -- analyze + email summary, no deletions
  - `.\scripts\Auto-CleanupOrphans.ps1 -NoEmail` -- skip email (useful for testing)
  - `.\scripts\Auto-CleanupOrphans.ps1 -FreeSpaceThresholdGB 500 -MinSeedDays 28` -- custom thresholds
- **`Schedule-WeeklyCleanup.ps1`** -- Registers `Auto-CleanupOrphans.ps1` as a Task Scheduler job (SYSTEM, every Monday 4 AM -- 1h after the weekly backup). Requires Administrator.

## Sonarr / Radarr / Prowlarr Configuration

- **`Configure-Sonarr.ps1`** -- Complete Sonarr configuration via API (quality profiles, naming, root folder).
- **`Configure-Sonarr-Simple.ps1`** -- Minimal essential Sonarr setup.
- **`Configure-Radarr.ps1`** -- Configures Radarr (quality profiles, root folder, media management) following the Sonarr pattern.
- **`Connect-Prowlarr-To-Sonarr.ps1`** -- Connect Prowlarr indexers to Sonarr (`.template` sibling shows the credential pattern).
- **`Connect-Prowlarr-To-Radarr.ps1`** -- Add Radarr as an application in Prowlarr to sync indexers.
- **`Connect-qBittorrent-To-Sonarr.ps1`** -- Connect qBittorrent download client to Sonarr.
- **`Connect-qBittorrent-To-Radarr.ps1`** -- Add qBittorrent as a download client in Radarr.
- **`Sync-Prowlarr-Indexers.ps1`** -- Trigger Prowlarr -> Sonarr application sync and report resulting indexers.
- **`Verify-Sonarr-Setup.ps1`** -- Verify Sonarr configuration and connectivity (system status, series, indexers).
- **`Check-Sonarr-MediaManagement.ps1`** -- Check media management settings (hardlinks, import behavior).
- **`Check-Sonarr-DownloadClient.ps1`** -- Inspect download client configuration in Sonarr.
- **`Check-ArrQueueStatus.ps1`** -- Read-only. Reports import errors and wanted/missing items from Sonarr and Radarr.
- **`Check-Missing-Episodes.ps1`** -- Lists episodes Sonarr has flagged missing and recent grab/import history.

## qBittorrent Configuration & Troubleshooting

**Essential for setup:**
- **`Enable-qBittorrent-AutoTMM.ps1`** -- **CRITICAL**: enable Automatic Torrent Management (required for category save paths to work).
- **`Setup-qBittorrent-Categories-Complete.ps1`** -- Complete category setup for TV/Movies/Books with Auto-TMM.
- **`Update-qBittorrent-Category-Path.ps1`** -- Update an existing category's save path.

**Diagnostics:**
- **`Debug-qBittorrent-Downloads.ps1`** -- Comprehensive diagnostic: global paths, categories, recent torrent locations.
- **`Check-qBittorrent-Categories.ps1`** -- Quick category configuration check.
- **`Check-qBittorrent-Settings.ps1`** -- Network settings, announce settings, tracker status.

**Troubleshooting / utilities:**
- **`Check-StalledUP-Trackers.ps1`** -- Check tracker announce status for stalled torrents.
- **`Force-Reannounce-All.ps1`** -- Force reannounce to all stalledUP torrents. Auto-loads qBittorrent username AND password from `config.ps1` (no prompt). `-user`/`-password` override. Uses `-UseBasicParsing` so it never triggers the IE-engine security prompt.
- **`Show-All-Torrents.ps1`** -- Display all torrents with details, grouped by state.
- **`Remove-OrphanedDownloads.ps1`** -- Deletes orphaned download files/folders for torrents already removed from qBittorrent whose Downloads copies were never cleaned up.

## VPN Port Forwarding (ProtonVPN) -- fully automated

A ProtonVPN reconnect breaks TWO things: (1) the forwarded port rotates, and (2) the
tunnel interface renumbers (friendly name stays `ProtonVPN` but the `iftype53_NNNNN`
value changes), leaving qBittorrent bound to a dead interface -- "disconnected", no
announces, trackers don't show seeding even though qB does. Both are handled
automatically via NAT-PMP (gateway `10.2.0.1`, pure PowerShell, no `natpmpc.exe`).
Works with the ProtonVPN GUI app today and a bare WireGuard tunnel later without code
changes. Full mechanism: [`../docs/QBITTORRENT_VPN_BINDING.md`](../docs/QBITTORRENT_VPN_BINDING.md).
For the symptom-driven runbook, use `/diagnose-seeding`.

- **`Sync-VpnPort.ps1`** -- Each pass reconciles BOTH qBittorrent's listening port (against the live NAT-PMP forwarded port) AND its bound interface (against the current `ProtonVPN` interface value). Renews the NAT-PMP lease; if either drifted, updates qBittorrent (Web API) and force-reannounces. Leaves the binding alone while the VPN is down (no IP leak). Logs to `logs\vpn_port_sync.log`.
  - `.\scripts\Sync-VpnPort.ps1 -Once` -- single pass, prints whether port + interface match (use to test)
  - `.\scripts\Sync-VpnPort.ps1` -- run forever, ~45s loop (used by the scheduled task)
- **`Schedule-VpnPortSync.ps1`** -- Registers `Sync-VpnPort.ps1` as a logon-triggered Scheduled Task that runs continuously (unlimited execution time, single instance). Requires Administrator. NOTE: after editing `Sync-VpnPort.ps1`, restart the task (`Stop-ScheduledTask`/`Start-ScheduledTask`) so the long-running loop reloads the new code.
- **`Diagnose-TrackerSeeding.ps1`** -- Read-only. Shows qBittorrent connection status, listen port vs live NAT-PMP forwarded port, bound interface, announce settings, and a per-torrent tracker status sample. First stop when trackers don't show you seeding.

## Seeding Audit & Cleanup

- **`Audit-Seeding-Torrents.ps1`** -- Reports all torrents with seed time, ratio, size, and tracker. Buckets by 10/14/21/30-day thresholds, breaks down per-tracker and per-category, flags low-ratio candidates.
  - `.\scripts\Audit-Seeding-Torrents.ps1` -- audit all torrents (default 10d threshold)
  - `.\scripts\Audit-Seeding-Torrents.ps1 -MinDays 14` -- stricter threshold
  - `.\scripts\Audit-Seeding-Torrents.ps1 -Category tv-sonarr` -- single category only
  - `.\scripts\Audit-Seeding-Torrents.ps1 -ExportCsv` -- save to `data\torrent_audit_<date>.csv`
- **`Remove-SeededTorrents.ps1`** -- Removes torrents meeting the seed threshold and deletes their Downloads copies. Dry run by default -- requires `-Execute`. Hardlink safety check (fsutil) confirms the Media copy exists before deleting. Ebook/audiobook/music categories always skipped. Torrents failing the hardlink check are reported but never deleted.
  - `.\scripts\Remove-SeededTorrents.ps1` -- dry run
  - `.\scripts\Remove-SeededTorrents.ps1 -Execute` -- actually remove eligible torrents
  - `.\scripts\Remove-SeededTorrents.ps1 -MinDays 14 -Execute` -- stricter threshold
  - `.\scripts\Remove-SeededTorrents.ps1 -Category tv-sonarr -Execute` -- one category only

## Hardlink Failure Workflow (true-duplicate cleanup)

Counterpart to `Remove-SeededTorrents.ps1`. That script protects torrents whose Media
copy is hardlinked (deletion would free 0 GB); the scripts below target the inverse --
torrents whose Downloads copy is NOT linked to Media (Sonarr upgraded, replaced, or
never imported them as hardlinks). These are true disk duplicates and removal frees
real space. **The `/deep-clean-torrents` skill drives this whole sequence.**

- **`Extract-HardlinkFailures.ps1`** -- Parses captured stdout from a `Remove-SeededTorrents.ps1` dry run and writes a fresh `data\hardlink_failures.txt`. Auto-detects newest `data\seeded_dryrun_*.txt`.
- **`Analyze-HardlinkFailures.ps1`** -- Categorizes each failure as `UPGRADE_ORPHAN_EPISODE`, `SEASON_COMPLETE`, `MOVIE_FOUND` (safe), `ACTIVE_SEASON` / `MISSING_SEASON` / `SHOW_NOT_IN_MEDIA` / `MOVIE_NOT_FOUND` (investigate), `BOOK_OR_OTHER` (skip), or `AMBIGUOUS` (manual review). Exports `data\hardlink_analysis_<date>.csv` with `-ExportCsv`.
- **`Verify-MediaTargets.ps1`** -- Sanity-checks every `MediaPath` in the analysis CSV before deletion -- confirms the target file/season folder is on disk with playable video.
- **`Remove-HardlinkOrphanTorrents.ps1`** -- Removes torrents from qBittorrent (`deleteFiles=true`) for analyzed entries in the safe categories. Three safety layers: (1) re-checks video-file hardlink status at removal time, (2) refuses any `content_path` under `A:\Media`, (3) excludes configurable categories (default `books`, `audiobooks`, `music`), tracker hosts (default `t.myanonamouse.net`), and arbitrary hashes (used by the orchestrator to skip -arr queue items). Dry run by default; requires `-Execute`.
  - `.\scripts\Remove-HardlinkOrphanTorrents.ps1` -- dry run with all safety filters active
  - `.\scripts\Remove-HardlinkOrphanTorrents.ps1 -Execute` -- apply removals
  - `.\scripts\Remove-HardlinkOrphanTorrents.ps1 -ExcludeTrackers @("t.myanonamouse.net","cow.milkie.cc") -Execute` -- additional tracker guards

Typical manual sequence (one-shot deep clean -- or just run `/deep-clean-torrents`):
```powershell
.\scripts\Remove-SeededTorrents.ps1 -MinDays 21 *>&1 | Tee-Object data\seeded_dryrun.txt
.\scripts\Extract-HardlinkFailures.ps1 -InputFile data\seeded_dryrun.txt
.\scripts\Analyze-HardlinkFailures.ps1 -ExportCsv
.\scripts\Verify-MediaTargets.ps1
.\scripts\Remove-HardlinkOrphanTorrents.ps1            # dry run
.\scripts\Remove-HardlinkOrphanTorrents.ps1 -Execute   # apply
```

## RAR Archive Extraction

Downloads from some release groups (e.g. BRAVERY) arrive as multi-part RAR archives
(`.rar` + `.r00`, `.r01`, ...) instead of plain video. Extract before Sonarr imports.

- **`Extract-RarSeason.ps1`** -- Extracts multi-part RAR archives for every episode in a season folder. Skips already-extracted episodes. Requires 7-Zip at `C:\Program Files\7-Zip\7z.exe`.
  - `.\scripts\Extract-RarSeason.ps1 -SeasonPath "A:\Downloads\TV\Show.S01.1080p..."`
  - Re-run safely: already-extracted episodes are skipped
  - After extraction, trigger Sonarr import via **Wanted -> Manual Import** or **Series -> Rescan Files**

## Media Library Management

- **`Quick-Delete-Empty.ps1`** -- Delete empty directories in the media library.
- **`Force-Delete-Empty.ps1`** -- Force delete empty directories (including hidden files), via native `rmdir`. Run as Administrator.

## Ebook / Calibre-Web Operations

- **`Start-CalibreWeb-With-Tunnel.ps1`** -- Start Calibre-Web and the Cloudflare Tunnel together (local + remote access). Also available as `..\Start-CalibreWeb-Remote.bat` (auto-starts on login).
- **`Stop-CalibreWeb-And-Tunnel.ps1`** -- Stop both Calibre-Web and the tunnel.
- **`Audit-Calibre-Tags.ps1`** -- Analyze current tags; writes reports to `data\calibre_tag_audit\`.
- **`Update-Calibre-Tags.ps1`** -- Apply the tag mapping to migrate existing tags to the standard taxonomy. Supports `-DryRun`; backs up before applying.
- **`Tag-New-Calibre-Imports.ps1`** -- Auto-tag books added in the last 7 days. `-Interactive` confirms each book. (See the `/tag-new-books` skill.)

```powershell
# Service control
.\Start-CalibreWeb-Remote.bat                          # start (or the .ps1 below)
.\scripts\Start-CalibreWeb-With-Tunnel.ps1
.\scripts\Stop-CalibreWeb-And-Tunnel.ps1
Get-Process | Where-Object {$_.ProcessName -like "*cps*" -or $_.ProcessName -like "*cloudflared*"}
& "C:\Users\rokon\.cloudflared\cloudflared.exe" tunnel info calibre-web-tunnel

# Tag management
.\scripts\Audit-Calibre-Tags.ps1                       # analyze -> data\calibre_tag_audit\
Copy-Item .\configs\calibre_tag_mapping.ps1.template .\configs\calibre_tag_mapping.ps1
.\scripts\Update-Calibre-Tags.ps1 -DryRun              # test migration
.\scripts\Update-Calibre-Tags.ps1                      # apply
.\scripts\Tag-New-Calibre-Imports.ps1                  # ongoing, after new imports
```

> The one-time Literature migration helpers (`Check-Literature-Directory.ps1`,
> `Compare-Calibre-Import.ps1`, `Backup-Literature-Library.ps1`,
> `Verify-Literature-Backup.ps1`) now live in `scripts\Archive\` -- migration complete.

## Quick command reference

```powershell
# System status
.\scripts\Verify-Sonarr-Setup.ps1
.\scripts\Debug-qBittorrent-Downloads.ps1
.\scripts\Check-Sonarr-MediaManagement.ps1
.\scripts\Check-ArrQueueStatus.ps1

# Tracker troubleshooting
.\scripts\Diagnose-TrackerSeeding.ps1        # read-only first stop
.\scripts\Sync-VpnPort.ps1 -Once             # reconcile port + interface
.\scripts\Force-Reannounce-All.ps1
```
