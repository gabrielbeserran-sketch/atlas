param(
    [string]$BaseUrl = "http://127.0.0.1:8000"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step([string]$Text) {
    Write-Host "`n$Text" -ForegroundColor Yellow
}

function Read-EnvFile([string]$Path) {
    if (-not (Test-Path $Path)) {
        throw "Arquivo de ambiente não encontrado: $Path"
    }

    $values = @{}
    foreach ($line in Get-Content $Path) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#') -or -not $trimmed.Contains('=')) {
            continue
        }
        $parts = $trimmed.Split('=', 2)
        $values[$parts[0].Trim()] = $parts[1].Trim().Trim('"').Trim("'")
    }
    return $values
}

function Assert-Equal($Actual, $Expected, [string]$Message) {
    if ($Actual -ne $Expected) {
        throw "$Message Esperado='$Expected' Atual='$Actual'."
    }
}

function Expand-AtlasItems {
    param(
        $Value
    )

    if ($null -eq $Value) {
        return
    }

    # Invoke-RestMethod/PowerShell pode preservar um array JSON como um
    # único System.Object[] quando a resposta atravessa outra função.
    # Desembrulhamos somente arrays reais; PSCustomObject continua intacto.
    if ($Value -is [System.Array]) {
        foreach ($item in $Value) {
            Expand-AtlasItems -Value $item
        }
        return
    }

    Write-Output $Value
}

function Get-AtlasFarmList {
    param(
        [Parameter(Mandatory=$true)][hashtable]$Headers
    )

    $response = Invoke-AtlasApi -Method GET -Path '/api/v1/farms' -Headers $Headers
    return @(Expand-AtlasItems -Value $response)
}

function Invoke-AtlasApi {
    param(
        [Parameter(Mandatory=$true)][string]$Method,
        [Parameter(Mandatory=$true)][string]$Path,
        [hashtable]$Headers = @{},
        $Body = $null
    )

    $params = @{
        Uri = "$BaseUrl$Path"
        Method = $Method
        Headers = $Headers
    }

    if ($null -ne $Body) {
        $params['ContentType'] = 'application/json'
        $params['Body'] = ($Body | ConvertTo-Json -Depth 20)
    }

    try {
        return Invoke-RestMethod @params
    }
    catch {
        Write-Host "`nFALHA HTTP: $Method $Path" -ForegroundColor Red
        if ($_.Exception.Response) {
            Write-Host "Status: $([int]$_.Exception.Response.StatusCode)" -ForegroundColor Red
        }
        if ($_.ErrorDetails.Message) {
            Write-Host $_.ErrorDetails.Message -ForegroundColor Red
        }
        throw
    }
}

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " ATLAS - TESTE INTEGRADO REAL DE FAZENDAS" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$env = Read-EnvFile (Join-Path $projectRoot "backend\.env")
$email = $env['ATLAS_BOOTSTRAP_ADMIN_EMAIL']
$password = $env['ATLAS_BOOTSTRAP_ADMIN_PASSWORD']

if ([string]::IsNullOrWhiteSpace($email) -or [string]::IsNullOrWhiteSpace($password)) {
    throw 'Credenciais bootstrap ausentes em backend\.env.'
}

Write-Step '[1/10] OpenAPI'
$openapi = Invoke-AtlasApi -Method GET -Path '/openapi.json'
Write-Host "OK - $($openapi.info.title)" -ForegroundColor Green

$requiredPaths = @(
    '/api/v1/auth/login',
    '/api/v1/farms',
    '/api/v1/farms/{farm_id}'
)
foreach ($requiredPath in $requiredPaths) {
    if (-not $openapi.paths.PSObject.Properties.Name.Contains($requiredPath)) {
        throw "Rota obrigatória ausente no OpenAPI: $requiredPath"
    }
}

Write-Step '[2/10] Login real'
$login = Invoke-AtlasApi -Method POST -Path '/api/v1/auth/login' -Body @{
    email = $email
    password = $password
}
if ([string]::IsNullOrWhiteSpace($login.access_token)) {
    throw 'Login não retornou access_token.'
}
$headers = @{ Authorization = "Bearer $($login.access_token)" }
Write-Host "OK - $($login.user_name) / $($login.role)" -ForegroundColor Green

Write-Step '[3/10] Escopo, empresa e permissões'
if ([string]::IsNullOrWhiteSpace($login.company_id)) { throw 'company_id ausente.' }
if ([string]::IsNullOrWhiteSpace($login.tenant_id)) { throw 'tenant_id ausente.' }
$requiredPermissions = @('farms.read','farms.create','farms.update')
foreach ($permission in $requiredPermissions) {
    if (-not ($login.effective_permissions -contains $permission)) {
        throw "Permissão obrigatória ausente para o usuário administrativo: $permission"
    }
}
Write-Host "OK - company=$($login.company_id) tenant=$($login.tenant_id)" -ForegroundColor Green

Write-Step '[4/10] Listar fazendas existentes'
$farmsBefore = @(Get-AtlasFarmList -Headers $headers)

