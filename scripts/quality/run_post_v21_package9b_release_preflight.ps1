$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

$Python = Get-Command python -ErrorAction SilentlyContinue
if (-not $Python) { $Python = Get-Command py -ErrorAction SilentlyContinue }
if (-not $Python) { throw "Python não encontrado." }

$MigrationPath = "backend/alembic/versions/20260824_0045_farm_handling_operations.py"

Write-Host "=== ATLAS POS-V21 PACOTE 9B - PREFLIGHT DE RELEASE ===" -ForegroundColor Cyan

& $Python.Source tools\atlas_post_v21_package9b_release_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate de release 9B falhou." }

if (-not (Test-Path $MigrationPath)) {
    throw "Migration 0045 ausente."
}

$MigrationContent = Get-Content -Raw -Path $MigrationPath
if ($MigrationContent -notmatch 'revision\s*=\s*"20260824_0045"') {
    throw "Revision da migration 0045 incorreta."
}
if ($MigrationContent -notmatch 'down_revision\s*=\s*"20260823_0044"') {
    throw "Migration 0045 não encadeia 0044."
}

git check-ignore -q -- $MigrationPath
if ($LASTEXITCODE -eq 0) {
    throw "Migration 0045 está ignorada pelo Git."
}
if ($LASTEXITCODE -notin @(0, 1)) {
    throw "Falha ao consultar regras de ignore."
}

$OldGitPager = $env:GIT_PAGER
$OldPager = $env:PAGER
$OldLess = $env:LESS
try {
    $env:GIT_PAGER = "cat"
    $env:PAGER = "cat"
    $env:LESS = "FRX"

    $DiffOutput = & git -c core.pager=cat -c core.safecrlf=false diff --check 2>$null
    if ($LASTEXITCODE -ne 0) {
        if ($DiffOutput) { $DiffOutput | Write-Host }
        throw "git diff --check encontrou inconsistências reais."
    }
}
finally {
    $env:GIT_PAGER = $OldGitPager
    $env:PAGER = $OldPager
    $env:LESS = $OldLess
}

Write-Host ""
Write-Host "ATLAS 9B RELEASE PREFLIGHT: APROVADO" -ForegroundColor Green
Write-Host "Próxima ordem:" -ForegroundColor Green
Write-Host "  git add -A" -ForegroundColor White
Write-Host "  powershell -ExecutionPolicy Bypass -File `".\scripts\quality\check_post_v21_package9b_staged_release.ps1`"" -ForegroundColor White
