# Auto-CleanupOrphans.ps1
# Weekly orchestrator: identifies and removes hardlink-orphaned download
# torrents (true disk duplicates) while preserving private-tracker safety.
#
# Pipeline:
#   1. Disk-free gate           -- exit if A: has more than -FreeSpaceThresholdGB free
#   2. -arr queue exclusion     -- skip anything currently being processed by Sonarr/Radarr
#   3. Seeding audit dry run    -- regenerate hardlink_failures.txt
#   4. Categorization           -- run Analyze-HardlinkFailures.ps1
#   5. Targeted removal         -- run Remove-HardlinkOrphanTorrents.ps1 -Execute
#                                  with MAM tracker + books/audiobooks/music category exclusions
#   6. Email summary            -- HTML report sent via Gmail SMTP (config.ps1)
#
# Designed to run unattended via Task Scheduler as SYSTEM. All paths are
# absolute; output is captured to a per-run log file under logs\.
#
# Usage:
#   .\scripts\Auto-CleanupOrphans.ps1                          # standard weekly run
#   .\scripts\Auto-CleanupOrphans.ps1 -Force                   # ignore disk gate
#   .\scripts\Auto-CleanupOrphans.ps1 -DryRun                  # analyze + email, no removals
#   .\scripts\Auto-CleanupOrphans.ps1 -FreeSpaceThresholdGB 500
#   .\scripts\Auto-CleanupOrphans.ps1 -MinSeedDays 14

param(
    [int]$FreeSpaceThresholdGB = 300,
    [int]$MinSeedDays          = 21,
    [string]$DriveLetter       = "A",
    [switch]$Force,
    [switch]$DryRun,
    [switch]$NoEmail
)

