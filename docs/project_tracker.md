# Plex Media Server & Automation Project Tracker

## Project Overview
**Goal:** Transform basic Plex server into fully automated media management system
**Timeline:** Phased approach - basic functionality first, then automation features
**Current Status:** Phase 3 - TV automation complete (Sonarr + qBittorrent), Phase 3.5 - Ebook management in progress (Calibre)

---

## PHASE 1: BASIC PLEX SERVER âœ…ðŸ”„
*Priority: HIGH - Foundation for everything else*

### Hardware Setup âœ…
- [x] Dell OptiPlex 7040 MT acquired and configured
- [x] Windows 11 fresh installation
- [x] BIOS configuration (AHCI, boot order)
- [x] System testing completed
- [x] WD Ultrastar 6TB drive ordered

### Storage Implementation ðŸ”„
- [x] **WAITING:** Drive delivery (ETA: few days)
- [x] Physical drive installation
- [x] Drive initialization and formatting
- [x] Test drive performance and health
- [ ] Plan future RAID 1 expansion (second 6TB drive)

### Basic Plex Setup ðŸ”„
- [x] Download Plex Media Server installer
- [x] Install Plex Media Server
- [x] Initial Plex configuration
- [x] Create basic library structure (Movies, TV Shows, Music)
- [x] Test local network streaming
- [x] Verify hardware transcoding (Quick Sync)

### Media Migration ðŸ”„
- [x] Plan folder structure on new drive
- [x] Transfer existing media library
- [x] Update Plex library paths
- [ ] Re-scan and verify all content

**Phase 1 Success Criteria:** Plex server operational with expanded storage, streaming reliably to local devices

---

## PHASE 2: RESEARCH & PLANNING ðŸ“‹
*Priority: MEDIUM - Can be done while Phase 1 is completing*

### Automation Tools Research ðŸ”„
- [ ] **Research Sonarr:** TV show automation features and requirements
- [ ] **Research Radarr:** Movie automation features and requirements
- [ ] **Research Prowlarr:** Indexer management benefits
- [ ] **Research Bazarr:** Subtitle automation value
- [ ] **Research Overseerr:** Family request management
- [ ] **Research Tautulli:** Monitoring and analytics features

### Indexer Research ðŸ“‹
- [ ] **Understand indexer types:** Public vs Private vs Usenet
- [ ] **Research legal considerations** for your jurisdiction
- [ ] **Evaluate Usenet providers** (if interested in that route)
- [ ] **Research VPN options** for privacy
- [ ] **Identify starter indexers** for testing

### Download Client Research ðŸ“‹
- [ ] **Compare qBittorrent vs Deluge** for torrent management
- [ ] **Research SABnzbd vs NZBGet** for Usenet (if applicable)
- [ ] **Plan download storage** (separate from media storage)
- [ ] **Understand seeding requirements** and ratio management

### Technical Planning ðŸ“‹
- [ ] **Plan VM vs Docker vs Windows install** for arr applications
- [ ] **Research resource requirements** for all applications
- [ ] **Plan network configuration** and port management
- [ ] **Design folder structure** for downloads vs final media

---

## PHASE 3: BASIC AUTOMATION ðŸ“‹
*Priority: MEDIUM - Start simple with core functionality*

### Core Arr Applications ðŸ“‹
- [ ] **Install Prowlarr** (indexer management)
- [ ] **Install Sonarr** (TV show automation)
- [ ] **Install Radarr** (movie automation)
- [ ] **Install download client** (qBittorrent or SABnzbd)

### Basic Configuration ðŸ“‹
- [ ] **Configure Prowlarr** with initial indexers
- [ ] **Connect Sonarr to Prowlarr** and download client
- [ ] **Connect Radarr to Prowlarr** and download client
- [ ] **Set up basic quality profiles** in Sonarr/Radarr
- [ ] **Configure folder monitoring** and file management
- [ ] **Test basic automation** with a few titles

### Integration Testing ðŸ“‹
- [ ] **Test TV show automation** end-to-end
- [ ] **Test movie automation** end-to-end
- [ ] **Verify Plex integration** (automatic detection)
- [ ] **Monitor system resources** during operation

---

## PHASE 3.5: EBOOK MANAGEMENT ðŸ"„
*Priority: MEDIUM - Expanding media automation to books*

