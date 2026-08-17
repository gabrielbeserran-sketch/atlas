$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Python = Join-Path $ProjectRoot "backend\.venv\Scripts\python.exe"
$Marco5BGate = Join-Path $PSScriptRoot "run_marco5b_gate.ps1"

Set-Location $ProjectRoot

Write-Host "=== ATLAS MARCO 5C GATE ===" -ForegroundColor Cyan
Write-Host "[1/4] Revalidando Marco 5B + baseline..." -ForegroundColor Yellow
& $Marco5BGate

if (-not (Test-Path $Python)) { throw "Python da .venv não encontrado: $Python." }

Write-Host "[2/4] Contrato de identidade/sessões 5C..." -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco5c_identity_contract.py
if ($LASTEXITCODE -ne 0) { throw "Contrato do Marco 5C falhou com código $LASTEXITCODE." }

Write-Host "[3/4] Testes específicos de identidade 5C..." -ForegroundColor Yellow
Set-Location (Join-Path $ProjectRoot "backend")
& $Python -m pytest -q tests\test_marco5c_identity_isolation.py
if ($LASTEXITCODE -ne 0) { throw "Testes específicos do Marco 5C falharam com código $LASTEXITCODE." }

Set-Location $ProjectRoot
Write-Host "[4/4] Rechecando contrato 5B após evolução de identidade..." -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco5b_security_contract.py
if ($LASTEXITCODE -ne 0) { throw "Regressão no contrato 5B detectada com código $LASTEXITCODE." }

Write-Host ""
Write-Host "ATLAS MARCO 5C: APROVADO" -ForegroundColor Green
Write-Host "Sessões vinculadas ao JWT, revogação imediata e MFA criptografado." -ForegroundColor Green
