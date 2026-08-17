$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Preflight = Join-Path $PSScriptRoot "preflight_project.ps1"
$BackendPython = Join-Path $ProjectRoot "backend\.venv\Scripts\python.exe"
$PowerShellAudit = Join-Path $ProjectRoot "scripts\quality\atlas_powershell_static_audit.py"
$BaselineAudit = Join-Path $ProjectRoot "scripts\quality\atlas_baseline_static_audit.py"

function Assert-Command {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw $Message
    }
}

function Assert-ExitCode {
    param(
        [Parameter(Mandatory = $true)][string]$Step,
        [Parameter(Mandatory = $true)][int]$ExitCode
    )

    if ($ExitCode -ne 0) {
        throw "$Step falhou com código $ExitCode."
    }
}

Set-Location $ProjectRoot

Write-Host "=== ATLAS - BOOTSTRAP DA BASELINE ===" -ForegroundColor Cyan

Write-Host "[1/5] Preflight..." -ForegroundColor Yellow
& $Preflight

Assert-Command -Name "flutter" -Message "Flutter não foi encontrado no PATH."
Assert-Command -Name "dart" -Message "Dart não foi encontrado no PATH."

Write-Host "[2/5] Validando Flutter..." -ForegroundColor Yellow
flutter --version
Assert-ExitCode -Step "Validação do Flutter" -ExitCode $LASTEXITCODE

Write-Host "[3/5] Restaurando dependências Flutter/Dart..." -ForegroundColor Yellow
flutter pub get
Assert-ExitCode -Step "Flutter pub get" -ExitCode $LASTEXITCODE

$PackageConfig = Join-Path $ProjectRoot ".dart_tool\package_config.json"
if (-not (Test-Path $PackageConfig)) {
    throw "flutter pub get não gerou package_config.json."
}

Write-Host "[4/5] Auditoria PowerShell estática..." -ForegroundColor Yellow
& $BackendPython $PowerShellAudit
Assert-ExitCode -Step "Auditoria PowerShell" -ExitCode $LASTEXITCODE

Write-Host "[5/5] Auditoria estática da baseline..." -ForegroundColor Yellow
& $BackendPython $BaselineAudit
Assert-ExitCode -Step "Auditoria da baseline" -ExitCode $LASTEXITCODE

Write-Host "ATLAS PROJECT BOOTSTRAP: APROVADO" -ForegroundColor Green
