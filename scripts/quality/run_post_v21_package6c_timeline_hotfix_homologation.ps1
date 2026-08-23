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

    return $Value.Trim().TrimEnd("/")
}

$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

$Python = Get-Command python -ErrorAction SilentlyContinue
if (-not $Python) { $Python = Get-Command py -ErrorAction SilentlyContinue }
if (-not $Python) { throw "Python não encontrado." }

Write-Host "=== ATLAS POS-V21 - HOTFIX TIMELINE 6C ===" -ForegroundColor Cyan
Write-Host "[1/2] Contrato de produção da Timeline" -ForegroundColor Yellow

& $Python.Source tools\atlas_post_v21_package6c_timeline_contract_gate.py
if ($LASTEXITCODE -ne 0) {
    throw "Gate preventivo da Timeline falhou."
}

Write-Host "[2/2] Pacote 6B + toda homologação anterior" -ForegroundColor Yellow

$Package6BParameters = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $Package6BParameters["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_post_v21_package6b_information_architecture_homologation.ps1" @Package6BParameters
if ($LASTEXITCODE -ne 0) {
    throw "Homologação integrada do hotfix Timeline falhou."
}

Write-Host ""
Write-Host "ATLAS POS-V21 HOTFIX TIMELINE 6C: GATES APROVADOS" -ForegroundColor Green
