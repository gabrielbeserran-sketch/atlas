$ErrorActionPreference = "Stop"
$base="https://atlas-api-29y2.onrender.com/api/v1"
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10A - RESULTADO MENSURAVEL ===" -ForegroundColor Cyan
for($i=1;$i -le 8;$i++){ try { $r=Invoke-RestMethod -Uri "$base/business/consulting/actions/deployment-readiness" -TimeoutSec 20; if($r.measurable_outcomes -eq $true){ Write-Host "[OK] Backend pronto." -ForegroundColor Green; Write-Host "[OK] Migration 0049 confirmada." -ForegroundColor Green; Write-Host "[OK] Linha de base e resultado mensuravel ativos." -ForegroundColor Green; Write-Host "ATLAS POS-V21 MACROPACOTE 10A: BACKEND + SCHEMA PUBLICADOS" -ForegroundColor Green; exit 0 } } catch {} ; Write-Host "Tentativa $i/8 falhou; aguardando deploy..." -ForegroundColor Yellow; Start-Sleep -Seconds 5 }
throw "10A ainda nao publicado."
