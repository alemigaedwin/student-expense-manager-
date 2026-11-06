@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  Gradle startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

@rem Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS=

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto init

@rem Try standard locations if JAVA_HOME is not set
if exist "%ProgramFiles%\Android\Android Studio\jbr\bin\java.exe" (
    set "JAVA_HOME=%ProgramFiles%\Android\Android Studio\jbr"
    set "JAVA_EXE=%ProgramFiles%\Android\Android Studio\jbr\bin\java.exe"
    goto init
)
for /d %%D in ("%ProgramFiles%\Eclipse Adoptium\jdk*") do (
    if exist "%%D\bin\java.exe" (
        set "JAVA_HOME=%%D"
        set "JAVA_EXE=%%D\bin\java.exe"
        goto init
    )
)

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto init

@rem Auto-healing fallback: if configured JAVA_HOME has a placeholder (e.g. jdk-17.0.XX-hotspot) or does not exist,
@rem automatically search for actual installed JDK locations (Android Studio bundled JBR, Eclipse Adoptium, Oracle JDK, or PATH).
if exist "%ProgramFiles%\Android\Android Studio\jbr\bin\java.exe" (
    set "JAVA_HOME=%ProgramFiles%\Android\Android Studio\jbr"
    set "JAVA_EXE=%ProgramFiles%\Android\Android Studio\jbr\bin\java.exe"
    goto init
)
if exist "%ProgramFiles%\Android\Android Studio\jre\bin\java.exe" (
    set "JAVA_HOME=%ProgramFiles%\Android\Android Studio\jre"
    set "JAVA_EXE=%ProgramFiles%\Android\Android Studio\jre\bin\java.exe"
    goto init
)
if exist "%LocalAppData%\Android\Android Studio\jbr\bin\java.exe" (
    set "JAVA_HOME=%LocalAppData%\Android\Android Studio\jbr"
    set "JAVA_EXE=%LocalAppData%\Android\Android Studio\jbr\bin\java.exe"
    goto init
)
for /d %%D in ("%ProgramFiles%\Eclipse Adoptium\jdk*") do (
    if exist "%%D\bin\java.exe" (
        set "JAVA_HOME=%%D"
        set "JAVA_EXE=%%D\bin\java.exe"
        goto init
    )
)
for /d %%D in ("%ProgramFiles%\Java\jdk*") do (
    if exist "%%D\bin\java.exe" (
        set "JAVA_HOME=%%D"
        set "JAVA_EXE=%%D\bin\java.exe"
        goto init
    )
)
for /d %%D in ("%ProgramFiles(x86)%\Java\jdk*") do (
    if exist "%%D\bin\java.exe" (
        set "JAVA_HOME=%%D"
        set "JAVA_EXE=%%D\bin\java.exe"
        goto init
    )
)
where java.exe >NUL 2>&1
if "%ERRORLEVEL%" == "0" (
    set JAVA_EXE=java.exe
    goto init
)

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:init
@rem Get command-line arguments, handling Windowz variants

if not "%OS%" == "Windows_NT" goto win9xME_args
if "%@eval[2+2]" == "4" goto 4NT_args

:win9xME_args
@rem Slurp the command line arguments.
set CMD_LINE_ARGS=
set _SKIP=2

:win9xME_args_slurp
if "x%~1" == "x" goto execute

set CMD_LINE_ARGS=%*
goto execute

:4NT_args
@rem Get arguments from the 4NT Shell from JP Software
set CMD_LINE_ARGS=%$

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar

@rem Execute Gradle
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %GRADLE_OPTS% "-Dorg.gradle.appname=%APP_BASE_NAME%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %CMD_LINE_ARGS%

:end
@rem End local scope for the variables with windows NT shell
if "%ERRORLEVEL%"=="0" goto mainEnd

:fail
rem Set variable GRADLE_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
if  not "" == "%GRADLE_EXIT_CONSOLE%" exit 1
exit /b 1

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
