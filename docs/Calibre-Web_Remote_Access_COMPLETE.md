# Calibre-Web Remote Access - Setup Complete

**Status:** ✅ COMPLETE - Operational
**Completed:** 2025-11-11
**Domain:** https://books.mnemo.info

---

## Summary

Successfully configured remote access to Calibre-Web ebook library using Cloudflare Tunnel. The library is now accessible both locally and remotely with automatic startup on system boot.

## Configuration Details

### Domain & DNS
- **Domain:** mnemo.info (registered with Porkbun)
- **Subdomain:** books.mnemo.info
- **DNS:** Managed by Cloudflare
- **SSL/HTTPS:** Automatic via Cloudflare (free)

### Cloudflare Tunnel
- **Tunnel Name:** calibre-web-tunnel
- **Tunnel ID:** 142f1d95-3768-4ff8-86b8-c599dcc1a0f5
- **Target Service:** http://localhost:8083 (Calibre-Web)
- **Configuration:** C:\Users\rokon\.cloudflared\config.yml
- **Credentials:** C:\Users\rokon\.cloudflared\142f1d95-3768-4ff8-86b8-c599dcc1a0f5.json

### Access URLs
- **Remote:** https://books.mnemo.info
- **Local:** http://localhost:8083

### Login Credentials
Stored in `config.ps1` (gitignored - NOT committed to repository):
- **Username:** [See config.ps1]
- **Password:** [See config.ps1]

---

## Automated Startup

### Windows Task Scheduler
A scheduled task automatically starts both Calibre-Web and Cloudflare Tunnel when you log in:

- **Task Name:** Start-CalibreWeb-Remote
- **Trigger:** At user login (rokon)
- **Action:** Runs Start-CalibreWeb-With-Tunnel.ps1
- **Run Level:** Highest (Administrator)

### Manual Control Scripts

**Start services:**
```powershell
C:\Users\rokon\source\media_automation\scripts\Start-CalibreWeb-With-Tunnel.ps1
```

**Stop services:**
```powershell
C:\Users\rokon\source\media_automation\scripts\Stop-CalibreWeb-And-Tunnel.ps1
```

**Quick start (batch file):**
```
C:\Users\rokon\source\media_automation\Start-CalibreWeb-Remote.bat
```

---

## Architecture

```
User's Browser (anywhere)
         ↓
    HTTPS (encrypted)
         ↓
Cloudflare Network (DDoS protection, SSL)
         ↓
Cloudflare Tunnel (cloudflared daemon)
         ↓
Your Windows PC (localhost only)
         ↓
Calibre-Web (http://localhost:8083)
         ↓
Calibre Library (A:\Media\Calibre)
```

---

## Security Features

- ✅ Home IP address hidden from all visitors
- ✅ No port forwarding required (firewall stays closed)
- ✅ HTTPS encryption via Cloudflare
- ✅ DDoS protection via Cloudflare
- ✅ Login required (no anonymous access)
- ✅ Isolated from torrent client/automation stack
- ✅ Private tracker safe (no connection to qBittorrent)

---

## File Locations

### Cloudflare Tunnel Files
```
C:\Users\rokon\.cloudflared\
├── cloudflared.exe                                    (tunnel daemon)
├── config.yml                                         (tunnel configuration)
├── cert.pem                                          (authentication certificate)
└── 142f1d95-3768-4ff8-86b8-c599dcc1a0f5.json        (tunnel credentials)
```

### Calibre-Web Files
```
A:\Media\Calibre-Web-Config\    (Calibre-Web configuration)
A:\Media\Calibre\               (Calibre library - ~70 books)
```

### Management Scripts
```
C:\Users\rokon\source\media_automation\
├── Start-CalibreWeb-Remote.bat                      (quick start - double-click)
└── scripts\
    ├── Start-CalibreWeb-With-Tunnel.ps1            (unified startup script)
    ├── Stop-CalibreWeb-And-Tunnel.ps1              (stop both services)
    └── Setup-Startup-Task.ps1                       (configure auto-start)
```

---

## Maintenance

### Check if Services are Running
```powershell
# Check Calibre-Web
Get-Process | Where-Object {$_.ProcessName -like "*cps*"}

# Check Cloudflare Tunnel
Get-Process | Where-Object {$_.ProcessName -like "*cloudflared*"}

# Check tunnel connection status
& "C:\Users\rokon\.cloudflared\cloudflared.exe" tunnel info calibre-web-tunnel
```

### Restart Services
```powershell
cd C:\Users\rokon\source\media_automation\scripts
.\Stop-CalibreWeb-And-Tunnel.ps1
.\Start-CalibreWeb-With-Tunnel.ps1
```

### Disable Auto-Start
```powershell
Disable-ScheduledTask -TaskName 'Start-CalibreWeb-Remote'
```

