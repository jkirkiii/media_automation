# Calibre-Web Remote Access - Configuration Decisions Guide

**Purpose:** This document summarizes the key configuration decisions you'll make during Cloudflare Tunnel setup for Calibre-Web remote access.

**Before You Begin:** Review the complete setup guide at `Calibre-Web_Remote_Access_Guide.md`

---

## Decision Summary

Here are the key choices you'll need to make. I'll walk you through each one below.

| Decision | Your Choice | Notes |
|----------|-------------|-------|
| **1. Domain Name** | mnemo.info | e.g., `yourfamily.com`, `smithbooks.com` |
| **2. Subdomain** | `books` | Full URL: `books.mnemo.info` (confirmed) |
| **3. Domain Registrar** | Porkbun | Recommended: Porkbun or Namecheap (~$10/year) |
| **4. User Access Model** | Manual creation | Manual creation vs Self-registration |
| **5. Anonymous Browsing** | Require login | Require login vs Allow public browsing |
| **6. Email/Kindle Support** | Enable SMTP | Enable SMTP for Send-to-Kindle? |
| **7. Email Provider** | Gmail | Gmail, Outlook, or other SMTP service |
| **8. User Permissions** | Download, browse, read online, send to email | What can family/friends do? |

---

## Decision Details

### 1. Domain Name

**Question:** What domain name do you want to register?

**Cost:** ~$10-15/year for `.com` domain

**Examples:**
- Your family name: `smithfamily.com`, `johnsons.com`
- Generic: `ourlibrary.com`, `familybooks.com`
- Personal: `yourname.com`

**Recommendation:** Choose something memorable that you wouldn't mind sharing with family/friends

**Your Choice:** mnemo.info

**Where to Buy:**
- **Porkbun** - Clean interface, no upsells (~$10/year)
- **Namecheap** - Popular, often first-year discounts (~$0.99 first year, then $10-13/year)
- **Cloudflare Registrar** - At-cost pricing (~$9/year, requires Cloudflare account first)

---

### 2. Subdomain for Calibre-Web

**Question:** What subdomain should we use for your ebook library?

**Your Choice:** `books` (confirmed)

**Full URL:** `books.mnemo.info`

**Why this matters:** This is the URL you'll share with family/friends

**Alternatives considered:**
- `books.yourdomain.com`
- `calibre.yourdomain.com`
- `ebooks.yourdomain.com`

---

### 3. User Account Management

**Question:** How should family/friends get accounts?

**Option A: Manual Creation (Recommended)**
- ✅ **You create** each account individually
- ✅ More secure - you control who has access
- ✅ Can customize permissions per user
- ❌ Requires you to set up each person

**Option B: Self-Registration**
- ⚠️ Users can **sign up themselves**
- ⚠️ Less control over who accesses your library
- ⚠️ Need to monitor for unauthorized accounts
- ✅ Less work for you

**Recommendation:** **Manual Creation** - Better security, especially with private tracker concerns

**Your Choice:** Manual Creation

**Implementation:**
- Manual: You'll create user accounts in Calibre-Web admin panel
- Self-Registration: Enable "Allow Public Registration" in Calibre-Web settings

---

### 4. Anonymous Browsing

**Question:** Can people browse your library without logging in?

**Option A: Require Login (Recommended)**
- ✅ More **private** - know who's accessing
- ✅ Track usage per user
- ✅ Control permissions better
- ❌ Slight friction for users (must log in)

**Option B: Allow Anonymous Browsing**
- ⚠️ Anyone with the URL can **browse** your catalog
- ⚠️ Less privacy - no tracking of who's viewing
- ✅ Easier for casual browsing
- ⚠️ Still requires login to download

**Recommendation:** **Require Login** for privacy and tracking

**Your Choice:** Require Login

**Implementation:**
- Require Login: Disable "Allow Anonymous Browsing" in Calibre-Web Feature Configuration
- Allow Anonymous: Enable "Allow Anonymous Browsing"

---

### 5. User Permissions (For Family/Friends)

**Question:** What should family/friends be able to do?

**Recommended Permissions:**

| Permission | Recommended | Why |
|------------|-------------|-----|
| **Download** | ✅ Enable | They can download ebooks to their devices |
| **Browse** | ✅ Enable | They can search and view the catalog |
| **Read Online** | ✅ Enable | They can read books in the browser |
| **Send to Kindle/Email** | ✅ Enable | They can email books to their Kindle/devices |
| **Upload** | ❌ Disable | Prevents unauthorized book uploads |
| **Edit Metadata** | ❌ Disable | Prevents accidental changes to book info |
| **Delete Books** | ❌ Disable | Prevents accidental deletions |
| **Admin Access** | ❌ Disable | Keep admin for yourself only |

**Your Choices:**
- Download: ✅ Enable ☐ Disable
- Browse: ✅ Enable ☐ Disable
- Read Online: ✅ Enable ☐ Disable
- Send to Kindle: ✅ Enable ❌ Disable
- Upload: ☐ Enable ❌ Disable
- Edit Metadata: ☐ Enable ❌ Disable
- Delete Books: ☐ Enable ❌ Disable

**Special Cases:**
- **Trusted family member** who helps manage library: Could enable Upload + Edit
- **Kids' accounts**: Maybe disable Download, enable Read Online only
- **Read-only accounts**: Enable Browse and Read Online, disable Download

---

### 6. Email/Send to Kindle Setup

**Question:** Do you want to enable "Send to Kindle" functionality?

**What it does:** Users can click a button to email books directly to their Kindle or email address

**Option A: Enable Email Sending**
- ✅ Users can **send books to Kindle** automatically
- ✅ Very convenient for Kindle users
- ✅ Can email books to any address
- ⚠️ Requires SMTP server configuration
- ⚠️ Requires email password/credentials

