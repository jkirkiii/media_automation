# Handling Missing Episodes in Sonarr

**Your Status:** 197 missing episodes detected across your library

---

## Understanding the Situation

When you imported your TV library, Sonarr scanned your shows and discovered that **197 episodes are missing** from your collection. However, **Sonarr will NOT automatically download these** unless you tell it to.

### Why Sonarr Doesn't Auto-Download Missing Episodes

This is **intentional and correct** behavior for several reasons:

1. **Protects Your Ratio** - Prevents mass downloads that could hurt your tracker ratio
2. **Respects Your Bandwidth** - Doesn't flood your connection
3. **Prevents Rate Limiting** - Avoids hammering indexers with hundreds of searches
4. **Gives You Control** - You decide which missing episodes to get

### What Sonarr WILL Auto-Download

✅ **NEW episodes** as they air (for monitored shows)
✅ **Future episodes** of shows you're watching
✅ Episodes you **manually search** for

### What Sonarr Will NOT Auto-Download

❌ **Old/missing episodes** from your existing library
❌ Episodes from unmonitored shows
❌ Episodes unless you trigger a search

---

## How to Check What's Missing

### Method 1: Web UI - Wanted Page

1. Go to http://localhost:8989
2. Click **"Wanted"** → **"Missing"** in the left sidebar
3. You'll see a list of ALL 197 missing episodes

**This page shows:**
- Which episodes are missing
- Which shows they belong to
- Air dates
- Search buttons for each episode

### Method 2: PowerShell Script

Run this anytime:
```powershell
cd C:\Users\rokon\source\media_automation
.\scripts\Check-Missing-Episodes.ps1
```

**This shows:**
- Total missing count
- Breakdown by show
- Recent activity
- Current queue status

### Method 3: Per-Show View

1. Go to http://localhost:8989
2. Click **"Series"**
3. Click on a specific show
4. Look for red "missing" indicators on episodes

---

## How to Download Missing Episodes

You have **three options**, from most conservative to most aggressive:

### Option 1: Manual Search (RECOMMENDED - Conservative)

**Best for:** Getting specific episodes you want

**Steps:**
1. Go to http://localhost:8989 → Wanted → Missing
2. Find the episode you want
3. Click the **magnifying glass icon** next to it
4. Sonarr will search all your indexers
5. **Review the results** - you'll see:
   - Release names
   - Quality (1080p WEB-DL, etc.)
   - Size
   - Seeders
   - Indexer source
6. Click **download icon** on the release you want
7. Repeat for each episode

**Pros:**
- ✅ Full control over what downloads
- ✅ Can review quality and size first
- ✅ Won't overwhelm your connection
- ✅ Protects your ratio

**Cons:**
- ❌ Manual process for each episode
- ❌ Time-consuming for many episodes

### Option 2: Batch Search from Wanted Page (Moderate)

**Best for:** Getting multiple episodes at once

**Steps:**
1. Go to Wanted → Missing
2. **Select episodes** using checkboxes
3. Click **"Search Selected"** at top
4. Sonarr will search and **auto-download best matches**

**Pros:**
- ✅ Faster than manual
- ✅ Sonarr picks best quality automatically
- ✅ Can control how many at once

**Cons:**
- ⚠️ Less control over individual releases
- ⚠️ Multiple downloads trigger at once
- ⚠️ Need to monitor ratio/bandwidth

### Option 3: Search Monitored for Entire Show (AGGRESSIVE)

**Best for:** Completing entire series you care about

**Steps:**
1. Go to Series → Click on show
2. Click **"Search Monitored"** button (top right)
3. Sonarr will search for **ALL missing episodes** of that show
4. Auto-downloads best matches for everything

**Pros:**
- ✅ Fastest way to complete a series
- ✅ One button for whole show

**Cons:**
- ⚠️⚠️ Can trigger 10-50+ downloads instantly
- ⚠️⚠️ Will hammer your ratio
- ⚠️⚠️ May hit tracker rate limits
- ⚠️⚠️ Could fill your bandwidth

**⚠️ WARNING:** Only use this if:
- You have good ratio buffer on trackers
- You have bandwidth to spare
- You really want the complete series
- You're prepared for many simultaneous downloads

---

## Recommended Strategy

Based on your conservative preferences, here's what I suggest:

### 1. Identify Priority Shows

First, decide which shows you actually want to complete:

**High Priority** (want complete series):
- Shows you're currently watching
- Shows you rewatch frequently
- Shows where missing episodes matter to continuity

**Low Priority** (missing episodes OK):
- Shows you're done watching
- Anthology shows where episodes are standalone
- Shows you might delete later

### 2. Handle High Priority Shows

For shows you want to complete:

**Option A: Manual Search (Safest)**
- Go through Wanted → Missing
- Search 5-10 episodes at a time
- Download over several days
- Monitor your ratio as you go

**Option B: Careful Batch**
- Select 10-20 episodes from Wanted → Missing
- Click "Search Selected"
- Wait for these to complete
- Repeat in batches

**Option C: Complete Series (if ratio permits)**
- Go to show page
- Click "Search Monitored"
- Let Sonarr grab everything
- Monitor downloads in Activity → Queue

### 3. Ignore Low Priority Shows

For shows you don't need complete:
- Leave them as-is
- Only get future episodes (if monitored)
- Missing episodes will stay marked as "missing" but won't download

---

## Monitoring Download Activity

### Check Current Activity

