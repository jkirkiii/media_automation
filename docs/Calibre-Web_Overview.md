# Calibre-Web Overview & Setup Guide

**What is Calibre-Web?**
A modern, web-based ebook reader and library manager that connects to your Calibre library.

**Status:** Planning Phase
**Your Calibre Library:** `A:\Media\Calibre`

---

## What Calibre-Web Offers

### Core Features

#### 1. **Web-Based Library Access**
- Access your ebook library from **any device with a browser**
  - Phone, tablet, laptop, desktop
  - No need to install Calibre on each device
- **Responsive design** - works great on mobile
- Access from anywhere (if you set up remote access)

#### 2. **Online Reading**
- **Built-in ebook reader** - read directly in your browser
  - Supports EPUB format natively
  - Clean, distraction-free reading interface
  - Adjustable font size, colors, themes
  - Bookmarks and reading progress sync
- **No need to download files** to read them

#### 3. **Library Browsing & Search**
- **Beautiful, modern interface** (much nicer than Calibre desktop)
- Browse by:
  - Authors
  - Series
  - Tags/Genres
  - Publishers
  - Languages
  - Ratings
- **Advanced search** with filters
- **Cover view** - see all your book covers in a grid
- **List view** - traditional table format

#### 4. **Book Management**
- **Download books** in any available format
  - EPUB, MOBI, AZW3, PDF, etc.
  - Send to your e-reader
- **Convert between formats** (if Calibre eBook converter installed)
- **Edit metadata** through web interface
- **Upload new books** to library
- **Delete books** from library

#### 5. **User Management**
- **Multi-user support** with separate accounts
  - Create accounts for family members
  - Each user has their own:
    - Reading progress
    - Bookmarks
    - Ratings
    - Shelves (personal collections)
- **Permission system**
  - Admin: Full access
  - User: Read-only or limited editing
  - Guest: Browse and read only

#### 6. **Personal Collections ("Shelves")**
- Create **custom reading lists**:
  - "Currently Reading"
  - "Want to Read"
  - "Favorites"
  - "Completed"
  - Custom categories
- **Like Goodreads shelves** but private and local

#### 7. **Reading Stats & Progress**
- Track reading progress per book
- See percentage completed
- Reading history
- Personal ratings and reviews

#### 8. **E-Reader Integration**
- **Send to Kindle** - Email books directly to your Kindle
- **Send to e-reader** - OPDS catalog support
  - Compatible with most e-readers (Kobo, Tolino, etc.)
- **Download formats** optimized for your device

#### 9. **OPDS Catalog Support**
- **Open Publication Distribution System**
- Access your library from dedicated e-reader apps:
  - KyBook (iOS)
  - Moon+ Reader (Android)
  - FBReader (cross-platform)
  - Any OPDS-compatible reader

---

## Calibre vs Calibre-Web Comparison

| Feature | Calibre Desktop | Calibre-Web |
|---------|----------------|-------------|
| **Interface** | Desktop application (Windows/Mac/Linux) | Web browser |
| **Access** | Only on computer where installed | Any device with browser |
| **Mobile** | No mobile app | Works on phones/tablets |
| **Reading** | Built-in reader (basic) | Modern web reader |
| **Editing** | Full editing power | Basic editing |
| **Metadata** | Download & manage | View & edit |
| **Conversion** | Full conversion suite | Basic (if Calibre installed) |
| **Multi-user** | Single user | Multiple users with permissions |
| **Remote Access** | Requires Calibre Content Server | Native web interface |
| **Speed** | Desktop app speed | Web app (network dependent) |

**The Ideal Setup:** Use **both**!
- **Calibre Desktop** for heavy management (bulk operations, advanced editing)
- **Calibre-Web** for daily reading and browsing

---

## Why You'd Want Calibre-Web

### Use Cases

#### 1. **Read on Any Device**
- Reading on your phone during commute
- Reading on tablet in bed
- Reading on laptop while traveling
- **No need to transfer files** - just open the web page

#### 2. **Family Sharing**
- Give family members access to your library
- They can browse and read without bugging you
- Track what everyone is reading
- Each person has their own reading progress

#### 3. **Remote Access** (Optional)
- Access your library from **outside your home**
- Read your books while traveling
- No need to carry files on your device

#### 4. **Better Browsing Experience**
- Calibre-Web's interface is **much prettier** than Calibre desktop
- Easier to discover books you forgot you had
- Cover grid view is great for visual browsing

#### 5. **Lightweight Reading**
- Don't want to open Calibre desktop just to read?
- Just open your browser and start reading
- No heavy application to launch

---

## What Calibre-Web Does NOT Do

**Important limitations:**

