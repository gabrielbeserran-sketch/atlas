$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

Set-Location (Join-Path $Root "backend")
if (Test-Path ".\.venv\Scripts\Activate.ps1") {
    . .\.venv\Scripts\Activate.ps1
}
$env:ATLAS_ENV = "test"
$env:ATLAS_DATABASE_URL = "sqlite:///./atlas_quality.db"
$env:ATLAS_JWT_SECRET = "quality-gate-secret-with-at-least-32-characters"
python scripts/quality/run_quality_gate.py

Set-Location $Root
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
Write-Host "Qualidade completa aprovada." -ForegroundColor Green
