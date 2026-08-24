$ErrorActionPreference = "Stop"
$baseUrl = "https://atlas-api-29y2.onrender.com/api/v1"

Write-Host "=== ATLAS POS-V21 PACOTE 9F - PLANO CONSULTIVO + AGENDA ===" -ForegroundColor Cyan
$lastError = $null
for ($attempt = 1; $attempt -le 6; $attempt++) {
    try {
        $health = Invoke-RestMethod -Uri "$baseUrl/health/ready" -Method Get -TimeoutSec 30
        if (-not $health) { throw "Backend sem resposta de readiness." }
        $ready = Invoke-RestMethod -Uri "$baseUrl/business/consulting/actions/deployment-readiness" -Method Get -TimeoutSec 30
        if (-not $ready.schema_ready -or -not $ready.idempotency -or -not $ready.agenda_sync -or -not $ready.bidirectional_completion -or $ready.migration -ne '0047') {
            throw "Backend/schema ainda nao expoe o contrato 9F completo."
        }
        Write-Host "[OK] Backend pronto." -ForegroundColor Green
        Write-Host "[OK] Migration 0047 confirmada." -ForegroundColor Green
        Write-Host "[OK] Idempotencia do plano consultivo ativa." -ForegroundColor Green
        Write-Host "[OK] Integracao com a Agenda ativa." -ForegroundColor Green
        Write-Host "[OK] Conclusao bidirecional ativa." -ForegroundColor Green
        Write-Host "ATLAS POS-V21 PACOTE 9F: BACKEND + SCHEMA PUBLICADOS" -ForegroundColor Green
        exit 0
    } catch {
        $lastError = $_
        if ($attempt -lt 6) {
            Write-Host "Tentativa $attempt/6 falhou; aguardando deploy..." -ForegroundColor Yellow
            Start-Sleep -Seconds (5 * $attempt)
        }
    }
}
throw "9F nao confirmado em producao: $lastError"