# Limpa exclusivamente resíduos do próprio teste que possam ter ficado ativos
# após uma execução interrompida. Fazendas reais nunca são tocadas aqui.
$qaLeftovers = @($farmsBefore | Where-Object { $_.name -like 'ATLAS QA *' })
foreach ($qaFarm in $qaLeftovers) {
    Write-Host "Limpando QA anterior: $($qaFarm.name)" -ForegroundColor DarkYellow
    Invoke-AtlasApi -Method DELETE -Path "/api/v1/farms/$($qaFarm.id)" -Headers $headers | Out-Null
}
if ($qaLeftovers.Count -gt 0) {
    $farmsBefore = @(Get-AtlasFarmList -Headers $headers)
}

Write-Host "OK - $($farmsBefore.Count) fazenda(s) ativa(s)." -ForegroundColor Green
$farmsBefore | Select-Object id,name,city,state,animals,area,active | Format-Table -AutoSize

Write-Step '[5/10] Criar fazenda temporária de QA'
$tempName = "ATLAS QA $([DateTime]::Now.ToString('yyyyMMdd-HHmmss'))"
$created = Invoke-AtlasApi -Method POST -Path '/api/v1/farms' -Headers $headers -Body @{
    name = $tempName
    city = 'Sobradinho'
    state = 'GO'
    animals = 25
    area = 80
}
Assert-Equal $created.name $tempName 'Nome incorreto após criação.'
Assert-Equal $created.animals 25 'Animals não persistiu na criação.'
Assert-Equal ([double]$created.area) 80.0 'Area não persistiu na criação.'
Assert-Equal $created.active $true 'Fazenda deveria estar ativa.'
Write-Host "OK - criada: $($created.id)" -ForegroundColor Green

Write-Step '[6/10] Recarregar imediatamente'
$reloadedCreated = Invoke-AtlasApi -Method GET -Path "/api/v1/farms/$($created.id)" -Headers $headers
Assert-Equal $reloadedCreated.animals 25 'Animals divergiu após releitura.'
Assert-Equal ([double]$reloadedCreated.area) 80.0 'Area divergiu após releitura.'
Write-Host 'OK - persistência de criação confirmada.' -ForegroundColor Green

Write-Step '[7/10] Editar fazenda'
$updatedName = "$tempName EDITADA"
$updated = Invoke-AtlasApi -Method PATCH -Path "/api/v1/farms/$($created.id)" -Headers $headers -Body @{
    name = $updatedName
    city = 'Formosa'
    state = 'GO'
    animals = 37
    area = 125
}
Assert-Equal $updated.name $updatedName 'Nome não foi atualizado.'
Assert-Equal $updated.animals 37 'Animals não foi atualizado.'
Assert-Equal ([double]$updated.area) 125.0 'Area não foi atualizada.'
Write-Host 'OK - PATCH persistido.' -ForegroundColor Green

Write-Step '[8/10] Recarregar após edição'
$reloadedUpdated = Invoke-AtlasApi -Method GET -Path "/api/v1/farms/$($created.id)" -Headers $headers
Assert-Equal $reloadedUpdated.name $updatedName 'Nome divergiu após releitura da edição.'
Assert-Equal $reloadedUpdated.animals 37 'Animals divergiu após releitura da edição.'
Assert-Equal ([double]$reloadedUpdated.area) 125.0 'Area divergiu após releitura da edição.'
Write-Host 'OK - edição confirmada por nova leitura.' -ForegroundColor Green

Write-Step '[9/10] Verificar a fazenda na listagem'
$farmsAfter = @(Get-AtlasFarmList -Headers $headers)
$listed = @($farmsAfter | Where-Object { $_.id -eq $created.id }) | Select-Object -First 1
if ($null -eq $listed) { throw 'Fazenda criada não apareceu na listagem.' }
if ($listed.animals -is [System.Array]) {
    throw "Listagem retornou animals como coleção inesperada: $($listed.animals | ConvertTo-Json -Compress)"
}
if ($listed.area -is [System.Array]) {
    throw "Listagem retornou area como coleção inesperada: $($listed.area | ConvertTo-Json -Compress)"
}
Assert-Equal $listed.animals 37 'Listagem retornou animals incorreto.'
Assert-Equal ([double]$listed.area) 125.0 'Listagem retornou area incorreta.'
Write-Host 'OK - listagem consistente.' -ForegroundColor Green

Write-Step '[10/10] Desativar e confirmar remoção da lista ativa'
$deleted = Invoke-AtlasApi -Method DELETE -Path "/api/v1/farms/$($created.id)" -Headers $headers
Assert-Equal $deleted.active $false 'DELETE lógico não desativou a fazenda.'
$farmsFinal = @(Get-AtlasFarmList -Headers $headers)
if ($farmsFinal | Where-Object { $_.id -eq $created.id }) {
    throw 'Fazenda desativada ainda aparece na listagem ativa.'
}
Write-Host 'OK - limpeza confirmada.' -ForegroundColor Green

Write-Host "`n==============================================" -ForegroundColor Green
Write-Host ' ATLAS FAZENDAS INTEGRADO: APROVADO' -ForegroundColor Green
Write-Host '==============================================' -ForegroundColor Green
