$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))

Write-Host "=== ATLAS POS-V21 PACOTE 6B ===" -ForegroundColor Cyan
Write-Host "[1/3] Gate de arquitetura de informacao" -ForegroundColor Yellow
python .\tools\atlas_post_v21_package6b_information_architecture_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate 6B falhou com codigo $LASTEXITCODE." }

Write-Host "[2/3] Analise estatica Flutter" -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) { throw "flutter analyze falhou com codigo $LASTEXITCODE." }

Write-Host "[3/3] Testes Flutter" -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) { throw "flutter test falhou com codigo $LASTEXITCODE." }

Write-Host "ATLAS POS-V21 PACOTE 6B: GATES APROVADOS" -ForegroundColor Green
