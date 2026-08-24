$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

Write-Host "=== ATLAS POS-V21 PACOTE 9C - STAGING CONTROLADO ===" -ForegroundColor Cyan

$ManifestPath = "docs/ATLAS_POS_V21_PACOTE_9C_MANIFEST.json"
if (-not (Test-Path $ManifestPath -PathType Leaf)) { throw "Manifesto canônico ausente: $ManifestPath" }
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$ReleasePaths = @($Manifest.release_paths)
if ($ReleasePaths.Count -eq 0) { throw "Manifesto 9C não contém release_paths." }

foreach ($Path in $ReleasePaths) {
    if (-not (Test-Path $Path -PathType Leaf)) { throw "Arquivo obrigatório ausente: $Path" }
}

& git add -- $ReleasePaths
if ($LASTEXITCODE -ne 0) { throw "Falha ao preparar staging controlado do 9C." }

$StagedPaths = @(& git -c core.pager=cat diff --cached --name-only)
$Unexpected = @($StagedPaths | Where-Object { $ReleasePaths -notcontains $_ })
if ($Unexpected.Count -gt 0) {
    Write-Host "Arquivos inesperados já estavam no staging:" -ForegroundColor Red
    $Unexpected | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    throw "Staging contém arquivos fora do manifesto canônico 9C."
}

Write-Host "[OK] Manifesto canônico carregado: $($ReleasePaths.Count) arquivos." -ForegroundColor Green
Write-Host "[OK] Somente arquivos do manifesto 9C foram preparados para commit." -ForegroundColor Green