**Web UI:**
- Go to http://localhost:8989
- Click **"Activity"** → **"Queue"**
- See what's downloading right now

**PowerShell:**
```powershell
.\scripts\Check-Missing-Episodes.ps1
```
Shows queue at the bottom

### What You'll See in Queue

- **Episode name** and show
- **Download status** (Queued, Downloading, Importing)
- **Progress percentage**
- **ETA** (estimated time remaining)
- **Quality** (1080p WEB-DL, etc.)

### Check History

**Web UI:**
- Activity → **History**
- See past downloads, imports, failures

**Shows:**
- What was grabbed
- What was imported
- Any failures or warnings

### Check What's Seeding

**In qBittorrent:**
1. Open qBittorrent
2. Filter by **category: tv-sonarr**
3. See all TV downloads
4. Check seed ratio and time
5. Remove when meeting requirements (10 days minimum)

---

## Example Workflow

Let's say you want to complete "Abbott Elementary" which has missing episodes:

### Step-by-Step

1. **Check what's missing:**
   - Go to http://localhost:8989
   - Series → Abbott Elementary
   - See which episodes are red (missing)

2. **Decide approach:**
   - Only 5-10 missing? → Manual search each
   - Whole season missing? → Use "Search Monitored"
   - Just a few you care about? → Manual from Wanted page

3. **Trigger search:**
   - **Manual:** Click magnifying glass on episode
   - **Batch:** Select from Wanted → "Search Selected"
   - **All:** Click "Search Monitored" on show page

4. **Monitor progress:**
   - Activity → Queue (see downloads)
   - qBittorrent (see torrent progress)
   - Wait for completion

5. **Verify import:**
   - Check A:\Media\TV Shows\Abbott Elementary\
   - Files should be renamed correctly
   - Episodes marked green in Sonarr

6. **Manage seeding:**
   - Keep in qBittorrent for 10 days
   - Check ratio
   - Remove when requirements met

---

## RSS Sync vs Manual Search

### RSS Sync (Automatic - For New Episodes)

**What it does:**
- Checks indexers every 60 minutes
- Looks for **NEW** releases
- Auto-downloads when episode airs

**When it runs:**
- Continuously in background
- Looks at calendar for upcoming episodes
- Grabs as soon as available

**You'll see:**
- New episodes appear in Queue automatically
- No action needed from you
- Works for future episodes only

### Manual Search (For Missing Episodes)

**What it does:**
- Searches indexers when you click the button
- Looks for **specific** episode you request
- Returns results for you to review or auto-grab

**When it runs:**
- Only when you trigger it
- On-demand for specific episodes
- For backfilling missing content

**You'll see:**
- Search results appear
- Can download immediately or review first
- One-time action per search

---

## Important Reminders

### Before Mass Downloads

✅ **Check ratio on all trackers** - ensure buffer
✅ **Verify disk space** - 4.21 TB free, but monitor
✅ **Consider bandwidth** - many downloads = slow internet
✅ **Check qBittorrent slots** - max concurrent downloads
✅ **Monitor tracker limits** - some have hourly/daily caps

### After Downloads Start

✅ **Watch Activity → Queue** - ensure no failures
✅ **Check qBittorrent** - verify all downloading
✅ **Monitor ratio** - ensure not dropping too low
✅ **Verify VPN** - NordVPN should always be connected

### After Downloads Complete

✅ **Verify imports** - check files in TV Shows folder
✅ **Update Plex** - scan library or wait for auto-scan
✅ **Keep seeding** - respect 10-day minimum
✅ **Remove after requirements met** - clean up qBittorrent

---

## Troubleshooting

### "No results found" when searching

**Possible causes:**
- Episode too old (no seeders)
- Indexers don't have it
- Wrong episode numbering
- Not in indexer categories

**Solutions:**
- Try different indexers (check Prowlarr)
- Search manually on tracker websites
- Check if episode exists (TVDb)
- Wait for reupload

### Downloads not starting

**Check:**
- qBittorrent running?
- VPN connected?
- Disk space available?
- Tracker limits hit?

**Fix:**
- Restart qBittorrent
- Reconnect VPN
- Free up space
- Wait for tracker cooldown

### Import failed

**Common issues:**
- File naming doesn't match
- Permissions problem
- Disk full
- File corrupt

**Solutions:**
- Check Activity → History for error
- Manual import: Activity → Manual Import
- Check logs: System → Logs
- Redownload if corrupt

---

## Quick Reference Commands

### Check missing episodes:
```powershell
.\scripts\Check-Missing-Episodes.ps1
```

### Verify setup:
```powershell
.\scripts\Verify-Setup.ps1
```

### Check what's coming:
Go to http://localhost:8989 → Calendar

### See active downloads:
Go to http://localhost:8989 → Activity → Queue

### Find missing episodes:
Go to http://localhost:8989 → Wanted → Missing

---

## Summary

**Current State:**
- 197 episodes missing across your library
- Sonarr knows about them but WON'T auto-download
- You control when/if to search for them

**For New Episodes:**
- Sonarr WILL auto-download (RSS sync)
- Happens automatically
- No action needed

**For Missing Episodes:**
- YOU must trigger searches
- Manual control recommended
- Use Wanted → Missing page

**Best Practice:**
- Start with 5-10 episodes
- Monitor ratio and bandwidth
- Complete priority shows first
- Leave low-priority shows incomplete

**Remember:** Quality over quantity! Better to have what you actually watch than everything you could possibly download.
