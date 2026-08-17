$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Python = Join-Path $ProjectRoot "backend\.venv\Scripts\python.exe"
$Marco5DGate = Join-Path $PSScriptRoot "run_marco5d_gate.ps1"

Set-Location $ProjectRoot

Write-Host "=== ATLAS MARCO 5 - GATE FINAL ===" -ForegroundColor Cyan

Write-Host "[1/5] Revalidando Marcos 5A-5D..." -ForegroundColor Yellow
& $Marco5DGate

if (-not (Test-Path $Python)) {
    throw "Python da .venv não encontrado: $Python."
}

Write-Host "[2/5] Contrato final 5E/5F/5G..." -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco5_final_contract.py
if ($LASTEXITCODE -ne 0) {
    throw "Contrato final do Marco 5 falhou com código $LASTEXITCODE."
}

Write-Host "[3/5] Testes específicos de concorrência/backup..." -ForegroundColor Yellow
Set-Location (Join-Path $ProjectRoot "backend")
& $Python -m pytest -q tests\test_marco5_final_production.py
if ($LASTEXITCODE -ne 0) {
    throw "Testes finais do Marco 5 falharam com código $LASTEXITCODE."
}

Set-Location $ProjectRoot
Write-Host "[4/5] Inventário final de prontidão..." -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco5a_production_readiness.py
if ($LASTEXITCODE -ne 0) {
    throw "Inventário final de produção falhou com código $LASTEXITCODE."
}

$Readiness = Get-Content -Raw -Encoding UTF8 `
    (Join-Path $ProjectRoot "ATLAS_MARCO5A_PRODUCTION_READINESS.json") |
    ConvertFrom-Json

if ($Readiness.blocker_count -ne 0) {
    throw "Marco 5 não pode fechar: ainda existem $($Readiness.blocker_count) bloqueadores."
}

Write-Host "[5/5] Marco 5 sem bloqueadores técnicos..." -ForegroundColor Yellow
Write-Host ""
Write-Host "ATLAS MARCO 5: CONCLUIDO" -ForegroundColor Green
Write-Host (
    "Qualidade e segurança de produção homologadas. " +
    "O único débito funcional explicitamente adiado é ATT-003, pertencente ao Marco 6/Android."
) -ForegroundColor Green
