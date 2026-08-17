$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Python = Join-Path $ProjectRoot "backend\.venv\Scripts\python.exe"
$Marco5CGate = Join-Path $PSScriptRoot "run_marco5c_gate.ps1"

Set-Location $ProjectRoot

Write-Host "=== ATLAS MARCO 5D GATE ===" -ForegroundColor Cyan

Write-Host "[1/4] Revalidando Marco 5C + baseline..." -ForegroundColor Yellow
& $Marco5CGate

if (-not (Test-Path $Python)) {
    throw "Python da .venv não encontrado: $Python."
}

Write-Host "[2/4] Contrato de Fotos/Documentos remotos..." -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco5d_media_contract.py
if ($LASTEXITCODE -ne 0) {
    throw "Contrato do Marco 5D falhou com código $LASTEXITCODE."
}

Write-Host "[3/4] Testes específicos de anexos..." -ForegroundColor Yellow
Set-Location (Join-Path $ProjectRoot "backend")
& $Python -m pytest -q tests\test_marco5d_animal_media.py
if ($LASTEXITCODE -ne 0) {
    throw "Testes específicos do Marco 5D falharam com código $LASTEXITCODE."
}

Set-Location $ProjectRoot
Write-Host "[4/4] Inventário de prontidão pós-5D..." -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco5a_production_readiness.py
if ($LASTEXITCODE -ne 0) {
    throw "Inventário de produção pós-5D falhou com código $LASTEXITCODE."
}

Write-Host ""
Write-Host "ATLAS MARCO 5D: APROVADO" -ForegroundColor Green
Write-Host (
    "Fotos e Documentos possuem autoridade remota multi-dispositivo. " +
    "Próximo: 5E transações, concorrência e idempotência."
) -ForegroundColor Green
