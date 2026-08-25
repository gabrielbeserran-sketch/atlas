$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
$manifestPath = ".\docs\ATLAS_POS_V21_11A_MANIFEST.json"
if (-not (Test-Path $manifestPath)) { throw "Manifesto 11A ausente." }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$paths = @($manifest.release_paths | Sort-Object -Unique)
foreach ($path in $paths) {
    if (-not (Test-Path $path)) { throw "Arquivo do manifesto ausente: $path" }
    git add -- $path
    if ($LASTEXITCODE -ne 0) { throw "Falha ao adicionar: $path" }
}
Write-Host "[OK] Staging 11A preparado pelo manifesto canônico." -ForegroundColor Green
