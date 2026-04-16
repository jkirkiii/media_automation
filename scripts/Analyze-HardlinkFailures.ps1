# Analyze-HardlinkFailures.ps1
# Cross-references the hardlink failure list from Remove-SeededTorrents.ps1 against
# A:\Media\TV Shows\ and A:\Media\Movies\ to categorize each torrent entry.
#
# Categories:
#   UPGRADE_ORPHAN_EPISODE  -- Single episode: episode IS in Media (better quality was imported)
#   SEASON_COMPLETE         -- Season pack: season folder exists in Media with files
#   ACTIVE_SEASON           -- Season folder exists but this specific episode absent (still airing?)
#   MISSING_SEASON          -- Show in Media but this season absent (import failure?)
#   SHOW_NOT_IN_MEDIA       -- No matching show folder found in TV Shows
#   MOVIE_FOUND             -- Movie matched in A:\Media\Movies
#   MOVIE_NOT_FOUND         -- No matching movie found in A:\Media\Movies
#   BOOK_OR_OTHER           -- Non-video file (.epub etc.) -- already skip-protected
#   AMBIGUOUS               -- Cannot identify (bare "Season XX" name, no show context)
#
# Usage:
#   .\scripts\Analyze-HardlinkFailures.ps1
#   .\scripts\Analyze-HardlinkFailures.ps1 -ExportCsv

param(
    [string]$FailuresFile = "",
    [string]$TvLibrary    = "A:\Media\TV Shows",
    [string]$MovieLibrary = "A:\Media\Movies",
    [switch]$ExportCsv
)

$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not $FailuresFile) {
    $FailuresFile = Join-Path $repoRoot "data\hardlink_failures.txt"
}

# ---------------------------------------------------------------------------
# Normalize a title for fuzzy matching
# Handles: "Show Name (2010)" -> "show name 2010"
#          "Bob's Burgers" -> "bobs burgers"
#          "Airplane!" -> "airplane"
#          "Glass Onion - A Knives Out Mystery" -> "glass onion a knives out mystery"
# ---------------------------------------------------------------------------
function Normalize-Title([string]$raw) {
    $n = $raw
    # Remove common video extensions
    $n = $n -replace '\.(mkv|mp4|avi|mov|wmv|iso|m2ts|bdmv|epub|pdf|mobi|azw3|cbr|cbz)$', ''
    # Dots and underscores to spaces
    $n = $n -replace '[._]', ' '
    # Parenthetical year "(2010)" -> "2010"
    $n = $n -replace '\((\d{4})\)', '$1'
    # Remove remaining brackets and parens
    $n = $n -replace '[\[\]\(\)]', ' '
    # Normalize & -> and (Plex may use either; torrents use the full word)
    $n = $n -replace '\s*&\s*', ' and '
    # Remove apostrophes, colons, exclamation marks (differ between torrent and Plex naming)
    $n = $n -replace "[!':]", ''
    # Dash with spaces " - " -> space (release/Plex separator style)
    $n = $n -replace '\s+-\s+', ' '
    # Collapse whitespace
    $n = $n -replace '\s+', ' '
    return $n.Trim().ToLower()
}

# ---------------------------------------------------------------------------
# Find the best-matching Media directory for a given title.
# Pass -StrictYear to require a year in the dir name to match the title year
# (used for movies where a year is known and false positives are likely).
# Returns the matched full path, or $null
# ---------------------------------------------------------------------------
function Find-MediaDir([string]$title, [string[]]$dirs, [switch]$StrictYear) {
    if (-not $title -or $dirs.Count -eq 0) { return $null }

    $normTitle = Normalize-Title $title

    $bestPath  = $null
    $bestScore = 0

    foreach ($dir in $dirs) {
        $leaf    = Split-Path $dir -Leaf
        $normDir = Normalize-Title $leaf

        # Exact match -- return immediately
        if ($normDir -eq $normTitle) { return $dir }

        # One is a prefix of the other (e.g. "bobs burgers" vs "bobs burgers 2011")
        $isPre = $normDir.StartsWith($normTitle) -or $normTitle.StartsWith($normDir)
        if ($isPre) {
            # Score = length of the shorter (more specific) string.
            # Movies use title+year in the search, so false prefix matches like
            # "shrek 2001" -> "shrek 2 2004" are already blocked; no extra check needed.
            $score = [math]::Min($normDir.Length, $normTitle.Length)
            if ($score -gt $bestScore) {
                $bestScore = $score
                $bestPath  = $dir
            }
            continue
        }

        # Word-overlap scoring -- require >= 80% overlap on significant words
        $tw = $normTitle -split '\s+' | Where-Object { $_.Length -gt 2 }
        $dw = $normDir   -split '\s+' | Where-Object { $_.Length -gt 2 }
        if ($tw.Count -gt 0 -and $dw.Count -gt 0) {
            $overlap  = ($tw | Where-Object { $dw -contains $_ }).Count
            $minWords = [math]::Min($tw.Count, $dw.Count)
            if ($minWords -gt 0 -and ($overlap / $minWords) -ge 0.8 -and $overlap -gt $bestScore) {
                $bestScore = $overlap
                $bestPath  = $dir
            }
        }
    }

    return $bestPath
}