### Re-enable Auto-Start
```powershell
Enable-ScheduledTask -TaskName 'Start-CalibreWeb-Remote'
```

### Remove Auto-Start Completely
```powershell
Unregister-ScheduledTask -TaskName 'Start-CalibreWeb-Remote' -Confirm:$false
```

---

## Troubleshooting

### Books.mnemo.info Not Loading

1. **Check if services are running:**
   ```powershell
   Get-Process | Where-Object {$_.ProcessName -like "*cps*" -or $_.ProcessName -like "*cloudflared*"}
   ```

2. **Check tunnel status:**
   ```powershell
   & "C:\Users\rokon\.cloudflared\cloudflared.exe" tunnel info calibre-web-tunnel
   ```
   Should show "4 active connections"

3. **Restart services:**
   ```powershell
   .\Stop-CalibreWeb-And-Tunnel.ps1
   .\Start-CalibreWeb-With-Tunnel.ps1
   ```

### Calibre-Web Not Starting

1. **Check if port 8083 is available:**
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 8083
   ```

2. **Start Calibre-Web manually:**
   ```powershell
   & "$env:APPDATA\Python\Python313\Scripts\cps.exe" -p "A:\Media\Calibre-Web-Config"
   ```

### Tunnel Not Connecting

1. **Run tunnel manually to see error messages:**
   ```powershell
   & "C:\Users\rokon\.cloudflared\cloudflared.exe" tunnel --config "C:\Users\rokon\.cloudflared\config.yml" run
   ```

2. **Check config file exists:**
   ```powershell
   Test-Path "C:\Users\rokon\.cloudflared\config.yml"
   ```

---

## Security & Email Configuration âœ…

### Completed Security Hardening (2025-12-06)
- [x] Changed admin password from default
- [x] Created user accounts for family/friends
- [x] Configured user permissions (Download, Browse, Read Online, Send to Kindle)
- [x] Set up Gmail SMTP for Send-to-Kindle functionality
- [x] Disabled anonymous browsing
- [x] Enabled proxy headers for accurate IP logging

### SMTP Configuration Details âœ…
**Email Provider:** Gmail
**Configuration:**
```
SMTP Hostname: smtp.gmail.com
SMTP Port: 587
Encryption: StartTLS
From E-mail: YOUR_EMAIL@gmail.com
Authentication: Gmail App Password (16-character)
```

**Send-to-Kindle Status:** âœ… Operational
- Users can send EPUB files directly to their Kindle devices
- Gmail sender address added to Amazon Kindle approved list
- Tested and verified working on multiple users' devices
- No customization needed - default subject/body work perfectly with Kindle

### User Access Summary
- **Admin Account:** (see config.ps1) (full permissions)
- **User Accounts:** Multiple family/friend accounts created
- **User Permissions:** Download, Browse, Read Online, Send to Kindle enabled
- **Upload/Edit/Delete:** Disabled for regular users (security)

### Future Enhancements
- [ ] Install Readarr for automated ebook acquisition
- [ ] Connect Readarr to MyAnonamouse indexer
- [ ] Set up custom Calibre-Web themes
- [ ] Configure OPDS catalog for mobile apps
- [ ] Add monitoring/alerts for service downtime

---

## Cost Breakdown

| Item | Cost | Frequency |
|------|------|-----------|
| Domain (mnemo.info) | ~$10 | Per year |
| Cloudflare Account | Free | Forever |
| Cloudflare Tunnel | Free | Forever |
| SSL Certificate | Free | Forever (auto-renewed) |
| **Total Annual Cost** | **~$10** | **Per year** |

---

## Technical Specifications

### Software Versions
- **cloudflared:** 2025.11.1 (built 2025-11-07)
- **Calibre-Web:** Installed via pip (Python 3.13)
- **Calibre Library:** ~70 books at A:\Media\Calibre
- **Windows:** Windows 11

### Network Configuration
- **No port forwarding required**
- **No firewall modifications required**
- **Outbound connection only** (PC → Cloudflare)
- **IP address hidden** from all external visitors

---

## Setup Timeline

Completed in approximately 2 hours:
1. Domain purchase and Cloudflare setup: 20 min
2. Cloudflared installation and authentication: 15 min
3. Tunnel creation and DNS configuration: 10 min
4. Service configuration troubleshooting: 45 min
5. Startup script creation and testing: 20 min
6. Auto-start task setup: 10 min

---

## References

- **Cloudflare Tunnel Docs:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **Calibre-Web GitHub:** https://github.com/janeczku/calibre-web
- **Project Documentation:** See `docs/` folder
  - Calibre-Web_Remote_Access_Guide.md
  - Calibre-Web_Configuration_Decisions.md
  - Calibre-Web_Security_Checklist.md

---

**Last Updated:** 2025-12-06
**Maintained By:** rokon
**Status:** ✅ Production - Fully Operational (including SMTP/Send-to-Kindle)
