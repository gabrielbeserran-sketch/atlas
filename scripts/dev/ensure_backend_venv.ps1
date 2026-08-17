$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Backend = Join-Path $ProjectRoot "backend"
$Venv = Join-Path $Backend ".venv"
$Python = Join-Path $Venv "Scripts\python.exe"
$Requirements = Join-Path $Backend "requirements.txt"
$RequirementsDev = Join-Path $Backend "requirements-dev.txt"
$Checker = Join-Path $Backend "scripts\check_python_environment.py"
$DependencyStamp = Join-Path $Venv ".atlas_requirements.sha256"

function Assert-ExitCode {
    param(
        [Parameter(Mandatory = $true)][string]$Step,
        [Parameter(Mandatory = $true)][int]$ExitCode
    )

    if ($ExitCode -ne 0) {
        throw "$Step falhou com código $ExitCode."
    }
}

function Get-SystemPython {
    $py = Get-Command "py" -ErrorAction SilentlyContinue
    if ($py) {
        & py -3 --version *> $null
        if ($LASTEXITCODE -eq 0) {
            return [PSCustomObject]@{
                Command = "py"
                Prefix = @("-3")
            }
        }
    }

    $python = Get-Command "python" -ErrorAction SilentlyContinue
    if ($python) {
        & python --version *> $null
        if ($LASTEXITCODE -eq 0) {
            return [PSCustomObject]@{
                Command = "python"
                Prefix = @()
            }
        }
    }

    throw @"
Python 3 não foi encontrado.
Instale Python 3.11 ou superior pelo python.org, marque
'Add python.exe to PATH' e execute novamente.
"@
}

function Get-RequirementsFingerprint {
    if (-not (Test-Path $Requirements)) {
        throw "Arquivo obrigatório ausente: $Requirements"
    }
    if (-not (Test-Path $RequirementsDev)) {
        throw "Arquivo obrigatório ausente: $RequirementsDev"
    }

    $hash1 = (Get-FileHash $Requirements -Algorithm SHA256).Hash
    $hash2 = (Get-FileHash $RequirementsDev -Algorithm SHA256).Hash
    $inputText = "$hash1|$hash2"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputText)
    $sha = [System.Security.Cryptography.SHA256]::Create()

    try {
        return (
            [System.BitConverter]::ToString(
                $sha.ComputeHash($bytes)
            ).Replace("-", "")
        )
    } finally {
        $sha.Dispose()
    }
}

function Test-CriticalDependencies {
    if (-not (Test-Path $Python)) {
        return $false
    }
    if (-not (Test-Path $Checker)) {
        throw "Validador Python não encontrado em $Checker."
    }

    & $Python $Checker *> $null
    return ($LASTEXITCODE -eq 0)
}

function Install-Dependencies {
    Write-Host "Atualizando pip..." -ForegroundColor DarkYellow
    & $Python -m pip install `
        --disable-pip-version-check `
        --upgrade pip
    Assert-ExitCode -Step "Atualização do pip" -ExitCode $LASTEXITCODE

    Write-Host "Instalando requirements-dev.txt..." -ForegroundColor DarkYellow
    & $Python -m pip install `
        --disable-pip-version-check `
        -r $RequirementsDev
    Assert-ExitCode -Step "Instalação das dependências backend" -ExitCode $LASTEXITCODE
}

Write-Host "=== ATLAS - AMBIENTE PYTHON DO BACKEND ===" -ForegroundColor Cyan
Write-Host "Projeto: $ProjectRoot" -ForegroundColor DarkGray

$created = $false

if (-not (Test-Path $Python)) {
    Write-Host "[1/4] .venv ausente. Criando ambiente virtual..." -ForegroundColor Yellow

    if (Test-Path $Venv) {
        # Somente ambiente virtual incompleto; não contém dados do Atlas.
        Remove-Item -Recurse -Force $Venv
    }

    $systemPython = Get-SystemPython
    $arguments = @()
    $arguments += $systemPython.Prefix
    $arguments += @("-m", "venv", $Venv)

    & $systemPython.Command @arguments
    Assert-ExitCode -Step "Criação da .venv" -ExitCode $LASTEXITCODE
    $created = $true
} else {
    Write-Host "[1/4] .venv encontrada." -ForegroundColor Green
}

if (-not (Test-Path $Python)) {
    throw "Python da .venv não encontrado em $Python."
}

Write-Host "[2/4] Validando versão do Python..." -ForegroundColor Yellow
& $Python $Checker --version-only
Assert-ExitCode -Step "Validação da versão Python" -ExitCode $LASTEXITCODE

$fingerprint = Get-RequirementsFingerprint
$currentFingerprint = ""
if (Test-Path $DependencyStamp) {
    $currentFingerprint = (Get-Content $DependencyStamp -Raw).Trim()
}

$dependenciesOk = Test-CriticalDependencies
$requirementsChanged = ($currentFingerprint -ne $fingerprint)

Write-Host "[3/4] Validando dependências Python..." -ForegroundColor Yellow
if ($created -or (-not $dependenciesOk) -or $requirementsChanged) {
    if (-not $dependenciesOk) {
        Write-Host "Dependências ausentes ou incompletas detectadas." -ForegroundColor DarkYellow
    }
    if ($requirementsChanged) {
        Write-Host "Requirements novos ou ainda não sincronizados." -ForegroundColor DarkYellow
    }

    Install-Dependencies
    Set-Content `
        -Path $DependencyStamp `
        -Value $fingerprint `
        -Encoding ASCII
} else {
    Write-Host "Dependências sincronizadas." -ForegroundColor Green
}

Write-Host "[4/4] Smoke test dos imports críticos..." -ForegroundColor Yellow
& $Python $Checker
Assert-ExitCode -Step "Smoke test do ambiente Python" -ExitCode $LASTEXITCODE

Write-Host ""
Write-Host "ATLAS BACKEND PYTHON ENVIRONMENT: APROVADO" -ForegroundColor Green
Write-Host "Python: $Python" -ForegroundColor Green
