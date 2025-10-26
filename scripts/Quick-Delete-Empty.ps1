# Quick delete empty torrent folders
# Simple and direct approach

$MoviesPath = "A:\Media\Movies"

Write-Host "Deleting empty torrent-style folders..." -ForegroundColor Yellow

# List of exact folder names to delete (from our analysis)
$foldersToDelete = @(
    "Alien (1979) [Theactrical] [Remastered]",
    "American.Fiction.2023.720p.AMZN.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "An American Tail Fievel Goes West (1991) [720p] [BluRay] [YTS.MX]",
    "Anyone.But.You.2023.720p.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "Ashes In The Snow (2018) [WEBRip] [720p] [YTS.AM]",
    "Barbie.2023.1080p.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Beauty And The Beast (2017) [YTS.AG]",
    "Beetlejuice.Beetlejuice.2024.1080p.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Belladonna Of Sadness (1973) [BluRay] [1080p] [YTS.LT]",
    "Blink.Twice.2024.720p.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "Bottoms.2023.1080p.AMZN.WEBRip.DDP5.1.x265.10bit-GalaxyRG265[TGx]",
    "Clue (1985) [BluRay] [720p] [YTS.AM]",
    "Deadpool.and.Wolverine.2024.1080p.AMZN.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Dinosour (2000) [1080p]",
    "Dream.Scenario.2023.1080p.AMZN.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Drop.Dead.Gorgeous.1999.720p.BluRay.999MB.HQ.x265.10bit-GalaxyRG[TGx]",
    "Freaky Friday (2003) [BluRay] [720p] [YTS.AM]",
    "Game Night (2018) [BluRay] [720p] [YTS.AM]",
    "Joy.Ride.2023.1080p.AMZN.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Mafia.Mamma.2023.720p.AMZN.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "Mean.Girls.2024.720p.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "Mystery.Men.1999.REMASTERED.720p.BluRay.999MB.HQ.x265.10bit-GalaxyRG[TGx]",
    "No.Men.Beyond.This.Point.2015.DVDRip.x264-RedBlade[PRiME]",
    "Past.Lives.2023.1080p.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Pineapple Express UNRATED (2008) [1080p]",
    "Pirates Of The Caribbean Dead Men Tell No Tales (2017) [YTS.AG]",
    "Poor.Things.2023.720p.WEBRip.900MB.x264-GalaxyRG[TGx]",
    "Rumours.2024.1080p.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Samsara (2011) [BluRay] [720p] [YTS.AM]",
    "Scrambled.2024.720p.AMZN.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "Showgirls.1995.720p.BluRay.999MB.HQ.x265.10bit-GalaxyRG[TGx]",
    "Speak.no.Evil.2024.1080p.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "Stargate (1994) [Extended]",
    "The Birdcage (1996) [BluRay] [1080p] [YTS.AM]",
    "The Hunger Games (2012) [1080p]",
    "The Hunger Games Mockingjay   Part 1 (2014) [1080p]",
    "The Land Before Time (1988) [BluRay] [720p] [YTS.AM]",
    "The.End.We.Start.From.2023.720p.AMZN.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "The.Fall.Guy.2024.1080p.AMZN.WEBRip.1400MB.DD5.1.x264-GalaxyRG[TGx]",
    "The.Holdovers.2023.720p.WEBRip.900MB.x264-GalaxyRG[TGx]",
    "The.Substance.2024.720p.WEBRip.900MB.x264-GalaxyRG[TGx]",
    "Trap.2024.720p.AMZN.WEBRip.800MB.x264-GalaxyRG[TGx]",
    "Walk Hard The Dewey Cox Story (2007) [BluRay] [720p] [YTS.AM]",
    "What We Do in the Shadows (2014) [1080p]"
)

$deleted = 0
$skipped = 0
$errors = 0

foreach ($folderName in $foldersToDelete) {
    $fullPath = Join-Path $MoviesPath $folderName

    if (Test-Path $fullPath) {
        # Check for video files one more time
        $videoFiles = Get-ChildItem -Path $fullPath -Include *.mkv,*.mp4,*.avi,*.mov,*.wmv -Recurse -File -ErrorAction SilentlyContinue

        if ($videoFiles.Count -gt 0) {
            Write-Host "[SKIPPED - HAS VIDEO] $folderName" -ForegroundColor Yellow
            $skipped++
        } else {
            try {
                Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                Write-Host "[DELETED] $folderName" -ForegroundColor Green
                $deleted++
            } catch {
                Write-Host "[ERROR] $folderName - $_" -ForegroundColor Red
                $errors++
            }
        }
    } else {
        Write-Host "[NOT FOUND] $folderName" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Folders deleted: $deleted" -ForegroundColor Green
Write-Host "Folders skipped (had video): $skipped" -ForegroundColor Yellow
Write-Host "Errors: $errors" -ForegroundColor Red
Write-Host ""

# Show final count
$remaining = (Get-ChildItem -Path $MoviesPath -Directory).Count
Write-Host "Total movie folders remaining: $remaining" -ForegroundColor White
