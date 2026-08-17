param(
    [Parameter(Mandatory=$true)]
    [string]$ApiUrl
)
. "$PSScriptRoot\atlas_android_common.ps1"
$root = Get-AtlasRoot
Set-Location $root

Assert-Command flutter
Assert-Java17
Assert-AndroidApi36
$api = Assert-ProductionApiUrl -ApiUrl $ApiUrl

if (-not (Test-Path "$root\android\key.properties")) {
    throw "key.properties ausente."
}

flutter clean
if ($LASTEXITCODE -ne 0) { throw "flutter clean falhou." }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get falhou." }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw "flutter analyze falhou." }
flutter test
if ($LASTEXITCODE -ne 0) { throw "flutter test falhou." }

flutter build appbundle `
    --release `
    --dart-define=ATLAS_ENV=production `
    --dart-define="ATLAS_API_BASE_URL=$api"
if ($LASTEXITCODE -ne 0) { throw "Build AAB falhou." }

$source = "$root\build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path $source)) { throw "AAB não encontrado." }

$dist = "$root\dist\android"
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$target = "$dist\atlas-1.0.0+6-release.aab"
Copy-Item $source $target -Force

$jarsigner = Get-Command jarsigner -ErrorAction SilentlyContinue
if ($jarsigner) {
    & $jarsigner.Source -verify $target
    if ($LASTEXITCODE -ne 0) { throw "Assinatura do AAB inválida." }
}

$hash = (Get-FileHash $target -Algorithm SHA256).Hash
[ordered]@{
    packageId = "br.com.projetoatlas.app"
    versionName = "1.0.0"
    versionCode = 6
    targetSdk = 36
    apiBaseUrl = $api
    aab = $target
    sha256 = $hash
    builtAt = (Get-Date).ToString("o")
} | ConvertTo-Json -Depth 4 |
    Set-Content "$dist\release-manifest.json" -Encoding UTF8

Write-Host "ATLAS RELEASE AAB: APROVADO" -ForegroundColor Green
Write-Host "SHA256: $hash" -ForegroundColor Green
