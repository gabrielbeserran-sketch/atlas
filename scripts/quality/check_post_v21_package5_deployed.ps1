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
$HealthUrl = "$BaseUrl/health/ready"
$BulletinUrl = "$BaseUrl/bulletins/readiness"

Write-Host "=== ATLAS POS-V21 PACOTE 5 - DEPLOY ===" -ForegroundColor Cyan
Write-Host "[1/2] Backend /health/ready" -ForegroundColor Yellow
$Health = Invoke-WithRetry -Url $HealthUrl
if ("$($Health.status)".ToLowerInvariant() -notin @("ready", "ok")) {
    throw "Health/readiness não retornou status pronto."
}
Write-Host "[OK] Backend pronto." -ForegroundColor Green

Write-Host "[2/2] Contrato + schema dos boletins" -ForegroundColor Yellow
$Bulletins = Invoke-WithRetry -Url $BulletinUrl
if ("$($Bulletins.status)".ToLowerInvariant() -ne "ready") {
    throw "Readiness dos boletins não retornou ready."
}
if ($Bulletins.schema_ready -ne $true) {
    throw "Migration 0042 ainda não está disponível no banco."
}

Write-Host "[OK] Rota de boletins publicada." -ForegroundColor Green
Write-Host "[OK] Migration 0042 confirmada no banco." -ForegroundColor Green

if ($Bulletins.whatsapp_configured -eq $true) {
    Write-Host "[OK] WhatsApp Business configurado." -ForegroundColor Green
} else {
    Write-Host "[INFO] WhatsApp Business ainda não configurado; nenhum envio automático será fingido." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 5: BACKEND + SCHEMA PUBLICADOS" -ForegroundColor Green
