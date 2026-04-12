# Backup-Configs.ps1
# Backs up all media stack service configs to a dated, compressed archive.
#
# Covers:
#   - Sonarr      (API-triggered backup zip, falls back to raw DB copy)
#   - Prowlarr    (API-triggered backup zip, falls back to raw DB copy)
#   - Radarr      (API-triggered backup zip, falls back to raw DB copy)
#   - Calibre-Web (app.db: users, SMTP, Kindle addresses, permissions)
#   - Cloudflare Tunnel (config.yml, cert.pem, tunnel credential JSON)
#
# Usage:
#   .\Backup-Configs.ps1
#   .\Backup-Configs.ps1 -BackupRoot "D:\Backups\MediaStack" -KeepCount 12
#   .\Backup-Configs.ps1 -SkipApiBackups   # copy raw DB files, no API calls
#
# Schedule weekly via Task Scheduler. See docs/Maintenance_Guide.md

param(
    [string]$BackupRoot     = "A:\Backups\MediaStack",
    [int]$KeepCount         = 10,
    [int]$ApiTimeoutSec     = 60,
    [switch]$SkipApiBackups
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Load credentials
# ---------------------------------------------------------------------------
$repoRoot   = Split-Path (Split-Path $MyInvocation.MyCommand.Path) -Parent
$configFile = Join-Path $repoRoot "config.ps1"
if (Test-Path $configFile) {
    . $configFile
} else {
    Write-Warning "config.ps1 not found - API backups will fail without API keys"
}

if (-not $SonarrApiKey)   { $SonarrApiKey   = "" }
if (-not $ProwlarrApiKey) { $ProwlarrApiKey  = "" }
if (-not $RadarrApiKey)   { $RadarrApiKey   = "" }
if (-not $SonarrUrl)      { $SonarrUrl      = "http://localhost:8989" }
if (-not $ProwlarrUrl)    { $ProwlarrUrl    = "http://localhost:9696" }
if (-not $RadarrUrl)      { $RadarrUrl      = "http://localhost:7878" }

# ---------------------------------------------------------------------------
# Setup: dated backup directory and logging
# ---------------------------------------------------------------------------
$timestamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupDir  = Join-Path $BackupRoot $timestamp
$logPath    = Join-Path $backupDir "backup.log"
$results    = New-Object System.Collections.ArrayList

New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "HH:mm:ss"), $Level, $Message
    if ($logPath -and (Test-Path (Split-Path $logPath))) {
        Add-Content -Path $logPath -Value $line
    }
    $color = switch ($Level) {
        "OK"   { "Green"  }
        "WARN" { "Yellow" }
        "FAIL" { "Red"    }
        default{ "White"  }
    }
    Write-Host $line -ForegroundColor $color
}

function Add-Result {
    param([string]$Name, [string]$Status, [string]$Detail = "")
    $null = $results.Add(@{ Name = $Name; Status = $Status; Detail = $Detail })
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Media Stack Config Backup" -ForegroundColor Cyan
Write-Host "  $timestamp" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Log ("Backup destination: " + $backupDir)
Write-Log ("Retention: keep " + $KeepCount + " most recent archives")
Write-Log ""

# ---------------------------------------------------------------------------
# Helper: trigger an *arr API backup and return the resulting zip FileInfo
# ---------------------------------------------------------------------------
function Invoke-ArrBackup {
    param(
        [string]$AppName,
        [string]$BaseUrl,
        [string]$ApiKey,
        [string]$ApiVersion,
        [string]$NativeBackupDir
    )

    Write-Log ("[" + $AppName + "] Triggering backup via API...")

    if (-not $ApiKey) {
        Write-Log ("[" + $AppName + "] No API key configured -- skipping API backup") "WARN"
        return $null
    }

    $headers = @{ "X-Api-Key" = $ApiKey }
    $body    = '{"name":"Backup"}'

    try {
        $resp      = Invoke-RestMethod -Uri ($BaseUrl + "/api/" + $ApiVersion + "/command") `
                         -Method POST -Headers $headers -Body $body -ContentType "application/json"
        $commandId = $resp.id
        Write-Log ("[" + $AppName + "] Backup command queued (id=" + $commandId + "), polling...")

        $deadline = (Get-Date).AddSeconds($ApiTimeoutSec)
        while ((Get-Date) -lt $deadline) {
            Start-Sleep -Seconds 2
            $cmd = Invoke-RestMethod -Uri ($BaseUrl + "/api/" + $ApiVersion + "/command/" + $commandId) `
                       -Headers $headers
            if ($cmd.status -eq "completed") {
                Write-Log ("[" + $AppName + "] API backup completed") "OK"
                break
            }
            if ($cmd.status -eq "failed") {
                Write-Log ("[" + $AppName + "] API backup failed: " + $cmd.exception) "FAIL"
                return $null
            }
        }

        if ((Get-Date) -ge $deadline) {
            Write-Log ("[" + $AppName + "] Timed out waiting for API backup") "WARN"
        }

        $zip = Get-ChildItem -Path $NativeBackupDir -Filter "*.zip" -Recurse -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending |
               Select-Object -First 1
        return $zip

    } catch {
        Write-Log ("[" + $AppName + "] API request failed: " + $_.Exception.Message) "FAIL"
        return $null
    }
}

