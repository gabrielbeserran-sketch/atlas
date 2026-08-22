param(
    [string]$BaseUrl = "https://atlas-api-29y2.onrender.com/api/v1",
    [switch]$SkipProductionSmoke
)

$ErrorActionPreference = "Stop"

function Assert-AtlasBaseUrl {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "BaseUrl vazia. Informe uma URL HTTP/HTTPS absoluta."
    }

    if ($Value.Trim().StartsWith("-")) {
        throw "BaseUrl inválida: '$Value'. Um nome de parâmetro foi recebido como valor. Verifique o encaminhamento de parâmetros do script chamador."
    }

    try {
        $Uri = [System.Uri]$Value
    } catch {
        throw "BaseUrl inválida: '$Value'. Não foi possível interpretar a URL."
    }

    if (-not $Uri.IsAbsoluteUri) {
        throw "BaseUrl inválida: '$Value'. A URL precisa ser absoluta."
    }

    if ($Uri.Scheme -notin @("http", "https")) {
        throw "BaseUrl inválida: '$Value'. Use http ou https."
    }

    if ([string]::IsNullOrWhiteSpace($Uri.Host)) {
        throw "BaseUrl inválida: '$Value'. Host ausente."
    }

    return $Value.Trim().TrimEnd("/")
}

$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

$Python = Get-Command python -ErrorAction SilentlyContinue
if (-not $Python) { $Python = Get-Command py -ErrorAction SilentlyContinue }
if (-not $Python) { throw "Python não encontrado para o gate do Pacote 1." }

Write-Host "=== ATLAS POS-V21 - PACOTE 1 ===" -ForegroundColor Cyan
Write-Host "[1/2] Contrato arquitetural do Pacote 1" -ForegroundColor Yellow
& $Python.Source tools\atlas_post_v21_package1_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate arquitetural do Pacote 1 falhou." }
& $Python.Source tools\atlas_powershell_parameter_forwarding_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate de encaminhamento PowerShell falhou." }

Write-Host "[2/2] Reexecutando homologação completa da baseline" -ForegroundColor Yellow
$V21Parameters = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $V21Parameters["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_v21_ux_homologation.ps1" @V21Parameters
if ($LASTEXITCODE -ne 0) { throw "Homologação integrada falhou." }

Write-Host "" 
Write-Host "ATLAS POS-V21 PACOTE 1: GATES APROVADOS" -ForegroundColor Green
