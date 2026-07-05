@echo off
REM ====================================================================
REM  unlimited-ai local dev double-click launcher (ASCII only)
REM  Bypasses PowerShell ExecutionPolicy and calls scripts\dev.ps1
REM ====================================================================

setlocal

cd /d "%~dp0\.."

echo.
echo   Starting unlimited-ai local dev server...
echo.

REM === Launch PowerShell script with Bypass policy =============
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass ^
  -File "%~dp0dev.ps1" %*

set EXITCODE=%ERRORLEVEL%

if not "%EXITCODE%"=="0" (
  echo.
  echo   [ERROR] Startup failed with exit code %EXITCODE%.
  echo.
  pause
)

endlocal
exit /b %EXITCODE%
