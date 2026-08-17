$ErrorActionPreference = "Stop"

Write-Host "[1/6] Dependencias Flutter"
flutter pub get

Write-Host "[2/6] Formatacao"
dart format --output=none --set-exit-if-changed lib test

Write-Host "[3/6] Analise Flutter"
flutter analyze

Write-Host "[4/6] Testes Flutter"
flutter test

Write-Host "[5/6] Gate backend"
Push-Location backend
python scripts\quality\check_route_declarations.py
python scripts\quality\check_duplicate_tablenames.py
python scripts\quality\check_consolidated_architecture.py
python scripts\quality\check_openapi.py
python -m pytest -q
Pop-Location

Write-Host "[6/6] Ciclo 1 aprovado"
