# Credential Management Guide

## Overview

This guide explains how to securely manage API keys, passwords, and other sensitive credentials in this project without committing them to version control.

## Problem

Previously, API keys and credentials were hardcoded in scripts:
- **Prowlarr API Key**: Hardcoded in `Connect-Prowlarr-To-Sonarr.ps1`
- **Sonarr API Key**: Hardcoded in `Connect-Prowlarr-To-Sonarr.ps1`
- **Username**: Documented in `CLAUDE.md`

This caused security concerns when committing to git.

## Solution

We now use a **credential configuration file** approach:

1. **`config.ps1.template`** - Template file (committed to git)
2. **`config.ps1`** - Your actual credentials (gitignored, never committed)
3. Scripts load credentials from `config.ps1` automatically

---

## Setup Instructions

### Step 1: Create Your Credential File

Copy the template to create your credential file:

```powershell
Copy-Item config.ps1.template config.ps1
```

### Step 2: Fill In Your Credentials

Open `config.ps1` in a text editor and replace the placeholder values:

```powershell
# Prowlarr Configuration
$ProwlarrUrl = "http://localhost:9696"
$ProwlarrApiKey = "YOUR_ACTUAL_PROWLARR_API_KEY"

# Sonarr Configuration
$SonarrUrl = "http://localhost:8989"
$SonarrApiKey = "YOUR_ACTUAL_SONARR_API_KEY"

# qBittorrent Configuration
$qBittorrentUrl = "http://localhost:8080"
$qBittorrentUsername = "your_username"
$qBittorrentPassword = "your_password"
```

### Step 3: Verify .gitignore Protection

Check that `config.ps1` is listed in `.gitignore`:

```powershell
git check-ignore config.ps1
```

Expected output: `config.ps1` (confirms it will NOT be committed)

---

## How Scripts Use Credentials

Scripts now automatically load credentials from `config.ps1`:

### Example: Connect-Prowlarr-To-Sonarr.ps1

```powershell
# Option 1: Use credentials from config.ps1 (recommended)
.\scripts\Connect-Prowlarr-To-Sonarr.ps1

# Option 2: Provide credentials as parameters (for testing)
.\scripts\Connect-Prowlarr-To-Sonarr.ps1 -ProwlarrApiKey "xxx" -SonarrApiKey "yyy"
```

The script checks for credentials in this order:
1. **Command-line parameters** (if provided)
2. **`config.ps1`** (if file exists)
3. **Error** (if no credentials found)

---

## Finding Your API Keys

### Prowlarr API Key

1. Open Prowlarr: http://localhost:9696
2. Settings → General → Security
3. Copy the **API Key** value

### Sonarr API Key

1. Open Sonarr: http://localhost:8989
2. Settings → General → Security
3. Copy the **API Key** value

### Radarr API Key (when configured)

1. Open Radarr: http://localhost:7878
2. Settings → General → Security
3. Copy the **API Key** value

---

## Security Best Practices

### ✅ DO:
- **Use `config.ps1`** for local credential storage
- **Copy credentials** from web UIs, don't type them manually
- **Regenerate API keys** if they're accidentally committed
- **Keep `config.ps1` local** - never share or commit it
- **Use template files** (`.template` extension) for scripts with credentials

### ❌ DON'T:
- **Don't hardcode credentials** directly in scripts
- **Don't commit `config.ps1`** to version control
- **Don't share credentials** via email/chat (use password manager)
- **Don't use the same password** across different services

---

## What's Protected by .gitignore

The following files are automatically ignored and will NOT be committed:

```
config.ps1           # Your actual credentials
config.json          # JSON credential files
credentials.json     # Credential storage
secrets.yml          # YAML secrets
secrets.yaml         # YAML secrets
*.key                # Private keys
*.pem                # SSL certificates
```

---

## Migrating Existing Scripts

If you have scripts with hardcoded credentials, convert them using this pattern:

### Before (Insecure):
```powershell
# Hardcoded credentials
$ApiKey = "abc123def456"
```

### After (Secure):
```powershell
param(
    [string]$ApiKey
)

# Load from config.ps1 if not provided
if (-not $ApiKey) {
    $configPath = Join-Path $PSScriptRoot "..\config.ps1"
    if (Test-Path $configPath) {
        . $configPath
    } else {
        Write-Host "ERROR: No credentials found!" -ForegroundColor Red
        exit 1
    }
}
```

---

## Troubleshooting

### Error: "No credentials provided"

**Problem**: Script can't find `config.ps1`

**Solution**:
1. Check that `config.ps1` exists in the project root
2. Verify you're running the script from the correct directory
3. Create `config.ps1` from `config.ps1.template` if missing

### Error: "Unauthorized" or "Invalid API Key"

**Problem**: API key in `config.ps1` is incorrect or expired

**Solution**:
1. Open the web UI for the service (Prowlarr/Sonarr/etc.)
2. Go to Settings → General → Security
3. Copy the current API key
4. Update `config.ps1` with the correct key

### Script shows "Using script defaults" warning

**Problem**: Script couldn't find `config.ps1` and is falling back to defaults

**Solution**:
- Create `config.ps1` from template
- Or provide credentials via command-line parameters

---

## Template File Reference

| Template File | Purpose | Creates |
|--------------|---------|---------|
| `config.ps1.template` | Master credential template | `config.ps1` |
| `scripts/*.ps1.template` | Script templates with credential loading | `scripts/*.ps1` |

---

## Emergency: API Key Compromised

If you accidentally commit an API key:

### Immediate Actions:
1. **Regenerate the API key** in the web UI immediately
2. **Update `config.ps1`** with the new key
3. **Reconnect services** that use the old key

### Optional: Remove from Git History
- See `docs/Removing_Sensitive_Data_From_Git.md` for advanced cleanup
- Not required if you've regenerated the key

---

## Additional Resources

- [GitHub: Removing Sensitive Data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
- [Git Filter-Repo](https://github.com/newren/git-filter-repo)

---

**Last Updated**: 2025-10-28
**Status**: Credential management system implemented and operational
