$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

Set-Location (Join-Path $Root "backend")
python scripts\quality\check_route_declarations.py
python scripts\quality\check_duplicate_tablenames.py
python scripts\quality\check_consolidated_architecture.py
python scripts\quality\check_openapi.py
python -m pytest -q
