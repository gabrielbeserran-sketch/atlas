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

Write-Host "=== ATLAS POS-V21 - PACOTE 7C LINGUAGEM RURAL ===" -ForegroundColor Cyan

& $Python.Source tools\atlas_dart_deprecation_regression_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate preventivo de deprecações falhou." }

& $Python.Source tools\atlas_post_v21_package7c_rural_language_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate de linguagem rural falhou." }

& $Python.Source tools\atlas_post_v21_package7c_intent_collision_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate de colisão de intenções falhou." }

$Previous = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $Previous["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_post_v21_package7b_dr_beserra_voice_homologation.ps1" @Previous
if ($LASTEXITCODE -ne 0) { throw "Homologação integrada do Pacote 7C falhou." }

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 7C: GATES APROVADOS" -ForegroundColor Green
