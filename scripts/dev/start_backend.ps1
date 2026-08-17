$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Backend = Join-Path $ProjectRoot "backend"
$Python = Join-Path $Backend ".venv\Scripts\python.exe"
$EnsurePythonScript = Join-Path $PSScriptRoot "ensure_backend_venv.ps1"
$InfraScript = Join-Path $PSScriptRoot "start_local_infrastructure.ps1"

if (-not (Test-Path $EnsurePythonScript)) {
    throw "Bootstrap Python ausente em $EnsurePythonScript."
}
if (-not (Test-Path $InfraScript)) {
    throw "Inicializador de infraestrutura ausente em $InfraScript."
}

Write-Host "=== ATLAS - INICIALIZAÇÃO DO BACKEND ===" -ForegroundColor Cyan
Write-Host "Preparando Python, PostgreSQL e FastAPI..." -ForegroundColor Yellow

& $EnsurePythonScript

if (-not (Test-Path $Python)) {
    throw "Bootstrap terminou sem criar $Python."
}

& $InfraScript

Set-Location $Backend
Write-Host ""
Write-Host "Ambiente aprovado. Iniciando FastAPI em http://127.0.0.1:8000 ..." -ForegroundColor Green

& $Python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
$uvicornExit = $LASTEXITCODE
if ($uvicornExit -ne 0) {
    throw "Backend Atlas encerrou com código $uvicornExit."
}
