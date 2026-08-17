$checks = @(
    "O ícone Atlas aparece no celular",
    "O aplicativo abre sem fechar sozinho",
    "A tela de login aparece",
    "O login real funciona",
    "A empresa e a fazenda são carregadas",
    "O módulo Rebanho abre",
    "Uma operação de campo pode ser registrada",
    "A Central Offline abre",
    "O aplicativo fecha e reabre mantendo a sessão",
    "O aplicativo mostra erro controlado quando o backend é desligado"
)
$failed = @()
foreach ($check in $checks) {
    $answer = Read-Host "$check? (s/n)"
    if ($answer.Trim().ToLower() -ne "s") { $failed += $check }
}
if ($failed.Count -gt 0) {
    Write-Host "TESTE NÃO APROVADO:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    exit 1
}
Write-Host "PASSOS 16-20 OK: Atlas Android 1.0 aprovado no primeiro dispositivo real." -ForegroundColor Green
