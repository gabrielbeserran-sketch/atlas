$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Python = Join-Path $ProjectRoot "backend\.venv\Scripts\python.exe"
$FullGate = Join-Path $PSScriptRoot "run_full_quality_gate.ps1"
$LockFile = Join-Path $ProjectRoot "ATLAS_MARCO5A_BASELINE_LOCK.json"
$LockScript = Join-Path $PSScriptRoot "atlas_marco5a_baseline_lock.py"

Set-Location $ProjectRoot

if (-not (Test-Path $FullGate)) {
    throw "Quality Gate completo não encontrado em $FullGate."
}

Write-Host "=== ATLAS MARCO 5A GATE ===" -ForegroundColor Cyan
Write-Host "[1/4] Revalidando baseline completa Marco 4E..." -ForegroundColor Yellow
& $FullGate

if (-not (Test-Path $Python)) {
    throw "Python da .venv não encontrado após o Quality Gate: $Python."
}
if (-not (Test-Path $LockScript)) {
    throw "Baseline lock não encontrado em $LockScript."
}

Write-Host "[2/4] Conferindo origem da trava da baseline..." -ForegroundColor Yellow

$NeedsLocalPromotion = $true
if (Test-Path $LockFile) {
    try {
        $LockData = Get-Content -Raw -Encoding UTF8 $LockFile | ConvertFrom-Json
        if ($LockData.baseline_origin -eq "local_full_quality_gate") {
            $NeedsLocalPromotion = $false
        }
    }
    catch {
        throw "ATLAS_MARCO5A_BASELINE_LOCK.json inválido: $($_.Exception.Message)"
    }
}

if ($NeedsLocalPromotion) {
    Write-Host (
        "Primeira execução local: promovendo SOMENTE a árvore que acabou de " +
        "passar o Full Quality Gate."
    ) -ForegroundColor Cyan

    & $Python $LockScript --promote-local-approved-baseline
    if ($LASTEXITCODE -ne 0) {
        throw "Promoção inicial da baseline local falhou com código $LASTEXITCODE."
    }
}
else {
    Write-Host "Baseline local já homologada. Nenhuma promoção automática será feita." -ForegroundColor Green
}

Write-Host "[3/4] Verificando trava da baseline homologada..." -ForegroundColor Yellow
& $Python $LockScript
if ($LASTEXITCODE -ne 0) {
    throw "Baseline lock do Marco 5A falhou com código $LASTEXITCODE."
}

Write-Host "[4/4] Inventariando prontidão de produção..." -ForegroundColor Yellow
& $Python scripts\quality\atlas_marco5a_production_readiness.py
if ($LASTEXITCODE -ne 0) {
    throw "Inventário de produção do Marco 5A falhou com código $LASTEXITCODE."
}

Write-Host ""
Write-Host "ATLAS MARCO 5A: APROVADO" -ForegroundColor Green
Write-Host (
    "Baseline local protegida; alterações futuras nos arquivos homologados " +
    "não serão promovidas automaticamente."
) -ForegroundColor Green