# ---------------------------------------------------------------------------
# Parse a torrent name into structured components
# Returns: Type (TV/MOVIE/BOOK/AMBIGUOUS), Title, Season (int), Episode (int?)
# ---------------------------------------------------------------------------
function Parse-TorrentName([string]$name) {
    $r = [PSCustomObject]@{
        Type    = "UNKNOWN"
        Title   = ""
        Season  = $null
        Episode = $null
        Year    = $null
    }

    # Book / non-video file
    if ($name -match '\.(epub|pdf|mobi|azw3|cbr|cbz)$') {
        $r.Type = "BOOK"
        return $r
    }

    # Bare season folder with no show context (e.g. torrent literally named "Season 02")
    if ($name -match '^Season\s+\d+$') {
        $r.Type = "AMBIGUOUS"
        return $r
    }

    # Normalize for regex parsing
    $n = $name -replace '[._]', ' '       # dots/underscores -> space
    $n = $n -replace '[\[\]\(\)]', ' '    # brackets -> space
    $n = $n -replace '\s*-\s*', ' '       # " - " -> space
    $n = $n -replace '\s+', ' '           # collapse
    $n = $n.Trim()

    # --- TV: SxxExx or Sxx pattern ---
    if ($n -match '(?i)\bS(?<s>\d{1,2})(?:E(?<e>\d{1,2}))?\b') {
        $r.Type   = "TV"
        $r.Season = [int]$Matches['s']
        if ($Matches['e']) { $r.Episode = [int]$Matches['e'] }

        # Title = everything before the SXX marker
        if ($n -match '(?i)^(.+?)\s+S\d{1,2}') {
            $r.Title = $Matches[1].Trim().TrimEnd('-').Trim()
        }
        return $r
    }

    # --- TV: "Season N Complete" / "Season N" style (no SXX code) ---
    if ($n -match '(?i)^(.+?)\s+Season\s+(\d+)') {
        $r.Type   = "TV"
        $r.Title  = $Matches[1].Trim()
        $r.Season = [int]$Matches[2]
        return $r
    }

    # --- Movie: has a recognizable year, no season marker ---
    if ($n -match '\b(?<yr>(19|20)\d{2})\b') {
        $r.Type = "MOVIE"
        $r.Year = [int]$Matches['yr']
        $yr     = $Matches['yr']
        if ($n -match ('^(.+?)\s+' + [regex]::Escape($yr))) {
            $r.Title = $Matches[1].Trim().TrimEnd('-').Trim()
        }
        return $r
    }

    # --- Fallback: strip known quality tokens and call it a movie ---
    $qualPat = '(?i)\s+(BluRay|BDRip|WEB[\-. ]?DL|WEBRip|HDTV|REMUX|1080p|2160p|720p|480p|4K|UHD|HDR|DV|x264|x265|H\.?264|H\.?265|HEVC|AVC|DTS|DDP|AAC|AC3|REPACK|PROPER|COMPLETE).+'
    $t = ($n -replace $qualPat, '').Trim()
    if ($t) {
        $r.Type  = "MOVIE"
        $r.Title = $t
    } else {
        $r.Type  = "AMBIGUOUS"
    }
    return $r
}

