$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10C - HOMOLOGACAO ===" -ForegroundColor Cyan

python .\tools\atlas_post_v21_macro10c_traceability_data_ux_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate 10C reprovado." }

$pythonFiles = @(
  'backend/alembic/versions/20260825_0050_data_quality_utf8_traceability.py',
  'backend/app/routers/livestock.py',
  'tools/atlas_post_v21_macro10c_traceability_data_ux_gate.py',
  'scripts/quality/atlas_predictive_risk_audit.py'
)
foreach ($file in $pythonFiles) {
  python -c "from pathlib import Path; compile(Path(r'$file').read_text(encoding='utf-8'), r'$file', 'exec')"
  if ($LASTEXITCODE -ne 0) { throw "Sintaxe Python reprovada: $file" }
}

$tests = @(
  'test/features/consultancy_client/post_v21_package9c_onboarding_contract_test.dart',
  'test/features/consultancy_client/post_v21_package9d_verified_onboarding_contract_test.dart',
  'test/features/consultancy_client/post_v21_package9e_farm_scoped_onboarding_contract_test.dart',
  'test/features/consultancy_client/post_v21_package9f_consultancy_action_plan_contract_test.dart',
  'test/features/consultancy_client/post_v21_package9g_execution_evidence_contract_test.dart',
  'test/features/consultancy_client/post_v21_macro10a_measurable_outcomes_contract_test.dart',
  'test/features/dashboard/post_v21_macro10b_intelligence_integrity_contract_test.dart',
  'test/features/animal/post_v21_macro10c_traceability_utf8_contract_test.dart'
)
foreach ($test in $tests) {
  flutter test $test
  if ($LASTEXITCODE -ne 0) { throw "Contrato reprovado: $test" }
}

python .\scripts\quality\atlas_full_project_audit.py
if ($LASTEXITCODE -ne 0) { throw "Auditoria global do projeto reprovada." }

python .\scripts\quality\atlas_predictive_risk_audit.py --no-write
if ($LASTEXITCODE -ne 0) { throw "Auditoria preventiva da baseline 10C reprovada." }

git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check reprovado." }

Write-Host "ATLAS POS-V21 MACROPACOTE 10C: GATES APROVADOS" -ForegroundColor Green
Write-Host "Migration: 0049 -> 0050" -ForegroundColor Green
Write-Host "Alembic producao: automatico no Render" -ForegroundColor Green
