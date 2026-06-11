# Ebook Request System -- Phased Setup Plan

**Goal:** Add an automated ebook request system on top of the existing media stack, so
family/friends can request a book and have it searched (MyAnonamouse via Prowlarr),
downloaded (qBittorrent), imported into the Calibre library, and served by Calibre-Web --
mirroring how Sonarr/Radarr already work for TV/movies.

**Chosen stack** (decided 2026-06-11 after evaluation -- see CLAUDE.md history):
- **Backend:** `readarr-rresurrected` (maintained Readarr fork, metadata baked in, MAM built-in)
- **Calibre handoff:** standalone **Calibre Content Server** pointed at `A:\Media\Calibre`
- **Request UI:** **Libreseerr** (Overseerr-style front-end for books)
- **Deployment:** Docker Desktop on Windows for the new pieces; existing stack stays native

> This is a multi-session implementation guide. Update the **Progress Tracker** below as we go.
> Each phase has its own verification and rollback so we can stop/resume cleanly.

---

## Progress Tracker

- [ ] Phase 0 -- Prerequisites, decisions, Docker Desktop
- [ ] Phase 1 -- Calibre Content Server (the foundation)
- [ ] Phase 2 -- Deploy readarr-rresurrected container
- [ ] Phase 3 -- Wire Readarr to Prowlarr (MAM) + qBittorrent
- [ ] Phase 4 -- Wire Readarr to Calibre Content Server + first end-to-end import
- [ ] Phase 5 -- Deploy Libreseerr + users
- [ ] Phase 6 -- Hardening, backups, auto-start, docs

---

## Target Architecture

```
   Family/friends
        |
        v
  Libreseerr  (Docker, port 5000)        request UI: search + click "request"
        |  (Readarr URL + API key)
        v
  readarr-rresurrected (Docker, port 8787)
        |   indexers  <--- Prowlarr (native, 9696)  [MAM already configured]
        |   download  ---> qBittorrent (native, 8080)  [category "books", NO auto-remove]
        |   import    ---> Calibre Content Server (native, 8085)  --copies into-->  A:\Media\Calibre
        |                                                                                |
        v                                                                                v
   (request status)                                                       Calibre-Web 0.6.26 (cps, 8083)
                                                                                  -> books.mnemo.info
```

### Port map (verified free vs in-use as of 2026-06-11)
| Service | Port | State |
|---|---|---|
| qBittorrent | 8080 | in use (existing) |
| Calibre-Web (cps) | 8083 | in use (existing) |
| Sonarr / Radarr / Prowlarr | 8989 / 7878 / 9696 | in use (existing) |
| **Calibre Content Server** | **8085** | free -- assign here |
| **Readarr (rresurrected)** | **8787** | free -- container |
| **Libreseerr** | **5000** | free -- container |

NOTE: Calibre Content Server defaults to **8080**, which collides with qBittorrent. We MUST
override it to 8085.

---

## Cross-Cutting Gotchas (apply across multiple phases -- read first)

