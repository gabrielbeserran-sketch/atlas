$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10C - STAGING CONTROLADO ===" -ForegroundColor Cyan

$manifestPath = '.\docs\ATLAS_POS_V21_MACROPACOTE_10C_MANIFEST.json'
if (-not (Test-Path $manifestPath)) { throw "Manifesto 10C ausente." }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$paths = @($manifest.release_paths)
if ($paths.Count -eq 0) { throw "Manifesto 10C vazio." }

foreach ($path in $paths) {
  if (-not (Test-Path $path)) { throw "Arquivo do manifesto ausente: $path" }
  git add -- $path
  if ($LASTEXITCODE -ne 0) { throw "Falha ao preparar staging: $path" }
}
Write-Host "[OK] Manifesto canonico carregado: $($paths.Count) arquivos autorizados." -ForegroundColor Green
Write-Host "[OK] Somente arquivos do manifesto 10C foram preparados para commit." -ForegroundColor Green