# ---------------------------------------------------------------------------
# Helper: copy raw DB files (fallback / no-API mode)
# ---------------------------------------------------------------------------
function Copy-RawDb {
    param(
        [string]$AppName,
        [string]$SourceDir,
        [string[]]$Files
    )

    $destDir = Join-Path $backupDir $AppName
    New-Item -Path $destDir -ItemType Directory -Force | Out-Null

    $copied = 0
    foreach ($f in $Files) {
        $src = Join-Path $SourceDir $f
        if (Test-Path $src) {
            Copy-Item $src -Destination $destDir -Force
            $copied++
        } else {
            Write-Log ("[" + $AppName + "] File not found: " + $f) "WARN"
        }
    }
    return $copied
}

# ---------------------------------------------------------------------------
# 1. Sonarr
# ---------------------------------------------------------------------------
Write-Log "--- Sonarr ---"
$sonarrDataDir   = "C:\ProgramData\Sonarr"
$sonarrBackupDir = Join-Path $sonarrDataDir "Backups"
$sonarrDbFiles   = @("config.xml", "sonarr.db", "sonarr.db-shm", "sonarr.db-wal")

if ($SkipApiBackups -or (-not $SonarrApiKey)) {
    Write-Log "[Sonarr] Copying raw database files..."
    $count = Copy-RawDb "Sonarr" $sonarrDataDir $sonarrDbFiles
    if ($count -gt 0) {
        Write-Log ("[Sonarr] Copied " + $count + " file(s)") "OK"
        Add-Result "Sonarr" "OK" ("raw DB files (" + $count + ")")
    } else {
        Write-Log "[Sonarr] No files copied -- is Sonarr installed?" "FAIL"
        Add-Result "Sonarr" "FAIL" "source not found"
    }
} else {
    $zip = Invoke-ArrBackup "Sonarr" $SonarrUrl $SonarrApiKey "v3" $sonarrBackupDir
    if ($zip) {
        $dest   = Join-Path $backupDir "Sonarr"
        New-Item -Path $dest -ItemType Directory -Force | Out-Null
        Copy-Item $zip.FullName -Destination $dest
        $sizeMB = [math]::Round($zip.Length / 1MB, 2)
        $detail = $zip.Name + " (" + $sizeMB + " MB)"
        Write-Log ("[Sonarr] Backed up: " + $detail) "OK"
        Add-Result "Sonarr" "OK" $detail
    } else {
        Write-Log "[Sonarr] API backup failed -- falling back to raw DB copy" "WARN"
        $count = Copy-RawDb "Sonarr" $sonarrDataDir $sonarrDbFiles
        Add-Result "Sonarr" "WARN" ("fallback raw DB (" + $count + " files)")
    }
}
Write-Log ""

# ---------------------------------------------------------------------------
# 2. Prowlarr
# ---------------------------------------------------------------------------
Write-Log "--- Prowlarr ---"
$prowlarrDataDir   = "C:\ProgramData\Prowlarr"
$prowlarrBackupDir = Join-Path $prowlarrDataDir "Backups"
$prowlarrDbFiles   = @("config.xml", "prowlarr.db", "prowlarr.db-shm", "prowlarr.db-wal")