1. **Read-only for most operations**
   - Calibre-Web mostly **reads** your Calibre library
   - Can edit metadata and upload books
   - But not as powerful as Calibre desktop for bulk operations

2. **Requires Calibre library**
   - Calibre-Web is a **frontend** to Calibre
   - You still need Calibre desktop for initial setup
   - Works by reading Calibre's database

3. **No format conversion** (unless Calibre installed)
   - Can convert if Calibre eBook converter is available
   - But limited compared to desktop

4. **Calibre must not be running simultaneously**
   - **Important:** Don't open Calibre desktop while Calibre-Web is running
   - They can conflict when accessing the database
   - **Solution:** Use Calibre desktop for management, then close it before using Calibre-Web

---

## Installation Options

### Option 1: Docker (Recommended)

**Pros:**
- Easiest to set up and maintain
- Isolated environment
- Easy to update
- Official Docker image available

**Cons:**
- Requires Docker Desktop for Windows
- Slightly more complex if you're unfamiliar with Docker

**Best for:** If you plan to use Docker for other services (Radarr, Readarr, etc.)

---

### Option 2: Windows Native (Python)

**Pros:**
- No Docker required
- Runs as a Windows service
- Direct access to file system

**Cons:**
- More manual setup
- Python environment management
- Updates require manual process

**Best for:** If you want simplicity and no Docker

---

### Option 3: Pre-built Windows Executable

**Pros:**
- Simplest installation (just run an .exe)
- No Python or Docker required
- Portable

**Cons:**
- May not be as up-to-date as Docker
- Limited official support

**Best for:** Quick testing or if you want zero dependencies

---

## Recommended Setup for Your System

Given your current setup:

**Phase 1: Start with Windows Native (Python)**
- Simpler for getting started
- No Docker overhead
- Easy to test and see if you like it

**Phase 2: Migrate to Docker Later (Optional)**
- If you decide to set up Radarr, Readarr, etc.
- Docker Compose for everything
- Cleaner long-term architecture

---

## Installation Steps (Windows Native)

### Prerequisites

1. **Python 3.8+** installed
2. **Calibre library** at `A:\Media\Calibre` (✓ You have this!)
3. **Port 8083** available (default for Calibre-Web)

### Quick Install

```powershell
# Install Python (if not already installed)
# Download from python.org and install with "Add to PATH" option

# Install Calibre-Web via pip
pip install calibreweb

# Create config directory
New-Item -Path "A:\Media\Calibre-Web-Config" -ItemType Directory

# Run Calibre-Web (first time setup)
cps -p A:\Media\Calibre-Web-Config
```

### First-Time Setup

1. **Open browser:** http://localhost:8083
2. **Login with defaults:**
   - Username: `admin`
   - Password: `admin123`
3. **Set Calibre library path:**
   - Settings → Basic Configuration
   - Location of Calibre database: `A:\Media\Calibre`
   - Save
4. **Change admin password!**
   - Settings → Users → admin → Edit
   - Set new secure password

### Configuration

**Important Settings:**

1. **Basic Configuration:**
   - Calibre library location: `A:\Media\Calibre`
   - Enable public registration: No (unless you want anyone to create accounts)
   - Enable anonymous browsing: No (require login)

2. **Feature Configuration:**
   - Enable uploads: Yes (if you want to add books via web)
   - Enable book conversion: Yes (if Calibre is installed)
   - Enable Kobo sync: Optional (if you have a Kobo)

3. **UI Configuration:**
   - Books per page: 50-100
   - Random books: 10-20
   - Default language: English

---

## Security Considerations

### Local Network Only (Default)

**Safe for:**
- Access only from your home network
- No internet exposure
- Recommended starting point

**Access from:**
- Your PC: http://localhost:8083
- Other home devices: http://[YOUR-PC-IP]:8083

### Remote Access (Advanced - Optional)

**If you want to access from outside your home:**

**⚠️ Security Requirements:**
1. **Strong passwords** for all accounts
2. **HTTPS/SSL** encryption (not plain HTTP)
3. **VPN** (most secure option)
   - Or reverse proxy with authentication (Caddy, Nginx)
4. **Firewall rules** to limit access

**Not recommended until you're comfortable with the basics!**

---

## Integration with Your Stack

### Current Integration Points

**Calibre-Web fits into your stack:**

```
Torrents → qBittorrent → A:\Downloads\Books
                               ↓
                         Calibre Desktop
                               ↓
                      A:\Media\Calibre
                               ↓
                         Calibre-Web ← You read here
```

### Future Integration (with Readarr)

**Automated workflow:**

```
Prowlarr → Readarr → qBittorrent → A:\Downloads\Books
                          ↓
                    Calibre Auto-Import
                          ↓
                   A:\Media\Calibre
                          ↓
                    Calibre-Web ← You read here
```

