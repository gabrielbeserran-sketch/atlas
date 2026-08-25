$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
$m = Get-Content .\docs\ATLAS_POS_V21_MACROPACOTE_10A_MANIFEST.json -Raw | ConvertFrom-Json
$declared=@($m.release_paths | ForEach-Object { $_ -replace '\\','/' } | Sort-Object -Unique)
$expected=@(); foreach($p in $declared){ if(-not(Test-Path $p)){throw "Ausente: $p"}; $d=@(git diff HEAD --name-only -- $p); if($d.Count -gt 0){$expected += $p} }
$staged=@(git diff --cached --name-only | ForEach-Object { $_ -replace '\\','/' } | Sort-Object -Unique)
$unexpected=@($staged | Where-Object { $declared -notcontains $_ }); $missing=@($expected | Where-Object { $staged -notcontains $_ })
if($unexpected.Count -gt 0){$unexpected|%{Write-Host $_ -ForegroundColor Red}; throw "Staging contaminado."}
if($missing.Count -gt 0){$missing|%{Write-Host $_ -ForegroundColor Red}; throw "Staging incompleto."}
git diff --cached --check; if($LASTEXITCODE -ne 0){throw "git diff --cached --check reprovado."}
Write-Host "[OK] Manifesto: $($declared.Count) autorizados; staged: $($staged.Count); 0 inesperados; 0 alterados ausentes." -ForegroundColor Green
Write-Host "ATLAS 10A STAGED RELEASE: APROVADO" -ForegroundColor Green
