$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 PACOTE 9G - PREFLIGHT ===" -ForegroundColor Cyan
python ".\tools\atlas_post_v21_package9g_execution_evidence_gate.py"
if ($LASTEXITCODE -ne 0) { throw "Gate 9G reprovado." }
git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check encontrou inconsistencias." }
Write-Host "ATLAS 9G RELEASE PREFLIGHT: APROVADO" -ForegroundColor Green
