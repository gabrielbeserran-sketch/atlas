$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10B - HOMOLOGACAO ===" -ForegroundColor Cyan

python .\tools\atlas_post_v21_macro10b_integrity_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate 10B reprovado." }

$py = @(
  'backend/app/routers/livestock.py',
  'tools/atlas_post_v21_macro10b_integrity_gate.py',
  'scripts/quality/atlas_predictive_risk_audit.py'
)
foreach ($f in $py) {
  python -c "from pathlib import Path; compile(Path(r'$f').read_text(encoding='utf-8'), r'$f', 'exec')"
  if ($LASTEXITCODE -ne 0) { throw "Sintaxe Python reprovada: $f" }
}

$tests = @(
  'test/features/consultancy_client/post_v21_package9c_onboarding_contract_test.dart',
  'test/features/consultancy_client/post_v21_package9d_verified_onboarding_contract_test.dart',
  'test/features/consultancy_client/post_v21_package9e_farm_scoped_onboarding_contract_test.dart',
  'test/features/consultancy_client/post_v21_package9f_consultancy_action_plan_contract_test.dart',
  'test/features/consultancy_client/post_v21_package9g_execution_evidence_contract_test.dart',
  'test/features/consultancy_client/post_v21_macro10a_measurable_outcomes_contract_test.dart',
  'test/features/dashboard/post_v21_macro10b_intelligence_integrity_contract_test.dart'
)
foreach ($t in $tests) {
  flutter test $t
  if ($LASTEXITCODE -ne 0) { throw "Contrato reprovado: $t" }
}

python .\scripts\quality\atlas_full_project_audit.py
if ($LASTEXITCODE -ne 0) { throw "Auditoria global do projeto reprovada." }

python .\scripts\quality\atlas_predictive_risk_audit.py --no-write
if ($LASTEXITCODE -ne 0) { throw "Auditoria preventiva da baseline 10B reprovada." }

git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check reprovado." }

Write-Host "ATLAS POS-V21 MACROPACOTE 10B: GATES APROVADOS" -ForegroundColor Green
Write-Host "Migration: nenhuma (baseline permanece 0049)" -ForegroundColor Green
