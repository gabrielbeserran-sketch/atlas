param(
    [string]$DeviceId = "",
    [switch]$UseLan
)
. "$PSScriptRoot\atlas_android_common.ps1"
$root = Get-AtlasRoot
Assert-Command flutter
if ([string]::IsNullOrWhiteSpace($DeviceId)) {
    $DeviceId = Get-AtlasAuthorizedAndroidDeviceId
}
if ($UseLan) {
    $api = Get-AtlasApiUrl
    Write-Host "Modo LAN selecionado: $api" -ForegroundColor Cyan
} else {
    $DeviceId = Enable-AtlasUsbBackendReverse -Port 8000 -DeviceId $DeviceId
    $api = "http://127.0.0.1:8000/api/v1"
    Write-Host "Modo USB selecionado. Não depende do Wi-Fi nem do firewall para o primeiro teste." -ForegroundColor Cyan
}
Set-Location $root
Write-Host "Executando Atlas no Android $DeviceId com API: $api" -ForegroundColor Cyan
& flutter run -d $DeviceId `
    --dart-define=ATLAS_ENV=development `
    --dart-define="ATLAS_API_BASE_URL=$api"
if ($LASTEXITCODE -ne 0) { throw "flutter run terminou com erro." }
