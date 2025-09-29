# Hardware Configuration - Dell OptiPlex 7040 MT

## System Overview
**Model:** Dell OptiPlex 7040 Micro Tower (MT)
**Installation Date:** [Date of setup]
**Primary Purpose:** Plex Media Server with automation tools

---

## Hardware Specifications

### Processor
- **CPU:** Intel Core i5-6500 @ 3.20GHz (Skylake, 6th Gen)
- **Cores:** 4 cores, 4 threads
- **Base Clock:** 3.20GHz
- **Architecture:** x64
- **Features:** Intel Quick Sync Video hardware transcoding support
- **Performance Notes:** Excellent for Plex transcoding via Quick Sync

### Memory
- **RAM:** 8GB DDR4-3200 (single stick)
- **Type:** DDR4
- **Speed:** 3200 MHz
- **Configuration:** 1x 8GB stick
- **Upgrade Potential:** Supports up to 32GB (2x16GB or 4x8GB)

### Storage Configuration

#### Primary Drive (OS)
- **Model:** Intel SSD (SSDSC2BP480G4)
- **Type:** SATA SSD
- **Capacity:** 480GB
- **Purpose:** Windows 10 Pro, applications, system files
- **Drive Letter:** C:\

#### Media Drive (Expanded Storage)
- **Model:** HGST HUS726T6TALE6L4 (6TB Enterprise)
- **Type:** Enterprise-grade 7200 RPM HDD
- **Capacity:** 6TB
- **Installation Date:** [Date installed]
- **Drive Letter:** F:\ (or as configured)
- **Purpose:** Primary media storage for Plex library
- **Performance:** ~200+ MB/s sequential read/write
- **Health Status:** Excellent (new/refurbished)
- **Power-on Hours:** [Initial hours at installation]

#### Future Expansion
- **RAID 1 Plan:** Second HGST 6TB for redundancy
- **Available SATA Ports:** [Number remaining]
- **Available Power Connectors:** [Number remaining]

### Graphics
- **GPU:** Intel HD Graphics (integrated)
- **Hardware Transcoding:** Intel Quick Sync Video
- **Supported Codecs:** H.264, H.265/HEVC
- **Performance:** Excellent for Plex hardware transcoding
- **Current Status:** Not needed - all devices direct play

### Network
- **Ethernet:** Gigabit Ethernet (built-in)
- **Wi-Fi:** [If available - check specs]
- **Network Performance:** Sufficient for local streaming

### Power Supply
- **Type:** [PSU specification]
- **Capacity:** [Wattage]
- **Additional Drive Support:** Confirmed available SATA power connectors

---

## BIOS/UEFI Configuration

### Current Settings
- **SATA Mode:** AHCI (confirmed)
- **Boot Order:** [Current configuration]
- **Intel Quick Sync:** Enabled (default)
- **Secure Boot:** [Status]
- **Legacy Boot:** [Status]

### Optimal Settings for Media Server
- ✅ SATA Mode: AHCI
- ✅ Intel Graphics: Enabled (for Quick Sync)
- ✅ Power Management: Optimized for performance

---

## Operating System

### Windows 10 Pro Configuration
- **Edition:** Windows 10 Pro
- **Version:** 2009 (20H2)
- **Installation:** Fresh install (clean)
- **Updates:** Current as of system setup

### Power Management
- **Power Plan:** High Performance (recommended for media server)
- **Sleep Settings:** Disabled (for 24/7 operation)
- **USB Selective Suspend:** Disabled

---

## Network Configuration

### Local Network Setup
- **IP Address:** 10.0.0.73 (consider setting static)
- **Subnet:** [Network configuration]
- **Gateway:** [Router IP]
- **DNS:** [Primary/Secondary DNS]

### Port Configuration
- **Plex Media Server:** 32400 (default)
- **Remote Access:** [Enabled/Disabled]
- **Future Automation Ports:** [To be documented during Phase 3]

---

## Performance Characteristics

### Plex Media Server Performance
- **Direct Play:** ✅ Confirmed working
- **Transcoding Method:** Software (sufficient for current needs)
- **Hardware Transcoding:** Available via Quick Sync (Plex Pass required)
- **Concurrent Streams:** [Test results to be documented]

### Storage Performance
- **Media Drive Read Speed:** ~200+ MB/s (sufficient for 4K streaming)
- **Network Streaming:** No bottlenecks observed
- **Boot Time:** [To be documented]

---

## Expansion Capabilities

### Storage Expansion
- **Additional SATA Drives:** [Number of available slots]
- **RAID Support:** Software RAID via Windows Storage Spaces
- **Recommended Next Drive:** Matching WD Ultrastar 6TB for RAID 1

### Memory Expansion
- **Current RAM:** 8GB DDR4-3200
- **Maximum Supported:** 32GB (OptiPlex 7040 limit)
- **Recommended for Automation:** 16GB minimum for full automation stack
- **Upgrade Path:** Add second 8GB stick for 16GB dual-channel

### Future Upgrades
- **SSD Upgrade:** Consider SSD for OS drive if currently HDD
- **Network:** Already optimal (Gigabit Ethernet)
- **Cooling:** Monitor temperatures during heavy automation workloads

---

## Automation Tool Requirements

### Resource Planning
- **Current Usage:** Minimal (Plex only)
- **Phase 3 Tools:** Sonarr, Radarr, Prowlarr, qBittorrent
- **Estimated Additional RAM:** 2-4GB for full automation stack
- **Estimated Additional CPU:** 10-20% during active downloads

### Docker Considerations
- **Docker Desktop:** Compatible with Windows 11
- **WSL2 Backend:** Available for Linux containers
- **Resource Allocation:** Plan 4-6GB RAM for Docker if used

---

## Maintenance Schedule

### Weekly
- [ ] Check drive temperatures via CrystalDiskInfo
- [ ] Monitor system resource usage
- [ ] Verify Plex service status

### Monthly
- [ ] Check for Windows updates
- [ ] Review drive health reports
- [ ] Clean temporary files and logs

### Quarterly
- [ ] Full system backup
- [ ] Review automation tool performance
- [ ] Plan storage expansion if needed

---

## Troubleshooting Reference

### Common Issues
- **Drive Not Detected:** Check SATA connections, verify AHCI mode
- **Poor Streaming Performance:** Check network, verify direct play
- **High CPU Usage:** Identify transcoding vs automation overhead

### Monitoring Tools
- **Drive Health:** CrystalDiskInfo
- **System Performance:** Task Manager, Resource Monitor
- **Network:** Built-in Windows network tools

---

**Last Updated:** [Current date]
**Configuration Verified:** [Date of last verification]
**Next Hardware Review:** [Scheduled date]