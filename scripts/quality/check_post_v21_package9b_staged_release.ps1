$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

$MigrationPath = "backend/alembic/versions/20260824_0045_farm_handling_operations.py"
$RouterPath = "backend/app/routers/livestock.py"
$ScreenPath = "lib/features/farm_handling/presentation/screens/farm_handling_screen.dart"

Write-Host "=== ATLAS POS-V21 PACOTE 9B - CHECK DO STAGING ===" -ForegroundColor Cyan

$OldGitPager = $env:GIT_PAGER
$OldPager = $env:PAGER
try {
    $env:GIT_PAGER = "cat"
    $env:PAGER = "cat"

    & git ls-files --error-unmatch -- $MigrationPath *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Migration 0045 ainda não está rastreada após git add -A."
    }

    $StagedPaths = @(& git -c core.pager=cat diff --cached --name-only)
    foreach ($Required in @($MigrationPath, $RouterPath, $ScreenPath)) {
        if ($StagedPaths -notcontains $Required) {
            throw "Arquivo obrigatório não está no staging: $Required"
        }
    }

    $DiffOutput = & git -c core.pager=cat -c core.safecrlf=false diff --cached --check 2>$null
    if ($LASTEXITCODE -ne 0) {
        if ($DiffOutput) { $DiffOutput | Write-Host }
        throw "git diff --cached --check encontrou inconsistências."
    }
}
finally {
    $env:GIT_PAGER = $OldGitPager
    $env:PAGER = $OldPager
}

Write-Host ""
Write-Host "ATLAS 9B STAGED RELEASE: APROVADO" -ForegroundColor Green
Write-Host "Migration 0045 + backend + Flutter estão no commit." -ForegroundColor Green
