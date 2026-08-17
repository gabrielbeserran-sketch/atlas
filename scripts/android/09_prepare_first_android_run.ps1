param([string]$DeviceId = "")
. "$PSScriptRoot\atlas_android_common.ps1"
Write-Host "ATLAS ANDROID 1.0 - PASSOS 11 A 15" -ForegroundColor Cyan
& "$PSScriptRoot\04_test_backend_from_pc.ps1"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if ([string]::IsNullOrWhiteSpace($DeviceId)) { $DeviceId = Get-AtlasAuthorizedAndroidDeviceId }
$DeviceId = Enable-AtlasUsbBackendReverse -Port 8000 -DeviceId $DeviceId
Write-Host "Android pronto para o primeiro flutter run." -ForegroundColor Green
Write-Host "Execute agora:" -ForegroundColor Yellow
Write-Host "powershell -ExecutionPolicy Bypass -File .\scripts\android\05_run_on_android.ps1 -DeviceId $DeviceId"