**How it works:**
1. Readarr monitors for new books (like Sonarr for TV)
2. Searches Prowlarr indexers (MyAnonamouse)
3. Sends to qBittorrent (books category)
4. After download, imports to Calibre automatically
5. Appears in Calibre-Web for reading

---

## Alternatives to Consider

### Calibre Content Server (Built-in)

**What:** Calibre has a built-in web server
- Run: Calibre → Connect/Share → Start Content Server
- Access at: http://localhost:8080

**Pros:**
- Already included with Calibre
- No additional installation

**Cons:**
- **Very basic interface** (not pretty)
- Limited features
- Requires Calibre to be running

**Verdict:** Calibre-Web is much better for actual use

---

### Kavita

**What:** Another ebook web server (also does comics/manga)

**Pros:**
- Beautiful modern UI
- Fast
- Good mobile support

**Cons:**
- **Does not use Calibre library** (separate database)
- No Calibre integration
- Would require duplicate management

**Verdict:** Stick with Calibre-Web for Calibre integration

---

### Komga

**What:** Digital library server (primarily for comics/manga)

**Similar situation to Kavita** - separate ecosystem

---

## Recommended Next Steps

### Phase 1: Install & Test (This Week)

1. **Install Calibre-Web** (Python method)
2. **Point it at your Calibre library**
3. **Test reading** a few books in the web interface
4. **Browse your library** - see if you like the interface
5. **Test on mobile** - open from your phone

**Time investment:** 1-2 hours

---

### Phase 2: Daily Use (Next 2 Weeks)

1. **Use Calibre-Web for reading** instead of Calibre desktop
2. **Create personal shelves** (Currently Reading, Want to Read)
3. **Add ratings** to books you finish
4. **Test uploading** a new book via web interface

**Goal:** Decide if you like it enough to keep using it

---

### Phase 3: Advanced Setup (Future)

1. **Create accounts for family members** (if sharing)
2. **Set up OPDS** for e-reader access (if you have one)
3. **Consider remote access** (VPN or reverse proxy)
4. **Install Readarr** for automation

---

## Quick Start Commands

### Install Calibre-Web

```powershell
# Install via pip
pip install calibreweb

# Create config directory
New-Item -Path "A:\Media\Calibre-Web-Config" -ItemType Directory

# Run Calibre-Web
cps -p A:\Media\Calibre-Web-Config

# Access in browser
# http://localhost:8083
# Username: admin
# Password: admin123
```

### Stop Calibre-Web

```powershell
# Press Ctrl+C in the terminal where it's running
# Or close the terminal window
```

### Run as Background Service (Advanced)

```powershell
# Install NSSM (Non-Sucking Service Manager)
# Download from nssm.cc

# Install as Windows service
nssm install CalibreWeb "C:\Path\To\Python\Scripts\cps.exe" "-p A:\Media\Calibre-Web-Config"

# Start service
nssm start CalibreWeb
```

---

## Resources

### Official Documentation
- **Calibre-Web GitHub:** https://github.com/janeczku/calibre-web
- **Wiki:** https://github.com/janeczku/calibre-web/wiki
- **Installation Guide:** https://github.com/janeczku/calibre-web/wiki/Installation

### Community
- **Reddit:** r/Calibre
- **Discord:** Various self-hosted communities

### Tutorials
- Search YouTube for "Calibre-Web setup" for video guides
- Lots of guides for Docker setup if you go that route

---

## Summary: Should You Use Calibre-Web?

### ✅ Yes, if you want:
- Read ebooks in your browser (any device)
- Beautiful, modern interface for browsing
- Access library from phone/tablet easily
- Multiple user accounts with reading progress
- Share library with family
- Better discovery of books you own

### ❌ Maybe not, if:
- You only read on one device (just use Calibre desktop)
- You prefer dedicated e-reader apps that read files directly
- You don't want to run another service
- You're happy with Calibre desktop's interface

---

## My Recommendation

**For your situation:** **Yes, install Calibre-Web!**

**Reasons:**
1. You have a **clean, organized Calibre library** now (nice work!)
2. You're already running services (Sonarr, qBittorrent)
3. **Web interface is much nicer** than Calibre desktop for daily use
4. **Sets you up for Readarr** automation later
5. **Low effort to try** - if you don't like it, just uninstall

**Start simple:**
- Install the Python version
- Test it out for a week
- See if you like reading in the browser
- If yes, consider Docker + Readarr next

---

**Ready to install?** Let me know and I can create a detailed installation script for you!

**Last Updated:** 2025-10-28
**Status:** Planning - Ready for installation
