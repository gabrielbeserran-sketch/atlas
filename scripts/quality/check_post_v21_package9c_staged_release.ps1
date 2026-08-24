$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

Write-Host "=== ATLAS POS-V21 PACOTE 9C - CHECK DO STAGING ===" -ForegroundColor Cyan

$ManifestPath = "docs/ATLAS_POS_V21_PACOTE_9C_MANIFEST.json"
if (-not (Test-Path $ManifestPath -PathType Leaf)) { throw "Manifesto canônico ausente: $ManifestPath" }
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$RequiredPaths = @($Manifest.release_paths)
if ($RequiredPaths.Count -eq 0) { throw "Manifesto 9C não contém release_paths." }

$StagedPaths = @(& git -c core.pager=cat diff --cached --name-only)
if ($StagedPaths.Count -eq 0) { throw "Nenhum arquivo está no staging. Execute stage_post_v21_package9c_release.ps1." }

$Missing = @($RequiredPaths | Where-Object { $StagedPaths -notcontains $_ })
if ($Missing.Count -gt 0) {
    Write-Host "Arquivos obrigatórios ausentes do staging:" -ForegroundColor Red
    $Missing | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    throw "Staging incompleto para o Pacote 9C."
}

$Unexpected = @($StagedPaths | Where-Object { $RequiredPaths -notcontains $_ })
if ($Unexpected.Count -gt 0) {
    Write-Host "Arquivos fora do manifesto canônico 9C encontrados no staging:" -ForegroundColor Red
    $Unexpected | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    throw "Staging contaminado por arquivos que não pertencem ao Pacote 9C."
}

$DiffOutput = & git -c core.pager=cat -c core.safecrlf=false diff --cached --check 2>$null
if ($LASTEXITCODE -ne 0) {
    if ($DiffOutput) { $DiffOutput | Write-Host }
    throw "git diff --cached --check encontrou inconsistências."
}

Write-Host "[OK] Staging e checker usam o mesmo manifesto canônico." -ForegroundColor Green
Write-Host "[OK] $($StagedPaths.Count) arquivos staged; 0 inesperados; 0 ausentes." -ForegroundColor Green
Write-Host ""
Write-Host "ATLAS 9C STAGED RELEASE: APROVADO" -ForegroundColor Green
Write-Host "Backend + Flutter + gates preventivos estão preparados para o commit." -ForegroundColor Green
