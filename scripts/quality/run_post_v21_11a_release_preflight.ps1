$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS 11A - RELEASE PREFLIGHT ===" -ForegroundColor Cyan
python .\tools\atlas_11a_architecture_governance_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate 11A reprovado." }
git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check reprovado." }
Write-Host "ATLAS 11A RELEASE PREFLIGHT: APROVADO" -ForegroundColor Green
