@echo off
setlocal
echo =====================================================================
echo    Packaging Student Expense Manager for Android Studio
echo =====================================================================
echo.

set "PROJECT_DIR=%~dp0"
set "ZIP_OUT=%PROJECT_DIR%student_expense_manager_android_studio.zip"
set "ARTIFACT_DIR=C:\Users\EDDY B\.gemini\antigravity\brain\03317478-e3d9-4a60-a801-7ba72a906f84\student_expense_manager_android_studio.zip"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$dest = '%ZIP_OUT%';" ^
    "if (Test-Path $dest) { Remove-Item $dest -Force };" ^
    "$items = Get-ChildItem -Path '%PROJECT_DIR%' | Where-Object { $_.Name -notin @('build', '.dart_tool', '.git') -and $_.Extension -ne '.zip' };" ^
    "Compress-Archive -Path $items.FullName -DestinationPath $dest -CompressionLevel Optimal;" ^
    "if (Test-Path '%ARTIFACT_DIR%') { Remove-Item '%ARTIFACT_DIR%' -Force };" ^
    "Copy-Item $dest '%ARTIFACT_DIR%' -Force;" ^
    "Write-Host '[SUCCESS] Zip archive created successfully:';" ^
    "Write-Host '  Local path:    ' $dest;" ^
    "Write-Host '  Artifact path: ' '%ARTIFACT_DIR%';"

echo.
pause
