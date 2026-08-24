$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))

$manifest = Get-Content -Raw -Encoding UTF8 ".\docs\ATLAS_POS_V21_PACOTE_9E_MANIFEST.json" | ConvertFrom-Json
$releasePaths = @($manifest.release_paths)
if ($releasePaths.Count -eq 0) { throw "Manifesto 9E vazio." }

foreach ($path in $releasePaths) {
    if (-not (Test-Path $path -PathType Leaf)) { throw "Arquivo do manifesto ausente: $path" }
}

git add -- $releasePaths
if ($LASTEXITCODE -ne 0) { throw "Falha ao preparar staging 9E." }

$staged = @(git diff --cached --name-only)
$unexpected = @($staged | Where-Object { $_ -notin $releasePaths })
$missing = @($releasePaths | Where-Object { $_ -notin $staged })
if ($unexpected.Count -gt 0) { throw "Staging contem arquivo fora do manifesto 9E: $($unexpected -join ', ')" }
if ($missing.Count -gt 0) { throw "Arquivos do 9E ausentes no staging: $($missing -join ', ')" }

Write-Host "[OK] Manifesto canonico 9E carregado: $($releasePaths.Count) arquivos." -ForegroundColor Green
Write-Host "[OK] Somente arquivos do pacote 9E foram preparados para commit." -ForegroundColor Green
