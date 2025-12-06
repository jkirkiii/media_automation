# Calibre-Web Remote Access Setup Guide

**Status:** In Progress - Documentation Created
**Last Updated:** 2025-11-04
**Method:** Cloudflare Tunnel (Zero Trust)

## Overview

This guide walks through setting up secure external access to your Calibre-Web ebook library using Cloudflare Tunnel. This allows family and friends to access your ebook collection from anywhere via a web browser without exposing your home IP address or requiring VPN setup.

## Architecture

```
User's Browser (anywhere in the world)
         ↓
    HTTPS (encrypted)
         ↓
Cloudflare Network (DDoS protection, SSL termination)
         ↓
Cloudflare Tunnel (cloudflared daemon)
         ↓
Your Windows PC (localhost only)
         ↓
Calibre-Web (http://localhost:8083)
```

### Key Benefits

- **No port forwarding required** - Works behind NAT/firewall
- **Your IP stays hidden** - Visitors see Cloudflare's IP, not yours
- **Free SSL/HTTPS** - Automatic encryption via Cloudflare
- **No dynamic DNS needed** - Cloudflare handles everything
- **Built-in DDoS protection** - Cloudflare's infrastructure protects you
- **Easy user access** - Just a URL in a browser, no VPN client needed

### Security Considerations

**What's Protected:**
- ✅ Your home IP address is hidden from all visitors
- ✅ Calibre-Web is isolated (no connection to qBittorrent/Sonarr)
- ✅ HTTPS encryption for all traffic
- ✅ DDoS protection via Cloudflare

**What to Be Aware Of:**
- ⚠️ Cloudflare can see HTTP traffic metadata (book titles in URLs, access patterns)
- ⚠️ Traffic passes through Cloudflare's servers (not end-to-end encrypted to your server)
- ⚠️ Misconfiguration could expose other services - we'll prevent this

**Private Tracker Safety:**
- ✅ **SAFE**: Calibre-Web has NO connection to your torrent client
- ✅ **SAFE**: Your actual IP address stays hidden from all visitors
- ✅ **SAFE**: Ebooks are finished files with no tracker metadata
- ⚠️ **CRITICAL**: Never expose qBittorrent, Sonarr, or Prowlarr through Cloudflare

## Prerequisites

### 1. Domain Name (Required)

You need to own a domain name. Options:

**Recommended (Budget-Friendly):**
- **Porkbun** - Clean interface, ~$10/year for `.com`, no hidden fees
- **Namecheap** - Popular, ~$9-13/year for `.com` (often $0.99 first year)
- **Cloudflare Registrar** - At-cost pricing, ~$9/year for `.com`

**Free Options (Less Recommended):**
- Freenom (`.tk`, `.ml`, `.ga`) - Can be reclaimed, unreliable
- Free subdomain services - Limited functionality

**Recommendation:** Invest $10/year in a `.com` domain for reliability and professionalism.

### 2. Cloudflare Account (Free)

- Sign up at https://dash.cloudflare.com/sign-up
- Free tier is sufficient for this setup
- No credit card required for basic features

### 3. Current System Status

**Already Configured:**
- ✅ Calibre-Web installed and running
- ✅ Calibre library at `A:\Media\Calibre` (~70 books)
- ✅ Calibre-Web accessible at `http://localhost:8083`
- ✅ Default credentials: `admin` / `admin123`

**What We'll Add:**
- Cloudflared daemon (Windows service)
- Cloudflare Tunnel configuration
- Enhanced Calibre-Web security settings
- User account management

## Setup Process Overview

### Phase 1: Domain & Cloudflare Setup (15 minutes)
1. Register domain name
2. Create Cloudflare account
3. Add domain to Cloudflare
4. Update nameservers at domain registrar