if ($SkipApiBackups -or (-not $ProwlarrApiKey)) {
    Write-Log "[Prowlarr] Copying raw database files..."
    $count = Copy-RawDb "Prowlarr" $prowlarrDataDir $prowlarrDbFiles
    if ($count -gt 0) {
        Write-Log ("[Prowlarr] Copied " + $count + " file(s)") "OK"
        Add-Result "Prowlarr" "OK" ("raw DB files (" + $count + ")")
    } else {
        Write-Log "[Prowlarr] No files copied -- is Prowlarr installed?" "FAIL"
        Add-Result "Prowlarr" "FAIL" "source not found"
    }
} else {
    $zip = Invoke-ArrBackup "Prowlarr" $ProwlarrUrl $ProwlarrApiKey "v1" $prowlarrBackupDir
    if ($zip) {
        $dest   = Join-Path $backupDir "Prowlarr"
        New-Item -Path $dest -ItemType Directory -Force | Out-Null
        Copy-Item $zip.FullName -Destination $dest
        $sizeMB = [math]::Round($zip.Length / 1MB, 2)
        $detail = $zip.Name + " (" + $sizeMB + " MB)"
        Write-Log ("[Prowlarr] Backed up: " + $detail) "OK"
        Add-Result "Prowlarr" "OK" $detail
    } else {
        Write-Log "[Prowlarr] API backup failed -- falling back to raw DB copy" "WARN"
        $count = Copy-RawDb "Prowlarr" $prowlarrDataDir $prowlarrDbFiles
        Add-Result "Prowlarr" "WARN" ("fallback raw DB (" + $count + " files)")
    }
}
Write-Log ""

# ---------------------------------------------------------------------------
# 3. Radarr
# ---------------------------------------------------------------------------
Write-Log "--- Radarr ---"
$radarrDataDir   = "C:\ProgramData\Radarr"
$radarrBackupDir = Join-Path $radarrDataDir "Backups"
$radarrDbFiles   = @("config.xml", "radarr.db", "radarr.db-shm", "radarr.db-wal")

if ($SkipApiBackups -or (-not $RadarrApiKey)) {
    Write-Log "[Radarr] Copying raw database files..."
    $count = Copy-RawDb "Radarr" $radarrDataDir $radarrDbFiles
    if ($count -gt 0) {
        Write-Log ("[Radarr] Copied " + $count + " file(s)") "OK"
        Add-Result "Radarr" "OK" ("raw DB files (" + $count + ")")
    } else {
        Write-Log "[Radarr] No files copied -- is Radarr installed?" "FAIL"
        Add-Result "Radarr" "FAIL" "source not found"
    }
} else {
    $zip = Invoke-ArrBackup "Radarr" $RadarrUrl $RadarrApiKey "v3" $radarrBackupDir
    if ($zip) {
        $dest   = Join-Path $backupDir "Radarr"
        New-Item -Path $dest -ItemType Directory -Force | Out-Null
        Copy-Item $zip.FullName -Destination $dest
        $sizeMB = [math]::Round($zip.Length / 1MB, 2)
        $detail = $zip.Name + " (" + $sizeMB + " MB)"
        Write-Log ("[Radarr] Backed up: " + $detail) "OK"
        Add-Result "Radarr" "OK" $detail
    } else {
        Write-Log "[Radarr] API backup failed -- falling back to raw DB copy" "WARN"
        $count = Copy-RawDb "Radarr" $radarrDataDir $radarrDbFiles
        Add-Result "Radarr" "WARN" ("fallback raw DB (" + $count + " files)")
    }
}
Write-Log ""

# ---------------------------------------------------------------------------
# 4. Calibre-Web
# ---------------------------------------------------------------------------
Write-Log "--- Calibre-Web ---"
$calibreWebDb = "A:\Media\Calibre-Web-Config\app.db"

if (Test-Path $calibreWebDb) {
    $dest = Join-Path $backupDir "CalibreWeb"
    New-Item -Path $dest -ItemType Directory -Force | Out-Null
    Copy-Item $calibreWebDb -Destination $dest
    $sizeMB = [math]::Round((Get-Item $calibreWebDb).Length / 1MB, 2)
    $detail = "app.db (" + $sizeMB + " MB)"
    Write-Log ("[Calibre-Web] Backed up " + $detail) "OK"
    Add-Result "Calibre-Web" "OK" $detail
} else {
    Write-Log ("[Calibre-Web] app.db not found: " + $calibreWebDb) "FAIL"
    Add-Result "Calibre-Web" "FAIL" ("not found: " + $calibreWebDb)
}
Write-Log ""

