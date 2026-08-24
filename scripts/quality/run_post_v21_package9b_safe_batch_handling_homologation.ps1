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

Write-Host "=== ATLAS POS-V21 - PACOTE 9B MANEJO COLETIVO SEGURO ===" -ForegroundColor Cyan

& $Python.Source tools\atlas_post_v21_package9b_safe_batch_handling_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate 9B falhou." }

$BackendFiles = @(
    "backend/app/models/legacy.py",
    "backend/app/schemas/legacy.py",
    "backend/app/routers/livestock.py",
    "backend/alembic/versions/20260824_0045_farm_handling_operations.py"
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

& "$ProjectRoot\scripts\quality\run_post_v21_package9a_vet_contact_homologation.ps1" @Previous
if ($LASTEXITCODE -ne 0) {
    throw "Regressão integrada 9A -> 9B falhou."
}

& $Python.Source tools\atlas_post_v21_package9b_release_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate de release 9B falhou." }

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 9B: GATES APROVADOS" -ForegroundColor Green
Write-Host "Backend alterado: após homologar, publique no Render; Alembic 0045 será aplicado automaticamente." -ForegroundColor Yellow
