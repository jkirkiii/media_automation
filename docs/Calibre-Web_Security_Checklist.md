# Calibre-Web Security Hardening Checklist

**Purpose:** Ensure your Calibre-Web remote access setup is secure before sharing with family and friends.

**When to Use:** After completing Cloudflare Tunnel setup, before sharing the URL externally.

---

## Critical Security Rules

### DO ✅

- ✅ Use strong, unique passwords for all accounts
- ✅ Only expose Calibre-Web (port 8083) through the tunnel
- ✅ Keep Calibre-Web updated to latest version
- ✅ Monitor access logs regularly
- ✅ Use separate user accounts (not admin) for sharing
- ✅ Enable "Use Proxy Headers" in Calibre-Web for accurate logging
- ✅ Regularly review user accounts and remove inactive users

### DON'T ❌

- ❌ **NEVER expose qBittorrent Web UI** (port 8080) through Cloudflare
- ❌ **NEVER expose Sonarr** (port 8989) through Cloudflare
- ❌ **NEVER expose Prowlarr** (port 9696) through Cloudflare
- ❌ Don't use the same password across services
- ❌ Don't give admin access to shared users
- ❌ Don't allow public registration (manually create accounts)
- ❌ Don't allow anonymous browsing

---

## Pre-Launch Security Checklist

Complete these steps **before** sharing your Calibre-Web URL with family/friends:

### Phase 1: Access Calibre-Web

- [ ] **Access Calibre-Web locally**
  - Open http://localhost:8083 in browser
  - Or via Cloudflare URL: https://library.yourdomain.com
  - Login with current credentials (default: `admin` / `admin123`)

---

### Phase 2: Admin Account Security

- [ ] **Change default admin password**
  - Click "Admin" (top right) → "Edit Basic Configuration"
  - Click "User Configuration" → Click "admin" user
  - Set strong new password (12+ characters, mix of letters/numbers/symbols)
  - Click "Save"
  - **Test new password** - Log out and back in

- [ ] **Create secondary admin account (recommended)**
  - Admin → Add New User
  - Username: `[yourname]_admin` (e.g., `rokon_admin`)
  - Set strong password
  - Enable: Admin, Download, Edit, Upload, Delete (all permissions)
  - Click "Save"
  - **Test new admin account** - Log in with new credentials
  - Keep original `admin` account as emergency backup

- [ ] **Document admin passwords**
  - Store in password manager (LastPass, 1Password, Bitwarden, etc.)
  - NEVER store in plain text files
  - NEVER email passwords

---

### Phase 3: User Account Management

- [ ] **Disable public registration**
  - Admin → Edit Basic Configuration → Feature Configuration
  - **Disable** "Allow Public Registration"
  - Click "Save"

- [ ] **Disable anonymous browsing**
  - Admin → Edit Basic Configuration → Feature Configuration
  - **Disable** "Allow Anonymous Browsing"
  - Click "Save"
  - This requires all users to log in

