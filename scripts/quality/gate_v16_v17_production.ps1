param(
    [string]$BaseUrl = "https://atlas-api-29y2.onrender.com/api/v1",
    [string]$FarmName = "Fazenda Atlas Producao",
    [int]$MaxAttempts = 5,
    [int]$RequestTimeoutSec = 180
)

$ErrorActionPreference = "Stop"

function Assert-AtlasBaseUrl {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "BaseUrl vazia. Informe uma URL HTTP/HTTPS absoluta."
    }

    if ($Value.Trim().StartsWith("-")) {
        throw "BaseUrl inválida: '$Value'. Um nome de parâmetro foi recebido como valor. Verifique o encaminhamento de parâmetros do script chamador."
    }

    try {
        $Uri = [System.Uri]$Value
    } catch {
        throw "BaseUrl inválida: '$Value'. Não foi possível interpretar a URL."
    }

    if (-not $Uri.IsAbsoluteUri) {
        throw "BaseUrl inválida: '$Value'. A URL precisa ser absoluta."
    }

    if ($Uri.Scheme -notin @("http", "https")) {
        throw "BaseUrl inválida: '$Value'. Use http ou https."
    }

    if ([string]::IsNullOrWhiteSpace($Uri.Host)) {
        throw "BaseUrl inválida: '$Value'. Host ausente."
    }

    return $Value.Trim().TrimEnd("/")
}

$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl
$ProgressPreference = "SilentlyContinue"

$pass = 0
$warn = 0
$fail = 0

function Result($Status, $Name, $Detail) {
    if ($Status -eq "PASS") {
        $script:pass++
        Write-Host "[OK]   $Name - $Detail" -ForegroundColor Green
    }
    elseif ($Status -eq "WARN") {
        $script:warn++
        Write-Host "[WARN] $Name - $Detail" -ForegroundColor Yellow
    }
    else {
        $script:fail++
        Write-Host "[ERRO] $Name - $Detail" -ForegroundColor Red
    }
}

function Get-HttpStatusCode($Exception) {
    try {
        if ($null -ne $Exception.Response -and $null -ne $Exception.Response.StatusCode) {
            return [int]$Exception.Response.StatusCode
        }
    }
    catch {}
    return $null
}

function Test-TransientFailure($Exception) {
    $status = Get-HttpStatusCode $Exception

    if ($null -eq $status) {
        # Timeout, DNS/transporte, conexão fechada ou cold start.
        return $true
    }

    return $status -in @(408, 425, 429, 500, 502, 503, 504)
}

function Invoke-AtlasRequest {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [string]$ContentType = "",
        [byte[]]$Body = $null,
        [int]$Attempts = $MaxAttempts,
        [int]$TimeoutSec = $RequestTimeoutSec,
        [string]$Operation = "requisição"
    )

    $delays = @(0, 5, 10, 20, 30, 45)

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        if ($attempt -gt 1) {
            $delayIndex = [Math]::Min($attempt - 1, $delays.Count - 1)
            $delay = $delays[$delayIndex]
            Write-Host "      ${Operation}: nova tentativa $attempt/$Attempts em ${delay}s..." -ForegroundColor DarkYellow
            Start-Sleep -Seconds $delay
        }

        try {
            $params = @{
                Uri        = $Uri
                Method     = $Method
                Headers    = $Headers
                TimeoutSec = $TimeoutSec
            }

            if ($ContentType) {
                $params.ContentType = $ContentType
            }
            if ($null -ne $Body) {
                $params.Body = $Body
            }

            return Invoke-RestMethod @params
        }
        catch {
            $isTransient = Test-TransientFailure $_.Exception
            $status = Get-HttpStatusCode $_.Exception
            $detail = if ($null -ne $status) {
                "HTTP $status - $($_.Exception.Message)"
            } else {
                $_.Exception.Message
            }

            if (-not $isTransient -or $attempt -eq $Attempts) {
                throw "$Operation falhou após $attempt tentativa(s): $detail"
            }

            Write-Host "      ${Operation}: falha transitória/cold start: $detail" -ForegroundColor DarkYellow
        }
    }

    throw "$Operation falhou sem resposta."
}

function Get-Json($Path, $Headers) {
    return Invoke-AtlasRequest `
        -Uri "$BaseUrl$Path" `
        -Method GET `
        -Headers $Headers `
        -Attempts 3 `
        -TimeoutSec $RequestTimeoutSec `
        -Operation "GET $Path"
}

