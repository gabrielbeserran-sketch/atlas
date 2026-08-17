$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Backend = Join-Path $ProjectRoot "backend"
$BackendEnv = Join-Path $Backend ".env"
$BackendPython = Join-Path $Backend ".venv\Scripts\python.exe"
Set-Location $ProjectRoot

function Assert-ExitCode {
    param(
        [Parameter(Mandatory = $true)][string]$Step,
        [Parameter(Mandatory = $true)][int]$ExitCode
    )
    if ($ExitCode -ne 0) {
        throw "$Step falhou com código $ExitCode."
    }
}

function Assert-Command {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$InstallHint
    )
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Comando '$Name' não encontrado. $InstallHint"
    }
}

function Invoke-DockerComposeChecked {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Step
    )

    & docker compose @Arguments
    $exitCode = $LASTEXITCODE
    Assert-ExitCode -Step $Step -ExitCode $exitCode
}

function Get-ComposeDatabaseContract {
    $raw = (& docker compose config --format json 2>&1) -join "`n"
    $exitCode = $LASTEXITCODE
    Assert-ExitCode -Step "Leitura do contrato Docker Compose" -ExitCode $exitCode

    try {
        $config = $raw | ConvertFrom-Json
    } catch {
        throw "Não foi possível interpretar 'docker compose config --format json'. Detalhe: $($_.Exception.Message)"
    }

    if (-not $config.services.db) {
        throw "O docker-compose.yml não possui o serviço obrigatório 'db'."
    }

    $environment = $config.services.db.environment
    $user = [string]$environment.POSTGRES_USER
    $database = [string]$environment.POSTGRES_DB
    $password = [string]$environment.POSTGRES_PASSWORD

    if ([string]::IsNullOrWhiteSpace($user) -or
        [string]::IsNullOrWhiteSpace($database) -or
        [string]::IsNullOrWhiteSpace($password)) {
        throw "POSTGRES_USER, POSTGRES_DB e POSTGRES_PASSWORD devem estar definidos no serviço db."
    }

    if ($user -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
        throw "POSTGRES_USER possui formato não suportado pelo reconciliador local: '$user'."
    }

    return [PSCustomObject]@{
        User = $user
        Database = $database
        Password = $password
    }
}

function Get-BackendDatabaseContract {
    if (-not (Test-Path $BackendEnv)) {
        throw "Arquivo backend/.env não encontrado em $BackendEnv."
    }

    $line = Get-Content $BackendEnv |
        Where-Object { $_ -match '^ATLAS_DATABASE_URL=' } |
        Select-Object -First 1

    if (-not $line) {
        throw "ATLAS_DATABASE_URL não está definido em backend/.env."
    }

    $url = ($line -split '=', 2)[1].Trim()
    $pattern = '^postgresql(?:\+[^:]+)?://([^:]+):([^@]+)@([^:/]+):(\d+)/([^?]+)'
    $match = [regex]::Match($url, $pattern)
    if (-not $match.Success) {
        throw "ATLAS_DATABASE_URL local deve usar PostgreSQL no formato postgresql+psycopg://usuario:senha@host:porta/banco."
    }

    return [PSCustomObject]@{
        Url = $url
        User = [System.Uri]::UnescapeDataString($match.Groups[1].Value)
        Password = [System.Uri]::UnescapeDataString($match.Groups[2].Value)
        Host = $match.Groups[3].Value
        Port = [int]$match.Groups[4].Value
        Database = [System.Uri]::UnescapeDataString($match.Groups[5].Value)
    }
}

function Assert-DatabaseContractsMatch {
    param($ComposeDb, $BackendDb)

    $errors = @()
    if ($BackendDb.User -ne $ComposeDb.User) {
        $errors += "usuário backend='$($BackendDb.User)' compose='$($ComposeDb.User)'"
    }
    if ($BackendDb.Database -ne $ComposeDb.Database) {
        $errors += "banco backend='$($BackendDb.Database)' compose='$($ComposeDb.Database)'"
    }
    if ($BackendDb.Password -ne $ComposeDb.Password) {
        $errors += "senha do backend/.env diferente da senha declarada no Compose"
    }
    if ($BackendDb.Host -notin @('localhost', '127.0.0.1')) {
        $errors += "host local do backend deve ser localhost ou 127.0.0.1, recebido '$($BackendDb.Host)'"
    }
    if ($BackendDb.Port -ne 5432) {
        $errors += "porta local do backend deve ser 5432, recebida '$($BackendDb.Port)'"
    }

    if ($errors.Count -gt 0) {
        throw "Contrato de banco inconsistente. $($errors -join '; ')."
    }
}

function Wait-ContainerPostgres {
    param(
        [Parameter(Mandatory = $true)][string]$User,
        [Parameter(Mandatory = $true)][string]$Database,
        [int]$TimeoutSeconds = 90
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        & docker compose exec -T db pg_isready -U $User -d $Database *> $null
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) {
            return
        }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    & docker compose ps db
    throw "PostgreSQL não ficou pronto dentro de $TimeoutSeconds segundos."
}

