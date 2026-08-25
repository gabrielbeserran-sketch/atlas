$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
python .\tools\atlas_post_v21_macro10a_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate 10A reprovado." }
git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check reprovado." }
Write-Host "ATLAS 10A RELEASE PREFLIGHT: APROVADO" -ForegroundColor Green