# ===========================================================================
# Main
# ===========================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Analyze-HardlinkFailures.ps1" -ForegroundColor Cyan
Write-Host "  Input : $FailuresFile" -ForegroundColor Cyan
Write-Host "  TV    : $TvLibrary" -ForegroundColor Cyan
Write-Host "  Movies: $MovieLibrary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $FailuresFile)) {
    Write-Host "[ERROR] Failures file not found: $FailuresFile" -ForegroundColor Red
    exit 1
}

# Read the failure list -- skip header/separator lines
$rawNames = Get-Content $FailuresFile | Where-Object {
    $_ -and
    $_ -notmatch '^---' -and
    $_ -notmatch '^Name\s*$' -and
    $_ -notmatch '^-{2,}'
} | ForEach-Object { $_.Trim() } | Where-Object { $_ }

Write-Host ("[INFO] Loaded {0} failure entries" -f $rawNames.Count) -ForegroundColor Gray

# Build Media directory indexes
$tvDirs    = @()
$movieDirs = @()

if (Test-Path $TvLibrary) {
    $tvDirs = @(Get-ChildItem -Path $TvLibrary -Directory | Select-Object -ExpandProperty FullName)
    Write-Host ("[INFO] TV library    : {0} show folders" -f $tvDirs.Count) -ForegroundColor Gray
} else {
    Write-Host "[WARN] TV library not found: $TvLibrary" -ForegroundColor Yellow
}

if (Test-Path $MovieLibrary) {
    $movieDirs = @(Get-ChildItem -Path $MovieLibrary -Directory | Select-Object -ExpandProperty FullName)
    Write-Host ("[INFO] Movie library : {0} movie folders" -f $movieDirs.Count) -ForegroundColor Gray
} else {
    Write-Host "[WARN] Movie library not found: $MovieLibrary" -ForegroundColor Yellow
}
Write-Host ""

# ---------------------------------------------------------------------------
# Categorize each entry
# ---------------------------------------------------------------------------
$results = [System.Collections.ArrayList]@()

