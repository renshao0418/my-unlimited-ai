<#
.SYNOPSIS
  One-click launch of the unlimited-ai Cloudflare Workers dev server.

.DESCRIPTION
  Runs out-of-the-box on Windows, no global config required:
    1. Pins WRANGLER_HOME / XDG_CONFIG_HOME to a project-local
       .wrangler-home folder so nothing is written under %AppData%.
       Works around sandbox / restricted-user EPERM errors.
    2. Checks Node.js availability and presence of .dev.vars.
    3. Defaults to --local mode; pass -Remote for Cloudflare remote.

.PARAMETER Ip
  Bind address, default 127.0.0.1.
.PARAMETER Port
  Bind port, default 8787.
.PARAMETER Remote
  Disable --local and connect to your Cloudflare account
  (requires `npx wrangler login` to have been run).
#>

[CmdletBinding()]
param(
  [string]$Ip   = "127.0.0.1",
  [int]   $Port = 8787,
  [switch]$Remote
)

$ErrorActionPreference = "Stop"

# ---------- Locate project root (folder that contains this script) ----------
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot
Write-Host ("==> Project root: " + $ProjectRoot) -ForegroundColor Cyan

# ---------- Helpers ----------
function Test-CommandExists([string]$Name) {
  return [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

# ---------- Pre-flight: Node.js ----------
if (-not (Test-CommandExists "node")) {
  Write-Host "[X] Node.js not found on PATH." -ForegroundColor Red
  Write-Host "    Install Node.js 18+ from https://nodejs.org/ and re-run." -ForegroundColor DarkGray
  exit 1
}
$nodeVer = & node -v
Write-Host ("    Node.js version: " + $nodeVer) -ForegroundColor Gray

# ---------- Pre-flight: .dev.vars ----------
$devVarsPath = Join-Path $ProjectRoot ".dev.vars"
if (-not (Test-Path -LiteralPath $devVarsPath)) {
  Write-Host "[!] .dev.vars missing. env.NVIDIA_API_KEY will be empty; /api/chat returns 500." -ForegroundColor Yellow
  Write-Host "    Create .dev.vars with one line: NVIDIA_API_KEY=nvapi-..." -ForegroundColor DarkGray
} else {
  Write-Host "    Found .dev.vars" -ForegroundColor Gray
}

# ---------- Pre-flight: wrangler.toml ----------
$wranglerToml = Join-Path $ProjectRoot "wrangler.toml"
if (-not (Test-Path -LiteralPath $wranglerToml)) {
  Write-Host "[X] wrangler.toml missing. Run this script from the project root." -ForegroundColor Red
  exit 1
}

# ---------- Project-local Wrangler home (no %AppData% writes) ----------
$wranglerHome     = Join-Path $ProjectRoot ".wrangler-home"
$wranglerRegistry = Join-Path $wranglerHome ".wrangler" | Join-Path -ChildPath "registry"
New-Item -ItemType Directory -Force -Path $wranglerRegistry | Out-Null

$env:WRANGLER_HOME   = $wranglerHome
$env:XDG_CONFIG_HOME = $wranglerHome
Write-Host ("    WRANGLER_HOME -> " + $wranglerHome) -ForegroundColor Gray

# ---------- Build wrangler dev argument list ----------
[string[]]$wranglerArgs = @("wrangler", "dev")
if (-not $Remote) {
  $wranglerArgs += "--local"
}
$wranglerArgs += "--ip"
$wranglerArgs += $Ip
$wranglerArgs += "--port"
$wranglerArgs += $Port.ToString()

# ---------- Pretty access URL ----------
if ($Ip -eq "0.0.0.0" -or $Ip -eq "::") {
  $accessUrl = "http://127.0.0.1:" + $Port.ToString()
} else {
  $accessUrl = "http://" + $Ip + ":" + $Port.ToString()
}

Write-Host ""
Write-Host ("==> Running: npx " + ($wranglerArgs -join ' ')) -ForegroundColor Cyan
Write-Host ("==> Open " + $accessUrl + " once server is ready") -ForegroundColor Green
Write-Host "    Press Ctrl+C to stop" -ForegroundColor DarkGray
Write-Host ""

# ---------- Execute (blocks until Ctrl+C) ----------
& npx @wranglerArgs
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
  Write-Host ""
  Write-Host ("[X] wrangler dev exited with code " + $exitCode) -ForegroundColor Red
  exit $exitCode
}
