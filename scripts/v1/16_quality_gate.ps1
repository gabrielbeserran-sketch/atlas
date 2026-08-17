$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $root
Write-Host "ATLAS V1 - PASSO 16 - Gate de qualidade" -ForegroundColor Green
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
Write-Host "PASSO 16 OK: Flutter aprovado." -ForegroundColor Green
if (Test-Path "$root\backend\.venv\Scripts\python.exe") {
  Push-Location "$root\backend"
  & ".\.venv\Scripts\python.exe" -m pytest -q
  Pop-Location
  Write-Host "Backend pytest aprovado." -ForegroundColor Green
} else {
  Write-Warning "Backend .venv não encontrado; pytest não foi executado."
}
