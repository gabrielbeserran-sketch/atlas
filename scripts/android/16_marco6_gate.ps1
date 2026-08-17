param(
    [Parameter(Mandatory=$true)]
    [string]$ApiUrl,
    [string]$DeviceId = ""
)
. "$PSScriptRoot\atlas_android_common.ps1"

Write-Host "=== ATLAS MARCO 6 - GATE FINAL ===" -ForegroundColor Cyan

& "$PSScriptRoot\01_validate_project.ps1"
if ($LASTEXITCODE -ne 0) { throw "Validação do projeto falhou." }

& "$PSScriptRoot\10_validate_public_api.ps1" -ApiUrl $ApiUrl
if ($LASTEXITCODE -ne 0) { throw "API pública falhou." }

$root = Get-AtlasRoot
if (-not (Test-Path "$root\android\key.properties")) {
    throw "Keystore ausente. Execute 11_generate_upload_keystore.ps1."
}

& "$PSScriptRoot\12_build_release_aab.ps1" -ApiUrl $ApiUrl
if ($LASTEXITCODE -ne 0) { throw "AAB falhou." }

& "$PSScriptRoot\13_build_release_apk.ps1" -ApiUrl $ApiUrl
if ($LASTEXITCODE -ne 0) { throw "APK falhou." }

& "$PSScriptRoot\14_install_release_apk.ps1" -DeviceId $DeviceId
if ($LASTEXITCODE -ne 0) { throw "Instalação física falhou." }

& "$PSScriptRoot\15_android_v1_smoke_test.ps1" -DeviceId $DeviceId
if ($LASTEXITCODE -ne 0) { throw "Smoke físico/Play falhou." }

Write-Host "ATLAS MARCO 6: CONCLUIDO" -ForegroundColor Green
