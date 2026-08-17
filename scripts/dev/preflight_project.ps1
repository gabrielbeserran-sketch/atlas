$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$EnsureBackend = Join-Path $PSScriptRoot "ensure_backend_venv.ps1"
$BackendPython = Join-Path $ProjectRoot "backend\.venv\Scripts\python.exe"
$PredictiveAudit = Join-Path $ProjectRoot "scripts\quality\atlas_predictive_risk_audit.py"

Set-Location $ProjectRoot

Write-Host "=== ATLAS - PREFLIGHT DA BASELINE ===" -ForegroundColor Cyan
Write-Host "[1/4] Parser nativo dos scripts PowerShell..." -ForegroundColor Yellow

$parseFailures = @()

Get-ChildItem -Path (Join-Path $ProjectRoot "scripts") -Recurse -Filter "*.ps1" | ForEach-Object {
    $tokens = $null
    $parseErrors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
        $_.FullName,
        [ref]$tokens,
        [ref]$parseErrors
    ) | Out-Null

    if ($parseErrors.Count -gt 0) {
        foreach ($parseError in $parseErrors) {
            $message = $_.FullName + ":" + $parseError.Extent.StartLineNumber
            $message += " - " + $parseError.Message
            $parseFailures += $message
        }
    }
}

if ($parseFailures.Count -gt 0) {
    Write-Host "ATLAS POWERSHELL NATIVE PARSER: FAIL" -ForegroundColor Red
    foreach ($failure in $parseFailures) {
        Write-Host " - $failure" -ForegroundColor Red
    }
    throw "Existem scripts PowerShell com erro de parser."
}

Write-Host "ATLAS POWERSHELL NATIVE PARSER: OK" -ForegroundColor Green

Write-Host "[2/4] Preparando ambiente Python..." -ForegroundColor Yellow
if (-not (Test-Path $EnsureBackend)) {
    throw "Bootstrap Python ausente em $EnsureBackend."
}

& $EnsureBackend

if (-not (Test-Path $BackendPython)) {
    throw "Python da .venv não encontrado após bootstrap: $BackendPython."
}

Write-Host "[3/4] Auditoria preditiva de riscos..." -ForegroundColor Yellow
if (-not (Test-Path $PredictiveAudit)) {
    throw "Auditor preditivo ausente em $PredictiveAudit."
}

& $BackendPython $PredictiveAudit
if ($LASTEXITCODE -ne 0) {
    throw "Auditoria preditiva da baseline falhou."
}

Write-Host "[4/4] Preflight concluído..." -ForegroundColor Yellow
Write-Host "ATLAS PREFLIGHT: APROVADO" -ForegroundColor Green
