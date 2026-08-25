$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
$m = Get-Content .\docs\ATLAS_POS_V21_MACROPACOTE_10A_MANIFEST.json -Raw | ConvertFrom-Json
foreach ($p in $m.release_paths) { if (Test-Path $p) { git add -- $p } else { throw "Arquivo do manifesto ausente: $p" } }
Write-Host "[OK] Somente arquivos do manifesto 10A foram preparados para commit." -ForegroundColor Green
