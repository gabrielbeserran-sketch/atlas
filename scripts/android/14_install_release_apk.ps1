param([string]$DeviceId = "")
. "$PSScriptRoot\atlas_android_common.ps1"
$root = Get-AtlasRoot
$adb = Get-AtlasAdbPath
if ([string]::IsNullOrWhiteSpace($DeviceId)) {
    $DeviceId = Get-AtlasAuthorizedAndroidDeviceId
}
$apk = "$root\dist\android\atlas-1.0.0+6-release.apk"
if (-not (Test-Path $apk)) { throw "APK não encontrado." }

& $adb -s $DeviceId install -r $apk
if ($LASTEXITCODE -ne 0) { throw "Instalação ADB falhou." }

$packagePath = & $adb -s $DeviceId shell pm path br.com.projetoatlas.app
if (-not ($packagePath -match "package:")) {
    throw "Pacote br.com.projetoatlas.app não encontrado."
}
Write-Host "ATLAS RELEASE APK INSTALADO: APROVADO" -ForegroundColor Green
