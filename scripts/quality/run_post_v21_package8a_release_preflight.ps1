param(
    [string]$BaseUrl = "https://atlas-api-29y2.onrender.com/api/v1"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

$Python = Get-Command python -ErrorAction SilentlyContinue
if (-not $Python) { $Python = Get-Command py -ErrorAction SilentlyContinue }
if (-not $Python) { throw "Python não encontrado." }

Write-Host "=== ATLAS POS-V21 PACOTE 8A - PREFLIGHT DE PUBLICACAO ===" -ForegroundColor Cyan

& $Python.Source tools\atlas_post_v21_package8a_release_preflight_gate.py
if ($LASTEXITCODE -ne 0) {
    throw "Contrato de publicação 8A falhou."
}

& "$ProjectRoot\scripts\quality\prepare_git_for_render.ps1"
if ($LASTEXITCODE -ne 0) {
    throw "Preparação segura do Git falhou."
}

$MigrationPath = "backend/alembic/versions/20260823_0043_security_camera_alerts.py"

if (-not (Test-Path $MigrationPath)) {
    throw "Migration 0043 não existe no caminho esperado."
}

$MigrationContent = Get-Content -Raw -Path $MigrationPath
if ($MigrationContent -notmatch 'revision\s*=\s*"20260823_0043"') {
    throw "Migration 0043 existe, mas revision está incorreta."
}
if ($MigrationContent -notmatch 'down_revision\s*=\s*"20260822_0042"') {
    throw "Migration 0043 não está encadeada à 0042."
}

git check-ignore -q -- $MigrationPath
if ($LASTEXITCODE -eq 0) {
    throw "Migration 0043 está ignorada pelo Git."
}
if ($LASTEXITCODE -notin @(0, 1)) {
    throw "Não foi possível verificar as regras de ignore da migration 0043."
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
        if ($DiffOutput) {
            $DiffOutput | Write-Host
        }
        throw "git diff --check encontrou inconsistências reais de whitespace."
    }
}
finally {
    $env:GIT_PAGER = $OldGitPager
    $env:PAGER = $OldPager
    $env:LESS = $OldLess
}

$MigrationTracked = $false
& git ls-files --error-unmatch -- $MigrationPath *> $null
if ($LASTEXITCODE -eq 0) {
    $MigrationTracked = $true
}

if ($MigrationTracked) {
    Write-Host "[OK] Migration 0043 já está rastreada pelo Git." -ForegroundColor Green
}
else {
    Write-Host "[OK] Migration 0043 está válida, não ignorada e pronta para git add." -ForegroundColor Green
}

Write-Host ""
Write-Host "ATLAS 8A RELEASE PREFLIGHT: APROVADO" -ForegroundColor Green
Write-Host "A migration 0043 foi validada antes do staging." -ForegroundColor Green
Write-Host "A publicação segura agora é:" -ForegroundColor Green
Write-Host "  git add -A" -ForegroundColor White
Write-Host "  powershell -ExecutionPolicy Bypass -File `".\scripts\quality\check_post_v21_package8a_staged_release.ps1`"" -ForegroundColor White
Write-Host '  git commit -m "feat: pacote 8A camera entrada whatsapp"' -ForegroundColor White
Write-Host "  git push origin master" -ForegroundColor White
Write-Host ""
Write-Host "O Render executará automaticamente alembic upgrade head." -ForegroundColor Yellow
Write-Host "Depois do deploy, execute:" -ForegroundColor Yellow
Write-Host "  powershell -ExecutionPolicy Bypass -File `".\scripts\quality\check_post_v21_package8a_security_camera_deployed.ps1`"" -ForegroundColor White
