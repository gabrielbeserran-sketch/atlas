param([string]$DeviceId = "")
. "$PSScriptRoot\atlas_android_common.ps1"
$root = Get-AtlasRoot
if ([string]::IsNullOrWhiteSpace($DeviceId)) {
    $DeviceId = Get-AtlasAuthorizedAndroidDeviceId
}

$checks = @(
    "O ícone Beserra/Atlas aparece corretamente",
    "O splash Beserra aparece e o app abre",
    "Login funciona pela API HTTPS pública sem USB",
    "Empresa e fazenda carregam",
    "Rebanho e Central do Animal abrem",
    "Agenda Lista/Semana/Mês abre",
    "Galeria Android seleciona e envia foto",
    "Câmera tira e envia foto",
    "Seletor Android escolhe documento",
    "Documento baixado abre por aplicativo compatível",
    "Sessão válida permanece após fechar/reabrir",
    "Falha de internet é tratada sem crash",
    "O AAB foi enviado à faixa interna/fechada Google Play",
    "A versão da faixa Play foi instalada em um Android"
)

$failed = @()
foreach ($check in $checks) {
    $answer = Read-Host "$check? (s/n)"
    if ($answer.Trim().ToLowerInvariant() -ne "s") { $failed += $check }
}

$dist = "$root\dist\android"
New-Item -ItemType Directory -Force -Path $dist | Out-Null
[ordered]@{
    deviceId = $DeviceId
    packageId = "br.com.projetoatlas.app"
    testedAt = (Get-Date).ToString("o")
    passed = ($failed.Count -eq 0)
    failedChecks = $failed
} | ConvertTo-Json -Depth 5 |
    Set-Content "$dist\marco6-device-smoke.json" -Encoding UTF8

if ($failed.Count -gt 0) {
    Write-Host "ATLAS MARCO 6 DEVICE SMOKE: REPROVADO" -ForegroundColor Red
    exit 1
}
Write-Host "ATLAS MARCO 6 DEVICE SMOKE: APROVADO" -ForegroundColor Green