### Phase 2: Cloudflare Tunnel Installation (20 minutes)
5. Install cloudflared on Windows
6. Authenticate cloudflared with Cloudflare account
7. Create tunnel configuration
8. Configure tunnel to point to Calibre-Web (localhost:8083)
9. Set up DNS record (`library.yourdomain.com`)

### Phase 3: Calibre-Web Security Hardening (15 minutes)
10. Change default admin password
11. Create user accounts for family/friends
12. Configure user permissions
13. Enable security features
14. Test access controls

### Phase 4: Testing & Verification (10 minutes)
15. Test external access from mobile/different network
16. Verify SSL certificate
17. Test user accounts
18. Review access logs

**Total Time:** ~60 minutes

## Detailed Step-by-Step Instructions

### Phase 1: Domain & Cloudflare Setup

#### Step 1: Register Domain Name

1. **Choose a domain registrar:**
   - Go to **Porkbun.com** or **Namecheap.com**

2. **Search for your desired domain:**
   - Example: `smithfamily.com`, `yourname.com`, `johnsbooks.com`
   - Choose something memorable for family/friends

3. **Purchase the domain:**
   - Select `.com` for best compatibility (~$10/year)
   - Add to cart and complete checkout
   - **Important:** Note your domain name for next steps

4. **Access your registrar's dashboard:**
   - You'll need to change nameservers later
   - Keep this tab open

#### Step 2: Create Cloudflare Account

1. **Sign up for Cloudflare:**
   - Go to https://dash.cloudflare.com/sign-up
   - Use your email and create a strong password
   - Verify your email address

2. **Choose Free plan:**
   - When prompted, select the **Free** plan
   - No credit card required

#### Step 3: Add Domain to Cloudflare

1. **In Cloudflare Dashboard, click "Add a Site"**

2. **Enter your domain name:**
   - Enter the domain you just registered (e.g., `yourdomain.com`)
   - Click "Add site"

3. **Select Free plan:**
   - Choose the **Free** plan
   - Click "Continue"

4. **Quick scan:**
   - Cloudflare will scan for existing DNS records
   - For a brand new domain, this will be empty - that's fine
   - Click "Continue"

5. **Note the nameservers:**
   - Cloudflare will show you two nameservers like:
     ```
     ahmed.ns.cloudflare.com
     jess.ns.cloudflare.com
     ```
   - **Keep this page open** - you'll need these in the next step

#### Step 4: Update Nameservers at Domain Registrar

**For Porkbun:**
1. Log into Porkbun account
2. Go to "Domain Management"
3. Click your domain name
4. Scroll to "Authoritative Nameservers"
5. Click "Edit"
6. Select "Use Custom Nameservers"
7. Enter the two Cloudflare nameservers
8. Click "Update"

**For Namecheap:**
1. Log into Namecheap account
2. Go to "Domain List"
3. Click "Manage" next to your domain
4. Find "Nameservers" section
5. Select "Custom DNS"
6. Enter the two Cloudflare nameservers
7. Click the checkmark to save

**Important:** DNS propagation can take 24-48 hours, but usually completes in 15-30 minutes.

5. **Back in Cloudflare, click "Done, check nameservers"**
   - Cloudflare will monitor the change
   - You'll receive an email when it's complete

---

### Phase 2: Cloudflare Tunnel Installation

**Note:** We'll create PowerShell scripts to automate this process.

#### Step 5: Install cloudflared on Windows

**Manual Installation:**
1. Download cloudflared for Windows:
   - Go to: https://github.com/cloudflare/cloudflared/releases
   - Download `cloudflared-windows-amd64.exe`
   - Or download `cloudflared-windows-amd64.msi` for installer