foreach ($name in $rawNames) {
    $p        = Parse-TorrentName $name
    $category = "UNKNOWN"
    $notes    = ""
    $mediaPath = ""

    switch ($p.Type) {

        "BOOK" {
            $category = "BOOK_OR_OTHER"
            $notes    = "Non-video file -- already protected from removal"
        }

        "AMBIGUOUS" {
            $category = "AMBIGUOUS"
            $notes    = "Cannot identify show -- check save_path in qBittorrent"
        }

        "TV" {
            $showDir = Find-MediaDir $p.Title $tvDirs

            if (-not $showDir) {
                $category = "SHOW_NOT_IN_MEDIA"
                $notes    = "No TV folder matched '$($p.Title)'"
            } else {
                $mediaPath  = $showDir
                $showName   = Split-Path $showDir -Leaf
                $seasonStr  = "Season {0:D2}" -f $p.Season
                $seasonPath = Join-Path $showDir $seasonStr

                if (-not (Test-Path $seasonPath)) {
                    $category = "MISSING_SEASON"
                    $notes    = "$seasonStr not in '$showName'"
                } elseif ($p.Episode -ne $null) {
                    # Single episode -- check if it exists in Media
                    $epFilter = "S{0:D2}E{1:D2}" -f $p.Season, $p.Episode
                    $epFiles  = @(Get-ChildItem -Path $seasonPath -Filter "*$epFilter*" -File -ErrorAction SilentlyContinue)
                    if ($epFiles) {
                        $category  = "UPGRADE_ORPHAN_EPISODE"
                        $notes     = "Media has $($epFiles[0].Name)"
                        $mediaPath = $epFiles[0].FullName
                    } else {
                        $category = "ACTIVE_SEASON"
                        $notes    = "$epFilter not found in $seasonStr of '$showName' -- may still be airing"
                    }
                } else {
                    # Season pack -- season folder exists; count files
                    $seasonFiles = @(Get-ChildItem -Path $seasonPath -File -ErrorAction SilentlyContinue)
                    if ($seasonFiles.Count -gt 0) {
                        $category  = "SEASON_COMPLETE"
                        $notes     = "$seasonStr has $($seasonFiles.Count) file(s) in '$showName'"
                        $mediaPath = $seasonPath
                    } else {
                        $category = "MISSING_SEASON"
                        $notes    = "$seasonStr folder exists but is empty in '$showName'"
                    }
                }
            }
        }

        "MOVIE" {
            # Primary: search with year included so "Shrek 2001" won't match "Shrek 2 (2004)"
            $searchTitle = if ($p.Year) { "$($p.Title) $($p.Year)" } else { $p.Title }
            $movieDir    = Find-MediaDir $searchTitle $movieDirs

            # Fallback: year-only mismatch (e.g. Taiwan pre-release with prior year).
            # Strip year from Media dir names and do exact title match.
            # Only accept if the year difference is <= 2 (release date slippage, not a different sequel).
            if (-not $movieDir -and $p.Title -and $p.Year) {
                $normT = Normalize-Title $p.Title
                foreach ($d in $movieDirs) {
                    $leaf      = Split-Path $d -Leaf
                    $normLeaf  = Normalize-Title $leaf
                    # Extract year from dir name
                    $dirYear   = $null
                    if ($normLeaf -match '\b(\d{4})$') { $dirYear = [int]$Matches[1] }
                    # Strip trailing 4-digit year from normalized dir name
                    $dirNoYear = ($normLeaf -replace '\s+\d{4}$', '').Trim()
                    if ($dirNoYear -eq $normT) {
                        # Only accept if year difference is plausible (pre-release or regional release)
                        if ($dirYear -ne $null -and [math]::Abs($p.Year - $dirYear) -le 2) {
                            $movieDir = $d
                            break
                        }
                    }
                }
                if ($movieDir) {
                    $notes = "Year mismatch: torrent=$($p.Year), lib=$(Split-Path $movieDir -Leaf)"
                }
            }

            if ($movieDir) {
                $category  = "MOVIE_FOUND"
                if (-not $notes) { $notes = "Matched: $(Split-Path $movieDir -Leaf)" }
                $mediaPath = $movieDir
            } else {
                $category = "MOVIE_NOT_FOUND"
                $notes    = "No Movies folder matched '$($p.Title)'"
            }
        }

        default {
            $category = "AMBIGUOUS"
            $notes    = "Could not parse torrent name"
        }
    }

    $null = $results.Add([PSCustomObject]@{
        Name      = $name
        Type      = $p.Type
        Title     = $p.Title
        Season    = if ($p.Season -ne $null) { "S{0:D2}" -f $p.Season } else { "" }
        Episode   = if ($p.Episode -ne $null) { "E{0:D2}" -f $p.Episode } else { "" }
        Category  = $category
        MediaPath = $mediaPath
        Notes     = $notes
    })
}

# ---------------------------------------------------------------------------
# Display report grouped by category
# ---------------------------------------------------------------------------
$catOrder = @(
    "UPGRADE_ORPHAN_EPISODE",
    "SEASON_COMPLETE",
    "ACTIVE_SEASON",
    "MISSING_SEASON",
    "SHOW_NOT_IN_MEDIA",
    "MOVIE_FOUND",
    "MOVIE_NOT_FOUND",
    "BOOK_OR_OTHER",
    "AMBIGUOUS",
    "UNKNOWN"
)

$catColors = @{
    "UPGRADE_ORPHAN_EPISODE" = "Green"
    "SEASON_COMPLETE"        = "Green"
    "ACTIVE_SEASON"          = "Yellow"
    "MISSING_SEASON"         = "Red"
    "SHOW_NOT_IN_MEDIA"      = "Red"
    "MOVIE_FOUND"            = "Green"
    "MOVIE_NOT_FOUND"        = "Red"
    "BOOK_OR_OTHER"          = "DarkGray"
    "AMBIGUOUS"              = "DarkYellow"
    "UNKNOWN"                = "Magenta"
}

