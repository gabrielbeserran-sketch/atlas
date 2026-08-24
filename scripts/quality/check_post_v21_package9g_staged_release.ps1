$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 PACOTE 9G - CHECK DO STAGING ===" -ForegroundColor Cyan
$manifest = Get-Content ".\docs\ATLAS_POS_V21_PACOTE_9G_MANIFEST.json" -Raw | ConvertFrom-Json
$declared = @($manifest.release_paths | ForEach-Object { $_ -replace '\\','/' } | Sort-Object -Unique)
$expected = @()
foreach ($path in $declared) {
  if (-not (Test-Path $path)) { throw "Arquivo do manifesto ausente: $path" }
  $diff = @(git diff HEAD --name-only -- $path)
  if ($diff.Count -gt 0) { $expected += $path }
}
$expected = @($expected | Sort-Object -Unique)
$staged = @(git diff --cached --name-only | ForEach-Object { $_ -replace '\\','/' } | Sort-Object -Unique)
$unexpected = @($staged | Where-Object { $declared -notcontains $_ })
$missing = @($expected | Where-Object { $staged -notcontains $_ })
if ($unexpected.Count -gt 0) { $unexpected | ForEach-Object { Write-Host $_ -ForegroundColor Red }; throw "Staging contaminado para 9G." }
if ($missing.Count -gt 0) { $missing | ForEach-Object { Write-Host $_ -ForegroundColor Red }; throw "Staging incompleto para 9G." }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw "git diff --cached --check encontrou inconsistencias." }
Write-Host "[OK] Manifesto: $($declared.Count) autorizados; staged: $($staged.Count); 0 inesperados; 0 alterados ausentes." -ForegroundColor Green
Write-Host "ATLAS 9G STAGED RELEASE: APROVADO" -ForegroundColor Green
