# Check Sonarr Media Management Settings
param(
    [string]$SonarrUrl = "http://localhost:8989",
    [string]$ApiKey = ""
)

$headers = @{
    "X-Api-Key" = $ApiKey
}

Write-Host "`n=== Sonarr Media Management Settings ===`n" -ForegroundColor Cyan

try {
    $config = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/config/mediamanagement" -Headers $headers

    Write-Host "Import Behavior:" -ForegroundColor Yellow
    Write-Host "  Auto Rename: $($config.autoRenameFolders)" -ForegroundColor White
    Write-Host "  Rename Episodes: $($config.renameEpisodes)" -ForegroundColor White
    Write-Host ""

    Write-Host "File Management:" -ForegroundColor Yellow
    Write-Host "  File Permissions: $($config.fileChmod)" -ForegroundColor White
    Write-Host "  Folder Permissions: $($config.folderChmod)" -ForegroundColor White
    Write-Host "  Copy Using Hardlinks: $($config.copyUsingHardlinks)" -ForegroundColor White
    Write-Host "  Import Extra Files: $($config.importExtraFiles)" -ForegroundColor White
    Write-Host ""

    Write-Host "Download Handling:" -ForegroundColor Yellow
    Write-Host "  Auto Unmonitor Deleted Episodes: $($config.autoUnmonitorPreviouslyDownloadedEpisodes)" -ForegroundColor White
    Write-Host "  Rescan After Refresh: $($config.rescanAfterRefresh)" -ForegroundColor White
    Write-Host ""

    Write-Host "Recycling Bin:" -ForegroundColor Yellow
    if ($config.recycleBin) {
        Write-Host "  Enabled: True" -ForegroundColor White
        Write-Host "  Path: $($config.recycleBin)" -ForegroundColor White
    } else {
        Write-Host "  Enabled: False" -ForegroundColor White
    }

    Write-Host "`nFull Config:" -ForegroundColor Cyan
    $config | ConvertTo-Json -Depth 5

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
