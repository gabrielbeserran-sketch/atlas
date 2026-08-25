$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))

Write-Host "=== ATLAS POS-V21 MACROPACOTE 10D - V1 RELEASE CANDIDATE ===" -ForegroundColor Cyan

function Assert-ExitCode {
    param([string]$Step)
    if ($LASTEXITCODE -ne 0) {
        throw "$Step reprovado."
    }
}

$psFiles = Get-ChildItem .\scripts -Recurse -Filter *.ps1 -File
foreach ($script in $psFiles) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $script.FullName,
        [ref]$tokens,
        [ref]$errors
    ) | Out-Null
    if ($errors.Count -gt 0) {
        Write-Host "PowerShell invalido: $($script.FullName)" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        throw "Parser PowerShell global reprovado."
    }
}
Write-Host "[OK] Parser PowerShell global: $($psFiles.Count) scripts." -ForegroundColor Green

python .\tools\atlas_post_v21_macro10d_v1_rc_gate.py
Assert-ExitCode "Gate estrutural 10D"

python .\scripts\quality\atlas_powershell_static_audit.py
Assert-ExitCode "Auditoria PowerShell"

python .\scripts\quality\atlas_marco5b_security_contract.py
Assert-ExitCode "Contrato de seguranca Marco 5B"

python .\tools\atlas_v21_6_critical_flows_gate.py
Assert-ExitCode "Fluxos criticos V21"

python .\scripts\quality\atlas_full_project_audit.py
Assert-ExitCode "Auditoria global"

python .\scripts\quality\atlas_predictive_risk_audit.py --no-write
Assert-ExitCode "Auditoria preventiva"

Write-Host "[RC] flutter pub get" -ForegroundColor Yellow
flutter pub get
Assert-ExitCode "flutter pub get"

Write-Host "[RC] flutter analyze" -ForegroundColor Yellow
flutter analyze
Assert-ExitCode "flutter analyze"

Write-Host "[RC] flutter test - suite integral" -ForegroundColor Yellow
flutter test
Assert-ExitCode "flutter test"

$ensureBackendVenv = ".\scripts\dev\ensure_backend_venv.ps1"
if (-not (Test-Path $ensureBackendVenv)) {
    throw "Bootstrap do backend ausente: $ensureBackendVenv"
}

Write-Host "[RC] preparando ambiente Python backend" -ForegroundColor Yellow
& $ensureBackendVenv

$backendDir = Resolve-Path ".\backend"
$backendPython = Join-Path $backendDir ".venv\Scripts\python.exe"

if (-not (Test-Path $backendPython)) {
    throw "Python do backend nao foi preparado."
}

Write-Host "[RC] pytest backend - suite integral" -ForegroundColor Yellow

Push-Location $backendDir
try {
    # O pacote Python "app" vive dentro de backend/. Executar pytest a partir
    # da raiz do projeto faz o Python perder esse pacote no sys.path.
    & $backendPython -m pytest -q .\tests
    if ($LASTEXITCODE -ne 0) {
        throw "pytest backend reprovado."
    }
}
finally {
    Pop-Location
}

Write-Host "[RC] build Windows release" -ForegroundColor Yellow
flutter build windows --release
Assert-ExitCode "flutter build windows --release"

git diff --check
Assert-ExitCode "git diff --check"

Write-Host ""
Write-Host "ATLAS POS-V21 MACROPACOTE 10D: V1 RC GATES APROVADOS" -ForegroundColor Green
Write-Host "Migration: nenhuma (baseline permanece 0050)" -ForegroundColor Green
Write-Host "Build Windows release: aprovado" -ForegroundColor Green
