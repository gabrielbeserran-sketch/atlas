$ErrorActionPreference = "Stop"
$baseUrl = "https://atlas-api-29y2.onrender.com/api/v1"

Write-Host "=== ATLAS POS-V21 PACOTE 9D - IMPLANTACAO VERIFICAVEL ===" -ForegroundColor Cyan
$lastError = $null
for ($attempt = 1; $attempt -le 6; $attempt++) {
    try {
        $health = Invoke-RestMethod -Uri "$baseUrl/health/ready" -Method Get -TimeoutSec 30
        if (-not $health) { throw "Backend sem resposta de readiness." }
        $ready = Invoke-RestMethod -Uri "$baseUrl/saas-growth/onboarding/deployment-readiness" -Method Get -TimeoutSec 30
        if (-not $ready.schema_ready -or -not $ready.farm_scoped_evidence -or -not $ready.automatic_evidence -or -not $ready.manual_step_restricted) {
            throw "Backend ainda nao expoe o contrato 9D completo."
        }
        Write-Host "[OK] Backend pronto." -ForegroundColor Green
        Write-Host "[OK] Evidencias escopadas por fazenda." -ForegroundColor Green
        Write-Host "[OK] Validacao automatica ativa." -ForegroundColor Green
        Write-Host "[OK] Passo manual restrito ao treinamento." -ForegroundColor Green
        Write-Host "ATLAS POS-V21 PACOTE 9D: BACKEND PUBLICADO" -ForegroundColor Green
        exit 0
    } catch {
        $lastError = $_
        if ($attempt -lt 6) {
            Write-Host "Tentativa $attempt/6 falhou; aguardando deploy..." -ForegroundColor Yellow
            Start-Sleep -Seconds (5 * $attempt)
        }
    }
}
throw "9D nao confirmado em producao: $lastError"
