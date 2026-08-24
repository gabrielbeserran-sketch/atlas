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

Write-Host "=== ATLAS POS-V21 - PACOTE 9A CONTATO VETERINARIO ===" -ForegroundColor Cyan

& $Python.Source tools\atlas_post_v21_package9a_vet_contact_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate 9A falhou." }

& $Python.Source tools\atlas_test_contract_semantics_gate.py
if ($LASTEXITCODE -ne 0) {
    throw "Semântica dos testes de contrato divergiu da arquitetura atual."
}

$BackendFiles = @(
    "backend/app/models/legacy.py",
    "backend/app/routers/consultancy.py",
    "backend/app/main.py",
    "backend/alembic/versions/20260823_0044_consultancy_contacts.py"
)

foreach ($File in $BackendFiles) {
    & $Python.Source -m py_compile $File
    if ($LASTEXITCODE -ne 0) {
        throw "Compilação Python falhou: $File"
    }
}

$Previous = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $Previous["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_post_v21_package8c_camera_compatibility_homologation.ps1" @Previous
if ($LASTEXITCODE -ne 0) {
    throw "Regressão integrada 8C -> 9A falhou."
}

& $Python.Source tools\atlas_post_v21_package9a_release_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate de release 9A falhou." }

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 9A: GATES APROVADOS" -ForegroundColor Green
Write-Host "Backend alterado: após homologar, publique no Render; Alembic 0044 será aplicado automaticamente." -ForegroundColor Yellow