Write-Host "`nATLAS V16/V17 - GATE DE PRODUCAO`n" -ForegroundColor Cyan
Write-Host "Render gratuito pode estar em cold start; o gate usa warm-up e retries automáticos." -ForegroundColor DarkGray

# Warm-up / readiness: um timeout inicial não é reprovação.
try {
    $health = Invoke-AtlasRequest `
        -Uri "$BaseUrl/health/ready" `
        -Method GET `
        -Attempts $MaxAttempts `
        -TimeoutSec $RequestTimeoutSec `
        -Operation "Health /health/ready"

    if ($health.status -eq "ready") {
        Result PASS "Health" "ready"
    }
    else {
        Result FAIL "Health" "status inesperado: $($health.status)"
        exit 2
    }
}
catch {
    Result FAIL "Health" $_.Exception.Message
    exit 2
}

$email = Read-Host "E-mail do administrador Atlas"
$secure = Read-Host "Senha do Atlas" -AsSecureString
$password = [Net.NetworkCredential]::new("", $secure).Password

$loginJson = @{
    email = $email
    password = $password
} | ConvertTo-Json -Compress

try {
    $login = Invoke-AtlasRequest `
        -Uri "$BaseUrl/auth/login" `
        -Method POST `
        -ContentType "application/json; charset=utf-8" `
        -Body ([Text.Encoding]::UTF8.GetBytes($loginJson)) `
        -Attempts 3 `
        -TimeoutSec $RequestTimeoutSec `
        -Operation "Login"

    if (-not $login.access_token) {
        throw "access_token ausente"
    }
    Result PASS "Login" "token recebido"
}
catch {
    Result FAIL "Login" $_.Exception.Message
    exit 2
}

$headers = @{
    Authorization = "Bearer $($login.access_token)"
}

try {
    $me = Get-Json "/auth/me" $headers
    Result PASS "/auth/me" "$($me.role)"
}
catch {
    Result FAIL "/auth/me" $_.Exception.Message
}

$farms = @()
try {
    $farms = @(Get-Json "/farms" $headers)
    Result PASS "Fazendas" "$($farms.Count) acessível(is)"
}
catch {
    Result FAIL "Fazendas" $_.Exception.Message
}

$farm = $farms | Where-Object { $_.name -eq $FarmName } | Select-Object -First 1
if (-not $farm) {
    $farm = $farms | Select-Object -First 1
}

if ($farm) {
    $farmId = $farm.id

    foreach ($check in @(
        @{Name="Rebanho"; Path="/livestock/animals?farm_id=$farmId"},
        @{Name="Lotes"; Path="/livestock/lots?farm_id=$farmId"},
        @{Name="Sanidade"; Path="/livestock/health?farm_id=$farmId"},
        @{Name="Nutrição"; Path="/livestock/nutrition?farm_id=$farmId"},
        @{Name="Financeiro"; Path="/livestock/finance/v2?farm_id=$farmId"},
        @{Name="Estoque"; Path="/livestock/inventory/products?farm_id=$farmId"},
        @{Name="Alertas"; Path="/livestock/intelligence/operational-alerts?farm_id=$farmId"},
        @{Name="Resumo operacional"; Path="/livestock/intelligence/operational-summary?farm_id=$farmId"},
        @{Name="Reconciliação V9"; Path="/livestock/integrity/reconciliation?farm_id=$farmId"}
    )) {
        try {
            $value = Get-Json $check.Path $headers
            Result PASS $check.Name "endpoint respondeu"
        }
        catch {
            Result FAIL $check.Name $_.Exception.Message
        }
    }
}
else {
    Result FAIL "Fazenda ativa" "nenhuma fazenda encontrada"
}

Write-Host "`nPASS: $pass" -ForegroundColor Green
Write-Host "WARN: $warn" -ForegroundColor Yellow
Write-Host "FAIL: $fail" -ForegroundColor Red

if ($fail -gt 0) {
    Write-Host "STATUS: REPROVADO" -ForegroundColor Red
    exit 2
}
elseif ($warn -gt 0) {
    Write-Host "STATUS: APROVADO_COM_ALERTAS" -ForegroundColor Yellow
    exit 1
}
else {
    Write-Host "STATUS: APROVADO" -ForegroundColor Green
    exit 0
}
