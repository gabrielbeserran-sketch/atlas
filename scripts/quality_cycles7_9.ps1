$ErrorActionPreference = "Stop"

flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

Push-Location backend
try {
    python scripts\quality\check_route_declarations.py
    python scripts\quality\check_duplicate_tablenames.py
    python scripts\quality\check_consolidated_architecture.py
    python scripts\quality\check_openapi.py
    python -m pytest -q
}
finally {
    Pop-Location
}
