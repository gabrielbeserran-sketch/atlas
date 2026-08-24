param(
    [string]$BaseUrl = "https://atlas-api-29y2.onrender.com/api/v1"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Assert-AtlasBaseUrl {
    param([Parameter(Mandatory = $true)][string]$Value)
    $Value = $Value.Trim().TrimEnd("/")
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.StartsWith("-")) {
        throw "BaseUrl inválida."
    }
    try { $Uri = [System.Uri]$Value } catch { throw "BaseUrl inválida." }
    if (-not $Uri.IsAbsoluteUri -or $Uri.Scheme -notin @("http", "https")) {
        throw "BaseUrl precisa ser HTTP/HTTPS absoluta."
    }
    return $Value
}

function Invoke-WithRetry {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$Attempts = 6
    )
    for ($Attempt = 1; $Attempt -le $Attempts; $Attempt++) {
        try {
            return Invoke-RestMethod -Uri $Url -Method GET -TimeoutSec 180
        } catch {
            if ($Attempt -ge $Attempts) { throw }
            $Delay = [Math]::Min(30, 5 * $Attempt)
            Write-Host "Tentativa $Attempt/$Attempts falhou; repetindo em ${Delay}s..." -ForegroundColor DarkYellow
            Start-Sleep -Seconds $Delay
        }
    }
}

$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl

Write-Host "=== ATLAS POS-V21 PACOTE 9A - CONTATO VETERINARIO ===" -ForegroundColor Cyan

$Health = Invoke-WithRetry -Url "$BaseUrl/health/ready"
if ("$($Health.status)".ToLowerInvariant() -notin @("ready", "ok")) {
    throw "Backend não está pronto."
}
Write-Host "[OK] Backend pronto." -ForegroundColor Green

$Ready = Invoke-WithRetry -Url "$BaseUrl/consultancy/deployment-readiness"
if ("$($Ready.status)".ToLowerInvariant() -ne "ready") {
    throw "Readiness da consultoria não retornou ready."
}
if ($Ready.schema_ready -ne $true) {
    throw "Migration 0044 ainda não está disponível."
}
if ($Ready.farm_scoped -ne $true) {
    throw "Contato da consultoria não está isolado por fazenda."
}
if ($Ready.hardcoded_flutter_contact -ne $false) {
    throw "Contrato de deploy reportou contato hardcoded."
}

Write-Host "[OK] Rota /consultancy publicada." -ForegroundColor Green
Write-Host "[OK] Migration 0044 confirmada." -ForegroundColor Green
Write-Host "[OK] Contato por fazenda." -ForegroundColor Green
Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 9A: BACKEND + SCHEMA PUBLICADOS" -ForegroundColor Green
