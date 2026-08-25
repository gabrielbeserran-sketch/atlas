$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10A - HOMOLOGACAO ===" -ForegroundColor Cyan
python .\tools\atlas_post_v21_macro10a_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate 10A reprovado." }
$py = @('backend/app/business_models.py','backend/app/routers/business.py','backend/app/routers/operations.py','backend/alembic/versions/20260825_0049_consultancy_measurable_outcomes.py')
foreach ($f in $py) { python -c "from pathlib import Path; compile(Path(r'$f').read_text(encoding='utf-8'), r'$f', 'exec')"; if ($LASTEXITCODE -ne 0) { throw "Sintaxe Python reprovada: $f" } }
$tests = @('test/features/consultancy_client/post_v21_package9c_onboarding_contract_test.dart','test/features/consultancy_client/post_v21_package9d_verified_onboarding_contract_test.dart','test/features/consultancy_client/post_v21_package9e_farm_scoped_onboarding_contract_test.dart','test/features/consultancy_client/post_v21_package9f_consultancy_action_plan_contract_test.dart','test/features/consultancy_client/post_v21_package9g_execution_evidence_contract_test.dart','test/features/consultancy_client/post_v21_macro10a_measurable_outcomes_contract_test.dart')
foreach ($t in $tests) { flutter test $t; if ($LASTEXITCODE -ne 0) { throw "Contrato reprovado: $t" } }
git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check reprovado." }
Write-Host "ATLAS POS-V21 MACROPACOTE 10A: GATES APROVADOS" -ForegroundColor Green
Write-Host "Migration: 0048 -> 0049" -ForegroundColor Green
Write-Host "Alembic producao: automatico no Render" -ForegroundColor Green
