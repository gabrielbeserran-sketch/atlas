$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Backend = Join-Path $ProjectRoot "backend"
$Python = Join-Path $Backend ".venv\Scripts\python.exe"
$EnsurePythonScript = Join-Path $ProjectRoot "scripts\dev\ensure_backend_venv.ps1"
$InfrastructureScript = Join-Path $ProjectRoot "scripts\dev\start_local_infrastructure.ps1"
Set-Location $ProjectRoot

function Assert-ExitCode {
    param([Parameter(Mandatory = $true)][string]$Step)

    if ($LASTEXITCODE -ne 0) {
        throw "$Step falhou com código $LASTEXITCODE."
    }
}

function Assert-Command {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw $Message
    }
}

function Get-AtlasEnvironment {
    $environment = "development"
    $envFile = Join-Path $Backend ".env"

    if (Test-Path $envFile) {
        $line = Get-Content $envFile |
            Where-Object { $_ -match '^ATLAS_ENV=' } |
            Select-Object -First 1

        if ($line) {
            $value = ($line -split '=', 2)[1]
            $environment = $value.Trim().ToLowerInvariant()
        }
    }

    return $environment
}

Write-Host "=== ATLAS FULL QUALITY GATE ===" -ForegroundColor Cyan

if (-not (Test-Path $EnsurePythonScript)) {
    throw "Bootstrap Python ausente em $EnsurePythonScript."
}

Write-Host "[1/18] Ambiente Python backend" -ForegroundColor Yellow
& $EnsurePythonScript

if (-not (Test-Path $Python)) {
    throw "Ambiente Python não foi criado em $Python."
}

Write-Host "[2/18] Sintaxe estática dos scripts PowerShell" -ForegroundColor Yellow
& $Python scripts\quality\atlas_powershell_static_audit.py
Assert-ExitCode -Step "Auditoria estática PowerShell"

Write-Host "[3/18] Auditoria estática da baseline" -ForegroundColor Yellow
& $Python scripts\quality\atlas_baseline_static_audit.py
Assert-ExitCode -Step "Auditoria estática da baseline"

Write-Host "[4/18] Contrato estático de infraestrutura local" -ForegroundColor Yellow
& $Python scripts\quality\atlas_local_infrastructure_contract.py
Assert-ExitCode -Step "Contrato de infraestrutura local"

$AtlasEnv = Get-AtlasEnvironment
if ($AtlasEnv -in @("development", "test")) {
    if (-not (Test-Path $InfrastructureScript)) {
        throw "Script de infraestrutura ausente em $InfrastructureScript."
    }

    Assert-Command `
        -Name "docker" `
        -Message "Docker não encontrado. Inicie/instale Docker Desktop."

    Write-Host "[5/18] Infraestrutura local PostgreSQL" -ForegroundColor Yellow
    & $InfrastructureScript
} else {
    Write-Host "[5/18] Infraestrutura local: não aplicável ($AtlasEnv)" -ForegroundColor DarkGray
}

Assert-Command `
    -Name "flutter" `
    -Message "Flutter não encontrado no PATH."
Assert-Command `
    -Name "dart" `
    -Message "Dart não encontrado no PATH."

Write-Host "[6/18] Flutter clean" -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Get-Process projeto_atlas,dart,dartaotruntime -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    foreach ($path in @(
        ".\linux\flutter\ephemeral",
        ".\windows\flutter\ephemeral",
        ".\build"
    )) {
        if (Test-Path $path) {
            Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
        }
    }

    flutter clean
    Assert-ExitCode -Step "Flutter clean"
}

Write-Host "[7/18] Flutter pub get" -ForegroundColor Yellow
flutter pub get
Assert-ExitCode -Step "Flutter pub get"

Write-Host "[8/18] Dart format" -ForegroundColor Yellow
dart format lib test
Assert-ExitCode -Step "Dart format"

Write-Host "[9/18] Flutter analyze" -ForegroundColor Yellow
flutter analyze
Assert-ExitCode -Step "Flutter analyze"

Write-Host "[10/18] Flutter test" -ForegroundColor Yellow
flutter test
Assert-ExitCode -Step "Flutter test"

Set-Location $Backend

if ($AtlasEnv -in @("development", "test")) {
    Write-Host "[11/18] Reconciliação segura do schema local/Alembic" -ForegroundColor Yellow
    & $Python scripts\reconcile_local_alembic.py
    Assert-ExitCode -Step "Reconciliação local Alembic"
} else {
    Write-Host "[11/18] Alembic upgrade head" -ForegroundColor Yellow
    & $Python -m alembic upgrade head
    Assert-ExitCode -Step "Alembic upgrade head"
}

Write-Host "[12/18] Alembic current/head" -ForegroundColor Yellow
& $Python -m alembic current
Assert-ExitCode -Step "Alembic current"
& $Python -m alembic heads
Assert-ExitCode -Step "Alembic heads"

Write-Host "[13/18] Pytest backend" -ForegroundColor Yellow
& $Python -m pytest -q
Assert-ExitCode -Step "Pytest backend"

Set-Location $ProjectRoot

Write-Host "[14/18] Auditoria estrutural Atlas" -ForegroundColor Yellow
& $Python scripts\quality\atlas_full_project_audit.py
Assert-ExitCode -Step "Auditoria estrutural"

Write-Host "[15/18] Matriz Marco 4 tela/rota" -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco4_route_screen_matrix.py
Assert-ExitCode -Step "Matriz Marco 4"

Write-Host "[16/18] Classificação de persistência/rotas" -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco4_persistence_classification.py
Assert-ExitCode -Step "Classificação Marco 4"

Write-Host "[17/18] Classificação de features avançadas" -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco4_advanced_feature_classification.py
Assert-ExitCode -Step "Features avançadas Marco 4"

Write-Host "[18/18] Fechamento funcional V1 Marco 4D" -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco4_v1_functional_closure.py
Assert-ExitCode -Step "Fechamento funcional V1 Marco 4D"

Write-Host ""
Write-Host "ATLAS FULL QUALITY GATE: APROVADO" -ForegroundColor Green
