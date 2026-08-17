$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path "$PSScriptRoot\..")
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
powershell -ExecutionPolicy Bypass -File .\scripts\publication\check_publication.ps1
Set-Location .\backend
python scripts\quality\run_cycles13_15_gate.py
Write-Host 'Ciclos 19 e 20 aprovados.' -ForegroundColor Green
