$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))

Write-Host "=== ATLAS POS-V21 PACOTE 9D - PREFLIGHT ===" -ForegroundColor Cyan
python ".\tools\atlas_post_v21_package9d_verified_onboarding_gate.py"
if ($LASTEXITCODE -ne 0) { throw "Gate 9D reprovado." }

git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check encontrou inconsistencias." }

$staged = @(git diff --cached --name-only)
if ($staged.Count -gt 0) { throw "Ja existem arquivos no staging. Limpe/conclua o staging anterior antes do 9D." }

Write-Host "ATLAS 9D RELEASE PREFLIGHT: APROVADO" -ForegroundColor Green
