# CLAUDE.md

Operating manual for working in this repository (Claude Code and humans alike).
For a project overview, stack, and status see [`README.md`](README.md); for the
full per-script catalog see [`scripts/README.md`](scripts/README.md).

## Project Overview

Plex Media Server automation stack on Windows (PowerShell, no Docker). Phased
approach tracked in `docs/project_tracker.md`.

**Status (2026-06-11):** TV (Sonarr), movies (Radarr), indexers (Prowlarr), and
ebooks (Calibre + Calibre-Web, remote access + Send-to-Kindle) are all operational.
qBittorrent runs behind ProtonVPN with automated NAT-PMP port forwarding. **Next:**
automated ebook acquisition + request system -- plan in
`docs/Ebook_Request_System_Setup_Plan.md`.

## Repository Map

- `scripts/` -- active automation scripts (catalog: `scripts/README.md`); `scripts/setup/` one-time installers; `scripts/Archive/` historical
- `.claude/skills/` -- slash-command runbooks (see Scripts & Skills below)
- `configs/` -- config templates and the Calibre tag taxonomy
- `templates/` -- reusable *arr config templates
- `docs/` -- setup guides, plans, decision records (`docs/Archive/` completed)
- `data/`, `logs/` -- runtime data and logs (gitignored)
- `config.ps1` -- all credentials (gitignored; copy from `config.ps1.template`)

## System Configuration

### Media Storage Structure
- **TV Shows**: `A:\Media\TV Shows\` -- final library (hardlinked from downloads)
- **Movies**: `A:\Media\Movies\` -- final library (hardlinked from downloads)
- **TV Downloads**: `A:\Downloads\TV\` -- active torrent seeding location
- **Movie Downloads**: `A:\Downloads\Movies\`
- **Books Downloads**: `A:\Downloads\Books\` -- ebook/audiobook download seeding
- **Calibre Library**: `A:\Media\Calibre` (~2,370 books, source for Calibre-Web)
- **Incomplete**: `A:\Downloads\Incomplete\` -- qBittorrent temp download location

### Key Configuration Details
- **Hardlinks**: Enabled in Sonarr/Radarr (`copyUsingHardlinks: true`) -- files exist in both download and media locations but consume disk space once. **Only works within the same drive** -- everything is on `A:\` so it works.
- **qBittorrent Auto TMM**: Enabled -- category save paths work automatically. Categories: `tv-sonarr` -> `A:\Downloads\TV`, `movie-radarr` -> `A:\Downloads\Movies`, `books` -> `A:\Downloads\Books`.
- **Quality Profile**: Conservative HD-1080p (prefers/cutoff at WEBDL-1080p) -- avoids endless upgrading and ratio drain.
- **Naming Convention**: `{Series Title} - S{season:00}E{episode:00} - {Episode Title}` (Plex standard).

### Private Tracker Safety (critical)
- **Never remove completed downloads** in *arr apps -- `removeCompletedDownloads: false`. Files must stay in qBittorrent for seeding.
- **Minimum seed time: 10 days** in qBittorrent (cleanup scripts default to 21).
- Trackers: TorrentDay, TorrentLeech, Darkpeers, MyAnonamouse. MAM (`t.myanonamouse.net`) is excluded from all automated cleanup.
- Ratio monitoring is currently manual -- check tracker stats weekly. Autobrr is a future enhancement.
- Cleanup scripts protect hardlinked Media copies and always skip books/audiobooks/music; deletions require explicit `-Execute`.

## Credential Management

**IMPORTANT**: this project stores all secrets in `config.ps1`.

- **`config.ps1`** -- all API keys and passwords (gitignored, never committed).
- **`config.ps1.template`** -- placeholders (committed). Copy it to `config.ps1` and fill in.
- **Scripts load credentials from `config.ps1`** by dot-sourcing it -- never hardcode keys in a script. Pattern:
  ```powershell
  . (Join-Path $PSScriptRoot "..\config.ps1")
  ```
- API keys were regenerated 2025-10-28 (older keys in git history are invalid).
- Full guide: `docs/Credential_Management_Guide.md`.

## Scripts & Skills

The full script catalog with usage lives in **`scripts/README.md`**. Folder layout:
`scripts/` (active) · `scripts/setup/` (one-time installers) · `scripts/Archive/`
(historical -- do not run blindly).

**Slash-command skills** (`.claude/skills/`) wrap multi-step workflows with the
correct sequence and safety checks -- prefer them for these tasks:
- `/diagnose-seeding` -- qB shows "seeding" but trackers don't credit you (diagnose -> `Sync-VpnPort` -> reannounce)
- `/deep-clean-torrents` -- reclaim disk by removing hardlink-orphan downloads (routine `Auto-CleanupOrphans` vs manual stage-by-stage)
- `/tag-new-books` -- apply the standardized Calibre taxonomy to new imports (or full-library cleanup)
- `/fix-download-paths` -- qB saving to the wrong folder (Auto-TMM diagnose -> enable -> verify)

## Common Issues & Troubleshooting

Root-cause reference. For the step-by-step fixes, use the matching skill above.

### Downloads land in the wrong folder
**Cause:** Auto-TMM not enabled, so qBittorrent ignores the category save path that
Sonarr/Radarr send via API and uses the global default. **Fix:** enable Auto-TMM
(`auto_tmm_enabled = true` AND `torrent_changed_tmm_enabled = true`) via
`Enable-qBittorrent-AutoTMM.ps1`. -> `/fix-download-paths`.

### qB shows "seeding" but trackers don't credit me
**Cause:** a ProtonVPN reconnect breaks two things at once -- the forwarded port
rotates, AND the tunnel interface renumbers (friendly name stays `ProtonVPN` but the
`iftype53_NNNNN` value changes), leaving qB bound to a dead interface. Normally the
`Sync-VpnPort` scheduled task reconciles both every ~45s via NAT-PMP. **Fix:**
`/diagnose-seeding`. **Never rebind while the VPN is down** (IP leak) -- the stale
binding is the safe state. Mechanism: `docs/QBITTORRENT_VPN_BINDING.md`.

### Hardlinks producing copies instead of links
**Cause:** source and destination on different drives. Everything must stay on `A:\`.
Verify with `Check-Sonarr-MediaManagement.ps1`.

### Prowlarr indexers out of sync
Resync with `Sync-Prowlarr-Indexers.ps1`; verify with `Verify-Sonarr-Setup.ps1`.

## Best Practices & Lessons Learned

### qBittorrent
1. **Always enable Auto-TMM** for category-based save paths to work.
2. **One category per *arr app** (`tv-sonarr`, `movie-radarr`, `books`).
3. **Never remove completed downloads** in *arr apps on private trackers.

### Sonarr / Radarr
1. **Use hardlinks** when downloads and media share a drive (saves space, keeps seeds).
2. **Category assignment is automatic** -- the *arr app sets it when sending to qBittorrent.
3. **Conservative quality cutoffs** avoid endless upgrading and ratio drain.
4. **Test with manual search first** before enabling automatic searching.

### Security
- All credentials via `config.ps1`; scripts dot-source it, never hardcode keys.
- Use `.template` files to keep secrets out of git.

### Development workflow
1. **Use diagnostic (`Debug-*` / `Check-*` / `Diagnose-*`) scripts** to understand current state before changing anything.
2. **Dry-run first** -- destructive scripts default to dry run and require `-Execute`. Show the user the dry-run output and confirm before executing.
3. **Document config changes** in comments and commit messages.

## PowerShell Scripting Gotchas

These have caused repeated failures when writing `.ps1` scripts here. Check before debugging.

### 1. Bash eats `$` variables in `-Command` strings
Running `powershell -Command "... $var ..."` from bash causes bash to interpolate `$var` before PowerShell sees it.
**Fix:** Write scripts to a `.ps1` file and run with `-File`. If using `-Command`, escape every `$` as `\$`.

### 2. Pipe `|` inside string literals breaks PS5.1 parser
Using `|` inside a string that is part of a concatenation or `-f` format expression causes "Expressions are only allowed as the first element of a pipeline".
**Fix:** Never use `|` as a visual separator in display strings. Use `--`, `//`, or spaces instead.

