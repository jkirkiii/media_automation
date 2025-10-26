# Diagnostic script to understand deletion issues
# Run as Administrator

$testFolder = "A:\Media\Movies\Barb and Star Go to Vista del Mar (2021)"

Write-Host "=== DIAGNOSTIC TEST ===" -ForegroundColor Cyan
Write-Host ""

# Check if folder exists
if (Test-Path $testFolder) {
    Write-Host "[EXISTS] Folder found: $testFolder" -ForegroundColor Yellow

    # Get folder details
    $folder = Get-Item $testFolder
    Write-Host "Attributes: $($folder.Attributes)" -ForegroundColor White

    # Check contents
    $files = Get-ChildItem $testFolder -File
    Write-Host "Files inside: $($files.Count)" -ForegroundColor White
    foreach ($file in $files) {
        Write-Host "  - $($file.Name) (Attributes: $($file.Attributes))" -ForegroundColor Gray
    }

    # Try different deletion methods
    Write-Host ""
    Write-Host "Testing deletion methods..." -ForegroundColor Cyan

    # Method 1: Standard Remove-Item
    Write-Host "Method 1: Standard Remove-Item..." -ForegroundColor Yellow
    try {
        Remove-Item -Path $testFolder -Recurse -Force -ErrorAction Stop
        Write-Host "  SUCCESS - Folder deleted" -ForegroundColor Green
    } catch {
        Write-Host "  FAILED - $_" -ForegroundColor Red
    }

    # Check if still exists
    if (Test-Path $testFolder) {
        Write-Host "  Folder STILL EXISTS after Remove-Item" -ForegroundColor Red

        # Method 2: CMD rmdir
        Write-Host ""
        Write-Host "Method 2: CMD rmdir /s /q..." -ForegroundColor Yellow
        cmd /c "rmdir /s /q `"$testFolder`" 2>&1"

        if (Test-Path $testFolder) {
            Write-Host "  Folder STILL EXISTS after rmdir" -ForegroundColor Red

            # Method 3: Take ownership and delete
            Write-Host ""
            Write-Host "Method 3: Take ownership..." -ForegroundColor Yellow
            takeown /F $testFolder /R /D Y | Out-Null
            icacls $testFolder /grant "$($env:USERNAME):(OI)(CI)F" /T | Out-Null
            Remove-Item -Path $testFolder -Recurse -Force -ErrorAction SilentlyContinue

            if (Test-Path $testFolder) {
                Write-Host "  Folder STILL EXISTS after takeown" -ForegroundColor Red

                # Check for locks
                Write-Host ""
                Write-Host "Checking for file locks..." -ForegroundColor Yellow
                $handles = Get-Process | Where-Object { $_.Path -like "$testFolder*" }
                if ($handles) {
                    Write-Host "  Found processes with handles:" -ForegroundColor Red
                    $handles | Format-Table Name, Id
                }
            } else {
                Write-Host "  SUCCESS - Folder deleted with takeown" -ForegroundColor Green
            }
        } else {
            Write-Host "  SUCCESS - Folder deleted with rmdir" -ForegroundColor Green
        }
    } else {
        Write-Host "  Confirmed - Folder successfully deleted" -ForegroundColor Green
    }
} else {
    Write-Host "[NOT FOUND] Folder doesn't exist - already deleted or path issue" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== TEST COMPLETE ===" -ForegroundColor Cyan
