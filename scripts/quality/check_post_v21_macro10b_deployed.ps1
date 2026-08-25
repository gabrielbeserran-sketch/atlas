$ErrorActionPreference = "Stop"

$base = "https://atlas-api-29y2.onrender.com/api/v1"

Write-Host "=== ATLAS POS-V21 MACROPACOTE 10B - INTELIGENCIA + INTEGRIDADE ===" -ForegroundColor Cyan

$maxAttempts = 18

for ($i = 1; $i -le $maxAttempts; $i++) {
    try {
        $health = Invoke-RestMethod `
            -Uri "$base/health/ready" `
            -TimeoutSec 25

        if (-not $health) {
            throw "readiness vazia"
        }
    }
    catch {
        Write-Host "Tentativa ${i}/${maxAttempts}: backend ainda indisponivel/convergindo." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        continue
    }

    try {
        $r = Invoke-RestMethod `
            -Uri "$base/livestock/intelligence/deployment-readiness" `
            -TimeoutSec 25

        $contractOk = $r.contract_version -eq "10B"
        $singleSourceOk = $r.single_source -eq $true
        $farmContextOk = $r.farm_context_guard -eq $true
        $priorityPositionOk = $r.priority_position_contract -eq $true
        $globalIntegrityOk = $r.global_integrity_audit -eq $true

        if (
            $contractOk -and
            $singleSourceOk -and
            $farmContextOk -and
            $priorityPositionOk -and
            $globalIntegrityOk
        ) {
            Write-Host "[OK] Backend pronto." -ForegroundColor Green
            Write-Host "[OK] Contrato de inteligencia 10B publicado." -ForegroundColor Green
            Write-Host "[OK] Fonte operacional unica declarada." -ForegroundColor Green
            Write-Host "[OK] Protecao de contexto de fazenda ativa." -ForegroundColor Green
            Write-Host "[OK] Contrato de posicao das prioridades ativo." -ForegroundColor Green
            Write-Host "[OK] Auditoria global de integridade ativa." -ForegroundColor Green
            Write-Host ""
            Write-Host "ATLAS POS-V21 MACROPACOTE 10B: BACKEND PUBLICADO" -ForegroundColor Green
            exit 0
        }

        Write-Host "Tentativa ${i}/${maxAttempts}: backend respondeu, mas contrato 10B ainda nao convergiu." -ForegroundColor Yellow

        if (-not $contractOk) {
            Write-Host "  - contract_version atual: $($r.contract_version)" -ForegroundColor DarkYellow
        }

        if (-not $singleSourceOk) {
            Write-Host "  - single_source ainda nao confirmado." -ForegroundColor DarkYellow
        }

        if (-not $farmContextOk) {
            Write-Host "  - farm_context_guard ainda nao confirmado." -ForegroundColor DarkYellow
        }

        if (-not $priorityPositionOk) {
            Write-Host "  - priority_position_contract ainda nao confirmado." -ForegroundColor DarkYellow
        }

        if (-not $globalIntegrityOk) {
            Write-Host "  - global_integrity_audit ainda nao confirmado." -ForegroundColor DarkYellow
        }
    }
    catch {
        Write-Host "Tentativa ${i}/${maxAttempts}: rota 10B ainda nao publicada ou indisponivel." -ForegroundColor Yellow
    }

    if ($i -lt $maxAttempts) {
        Start-Sleep -Seconds 10
    }
}

throw "10B nao convergiu no Render dentro da janela de verificacao."
