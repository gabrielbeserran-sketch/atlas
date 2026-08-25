$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
$manifestPath = ".\docs\ATLAS_POS_V21_11A_MANIFEST.json"
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$declared = @($manifest.release_paths | ForEach-Object { $_ -replace '\\','/' } | Sort-Object -Unique)
$staged = @(git diff --cached --name-only | ForEach-Object { $_ -replace '\\','/' } | Sort-Object -Unique)
$expected = @()
foreach ($path in $declared) {
    $diff = @(git diff HEAD --name-only -- $path)
    if ($diff.Count -gt 0) { $expected += $path }
}
$expected = @($expected | Sort-Object -Unique)
$unexpected = @($staged | Where-Object { $declared -notcontains $_ })
$missing = @($expected | Where-Object { $staged -notcontains $_ })
if ($unexpected.Count -gt 0) { $unexpected | ForEach-Object { Write-Host $_ -ForegroundColor Red }; throw "Staging 11A contaminado." }
if ($missing.Count -gt 0) { $missing | ForEach-Object { Write-Host $_ -ForegroundColor Red }; throw "Staging 11A incompleto." }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw "git diff --cached --check reprovado." }
Write-Host "[OK] Manifesto autorizado: $($declared.Count); staged: $($staged.Count); 0 inesperados; 0 alterados ausentes." -ForegroundColor Green
Write-Host "ATLAS 11A STAGED RELEASE: APROVADO" -ForegroundColor Green
