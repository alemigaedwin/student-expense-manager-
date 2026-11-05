@echo off
setlocal enabledelayedexpansion
title Student Expense Manager - Fix Java & Build APK

echo =====================================================================
echo       STUDENT EXPENSE MANAGER - AUTOMATIC JAVA FIX & BUILD
echo =====================================================================
echo.

set "FOUND_JDK="

REM 1. Check for Eclipse Adoptium JDK
for /d %%D in ("%ProgramFiles%\Eclipse Adoptium\jdk*") do (
    if exist "%%D\bin\java.exe" (
        set "FOUND_JDK=%%D"
        goto :jdk_found
    )
)

REM 2. Check for Android Studio bundled JBR
if exist "%ProgramFiles%\Android\Android Studio\jbr\bin\java.exe" (
    set "FOUND_JDK=%ProgramFiles%\Android\Android Studio\jbr"
    goto :jdk_found
)

REM 3. Check for standard Oracle / OpenJDK in Program Files\Java
for /d %%D in ("%ProgramFiles%\Java\jdk*") do (
    if exist "%%D\bin\java.exe" (
        set "FOUND_JDK=%%D"
        goto :jdk_found
    )
)

REM 4. Check for Android Studio JRE
if exist "%ProgramFiles%\Android\Android Studio\jre\bin\java.exe" (
    set "FOUND_JDK=%ProgramFiles%\Android\Android Studio\jre"
    goto :jdk_found
)

REM 5. Check Local AppData Android Studio JBR
if exist "%LocalAppData%\Android\Android Studio\jbr\bin\java.exe" (
    set "FOUND_JDK=%LocalAppData%\Android\Android Studio\jbr"
    goto :jdk_found
)

:jdk_found
if not defined FOUND_JDK (
    echo [!] Could not automatically detect a JDK installation.
    echo Please ensure Android Studio or Eclipse Adoptium JDK 17 is installed.
    echo.
    pause
    exit /b 1
)

echo [*] Detected valid Java installation at:
echo     "%FOUND_JDK%"
echo.
echo [*] Updating JAVA_HOME environment variable permanently...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.Environment]::SetEnvironmentVariable('JAVA_HOME', '%FOUND_JDK%', 'User')"

set "JAVA_HOME=%FOUND_JDK%"
set "PATH=%FOUND_JDK%\bin;%PATH%"

echo [OK] JAVA_HOME successfully set to: %JAVA_HOME%
echo.

echo =====================================================================
echo Building Release APK for Android Smartphones...
echo =====================================================================
call flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =====================================================================
    echo [SUCCESS] APK built successfully!
    echo Output location:
    echo     build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo You can copy app-release.apk to your phone and install it directly!
    echo =====================================================================
) else (
    echo.
    echo [!] Build encountered an issue. See above output for details.
)

pause
