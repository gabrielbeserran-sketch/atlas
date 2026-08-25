$ErrorActionPreference = "Stop"
$base = "https://atlas-api-29y2.onrender.com/api/v1"
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10D - V1 RELEASE CANDIDATE ===" -ForegroundColor Cyan

$maxAttempts = 24
for ($i = 1; $i -le $maxAttempts; $i++) {
    try {
        $health = Invoke-RestMethod -Uri "$base/health/ready" -TimeoutSec 25
        if (-not $health -or $health.status -ne 'ready') {
            throw "backend ainda nao pronto"
        }
    }
    catch {
        Write-Host "Tentativa ${i}/${maxAttempts}: backend ainda indisponivel/convergindo." -ForegroundColor Yellow
        if ($i -lt $maxAttempts) { Start-Sleep -Seconds 10 }
        continue
    }

    try {
        $rc = Invoke-RestMethod -Uri "$base/health/v1-release-candidate" -TimeoutSec 25
        $c10b = Invoke-RestMethod -Uri "$base/livestock/intelligence/deployment-readiness" -TimeoutSec 25
        $c10c = Invoke-RestMethod -Uri "$base/livestock/data-quality/deployment-readiness" -TimeoutSec 25

        $checks = $rc.checks
        $ok = (
            $rc.contract_version -eq '10D' -and
            $rc.release_candidate -eq $true -and
            $checks.database_ready -eq $true -and
            $checks.schema_0050_ready -eq $true -and
            $checks.distributed_rate_limit -eq $true -and
            $checks.remote_media -eq $true -and
            $checks.backup_restore_verification -eq $true -and
            $checks.bootstrap_locked -eq $true -and
            $checks.docs_locked -eq $true -and
            $checks.auto_schema_locked -eq $true -and
            $c10b.contract_version -eq '10B' -and
            $c10c.contract_version -eq '10C' -and
            $c10c.schema_ready -eq $true
        )

        if ($ok) {
            Write-Host "[OK] Backend pronto." -ForegroundColor Green
            Write-Host "[OK] Schema 0050 confirmado." -ForegroundColor Green
            Write-Host "[OK] Rate limit distribuido ativo." -ForegroundColor Green
            Write-Host "[OK] Midia remota Supabase ativa." -ForegroundColor Green
            Write-Host "[OK] Restore verificavel disponivel." -ForegroundColor Green
            Write-Host "[OK] Bootstrap/docs/auto-schema bloqueados em producao." -ForegroundColor Green
            Write-Host "[OK] Contratos 10B e 10C preservados." -ForegroundColor Green
            Write-Host ""
            Write-Host "ATLAS POS-V21 MACROPACOTE 10D: V1 RELEASE CANDIDATE PUBLICADO" -ForegroundColor Green
            exit 0
        }

        Write-Host "Tentativa ${i}/${maxAttempts}: backend respondeu, mas readiness 10D ainda nao convergiu." -ForegroundColor Yellow
    }
    catch {
        Write-Host "Tentativa ${i}/${maxAttempts}: rota/contrato 10D ainda nao publicado." -ForegroundColor Yellow
    }

    if ($i -lt $maxAttempts) { Start-Sleep -Seconds 10 }
}

throw "10D nao convergiu no Render dentro da janela de verificacao."
