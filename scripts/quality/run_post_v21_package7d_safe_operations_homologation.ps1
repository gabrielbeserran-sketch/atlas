param(
    [string]$BaseUrl = "https://atlas-api-29y2.onrender.com/api/v1",
    [switch]$SkipProductionSmoke
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

$Python = Get-Command python -ErrorAction SilentlyContinue
if (-not $Python) { $Python = Get-Command py -ErrorAction SilentlyContinue }
if (-not $Python) { throw "Python não encontrado." }

Write-Host "=== ATLAS POS-V21 - PACOTE 7D OPERACOES SEGURAS ===" -ForegroundColor Cyan

& $Python.Source tools\atlas_post_v21_package7d_safe_operations_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate de operações seguras 7D falhou." }

$Previous = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $Previous["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_post_v21_package7c_rural_language_homologation.ps1" @Previous
if ($LASTEXITCODE -ne 0) { throw "Homologação integrada do Pacote 7D falhou." }

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 7D: GATES APROVADOS" -ForegroundColor Green