# ---------------------------------------------------------------------------
# 5. Cloudflare Tunnel
# ---------------------------------------------------------------------------
Write-Log "--- Cloudflare Tunnel ---"
$cloudflaredDir = Join-Path $env:USERPROFILE ".cloudflared"
$cfStaticFiles  = @("config.yml", "cert.pem")

$cfJsonFiles = @(Get-ChildItem -Path $cloudflaredDir -Filter "*.json" -ErrorAction SilentlyContinue |
                 Select-Object -ExpandProperty Name)
$allCfFiles  = $cfStaticFiles + $cfJsonFiles

$dest = Join-Path $backupDir "Cloudflare"
New-Item -Path $dest -ItemType Directory -Force | Out-Null

$copied = 0
foreach ($f in $allCfFiles) {
    $src = Join-Path $cloudflaredDir $f
    if (Test-Path $src) {
        Copy-Item $src -Destination $dest
        $copied++
    } else {
        Write-Log ("[Cloudflare] File not found: " + $f) "WARN"
    }
}

if ($copied -gt 0) {
    Write-Log ("[Cloudflare] Backed up " + $copied + " file(s)") "OK"
    Add-Result "Cloudflare Tunnel" "OK" ($copied.ToString() + " files")
} else {
    Write-Log ("[Cloudflare] No files found in: " + $cloudflaredDir) "FAIL"
    Add-Result "Cloudflare Tunnel" "FAIL" "directory not found"
}
Write-Log ""

# ---------------------------------------------------------------------------
# 6. Compress staging directory to zip
# ---------------------------------------------------------------------------
Write-Log "--- Compressing ---"
$archivePath = $backupDir + ".zip"

try {
    Compress-Archive -Path ($backupDir + "\*") -DestinationPath $archivePath -CompressionLevel Optimal
    $sizeMB = [math]::Round((Get-Item $archivePath).Length / 1MB, 2)
    Write-Log ("Archive: " + (Split-Path $archivePath -Leaf) + " (" + $sizeMB + " MB)") "OK"
    Remove-Item -Path $backupDir -Recurse -Force
} catch {
    Write-Log ("Compression failed: " + $_.Exception.Message + " -- leaving uncompressed") "WARN"
    $archivePath = $backupDir
}
Write-Log ""

# ---------------------------------------------------------------------------
# 7. Prune old backups beyond retention limit
# ---------------------------------------------------------------------------
Write-Log ("--- Pruning old backups (keep " + $KeepCount + ") ---")

$existing = Get-ChildItem -Path $BackupRoot |
            Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}' } |
            Sort-Object Name -Descending

$toDelete = $existing | Select-Object -Skip $KeepCount
if ($toDelete) {
    foreach ($item in $toDelete) {
        Remove-Item -Path $item.FullName -Recurse -Force
        Write-Log ("Deleted old backup: " + $item.Name)
    }
    Write-Log ("Pruned " + $toDelete.Count + " old backup(s)") "OK"
} else {
    Write-Log ("No pruning needed (" + $existing.Count + " backup(s) on disk)")
}
Write-Log ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Backup Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$okCount   = @($results | Where-Object { $_.Status -eq "OK"   }).Count
$warnCount = @($results | Where-Object { $_.Status -eq "WARN" }).Count
$failCount = @($results | Where-Object { $_.Status -eq "FAIL" }).Count

foreach ($r in $results) {
    $symbol = switch ($r.Status) { "OK" { "[OK]  " } "WARN" { "[WARN] " } "FAIL" { "[FAIL] " } }
    $color  = switch ($r.Status) { "OK" { "Green" } "WARN" { "Yellow" } "FAIL" { "Red" } }
    $line   = "  " + $symbol + $r.Name
    if ($r.Detail) { $line += "  (" + $r.Detail + ")" }
    Write-Host $line -ForegroundColor $color
}

Write-Host ""
Write-Host ("  Archive : " + $archivePath) -ForegroundColor White
Write-Host ("  Log     : " + $logPath)     -ForegroundColor White
Write-Host ""

if ($failCount -eq 0 -and $warnCount -eq 0) {
    Write-Host "  All services backed up successfully." -ForegroundColor Green
} elseif ($failCount -eq 0) {
    Write-Host ("  Backup complete with " + $warnCount + " warning(s) -- review log.") -ForegroundColor Yellow
} else {
    Write-Host ("  Backup completed with " + $failCount + " failure(s) -- review log.") -ForegroundColor Red
    exit 1
}
Write-Host ""
