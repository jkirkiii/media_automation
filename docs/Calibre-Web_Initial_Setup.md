# Calibre-Web Initial Configuration

## First-Time Setup

1. **Start Calibre-Web:**
   ```powershell
   .\scripts\Start-CalibreWeb.ps1
   ```

2. **Access Web Interface:**
   - Open browser: http://localhost:8083
   - Or from another device: http://[YOUR-PC-IP]:8083

3. **Login with default credentials:**
   - Username: admin
   - Password: admin123

4. **Configure Calibre Library Path:**
   - Click "Admin" (top right) â†’ "Basic Configuration"
   - Or go to: http://localhost:8083/admin/config
   - Set "Location of Calibre database": A:\Media\Calibre
   - Click "Save"
   - Calibre-Web will restart

5. **Change Admin Password (IMPORTANT!):**
   - Click "Admin" â†’ "Edit Users" â†’ "admin"
   - Set new secure password
   - Click "Save"

6. **Configure UI Settings:**
   - Admin â†’ "UI Configuration"
   - Books per page: 50-100
   - Random books to show: 10-20
   - Language: English
   - Theme: Choose your preference
   - Click "Save"

7. **Enable Features:**
   - Admin â†’ "Feature Configuration"
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
  ```powershell
  New-NetFirewallRule -DisplayName "Calibre-Web" -Direction Inbound -Protocol TCP -LocalPort 8083 -Action Allow
  ```

### Books not showing up
- Verify Calibre library path is correct
- Make sure path points to the folder containing metadata.db
- Check that Calibre desktop is NOT running (conflicts)

### Permission errors
- Make sure Calibre-Web has read access to A:\Media\Calibre
- Run PowerShell as administrator if needed

## Next Steps

1. Browse your library in the web interface
2. Test reading a book in your browser
3. Try accessing from your phone/tablet
4. Create personal shelves
5. Add ratings to books you've read

Enjoy your library!
