$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10D - CHECK DO STAGING ===" -ForegroundColor Cyan

$manifest = Get-Content '.\docs\ATLAS_POS_V21_MACROPACOTE_10D_MANIFEST.json' -Raw | ConvertFrom-Json
$declared = @(
    $manifest.release_paths |
        ForEach-Object { $_ -replace '\\', '/' } |
        Sort-Object -Unique
)

$expectedChanged = @()
foreach ($path in $declared) {
    if (-not (Test-Path $path)) {
        throw "Arquivo declarado ausente: $path"
    }
    $diffForPath = @(git diff HEAD --name-only -- $path)
    if ($diffForPath.Count -gt 0) {
        $expectedChanged += $path
    }
}

$expectedChanged = @($expectedChanged | Sort-Object -Unique)
$staged = @(
    git diff --cached --name-only |
        ForEach-Object { $_ -replace '\\', '/' } |
        Sort-Object -Unique
)

$unexpected = @($staged | Where-Object { $declared -notcontains $_ })
$missing = @($expectedChanged | Where-Object { $staged -notcontains $_ })

if ($unexpected.Count -gt 0) {
    $unexpected | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    throw "Staging contaminado para 10D."
}
if ($missing.Count -gt 0) {
    $missing | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    throw "Staging incompleto para 10D."
}

git diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw "git diff --cached --check reprovado."
}

Write-Host "[OK] Manifesto: $($declared.Count) autorizados; staged: $($staged.Count); 0 inesperados; 0 alterados ausentes." -ForegroundColor Green
Write-Host "ATLAS 10D STAGED RELEASE: APROVADO" -ForegroundColor Green
