$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

function Require($Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name não encontrado no PATH."
    }
}

Write-Host "=== ATLAS ANDROID RC - PREFLIGHT ===" -ForegroundColor Cyan
Require "flutter"
Require "dart"

flutter doctor -v
if ($LASTEXITCODE -ne 0) {
    throw "flutter doctor encontrou problema."
}

flutter devices
if ($LASTEXITCODE -ne 0) {
    throw "Não foi possível consultar dispositivos."
}

$manifest = Join-Path $ProjectRoot "android\app\src\main\AndroidManifest.xml"
if (-not (Test-Path $manifest)) {
    throw "AndroidManifest.xml não encontrado."
}

$gradle = Join-Path $ProjectRoot "android\app\build.gradle.kts"
if (-not (Test-Path $gradle)) {
    $gradle = Join-Path $ProjectRoot "android\app\build.gradle"
}
if (-not (Test-Path $gradle)) {
    throw "Gradle do app Android não encontrado."
}

Write-Host "AndroidManifest: OK" -ForegroundColor Green
Write-Host "Gradle app: OK" -ForegroundColor Green
Write-Host ""
Write-Host "PREFLIGHT ANDROID RC: OK" -ForegroundColor Green