$catDesc = @{
    "UPGRADE_ORPHAN_EPISODE" = "Safe to remove -- episode is in Media (better quality was imported)"
    "SEASON_COMPLETE"        = "Likely safe -- season pack; season folder with files exists in Media"
    "ACTIVE_SEASON"          = "Caution -- season in Media but this episode unconfirmed (still airing?)"
    "MISSING_SEASON"         = "Investigate -- show is in Media but this season is absent"
    "SHOW_NOT_IN_MEDIA"      = "Investigate -- no matching show folder found (Sonarr import failure?)"
    "MOVIE_FOUND"            = "Safe to remove -- movie is in Media (upgrade orphan or manual copy)"
    "MOVIE_NOT_FOUND"        = "Investigate -- no matching movie folder found"
    "BOOK_OR_OTHER"          = "Skip -- non-video; already protected by Remove-SeededTorrents.ps1"
    "AMBIGUOUS"              = "Manual review -- bare season name, check qBittorrent save_path"
    "UNKNOWN"                = "Unclassified"
}

foreach ($cat in $catOrder) {
    $group = @($results | Where-Object { $_.Category -eq $cat })
    if ($group.Count -eq 0) { continue }

    $col = $catColors[$cat]
    Write-Host ("=== $cat ({0}) ===" -f $group.Count) -ForegroundColor $col
    Write-Host ("    " + $catDesc[$cat]) -ForegroundColor DarkGray
    Write-Host ""

    foreach ($r in ($group | Sort-Object Title, Name)) {
        $label = $r.Name
        if ($label.Length -gt 90) { $label = $label.Substring(0, 87) + "..." }
        Write-Host ("  " + $label) -ForegroundColor White
        Write-Host ("    -> " + $r.Notes) -ForegroundColor DarkGray
    }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
$totalSafe    = @($results | Where-Object { $_.Category -in @("UPGRADE_ORPHAN_EPISODE","SEASON_COMPLETE","MOVIE_FOUND") }).Count
$totalCaution = @($results | Where-Object { $_.Category -in @("ACTIVE_SEASON","AMBIGUOUS") }).Count
$totalInvest  = @($results | Where-Object { $_.Category -in @("MISSING_SEASON","SHOW_NOT_IN_MEDIA","MOVIE_NOT_FOUND","UNKNOWN") }).Count
$totalSkip    = @($results | Where-Object { $_.Category -eq "BOOK_OR_OTHER" }).Count

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
foreach ($cat in $catOrder) {
    $cnt = @($results | Where-Object { $_.Category -eq $cat }).Count
    if ($cnt -eq 0) { continue }
    Write-Host ("  {0,-30} {1,4}" -f $cat, $cnt) -ForegroundColor $catColors[$cat]
}
Write-Host ""
Write-Host ("  {0,-30} {1,4}  (safe to remove)" -f "LIKELY SAFE", $totalSafe) -ForegroundColor Green
Write-Host ("  {0,-30} {1,4}  (check before removing)" -f "CAUTION", $totalCaution) -ForegroundColor Yellow
Write-Host ("  {0,-30} {1,4}  (possible import failures)" -f "INVESTIGATE", $totalInvest) -ForegroundColor Red
Write-Host ("  {0,-30} {1,4}  (skip)" -f "SKIP", $totalSkip) -ForegroundColor DarkGray
Write-Host ("  {0,-30} {1,4}" -f "TOTAL", $results.Count) -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  UPGRADE_ORPHAN_EPISODE / MOVIE_FOUND / SEASON_COMPLETE:" -ForegroundColor Cyan
Write-Host "    These can be added to a safe-removal list for Remove-SeededTorrents.ps1." -ForegroundColor Gray
Write-Host "  ACTIVE_SEASON:" -ForegroundColor Cyan
Write-Host "    Check if the show is still airing. If fully aired and imported, safe to remove." -ForegroundColor Gray
Write-Host "  MISSING_SEASON / SHOW_NOT_IN_MEDIA / MOVIE_NOT_FOUND:" -ForegroundColor Cyan
Write-Host "    Open Sonarr/Radarr and check import history. May need manual import." -ForegroundColor Gray
Write-Host "  AMBIGUOUS (bare Season XX):" -ForegroundColor Cyan
Write-Host "    Open qBittorrent, find by name, check save_path to identify the show." -ForegroundColor Gray
Write-Host ""

# ---------------------------------------------------------------------------
# CSV export
# ---------------------------------------------------------------------------
if ($ExportCsv) {
    $date    = Get-Date -Format 'yyyy-MM-dd'
    $csvPath = Join-Path $repoRoot "data\hardlink_analysis_$date.csv"
    $results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("[OK] Exported to: $csvPath") -ForegroundColor Green
    Write-Host ""
}
