@echo off
title Student Expense Manager - Free 24/7 Live Public URL Generator
echo =====================================================================
echo    STUDENT EXPENSE MANAGER - 100%% FREE PUBLIC CLOUD TUNNEL
echo =====================================================================
echo.
echo This tool makes your local XAMPP backend instantly accessible
echo to smartphones anywhere in the world with a secure HTTPS URL!
echo.
echo Checking for Localtunnel (npx / node)...
where npx >NUL 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [*] Starting free Localtunnel on port 80...
    echo [*] Your free public URL will appear below:
    npx localtunnel --port 80
    goto :end
)

echo Checking for Cloudflare Tunnel (cloudflared)...
where cloudflared >NUL 2>&1
if %ERRORLEVEL% EQU 0 (
    cloudflared tunnel --url http://localhost:80
    goto :end
)

echo.
echo [!] Neither npx nor cloudflared were detected on this machine.
echo.
echo To host your backend 100%% FREE on the cloud so any student can access it:
echo 1. Recommended: Register free at https://www.infinityfree.com (Free PHP + MySQL)
echo 2. Upload the files in the 'backend' folder to your free web host.
echo 3. Copy your live URL (e.g. https://your-site.infinityfreeapp.com/api.php)
echo 4. In your smartphone app, tap "Database: ..." on the Login screen, paste your URL, and tap Save!
echo.
:end
pause
