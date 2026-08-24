$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))

Write-Host "=== ATLAS POS-V21 PACOTE 9F - STAGING CONTROLADO ===" -ForegroundColor Cyan
$manifestPath = ".\docs\ATLAS_POS_V21_PACOTE_9F_MANIFEST.json"
if (-not (Test-Path $manifestPath)) { throw "Manifesto 9F ausente." }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$paths = @($manifest.release_paths)
if ($paths.Count -eq 0) { throw "Manifesto 9F vazio." }

foreach ($path in $paths) {
    if (-not (Test-Path $path)) { throw "Arquivo do manifesto ausente: $path" }
    git add -- $path
    if ($LASTEXITCODE -ne 0) { throw "Falha ao adicionar ao staging: $path" }
}
Write-Host "[OK] Manifesto canonico carregado: $($paths.Count) arquivos." -ForegroundColor Green
Write-Host "[OK] Somente arquivos do manifesto 9F foram preparados para commit." -ForegroundColor Green