function Reconcile-PostgresPassword {
    param($DbContract)

    # POSTGRES_PASSWORD só é aplicado na criação inicial do volume. Esta etapa
    # torna o bootstrap idempotente também para volumes antigos.
    $sqlPassword = $DbContract.Password.Replace("'", "''")
    $sql = "ALTER ROLE `"$($DbContract.User)`" WITH LOGIN PASSWORD '$sqlPassword';"

    Write-Host "Reconciliando credencial do usuário PostgreSQL no volume existente..." -ForegroundColor DarkYellow
    & docker compose exec -T db psql `
        -v ON_ERROR_STOP=1 `
        -U $DbContract.User `
        -d $DbContract.Database `
        -c $sql *> $null
    $exitCode = $LASTEXITCODE
    Assert-ExitCode -Step "Reconciliação da senha PostgreSQL" -ExitCode $exitCode
}

function Test-TcpEndpoint {
    param(
        [string]$HostName = '127.0.0.1',
        [int]$Port = 5432,
        [int]$TimeoutMilliseconds = 2500
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $asyncResult = $client.BeginConnect($HostName, $Port, $null, $null)
        try {
            if (-not $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMilliseconds, $false)) {
                return $false
            }
            $client.EndConnect($asyncResult)
            return $client.Connected
        } finally {
            $asyncResult.AsyncWaitHandle.Close()
        }
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

function Wait-TcpEndpoint {
    param(
        [string]$HostName = '127.0.0.1',
        [int]$Port = 5432,
        [int]$TimeoutSeconds = 45
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        if (Test-TcpEndpoint -HostName $HostName -Port $Port) {
            return $true
        }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    return $false
}

function Repair-LocalDatabaseReachability {
    param($ComposeDb)

    Write-Host "PostgreSQL não respondeu em 127.0.0.1:5432. Recriando somente o container db e preservando o volume..." -ForegroundColor DarkYellow
    Invoke-DockerComposeChecked `
        -Arguments @('up', '-d', '--force-recreate', '--no-deps', 'db') `
        -Step "Recriação segura do container PostgreSQL"

    Wait-ContainerPostgres -User $ComposeDb.User -Database $ComposeDb.Database
    Reconcile-PostgresPassword -DbContract $ComposeDb
}

function Assert-LocalDatabaseReachability {
    param($ComposeDb)

    # Critério de runtime: o socket que o backend realmente usa precisa abrir.
    # Docker inspect/PortBindings servem para diagnóstico humano, não para
    # aprovação, evitando falsos negativos de parsing no PowerShell.
    if (Wait-TcpEndpoint -HostName '127.0.0.1' -Port 5432 -TimeoutSeconds 20) {
        Write-Host "Socket PostgreSQL confirmado em 127.0.0.1:5432." -ForegroundColor Green
        return
    }

    Repair-LocalDatabaseReachability -ComposeDb $ComposeDb

    if (-not (Wait-TcpEndpoint -HostName '127.0.0.1' -Port 5432 -TimeoutSeconds 45)) {
        Write-Host "Diagnóstico do container PostgreSQL:" -ForegroundColor DarkYellow
        & docker compose ps db
        throw "PostgreSQL está saudável no Docker, mas 127.0.0.1:5432 não está acessível após recriação segura do container."
    }

    Write-Host "Socket PostgreSQL confirmado em 127.0.0.1:5432 após reparo automático." -ForegroundColor Green
}

function Assert-BackendAuthentication {
    if (-not (Test-Path $BackendPython)) {
        throw "Ambiente backend não encontrado em $BackendPython. A validação real de autenticação não pode ser ignorada."
    }

    Push-Location $Backend
    try {
        & $BackendPython scripts\check_local_database_connection.py
        $exitCode = $LASTEXITCODE
        Assert-ExitCode -Step "Validação da autenticação PostgreSQL pelo backend" -ExitCode $exitCode
    } finally {
        Pop-Location
    }
}

Assert-Command -Name "docker" -InstallHint "Instale/inicie o Docker Desktop e abra novamente o terminal."

Write-Host "=== ATLAS - INFRAESTRUTURA LOCAL CONFIÁVEL ===" -ForegroundColor Cyan
Write-Host "Projeto: $ProjectRoot" -ForegroundColor DarkGray

& docker info *> $null
$dockerInfoExit = $LASTEXITCODE
if ($dockerInfoExit -ne 0) {
    throw "Docker Desktop não está respondendo. Abra o Docker Desktop e aguarde até ele ficar pronto."
}

Write-Host "[1/6] Validando contrato Docker Compose + backend/.env..." -ForegroundColor Yellow
& docker compose config --quiet
$composeValidationExit = $LASTEXITCODE
Assert-ExitCode -Step "Validação do Docker Compose" -ExitCode $composeValidationExit

$composeDb = Get-ComposeDatabaseContract
$backendDb = Get-BackendDatabaseContract
Assert-DatabaseContractsMatch -ComposeDb $composeDb -BackendDb $backendDb

Write-Host "[2/6] Criando/iniciando PostgreSQL local..." -ForegroundColor Yellow
Invoke-DockerComposeChecked `
    -Arguments @('up', '-d', '--no-deps', 'db') `
    -Step "Inicialização do PostgreSQL local"

Write-Host "[3/6] Aguardando PostgreSQL dentro do container..." -ForegroundColor Yellow
Wait-ContainerPostgres -User $composeDb.User -Database $composeDb.Database

Write-Host "[4/6] Reconciliando senha do volume PostgreSQL..." -ForegroundColor Yellow
Reconcile-PostgresPassword -DbContract $composeDb

Write-Host "[5/6] Validando acesso real do Windows ao PostgreSQL..." -ForegroundColor Yellow
Assert-LocalDatabaseReachability -ComposeDb $composeDb

Write-Host "[6/6] Validando autenticação real com a configuração do backend..." -ForegroundColor Yellow
Assert-BackendAuthentication

Write-Host ""
Write-Host "ATLAS LOCAL INFRASTRUCTURE: APROVADA" -ForegroundColor Green
Write-Host "PostgreSQL Atlas pronto e autenticado." -ForegroundColor Green
Write-Host "Host: 127.0.0.1" -ForegroundColor Green
Write-Host "Porta: 5432" -ForegroundColor Green
Write-Host "Banco: $($composeDb.Database)" -ForegroundColor Green
Write-Host "Usuário: $($composeDb.User)" -ForegroundColor Green
Write-Host ""
& docker compose ps db
