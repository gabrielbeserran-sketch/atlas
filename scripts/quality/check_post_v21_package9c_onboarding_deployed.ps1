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

Write-Host "=== ATLAS POS-V21 PACOTE 9C - IMPLANTACAO ATLAS ===" -ForegroundColor Cyan

$Health = Invoke-WithRetry -Url "$BaseUrl/health/ready"
if ("$($Health.status)".ToLowerInvariant() -notin @("ready", "ok")) {
    throw "Backend não está pronto."
}
Write-Host "[OK] Backend pronto." -ForegroundColor Green

$Ready = Invoke-WithRetry -Url "$BaseUrl/saas-growth/onboarding/deployment-readiness"
if ("$($Ready.status)".ToLowerInvariant() -ne "ready") {
    throw "Readiness da implantação não retornou ready."
}
foreach ($Field in @("schema_ready", "read_api", "write_api", "persistent_progress")) {
    if ($Ready.$Field -ne $true) { throw "Readiness 9C falhou em: $Field" }
}

Write-Host "[OK] Schema onboarding_progress disponível." -ForegroundColor Green
Write-Host "[OK] Leitura remota disponível." -ForegroundColor Green
Write-Host "[OK] Gravação remota disponível." -ForegroundColor Green
Write-Host "[OK] Progresso persistente disponível." -ForegroundColor Green
Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 9C: BACKEND PUBLICADO" -ForegroundColor Green
