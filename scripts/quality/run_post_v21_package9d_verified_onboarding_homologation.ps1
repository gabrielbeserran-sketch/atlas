$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))

Write-Host "=== ATLAS POS-V21 PACOTE 9D - HOMOLOGACAO ===" -ForegroundColor Cyan
python ".\tools\atlas_post_v21_package9d_verified_onboarding_gate.py"
if ($LASTEXITCODE -ne 0) { throw "Gate estrutural 9D reprovado." }

$pythonFiles = @(".\backend\app\routers\saas_growth.py")
foreach ($file in $pythonFiles) {
    $source = Get-Content -Raw -Encoding UTF8 $file
    $escaped = $file.Replace("'", "''")
    $source | python -c "import sys; compile(sys.stdin.read(), r'$escaped', 'exec')"
    if ($LASTEXITCODE -ne 0) { throw "Sintaxe Python invalida: $file" }
}

flutter test ".\test\features\consultancy_client\post_v21_package9c_onboarding_contract_test.dart"
if ($LASTEXITCODE -ne 0) { throw "Regressao do contrato Flutter 9C detectada." }

flutter test ".\test\features\consultancy_client\post_v21_package9d_verified_onboarding_contract_test.dart"
if ($LASTEXITCODE -ne 0) { throw "Contrato Flutter 9D reprovado." }

Write-Host "ATLAS POS-V21 PACOTE 9D: GATES APROVADOS" -ForegroundColor Green
Write-Host "Migration: nenhuma (reutiliza onboarding_progress)" -ForegroundColor Green
