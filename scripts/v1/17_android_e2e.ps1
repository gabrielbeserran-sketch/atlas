param(
  [string]$DeviceId = "",
  [string]$ApiBaseUrl = "http://127.0.0.1:8000/api/v1"
)
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $root
Write-Host "ATLAS V1 - PASSO 17 - Teste Android de ponta a ponta" -ForegroundColor Green
if ([string]::IsNullOrWhiteSpace($DeviceId)) {
  flutter devices
  throw "Informe -DeviceId com o identificador do aparelho exibido acima."
}
Write-Host "Executando no dispositivo $DeviceId"
flutter run -d $DeviceId --dart-define="ATLAS_API_BASE_URL=$ApiBaseUrl"
