$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path "$PSScriptRoot\..\..")
flutter pub get
flutter analyze
flutter test
$required = @(
  'docs/publication/ANDROID_RELEASE.md',
  'docs/publication/IOS_RELEASE.md',
  'docs/publication/WEB_RELEASE.md',
  'docs/publication/PRIVACIDADE_TERMOS_SUPORTE.md',
  'docs/strategy/ATLAS_3_ROADMAP_5_ANOS.md'
)
foreach ($item in $required) {
  if (-not (Test-Path $item)) { throw "Contrato ausente: $item" }
}
Write-Host 'Gate de publicação e escala aprovado.' -ForegroundColor Green
