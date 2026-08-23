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

Write-Host "=== ATLAS POS-V21 - PACOTE 6C ===" -ForegroundColor Cyan
Write-Host "[1/2] Propriedade dos recursos especializados" -ForegroundColor Yellow

& $Python.Source tools\atlas_post_v21_package6c_capability_ownership_gate.py
if ($LASTEXITCODE -ne 0) {
    throw "Gate de arquitetura dos recursos especializados falhou."
}

Write-Host "[2/2] Timeline 6C + Pacote 6B + toda homologação anterior" -ForegroundColor Yellow

$PreviousParameters = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $PreviousParameters["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_post_v21_package6c_timeline_hotfix_homologation.ps1" @PreviousParameters
if ($LASTEXITCODE -ne 0) {
    throw "Homologação integrada do Pacote 6C falhou."
}

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 6C: GATES APROVADOS" -ForegroundColor Green