2. **Recommended:** Use the MSI installer for automatic PATH setup
   - Run the `.msi` installer
   - Follow the installation wizard
   - Installs to `C:\Program Files\cloudflared\`

3. **Verify installation:**
   ```powershell
   cloudflared --version
   ```

**Automated Installation (via our script):**
```powershell
.\scripts\Install-Cloudflared.ps1
```

#### Step 6: Authenticate cloudflared with Cloudflare

1. **Run authentication command:**
   ```powershell
   cloudflared tunnel login
   ```

2. **Browser will open:**
   - Log into your Cloudflare account
   - Select your domain from the list
   - Click "Authorize"

3. **Certificate saved:**
   - Authentication certificate saved to:
     `C:\Users\[YourUsername]\.cloudflared\cert.pem`
   - This allows cloudflared to create tunnels in your account

#### Step 7: Create Tunnel

1. **Create a named tunnel:**
   ```powershell
   cloudflared tunnel create calibre-web-tunnel
   ```

2. **Note the Tunnel ID:**
   - Output will show a UUID like: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`
   - **Save this Tunnel ID** - you'll need it for configuration

3. **Tunnel credentials saved:**
   - Credentials saved to:
     `C:\Users\[YourUsername]\.cloudflared\[tunnel-id].json`

#### Step 8: Configure Tunnel

1. **Create tunnel configuration file:**
   - Location: `C:\Users\[YourUsername]\.cloudflared\config.yml`

   ```yaml
   tunnel: a1b2c3d4-e5f6-7890-abcd-ef1234567890  # Your tunnel ID
   credentials-file: C:\Users\[YourUsername]\.cloudflared\a1b2c3d4-e5f6-7890-abcd-ef1234567890.json

   ingress:
     - hostname: library.yourdomain.com
       service: http://localhost:8083
     - service: http_status:404
   ```

2. **Customize the configuration:**
   - Replace `a1b2c3d4-e5f6-7890-abcd-ef1234567890` with your actual tunnel ID
   - Replace `[YourUsername]` with your Windows username
   - Replace `library.yourdomain.com` with your chosen subdomain + domain

**Automated Configuration (via our script):**
```powershell
.\scripts\Configure-Cloudflare-Tunnel.ps1 -Domain "yourdomain.com" -Subdomain "library"
```

#### Step 9: Create DNS Record

1. **Route DNS to your tunnel:**
   ```powershell
   cloudflared tunnel route dns calibre-web-tunnel library.yourdomain.com
   ```

2. **Verify in Cloudflare Dashboard:**
   - Go to Cloudflare Dashboard → DNS → Records
   - You should see a CNAME record:
     - Type: `CNAME`
     - Name: `library`
     - Target: `a1b2c3d4-e5f6-7890-abcd-ef1234567890.cfargotunnel.com`
     - Proxied: ✅ (orange cloud)

#### Step 10: Start Tunnel (Testing)

1. **Run tunnel in foreground for testing:**
   ```powershell
   cloudflared tunnel run calibre-web-tunnel
   ```

2. **Verify output:**
   - Should see: `Connection registered` messages
   - No error messages

3. **Test access:**
   - Open browser (can be on same computer for now)
   - Go to: `https://library.yourdomain.com`
   - You should see Calibre-Web login page
   - Note: HTTPS is automatic via Cloudflare

4. **Stop the test:**
   - Press `Ctrl+C` to stop the tunnel

#### Step 11: Install as Windows Service

1. **Install cloudflared as a service:**
   ```powershell
   cloudflared service install
   ```

2. **Verify service installation:**
   ```powershell
   Get-Service cloudflared
   ```

3. **Service should auto-start:**
   - Service runs on boot
   - No need to manually start tunnel
   - Runs in background

4. **Start the service:**
   ```powershell
   Start-Service cloudflared
   ```

5. **Verify service is running:**
   ```powershell
   Get-Service cloudflared | Select-Object Name, Status, StartType
   ```

---

### Phase 3: Calibre-Web Security Hardening

#### Step 12: Change Default Admin Password

1. **Access Calibre-Web:**
   - Go to `http://localhost:8083` or `https://library.yourdomain.com`
   - Login with `admin` / `admin123`

