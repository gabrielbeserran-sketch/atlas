param(
  [Parameter(Mandatory=$true)]
  [string]$ApiBaseUrl
)
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $root
if (-not $ApiBaseUrl.StartsWith("https://")) {
  throw "Build de produção exige ATLAS_API_BASE_URL com HTTPS."
}
Write-Host "ATLAS V1 - PASSO 19 - APK/AAB release" -ForegroundColor Green
if (-not (Test-Path "android\key.properties")) {
  throw "android\key.properties ausente. Configure a chave de assinatura release antes da build de produção."
}
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define="ATLAS_API_BASE_URL=$ApiBaseUrl"
flutter build appbundle --release --dart-define="ATLAS_API_BASE_URL=$ApiBaseUrl"
New-Item -ItemType Directory -Force "dist\android" | Out-Null
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "dist\android\atlas-v1-release.apk" -Force
Copy-Item "build\app\outputs\bundle\release\app-release.aab" "dist\android\atlas-v1-release.aab" -Force
Write-Host "Artefatos em dist\android" -ForegroundColor Green
Write-Warning "Antes da Play Store, configure uma chave de assinatura de release; debug signing não é aceitável para publicação."
