param(
    [string]$BaseUrl = "https://atlas-api-29y2.onrender.com/api/v1",
    [switch]$SkipProductionSmoke
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

$Python = Get-Command python -ErrorAction SilentlyContinue
if (-not $Python) { $Python = Get-Command py -ErrorAction SilentlyContinue }
if (-not $Python) { throw "Python não encontrado." }

Write-Host "=== ATLAS POS-V21 - PACOTE 6D-D UX GLOBAL ===" -ForegroundColor Cyan
Write-Host "[1/2] Auditoria transversal de UX e navegação" -ForegroundColor Yellow

& $Python.Source tools\atlas_post_v21_package6d_d_global_ux_gate.py
if ($LASTEXITCODE -ne 0) {
    throw "Gate global de UX 6D-D falhou."
}

Write-Host "[2/2] Reexecutando 6D-C e toda homologação anterior" -ForegroundColor Yellow

$Previous = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $Previous["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_post_v21_package6d_c_field_analysis_reports_homologation.ps1" @Previous
if ($LASTEXITCODE -ne 0) {
    throw "Homologação integrada 6D-D falhou."
}

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 6D-D: GATES APROVADOS" -ForegroundColor Green