2. **Change admin password:**
   - Click "Admin" in top right
   - Click "Edit Basic Configuration"
   - Go to "User Configuration" section
   - Click "admin" user
   - Set new strong password
   - Click "Save"

3. **Test new password:**
   - Log out
   - Log back in with new password

#### Step 13: Create User Accounts for Family/Friends

1. **Create new users:**
   - Click "Admin" → "Edit Basic Configuration"
   - Go to "Users" section
   - Click "Add New User"

2. **For each user, configure:**
   - **Username:** Their name or email
   - **Email:** Their email address (for password resets and send-to-email features)
   - **Password:** Generate strong password or let them set it
   - **Permissions:** See next step

3. **Recommended permissions for regular users:**
   - ✅ **Download:** Allow downloading ebooks
   - ✅ **Browse:** Browse the library
   - ✅ **Read Books:** View books online
   - ✅ **Send to Kindle:** Email books to Kindle
   - ❌ **Upload:** Disable (prevent unauthorized uploads)
   - ❌ **Edit:** Disable (prevent metadata changes)
   - ❌ **Delete Books:** Disable (prevent deletions)
   - ❌ **Admin:** Disable (no admin access)

4. **Create separate admin account (recommended):**
   - Create a new admin user with a different name (e.g., `rokon_admin`)
   - Give full permissions
   - Use this for your administrative tasks
   - Keep the original `admin` account as emergency backup

#### Step 14: Configure User Permissions & Features

1. **Enable public registration (optional):**
   - If you want users to self-register:
     - Admin → Edit Basic Configuration → Feature Configuration
     - Enable "Allow Public Registration"
     - Set "Default User Role" with limited permissions
   - **Recommendation:** Keep disabled, manually create accounts for security

