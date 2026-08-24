$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))

Write-Host "=== ATLAS POS-V21 PACOTE 9F - CHECK DO STAGING ===" -ForegroundColor Cyan

$manifestPath = ".\docs\ATLAS_POS_V21_PACOTE_9F_MANIFEST.json"
if (-not (Test-Path $manifestPath)) { throw "Manifesto 9F ausente." }

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$declared = @(
    $manifest.release_paths |
    ForEach-Object { $_ -replace '\\','/' } |
    Sort-Object -Unique
)
if ($declared.Count -eq 0) { throw "Manifesto 9F vazio." }

# O manifesto define os arquivos AUTORIZADOS do pacote.
# O staging so pode exigir os que realmente diferem do HEAD local.
$expectedChanged = @()
foreach ($path in $declared) {
    if (-not (Test-Path $path)) {
        throw "Arquivo declarado no manifesto ausente da arvore: $path"
    }

    $diffForPath = @(git diff HEAD --name-only -- $path)
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao comparar arquivo do manifesto com HEAD: $path"
    }

    if ($diffForPath.Count -gt 0) {
        $expectedChanged += $path
    }
}

$expectedChanged = @($expectedChanged | Sort-Object -Unique)
$staged = @(
    git diff --cached --name-only |
    ForEach-Object { $_ -replace '\\','/' } |
    Sort-Object -Unique
)

$unexpected = @($staged | Where-Object { $declared -notcontains $_ })
$missing = @($expectedChanged | Where-Object { $staged -notcontains $_ })

if ($unexpected.Count -gt 0) {
    Write-Host "Arquivos fora do manifesto 9F encontrados no staging:" -ForegroundColor Red
    $unexpected | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    throw "Staging contaminado por arquivos que nao pertencem ao Pacote 9F."
}

if ($missing.Count -gt 0) {
    Write-Host "Arquivos alterados do Pacote 9F ausentes do staging:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    throw "Staging incompleto para o Pacote 9F."
}

git diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw "git diff --cached --check encontrou inconsistencias."
}

$unchanged = @($declared | Where-Object { $expectedChanged -notcontains $_ })

Write-Host "[OK] Manifesto canonico: $($declared.Count) arquivos autorizados." -ForegroundColor Green
Write-Host "[OK] Arquivos realmente alterados contra HEAD: $($expectedChanged.Count)." -ForegroundColor Green
Write-Host "[OK] Arquivos staged: $($staged.Count); 0 inesperados; 0 alterados ausentes." -ForegroundColor Green
if ($unchanged.Count -gt 0) {
    Write-Host "[OK] Arquivos do manifesto ja identicos ao HEAD nao foram exigidos no staging: $($unchanged.Count)." -ForegroundColor Green
}
Write-Host "ATLAS 9F STAGED RELEASE: APROVADO" -ForegroundColor Green
