$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Write-Host "ATLAS V1 - PASSO 12 - Inventário de IA" -ForegroundColor Green
$files = Get-ChildItem "$root\lib\features" -Recurse -Filter *.dart |
  Where-Object { $_.FullName -match '(ai|intelligence|predict|brain|copilot|agent)' }
$out = Join-Path $root "release\checklists\ai_v1_inventory.txt"
$files.FullName | Sort-Object | Set-Content -Encoding UTF8 $out
Write-Host "Componentes de IA encontrados: $($files.Count)"
Write-Host "Inventário salvo em: $out"
Write-Host "Regra V1: IA orienta; ações críticas exigem confirmação humana."
