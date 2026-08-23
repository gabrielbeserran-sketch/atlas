param(
    [string]$BaseUrl = "https://atlas-api-29y2.onrender.com/api/v1"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Assert-AtlasBaseUrl {
    param([Parameter(Mandatory = $true)][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "BaseUrl vazia."
    }
    if ($Value.Trim().StartsWith("-")) {
        throw "BaseUrl inválida: '$Value'."
    }
    try {
        $Uri = [System.Uri]$Value
    } catch {
        throw "BaseUrl inválida: '$Value'."
    }
    if (-not $Uri.IsAbsoluteUri -or $Uri.Scheme -notin @("http", "https")) {
        throw "BaseUrl precisa ser HTTP/HTTPS absoluta."
    }
    return $Value.Trim().TrimEnd("/")
}

function Invoke-WithRetry {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$Attempts = 6
    )
    for ($Attempt = 1; $Attempt -le $Attempts; $Attempt++) {
        try {
            return Invoke-RestMethod `
                -Uri $Url `
                -Method GET `
                -TimeoutSec 180
        } catch {
            if ($Attempt -ge $Attempts) { throw }
            $Delay = [Math]::Min(30, 5 * $Attempt)
            Write-Host `
                "Tentativa $Attempt/$Attempts falhou; repetindo em ${Delay}s..." `
                -ForegroundColor DarkYellow
            Start-Sleep -Seconds $Delay
        }
    }
}

$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl

Write-Host "=== ATLAS POS-V21 PACOTE 8A - CAMERA DA ENTRADA ===" -ForegroundColor Cyan

Write-Host "[1/2] Backend /health/ready" -ForegroundColor Yellow
$Health = Invoke-WithRetry -Url "$BaseUrl/health/ready"
if ("$($Health.status)".ToLowerInvariant() -notin @("ready", "ok")) {
    throw "Health/readiness não retornou status pronto."
}
Write-Host "[OK] Backend pronto." -ForegroundColor Green

Write-Host "[2/2] Contrato + schema da câmera" -ForegroundColor Yellow
$Camera = Invoke-WithRetry -Url "$BaseUrl/security-camera/deployment-readiness"
if ("$($Camera.status)".ToLowerInvariant() -ne "ready") {
    throw "Readiness da câmera não retornou ready."
}
if ($Camera.schema_ready -ne $true) {
    throw "Migration 0043 ainda não está disponível no banco."
}
if ($Camera.iot_ingest_key_configured -ne $true) {
    throw "Chave segura de ingestão IoT não está configurada."
}

Write-Host "[OK] Rota da câmera publicada." -ForegroundColor Green
Write-Host "[OK] Migration 0043 confirmada." -ForegroundColor Green
Write-Host "[OK] Ingestão IoT protegida." -ForegroundColor Green

if ($Camera.whatsapp_security_alert_configured -eq $true) {
    Write-Host "[OK] Template de segurança do WhatsApp configurado." -ForegroundColor Green
} else {
    Write-Host "[INFO] Template de segurança do WhatsApp ainda não configurado; eventos serão persistidos sem fingir envio." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 8A: BACKEND + SCHEMA PUBLICADOS" -ForegroundColor Green
