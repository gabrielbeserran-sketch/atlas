$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 PACOTE 9G - STAGING CONTROLADO ===" -ForegroundColor Cyan
$manifest = Get-Content ".\docs\ATLAS_POS_V21_PACOTE_9G_MANIFEST.json" -Raw | ConvertFrom-Json
foreach ($path in $manifest.release_paths) { git add -- $path }
if ($LASTEXITCODE -ne 0) { throw "Falha no staging controlado 9G." }
Write-Host "[OK] Manifesto canonico carregado: $($manifest.release_paths.Count) arquivos." -ForegroundColor Green
Write-Host "[OK] Somente arquivos do manifesto 9G foram preparados para commit." -ForegroundColor Green