# ---------------------------------------------------------------------------
# Paths + logging
# ---------------------------------------------------------------------------
$ErrorActionPreference = "Continue"
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path $scriptDir -Parent
$logDir    = Join-Path $repoRoot "logs"
$dataDir   = Join-Path $repoRoot "data"
foreach ($d in @($logDir, $dataDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
}

$runStamp  = Get-Date -Format "yyyy-MM-dd_HHmmss"
$logFile   = Join-Path $logDir "auto_cleanup_$runStamp.log"

# Accumulate structured run state for the email
$runReport = [PSCustomObject]@{
    StartedAt          = (Get-Date)
    Host               = $env:COMPUTERNAME
    DiskBeforeGB       = $null
    DiskAfterGB        = $null
    DiskThresholdGB    = $FreeSpaceThresholdGB
    MinSeedDays        = $MinSeedDays
    Mode               = if ($DryRun) { "DRY RUN" } else { "EXECUTE" }
    Result             = "Pending"
    Reason             = ""
    ArrQueueExclusions = 0
    Removed            = 0
    FreedGB            = 0.0
    Skipped            = @()
    Errors             = @()
    LogFile            = $logFile
}

function Write-Log {
    param([string]$msg, [string]$color = "White")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$ts  $msg"
    Add-Content -Path $logFile -Value $line -Encoding UTF8
    Write-Host $line -ForegroundColor $color
}

function Log-Error {
    param([string]$where, [string]$msg)
    Write-Log "[ERROR] $where -- $msg" "Red"
    $runReport.Errors += "$where -- $msg"
}

# ---------------------------------------------------------------------------
# Load config
# ---------------------------------------------------------------------------
$configFile = Join-Path $repoRoot "config.ps1"
if (-not (Test-Path $configFile)) {
    Write-Log "[FATAL] config.ps1 not found at $configFile" "Red"
    exit 2
}
. $configFile

Write-Log "============================================================"
Write-Log "  Auto-CleanupOrphans.ps1  [$($runReport.Mode)]"
Write-Log "  Drive            : ${DriveLetter}:"
Write-Log "  Free threshold   : $FreeSpaceThresholdGB GB"
Write-Log "  Min seed days    : $MinSeedDays"
Write-Log "  Log              : $logFile"
Write-Log "============================================================"

# ---------------------------------------------------------------------------
# Phase 1: disk-free gate
# ---------------------------------------------------------------------------
$drive = Get-PSDrive $DriveLetter -ErrorAction SilentlyContinue
if (-not $drive) {
    Log-Error "Phase 1" "Drive ${DriveLetter}: not found"
    $runReport.Result = "Error"
    $runReport.Reason = "Drive ${DriveLetter}: not found"
} else {
    $runReport.DiskBeforeGB = [math]::Round($drive.Free / 1GB, 2)
    Write-Log "[INFO] Free space on ${DriveLetter}: $($runReport.DiskBeforeGB) GB"

    if ($runReport.DiskBeforeGB -ge $FreeSpaceThresholdGB -and -not $Force) {
        Write-Log "[SKIP] Free space exceeds threshold. No cleanup needed."
        $runReport.Result = "NoOp"
        $runReport.Reason = "Free space $($runReport.DiskBeforeGB) GB >= threshold $FreeSpaceThresholdGB GB"
    }
}

# ---------------------------------------------------------------------------
# Phase 2: -arr queue exclusion list
# ---------------------------------------------------------------------------
$excludeHashes = New-Object System.Collections.Generic.HashSet[string]
if ($runReport.Result -eq "Pending") {
    foreach ($svc in @(
        @{Name='Sonarr'; Url=$SonarrUrl; Key=$SonarrApiKey; Param='includeUnknownSeriesItems=true'},
        @{Name='Radarr'; Url=$RadarrUrl; Key=$RadarrApiKey; Param='includeUnknownMovieItems=true'}
    )) {
        if (-not $svc.Url -or -not $svc.Key) {
            Write-Log "[WARN] $($svc.Name) URL or API key missing in config.ps1 -- skipping queue check" "Yellow"
            continue
        }
        try {
            $resp = Invoke-RestMethod -Uri "$($svc.Url)/api/v3/queue?pageSize=500&$($svc.Param)" `
                -Headers @{ "X-Api-Key" = $svc.Key } -ErrorAction Stop
            $records = if ($resp.records) { $resp.records } else { $resp }
            $added   = 0
            foreach ($rec in $records) {
                if ($rec.downloadId) {
                    if ($excludeHashes.Add($rec.downloadId.ToLower())) { $added++ }
                }
            }
            Write-Log "[OK] $($svc.Name) queue: $($records.Count) items, $added unique hashes added to exclusion"
        } catch {
            Log-Error "Phase 2 $($svc.Name)" $_.Exception.Message
            # Non-fatal: 21-day floor still protects us
        }
    }
    $runReport.ArrQueueExclusions = $excludeHashes.Count
}

# ---------------------------------------------------------------------------
# Phase 3: regenerate hardlink failure list via Remove-SeededTorrents dry run
# ---------------------------------------------------------------------------
$seededOut = Join-Path $dataDir "seeded_dryrun_auto_$runStamp.txt"
if ($runReport.Result -eq "Pending") {
    try {
        Write-Log "[STEP] Running Remove-SeededTorrents.ps1 dry-run (MinDays=$MinSeedDays)..."
        & "$scriptDir\Remove-SeededTorrents.ps1" -MinDays $MinSeedDays *>&1 |
            Tee-Object -FilePath $seededOut | Out-Null
        Write-Log "[OK] Dry-run output captured to $seededOut"
    } catch {
        Log-Error "Phase 3" $_.Exception.Message
        $runReport.Result = "Error"
        $runReport.Reason = "Remove-SeededTorrents dry-run failed"
    }
}

# ---------------------------------------------------------------------------
# Phase 4: extract failures and analyze
# ---------------------------------------------------------------------------
$failuresFile = Join-Path $dataDir "hardlink_failures.txt"
$analysisCsv  = Join-Path $dataDir ("hardlink_analysis_" + (Get-Date -Format "yyyy-MM-dd") + ".csv")
if ($runReport.Result -eq "Pending") {
    try {
        Write-Log "[STEP] Extracting hardlink failures..."
        & "$scriptDir\Extract-HardlinkFailures.ps1" -InputFile $seededOut -OutputFile $failuresFile *>&1 |
            ForEach-Object { Write-Log $_ }
    } catch {
        Log-Error "Phase 4 extract" $_.Exception.Message
        $runReport.Result = "Error"
        $runReport.Reason = "Extract-HardlinkFailures failed"
    }

    if ($runReport.Result -eq "Pending") {
        try {
            $failureCount = 0
            if (Test-Path $failuresFile) {
                # First 4 lines are header; subtract them
                $failureCount = [math]::Max(0, (Get-Content $failuresFile).Count - 4)
            }
            Write-Log "[INFO] $failureCount hardlink failures past $MinSeedDays-day seed threshold"

            if ($failureCount -eq 0) {
                Write-Log "[OK] Nothing to analyze. Run complete."
                $runReport.Result = "NoOp"
                $runReport.Reason = "No hardlink failures past seed threshold"
            } else {
                Write-Log "[STEP] Analyzing failures..."
                & "$scriptDir\Analyze-HardlinkFailures.ps1" -FailuresFile $failuresFile -ExportCsv *>&1 |
                    ForEach-Object { Write-Log $_ }
            }
        } catch {
            Log-Error "Phase 4 analyze" $_.Exception.Message
            $runReport.Result = "Error"
            $runReport.Reason = "Analyze-HardlinkFailures failed"
        }
    }
}

# ---------------------------------------------------------------------------
# Phase 5: targeted removal with all exclusions
# ---------------------------------------------------------------------------
if ($runReport.Result -eq "Pending") {
    # Find the newest CSV (Analyze writes one with today's date)
    $latestCsv = Get-ChildItem -Path $dataDir -Filter "hardlink_analysis_*.csv" -ErrorAction SilentlyContinue |
                 Sort-Object Name -Descending | Select-Object -First 1
    if (-not $latestCsv) {
        Log-Error "Phase 5" "No hardlink_analysis_*.csv found after analyze step"
        $runReport.Result = "Error"
        $runReport.Reason = "Analysis CSV not produced"
    } else {
        Write-Log "[STEP] Removing orphaned torrents (CSV: $($latestCsv.Name))"
        Write-Log "[INFO] Excluding categories: books, audiobooks, music"
        Write-Log "[INFO] Excluding trackers  : t.myanonamouse.net"
        Write-Log "[INFO] Excluding -arr hashes: $($excludeHashes.Count)"

        $removeArgs = @{
            CsvFile         = $latestCsv.FullName
            ExcludeQbCats   = @("books","audiobooks","music")
            ExcludeTrackers = @("t.myanonamouse.net")
            ExcludeHashes   = @($excludeHashes)
        }
        if (-not $DryRun) { $removeArgs.Execute = $true }

        $removeOut = Join-Path $dataDir "remove_orphans_auto_$runStamp.txt"
        try {
            & "$scriptDir\Remove-HardlinkOrphanTorrents.ps1" @removeArgs *>&1 |
                Tee-Object -FilePath $removeOut | Out-Null

            $removeOutput = Get-Content $removeOut -Raw
            Add-Content -Path $logFile -Value $removeOutput -Encoding UTF8

            # Parse counts and freed GB from the removal output
            if ($DryRun) {
                if ($removeOutput -match '(\d+) torrents\s+([\d\.]+) GB would be freed') {
                    $runReport.Removed = [int]$Matches[1]
                    $runReport.FreedGB = [double]$Matches[2]
                }
            } else {
                if ($removeOutput -match 'Removed\s*:\s*(\d+) torrents') {
                    $runReport.Removed = [int]$Matches[1]
                }
                if ($removeOutput -match 'Freed\s*:\s*([\d\.]+) GB') {
                    $runReport.FreedGB = [double]$Matches[1]
                }
            }

            # If the safety filters ate everything, report that as NoOp not Action
            if ($runReport.Removed -eq 0) {
                $runReport.Result = "NoOp"
                if (-not $runReport.Reason) {
                    $runReport.Reason = "No removable items after safety filters (everything is either hardlinked, in -arr queue, or protected)"
                }
            } else {
                $runReport.Result = "Action"
            }

            # Capture skipped buckets for the email
            foreach ($pat in @(
                @{ Re = '--- (\d+) entries SKIPPED: qB category is protected'; Label = 'Protected qB category' },
                @{ Re = '--- (\d+) entries SKIPPED: tracker is on no-touch list'; Label = 'Protected tracker (MAM)' },
                @{ Re = '--- (\d+) entries SKIPPED: currently in Sonarr/Radarr queue'; Label = 'In -arr queue' },
                @{ Re = '--- (\d+) entries SKIPPED: now hardlinked'; Label = 'Now hardlinked (no real savings)' },
                @{ Re = '--- (\d+) entries REFUSED: content_path is inside Media root'; Label = 'REFUSED: under Media root' },
                @{ Re = '--- (\d+) CSV entries not in qBittorrent'; Label = 'Already removed from qBittorrent' }
            )) {
                if ($removeOutput -match $pat.Re) {
                    $runReport.Skipped += [PSCustomObject]@{
                        Reason = $pat.Label
                        Count  = [int]$Matches[1]
                    }
                }
            }

        } catch {
            Log-Error "Phase 5" $_.Exception.Message
            $runReport.Result = "Error"
            $runReport.Reason = "Remove-HardlinkOrphanTorrents failed"
        }
    }
}

# ---------------------------------------------------------------------------
# Phase 6: post-run disk measurement
# ---------------------------------------------------------------------------
$driveAfter = Get-PSDrive $DriveLetter -ErrorAction SilentlyContinue
if ($driveAfter) {
    $runReport.DiskAfterGB = [math]::Round($driveAfter.Free / 1GB, 2)
}

Write-Log ""
Write-Log "============================================================"
Write-Log "  Result      : $($runReport.Result)"
if ($runReport.Reason) { Write-Log "  Reason      : $($runReport.Reason)" }
Write-Log "  Free before : $($runReport.DiskBeforeGB) GB"
Write-Log "  Free after  : $($runReport.DiskAfterGB) GB"
Write-Log "  Removed     : $($runReport.Removed) torrents"
Write-Log "  Freed       : $($runReport.FreedGB) GB"
Write-Log "  Errors      : $($runReport.Errors.Count)"
Write-Log "============================================================"

# ---------------------------------------------------------------------------
# Phase 7: email summary
# ---------------------------------------------------------------------------
function Send-Report {
    param($report)

    $cfgOk = $SmtpServer -and $SmtpUsername -and $SmtpPassword -and $SmtpFrom -and $SmtpReportTo `
        -and ($SmtpUsername -notlike 'YOUR_*') -and ($SmtpPassword -notlike 'YOUR_*')
    if (-not $cfgOk) {
        Write-Log "[WARN] SMTP not configured in config.ps1 -- skipping email" "Yellow"
        return
    }

    $subjPrefix = switch ($report.Result) {
        'Action' { '[Action]' }
        'NoOp'   { '[NoOp]'   }
        'Error'  { '[Error]'  }
        default  { '[?]'      }
    }
    $freedFmt   = "{0:N2}" -f $report.FreedGB
    $beforeFmt  = if ($null -ne $report.DiskBeforeGB) { "{0:N2}" -f $report.DiskBeforeGB } else { "n/a" }
    $afterFmt   = if ($null -ne $report.DiskAfterGB)  { "{0:N2}" -f $report.DiskAfterGB  } else { "n/a" }
    $subject    = "$subjPrefix MediaStack cleanup -- $($report.Removed) removed, $freedFmt GB freed"

    $skippedRows = ""
    if ($report.Skipped.Count -gt 0) {
        $skippedRows = ($report.Skipped | ForEach-Object {
            "<tr><td>$($_.Reason)</td><td style='text-align:right'>$($_.Count)</td></tr>"
        }) -join ""
    }

    $errorRows = ""
    if ($report.Errors.Count -gt 0) {
        $errorRows = ($report.Errors | ForEach-Object {
            "<li>$([System.Net.WebUtility]::HtmlEncode($_))</li>"
        }) -join ""
    }

    $body = @"
<html><body style='font-family:Segoe UI,Arial,sans-serif;'>
<h2 style='margin-bottom:6px'>MediaStack auto-cleanup</h2>
<p style='color:#666;margin-top:0'>$($report.Host) -- $($report.StartedAt.ToString('yyyy-MM-dd HH:mm:ss'))</p>

<table style='border-collapse:collapse'>
<tr><td><b>Result</b></td><td>$($report.Result)</td></tr>
<tr><td><b>Mode</b></td><td>$($report.Mode)</td></tr>
<tr><td><b>Reason</b></td><td>$($report.Reason)</td></tr>
<tr><td><b>Drive free before</b></td><td>$beforeFmt GB</td></tr>
<tr><td><b>Drive free after</b></td><td>$afterFmt GB</td></tr>
<tr><td><b>Free-space threshold</b></td><td>$($report.DiskThresholdGB) GB</td></tr>
<tr><td><b>Min seed days</b></td><td>$($report.MinSeedDays)</td></tr>
<tr><td><b>-arr queue exclusions</b></td><td>$($report.ArrQueueExclusions)</td></tr>
<tr><td><b>Torrents removed</b></td><td>$($report.Removed)</td></tr>
<tr><td><b>GB freed (qB-reported)</b></td><td>$freedFmt</td></tr>
</table>
"@

    if ($skippedRows) {
        $body += @"
<h3>Skipped</h3>
<table border='1' cellpadding='6' style='border-collapse:collapse'>
<tr><th>Reason</th><th>Count</th></tr>
$skippedRows
</table>
"@
    }

    if ($errorRows) {
        $body += "<h3 style='color:#b00'>Errors</h3><ul>$errorRows</ul>"
    }

    $body += @"
<p style='color:#666;font-size:90%'>Log file: $($report.LogFile)</p>
</body></html>
"@

    try {
        $securePass = ConvertTo-SecureString $SmtpPassword -AsPlainText -Force
        $cred       = New-Object System.Management.Automation.PSCredential($SmtpUsername, $securePass)
        Send-MailMessage `
            -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl `
            -From $SmtpFrom -To $SmtpReportTo `
            -Subject $subject -Body $body -BodyAsHtml `
            -Credential $cred -ErrorAction Stop
        Write-Log "[OK] Email report sent to $SmtpReportTo"
    } catch {
        Log-Error "Phase 7 email" $_.Exception.Message
    }
}

if (-not $NoEmail) { Send-Report $runReport }

Write-Log "Done."
exit 0
