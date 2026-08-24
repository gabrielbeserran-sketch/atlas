$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))

$manifest = Get-Content -Raw -Encoding UTF8 ".\docs\ATLAS_POS_V21_PACOTE_9E_MANIFEST.json" | ConvertFrom-Json
$releasePaths = @($manifest.release_paths)
$staged = @(git diff --cached --name-only)
$unexpected = @($staged | Where-Object { $_ -notin $releasePaths })
$missing = @($releasePaths | Where-Object { $_ -notin $staged })

if ($unexpected.Count -gt 0) { throw "Arquivos inesperados no staging: $($unexpected -join ', ')" }
if ($missing.Count -gt 0) { throw "Arquivos obrigatorios ausentes no staging: $($missing -join ', ')" }

git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw "git diff --cached --check encontrou inconsistencias." }

Write-Host "[OK] Staging e checker usam o mesmo manifesto canonico 9E." -ForegroundColor Green
Write-Host "[OK] $($staged.Count) arquivos staged; 0 inesperados; 0 ausentes." -ForegroundColor Green
Write-Host "ATLAS 9E STAGED RELEASE: APROVADO" -ForegroundColor Green
