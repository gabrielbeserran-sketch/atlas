$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Write-Host "ATLAS V1 - PASSO 11 - Auditoria de dashboards" -ForegroundColor Green
$patterns = @(
  "mock", "demo", "fixture", "fake", "sampleData", "hardcoded"
)
$matches = @()
foreach ($pattern in $patterns) {
  $found = Get-ChildItem "$root\lib" -Recurse -Filter *.dart |
    Select-String -Pattern $pattern -SimpleMatch -CaseSensitive:$false
  if ($found) { $matches += $found }
}
$out = Join-Path $root "release\checklists\dashboard_mock_candidates.txt"
$matches | ForEach-Object { "$($_.Path):$($_.LineNumber): $($_.Line.Trim())" } |
  Set-Content -Encoding UTF8 $out
Write-Host "Relatório: $out"
Write-Host "Candidatos encontrados: $($matches.Count)"
Write-Host "Observação: ocorrência textual não significa automaticamente dado fictício."
