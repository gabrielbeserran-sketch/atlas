$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $root
Write-Host "ATLAS V1 - PASSO 20 - Gate de publicação" -ForegroundColor Green
& "$root\scripts\v1\16_quality_gate.ps1"
& "$root\scripts\v1\18_production_readiness.ps1"
if (-not (Test-Path "dist\android\atlas-v1-release.aab")) {
  Write-Warning "AAB de release ainda não foi gerado."
}
Write-Host "Checklist técnico concluído. Publicação na Play Store continua sendo uma ação externa e supervisionada." -ForegroundColor Green
