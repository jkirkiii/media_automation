# Verify-MediaTargets.ps1
# Confirms each candidate-for-removal entry in hardlink_analysis CSV actually
# has a video file in the Media library before deletion.

param(
    [string]$CsvFile = ""
)

$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not $CsvFile) {
    $cands = @(Get-ChildItem (Join-Path $repoRoot "data") -Filter "hardlink_analysis_*.csv" -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
    if ($cands) { $CsvFile = $cands[0].FullName }
}
if (-not (Test-Path $CsvFile)) { Write-Host "[ERROR] CSV not found"; exit 1 }

$videoExt = '.mkv','.mp4','.avi','.m4v','.mov','.wmv','.iso','.ts','.m2ts'

function Test-HasVideo($target) {
    if (-not $target) { return $false }
    # If it's a file path, just check the file exists.
    if (Test-Path -LiteralPath $target -PathType Leaf) { return $true }
    # If it's a folder, check there is at least one video file inside.
    if (Test-Path -LiteralPath $target -PathType Container) {
        $files = Get-ChildItem -LiteralPath $target -Recurse -File -ErrorAction SilentlyContinue |
                 Where-Object { $videoExt -contains $_.Extension.ToLower() } |
                 Select-Object -First 1
        return [bool]$files
    }
    return $false
}

$safe = @('UPGRADE_ORPHAN_EPISODE','SEASON_COMPLETE','MOVIE_FOUND')
$rows = Import-Csv $CsvFile | Where-Object { $safe -contains $_.Category }

$ok = New-Object System.Collections.Generic.List[object]
$bad = New-Object System.Collections.Generic.List[object]

foreach ($r in $rows) {
    $target = $r.MediaPath
    if (-not $target) { $target = $r.MediaMatch }
    if (-not $target) {
        $bad.Add($r); continue
    }
    if (Test-HasVideo $target) {
        $ok.Add([PSCustomObject]@{ Name=$r.Name; Category=$r.Category; Media=$target })
    } else {
        $bad.Add([PSCustomObject]@{ Name=$r.Name; Category=$r.Category; Media=$target; Reason='no video file' })
    }
}

Write-Host ""
Write-Host ("Verified : {0}" -f $ok.Count) -ForegroundColor Green
Write-Host ("Failed   : {0}" -f $bad.Count) -ForegroundColor Yellow
if ($bad.Count -gt 0) {
    Write-Host ""
    Write-Host "--- Failed verification (DO NOT remove without checking) ---" -ForegroundColor Yellow
    $bad | Format-Table -AutoSize
}
