param(
    [ValidateSet("debug", "release")][string]$Mode = "release",
    [string]$ApiUrl = ""
)
. "$PSScriptRoot\atlas_android_common.ps1"
$root = Get-AtlasRoot
Assert-Command flutter
if ([string]::IsNullOrWhiteSpace($ApiUrl)) { $ApiUrl = Get-AtlasApiUrl }
$ApiUrl = $ApiUrl.TrimEnd('/')
Write-Host "APK será configurado para API: $ApiUrl" -ForegroundColor Cyan
Set-Location $root
flutter clean
if ($LASTEXITCODE -ne 0) { throw "flutter clean falhou." }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get falhou." }
if ($Mode -eq "debug") {
    flutter build apk --debug --dart-define=ATLAS_ENV=development --dart-define="ATLAS_API_BASE_URL=$ApiUrl"
    $apk = "$root\build\app\outputs\flutter-apk\app-debug.apk"
} else {
    flutter build apk --release --dart-define=ATLAS_ENV=development --dart-define="ATLAS_API_BASE_URL=$ApiUrl"
    $apk = "$root\build\app\outputs\flutter-apk\app-release.apk"
}
if ($LASTEXITCODE -ne 0) { throw "Build Android falhou." }
if (-not (Test-Path $apk)) { throw "APK não encontrado em $apk" }
$dist = "$root\dist\android"
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$target = "$dist\atlas-android-1.0.0-$Mode.apk"
Copy-Item $apk $target -Force
$hash = Get-FileHash $target -Algorithm SHA256
Write-Host "APK criado: $target" -ForegroundColor Green
Write-Host "SHA256: $($hash.Hash)" -ForegroundColor Green
Write-Host "PASSOS 16-17 OK: APK gerado." -ForegroundColor Green
