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

Write-Host "=== ATLAS POS-V21 - PACOTE 6A ===" -ForegroundColor Cyan
Write-Host "[1/2] Navegação + arquitetura de informação + Central do Animal" -ForegroundColor Yellow

& $Python.Source tools\atlas_post_v21_package6a_navigation_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate de navegação do Pacote 6A falhou." }

& $Python.Source tools\atlas_powershell_parameter_forwarding_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate PowerShell falhou." }

Write-Host "[2/2] Reexecutando Pacote 5 + toda homologação anterior" -ForegroundColor Yellow

$Package5Parameters = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $Package5Parameters["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_post_v21_package5_homologation.ps1" @Package5Parameters
if ($LASTEXITCODE -ne 0) { throw "Homologação integrada do Pacote 6A falhou." }

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 6A: GATES APROVADOS" -ForegroundColor Green
Write-Host "Pacote 5 continua contendo a migration 20260822_0042 ainda pendente de deploy em produção." -ForegroundColor Cyan