- [ ] **Create user accounts for family/friends**
  - For each person:
    - Admin → Add New User
    - Username: Their name or email
    - Email: Their email address (for password resets, Send to Kindle)
    - Strong password (or temporary password they'll change)
    - Set permissions (see below)
    - Click "Save"

#### Recommended User Permissions

For typical family/friend accounts:

| Permission | Enable? | Why |
|------------|---------|-----|
| Download | ✅ Yes | Allow downloading ebooks |
| Browse | ✅ Yes | Browse and search library |
| Read Books | ✅ Yes | Read online in browser |
| Send to Kindle | ✅ Yes | Email books to Kindle/devices |
| Upload | ❌ No | Prevent unauthorized uploads |
| Edit | ❌ No | Prevent metadata changes |
| Delete Books | ❌ No | Prevent accidental deletions |
| Admin | ❌ No | Only for you |

**Checklist for each user account:**

- [ ] Download enabled
- [ ] Browse enabled
- [ ] Read Books enabled
- [ ] Send to Kindle enabled (if they use Kindle)
- [ ] Upload **disabled**
- [ ] Edit **disabled**
- [ ] Delete Books **disabled**
- [ ] Admin **disabled**

---

### Phase 4: Calibre-Web Security Settings

- [ ] **Enable proxy headers (critical for Cloudflare)**
  - Admin → Edit Basic Configuration → Feature Configuration
  - Scroll to "Reverse Proxy Configuration"
  - **Enable** "Use Proxy Headers"
  - Click "Save"
  - This ensures Calibre-Web logs real client IPs, not Cloudflare's

- [ ] **Review upload restrictions (if Upload enabled for anyone)**
  - Admin → Edit Basic Configuration → Feature Configuration
  - Check "Uploading" section
  - Verify allowed file types
  - Set reasonable file size limits

- [ ] **Check external authentication (should be disabled for now)**
  - Admin → Edit Basic Configuration → Feature Configuration
  - Ensure "External Authentication" is **disabled**
  - We're using Calibre-Web's built-in authentication

---

### Phase 5: Email Configuration (Optional but Recommended) ✅

**Status:** COMPLETE - 2025-12-06

- [x] **Configure SMTP settings**
  - Admin → Edit Basic Configuration → Feature Configuration
  - Scroll to "E-Mail Server Settings"

#### For Gmail:
```
SMTP Hostname: smtp.gmail.com
SMTP Port: 587
Encryption: StartTLS
From E-mail: youremail@gmail.com
SMTP Username: youremail@gmail.com
SMTP Password: [App Password - NOT your regular Gmail password]
```

**Generate Gmail App Password:** ✅ COMPLETED
1. ✅ Went to https://myaccount.google.com/apppasswords
2. ✅ Selected "Mail" and "Windows Computer"
3. ✅ Generated 16-character password
4. ✅ Added to Calibre-Web SMTP Password field

**Configuration Used:**
```
SMTP Hostname: smtp.gmail.com
SMTP Port: 587
Encryption: StartTLS
From E-mail: rokonin@gmail.com
Authentication: Gmail App Password
```

- [x] **Test email settings**
  - Click "Save" in E-Mail configuration
  - Go to a book in your library
  - Click the dropdown arrow → "Send to Kindle/E-Mail"
  - Send test email to yourself
  - ✅ Verified email arrives successfully

- [x] **Users configure their Kindle email (if using Send to Kindle)**
  - Users log in → Click their username (top right) → "Your Kindle E-Mail"
  - Enter their Kindle email: `username@kindle.com`
  - ✅ Configured for multiple users

- [x] **Add sender email to Amazon Kindle Approved list**
  - Go to https://www.amazon.com/myk (Amazon Manage Your Content and Devices)
  - Settings → Personal Document Settings
  - Approved Personal Document E-mail List
  - ✅ Added rokonin@gmail.com to approved senders
  - ✅ Tested and verified working on multiple devices

---

### Phase 6: Cloudflare Tunnel Security

- [ ] **Verify ONLY Calibre-Web is exposed**
  - Open `C:\Users\[yourusername]\.cloudflared\config.yml`
  - Verify ingress only includes:
    ```yaml
    ingress:
      - hostname: library.yourdomain.com
        service: http://localhost:8083
      - service: http_status:404
    ```
  - **No other services** should be listed

- [ ] **Verify cloudflared service is running**
  - Open PowerShell as Administrator
  - Run: `Get-Service cloudflared`
  - Status should be "Running"
  - Startup Type should be "Automatic"

- [ ] **Test external access**
  - Use mobile phone (turn off WiFi, use cellular data)
  - Go to https://library.yourdomain.com
  - Should see Calibre-Web login page
  - Should have valid SSL certificate (padlock icon)
  - Log in with a test user account
  - Verify permissions work as expected

---

### Phase 7: Windows Firewall Verification

- [ ] **Verify no direct port forwarding exists**
  - Open Windows Firewall (Windows Security → Firewall & Network Protection)
  - Click "Advanced settings"
  - Inbound Rules → Look for port 8083
  - There should be **no public inbound rule** for port 8083
  - Cloudflare Tunnel uses outbound connections only

- [ ] **Verify qBittorrent/Sonarr are NOT exposed**
  - Check for rules allowing inbound to port 8080 (qBittorrent)
  - Check for rules allowing inbound to port 8989 (Sonarr)
  - Check for rules allowing inbound to port 9696 (Prowlarr)
  - **Delete any public inbound rules** for these ports

---

### Phase 8: Cloudflare Dashboard Security

- [ ] **Review DNS records in Cloudflare**
  - Log into Cloudflare Dashboard
  - Select your domain
  - DNS → Records
  - Verify ONLY the library subdomain CNAME exists
  - Should point to: `[tunnel-id].cfargotunnel.com`
  - Orange cloud (Proxied) should be enabled

- [ ] **Enable Cloudflare security features (optional)**
  - Security → WAF
  - Consider enabling:
    - Rate limiting (free tier allows limited rules)
    - Bot Fight Mode (free)
    - Challenge Passage (free)

- [ ] **Review Cloudflare firewall rules (optional)**
  - Security → Firewall Rules (paid feature)
  - Can add geo-blocking, IP whitelisting, etc.

---

### Phase 9: Calibre-Web Updates & Maintenance

- [ ] **Check current Calibre-Web version**
  - Access Calibre-Web
  - Look at bottom of page for version number
  - Current stable version: Check https://github.com/janeczku/calibre-web/releases

- [ ] **Set up update reminder**
  - Add calendar reminder to check for updates monthly
  - Or subscribe to GitHub releases: https://github.com/janeczku/calibre-web/releases

- [ ] **Backup current configuration**
  - Backup `A:\Media\Calibre-Web-Config\app.db`
  - Store backup in safe location
  - This contains user accounts, settings, reading progress

---

### Phase 10: Monitoring & Logging

- [ ] **Review Calibre-Web access logs**
  - Admin → Logfiles
  - Check for any suspicious activity
  - Look for failed login attempts

- [ ] **Set up log monitoring schedule**
  - Review logs weekly (at minimum)
  - Look for:
    - Unexpected login times
    - Failed authentication attempts
    - Unknown IP addresses (with proxy headers enabled)

- [ ] **Review Cloudflare Analytics**
  - Cloudflare Dashboard → Analytics & Logs
  - Check visitor statistics
  - Monitor for unusual traffic patterns

- [ ] **Set up usage alerts (optional)**
  - Cloudflare Dashboard → Notifications
  - Can set up alerts for:
    - Traffic spikes
    - Security events
    - DNS changes

---

## Post-Launch Security Maintenance

### Weekly Tasks

- [ ] Review Calibre-Web access logs
- [ ] Check Cloudflare Analytics for unusual activity
- [ ] Verify cloudflared service is still running

### Monthly Tasks

- [ ] Review user accounts - remove inactive users
- [ ] Check for Calibre-Web updates
- [ ] Review user permissions (are they still appropriate?)
- [ ] Backup Calibre-Web configuration (`app.db`)

### Quarterly Tasks

- [ ] Rotate admin passwords
- [ ] Audit full user list
- [ ] Review security settings
- [ ] Check for cloudflared updates

---

## Security Incident Response

### If You Suspect Unauthorized Access:

1. **Immediate Actions:**
   - [ ] Stop cloudflared service: `Stop-Service cloudflared`
   - [ ] Change all admin passwords
   - [ ] Review all user accounts in Calibre-Web
   - [ ] Check Calibre-Web access logs for suspicious activity

2. **Investigation:**
   - [ ] Review Cloudflare Analytics for unusual traffic
   - [ ] Check Windows Event Logs
   - [ ] Review cloudflared logs

3. **Remediation:**
   - [ ] Delete any suspicious user accounts
   - [ ] Reset passwords for all legitimate users
   - [ ] Consider regenerating Cloudflare Tunnel
   - [ ] Review and tighten permissions

4. **Prevention:**
   - [ ] Enable Cloudflare security features
   - [ ] Implement stricter user permissions
   - [ ] Consider adding 2FA (via Cloudflare Access - paid)

---

## Quick Security Audit Commands

Run these periodically to verify security:

### Check cloudflared service:
```powershell
Get-Service cloudflared | Select-Object Name, Status, StartType
```

### Check Calibre-Web is NOT publicly accessible on port 8083:
```powershell
Get-NetTCPConnection -LocalPort 8083 | Select-Object LocalAddress, State
# Should show 127.0.0.1 (localhost) only, NOT 0.0.0.0 (all interfaces)
```

### Verify no firewall rules exposing private services:
```powershell
Get-NetFirewallRule | Where-Object {
    $_.Direction -eq "Inbound" -and
    ($_.LocalPort -eq "8080" -or $_.LocalPort -eq "8989" -or $_.LocalPort -eq "9696")
}
# Should return nothing (no rules)
```

### Check Cloudflare Tunnel status:
```powershell
cloudflared tunnel list
cloudflared tunnel info calibre-web-tunnel
```

---

## Security Best Practices Summary

### Passwords
- ✅ 12+ characters minimum
- ✅ Mix of uppercase, lowercase, numbers, symbols
- ✅ Unique password for each service
- ✅ Stored in password manager
- ❌ Never reuse passwords
- ❌ Never share via email/text

### User Management
- ✅ Separate accounts for each person
- ✅ Minimum necessary permissions
- ✅ Review and audit regularly
- ✅ Remove inactive users
- ❌ Never share admin credentials
- ❌ Never allow public registration

### Network Security
- ✅ Only expose necessary services (Calibre-Web only)
- ✅ Use Cloudflare Tunnel (no port forwarding)
- ✅ Keep firewall enabled
- ✅ Monitor access logs
- ❌ Never expose qBittorrent/Sonarr/Prowlarr
- ❌ Never disable Windows Firewall

### Private Tracker Protection
- ✅ Your IP stays hidden (Cloudflare Tunnel)
- ✅ No connection between Calibre-Web and torrent client
- ✅ Ebooks are "finished products" (no tracker metadata)
- ✅ Monitoring for unusual activity
- ❌ Never expose torrent-related services
- ❌ Never share torrent client access

---

## Security Resources

- **Cloudflare Security Best Practices:** https://developers.cloudflare.com/fundamentals/security/
- **Calibre-Web Security:** https://github.com/janeczku/calibre-web/wiki/Security
- **Password Manager Recommendations:**
  - Bitwarden (free, open source)
  - 1Password (paid, very polished)
  - LastPass (freemium)

---

## Final Pre-Launch Checklist

Before sharing URL with family/friends, verify:

- [ ] Admin password changed from default
- [ ] Public registration disabled
- [ ] Anonymous browsing disabled
- [ ] User accounts created with appropriate permissions
- [ ] Proxy headers enabled
- [ ] ONLY Calibre-Web exposed via Cloudflare Tunnel
- [ ] cloudflared service running and set to auto-start
- [ ] External access tested and working
- [ ] SSL certificate valid
- [ ] Access logs reviewed
- [ ] Backup of configuration created

---

**Congratulations!** If all items above are checked, your Calibre-Web remote access is secure and ready to share with family and friends.

**Share with users:**
- URL: https://library.yourdomain.com
- Their username and password (via secure method - Signal, in person, etc.)
- Brief usage instructions

**Last Updated:** 2025-11-04
**Next Security Review:** _____________ (set reminder for 1 week from now)
