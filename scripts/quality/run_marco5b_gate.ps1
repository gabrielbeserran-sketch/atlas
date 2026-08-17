$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Python = Join-Path $ProjectRoot "backend\.venv\Scripts\python.exe"
$FullGate = Join-Path $PSScriptRoot "run_full_quality_gate.ps1"
$Marco5AGate = Join-Path $PSScriptRoot "run_marco5a_gate.ps1"

Set-Location $ProjectRoot

Write-Host "=== ATLAS MARCO 5B GATE ===" -ForegroundColor Cyan

Write-Host "[1/4] Revalidando Marco 5A + baseline..." -ForegroundColor Yellow
& $Marco5AGate

if (-not (Test-Path $Python)) {
    throw "Python da .venv não encontrado: $Python."
}

Write-Host "[2/4] Contrato de segurança/configuração 5B..." -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco5b_security_contract.py
if ($LASTEXITCODE -ne 0) {
    throw "Contrato do Marco 5B falhou com código $LASTEXITCODE."
}

Write-Host "[3/4] Testes de regressão específicos 5B..." -ForegroundColor Yellow
Set-Location (Join-Path $ProjectRoot "backend")
& $Python -m pytest -q tests\test_marco5b_production_security.py
if ($LASTEXITCODE -ne 0) {
    throw "Testes específicos do Marco 5B falharam com código $LASTEXITCODE."
}

Set-Location $ProjectRoot
Write-Host "[4/4] Reclassificando prontidão de produção..." -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco5a_production_readiness.py
if ($LASTEXITCODE -ne 0) {
    throw "Inventário de produção pós-5B falhou com código $LASTEXITCODE."
}

Write-Host ""
Write-Host "ATLAS MARCO 5B: APROVADO" -ForegroundColor Green
Write-Host (
    "Configuração de produção, secrets, HTTPS/CORS e confiança de proxy " +
    "endurecidos. Próximo: 5C autenticação/isolamento."
) -ForegroundColor Green
