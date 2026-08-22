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
        throw "BaseUrl inválida: '$Value'. Um nome de parâmetro foi recebido como valor."
    }

    try {
        $Uri = [System.Uri]$Value
    } catch {
        throw "BaseUrl inválida: '$Value'."
    }

    if (-not $Uri.IsAbsoluteUri -or $Uri.Scheme -notin @("http", "https")) {
        throw "BaseUrl precisa ser uma URL HTTP/HTTPS absoluta."
    }
    if ([string]::IsNullOrWhiteSpace($Uri.Host)) {
        throw "BaseUrl inválida: host ausente."
    }
    return $Value.Trim().TrimEnd("/")
}

$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

$Python = Get-Command python -ErrorAction SilentlyContinue
if (-not $Python) { $Python = Get-Command py -ErrorAction SilentlyContinue }
if (-not $Python) { throw "Python não encontrado para o gate do Pacote 2." }

Write-Host "=== ATLAS POS-V21 - PACOTE 2 ===" -ForegroundColor Cyan
Write-Host "[1/2] Manejo coletivo + arquitetura do menu" -ForegroundColor Yellow

& $Python.Source tools\atlas_post_v21_package2_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate arquitetural do Pacote 2 falhou." }

& $Python.Source tools\atlas_post_v21_package2_dart_hygiene_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate Dart do Pacote 2 falhou." }

& $Python.Source tools\atlas_post_v21_package2_deploy_check_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate preventivo do check pós-deploy falhou." }

& $Python.Source tools\atlas_powershell_parameter_forwarding_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate de encaminhamento PowerShell falhou." }

Write-Host "[2/2] Reexecutando Pacote 1 + homologação V21" -ForegroundColor Yellow

$Package1Parameters = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $Package1Parameters["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_post_v21_package1_homologation.ps1" @Package1Parameters
if ($LASTEXITCODE -ne 0) { throw "Homologação integrada do Pacote 2 falhou." }

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 2: GATES APROVADOS" -ForegroundColor Green
Write-Host "Após publicar o backend no Render, execute:" -ForegroundColor Cyan
Write-Host "powershell -ExecutionPolicy Bypass -File `".\scripts\quality\check_post_v21_package2_deployed.ps1`""