**Option B: Disable Email Sending**
- ✅ Simpler setup - no SMTP needed
- ❌ Users must **manually download** books and transfer to Kindle
- ❌ Less convenient

**Recommendation:** **Enable** if you or family use Kindles (worth the extra setup)

**Your Choice:** ✅ Enable ☐ Disable

---

### 7. Email Provider (If Enabling Email)

**Question:** Which email service will you use for sending books?

**Option A: Gmail (Recommended for most)**
- ✅ **Free** and reliable
- ✅ Well-documented
- ⚠️ Requires App Password (not regular password)
- ✅ 500 emails/day limit (plenty for personal use)

**Settings:**
```
SMTP Hostname: smtp.gmail.com
SMTP Port: 587
Encryption: StartTLS
Username: youremail@gmail.com
Password: [App Password - generate at https://myaccount.google.com/apppasswords]
```

**Option B: Outlook/Hotmail**
- ✅ Free and reliable
- ✅ No app password needed (use regular password)

**Settings:**
```
SMTP Hostname: smtp-mail.outlook.com
SMTP Port: 587
Encryption: StartTLS
Username: youremail@outlook.com
Password: [Your Outlook password]
```

**Option C: Your ISP or Custom Email**
- Check with your email provider for SMTP settings

**Your Choice:** Gmail

**Your Email Address:** ________________

---

### 8. Cloudflare Account Email

**Question:** What email should you use for your Cloudflare account?

**Recommendation:** Use the **same email** as your domain registrar for easier management

**Your Choice:** YOUR_EMAIL@gmail.com

---

## Security Decisions

### Admin Account Strategy

**Recommendation:** Create **two admin accounts**

1. **Primary Admin** (e.g., `rokon_admin`)
   - Your main administrative account
   - Use for day-to-day management
   - Strong unique password

2. **Emergency Admin** (keep the default `admin` account)
   - Change the password from `admin123`
   - Use only for emergency recovery
   - Store password in password manager

**Your Admin Username:** (see config.ps1)

---

### Password Strategy

**For Admin Account:**
- ✅ Use a **strong, unique password** (12+ characters, mix of letters/numbers/symbols)
- ✅ Store in password manager (LastPass, 1Password, Bitwarden, etc.)
- ❌ Don't reuse passwords from other services

**For User Accounts:**
- **Option A:** You generate strong passwords, send securely to users (Signal, in-person)
- **Option B:** You create accounts with temporary passwords, users change on first login
- **Option C:** If self-registration enabled, users create their own

**Your Choice:** Option B

---

## Summary Checklist

Before starting setup, confirm you have answers for:

- [ ] Domain name chosen: mnemo.info
- [ ] Domain registrar chosen: Porkbun
- [ ] User access model: ✅ Manual ☐ Self-registration
- [ ] Anonymous browsing: ✅ Require login ☐ Allow anonymous
- [ ] Email sending: ✅ Enable ☐ Disable
- [ ] Email provider (if enabled): Gmail
- [ ] User permissions decided (see table above)
- [ ] Admin account strategy: (see config.ps1)
- [ ] Cloudflare account email: YOUR_EMAIL@gmail.com

---

## What Happens Next?

Once you've made these decisions, the setup process follows this order:

### Phase 1: Domain Setup (15 min)
1. Register domain at chosen registrar
2. Create Cloudflare account
3. Add domain to Cloudflare
4. Update nameservers at registrar

### Phase 2: Cloudflare Tunnel (20 min)
5. Install cloudflared on Windows
6. Authenticate with Cloudflare
7. Create tunnel pointing to localhost:8083
8. Set up DNS record (library.yourdomain.com)
9. Install as Windows service

### Phase 3: Calibre-Web Security (15 min)
10. Change admin password
11. Create user accounts
12. Configure permissions
13. Set up SMTP (if enabling email)
14. Test access controls

### Phase 4: Testing (10 min)
15. Test external access from mobile/different network
16. Verify SSL certificate
17. Test user logins
18. Test Send to Kindle (if enabled)

---

## Need Help Deciding?

### Minimal Setup (Fastest)
- **User Access:** Manual creation
- **Anonymous Browsing:** Require login
- **Email:** Disable for now (add later if needed)
- **User Permissions:** Download, Browse, Read Online only

### Recommended Setup (Best Experience)
- **User Access:** Manual creation
- **Anonymous Browsing:** Require login
- **Email:** Enable with Gmail
- **User Permissions:** Download, Browse, Read Online, Send to Kindle

### Maximum Security Setup
- **User Access:** Manual creation
- **Anonymous Browsing:** Require login
- **Email:** Enable (helps avoid downloads if you're concerned about file sharing)
- **User Permissions:** Read Online and Send to Email only (no direct downloads)

---

## Questions to Ask Yourself

1. **Who will use this?**
   - Just family (5-10 people) → Manual creation
   - Friends + family (20+ people) → Consider self-registration

2. **Do people use Kindles?**
   - Yes → Enable email/Kindle support
   - No → Can skip email setup

3. **How much control do you want?**
   - Full control → Manual accounts, require login, limited permissions
   - More relaxed → Self-registration, allow downloads, less restrictions

4. **Private tracker concerns?**
   - High → Require login, no anonymous browsing, careful user permissions
   - Low → More flexibility

---

## Resources

- **Full Setup Guide:** `Calibre-Web_Remote_Access_Guide.md`
- **Cloudflare Tunnel Docs:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **Calibre-Web Features:** https://github.com/janeczku/calibre-web/wiki

---

## Notes & Custom Decisions

Use this space to note any custom decisions or special requirements:

```
[Your notes here]
```

---

**Last Updated:** 2025-11-11
**Next Step:** Review full setup guide and begin Phase 1 (Domain Registration)
