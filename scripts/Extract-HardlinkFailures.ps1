# Extract-HardlinkFailures.ps1
# Parses captured stdout from Remove-SeededTorrents.ps1 (dry run) and writes
# a fresh hardlink_failures.txt for Analyze-HardlinkFailures.ps1 to consume.

param(
    [string]$InputFile  = "",
    [string]$OutputFile = ""
)

$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not $InputFile)  { $InputFile  = Join-Path $repoRoot "data\seeded_dryrun_2026-06-06.txt" }
if (-not $OutputFile) { $OutputFile = Join-Path $repoRoot "data\hardlink_failures.txt" }

if (-not (Test-Path $InputFile)) {
    Write-Host "[ERROR] Input file not found: $InputFile" -ForegroundColor Red
    exit 1
}

$lines = Get-Content $InputFile -Encoding UTF8

# Locate the SKIPPED section and its end marker.
$startIdx = $null
$endIdx   = $null
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($null -eq $startIdx -and $lines[$i] -match 'SKIPPED: hardlink check failed') {
        $startIdx = $i
        continue
    }
    if ($null -ne $startIdx -and $lines[$i] -match '^--- Skipped \d+ torrents') {
        $endIdx = $i
        break
    }
}

if ($null -eq $startIdx) {
    Write-Host "[ERROR] Could not find SKIPPED header in $InputFile" -ForegroundColor Red
    exit 1
}
if ($null -eq $endIdx) { $endIdx = $lines.Count }

# Format-Table output columns: Name | Reason | SizeGB. The Name column ends
# where "hardlink check FAILED" begins. Use that as a left-anchored split.
$nameMarker = 'hardlink check FAILED'
$names = New-Object System.Collections.Generic.List[string]
for ($i = $startIdx; $i -lt $endIdx; $i++) {
    $line = $lines[$i]
    $hit  = $line.IndexOf($nameMarker)
    if ($hit -lt 1) { continue }
    $name = $line.Substring(0, $hit).TrimEnd()
    if ([string]::IsNullOrWhiteSpace($name)) { continue }
    # Skip the column header itself if it ever shows up
    if ($name -eq 'Name') { continue }
    $names.Add($name) | Out-Null
}

if ($names.Count -eq 0) {
    Write-Host "[WARN] No hardlink failures found in input." -ForegroundColor Yellow
    exit 0
}

# Write file in the format Analyze-HardlinkFailures.ps1 expects:
# a header line followed by names (one per line).
$header = @(
    "--- SKIPPED: hardlink check failed (files may not be in Media library) ---",
    "",
    "Name",
    "----"
)
$out = $header + $names
$out | Set-Content -Path $OutputFile -Encoding UTF8

Write-Host ("[OK] Wrote " + $names.Count + " hardlink failures to " + $OutputFile) -ForegroundColor Green
