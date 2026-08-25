$ErrorActionPreference = "Stop"
$base = "https://atlas-api-29y2.onrender.com/api/v1"
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10C - RASTREABILIDADE + DADOS + UX ===" -ForegroundColor Cyan

$maxAttempts = 18
for ($i = 1; $i -le $maxAttempts; $i++) {
  try {
    $health = Invoke-RestMethod -Uri "$base/health/ready" -TimeoutSec 25
    if (-not $health) { throw "readiness vazia" }
  }
  catch {
    Write-Host "Tentativa ${i}/${maxAttempts}: backend ainda indisponivel/convergindo." -ForegroundColor Yellow
    if ($i -lt $maxAttempts) { Start-Sleep -Seconds 10 }
    continue
  }

  try {
    $r = Invoke-RestMethod -Uri "$base/livestock/data-quality/deployment-readiness" -TimeoutSec 25
    $ok = (
      $r.contract_version -eq '10C' -and
      $r.schema_ready -eq $true -and
      $r.utf8_sanitized -eq $true -and
      $r.runtime_normalization -eq $true -and
      $r.animal_traceability -eq $true -and
      $r.farm_scope_guard -eq $true
    )
    if ($ok) {
      Write-Host "[OK] Backend pronto." -ForegroundColor Green
      Write-Host "[OK] Migration 0050 confirmada." -ForegroundColor Green
      Write-Host "[OK] Saneamento UTF-8 persistido confirmado." -ForegroundColor Green
      Write-Host "[OK] Normalizacao em runtime ativa." -ForegroundColor Green
      Write-Host "[OK] Rastreabilidade da Central do Animal ativa." -ForegroundColor Green
      Write-Host "[OK] Protecao de escopo de fazenda ativa." -ForegroundColor Green
      Write-Host "ATLAS POS-V21 MACROPACOTE 10C: BACKEND + SCHEMA PUBLICADOS" -ForegroundColor Green
      exit 0
    }
    Write-Host "Tentativa ${i}/${maxAttempts}: backend respondeu, mas contrato 10C ainda nao convergiu." -ForegroundColor Yellow
  }
  catch {
    Write-Host "Tentativa ${i}/${maxAttempts}: rota/schema 10C ainda nao publicado." -ForegroundColor Yellow
  }

  if ($i -lt $maxAttempts) { Start-Sleep -Seconds 10 }
}
throw "10C nao convergiu no Render dentro da janela de verificacao."
