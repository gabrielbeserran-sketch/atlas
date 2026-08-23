$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $root

Write-Host "=== ATLAS - PREPARACAO SEGURA DO GIT PARA O RENDER ===" -ForegroundColor Cyan

if (-not (Test-Path ".git")) {
    throw "A pasta .git não existe. Execute scripts\dev\restore_git_metadata.ps1 primeiro."
}

& "$root\scripts\quality\fix_git_tracked_secrets.ps1"
if ($LASTEXITCODE -ne 0) {
    throw "Correção de segredos rastreados falhou."
}

& "$root\scripts\quality\audit_git_secrets.ps1"
if ($LASTEXITCODE -ne 0) {
    throw "Auditoria de segredos falhou."
}

$OldGitPager = $env:GIT_PAGER
$OldPager = $env:PAGER
$OldLess = $env:LESS

try {
    $env:GIT_PAGER = "cat"
    $env:PAGER = "cat"
    $env:LESS = "FRX"

    Write-Host ""
    Write-Host "Branch:" -ForegroundColor Yellow
    & git -c core.pager=cat branch --show-current

    Write-Host ""
    Write-Host "Origin:" -ForegroundColor Yellow
    & git -c core.pager=cat remote get-url origin

    Write-Host ""
    Write-Host "Quantidade de alterações:" -ForegroundColor Yellow
    $ChangeCount = @(
        & git -c core.pager=cat status --short --untracked-files=all
    ).Count
    Write-Host $ChangeCount
}
finally {
    $env:GIT_PAGER = $OldGitPager
    $env:PAGER = $OldPager
    $env:LESS = $OldLess
}

Write-Host ""
Write-Host "ATLAS GIT PREPARE: APROVADO" -ForegroundColor Green
Write-Host "A remoção staged de segredos previamente rastreados é esperada e segura." -ForegroundColor Green
Write-Host "Ainda não foi executado git add/commit/push." -ForegroundColor Green
