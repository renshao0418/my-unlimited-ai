#Requires -Version 5.1
<#
.SYNOPSIS
  unlimited-ai local dev bootstrap (Windows PowerShell)
.DESCRIPTION
  1. Check Node.js / npm
  2. Install wrangler globally if missing
  3. Validate NVIDIA_API_KEY in .dev.vars
  4. Optionally install VC++ Redistributable for workerd
  5. Start wrangler dev
.NOTES
  Double-click: use dev.cmd in the same folder
  CLI: powershell -ExecutionPolicy Bypass -File scripts\dev.ps1
#>

[CmdletBinding()]
param(
  [string]$BindHost = "0.0.0.0",
  [int]$Port        = 8787,
  [switch]$SkipVCFix = $false
)

$ErrorActionPreference = "Stop"
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Push-Location $ProjectRoot
try {

  # ---------- console encoding (critical for Chinese output from cmd) ----------
  try {
    & chcp 65001 >$null 2>&1
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [Console]::OutputEncoding = $utf8
    [Console]::InputEncoding  = $utf8
    $OutputEncoding           = $utf8
  } catch { }

  # ---------- helpers ----------
  function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
  function Write-OK($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
  function Write-Warn($msg) { Write-Host "    [!]  $msg" -ForegroundColor Yellow }
  function Write-Fail($msg) { Write-Host "    [X]  $msg" -ForegroundColor Red }

  function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
  }

  function Get-NpmGlobalBin() {
    $prefix = & npm config get prefix 2>$null
    if (-not $prefix) { return $null }
    return (Join-Path $prefix)
  }

  function Resolve-WranglerPath() {
    if (Test-Command wrangler) { return "wrangler" }
    $globalBin = Get-NpmGlobalBin
    if ($globalBin) {
      foreach ($c in @(
        (Join-Path $globalBin "wrangler.cmd"),
        (Join-Path $globalBin "wrangler.ps1"),
        (Join-Path $globalBin "wrangler"))) {
        if (Test-Path $c) { return $c }
      }
    }
    return $null
  }

  # ---------- banner ----------
  Write-Host ""
  Write-Host "  +----------------------------------------------+" -ForegroundColor Magenta
  Write-Host "  |     unlimited-ai - Local Dev Bootstrap       |" -ForegroundColor Magenta
  Write-Host "  +----------------------------------------------+" -ForegroundColor Magenta
  Write-Host "  Project : $ProjectRoot"
  Write-Host "  URL     : http://$BindHost`:$Port"

  # ---------- Step 1: Node / npm ----------
  Write-Step "Step 1/5 Check Node.js / npm"

  if (-not (Test-Command node)) {
    Write-Fail "Node.js not found. Install LTS from https://nodejs.org/"
    exit 1
  }
  $nodeVer = & node --version
  Write-OK "Node.js $nodeVer"

  if (-not (Test-Command npm)) {
    Write-Fail "npm not found - it ships with Node.js, please reinstall Node.js."
    exit 1
  }
  $npmVer = & npm --version
  Write-OK "npm $npmVer"

  # ---------- Step 2: wrangler ----------
  Write-Step "Step 2/5 Check wrangler CLI"

  $wranglerExe = Resolve-WranglerPath
  if (-not $wranglerExe) {
    Write-Warn "wrangler not installed - installing globally..."
    & npm i -g wrangler
    if ($LASTEXITCODE -ne 0) {
      Write-Fail "wrangler install failed. Please run:  npm i -g wrangler"
      exit 1
    }
    $wranglerExe = Resolve-WranglerPath
    if (-not $wranglerExe) {
      Write-Fail "wrangler binary still not found after install. Restart terminal or check npm global PATH."
      exit 1
    }
  }

  $wrVer = & $wranglerExe --version 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-OK "wrangler $wrVer  ->  $wranglerExe"
  } else {
    Write-OK "wrangler ready  ->  $wranglerExe"
  }

  # ---------- Step 3: .dev.vars ----------
  Write-Step "Step 3/5 Validate NVIDIA_API_KEY (.dev.vars)"

  $devVarsPath = Join-Path $ProjectRoot ".dev.vars"
  if (-not (Test-Path $devVarsPath)) {
    Write-Warn ".dev.vars not found - creating template..."
    "NVIDIA_API_KEY=REPLACE_WITH_YOUR_REAL_NVIDIA_API_KEY" |
      Set-Content -Path $devVarsPath -Encoding UTF8
    Write-Fail "Created .dev.vars in project root. Fill in a real NVIDIA_API_KEY then re-run."
    Write-Host "    Get one at: https://build.nvidia.com/" -ForegroundColor DarkGray
    exit 1
  }

  $devVars = @{}
  Get-Content $devVarsPath | ForEach-Object {
    if ($_ -match '^\s*([^#=][^=]*?)\s*=\s*(.*?)\s*$') {
      $devVars[$Matches[1]] = $Matches[2]
    }
  }

  $key = $devVars["NVIDIA_API_KEY"]
  if ([string]::IsNullOrWhiteSpace($key) -or
      $key -match 'REPLACE_WITH|YOUR_REAL|xxxxx|此处|你的') {
    Write-Fail "NVIDIA_API_KEY in .dev.vars is empty or still a placeholder. Put a real key there."
    exit 1
  }
  $masked = if ($key.Length -gt 8) { $key.Substring(0, 8) + "..." } else { "***" }
  Write-OK "NVIDIA_API_KEY configured ($masked)"

  # ---------- Step 4: VC++ Redistributable ----------
  Write-Step "Step 4/5 VC++ Redistributable (workerd compatibility)"

  if (-not $SkipVCFix) {
    $vcInstalled = $false
    $vcVersion = ""
    foreach ($rp in @(
      "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64",
      "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64")) {
      if (Test-Path $rp) {
        $val = Get-ItemProperty $rp -ErrorAction SilentlyContinue
        if ($val -and $val.Installed -eq 1) {
          $vcInstalled = $true
          $vcVersion = $val.Version
          break
        }
      }
    }

    if ($vcInstalled) {
      Write-OK "VC++ 2015-2022 x64 Redistributable installed (v$vcVersion)"
    } else {
      Write-Warn "VC++ Redistributable not detected - workerd runtime may crash with access violation."
      $ans = Read-Host "    Auto-install via winget? [Y/n] (default Y)"
      if ($ans -ne "n" -and $ans -ne "N") {
        if (Test-Command winget) {
          Write-Host "    Installing Microsoft.VCRedist.2015+.x64 via winget..." -ForegroundColor DarkGray
          & winget install --id Microsoft.VCRedist.2015+.x64 -e --accept-package-agreements --accept-source-agreements
          if ($LASTEXITCODE -eq 0) {
            Write-OK "VC++ Redistributable installed"
          } else {
            Write-Warn "VC++ install returned non-zero. If wrangler dev crashes later, install manually from:"
            Write-Host "    https://aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor Cyan
          }
        } else {
          Write-Fail "winget not found. Install VC++ manually from:"
          Write-Host "    https://aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor Cyan
          exit 1
        }
      } else {
        Write-Warn "Skipped. Re-run this script without -SkipVCFix later if workerd crashes."
      }
    }
  } else {
    Write-Warn "-SkipVCFix supplied - skipped VC++ check"
  }

  # ---------- Step 5: start wrangler dev ----------
  Write-Step "Step 5/5 Start wrangler dev"
  Write-Host "    Open in browser: http://127.0.0.1:$Port" -ForegroundColor Green
  Write-Host "    Chat password   : CHAT_PASSWORD in src/config.js (default 123456)" -ForegroundColor DarkGray
  Write-Host "    Press Ctrl+C to stop`n" -ForegroundColor DarkGray

  & $wranglerExe dev --ip $BindHost --port $Port

  if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Fail "wrangler exited abnormally (exit $LASTEXITCODE)"
    Write-Host "    Tip: on access violation re-run script to install VC++ (drop -SkipVCFix)" -ForegroundColor Yellow
    exit $LASTEXITCODE
  }

} finally {
  Pop-Location
}