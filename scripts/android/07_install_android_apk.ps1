param(
    [ValidateSet("debug", "release")][string]$Mode = "release",
    [string]$DeviceId = ""
)
. "$PSScriptRoot\atlas_android_common.ps1"
$root = Get-AtlasRoot
$adb = Initialize-AtlasAdb
if ([string]::IsNullOrWhiteSpace($DeviceId)) { $DeviceId = Get-AtlasAuthorizedAndroidDeviceId }
$apk = Join-Path $root "dist\android\atlas-android-1.0.0-$Mode.apk"
if (-not (Test-Path $apk)) { throw "APK não encontrado em '$apk'. Execute 06_build_android_apk.ps1 primeiro." }
Write-Host "Instalando $apk em $DeviceId" -ForegroundColor Cyan
& $adb -s $DeviceId install -r $apk
if ($LASTEXITCODE -ne 0) { throw "Falha ao instalar o APK." }
Write-Host "PASSO 18 OK: Atlas instalado no Android." -ForegroundColor Green
