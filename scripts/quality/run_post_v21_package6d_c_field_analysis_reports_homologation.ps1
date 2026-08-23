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

Write-Host "=== ATLAS POS-V21 - PACOTE 6D-C ===" -ForegroundColor Cyan

& $Python.Source tools\atlas_post_v21_package6d_c_field_analysis_reports_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate 6D-C falhou." }

$Previous = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $Previous["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_post_v21_package6d_b_management_centers_homologation.ps1" @Previous
if ($LASTEXITCODE -ne 0) { throw "Homologação integrada 6D-C falhou." }

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 6D-C: GATES APROVADOS" -ForegroundColor Green
