# Check-ArrQueueStatus.ps1
# Reports import errors and wanted/missing items from Sonarr and Radarr.
# Read-only -- makes no changes.
#
# Usage:
#   .\scripts\Check-ArrQueueStatus.ps1

param(
    [string]$SonarrUrl   = "",
    [string]$SonarrKey   = "",
    [string]$RadarrUrl   = "",
    [string]$RadarrKey   = ""
)

$repoRoot   = Split-Path $PSScriptRoot -Parent
$configFile = Join-Path $repoRoot "config.ps1"
if (Test-Path $configFile) {
    . $configFile
    if (-not $SonarrUrl) { $SonarrUrl = $sonarrUrl }
    if (-not $SonarrKey) { $SonarrKey = $sonarrApiKey }
    if (-not $RadarrUrl) { $RadarrUrl = $radarrUrl }
    if (-not $RadarrKey) { $RadarrKey = $radarrApiKey }
}
if (-not $SonarrUrl) { $SonarrUrl = "http://localhost:8989" }
if (-not $RadarrUrl) { $RadarrUrl = "http://localhost:7878" }

function Invoke-ArrApi([string]$baseUrl, [string]$apiKey, [string]$endpoint) {
    $uri     = "$baseUrl/api/v3/$endpoint"
    $headers = @{ "X-Api-Key" = $apiKey }
    try {
        return Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction Stop
    } catch {
        Write-Host "[ERROR] $uri -- $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Show-QueueErrors([string]$appName, [string]$baseUrl, [string]$apiKey) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  $appName -- Queue / Import Errors" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan

    $unknownParam = if ($appName -eq "Sonarr") { "includeUnknownSeriesItems=true" } else { "includeUnknownMovieItems=true" }
    $queue = Invoke-ArrApi $baseUrl $apiKey "queue?pageSize=500&$unknownParam"
    if (-not $queue) { return }

    $records = if ($queue.records) { $queue.records } else { $queue }

    $errors   = @($records | Where-Object { $_.trackedDownloadStatus -in @("warning","error") -or $_.status -eq "warning" })
    $ok       = @($records | Where-Object { $_.trackedDownloadStatus -notin @("warning","error") -and $_.status -ne "warning" })

    Write-Host ("[INFO] Queue total: {0}   with errors/warnings: {1}   ok: {2}" -f $records.Count, $errors.Count, $ok.Count) -ForegroundColor Gray
    Write-Host ""

    if ($errors.Count -eq 0) {
        Write-Host "  No import errors in queue." -ForegroundColor Green
        return
    }

    foreach ($item in $errors | Sort-Object title) {
        $title  = if ($item.series) { "$($item.series.title) $($item.episode.seasonNumber)x$($item.episode.episodeNumber)" `
                  } elseif ($item.movie) { $item.movie.title `
                  } else { $item.title }
        $status = $item.trackedDownloadStatus
        $state  = $item.trackedDownloadState

        Write-Host ("  [{0}] {1}" -f $status.ToUpper(), $title) -ForegroundColor Yellow
        Write-Host ("    State   : $state") -ForegroundColor DarkGray
        Write-Host ("    Torrent : $($item.title)") -ForegroundColor DarkGray

        if ($item.statusMessages) {
            foreach ($msg in $item.statusMessages) {
                foreach ($line in $msg.messages) {
                    Write-Host ("    Reason  : $line") -ForegroundColor Red
                }
            }
        }
        Write-Host ""
    }
}

function Show-Wanted([string]$appName, [string]$baseUrl, [string]$apiKey) {
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  $appName -- Wanted / Missing" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan

    if ($appName -eq "Sonarr") {
        # Wanted missing episodes (monitored, cutoff unmet)
        $missing = Invoke-ArrApi $baseUrl $apiKey "wanted/missing?pageSize=100&sortKey=airDateUtc&sortDir=desc&includeSeries=true"
        if (-not $missing) { return }
        $records = if ($missing.records) { $missing.records } else { @() }
        Write-Host ("[INFO] Missing episodes (most recent first): {0} shown of {1} total" -f $records.Count, $missing.totalRecords) -ForegroundColor Gray
        Write-Host ""
        if ($records.Count -eq 0) {
            Write-Host "  No missing episodes." -ForegroundColor Green
        } else {
            foreach ($ep in $records) {
                $aired      = if ($ep.airDateUtc) { ([datetime]$ep.airDateUtc).ToString("yyyy-MM-dd") } else { "unaired  " }
                $seriesName = if ($ep.series -and $ep.series.title) { $ep.series.title } else { "(series $($ep.seriesId))" }
                Write-Host ("  $aired  {0} S{1:D2}E{2:D2}  {3}" -f $seriesName, $ep.seasonNumber, $ep.episodeNumber, $ep.title) -ForegroundColor White
            }
        }
        Write-Host ""

        # Cutoff unmet (have a file but it's below quality cutoff)
        $cutoff = Invoke-ArrApi $baseUrl $apiKey "wanted/cutoff?pageSize=50&sortKey=airDateUtc&sortDir=desc"
        if ($cutoff) {
            $cRecords = if ($cutoff.records) { $cutoff.records } else { @() }
            Write-Host ("[INFO] Cutoff unmet (have file, want upgrade): {0} shown of {1} total" -f $cRecords.Count, $cutoff.totalRecords) -ForegroundColor Gray
            Write-Host ""
            if ($cRecords.Count -eq 0) {
                Write-Host "  No cutoff-unmet episodes." -ForegroundColor Green
            } else {
                foreach ($ep in $cRecords) {
                    Write-Host ("  $($ep.series.title) S{0:D2}E{1:D2}  $($ep.title)" -f $ep.seasonNumber, $ep.episodeNumber) -ForegroundColor DarkYellow
                }
            }
        }
    } else {
        # Radarr: monitored movies with no file
        $movies = Invoke-ArrApi $baseUrl $apiKey "movie"
        if (-not $movies) { return }
        $missing = @($movies | Where-Object { $_.monitored -and -not $_.hasFile } | Sort-Object title)
        Write-Host ("[INFO] Monitored movies with no file: {0}" -f $missing.Count) -ForegroundColor Gray
        Write-Host ""
        if ($missing.Count -eq 0) {
            Write-Host "  No missing monitored movies." -ForegroundColor Green
        } else {
            foreach ($m in $missing) {
                $status = if ($m.status) { $m.status } else { "unknown" }
                Write-Host ("  [{0}] {1} ({2})" -f $status, $m.title, $m.year) -ForegroundColor White
            }
        }

        Write-Host ""

        # Cutoff unmet
        $cutoff = Invoke-ArrApi $baseUrl $apiKey "wanted/cutoff?pageSize=50&sortKey=physicalRelease&sortDir=desc"
        if ($cutoff) {
            $cRecords = if ($cutoff.records) { $cutoff.records } else { @() }
            Write-Host ("[INFO] Cutoff unmet (have file, want upgrade): {0} shown of {1} total" -f $cRecords.Count, $cutoff.totalRecords) -ForegroundColor Gray
            if ($cRecords.Count -gt 0) {
                foreach ($m in $cRecords) {
                    Write-Host ("  $($m.title) ($($m.year))") -ForegroundColor DarkYellow
                }
            } else {
                Write-Host "  No cutoff-unmet movies." -ForegroundColor Green
            }
        }
    }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
Show-QueueErrors "Sonarr" $SonarrUrl $SonarrKey
Show-Wanted      "Sonarr" $SonarrUrl $SonarrKey
Show-QueueErrors "Radarr" $RadarrUrl $RadarrKey
Show-Wanted      "Radarr" $RadarrUrl $RadarrKey