### Calibre Setup & Library Standardization âœ…
- [x] **Install Calibre** desktop application
- [x] **Initial import** of existing ebooks from `A:\Media\Literature\`
- [x] **Analyze current library structure** and identify inconsistencies
- [x] **Create backup** of original Literature directory
- [x] **Standardize folder structure** - Let Calibre manage organization
- [x] **Re-import cleaned library** into Calibre at `A:\Media\Calibre`
- [x] **Configure Calibre preferences** (library location, metadata sources)
- [x] **Cleanup duplicates and metadata issues**
- [x] **Verify torrents still seeding** after migration

### Calibre-Web Integration âœ…
- [x] **Research Calibre-Web** installation options (Docker vs Windows)
- [x] **Install Calibre-Web** via Python/pip (native Windows)
- [x] **Configure Calibre-Web** to connect to Calibre library
- [x] **Test web interface** functionality at http://localhost:8083
- [x] **Document manual import workflow** for adding new books

### Readarr Automation ðŸ"‹
- [ ] **Research Readarr** features and MyAnonamouse integration
- [ ] **Install Readarr** for ebook automation
- [ ] **Connect Readarr to Prowlarr** (MyAnonamouse indexer)
- [ ] **Connect Readarr to qBittorrent** (`books` category)
- [ ] **Configure quality profiles** for ebook formats (EPUB, MOBI, AZW3)
- [ ] **Set up Calibre integration** in Readarr
- [ ] **Test automated ebook acquisition** with manual search

### Audiobook Consideration ðŸ"‹
- [ ] **Research audiobook management** options (Audiobookshelf, Booksonic)
- [ ] **Evaluate Readarr audiobook support**
- [ ] **Plan audiobook folder structure** separate from ebooks
- [ ] **Consider Plex audiobook library** vs dedicated solution

**Phase 3.5 Success Criteria:** Calibre managing clean, standardized ebook library with web access via Calibre-Web; Readarr automating new ebook acquisitions from MyAnonamouse

---

## PHASE 4: ADVANCED AUTOMATION ðŸ"‹
*Priority: LOW - Polish and convenience features*

### Enhanced Features ðŸ“‹
- [ ] **Install Bazarr** for subtitle automation
- [ ] **Install Overseerr** for request management
- [ ] **Install Tautulli** for Plex monitoring
- [ ] **Install Organizr** for unified dashboard

### Advanced Configuration ðŸ“‹
- [ ] **Fine-tune quality profiles** based on experience
- [ ] **Set up custom release group preferences**
- [ ] **Configure upgrade policies** (720p â†’ 1080p)
- [ ] **Set up user management** in Overseerr
- [ ] **Configure notifications** (Discord, email, etc.)

### Optimization ðŸ“‹
- [ ] **Monitor and optimize performance**
- [ ] **Set up automated backups** of configurations
- [ ] **Document your setup** for future reference
- [ ] **Plan redundancy** (second drive for RAID 1)

---

## DECISION POINTS & RESEARCH ITEMS

### Critical Decisions Needed:
1. **Indexer Strategy:** Public torrents vs Usenet vs Private trackers
2. **Download Method:** Torrents vs Usenet (affects client choice)
3. **Installation Method:** Windows apps vs Docker vs VM
4. **VPN Strategy:** Which provider, always-on vs selective

### Research Tasks:
- [ ] **Legal research** for your jurisdiction regarding automation tools
- [ ] **Cost analysis** of Usenet vs torrent approach
- [ ] **Performance impact** of automation tools on your hardware
- [ ] **Backup strategy** for both media and configurations

---

## RESOURCES & BOOKMARKS

### Documentation:
- [ ] Bookmark official Sonarr/Radarr documentation
- [ ] Save quality setup guides and best practices
- [ ] Collect troubleshooting resources

### Communities:
- [ ] Join relevant Reddit communities (r/sonarr, r/radarr, r/PleX)
- [ ] Find Discord servers for real-time help

---

## NOTES & LESSONS LEARNED
*Use this section to track discoveries, gotchas, and configuration details*

**Hardware Notes:**
- Dell OptiPlex 7040 MT specs confirmed
- Quick Sync hardware transcoding available
- Power and SATA connections available for additional drives

**Performance Notes:**
- (To be filled as you test)

**Configuration Notes:**
- (To be filled as you configure)

---

**Last Updated:** [Date]
**Next Review:** [Date]