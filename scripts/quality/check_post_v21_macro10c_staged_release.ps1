$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10C - CHECK DO STAGING ===" -ForegroundColor Cyan

$manifestPath = '.\docs\ATLAS_POS_V21_MACROPACOTE_10C_MANIFEST.json'
if (-not (Test-Path $manifestPath)) { throw "Manifesto 10C ausente." }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$declared = @($manifest.release_paths | ForEach-Object { $_ -replace '\\','/' } | Sort-Object -Unique)

$expectedChanged = @()
foreach ($path in $declared) {
  if (-not (Test-Path $path)) { throw "Arquivo declarado ausente: $path" }
  $diffForPath = @(git diff HEAD --name-only -- $path)
  if ($LASTEXITCODE -ne 0) { throw "Falha ao comparar com HEAD: $path" }
  if ($diffForPath.Count -gt 0) { $expectedChanged += $path }
}
$expectedChanged = @($expectedChanged | Sort-Object -Unique)
$staged = @(git diff --cached --name-only | ForEach-Object { $_ -replace '\\','/' } | Sort-Object -Unique)
$unexpected = @($staged | Where-Object { $declared -notcontains $_ })
$missing = @($expectedChanged | Where-Object { $staged -notcontains $_ })

if ($unexpected.Count -gt 0) {
  $unexpected | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
  throw "Staging contaminado por arquivos fora do 10C."
}
if ($missing.Count -gt 0) {
  $missing | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
  throw "Staging incompleto para o 10C."
}

git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw "git diff --cached --check reprovado." }

$unchanged = @($declared | Where-Object { $expectedChanged -notcontains $_ })
Write-Host "[OK] Manifesto: $($declared.Count) autorizados; staged: $($staged.Count); 0 inesperados; 0 alterados ausentes." -ForegroundColor Green
if ($unchanged.Count -gt 0) { Write-Host "[OK] $($unchanged.Count) arquivo(s) do manifesto ja identico(s) ao HEAD." -ForegroundColor Green }
Write-Host "ATLAS 10C STAGED RELEASE: APROVADO" -ForegroundColor Green
