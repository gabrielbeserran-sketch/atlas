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

    $Uri = [System.Uri]$Value
    if (-not $Uri.IsAbsoluteUri -or $Uri.Scheme -notin @("http", "https")) {
        throw "BaseUrl precisa ser HTTP/HTTPS absoluta."
    }
    return $Value.Trim().TrimEnd("/")
}

$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl
$Uri = [System.Uri]$BaseUrl
$Origin = "$($Uri.Scheme)://$($Uri.Authority)"
$OpenApiUrl = "$Origin/openapi.json"

Write-Host "=== ATLAS POS-V21 PACOTE 2 - CONTRATO PUBLICADO ===" -ForegroundColor Cyan
Write-Host "Consultando $OpenApiUrl" -ForegroundColor DarkGray

$openApi = Invoke-RestMethod -Uri $OpenApiUrl -Method GET -TimeoutSec 180
$path = "/api/v1/livestock/handling/batch"

if ($null -eq $openApi.paths.$path) {
    throw "O Render ainda não publicou $path."
}
if ($null -eq $openApi.paths.$path.post) {
    throw "O endpoint $path existe, mas o método POST não foi publicado."
}

Write-Host "[OK] POST $path publicado no Render." -ForegroundColor Green
Write-Host "ATLAS POS-V21 PACOTE 2: BACKEND PUBLICADO" -ForegroundColor Green
