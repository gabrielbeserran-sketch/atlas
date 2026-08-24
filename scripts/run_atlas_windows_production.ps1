param(
    [string]$BaseUrl = "https://atlas-api-29y2.onrender.com/api/v1"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $ProjectRoot

$Flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $Flutter) {
    throw "Flutter não encontrado no PATH."
}

Write-Host "=== ATLAS - WINDOWS / PRODUCAO ===" -ForegroundColor Cyan
Write-Host "Backend: $BaseUrl" -ForegroundColor DarkGray

& $Flutter.Source pub get
if ($LASTEXITCODE -ne 0) {
    throw "flutter pub get falhou."
}

& $Flutter.Source run `
    -d windows `
    --dart-define=ATLAS_ENV=production `
    --dart-define="ATLAS_API_BASE_URL=$BaseUrl"

if ($LASTEXITCODE -ne 0) {
    throw "flutter run -d windows falhou."
}
