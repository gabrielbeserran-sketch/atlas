$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))

Write-Host "=== ATLAS POS-V21 PACOTE 9E - PREFLIGHT ===" -ForegroundColor Cyan
python ".\tools\atlas_post_v21_package9e_farm_scoped_onboarding_gate.py"
if ($LASTEXITCODE -ne 0) { throw "Gate 9E reprovado." }

git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check encontrou inconsistencias." }

$migration = ".\backend\alembic\versions\20260824_0046_onboarding_progress_farm_scope.py"
if (-not (Test-Path $migration -PathType Leaf)) { throw "Migration 0046 ausente." }
$content = Get-Content -Raw -Encoding UTF8 $migration
if ($content -notmatch 'revision\s*=\s*"20260824_0046"' -or $content -notmatch 'down_revision\s*=\s*"20260824_0045"') {
    throw "Encadeamento Alembic 0045 -> 0046 invalido."
}

$staged = @(git diff --cached --name-only)
if ($staged.Count -gt 0) { throw "Ja existem arquivos no staging. Conclua/limpe o staging anterior antes do 9E." }

Write-Host "[OK] Gate 9E aprovado." -ForegroundColor Green
Write-Host "[OK] Migration 0046 encadeada em 0045." -ForegroundColor Green
Write-Host "ATLAS 9E RELEASE PREFLIGHT: APROVADO" -ForegroundColor Green
