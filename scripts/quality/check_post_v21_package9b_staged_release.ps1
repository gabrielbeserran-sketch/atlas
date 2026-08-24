$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

$MigrationPath = "backend/alembic/versions/20260824_0045_farm_handling_operations.py"
$RouterPath = "backend/app/routers/livestock.py"
$ScreenPath = "lib/features/farm_handling/presentation/screens/farm_handling_screen.dart"
$RequiredPaths = @($MigrationPath, $RouterPath, $ScreenPath)

Write-Host "=== ATLAS POS-V21 PACOTE 9B - CHECK DO STAGING ===" -ForegroundColor Cyan

$OldGitPager = $env:GIT_PAGER
$OldPager = $env:PAGER
try {
    $env:GIT_PAGER = "cat"
    $env:PAGER = "cat"

    & git ls-files --error-unmatch -- $MigrationPath *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Migration 0045 não está rastreada pelo Git."
    }

    $StagedPaths = @(& git -c core.pager=cat diff --cached --name-only)

    if ($StagedPaths.Count -eq 0) {
        $DirtyPaths = @(& git -c core.pager=cat status --porcelain)
        if ($DirtyPaths.Count -ne 0) {
            throw "Não há staging, mas o working tree possui alterações. Execute git add -A antes deste gate."
        }

        foreach ($Required in $RequiredPaths) {
            & git cat-file -e "HEAD:$Required" 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Arquivo obrigatório não existe no HEAD: $Required"
            }
        }

        Write-Host ""
        Write-Host "ATLAS 9B RELEASE STATE: JA COMMITADO" -ForegroundColor Yellow
        Write-Host "Working tree limpo e arquivos obrigatórios presentes no HEAD." -ForegroundColor Green
        exit 0
    }

    foreach ($Required in $RequiredPaths) {
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
Write-Host "Migration 0045 + backend + Flutter estão preparados para o commit." -ForegroundColor Green
