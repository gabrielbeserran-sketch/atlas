$ErrorActionPreference = "Stop"
$baseUrl = "https://atlas-api-29y2.onrender.com/api/v1"

Write-Host "=== ATLAS POS-V21 PACOTE 9E - ONBOARDING POR FAZENDA ===" -ForegroundColor Cyan
$lastError = $null
for ($attempt = 1; $attempt -le 6; $attempt++) {
    try {
        $health = Invoke-RestMethod -Uri "$baseUrl/health/ready" -Method Get -TimeoutSec 30
        if (-not $health) { throw "Backend sem resposta de readiness." }
        $ready = Invoke-RestMethod -Uri "$baseUrl/saas-growth/onboarding/deployment-readiness" -Method Get -TimeoutSec 30
        if (-not $ready.schema_ready -or -not $ready.farm_scoped_manual_progress -or -not $ready.legacy_progress_migration -or $ready.migration -ne '0046') {
            throw "Backend/schema ainda nao expoe o contrato 9E completo."
        }
        Write-Host "[OK] Backend pronto." -ForegroundColor Green
        Write-Host "[OK] Migration 0046 confirmada." -ForegroundColor Green
        Write-Host "[OK] Progresso manual isolado por fazenda." -ForegroundColor Green
        Write-Host "[OK] Compatibilidade com registros legados ativa." -ForegroundColor Green
        Write-Host "ATLAS POS-V21 PACOTE 9E: BACKEND + SCHEMA PUBLICADOS" -ForegroundColor Green
        exit 0
    } catch {
        $lastError = $_
        if ($attempt -lt 6) {
            Write-Host "Tentativa $attempt/6 falhou; aguardando deploy..." -ForegroundColor Yellow
            Start-Sleep -Seconds (5 * $attempt)
        }
    }
}
throw "9E nao confirmado em producao: $lastError"
