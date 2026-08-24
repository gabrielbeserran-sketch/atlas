$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

$MigrationPath = "backend/alembic/versions/20260823_0044_consultancy_contacts.py"
$RouterPath = "backend/app/routers/consultancy.py"
$ContactService = "lib/features/consultancy_client/data/services/atlas_consultancy_contact_service.dart"

Write-Host "=== ATLAS POS-V21 PACOTE 9A - CHECK DO STAGING ===" -ForegroundColor Cyan

$OldGitPager = $env:GIT_PAGER
$OldPager = $env:PAGER
try {
    $env:GIT_PAGER = "cat"
    $env:PAGER = "cat"

    & git ls-files --error-unmatch -- $MigrationPath *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Migration 0044 ainda não está rastreada após git add -A."
    }

    $StagedPaths = @(& git -c core.pager=cat diff --cached --name-only)
    foreach ($Required in @($MigrationPath, $RouterPath, $ContactService)) {
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
Write-Host "ATLAS 9A STAGED RELEASE: APROVADO" -ForegroundColor Green
Write-Host "Migration 0044 + backend + Flutter estão no commit." -ForegroundColor Green
