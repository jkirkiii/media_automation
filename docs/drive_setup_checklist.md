# Drive Setup and Health Check Checklist

## Overview
This checklist covers proper installation and testing procedures for new/refurbished drives in your Plex media server system. Follow these steps for each additional drive to ensure reliability and optimal performance.

---

## Physical Installation

### Pre-Installation Checklist
- [ ] **Power down system completely** and unplug power cable
- [ ] **Ground yourself** by touching the case before handling drives
- [ ] **Verify available mounting bays** and SATA connections
- [ ] **Check for existing unused SATA cables** (may be pre-connected to motherboard)

### Hardware Installation Steps
1. **Mount drive in 3.5" bay** using proper drive mounting screws
2. **Connect SATA data cable** to motherboard (use SATA III ports when available)
3. **Connect SATA power cable** from PSU to drive
4. **Verify cable routing** doesn't obstruct airflow or fans
5. **Secure all connections** and close case

### BIOS Verification
- [ ] Boot into BIOS/UEFI setup
- [ ] Navigate to **System Configuration > Drives** (or equivalent)
- [ ] **Verify drive is detected** on appropriate SATA port
- [ ] **Note drive model/serial** for documentation
- [ ] **Confirm SATA mode is AHCI** (not IDE)

---

## Drive Health Assessment

### 1. Health Status Check (5-10 minutes)
**Tool:** CrystalDiskInfo (free download)

**What to Check:**
- [ ] **Overall health status** should show "Good" (avoid Yellow/Red warnings)
- [ ] **Power-on hours** (acceptable ranges):
  - New drives: 0-100 hours
  - Refurbished enterprise: Under 30,000 hours is reasonable
  - Refurbished consumer: Under 20,000 hours preferred
- [ ] **Reallocated sectors** should be 0 or very low numbers
- [ ] **Pending sectors** should be 0
- [ ] **Temperature** should be within normal operating range

**Red Flags to Watch For:**
- Health status showing "Caution" or "Bad"
- High reallocated or pending sector counts
- Unusually high power-on hours for drive type

### 2. Performance Baseline (10-15 minutes)
**Tool:** CrystalDiskMark (free download)

**Test Configuration:**
- [ ] Run **3 sequential tests** at 1GB each
- [ ] Focus on **sequential read speeds** (most important for media)
- [ ] Note both **read and write performance**

**Expected Performance (SATA III):**
- **Modern 7200 RPM drives:** 150-200+ MB/s sequential
- **Enterprise drives (WD Ultrastar, etc.):** 200+ MB/s sequential
- **5400 RPM drives:** 100-150 MB/s sequential

**Note:** Drive must be formatted with a drive letter for CrystalDiskMark to detect it.

### 3. Surface Scan (Optional - 4-8 hours)
**Recommended for:** Refurbished drives, drives with questionable history, or when maximum reliability is critical.

**Tools:**
- **HD Tune** (free version) - Benchmark tab > Error Scan
- **Windows chkdsk** - Command: `chkdsk /f /r [drive letter]:`

**When to Run:**
- Can be done after formatting while setting up other components
- Schedule during downtime (very time-consuming for large drives)
- Consider skipping if health check shows excellent status

---

## Drive Initialization and Formatting

### Windows Disk Management Setup
1. **Open Disk Management**
   - Right-click "This PC" → "Manage" → "Disk Management"
   - OR Windows + X → "Disk Management"

2. **Initialize Disk (if prompted)**
   - **Always choose GPT** for drives >2TB
   - **Choose MBR** only for drives <2TB and compatibility needs

3. **Convert to GPT (if needed)**
   - Right-click disk number → "Convert to GPT Disk"
   - If grayed out, use Diskpart method (see troubleshooting section)

4. **Create Partition**
   - Right-click unallocated space → "New Simple Volume"
   - **Size:** Maximum available space
   - **Drive letter:** Choose meaningful letter (F: for media, etc.)
   - **File system:** NTFS
   - **Allocation unit size:** Default (4096 bytes)
   - **Volume label:** Descriptive name (e.g., "PLEX-MEDIA-02")
   - **Compression:** **DO NOT ENABLE** for media drives

### Recommended Folder Structure
Create immediately after formatting:
```
[Drive Letter]:\
├── Media\
│   ├── Movies\
│   ├── TV Shows\
│   ├── Music\
│   └── Other\
├── Downloads\
│   ├── Complete\
│   ├── Incomplete\
│   └── Watch\
└── Backups\
    └── Configs\
```

---

## Documentation and Record Keeping

### Drive Information to Record
- [ ] **Drive model and serial number**
- [ ] **Installation date**
- [ ] **SATA port used** (SATA-0, SATA-1, etc.)
- [ ] **Initial power-on hours** (from CrystalDiskInfo)
- [ ] **Performance baseline results** (sequential read/write speeds)
- [ ] **Drive letter assigned**
- [ ] **Volume label used**

### Create Drive Inventory
Keep a simple spreadsheet or document with:
```
Drive | Model | Serial | Install Date | SATA Port | Hours | Drive Letter | Notes
------|-------|--------|--------------|-----------|-------|--------------|-------
1     | WD6003FRYZ | ABC123 | 2025-09-27 | SATA-3 | 15,729 | F: | Primary media
2     | [Future] | | | | | | 
```

---

## Troubleshooting Common Issues

### Drive Not Detected in BIOS
- [ ] Verify SATA data cable connection at both ends
- [ ] Try different SATA port on motherboard
- [ ] Test SATA cable with known working drive
- [ ] Ensure SATA power connector is fully seated

### Drive Not Appearing in Windows
- [ ] Check Disk Management - may need initialization
- [ ] Verify drive shows as "Healthy" in Disk Management
- [ ] If showing as "Foreign" or "Dynamic," convert to basic disk

### Cannot Convert to GPT
- [ ] Use Diskpart method:
  ```cmd
  diskpart
  list disk
  select disk X
  clean
  convert gpt
  exit
  ```
- [ ] Refresh Disk Management (F5) after Diskpart

### Poor Performance Results
- [ ] Verify SATA III connection (not SATA I/II)
- [ ] Check for background processes during test
- [ ] Ensure drive isn't running on USB adapter
- [ ] Test with different benchmark tool to confirm

---

## Best Practices

### For Media Server Drives
- **Never enable compression** - minimal space savings, significant performance cost
- **Use GPT partitioning** for all drives >2TB
- **Plan for RAID 1 expansion** when adding drives for redundancy
- **Test drives individually** before adding to arrays
- **Keep original drive documentation** for warranty purposes

### Maintenance Schedule
- **Monthly:** Check drive temperatures and health status
- **Quarterly:** Review drive space usage and plan expansions
- **Annually:** Re-run performance benchmarks to detect degradation
- **As needed:** Full surface scans if health status changes

---

## Tools Download Links
- **CrystalDiskInfo:** https://crystalmark.info/en/software/crystaldiskinfo/
- **CrystalDiskMark:** https://crystalmark.info/en/software/crystaldiskmark/
- **HD Tune:** https://www.hdtune.com/download.html

---

*Last Updated: [Date of drive installation]*
*Next Drive Addition: [Planned date]*