. "$PSScriptRoot\atlas_android_common.ps1"

Assert-Command flutter
$adb = Initialize-AtlasAdb

Write-Host "Dispositivos ADB:" -ForegroundColor Cyan
& $adb devices -l
if ($LASTEXITCODE -ne 0) {
    throw "O ADB foi encontrado, mas falhou ao consultar os dispositivos."
}

Write-Host "Dispositivos Flutter:" -ForegroundColor Cyan
flutter devices
if ($LASTEXITCODE -ne 0) {
    throw "Flutter não conseguiu consultar os dispositivos."
}

$deviceOutput = & $adb devices
$authorizedDevices = $deviceOutput |
    Select-String "\sdevice$" |
    Where-Object { $_.Line -notmatch '^List of devices' }

if (-not $authorizedDevices) {
    $unauthorizedDevices = $deviceOutput | Select-String "\sunauthorized$"
    if ($unauthorizedDevices) {
        throw "O celular foi encontrado, mas ainda não foi autorizado. Desbloqueie o Android e aceite a chave RSA de Depuração USB."
    }

    throw "Nenhum Android autorizado foi encontrado. Ative Depuração USB, conecte um cabo de dados e aceite a chave RSA no celular."
}

Write-Host "PASSOS 6-10 OK: Android reconhecido e autorizado." -ForegroundColor Green
