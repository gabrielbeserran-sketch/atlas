$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Preflight = Join-Path $ProjectRoot "scripts\dev\preflight_project.ps1"
$CoreGate = Join-Path $PSScriptRoot "run_full_quality_gate_core.ps1"

Set-Location $ProjectRoot

Write-Host "=== ATLAS FULL QUALITY GATE ===" -ForegroundColor Cyan
Write-Host "[PRE] Executando preflight obrigatório..." -ForegroundColor Yellow

if (-not (Test-Path $Preflight)) {
    throw "Preflight ausente em $Preflight."
}
if (-not (Test-Path $CoreGate)) {
    throw "Quality Gate core ausente em $CoreGate."
}

& $Preflight
& $CoreGate
