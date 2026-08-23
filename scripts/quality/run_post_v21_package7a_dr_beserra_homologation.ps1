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

Write-Host "=== ATLAS POS-V21 - PACOTE 7A DR. BESERRA ===" -ForegroundColor Cyan

& $Python.Source tools\atlas_post_v21_package7a_dr_beserra_safe_commands_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate seguro do Dr. Beserra falhou." }

$Previous = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $Previous["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_post_v21_package6d_d_global_ux_homologation.ps1" @Previous
if ($LASTEXITCODE -ne 0) { throw "Homologação integrada do Pacote 7A falhou." }

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 7A DR. BESERRA: GATES APROVADOS" -ForegroundColor Green
