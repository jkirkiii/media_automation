# Media Automation

A Plex Media Server automation stack for Windows, built around the *arr
applications, qBittorrent, and Calibre. It turns a basic Plex server into a
largely hands-off media management system: automatic TV/movie acquisition,
private-tracker-safe seeding, an ebook library with remote access and
Send-to-Kindle, and scheduled maintenance.

> **Working in this repo (with or without Claude Code)?** Read
> [`CLAUDE.md`](CLAUDE.md) for the operational conventions: storage paths, config
> facts, private-tracker safety rules, the credential pattern, and the
> hard-won PowerShell gotchas. The full per-script catalog is in
> [`scripts/README.md`](scripts/README.md).

## Current status

| Phase | Status |
|---|---|
| Plex + storage | ✅ Operational |
| TV automation (Sonarr) | ✅ Operational |
| Movie automation (Radarr) | ✅ Operational |
| Indexers (Prowlarr) | ✅ Operational |
| Ebooks (Calibre + Calibre-Web, remote + Send-to-Kindle) | ✅ Operational |
| Automated ebook acquisition + request system | 🔜 In planning |

Stack versions current as of 2026-06-11: **Calibre 9.9.0**, **Calibre-Web 0.6.26**,
**Sonarr v4.0.15**. Detailed phase tracking lives in
[`docs/project_tracker.md`](docs/project_tracker.md).

## Technology stack

**Deployed**
- **Plex Media Server** -- media server (Windows)
- **Sonarr** (`:8989`) -- TV automation
- **Radarr** (`:7878`) -- movie automation
- **Prowlarr** (`:9696`) -- indexer manager
- **qBittorrent** (`:8080`) -- download client (behind ProtonVPN with NAT-PMP port forwarding)
- **Calibre 9.9.0** + **Calibre-Web 0.6.26** (`:8083`) -- ebook library (~2,370 books at `A:\Media\Calibre`)
- **Cloudflare Tunnel** -- remote ebook access at https://books.mnemo.info
- **Private trackers:** TorrentDay, TorrentLeech, Darkpeers, MyAnonamouse

**Planned / under consideration**
- Automated ebook acquisition + request UI (evaluating Readarr forks / LazyLibrarian + Libreseerr)
- Autobrr (ratio-aware automation), Bazarr (subtitles), Tautulli (monitoring)
- Possible Docker Compose migration

## Repository layout

```
.
├── CLAUDE.md            # Operating manual: conventions, safety rules, gotchas (read first)
├── README.md           # This file
├── config.ps1          # All credentials (gitignored; copy from config.ps1.template)
├── scripts/            # Automation scripts -- see scripts/README.md for the full catalog
│   ├── setup/          # One-time installers (kept for disaster recovery)
│   └── Archive/        # Superseded / one-off scripts (historical)
├── configs/            # Config templates & tag taxonomy
├── templates/          # Reusable *arr config templates
├── docs/               # Setup guides, plans, and decision records
│   └── Archive/         # Completed-phase / historical docs
├── .claude/skills/     # Slash-command runbooks (/diagnose-seeding, etc.)
├── data/               # Runtime data (gitignored)
└── logs/               # Application logs (gitignored)
```

## Quick start

1. **Credentials** -- copy the template and fill in your values:
   ```powershell
   Copy-Item config.ps1.template config.ps1
   # edit config.ps1 -- API keys, qBittorrent/Calibre-Web creds, SMTP
   ```
   `config.ps1` is gitignored and never committed. Details:
   [`docs/Credential_Management_Guide.md`](docs/Credential_Management_Guide.md).

2. **Verify the stack** is reachable:
   ```powershell
   .\scripts\Verify-Sonarr-Setup.ps1
   .\scripts\Debug-qBittorrent-Downloads.ps1
   ```

3. **Common operations** -- see [`scripts/README.md`](scripts/README.md) for the
   full catalog, or use the Claude Code slash-command skills:

   | Skill | Use when |
   |---|---|
   | `/diagnose-seeding` | qB shows "seeding" but trackers don't credit you |
   | `/deep-clean-torrents` | Reclaim disk by removing hardlink-orphan downloads |
   | `/tag-new-books` | Apply the standard Calibre taxonomy to new imports |
   | `/fix-download-paths` | qB saving downloads to the wrong folder |

## Documentation

- [`CLAUDE.md`](CLAUDE.md) -- operating manual / conventions (start here for any work)
- [`scripts/README.md`](scripts/README.md) -- full script catalog
- [`docs/project_tracker.md`](docs/project_tracker.md) -- phase breakdown and task tracking
- [`docs/Ebook_Request_System_Setup_Plan.md`](docs/Ebook_Request_System_Setup_Plan.md) -- multi-session plan for automated ebook acquisition
- [`docs/QBITTORRENT_VPN_BINDING.md`](docs/QBITTORRENT_VPN_BINDING.md) -- ProtonVPN port/interface auto-sync mechanism
- [`docs/Sonarr_Setup_Guide.md`](docs/Sonarr_Setup_Guide.md) · [`docs/Radarr_Setup_Guide.md`](docs/Radarr_Setup_Guide.md) · [`docs/Prowlarr_Configuration.md`](docs/Prowlarr_Configuration.md)
- [`docs/Calibre-Web_Remote_Access_Guide.md`](docs/Calibre-Web_Remote_Access_Guide.md) · [`docs/Calibre_Tag_Management_Guide.md`](docs/Calibre_Tag_Management_Guide.md)

## External resources

[Servarr Wiki](https://wiki.servarr.com/) ·
[TRaSH Guides](https://trash-guides.info/) ·
[qBittorrent Web API](https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)) ·
[Autobrr](https://autobrr.com/) ·
[Calibre-Web](https://github.com/janeczku/calibre-web)
