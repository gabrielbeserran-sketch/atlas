$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10D - STAGING CONTROLADO ===" -ForegroundColor Cyan

$manifest = Get-Content '.\docs\ATLAS_POS_V21_MACROPACOTE_10D_MANIFEST.json' -Raw | ConvertFrom-Json
$paths = @($manifest.release_paths)
if ($paths.Count -eq 0) {
    throw "Manifesto 10D vazio."
}

foreach ($path in $paths) {
    if (-not (Test-Path $path)) {
        throw "Arquivo do manifesto ausente: $path"
    }
    git add -- $path
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao preparar staging: $path"
    }
}

Write-Host "[OK] Somente arquivos do manifesto 10D foram preparados para commit." -ForegroundColor Green
