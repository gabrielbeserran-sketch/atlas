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
    if ([string]::IsNullOrWhiteSpace($Uri.Host)) {
        throw "BaseUrl inválida: host ausente."
    }

    return $Value.Trim().TrimEnd("/")
}

function Get-HttpStatusCode {
    param([Parameter(Mandatory = $true)]$Exception)

    try {
        if ($null -ne $Exception.Response.StatusCode) {
            return [int]$Exception.Response.StatusCode
        }
    } catch {}

    try {
        if ($null -ne $Exception.Exception.Response.StatusCode) {
            return [int]$Exception.Exception.Response.StatusCode
        }
    } catch {}

    return 0
}

function Invoke-AtlasWarmup {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$Attempts = 6
    )

    for ($Attempt = 1; $Attempt -le $Attempts; $Attempt++) {
        try {
            $Response = Invoke-RestMethod `
                -Uri $Url `
                -Method GET `
                -TimeoutSec 180

            $Status = "$($Response.status)".Trim().ToLowerInvariant()
            if ($Status -in @("ready", "ok")) {
                Write-Host "[OK] Health/readiness respondeu." -ForegroundColor Green
                return
            }

            throw "Health respondeu, mas status foi '$Status'."
        } catch {
            if ($Attempt -ge $Attempts) {
                throw "Health/readiness falhou após $Attempts tentativa(s): $($_.Exception.Message)"
            }

            $Delay = [Math]::Min(30, 5 * $Attempt)
            Write-Host `
                "Health/readiness: tentativa $Attempt/$Attempts falhou; nova tentativa em ${Delay}s..." `
                -ForegroundColor DarkYellow
            Start-Sleep -Seconds $Delay
        }
    }
}

function Test-AtlasProtectedPostRoute {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$Attempts = 4
    )

    for ($Attempt = 1; $Attempt -le $Attempts; $Attempt++) {
        try {
            $Response = Invoke-WebRequest `
                -Uri $Url `
                -Method POST `
                -ContentType "application/json" `
                -Body "{}" `
                -TimeoutSec 180 `
                -UseBasicParsing

            $Code = [int]$Response.StatusCode

            if ($Code -ge 200 -and $Code -lt 500 -and $Code -ne 404) {
                Write-Host "[OK] POST $Url respondeu HTTP $Code." -ForegroundColor Green
                return $Code
            }

            if ($Code -eq 404) {
                throw "Endpoint retornou HTTP 404."
            }

            throw "Endpoint respondeu HTTP $Code."
        } catch {
            $Code = Get-HttpStatusCode -Exception $_

            # Sem token e/ou sem corpo válido, uma rota FastAPI existente pode responder
            # 401 (não autenticado), 403 (sem permissão) ou 422 (payload incompleto).
            # Todos provam que o roteador POST foi publicado. 405 também prova que o path
            # existe, mas seria erro de contrato porque esperamos POST.
            if ($Code -in @(401, 403, 422)) {
                Write-Host `
                    "[OK] Endpoint publicado e protegido/validando (HTTP $Code)." `
                    -ForegroundColor Green
                return $Code
            }

            if ($Code -eq 405) {
                throw "O caminho existe, mas POST não está publicado (HTTP 405)."
            }

            if ($Code -eq 404) {
                if ($Attempt -ge $Attempts) {
                    throw "POST $Url ainda retorna 404 após $Attempts tentativa(s). O deploy não contém a rota."
                }

                $Delay = [Math]::Min(30, 5 * $Attempt)
                Write-Host `
                    "Endpoint ainda não publicado (404); nova tentativa em ${Delay}s..." `
                    -ForegroundColor DarkYellow
                Start-Sleep -Seconds $Delay
                continue
            }

            if ($Attempt -ge $Attempts) {
                throw "Não foi possível validar POST $Url. HTTP=$Code. $($_.Exception.Message)"
            }

            $Delay = [Math]::Min(30, 5 * $Attempt)
            Write-Host `
                "Validação do endpoint falhou; nova tentativa em ${Delay}s..." `
                -ForegroundColor DarkYellow
            Start-Sleep -Seconds $Delay
        }
    }

    throw "Validação do endpoint terminou sem resultado."
}

$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl
$HealthUrl = "$BaseUrl/health/ready"
$HandlingUrl = "$BaseUrl/livestock/handling/batch"

Write-Host "=== ATLAS POS-V21 PACOTE 2 - CONTRATO PUBLICADO ===" -ForegroundColor Cyan
Write-Host "Base de produção: $BaseUrl" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[1/2] Aquecendo e validando backend de produção" -ForegroundColor Yellow
Invoke-AtlasWarmup -Url $HealthUrl

Write-Host "[2/2] Validando rota de manejo coletivo" -ForegroundColor Yellow
$StatusCode = Test-AtlasProtectedPostRoute -Url $HandlingUrl

Write-Host ""
Write-Host "[OK] POST /api/v1/livestock/handling/batch está publicado." -ForegroundColor Green
Write-Host "Resposta de contrato sem autenticação: HTTP $StatusCode" -ForegroundColor DarkGray
Write-Host "ATLAS POS-V21 PACOTE 2: BACKEND PUBLICADO" -ForegroundColor Green
