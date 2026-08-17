param(
    [string]$BaseUrl = "http://127.0.0.1:8000"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

Write-Host "=== ATLAS RUNTIME API VALIDATION ===" -ForegroundColor Cyan

try {
    $openapi = Invoke-RestMethod -Uri "$BaseUrl/openapi.json" -Method Get -TimeoutSec 10
} catch {
    throw "Backend Atlas não está disponível em $BaseUrl. Inicie o Uvicorn antes desta validação."
}

if ([string]::IsNullOrWhiteSpace($openapi.info.title)) {
    throw "OpenAPI respondeu sem metadados válidos."
}

Write-Host "[1/2] OpenAPI: $($openapi.info.title)" -ForegroundColor Green

Write-Host "[2/2] Fluxo real de Fazendas" -ForegroundColor Yellow
& powershell -ExecutionPolicy Bypass -File ".\scripts\quality\test_integrated_api_farms.ps1" -BaseUrl $BaseUrl
if ($LASTEXITCODE -ne 0) {
    throw "Teste integrado de Fazendas falhou com código $LASTEXITCODE."
}

Write-Host ""
Write-Host "ATLAS RUNTIME API VALIDATION: APROVADO" -ForegroundColor Green
