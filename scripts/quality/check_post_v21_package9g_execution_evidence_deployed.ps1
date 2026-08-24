$ErrorActionPreference = "Stop"
$base = "https://atlas-api-29y2.onrender.com/api/v1"
Write-Host "=== ATLAS POS-V21 PACOTE 9G - EXECUCAO COMPROVAVEL ===" -ForegroundColor Cyan
$ready=$null
for ($i=1; $i -le 6; $i++) {
  try {
    $health = Invoke-RestMethod -Uri "$base/health/ready" -Method Get -TimeoutSec 30
    $candidate = Invoke-RestMethod -Uri "$base/business/consulting/actions/deployment-readiness" -Method Get -TimeoutSec 30
    if ($candidate.migration -eq "0048" -and $candidate.execution_evidence_required -eq $true -and $candidate.completion_actor -eq $true -and $candidate.audit_trail -eq $true) { $ready=$candidate; break }
  } catch {}
  Write-Host "Tentativa $i/6 falhou; aguardando deploy..." -ForegroundColor Yellow
  Start-Sleep -Seconds (5*$i)
}
if ($null -eq $ready) { throw "9G ainda nao esta publicado integralmente." }
Write-Host "[OK] Backend pronto." -ForegroundColor Green
Write-Host "[OK] Migration 0048 confirmada." -ForegroundColor Green
Write-Host "[OK] Evidencia obrigatoria ativa." -ForegroundColor Green
Write-Host "[OK] Executor persistido." -ForegroundColor Green
Write-Host "[OK] Trilha de auditoria ativa." -ForegroundColor Green
Write-Host "ATLAS POS-V21 PACOTE 9G: BACKEND + SCHEMA PUBLICADOS" -ForegroundColor Green
