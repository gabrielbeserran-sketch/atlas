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

Write-Host "=== ATLAS POS-V21 - PACOTE 8A CAMERA DA ENTRADA ===" -ForegroundColor Cyan

& $Python.Source tools\atlas_flutter_farm_model_boundary_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate de fronteira dos modelos de fazenda falhou." }

& $Python.Source tools\atlas_post_v21_package8a_security_camera_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate da câmera da entrada falhou." }

$BackendFiles = @(
    "backend/app/config.py",
    "backend/app/models/legacy.py",
    "backend/app/services/whatsapp_provider.py",
    "backend/app/services/whatsapp_webhook.py",
    "backend/app/services/security_camera_alerts.py",
    "backend/app/routers/security_camera.py",
    "backend/app/main.py",
    "backend/alembic/versions/20260823_0043_security_camera_alerts.py"
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

& "$ProjectRoot\scripts\quality\run_post_v21_package7f_contextual_intelligence_homologation.ps1" @Previous
if ($LASTEXITCODE -ne 0) { throw "Regressão integrada do Pacote 8A falhou." }

& $Python.Source tools\atlas_post_v21_package8a_release_preflight_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate de release 8A falhou." }

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 8A CAMERA: GATES APROVADOS" -ForegroundColor Green
Write-Host "Backend alterado: publique no Render; o startup aplicará Alembic automaticamente." -ForegroundColor Yellow
Write-Host "Depois execute scripts\quality\check_post_v21_package8a_security_camera_deployed.ps1" -ForegroundColor Yellow
