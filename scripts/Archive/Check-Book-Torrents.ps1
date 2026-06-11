param(
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$username = "admin"

# Login to qBittorrent
$loginBody = @{
    username = $username
    password = $Password
}

try {
    $login = Invoke-WebRequest -Uri "http://localhost:8080/api/v2/auth/login" `
        -Method Post `
        -Body $loginBody `
        -SessionVariable 'session'

    # Get all torrents
    $torrents = Invoke-RestMethod -Uri "http://localhost:8080/api/v2/torrents/info" `
        -WebSession $session

    # Filter for book-related torrents
    $bookTorrents = $torrents | Where-Object {
        $_.save_path -like '*Literature*' -or
        $_.save_path -like '*Books*' -or
        $_.category -eq 'books'
    }

    Write-Host "=== QBITTORRENT BOOK TORRENTS ANALYSIS ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total torrents seeding: $($torrents.Count)"
    Write-Host "Book-related torrents: $($bookTorrents.Count)"
    Write-Host ""

    if ($bookTorrents.Count -gt 0) {
        Write-Host "=== BOOK TORRENT DETAILS ===" -ForegroundColor Yellow
        Write-Host ""

        foreach ($torrent in $bookTorrents) {
            Write-Host "Name: $($torrent.name)" -ForegroundColor Green
            Write-Host "  Category: $($torrent.category)"
            Write-Host "  Save Path: $($torrent.save_path)"
            Write-Host "  Content Path: $($torrent.content_path)"
            Write-Host "  State: $($torrent.state)"
            Write-Host "  Size: $([math]::Round($torrent.size / 1MB, 2)) MB"
            Write-Host ""
        }

        # Group by save path
        Write-Host "=== SAVE PATH SUMMARY ===" -ForegroundColor Yellow
        $bookTorrents | Group-Object save_path | ForEach-Object {
            Write-Host "$($_.Name): $($_.Count) torrents"
        }
    } else {
        Write-Host "No book torrents found." -ForegroundColor Yellow
    }

} catch {
    Write-Host "Error connecting to qBittorrent: $_" -ForegroundColor Red
    Write-Host "Make sure qBittorrent is running and credentials are correct."
}
