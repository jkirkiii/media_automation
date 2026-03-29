# Check Sonarr Download Client Configuration
param(
    [string]$SonarrUrl = "http://localhost:8989",
    [string]$ApiKey = ""
)

$headers = @{ "X-Api-Key" = $ApiKey }

Write-Host ""
Write-Host "=== Sonarr Download Client Configuration ===" -ForegroundColor Cyan
Write-Host ""

try {
    $clients = Invoke-RestMethod -Uri "$SonarrUrl/api/v3/downloadclient" -Headers $headers

    foreach ($client in $clients) {
        Write-Host "Client: $($client.name)" -ForegroundColor Yellow
        Write-Host "  Type: $($client.implementation)" -ForegroundColor White
        Write-Host "  Protocol: $($client.protocol)" -ForegroundColor White
        Write-Host "  Enabled: $($client.enable)" -ForegroundColor White

        Write-Host ""
        Write-Host "  Fields:" -ForegroundColor Gray
        foreach ($field in $client.fields) {
            if ($field.name -like "*path*" -or $field.name -like "*category*" -or $field.name -like "*directory*") {
                Write-Host "    $($field.name): $($field.value)" -ForegroundColor Cyan
            } else {
                Write-Host "    $($field.name): $($field.value)" -ForegroundColor White
            }
        }
        Write-Host ""
    }

    Write-Host "Full JSON:" -ForegroundColor Yellow
    $clients | ConvertTo-Json -Depth 10

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
