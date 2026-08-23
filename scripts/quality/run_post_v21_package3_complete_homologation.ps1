param(
    [string]$BaseUrl = "https://atlas-api-29y2.onrender.com/api/v1",
    [switch]$SkipProductionSmoke
)

$ErrorActionPreference = "Stop"

function Assert-AtlasBaseUrl {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "BaseUrl vazia."
    }
    if ($Value.Trim().StartsWith("-")) {
        throw "BaseUrl inválida: '$Value'."
    }

    try {
        $Uri = [System.Uri]$Value
    } catch {
        throw "BaseUrl inválida: '$Value'."
    }

    if (-not $Uri.IsAbsoluteUri -or $Uri.Scheme -notin @("http", "https")) {
        throw "BaseUrl precisa ser HTTP/HTTPS absoluta."
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
if (-not $Python) { throw "Python não encontrado." }

Write-Host "=== ATLAS POS-V21 - PACOTE 3 COMPLETO ===" -ForegroundColor Cyan
Write-Host "[1/2] Campo, Estoque, Financeiro, Inteligência e Relatórios" -ForegroundColor Yellow

& $Python.Source tools\atlas_post_v21_package3_complete_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate do Pacote 3 completo falhou." }

& $Python.Source tools\atlas_powershell_parameter_forwarding_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate PowerShell falhou." }

Write-Host "[2/2] Reexecutando Pacote 3A-C + toda homologação anterior" -ForegroundColor Yellow

$Package3Parameters = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $Package3Parameters["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_post_v21_package3_homologation.ps1" @Package3Parameters
if ($LASTEXITCODE -ne 0) { throw "Homologação integrada do Pacote 3 completo falhou." }

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 3 COMPLETO: GATES APROVADOS" -ForegroundColor Green
