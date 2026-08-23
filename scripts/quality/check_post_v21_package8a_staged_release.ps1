$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

$MigrationPath = "backend/alembic/versions/20260823_0043_security_camera_alerts.py"

Write-Host "=== ATLAS POS-V21 PACOTE 8A - CHECK DO STAGING ===" -ForegroundColor Cyan

$OldGitPager = $env:GIT_PAGER
$OldPager = $env:PAGER
$OldLess = $env:LESS

try {
    $env:GIT_PAGER = "cat"
    $env:PAGER = "cat"
    $env:LESS = "FRX"

    & git ls-files --error-unmatch -- $MigrationPath *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Migration 0043 ainda não está rastreada após git add -A."
    }

    $StagedPaths = @(
        & git -c core.pager=cat diff --cached --name-only
    )

    if ($StagedPaths -notcontains $MigrationPath) {
        throw "Migration 0043 não está no staging do commit atual."
    }

    $DiffOutput = & git -c core.pager=cat -c core.safecrlf=false diff --cached --check 2>$null
    if ($LASTEXITCODE -ne 0) {
        if ($DiffOutput) {
            $DiffOutput | Write-Host
        }
        throw "git diff --cached --check encontrou inconsistências reais."
    }

    $SecurityRouter = "backend/app/routers/security_camera.py"
    if ($StagedPaths -notcontains $SecurityRouter) {
        throw "Router de segurança da câmera não está no staging."
    }

    $CameraWidget = "lib/features/security_camera/presentation/widgets/atlas_security_camera_card.dart"
    if ($StagedPaths -notcontains $CameraWidget) {
        throw "Interface da câmera não está no staging."
    }
}
finally {
    $env:GIT_PAGER = $OldGitPager
    $env:PAGER = $OldPager
    $env:LESS = $OldLess
}

Write-Host ""
Write-Host "ATLAS 8A STAGED RELEASE: APROVADO" -ForegroundColor Green
Write-Host "Migration 0043 + backend + app estão incluídos no commit." -ForegroundColor Green
Write-Host "Pode executar o commit e o push." -ForegroundColor Green