2. **Enable Email (for Send to Kindle):**
   - Admin → Edit Basic Configuration → Feature Configuration
   - Scroll to "E-Mail Server Settings"
   - Configure SMTP:
     - **SMTP Hostname:** Your email provider's SMTP server (e.g., `smtp.gmail.com`)
     - **SMTP Port:** Usually `587` (TLS) or `465` (SSL)
     - **From E-mail:** Your email address
     - **SMTP Username:** Your email
     - **SMTP Password:** Your email password or app-specific password
   - Test email settings
   - Click "Save"

   **Gmail Example:**
   - SMTP Hostname: `smtp.gmail.com`
   - SMTP Port: `587`
   - Encryption: `StartTLS`
   - Username: `youremail@gmail.com`
   - Password: Generate an [App Password](https://support.google.com/accounts/answer/185833)

3. **Configure Send to Kindle:**
   - Users can add their Kindle email in their profile
   - Format: `username@kindle.com`
   - Users must add the sender email to their Amazon Kindle Approved Email list

4. **Anonymous browsing (optional):**
   - Admin → Edit Basic Configuration → Feature Configuration
   - Enable "Allow Anonymous Browsing" if you want public catalog browsing
   - **Recommendation:** Disable for privacy (require login)

#### Step 15: Enable Security Features

1. **Require login for all access:**
   - Admin → Edit Basic Configuration → Feature Configuration
   - Disable "Allow Anonymous Browsing"
   - Ensure all users must log in

2. **Enable password complexity (if available):**
   - Check Feature Configuration for password policies
   - Enable if available in your Calibre-Web version

3. **Session timeout configuration:**
   - Check if session timeout can be configured
   - Default is usually reasonable

4. **Reverse proxy settings:**
   - Admin → Edit Basic Configuration → Feature Configuration
   - Scroll to "Reverse Proxy Configuration"
   - Enable "Use Proxy Headers" (important for Cloudflare)
   - This ensures Calibre-Web sees real client IPs, not Cloudflare's

---

### Phase 4: Testing & Verification

#### Step 16: Test External Access

1. **Test from different network:**
   - Use mobile phone (turn off WiFi, use cellular)
   - Or ask a friend to test
   - Go to `https://library.yourdomain.com`

2. **Verify SSL certificate:**
   - Click the padlock icon in browser
   - Certificate should be issued by Cloudflare
   - Should say "Connection is secure"

3. **Test login:**
   - Log in with a test user account
   - Verify permissions work as expected

4. **Test features:**
   - Browse library
   - Download a book
   - Send to email (if configured)
   - Read online

#### Step 17: Verify Service Auto-Start

1. **Restart your PC**

2. **After reboot, verify services:**
   ```powershell
   Get-Service cloudflared
   ```
   - Should show "Running"

3. **Test access:**
   - Go to `https://library.yourdomain.com`
   - Should work without manually starting anything

#### Step 18: Review Access Logs

1. **Check Calibre-Web access logs:**
   - Admin → Logfiles
   - Review who's accessing and when

2. **Check Cloudflare Analytics:**
   - Cloudflare Dashboard → Analytics & Logs
   - See visitor statistics
   - Monitor for suspicious activity

---

## Configuration Scripts

### Automated Setup Scripts

We'll create PowerShell scripts to automate the installation and configuration:

1. **`Install-Cloudflared.ps1`**
   - Downloads and installs cloudflared
   - Verifies installation
   - Checks PATH configuration

2. **`Configure-Cloudflare-Tunnel.ps1`**
   - Authenticates with Cloudflare
   - Creates tunnel
   - Generates config.yml
   - Creates DNS record
   - Installs Windows service

3. **`Verify-Cloudflare-Tunnel.ps1`**
   - Checks tunnel status
   - Verifies DNS configuration
   - Tests connectivity
   - Reports on service health

4. **`Configure-CalibreWeb-Security.ps1`**
   - Prompts for security settings
   - Creates user accounts via API
   - Configures permissions

---

## Security Best Practices

### Critical Security Rules

**DO:**
- ✅ Use strong, unique passwords for all accounts
- ✅ Only expose Calibre-Web (port 8083) through the tunnel
- ✅ Keep Calibre-Web updated to latest version
- ✅ Monitor access logs regularly
- ✅ Use separate user accounts (not admin) for sharing
- ✅ Enable "Use Proxy Headers" in Calibre-Web for accurate logging
- ✅ Regularly review user accounts and remove inactive users

**DON'T:**
- ❌ **NEVER expose qBittorrent Web UI** (port 8080) through Cloudflare
- ❌ **NEVER expose Sonarr** (port 8989) through Cloudflare
- ❌ **NEVER expose Prowlarr** (port 9696) through Cloudflare
- ❌ Don't use the same password across services
- ❌ Don't give admin access to shared users
- ❌ Don't allow public registration (manually create accounts)
- ❌ Don't allow anonymous browsing

### Firewall Configuration

**No changes needed!** One of the benefits of Cloudflare Tunnel is that it doesn't require opening firewall ports. The tunnel creates an outbound connection to Cloudflare, so your firewall stays closed.

**Verify your firewall blocks incoming connections:**
```powershell
# Check Windows Firewall status
Get-NetFirewallProfile | Select-Object Name, Enabled

# Verify no rules allowing inbound to port 8083
Get-NetFirewallRule | Where-Object {$_.Direction -eq "Inbound" -and $_.LocalPort -eq "8083"}
```

### Monitoring & Maintenance

**Weekly:**
- Review Calibre-Web access logs
- Check Cloudflare Analytics for unusual traffic
- Verify service is running: `Get-Service cloudflared`

**Monthly:**
- Review user accounts and permissions
- Check for Calibre-Web updates
- Review Cloudflare Tunnel logs

**Quarterly:**
- Rotate admin passwords
- Audit user list (remove inactive users)
- Review security settings

---

## Troubleshooting

### Tunnel Not Connecting

**Symptom:** `cloudflared tunnel run` shows connection errors

**Solutions:**
1. Verify tunnel ID in config.yml matches created tunnel
2. Check credentials file path is correct
3. Verify Calibre-Web is running on localhost:8083
4. Check Windows Firewall isn't blocking cloudflared.exe

**Diagnostic commands:**
```powershell
# List all tunnels
cloudflared tunnel list

# Check tunnel info
cloudflared tunnel info calibre-web-tunnel

# Test tunnel connection
cloudflared tunnel run --loglevel debug calibre-web-tunnel
```

### DNS Not Resolving

**Symptom:** `library.yourdomain.com` doesn't resolve

**Solutions:**
1. Verify nameservers updated at domain registrar (can take 24-48 hours)
2. Check DNS record exists in Cloudflare Dashboard
3. Verify CNAME is "Proxied" (orange cloud icon)
4. Clear DNS cache: `ipconfig /flushdns`

**Test DNS:**
```powershell
# Check DNS resolution
nslookup library.yourdomain.com

# Should return Cloudflare IP addresses (not your home IP)
```

### 502 Bad Gateway Error

**Symptom:** Accessing `https://library.yourdomain.com` shows 502 error

**Solutions:**
1. Verify Calibre-Web is running: Open `http://localhost:8083`
2. Check cloudflared service is running: `Get-Service cloudflared`
3. Verify tunnel is connected: `cloudflared tunnel info calibre-web-tunnel`
4. Check config.yml service URL is `http://localhost:8083` (not https)

### Can't Login After Changing Password

**Solution:** Reset password via command line:
```powershell
# Stop Calibre-Web
# Edit the database directly (advanced) or reinstall
# Recommendation: Keep backup of app.db before changes
```

**Prevention:** Always create a backup admin account before changing passwords.

### Service Won't Auto-Start

**Symptom:** Tunnel works manually but not after reboot

**Solutions:**
1. Verify service is installed: `Get-Service cloudflared`
2. Check service start type: Should be "Automatic"
3. Set to automatic if not:
   ```powershell
   Set-Service -Name cloudflared -StartupType Automatic
   Start-Service cloudflared
   ```

---

## Configuration Decisions Reference

This section summarizes the key decisions you'll make during setup:

### 1. Domain Name Choice
- **Question:** What domain name do you want?
- **Examples:** `yourlastname.com`, `familyname.com`, `yourbooks.com`
- **Recommendation:** Something memorable and professional
- **Cost:** ~$10/year for `.com`

### 2. Subdomain Choice
- **Question:** What subdomain for Calibre-Web?
- **Default:** `library.yourdomain.com`
- **Alternatives:** `books.yourdomain.com`, `calibre.yourdomain.com`, `ebooks.yourdomain.com`
- **Your Choice:** `library.yourdomain.com` (confirmed)

### 3. User Access Model
- **Question:** How will users get accounts?
- **Options:**
  - **Manual creation** (recommended) - You create accounts for each person
  - **Self-registration** - Users can sign up themselves (less secure)
- **Recommendation:** Manual creation for better security

### 4. User Permissions
- **Question:** What can users do?
- **Recommended for family/friends:**
  - ✅ Download books
  - ✅ Browse library
  - ✅ Read online
  - ✅ Send to Kindle/Email
  - ❌ Upload books
  - ❌ Edit metadata
  - ❌ Delete books
  - ❌ Admin access

### 5. Anonymous Browsing
- **Question:** Can people browse without logging in?
- **Options:**
  - **Require login** (recommended) - More private, know who's accessing
  - **Allow anonymous** - Public catalog browsing
- **Recommendation:** Require login for privacy and tracking

### 6. Email/Send to Kindle
- **Question:** Enable email sending for books?
- **Options:**
  - **Enable** - Users can email books to themselves/Kindle
  - **Disable** - Download only
- **Recommendation:** Enable for convenience (requires SMTP setup)
- **Email Provider:** Gmail, Outlook, or your email host

### 7. Auto-Update Behavior
- **Question:** How to handle Calibre-Web updates?
- **Current:** Manual updates via pip
- **Future:** Could automate with scripts
- **Recommendation:** Check for updates monthly

---

## Next Steps After Setup

### Immediate (After Setup Complete)
1. ✅ Test access from multiple devices
2. ✅ Share URL with family/friends
3. ✅ Provide login credentials securely (don't email passwords)
4. ✅ Create user guide for family/friends

### Short Term (First Month)
1. Monitor access logs weekly
2. Gather feedback from users
3. Adjust permissions based on usage
4. Consider adding more books to library

### Medium Term (3-6 Months)
1. **Implement Readarr** for automated ebook acquisition
2. **Set up Calibre-Web OPDS** for better mobile app integration
3. **Consider Tailscale VPN** for admin access (hybrid approach)
4. **Automate Calibre library backups**

### Long Term (6+ Months)
1. Evaluate usage patterns
2. Consider premium Cloudflare features if needed
3. Expand to other media types (audiobooks?)
4. Implement automated library organization

---

## Cost Summary

### One-Time Costs
- **Domain Name:** ~$10-13 (first year, often discounted to $0.99)
- **Setup Time:** ~60 minutes of your time

### Recurring Costs (Annual)
- **Domain Renewal:** ~$10-15/year
- **Cloudflare:** $0 (Free tier sufficient)
- **cloudflared:** $0 (Free and open source)
- **Calibre-Web:** $0 (Free and open source)

**Total Annual Cost:** ~$10-15/year for domain only

### What's Free
- Cloudflare Tunnel (no bandwidth limits on Free tier)
- SSL/HTTPS certificates
- DDoS protection
- DNS hosting
- Unlimited users
- Unlimited traffic (within Cloudflare's fair use)

---

## Additional Resources

### Official Documentation
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Calibre-Web Documentation](https://github.com/janeczku/calibre-web/wiki)
- [cloudflared GitHub](https://github.com/cloudflare/cloudflared)

### Community Resources
- [Cloudflare Community Forums](https://community.cloudflare.com/)
- [Calibre-Web GitHub Issues](https://github.com/janeczku/calibre-web/issues)
- [Self-Hosted Reddit](https://www.reddit.com/r/selfhosted/)

### Alternative Solutions (For Future Reference)
- **Tailscale VPN** - For admin access, more secure
- **Caddy** - Alternative reverse proxy (self-hosted)
- **nginx** - Traditional reverse proxy option
- **WireGuard** - VPN alternative to Tailscale

---

## Appendix: Quick Reference Commands

### Cloudflare Tunnel Management
```powershell
# List all tunnels
cloudflared tunnel list

# Get tunnel info
cloudflared tunnel info calibre-web-tunnel

# Run tunnel in foreground (testing)
cloudflared tunnel run calibre-web-tunnel

# Run with debug logging
cloudflared tunnel run --loglevel debug calibre-web-tunnel

# Clean up unused tunnels
cloudflared tunnel cleanup calibre-web-tunnel
```

### Windows Service Management
```powershell
# Check service status
Get-Service cloudflared

# Start service
Start-Service cloudflared

# Stop service
Stop-Service cloudflared

# Restart service
Restart-Service cloudflared

# Check service logs
Get-EventLog -LogName Application -Source cloudflared -Newest 20
```

### DNS Commands
```powershell
# Flush DNS cache
ipconfig /flushdns

# Check DNS resolution
nslookup library.yourdomain.com

# Detailed DNS query
Resolve-DnsName library.yourdomain.com -Type CNAME
```

### Calibre-Web
```powershell
# Start Calibre-Web (if not using service)
.\Start-CalibreWeb.bat

# Check if Calibre-Web is running
Get-NetTCPConnection -LocalPort 8083

# Access local Calibre-Web
Start-Process "http://localhost:8083"
```

---

## Document Version History

- **v1.0** (2025-11-04) - Initial documentation created
- Setup in progress - awaiting domain registration