### 3. Non-ASCII characters cause cascading parse errors
PowerShell 5.1 reads `.ps1` files as Windows-1252 by default (no BOM). The UTF-8 bytes for an em-dash (`—`, U+2014) include byte `0x94`, which is a right curly-quote in Windows-1252 — PS5.1 treats it as a string terminator, causing "missing terminator" errors many lines later.
**Fix:** Keep all `.ps1` files pure ASCII. Use `--` instead of `—`, straight quotes instead of curly quotes. Diagnose with:
```powershell
$text = [System.IO.File]::ReadAllText('script.ps1')
($text -split '\n') | ForEach-Object -Begin { $i=0 } -Process {
    $i++; $j=0
    $_.ToCharArray() | ForEach-Object { $j++; if ([int]$_ -gt 127) { Write-Host "Line $i char $j : U+$([int]$_.ToString('X4'))" } }
}
```

### 4. Pre-creating a WebRequestSession conflicts with `-SessionVariable`
Using `New-Object Microsoft.PowerShell.Commands.WebRequestSession` before passing `-SessionVariable session` causes a null reference exception.
**Fix:** Remove the `New-Object` line. Let `-SessionVariable` create the variable, then reference it with `$` in later calls:
```powershell
Invoke-WebRequest -Uri $loginUrl -SessionVariable qbSession | Out-Null
Invoke-RestMethod -Uri $apiUrl -WebSession $qbSession
```

### 5. `[byte] -shl` overflows within the 8-bit type and silently yields 0
When assembling a multi-byte integer from a `byte[]` (e.g. parsing a NAT-PMP response), shifting a `[byte]` left by 8 or more bits drops the shifted bits because the operand stays a byte: `[byte]0xEF -shl 8` is `0`, not `61184`. You silently read only the low byte (e.g. port `61391` parses as `207`).
**Fix:** Cast each byte to `[int]` (or `[uint32]` for wider fields) before shifting:
```powershell
$port = ([int]$resp[10] -shl 8) -bor [int]$resp[11]   # correct
```
Diagnose by dumping the raw hex and hand-computing one value. Used in `scripts\Sync-VpnPort.ps1`.

## Key Documentation

- `docs/project_tracker.md` -- phase breakdown and task tracking
- `docs/Ebook_Request_System_Setup_Plan.md` -- multi-session plan for automated ebook acquisition (the active "Next" work)
- `docs/QBITTORRENT_VPN_BINDING.md` -- ProtonVPN port/interface auto-sync mechanism
- `docs/Credential_Management_Guide.md` -- credential/security guide
- `docs/Sonarr_Setup_Guide.md`, `docs/Radarr_Setup_Guide.md`, `docs/Prowlarr_Configuration.md` -- service setup
- `docs/Calibre-Web_Remote_Access_Guide.md`, `docs/Calibre_Tag_Management_Guide.md` -- ebook stack
