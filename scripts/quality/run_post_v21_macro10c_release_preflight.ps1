$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10C - PREFLIGHT ===" -ForegroundColor Cyan

$releaseScripts = @(
  '.\scripts\quality\run_post_v21_macro10c_homologation.ps1',
  '.\scripts\quality\run_post_v21_macro10c_release_preflight.ps1',
  '.\scripts\quality\stage_post_v21_macro10c_release.ps1',
  '.\scripts\quality\check_post_v21_macro10c_staged_release.ps1',
  '.\scripts\quality\check_post_v21_macro10c_deployed.ps1'
)
foreach ($script in $releaseScripts) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $script), [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    throw "Sintaxe PowerShell reprovada: $script"
  }
}
Write-Host "[OK] Sintaxe PowerShell validada." -ForegroundColor Green

python .\tools\atlas_post_v21_macro10c_traceability_data_ux_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate 10C reprovado no preflight." }

git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check encontrou inconsistencias." }

Write-Host "ATLAS POS-V21 MACROPACOTE 10C: PREFLIGHT APROVADO" -ForegroundColor Green
