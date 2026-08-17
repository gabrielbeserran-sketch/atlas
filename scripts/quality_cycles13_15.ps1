$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
Set-Location (Join-Path $Root 'backend')
python scripts/quality/run_cycles13_15_gate.py
Write-Host 'Ciclos 13 a 15 aprovados.' -ForegroundColor Green