1. **Calibre single-writer rule (the #1 risk).** Only ONE process may open a Calibre library
   for *writing* at a time. Readers (Calibre-Web) are fine alongside one writer because Calibre
   uses SQLite WAL. The plan makes the **standalone Calibre Content Server the sole writer** to
   `A:\Media\Calibre`. Consequence/decision: **do not open Calibre Desktop directly on this
   library while the Content Server is running** -- instead either (a) stop the Content Server
   briefly for manual desktop work, or (b) connect Calibre Desktop to the Content Server as a
   *remote* library (Desktop -> Connect to folder/server). Pick one workflow and stick to it
   (see Phase 1 decision point).

2. **Docker-to-native networking.** Containers reach native Windows services via
   `host.docker.internal`, NOT `localhost`. So inside Readarr: Prowlarr =
   `http://host.docker.internal:9696`, qBittorrent = `http://host.docker.internal:8080`,
   Calibre Content Server = `http://host.docker.internal:8085`.

3. **Remote Path Mapping (classic -arr+Docker trap).** qBittorrent (native) reports Windows
   paths like `A:\Downloads\Books\<book>`. Readarr (container) sees the same files at a mounted
   path like `/downloads/Books/<book>`. Without a **Remote Path Mapping** in Readarr
   (Settings -> Download Clients -> Remote Path Mappings: host `host.docker.internal`, remote
   `A:\Downloads\`, local `/downloads/`), imports fail with "file not found."

4. **Calibre import = COPY, not hardlink.** Unlike Sonarr/Radarr (which hardlink within `A:\`),
   the Calibre Content Server *copies* the file into Calibre's own managed folder structure.
   So a book exists twice: the seeding torrent in `A:\Downloads\Books` + Calibre's copy in
   `A:\Media\Calibre`. For ebooks this is trivial (KB-MB). For audiobooks it is not -- another
   reason Phase 1-5 scope is **ebooks only** (see Decision D3). Readarr's hardlink/copy setting
   is irrelevant once Calibre Content Server is enabled on the root folder.

5. **Private-tracker safety (MAM).** Readarr must NOT remove completed downloads (mirror the
   Sonarr rule). Use the existing `books` qB category. Your weekly `Auto-CleanupOrphans.ps1`
   already excludes the `books` category and the `t.myanonamouse.net` tracker, so automated
   cleanup will not touch these torrents. Keep seed time >= existing 10-day minimum.

6. **MAM specifics.** MAM is strict about ratio and automated hammering. Prefer driving MAM
   through your existing **Prowlarr** sync (one place to manage the session) rather than the
   fork's built-in MAM indexer (Decision D2). Keep Readarr's RSS/automatic-search cadence
   conservative. MAM pins sessions to an IP; the container's outbound traffic uses the host IP,
   so this is fine.

7. **Docker Desktop drive sharing.** With the WSL2 backend, `A:\` is generally auto-available
   to containers; with the Hyper-V backend you must explicitly share the `A:` drive in Docker
   Desktop settings. Bind-mount performance for `A:\` is acceptable for this low-throughput use.

---

## Decision Points (confirm before / during implementation)

- **D1 -- Content Server host model:** standalone `calibre-server.exe` as an always-on
  Scheduled Task (recommended, mirrors how Calibre-Web is run) vs Calibre Desktop's built-in
  server (requires Desktop always running). **Recommended: standalone Scheduled Task.**
- **D2 -- MAM source:** Prowlarr sync (recommended, consistent with stack) vs fork's built-in
  MAM indexer.
- **D3 -- Scope:** ebooks only for v1 (recommended) vs ebooks + audiobooks. Audiobooks may be
  better served later by Audiobookshelf rather than Calibre. **Recommended: ebooks only first.**
- **D4 -- Calibre Desktop workflow** under the single-writer rule (see Gotcha 1): "stop server
  for manual edits" vs "connect Desktop as remote client." **Recommended: stop-server-for-edits**
  (simplest; manual edits are now rare since acquisition is automated).
- **D5 -- Container management:** raw `docker run` vs a single `docker-compose.yml` checked into
  this repo (recommended -- reproducible, easy to back up).

---

## Phase 0 -- Prerequisites, decisions, Docker Desktop

**Do:**
1. Confirm Decisions D1-D5 above.
2. Install **Docker Desktop for Windows** (WSL2 backend recommended). Reboot if prompted.
3. Verify drive sharing: `docker run --rm -v A:/:/test alpine ls /test` lists the A: drive root.
4. Create a repo folder `docker/ebook-stack/` to hold `docker-compose.yml` and `.env`
   (API keys go in `.env`, which must be gitignored -- consistent with `config.ps1` policy).

**Gotchas:** Docker Desktop install needs a reboot and pulls WSL2; budget time. Ensure
virtualization is enabled in BIOS (usually already on).

**Verify:** `docker --version` works; the alpine drive-mount test prints the A: contents.

**Rollback:** uninstall Docker Desktop (no impact on existing native stack).

---

## Phase 1 -- Calibre Content Server (the foundation)

This is the trickiest phase because of the single-writer rule. Do it before Readarr so the
import target exists and is proven.

**Do:**
1. Pick the Content Server port **8085** and create a server-only user with write access:
   `& "C:\Program Files\Calibre2\calibre-server.exe" --manage-users` (add e.g. user `readarr`).
2. Test-run in the foreground:
   `& "C:\Program Files\Calibre2\calibre-server.exe" --port 8085 --enable-local-write "A:\Media\Calibre"`
   (exact auth flags to be finalized during implementation; the key requirement is that writes
   require the username/password -- see Gotcha below).
3. Once proven, register it as a **Scheduled Task** (model after the existing
   `Start-CalibreWeb-Remote` task: run at logon, keep-alive). A new script
   `scripts\Start-CalibreContentServer.ps1` + `scripts\Schedule-CalibreContentServer.ps1`
   will be added (mirrors the Calibre-Web start/schedule scripts).

**Gotchas:**
- **CRITICAL:** Readarr's Calibre integration requires the content server to *require a username
  and password*. If anonymous access is allowed, Readarr import fails with
  "Anonymous users are not allowed to make changes." Configure auth + the write-enabled user.
- Enforce the single-writer rule now: while this server runs, do not open Calibre Desktop on
  `A:\Media\Calibre` (per Decision D4).
- Calibre-Web (cps) keeps reading the same on-disk library directly -- it does NOT go through
  this server, and read+single-writer is safe. No Calibre-Web change needed.

**Verify:** Browse `http://localhost:8085`, log in, see the 2,372-book library. From another
machine/the host, confirm a test `calibredb add --with-library http://localhost:8085#<lib>`
(authenticated) adds a book and it appears in Calibre-Web. Then remove the test book.

**Rollback:** stop/disable the scheduled task; nothing else touches the library.

---

## Phase 2 -- Deploy readarr-rresurrected container

**Do:**
1. Add `readarr` service to `docker/ebook-stack/docker-compose.yml`:
   ```yaml
   services:
     readarr:
       image: ricetim/readarr-rresurrected:latest
       container_name: readarr
       ports: ["8787:8787"]
       environment:
         - PUID=1000
         - PGID=1000
         - TZ=America/Chicago            # set to local TZ
         - GOOGLE_BOOKS_API_KEY=         # optional, improves edition matching
       volumes:
         - ./readarr-config:/config
         - A:/Downloads:/downloads        # so Readarr can see qB's completed books
       restart: unless-stopped
   ```
2. `docker compose up -d readarr`; open `http://localhost:8787`; set auth (Settings -> General),
   grab the Readarr API key (needed by Libreseerr later).

**Gotchas:**
- Metadata service is baked in (binds `127.0.0.1:28202` inside the container) -- nothing to wire.
- The `A:/Downloads` mount must match the Remote Path Mapping configured in Phase 3.
- Set TZ correctly or scheduled searches/logs are off.

**Verify:** Readarr UI loads; System -> Status is clean; a manual author search returns metadata
(proves the baked-in bookinfo service works).

**Rollback:** `docker compose rm -sf readarr` (config persists in `./readarr-config`).

---

## Phase 3 -- Wire Readarr to Prowlarr (MAM) + qBittorrent

**Do:**
1. **Indexers via Prowlarr:** in Prowlarr -> Settings -> Apps, add a **Readarr** app
   (URL `http://host.docker.internal:8787`, Readarr's API key). Prowlarr will push compatible
   indexers (incl. MAM, per Decision D2) into Readarr. Sync.
2. **Download client:** in Readarr -> Settings -> Download Clients, add **qBittorrent**
   (host `host.docker.internal`, port 8080, creds from `config.ps1`). Set **Category = books**.
3. **Completed Download Handling:** ensure Readarr does **NOT** remove completed downloads
   (preserve seeding -- mirror the Sonarr `removeCompletedDownloads: false` rule).
4. **Remote Path Mapping:** Readarr -> Settings -> Download Clients -> Remote Path Mappings:
   Host `host.docker.internal`, Remote Path `A:\Downloads\`, Local Path `/downloads/`.

**Gotchas:**
- Path mapping is the usual failure point -- get the trailing slashes and drive case right.
- Confirm MAM actually appears in Readarr after Prowlarr sync; if not, fall back to the fork's
  built-in MAM indexer (Decision D2 fallback) using your MAM session.
- Keep search cadence conservative for MAM (ratio safety).

**Verify:** Readarr -> System -> Health is clean. A manual search for a known book returns MAM
results. (Do not import yet -- that is Phase 4.)

**Rollback:** remove the Readarr app from Prowlarr and the download client from Readarr.

---

## Phase 4 -- Wire Readarr to Calibre + first end-to-end import

**Do:**
1. Readarr -> Settings -> Media Management -> Root Folders -> Add. Set a root folder path
   (e.g. `/calibre-library`, a mount you add to the compose file pointing wherever Calibre
   expects -- finalized in implementation), then enable **"Use Calibre Content Server"**:
   - Calibre Host: `host.docker.internal`
   - Calibre Port: `8085`
   - Calibre Username/Password: the write-enabled user from Phase 1
   - Library: select `A:\Media\Calibre`
2. Add ONE inexpensive/known book, monitor it, let Readarr search -> grab -> download in
   qBittorrent (books category) -> import via Calibre Content Server.
3. Confirm the book appears in Calibre-Web and the torrent keeps seeding in qBittorrent.

**Gotchas:**
- With Calibre integration, **Readarr does not name files** -- Calibre does. Do not fight it.
- The book is COPIED into Calibre (Gotcha 4); the seeding torrent stays in `A:\Downloads\Books`.
- If import errors with "Anonymous users not allowed," revisit Phase 1 auth.
- Watch for the single-writer rule: Calibre Desktop must be closed on this library during import.

**Verify (the key end-to-end test):** requested book shows in Calibre-Web at
`https://books.mnemo.info`, opens/downloads, AND the torrent is still seeding to MAM.

**Rollback:** delete the test book from Calibre (via Content Server) + remove the torrent; the
root folder config can stay.

---

## Phase 5 -- Deploy Libreseerr + users

**Do:**
1. Add `libreseerr` to the compose file:
   ```yaml
     libreseerr:
       image: ghcr.io/zamnzim/libreseerr:latest
       container_name: libreseerr
       ports: ["5000:5000"]
       environment:
         - PYTHONUNBUFFERED=1
         - SECRET_KEY=${LIBRESEERR_SECRET_KEY}   # from .env
       volumes:
         - ./libreseerr-data:/app/data
       restart: unless-stopped
   ```
2. `docker compose up -d libreseerr`; open `http://localhost:5000`; log in `admin`/`admin` and
   **change the password immediately**.
3. Settings -> connect the **Readarr (ebook)** instance: URL `http://host.docker.internal:8787`
   + Readarr API key + default quality profile/root folder.
4. Create user accounts for family/friends (or wire OIDC/LDAP later).

**Gotchas:**
- Libreseerr is **early-stage (v0.9.0, ~50 stars)** -- expect rough edges; keep it internal at
  first and only expose remotely (via a new Cloudflare Tunnel hostname) after it proves stable.
- Default admin/admin is a real exposure -- change before any external access.
- Decide remote-access story separately (likely a `requests.mnemo.info` tunnel hostname mirroring
  the Calibre-Web tunnel setup) -- defer to Phase 6.

**Verify:** from a non-admin Libreseerr account, request a book -> it appears in Readarr ->
flows through to Calibre-Web. Status updates show in Libreseerr.

**Rollback:** `docker compose rm -sf libreseerr` (data persists in `./libreseerr-data`).

---

## Phase 6 -- Hardening, backups, auto-start, docs

**Do:**
1. **Backups:** extend `scripts\Backup-Configs.ps1` to also archive `readarr-config`,
   `libreseerr-data`, the compose file, and the Calibre Content Server scripts.
2. **Auto-start:** Docker Desktop set to start on login + `restart: unless-stopped` covers the
   containers; the Calibre Content Server scheduled task covers the native piece.
3. **Remote access (optional):** add a Cloudflare Tunnel hostname for Libreseerr
   (e.g. `requests.mnemo.info`) only after security review; keep Readarr's UI local-only.
4. **Docs:** update `CLAUDE.md` (Technology Stack + roadmap), add start/stop/troubleshooting
   notes, and flip the Progress Tracker boxes above.

**Gotchas:**
- Do not expose Readarr externally (no auth-hardening for public use).
- Re-check that `Auto-CleanupOrphans.ps1` still excludes `books` + MAM after any category changes.

**Verify:** reboot the machine; confirm Calibre Content Server, both containers, qBittorrent,
Prowlarr, and Calibre-Web all come back and a fresh request still works end-to-end.

---

## Global Rollback (full back-out)

The existing native stack is never modified destructively, so backing out is clean:
1. `docker compose down` (removes containers; named config dirs remain for a retry).
2. Stop/disable the Calibre Content Server scheduled task.
3. Resume the current manual workflow (Download -> qB -> Calibre Desktop -> Calibre-Web).
Nothing in TV/Movies/Calibre-Web is touched by this project.

---

## Per-Session Resumption Notes

- Always check the **Progress Tracker** first to see where we stopped.
- Secrets (Readarr API key, qB creds, Libreseerr secret, MAM session) live in
  `docker/ebook-stack/.env` and `config.ps1` -- both gitignored.
- The single-writer Calibre rule (Gotcha 1 / Decision D4) is the thing most likely to cause
  confusing failures across sessions -- re-confirm Calibre Desktop is closed on the library
  before any import test.
