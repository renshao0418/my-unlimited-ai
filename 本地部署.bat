@echo off
REM =========================================================================
REM  双击启动 unlimited-ai 本地开发服务器（Cloudflare Workers / wrangler dev）
REM  包装 本地部署.ps1，并自动绕过 PowerShell 默认执行策略。
REM
REM  用法：
REM    本地部署.bat                      -> 默认 127.0.0.1:8787（本地模式 --local）
REM    本地部署.bat --ip 0.0.0.0 --port 8080
REM    本地部署.bat --Remote              -> Cloudflare 远程模式（需先登录）
REM =========================================================================

setlocal
cd /d "%~dp0"

echo ==> Launching dev.ps1 (ExecutionPolicy Bypass) ...
echo.

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
  -File "%~dp0dev.ps1" %*
set "EXIT_CODE=%ERRORLEVEL%"

if NOT "%EXIT_CODE%"=="0" (
  echo.
  echo [X] dev.ps1 exited with code %EXIT_CODE%
  echo     Press any key to close this window ...
  pause > nul
)

endlocal
exit /b %EXIT_CODE%
