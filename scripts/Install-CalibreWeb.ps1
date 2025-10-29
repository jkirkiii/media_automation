# Install-CalibreWeb.ps1
# Installs and configures Calibre-Web

param(
    [string]$ConfigPath = "A:\Media\Calibre-Web-Config",
    [string]$CalibreLibrary = "A:\Media\Calibre"
)

$ErrorActionPreference = "Stop"

Write-Host "=== CALIBRE-WEB INSTALLATION ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify Python installation
Write-Host "Step 1: Verifying Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  [PASS] Python installed: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Python not found!" -ForegroundColor Red
    Write-Host "  Please install Python from python.org" -ForegroundColor Red
    exit 1
}

# Check pip
try {
    $pipVersion = python -m pip --version 2>&1
    Write-Host "  [PASS] pip installed: $pipVersion" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] pip not found!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Verify Calibre library exists
Write-Host "Step 2: Verifying Calibre library..." -ForegroundColor Yellow
if (Test-Path $CalibreLibrary) {
    $bookCount = (Get-ChildItem -Path $CalibreLibrary -Directory | Where-Object { $_.Name -notlike ".*" }).Count
    Write-Host "  [PASS] Calibre library found at: $CalibreLibrary" -ForegroundColor Green
    Write-Host "  Found $bookCount author directories" -ForegroundColor Gray
} else {
    Write-Host "  [FAIL] Calibre library not found at: $CalibreLibrary" -ForegroundColor Red
    Write-Host "  Please verify the path is correct" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Create config directory
Write-Host "Step 3: Creating configuration directory..." -ForegroundColor Yellow
if (-not (Test-Path $ConfigPath)) {
    New-Item -Path $ConfigPath -ItemType Directory -Force | Out-Null
    Write-Host "  [PASS] Created: $ConfigPath" -ForegroundColor Green
} else {
    Write-Host "  [INFO] Directory already exists: $ConfigPath" -ForegroundColor Cyan
}

Write-Host ""

# Step 4: Install Calibre-Web
Write-Host "Step 4: Installing Calibre-Web..." -ForegroundColor Yellow
Write-Host "  This may take a few minutes..." -ForegroundColor Gray
Write-Host ""

try {
    # Upgrade pip first
    Write-Host "  Upgrading pip..." -ForegroundColor Gray
    python -m pip install --upgrade pip --quiet

    # Install calibreweb
    Write-Host "  Installing calibreweb package..." -ForegroundColor Gray
    python -m pip install calibreweb --quiet

    Write-Host ""
    Write-Host "  [PASS] Calibre-Web installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Installation failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 5: Create startup script
Write-Host "Step 5: Creating startup script..." -ForegroundColor Yellow

$startupScript = @"
# Start-CalibreWeb.ps1
# Starts Calibre-Web server

`$ConfigPath = "$ConfigPath"
`$Port = 8083

Write-Host "=== STARTING CALIBRE-WEB ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration: `$ConfigPath" -ForegroundColor White
Write-Host "Port: `$Port" -ForegroundColor White
Write-Host ""
Write-Host "Access Calibre-Web at: http://localhost:`$Port" -ForegroundColor Green
Write-Host ""
Write-Host "Default login:" -ForegroundColor Yellow
Write-Host "  Username: admin" -ForegroundColor White
Write-Host "  Password: admin123" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Change the admin password after first login!" -ForegroundColor Red
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
Write-Host ""
Write-Host "---" -ForegroundColor Gray
Write-Host ""

# Start Calibre-Web
cps -p "`$ConfigPath" -i 0.0.0.0 -port `$Port
"@

$startupScriptPath = "scripts\Start-CalibreWeb.ps1"
$startupScript | Out-File -FilePath $startupScriptPath -Encoding UTF8

Write-Host "  [PASS] Startup script created: $startupScriptPath" -ForegroundColor Green
Write-Host ""

# Step 6: Create initial configuration guide
Write-Host "Step 6: Creating configuration guide..." -ForegroundColor Yellow

$configGuide = @"
# Calibre-Web Initial Configuration

## First-Time Setup

1. **Start Calibre-Web:**
   ``````powershell
   .\scripts\Start-CalibreWeb.ps1
   ``````

2. **Access Web Interface:**
   - Open browser: http://localhost:8083
   - Or from another device: http://[YOUR-PC-IP]:8083

3. **Login with default credentials:**
   - Username: admin
   - Password: admin123

4. **Configure Calibre Library Path:**
   - Click "Admin" (top right) → "Basic Configuration"
   - Or go to: http://localhost:8083/admin/config
   - Set "Location of Calibre database": $CalibreLibrary
   - Click "Save"
   - Calibre-Web will restart

5. **Change Admin Password (IMPORTANT!):**
   - Click "Admin" → "Edit Users" → "admin"
   - Set new secure password
   - Click "Save"

6. **Configure UI Settings:**
   - Admin → "UI Configuration"
   - Books per page: 50-100
   - Random books to show: 10-20
   - Language: English
   - Theme: Choose your preference
   - Click "Save"

7. **Enable Features:**
   - Admin → "Feature Configuration"
   - Enable Uploads: Yes (if you want to add books via web)
   - Enable Book Conversion: Yes (if you want format conversion)
   - Enable Kobo Sync: No (unless you have Kobo e-reader)
   - Click "Save"

## Usage Tips

### Browse Your Library
- Click "Books" to see all books
- Use sidebar to filter by Author, Series, Tags, etc.
- Click cover images to see book details

### Read a Book
- Click on a book
- Click "Read in browser" button
- Use arrow keys or click to turn pages
- Adjust font size with buttons in reader

### Download Books
- Click on a book
- Click "Download" button
- Choose format (EPUB, MOBI, etc.)
- File downloads to your browser's download folder

### Create Personal Shelves
- Click on a book
- Click "Add to shelf" button
- Create shelves like "Currently Reading", "Want to Read", etc.
- View your shelves from the sidebar

### Search
- Use search box in top navigation
- Search by title, author, series, tags, etc.

## Stopping Calibre-Web

- Press Ctrl+C in the terminal window where it's running
- Or close the terminal window

## Troubleshooting

### Can't access from another device
- Check Windows Firewall
- May need to allow port 8083 through firewall:
  ``````powershell
  New-NetFirewallRule -DisplayName "Calibre-Web" -Direction Inbound -Protocol TCP -LocalPort 8083 -Action Allow
  ``````

### Books not showing up
- Verify Calibre library path is correct
- Make sure path points to the folder containing metadata.db
- Check that Calibre desktop is NOT running (conflicts)

### Permission errors
- Make sure Calibre-Web has read access to $CalibreLibrary
- Run PowerShell as administrator if needed

## Next Steps

1. Browse your library in the web interface
2. Test reading a book in your browser
3. Try accessing from your phone/tablet
4. Create personal shelves
5. Add ratings to books you've read

Enjoy your library!
"@

$configGuidePath = "docs\Calibre-Web_Initial_Setup.md"
$configGuide | Out-File -FilePath $configGuidePath -Encoding UTF8

Write-Host "  [PASS] Configuration guide created: $configGuidePath" -ForegroundColor Green
Write-Host ""

# Installation complete
Write-Host "===============================================================" -ForegroundColor Green
Write-Host "           CALIBRE-WEB INSTALLATION COMPLETE                   " -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "What was installed:" -ForegroundColor Cyan
Write-Host "  - Calibre-Web Python package" -ForegroundColor White
Write-Host "  - Configuration directory: $ConfigPath" -ForegroundColor White
Write-Host "  - Startup script: scripts\Start-CalibreWeb.ps1" -ForegroundColor White
Write-Host "  - Setup guide: docs\Calibre-Web_Initial_Setup.md" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run: .\scripts\Start-CalibreWeb.ps1" -ForegroundColor White
Write-Host "  2. Open browser: http://localhost:8083" -ForegroundColor White
Write-Host "  3. Login with: admin / admin123" -ForegroundColor White
Write-Host "  4. Configure Calibre library path: $CalibreLibrary" -ForegroundColor White
Write-Host "  5. Change admin password!" -ForegroundColor White
Write-Host ""
Write-Host "Full setup instructions in: docs\Calibre-Web_Initial_Setup.md" -ForegroundColor Cyan
Write-Host ""
