$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))

Write-Host "=== ATLAS POS-V21 PACOTE 9F - PREFLIGHT DE RELEASE ===" -ForegroundColor Cyan

python ".\tools\atlas_post_v21_package9f_consultancy_action_plan_gate.py"
if ($LASTEXITCODE -ne 0) { throw "Gate estrutural 9F reprovado." }

$migration = ".\backend\alembic\versions\20260824_0047_consultancy_action_idempotency.py"
if (-not (Test-Path $migration)) { throw "Migration 0047 ausente." }
$content = Get-Content $migration -Raw
if ($content -notmatch 'revision = "20260824_0047"' -or $content -notmatch 'down_revision = "20260824_0046"') {
    throw "Encadeamento Alembic 0046 -> 0047 invalido."
}

git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check encontrou inconsistencias." }

Write-Host "ATLAS 9F RELEASE PREFLIGHT: APROVADO" -ForegroundColor Green
Write-Host "Proxima etapa: stage_post_v21_package9f_release.ps1" -ForegroundColor Green
