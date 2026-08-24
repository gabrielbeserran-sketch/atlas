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

Write-Host "=== ATLAS POS-V21 - PACOTE 8C COMPATIBILIDADE DA CAMERA ===" -ForegroundColor Cyan

& $Python.Source tools\atlas_post_v21_package8c_camera_compatibility_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate 8C falhou." }

$GatewayPython = Get-ChildItem `
    ".\edge\camera_gateway\atlas_camera_gateway" `
    -Filter "*.py" `
    -File

foreach ($File in $GatewayPython) {
    & $Python.Source -m py_compile $File.FullName
    if ($LASTEXITCODE -ne 0) {
        throw "Compilação Python do gateway falhou: $($File.Name)"
    }
}

& $Python.Source ".\edge\camera_gateway\scripts\selftest.py"
if ($LASTEXITCODE -ne 0) { throw "Selftest do gateway 8C falhou." }

$Previous = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $Previous["SkipProductionSmoke"] = $true
}

& "$ProjectRoot\scripts\quality\run_post_v21_package8b_edge_gateway_homologation.ps1" @Previous
if ($LASTEXITCODE -ne 0) {
    throw "Regressão integrada 8B -> 8C falhou."
}

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 8C: GATES APROVADOS" -ForegroundColor Green
Write-Host "Próxima etapa de campo: executar probe-camera contra o equipamento real." -ForegroundColor Yellow
