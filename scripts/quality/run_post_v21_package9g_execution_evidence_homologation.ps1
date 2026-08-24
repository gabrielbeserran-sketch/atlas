$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 PACOTE 9G - HOMOLOGACAO ===" -ForegroundColor Cyan
$releaseScripts = @(
  ".\scripts\quality\run_post_v21_package9g_execution_evidence_homologation.ps1",
  ".\scripts\quality\run_post_v21_package9g_release_preflight.ps1",
  ".\scripts\quality\stage_post_v21_package9g_release.ps1",
  ".\scripts\quality\check_post_v21_package9g_staged_release.ps1",
  ".\scripts\quality\check_post_v21_package9g_execution_evidence_deployed.ps1"
)
foreach ($script in $releaseScripts) {
  $tokens=$null; $errors=$null
  [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $script), [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) { throw "Sintaxe PowerShell invalida em $script : $($errors[0].Message)" }
}
python ".\tools\atlas_post_v21_package9g_execution_evidence_gate.py"
if ($LASTEXITCODE -ne 0) { throw "Gate estrutural 9G reprovado." }
@'
from pathlib import Path
for name in [
 Path('backend/app/business_models.py'),
 Path('backend/app/routers/business.py'),
 Path('backend/app/routers/operations.py'),
 Path('backend/alembic/versions/20260824_0048_consultancy_execution_evidence.py'),
]:
 compile(name.read_text(encoding='utf-8-sig'), str(name), 'exec')
print('[OK] Sintaxe Python validada sem gerar cache.')
'@ | python -
if ($LASTEXITCODE -ne 0) { throw "Sintaxe Python 9G reprovada." }
foreach ($test in @(
 ".\test\features\consultancy_client\post_v21_package9c_onboarding_contract_test.dart",
 ".\test\features\consultancy_client\post_v21_package9d_verified_onboarding_contract_test.dart",
 ".\test\features\consultancy_client\post_v21_package9e_farm_scoped_onboarding_contract_test.dart",
 ".\test\features\consultancy_client\post_v21_package9f_consultancy_action_plan_contract_test.dart",
 ".\test\features\consultancy_client\post_v21_package9g_execution_evidence_contract_test.dart"
)) {
 flutter test $test
 if ($LASTEXITCODE -ne 0) { throw "Contrato/regressao reprovado: $test" }
}
git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check encontrou inconsistencias." }
Write-Host "ATLAS POS-V21 PACOTE 9G: GATES APROVADOS" -ForegroundColor Green
Write-Host "Migration: 0047 -> 0048" -ForegroundColor Green
Write-Host "Alembic producao: automatico no Render" -ForegroundColor Green
