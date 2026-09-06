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

if (-not $BaseUrl.StartsWith("https://")) {
    throw "O build de produção exige uma API HTTPS."
}

Write-Host "=== ATLAS - BUILD WINDOWS / PRODUCAO ===" -ForegroundColor Cyan
Write-Host "Backend: $BaseUrl" -ForegroundColor DarkGray

& $Flutter.Source build windows --release `
    --dart-define=ATLAS_ENV=production `
    --dart-define="ATLAS_API_BASE_URL=$BaseUrl"

if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows falhou."
}

Write-Host "Release pronto em build\\windows\\x64\\runner\\Release\\projeto_atlas.exe" -ForegroundColor Green
