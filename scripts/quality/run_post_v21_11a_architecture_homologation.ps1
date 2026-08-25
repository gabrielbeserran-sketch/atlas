$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS 11A - ARCHITECTURE GOVERNANCE ===" -ForegroundColor Cyan
python .\tools\atlas_11a_architecture_governance_gate.py
if ($LASTEXITCODE -ne 0) { throw "Gate 11A reprovado." }
python .\tools\atlas_architecture_map.py --lib .\lib --out .\docs\architecture\_11a_runtime_check
if ($LASTEXITCODE -ne 0) { throw "Regeneracao do mapa arquitetural falhou." }
$runtime = Get-Content .\docs\architecture\_11a_runtime_check\atlas_architecture_map.json -Raw | ConvertFrom-Json
$baseline = Get-Content .\docs\architecture\11A\generated\atlas_architecture_map_11a.json -Raw | ConvertFrom-Json
if ($runtime.summary.duplicate_public_declarations -gt $baseline.summary.duplicate_public_declarations) { throw "Novas duplicidades arquiteturais detectadas." }
if ($runtime.summary.likely_orphans -gt $baseline.summary.likely_orphans) { throw "Novos candidatos a orfao detectados." }
Remove-Item .\docs\architecture\_11a_runtime_check -Recurse -Force
git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check reprovado." }
Write-Host "ATLAS 11A: ARCHITECTURE GOVERNANCE APROVADA" -ForegroundColor Green
Write-Host "Nenhum arquivo de runtime foi movido ou removido." -ForegroundColor Green
