param([switch]$SkipMarco5)

. "$PSScriptRoot\atlas_android_common.ps1"
$root = Get-AtlasRoot
Set-Location $root

Assert-Command flutter
Assert-Command dart
Assert-Java17
Assert-AndroidApi36

if (-not $SkipMarco5) {
    & "$root\scripts\quality\run_marco5_final_gate.ps1"
    if ($LASTEXITCODE -ne 0) { throw "Marco 5 regrediu." }
}

flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get falhou." }

$python = "$root\backend\.venv\Scripts\python.exe"
& $python "$root\scripts\quality\atlas_marco6_dependency_lock.py" --promote
if ($LASTEXITCODE -ne 0) { throw "Dependency lock não pôde ser promovido." }

dart format --output=none --set-exit-if-changed lib test
if ($LASTEXITCODE -ne 0) { throw "dart format falhou." }

flutter analyze
if ($LASTEXITCODE -ne 0) { throw "flutter analyze falhou." }

flutter test
if ($LASTEXITCODE -ne 0) { throw "flutter test falhou." }

& $python "$root\scripts\quality\atlas_marco6_dependency_lock.py"
if ($LASTEXITCODE -ne 0) { throw "Dependency lock divergiu." }

& $python "$root\scripts\quality\atlas_marco6_android_contract.py"
if ($LASTEXITCODE -ne 0) { throw "Contrato Android falhou." }

Write-Host "ATLAS MARCO 6 PROJECT VALIDATION: APROVADO" -ForegroundColor Green
