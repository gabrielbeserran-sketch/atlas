param(
    [string]$BaseUrl = "https://atlas-api-29y2.onrender.com/api/v1",
    [string]$FarmName = "Fazenda Atlas Producao"
)

$ErrorActionPreference = "Stop"
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

function Get-Json($Path, $Headers) {
    return Invoke-RestMethod `
        -Uri "$BaseUrl$Path" `
        -Method GET `
        -Headers $Headers `
        -TimeoutSec 120
}

Write-Host "`nATLAS V16/V17 - GATE DE PRODUCAO`n" -ForegroundColor Cyan

try {
    $health = Invoke-RestMethod `
        -Uri "$BaseUrl/health/ready" `
        -Method GET `
        -TimeoutSec 120
    if ($health.status -eq "ready") {
        Result PASS "Health" "ready"
    }
    else {
        Result FAIL "Health" "status inesperado"
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
    $login = Invoke-RestMethod `
        -Uri "$BaseUrl/auth/login" `
        -Method POST `
        -ContentType "application/json; charset=utf-8" `
        -Body ([Text.Encoding]::UTF8.GetBytes($loginJson)) `
        -TimeoutSec 120

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

$farm = $farms | Where-Object { $_.name -eq $FarmName } |
    Select-Object -First 1
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
