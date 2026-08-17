$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $root
Write-Host "ATLAS V1 - PASSO 18 - Prontidão de produção" -ForegroundColor Green
$fail = $false
$required = @(
  "docs\legal\PRIVACIDADE_RASCUNHO.md",
  "docs\legal\TERMOS_RASCUNHO.md",
  "release\checklists\ANDROID_E2E_CHECKLIST.md",
  "release\checklists\PLAY_STORE_CHECKLIST.md"
)
foreach ($item in $required) {
  if (-not (Test-Path $item)) {
    Write-Error "Ausente: $item"
    $fail = $true
  }
}
if (Select-String -Path "backend\.env" -Pattern "troque-esta-chave|change_me|@localhost" -Quiet -ErrorAction SilentlyContinue) {
  Write-Warning "backend\.env contém valor de desenvolvimento. Não usar este .env em produção."
}
if ($fail) { exit 1 }
Write-Host "Estrutura de prontidão presente. Revisão humana ainda obrigatória." -ForegroundColor Green
