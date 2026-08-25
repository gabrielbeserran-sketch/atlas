$ErrorActionPreference = "Stop"
$base = "https://atlas-api-29y2.onrender.com/api/v1"
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10B - INTELIGENCIA + INTEGRIDADE ===" -ForegroundColor Cyan

$maxAttempts = 18
for ($i = 1; $i -le $maxAttempts; $i++) {
  try {
    $health = Invoke-RestMethod -Uri "$base/health/ready" -TimeoutSec 25
    if (-not $health) { throw "readiness vazia" }
  } catch {
    Write-Host "Tentativa $i/$maxAttempts: backend ainda indisponível/convergindo." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    continue
  }

  try {
    $r = Invoke-RestMethod -Uri "$base/livestock/intelligence/deployment-readiness" -TimeoutSec 25
    if ($r.contract_version -eq '10B' -and $r.single_source -eq $true -and $r.farm_context_guard -eq $true -and $r.priority_position_contract -eq $true -and $r.global_integrity_audit -eq $true) {
      Write-Host "[OK] Backend pronto." -ForegroundColor Green
      Write-Host "[OK] Contrato de inteligência 10B publicado." -ForegroundColor Green
      Write-Host "[OK] Fonte operacional única declarada." -ForegroundColor Green
      Write-Host "[OK] Proteção de contexto de fazenda ativa." -ForegroundColor Green
      Write-Host "[OK] Contrato de posição das prioridades ativo." -ForegroundColor Green
      Write-Host "ATLAS POS-V21 MACROPACOTE 10B: BACKEND PUBLICADO" -ForegroundColor Green
      exit 0
    }
    Write-Host "Tentativa $i/$maxAttempts: backend respondeu, mas contrato 10B ainda não convergiu." -ForegroundColor Yellow
  } catch {
    Write-Host "Tentativa $i/$maxAttempts: rota 10B ainda não publicada." -ForegroundColor Yellow
  }
  Start-Sleep -Seconds 10
}
throw "10B não convergiu no Render dentro da janela de verificação."
