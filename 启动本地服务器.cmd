@echo off
REM ====================================================================
REM  unlimited-ai - one-click local dev launcher (ASCII only)
REM  Place in project root so users can just double-click this file.
REM ====================================================================

setlocal
cd /d "%~dp0"

echo.
echo   Launching scripts\dev.cmd ...
echo.

call "%~dp0scripts\dev.cmd" %*

set EXITCODE=%ERRORLEVEL%
endlocal
exit /b %EXITCODE%
