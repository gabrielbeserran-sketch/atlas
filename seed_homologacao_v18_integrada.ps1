﻿param(
    [string]$BaseUrl = "https://atlas-api-29y2.onrender.com/api/v1",
    [string]$FarmName = "Fazenda Atlas Producao"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Step {
    param([string]$Text)
    Write-Host ""
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor Green
}

function Write-Info {
    param([string]$Text)
    Write-Host "[INFO] $Text" -ForegroundColor Yellow
}

function Wait-AtlasReady {
    param(
        [int]$Attempts = 8,
        [int]$DelaySeconds = 8
    )

    Write-Step "AQUECENDO API DO RENDER"

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            Write-Info "Health check $attempt de $Attempts..."

            $health = Invoke-RestMethod `
                -Uri "$BaseUrl/health/ready" `
                -Method GET `
                -TimeoutSec 60

            if ($health.status -eq "ready") {
                Write-Ok "API do Render pronta"
                return
            }
        }
        catch {
            Write-Info "API ainda acordando. Aguardando $DelaySeconds s..."
        }

        Start-Sleep -Seconds $DelaySeconds
    }

    throw "A API não ficou pronta após $Attempts tentativas."
}

function Invoke-AtlasLogin {
    param(
        [string]$Email,
        [string]$Password,
        [int]$Attempts = 5
    )

    $loginJson = @{
        email    = $Email
        password = $Password
    } | ConvertTo-Json -Compress

    $loginBody = [System.Text.Encoding]::UTF8.GetBytes($loginJson)

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            Write-Info "Tentativa de login $attempt de $Attempts..."

            $login = Invoke-RestMethod `
                -Uri "$BaseUrl/auth/login" `
                -Method POST `
                -ContentType "application/json; charset=utf-8" `
                -Body $loginBody `
                -TimeoutSec 180

            if ($login.access_token) {
                return $login
            }

            throw "O login respondeu sem access_token."
        }
        catch {
            $message = $_.Exception.Message

            if (
                $message -match "401" -or
                $message -match "403" -or
                $message -match "Não Autorizado" -or
                $message -match "Unauthorized"
            ) {
                throw
            }

            if ($attempt -eq $Attempts) {
                throw
            }

            Write-Info "Falha transitória no login: $message"
            Write-Info "Aguardando 10 segundos antes de tentar novamente..."
            Start-Sleep -Seconds 10

            try {
                Invoke-RestMethod `
                    -Uri "$BaseUrl/health/ready" `
                    -Method GET `
                    -TimeoutSec 60 | Out-Null
            }
            catch {}
        }
    }
}

function Get-ErrorBody {
    param($Exception)

    try {
        if ($Exception.Response -and $Exception.Response.GetResponseStream) {
            $reader = New-Object System.IO.StreamReader(
                $Exception.Response.GetResponseStream()
            )
            return $reader.ReadToEnd()
        }
    }
    catch {}

    return $Exception.Message
}

function Invoke-Atlas {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "POST", "PATCH", "DELETE")]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        $Body = $null
    )

    $params = @{
        Uri        = "$BaseUrl$Path"
        Method     = $Method
        Headers    = $script:Headers
        TimeoutSec = 180
    }

    if ($null -ne $Body) {
        # Windows PowerShell 5.1 pode enviar strings JSON com acentos usando
        # uma codificação incompatível com o FastAPI. Serializamos e enviamos
        # bytes UTF-8 explicitamente para todos os POST/PATCH.
        $json = $Body | ConvertTo-Json -Depth 30 -Compress
        $params["ContentType"] = "application/json; charset=utf-8"
        $params["Body"] = [System.Text.Encoding]::UTF8.GetBytes($json)
    }

    try {
        return Invoke-RestMethod @params
    }
    catch {
        $bodyText = Get-ErrorBody $_.Exception
        throw "Falha $Method $Path`n$bodyText"
    }
}

function As-Array {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }

    return @($Value)
}


function Test-AtlasModule {
    param(
        [string]$Name,
        [string]$Path,
        [switch]$Optional
    )

    try {
        Invoke-Atlas GET $Path | Out-Null
        Write-Ok "Preflight: $Name"
        return $true
    }
    catch {
        if ($Optional) {
            Write-Info "Preflight opcional falhou: $Name"
            Write-Info $_.Exception.Message
            return $false
        }

        throw "Preflight obrigatório falhou em $Name`n$($_.Exception.Message)"
    }
}

function Invoke-BestEffort {
    param(
        [string]$Label,
        [scriptblock]$Action
    )

    try {
        & $Action
    }
    catch {
        Write-Info "$Label não concluído; carga continuará."
        Write-Info $_.Exception.Message
    }
}

function Ensure-Lot {
    param(
        [string]$Name,
        [string]$Category,
        [int]$Capacity,
        [string]$Paddock,
        [string]$Notes
    )

    $lots = As-Array (
        Invoke-Atlas GET "/livestock/lots?farm_id=$script:FarmId"
    )

    $existing = $lots |
        Where-Object { $_.name -eq $Name } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Lote já existe: $Name"
        return $existing
    }

    $created = Invoke-Atlas POST "/livestock/lots" @{
        farm_id  = $script:FarmId
        name     = $Name
        category = $Category
        capacity = $Capacity
        paddock  = $Paddock
        notes    = $Notes
    }

    Write-Ok "Lote criado: $Name"
    return $created
}

function Ensure-Paddock {
    param(
        [string]$Name,
        [double]$Area,
        [string]$Status,
        [string]$Notes
    )

    $items = As-Array (
        Invoke-Atlas GET "/livestock/paddocks?farm_id=$script:FarmId"
    )

    $existing = $items |
        Where-Object { $_.name -eq $Name } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Piquete já existe: $Name"
        return $existing
    }

    $created = Invoke-Atlas POST "/livestock/paddocks" @{
        farm_id = $script:FarmId
        name    = $Name
        area    = $Area
        status  = $Status
        animals = 0
        notes   = $Notes
    }

    Write-Ok "Piquete criado: $Name"
    return $created
}

function Ensure-Animal {
    param(
        [string]$Tag,
        [string]$Name,
        [string]$LotId,
        [string]$Sex,
        [string]$Breed,
        [string]$Category,
        [string]$BirthDate,
        [double]$Weight,
        [double]$BodyScore
    )

    $animals = As-Array (
        Invoke-Atlas GET "/livestock/animals?farm_id=$script:FarmId"
    )

    $existing = $animals |
        Where-Object { $_.tag -eq $Tag } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Animal já existe: $Tag - $Name"
        return $existing
    }

    $created = Invoke-Atlas POST "/livestock/animals" @{
        farm_id              = $script:FarmId
        lot_id               = $LotId
        tag                  = $Tag
        sisbov               = ""
        name                 = $Name
        sex                  = $Sex
        breed                = $Breed
        category             = $Category
        birth_date           = $BirthDate
        status               = "active"
        current_weight       = $Weight
        body_condition_score = $BodyScore
        metadata_json        = @{
            origin = "Nascido na fazenda"
            seed   = "ATLAS-DEMO-2026"
        }
    }

    Write-Ok "Animal criado: $Tag - $Name"
    return $created
}

function Ensure-Weight {
    param(
        [string]$AnimalId,
        [double]$Weight,
        [double]$BodyScore,
        [datetime]$MeasuredAt,
        [string]$Marker
    )

    $history = As-Array (
        Invoke-Atlas GET "/livestock/animals/$AnimalId/weights"
    )

    $existing = $history |
        Where-Object { $_.notes -eq $Marker } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Pesagem já existe: $Marker"
        return $existing
    }

    $created = Invoke-Atlas POST "/livestock/animals/$AnimalId/weights" @{
        weight               = $Weight
        body_condition_score = $BodyScore
        source               = "Balança eletrônica"
        equipment            = "Balança Demo Atlas"
        measured_at          = $MeasuredAt.ToUniversalTime().ToString("o")
        notes                = $Marker
    }

    Write-Ok "Pesagem criada: $Weight kg"
    return $created
}

function Ensure-Reproduction {
    param(
        [string]$AnimalId,
        [string]$EventType,
        [string]$EventCode,
        [string]$Result,
        [string]$Status,
        [datetime]$OccurredAt,
        [string]$Notes
    )

    $history = As-Array (
        Invoke-Atlas GET "/livestock/animals/$AnimalId/reproduction"
    )

    $existing = $history |
        Where-Object { $_.notes -eq $Notes } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Evento reprodutivo já existe: $EventType"
        return $existing
    }

    $created = Invoke-Atlas POST "/livestock/animals/$AnimalId/reproduction" @{
        event_type          = $EventType
        event_code          = $EventCode
        protocol_name       = "Protocolo Demo Atlas"
        protocol_stage      = ""
        sire_reference      = "Touro Demo 001"
        result              = $Result
        reproductive_status = $Status
        responsible         = "Equipe Atlas"
        attempt_number      = 1
        pregnancy_days      = 0
        calf_id             = ""
        calf_sex            = ""
        birth_type          = ""
        occurred_at         = $OccurredAt.ToUniversalTime().ToString("o")
        expected_date       = $null
        notes               = $Notes
        metadata_json       = @{
            seed = "ATLAS-DEMO-2026"
        }
    }

    Write-Ok "Evento reprodutivo criado: $EventType"
    return $created
}

function Ensure-HealthEvent {
    param(
        [string]$AnimalId,
        [string]$EventType,
        [string]$ProductName,
        [string]$Dosage,
        [string]$Route,
        [datetime]$OccurredAt,
        [datetime]$NextDate,
        [string]$Notes,
        [string]$ProductId,
        [double]$InventoryQuantity
    )

    $events = As-Array (
        Invoke-Atlas GET (
            "/livestock/health?farm_id=$script:FarmId&animal_id=$AnimalId"
        )
    )

    $existing = $events |
        Where-Object { $_.notes -eq $Notes } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Evento sanitário já existe: $EventType"
        return $existing
    }

    $created = Invoke-Atlas POST "/livestock/health" @{
        farm_id                = $script:FarmId
        animal_id              = $AnimalId
        lot_id                 = $null
        event_type             = $EventType
        product_name           = $ProductName
        dosage                 = $Dosage
        route                  = $Route
        occurred_at            = $OccurredAt.ToUniversalTime().ToString("o")
        responsible            = "Equipe Atlas"
        notes                  = $Notes
        protocol_name          = "Programa Sanitário Demo"
        product_batch          = "DEMO-2026"
        frequency              = "Conforme protocolo"
        diagnosis              = ""
        severity               = "low"
        next_date              = $NextDate.ToUniversalTime().ToString("o")
        status                 = "completed"
        is_quarantine          = $false
        is_mortality           = $false
        necropsy_result        = ""
        inventory_product_id   = $ProductId
        inventory_quantity     = $InventoryQuantity
        treatment_cost         = 0
    }

    Write-Ok "Evento sanitário criado: $EventType"
    return $created
}

function Ensure-InventoryProduct {
    param(
        [string]$Sku,
        [string]$Name,
        [string]$Category,
        [string]$Unit,
        [double]$Minimum,
        [double]$AverageCost,
        [string]$Supplier
    )

    $products = As-Array (
        Invoke-Atlas GET (
            "/livestock/inventory/products?farm_id=$script:FarmId"
        )
    )

    $existing = $products |
        Where-Object { $_.sku -eq $Sku } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Produto já existe: $Name"
        return $existing
    }

    $created = Invoke-Atlas POST "/livestock/inventory/products/v2" @{
        farm_id            = $script:FarmId
        sku                = $Sku
        name               = $Name
        category           = $Category
        unit               = $Unit
        quantity           = 0
        minimum_quantity   = $Minimum
        maximum_quantity   = 200
        average_cost       = $AverageCost
        last_purchase_cost = $AverageCost
        batch_number       = "DEMO-2026"
        supplier           = $Supplier
        storage_location   = "Almoxarifado principal"
        active_ingredient  = ""
        barcode            = ""
        notes              = "ATLAS-DEMO-2026"
    }

    Write-Ok "Produto criado: $Name"
    return $created
}

function Ensure-StockEntry {
    param(
        [string]$ProductId,
        [double]$Quantity,
        [double]$UnitCost,
        [string]$ReferenceId
    )

    $history = As-Array (
        Invoke-Atlas GET (
            "/livestock/inventory/products/$ProductId/movements"
        )
    )

    $existing = $history |
        Where-Object {
            $_.reference_type -eq "demo_seed" -and
            $_.reference_id -eq $ReferenceId
        } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Movimentação de estoque já existe: $ReferenceId"
        return $existing
    }

    $created = Invoke-Atlas POST (
        "/livestock/inventory/products/$ProductId/movements/v2"
    ) @{
        movement_type  = "entry"
        quantity       = $Quantity
        unit_cost      = $UnitCost
        reason         = "Carga de demonstração do Atlas"
        document_number = "DEMO-2026"
        product_batch  = "DEMO-2026"
        reference_type = "demo_seed"
        reference_id   = $ReferenceId
        occurred_at    = (Get-Date).ToUniversalTime().ToString("o")
    }

    Write-Ok "Entrada de estoque criada: $Quantity"
    return $created
}

function Ensure-NutritionIngredient {
    param(
        [string]$Name,
        [double]$DryMatter,
        [double]$Protein,
        [double]$Ndf,
        [double]$Tdn,
        [double]$Cost,
        [string]$ProductId
    )

    $items = As-Array (
        Invoke-Atlas GET (
            "/livestock/nutrition/ingredients?farm_id=$script:FarmId"
        )
    )

    $existing = $items |
        Where-Object { $_.name -eq $Name } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Ingrediente já existe: $Name"
        return $existing
    }

    $created = Invoke-Atlas POST "/livestock/nutrition/ingredients" @{
        farm_id               = $script:FarmId
        inventory_product_id  = $ProductId
        name                  = $Name
        category              = "concentrate"
        unit                  = "kg"
        dry_matter_percent    = $DryMatter
        crude_protein_percent = $Protein
        ndf_percent           = $Ndf
        adf_percent           = 12
        tdn_percent           = $Tdn
        cost_per_kg           = $Cost
        notes                 = "ATLAS-DEMO-2026"
    }

    Write-Ok "Ingrediente criado: $Name"
    return $created
}

function Ensure-NutritionPlan {
    param(
        [string]$LotId,
        [string]$Name
    )

    $plans = As-Array (
        Invoke-Atlas GET (
            "/livestock/nutrition/plans?farm_id=$script:FarmId&lot_id=$LotId"
        )
    )

    $existing = $plans |
        Where-Object { $_.name -eq $Name } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Plano nutricional já existe: $Name"
        return $existing
    }

    $created = Invoke-Atlas POST "/livestock/nutrition/plans" @{
        farm_id                    = $script:FarmId
        lot_id                     = $LotId
        name                       = $Name
        category                   = "Matrizes"
        start_date                 = (Get-Date).AddDays(-7).ToUniversalTime().ToString("o")
        end_date                   = (Get-Date).AddDays(90).ToUniversalTime().ToString("o")
        daily_amount_per_animal_kg = 8.5
        animal_count               = 3
        average_body_weight_kg     = 470
        target_daily_gain_kg       = 0.45
        dry_matter_percent         = 65
        crude_protein_percent      = 14
        ndf_percent                = 38
        tdn_percent                = 68
        cost_per_kg                = 1.85
        ingredients_json           = @(
            @{
                name       = "Silagem de milho"
                percentage = 70
            },
            @{
                name       = "Concentrado Demo Atlas"
                percentage = 30
            }
        )
        stock_integration_enabled  = $true
        inventory_deducted         = $false
        inventory_deduction_cost   = 0
        notes                      = "ATLAS-DEMO-2026"
    }

    Write-Ok "Plano nutricional criado: $Name"
    return $created
}

function Ensure-NutritionConsumption {
    param(
        [string]$LotId,
        [string]$PlanId,
        [string]$ProductId,
        [string]$Marker
    )

    $events = As-Array (
        Invoke-Atlas GET (
            "/livestock/nutrition?farm_id=$script:FarmId&lot_id=$LotId"
        )
    )

    $existing = $events |
        Where-Object { $_.notes -eq $Marker } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Consumo nutricional integrado já existe"
        return $existing
    }

    $created = Invoke-Atlas POST (
        "/livestock/nutrition/lots/$LotId/consumption"
    ) @{
        nutrition_plan_id       = $PlanId
        product_id              = $ProductId
        diet_name               = "Dieta Homologação V18 Matrizes"
        amount_per_animal       = 8.5
        animal_count            = 3
        total_quantity          = 25.5
        planned_quantity        = 25.5
        observed_daily_gain_kg  = 0.45
        notes                   = $Marker
        occurred_at             = (Get-Date).AddDays(-1).ToUniversalTime().ToString("o")
    }

    Write-Ok "Consumo nutricional integrado registrado"
    return $created
}

function Ensure-Finance {
    param(
        [string]$EntryType,
        [string]$Category,
        [string]$Description,
        [double]$Amount,
        [string]$ReferenceId,
        [string]$LotId = "",
        [string]$AnimalId = ""
    )

    $entries = As-Array (
        Invoke-Atlas GET "/livestock/finance/v2?farm_id=$script:FarmId"
    )

    $existing = $entries |
        Where-Object {
            $_.reference_type -eq "demo_seed" -and
            $_.reference_id -eq $ReferenceId
        } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Financeiro já existe: $Description"
        return $existing
    }

    $body = @{
        farm_id          = $script:FarmId
        animal_id        = if ($AnimalId) { $AnimalId } else { $null }
        lot_id           = if ($LotId) { $LotId } else { $null }
        entry_type       = $EntryType
        category         = $Category
        cost_center      = "Operação pecuária"
        description      = $Description
        amount           = $Amount
        status           = "paid"
        competence_date  = (Get-Date).AddDays(-5).ToUniversalTime().ToString("o")
        due_date         = (Get-Date).AddDays(-2).ToUniversalTime().ToString("o")
        paid_at          = (Get-Date).AddDays(-2).ToUniversalTime().ToString("o")
        payment_method   = "Pix"
        counterparty     = "Fornecedor Demo Atlas"
        document_number  = "DEMO-2026"
        recurring        = $false
        recurrence_rule  = ""
        reference_type   = "demo_seed"
        reference_id     = $ReferenceId
        notes            = "ATLAS-DEMO-2026"
    }

    $created = Invoke-Atlas POST "/livestock/finance/v2" $body
    Write-Ok "Financeiro: $Description"
    return $created
}

function Ensure-Task {
    param(
        [string]$Title,
        [string]$Description,
        [string]$Priority,
        [datetime]$DueAt
    )

    $tasks = As-Array (
        Invoke-Atlas GET "/operations/tasks?farm_id=$script:FarmId"
    )

    $existing = $tasks |
        Where-Object { $_.title -eq $Title } |
        Select-Object -First 1

    if ($existing) {
        Write-Ok "Tarefa já existe: $Title"
        return $existing
    }

    $created = Invoke-Atlas POST "/operations/tasks" @{
        farm_id             = $script:FarmId
        source_type         = "demo_seed"
        source_id           = "ATLAS-DEMO-2026"
        title               = $Title
        description         = $Description
        responsible_user_id = $null
        priority            = $Priority
        due_at              = $DueAt.ToUniversalTime().ToString("o")
    }

    Write-Ok "Tarefa criada: $Title"
    return $created
}

function Ensure-CalendarEvent {
    param(
        [string]$Title,
        [string]$Category,
        [string]$Description,
        [datetime]$StartsAt,
        [datetime]$EndsAt
    )

    try {
        $items = As-Array (
            Invoke-Atlas GET "/automation/calendar"
        )

        $existing = $items |
            Where-Object { $_.title -eq $Title } |
            Select-Object -First 1

        if ($existing) {
            Write-Ok "Agenda já possui: $Title"
            return $existing
        }

        $created = Invoke-Atlas POST "/automation/calendar" @{
            farm_id             = $script:FarmId
            title               = $Title
            category            = $Category
            description         = $Description
            starts_at           = $StartsAt.ToUniversalTime().ToString("o")
            ends_at             = $EndsAt.ToUniversalTime().ToString("o")
            responsible_user_id = $null
            metadata_json       = @{
                seed = "ATLAS-DEMO-2026"
            }
        }

        Write-Ok "Agenda: $Title"
        return $created
    }
    catch {
        Write-Info "Agenda não foi populada: $($_.Exception.Message)"
        return $null
    }
}

Write-Host ""
Write-Host "ATLAS - CARGA INTEGRADA DE HOMOLOGACAO V18" `
    -ForegroundColor Green
Write-Host "Base: $BaseUrl"
Write-Host "O script é idempotente e valida vínculos cruzados reais antes da conferência visual."
Write-Host ""

$email = Read-Host "E-mail do administrador Atlas"
$securePassword = Read-Host "Senha do Atlas" -AsSecureString
$password = [System.Net.NetworkCredential]::new(
    "",
    $securePassword
).Password

Wait-AtlasReady

Write-Step "AUTENTICACAO"

$login = Invoke-AtlasLogin `
    -Email $email `
    -Password $password

$script:Headers = @{
    Authorization = "Bearer $($login.access_token)"
}

Write-Ok "Login de produção aprovado"

Write-Step "FAZENDA"

$farms = As-Array (Invoke-Atlas GET "/farms")
$farm = $farms |
    Where-Object { $_.name -eq $FarmName } |
    Select-Object -First 1

if (-not $farm) {
    $farm = $farms | Select-Object -First 1
}

if (-not $farm) {
    throw "Nenhuma fazenda encontrada para a conta."
}

$script:FarmId = $farm.id
Write-Ok "Fazenda selecionada: $($farm.name)"

Write-Step "PREFLIGHT DOS MODULOS"

Test-AtlasModule "Lotes" "/livestock/lots?farm_id=$script:FarmId" | Out-Null
Test-AtlasModule "Animais" "/livestock/animals?farm_id=$script:FarmId" | Out-Null
Test-AtlasModule "Sanidade" "/livestock/health?farm_id=$script:FarmId" | Out-Null
Test-AtlasModule "Nutrição" "/livestock/nutrition?farm_id=$script:FarmId" | Out-Null
Test-AtlasModule "Estoque" "/livestock/inventory/products?farm_id=$script:FarmId" | Out-Null
Test-AtlasModule "Financeiro" "/livestock/finance/v2?farm_id=$script:FarmId" | Out-Null
Test-AtlasModule "Tarefas" "/operations/tasks?farm_id=$script:FarmId" -Optional | Out-Null
Test-AtlasModule "Agenda" "/automation/calendar" -Optional | Out-Null

Write-Step "PIQUETES E LOTES"

$paddockNorth = Ensure-Paddock `
    "DEMO - Piquete Norte" `
    28.5 `
    "Em uso" `
    "Piquete para conferência geral do Atlas"

$paddockSouth = Ensure-Paddock `
    "DEMO - Piquete Sul" `
    32.0 `
    "Descanso" `
    "Segundo piquete de demonstração"

$lotMatrizes = Ensure-Lot `
    "DEMO - Matrizes" `
    "Vacas" `
    80 `
    "DEMO - Piquete Norte" `
    "Lote de matrizes para conferência"

$lotNovilhas = Ensure-Lot `
    "DEMO - Novilhas" `
    "Novilhas" `
    60 `
    "DEMO - Piquete Sul" `
    "Lote de novilhas para conferência"

Write-Step "ANIMAIS"

$aurora = Ensure-Animal `
    "DEMO-101" `
    "Aurora" `
    $lotMatrizes.id `
    "Fêmea" `
    "Nelore" `
    "Matriz" `
    "2022-09-10" `
    450 `
    3.0

$bela = Ensure-Animal `
    "DEMO-102" `
    "Bela" `
    $lotMatrizes.id `
    "Fêmea" `
    "Nelore" `
    "Novilha" `
    "2024-02-15" `
    330 `
    3.0

$cacique = Ensure-Animal `
    "DEMO-103" `
    "Cacique" `
    $lotMatrizes.id `
    "Macho" `
    "Nelore" `
    "Touro" `
    "2021-07-20" `
    710 `
    3.5

Write-Step "MOVIMENTACAO DE LOTE"

$movements = As-Array (
    Invoke-Atlas GET "/livestock/animals/$($bela.id)/movements"
)

$demoMovement = $movements |
    Where-Object {
        $_.document_reference -eq "ATLAS-DEMO-MOV-001"
    } |
    Select-Object -First 1

if (-not $demoMovement) {
    Invoke-Atlas POST "/livestock/animals/$($bela.id)/movements" @{
        movement_type     = "lot_change"
        to_lot_id         = $lotNovilhas.id
        occurred_at       = (Get-Date).AddDays(-10).ToUniversalTime().ToString("o")
        reason            = "Separação por categoria - carga demonstrativa"
        document_reference = "ATLAS-DEMO-MOV-001"
    } | Out-Null

    Write-Ok "Bela movimentada para DEMO - Novilhas"
}
else {
    Write-Ok "Movimentação de Bela já existe"
}

Write-Step "PESAGENS"

Ensure-Weight $aurora.id 430 3.0 (Get-Date).AddDays(-60) "ATLAS-DEMO-WEIGHT-001" | Out-Null
Ensure-Weight $aurora.id 465 3.25 (Get-Date).AddDays(-30) "ATLAS-DEMO-WEIGHT-002" | Out-Null
Ensure-Weight $aurora.id 480 3.5 (Get-Date).AddDays(-1) "ATLAS-DEMO-WEIGHT-003" | Out-Null

Ensure-Weight $bela.id 315 2.75 (Get-Date).AddDays(-45) "ATLAS-DEMO-WEIGHT-004" | Out-Null
Ensure-Weight $bela.id 340 3.0 (Get-Date).AddDays(-1) "ATLAS-DEMO-WEIGHT-005" | Out-Null

Write-Step "REPRODUCAO"

Ensure-Reproduction `
    $aurora.id `
    "IATF" `
    "iatf" `
    "Procedimento realizado" `
    "awaiting_diagnosis" `
    (Get-Date).AddDays(-45) `
    "ATLAS-DEMO-REPRO-IATF-001" | Out-Null

Ensure-Reproduction `
    $aurora.id `
    "Diagnóstico de gestação" `
    "pregnancy_diagnosis" `
    "Positivo - prenhe" `
    "pregnant" `
    (Get-Date).AddDays(-15) `
    "ATLAS-DEMO-REPRO-DG-001" | Out-Null

Write-Step "ESTOQUE"

$mineral = Ensure-InventoryProduct `
    "DEMO-MIN-001" `
    "Sal Mineral Demo" `
    "Nutrição" `
    "kg" `
    50 `
    3.20 `
    "Fornecedor Nutri Demo"

$vacina = Ensure-InventoryProduct `
    "DEMO-VAC-001" `
    "Vacina Clostridial Demo" `
    "Sanidade" `
    "frasco" `
    5 `
    28.50 `
    "Fornecedor Vet Demo"

$ivermectina = Ensure-InventoryProduct `
    "DEMO-IVE-001" `
    "Ivermectina Demo" `
    "Sanidade" `
    "frasco" `
    4 `
    42.00 `
    "Fornecedor Vet Demo"

$concentrado = Ensure-InventoryProduct `
    "DEMO-CON-001" `
    "Concentrado Homologação V18" `
    "Nutrição" `
    "kg" `
    100 `
    1.95 `
    "Fornecedor Nutri Demo"

Ensure-StockEntry $mineral.id 120 3.20 "stock-mineral-001" | Out-Null
Ensure-StockEntry $vacina.id 12 28.50 "stock-vacina-001" | Out-Null
Ensure-StockEntry $ivermectina.id 8 42.00 "stock-ivermectina-001" | Out-Null
Ensure-StockEntry $concentrado.id 500 1.95 "stock-concentrado-v18-001" | Out-Null

Write-Step "SANIDADE INTEGRADA -> ESTOQUE -> FINANCEIRO -> AGENDA"

$healthVaccine = Ensure-HealthEvent `
    $aurora.id `
    "Vacinação" `
    "Vacina Clostridial Demo" `
    "5 mL" `
    "Subcutânea" `
    (Get-Date).AddDays(-2) `
    (Get-Date).AddDays(160) `
    "ATLAS-HOMO-V18-HEALTH-VACCINE-001" `
    $vacina.id `
    1

$healthDeworm = Ensure-HealthEvent `
    $bela.id `
    "Vermifugação" `
    "Ivermectina Demo" `
    "1 mL / 50 kg" `
    "Subcutânea" `
    (Get-Date).AddDays(-1) `
    (Get-Date).AddDays(78) `
    "ATLAS-HOMO-V18-HEALTH-DEWORM-001" `
    $ivermectina.id `
    1

Write-Step "NUTRICAO"

$ingredient = Ensure-NutritionIngredient `
    "Concentrado Homologação V18" `
    88 `
    18 `
    24 `
    76 `
    1.95 `
    $concentrado.id

$plan = Ensure-NutritionPlan `
    $lotMatrizes.id `
    "Plano Homologação V18 Matrizes"

$nutritionEvent = Ensure-NutritionConsumption `
    $lotMatrizes.id `
    $plan.id `
    $concentrado.id `
    "ATLAS-HOMO-V18-NUTRITION-CONSUMPTION-001"

Write-Step "FINANCEIRO MANUAL + LANCAMENTOS AUTOMATICOS"

Ensure-Finance `
    "expense" `
    "Manutenção" `
    "Manutenção de equipamento - homologação V18" `
    275.00 `
    "finance-maintenance-v18-001" | Out-Null

Ensure-Finance `
    "income" `
    "Venda" `
    "Receita pecuária - homologação V18" `
    6850.00 `
    "finance-income-v18-001" | Out-Null

Write-Step "AGENDA E TAREFAS"

try {
    Ensure-Task `
        "DEMO - Diagnóstico reprodutivo" `
        "Conferir protocolo e diagnóstico da matriz Aurora." `
        "high" `
        (Get-Date).AddDays(3) | Out-Null
}
catch {
    Write-Info "Tarefa reprodutiva não criada: $($_.Exception.Message)"
}

try {
    Ensure-Task `
        "DEMO - Revisar estoque sanitário" `
        "Verificar vacinas, vermífugos e estoque mínimo." `
        "medium" `
        (Get-Date).AddDays(5) | Out-Null
}
catch {
    Write-Info "Tarefa de estoque não criada: $($_.Exception.Message)"
}

Ensure-CalendarEvent `
    "DEMO - Manejo reprodutivo" `
    "Reprodução" `
    "Evento demonstrativo para conferência da agenda." `
    (Get-Date).Date.AddDays(2).AddHours(9) `
    (Get-Date).Date.AddDays(2).AddHours(10) | Out-Null

Ensure-CalendarEvent `
    "DEMO - Manejo sanitário" `
    "Sanidade" `
    "Evento demonstrativo para conferência da agenda." `
    (Get-Date).Date.AddDays(4).AddHours(14) `
    (Get-Date).Date.AddDays(4).AddHours(15) | Out-Null

Write-Step "AUDITORIA FINAL INTEGRADA V18"

$script:AuditFailures = 0
function Assert-Atlas {
    param([bool]$Condition, [string]$Message)
    if ($Condition) {
        Write-Ok $Message
    }
    else {
        $script:AuditFailures++
        Write-Host "[FALHA] $Message" -ForegroundColor Red
    }
}

$lotsFinal = As-Array (Invoke-Atlas GET "/livestock/lots?farm_id=$script:FarmId")
$animalsFinal = As-Array (Invoke-Atlas GET "/livestock/animals?farm_id=$script:FarmId")
$healthFinal = As-Array (Invoke-Atlas GET "/livestock/health?farm_id=$script:FarmId")
$nutritionFinal = As-Array (Invoke-Atlas GET "/livestock/nutrition?farm_id=$script:FarmId")
$financeFinal = As-Array (Invoke-Atlas GET "/livestock/finance/v2?farm_id=$script:FarmId")
$inventoryFinal = As-Array (Invoke-Atlas GET "/livestock/inventory/products?farm_id=$script:FarmId")
$tasksFinal = As-Array (Invoke-Atlas GET "/operations/tasks?farm_id=$script:FarmId")
$reproSummary = Invoke-Atlas GET "/livestock/reproduction/summary?farm_id=$script:FarmId"
$reconciliation = Invoke-Atlas GET "/livestock/integrity/reconciliation?farm_id=$script:FarmId"
$operationalAlerts = Invoke-Atlas GET "/livestock/intelligence/operational-alerts?farm_id=$script:FarmId"
$operationalSummary = Invoke-Atlas GET "/livestock/intelligence/operational-summary?farm_id=$script:FarmId"

$vacinaMovements = As-Array (Invoke-Atlas GET "/livestock/inventory/products/$($vacina.id)/movements")
$ivermectinaMovements = As-Array (Invoke-Atlas GET "/livestock/inventory/products/$($ivermectina.id)/movements")
$concentradoMovements = As-Array (Invoke-Atlas GET "/livestock/inventory/products/$($concentrado.id)/movements")

$healthVaccineStock = $vacinaMovements | Where-Object { $_.reference_type -eq "health_event" -and $_.reference_id -eq $healthVaccine.id } | Select-Object -First 1
$healthDewormStock = $ivermectinaMovements | Where-Object { $_.reference_type -eq "health_event" -and $_.reference_id -eq $healthDeworm.id } | Select-Object -First 1
$nutritionStock = $concentradoMovements | Where-Object { $_.reference_type -eq "nutrition_event" -and $_.reference_id -eq $nutritionEvent.id } | Select-Object -First 1

$healthVaccineFinance = $financeFinal | Where-Object { $_.reference_type -eq "health_event" -and $_.reference_id -eq $healthVaccine.id } | Select-Object -First 1
$healthDewormFinance = $financeFinal | Where-Object { $_.reference_type -eq "health_event" -and $_.reference_id -eq $healthDeworm.id } | Select-Object -First 1
$nutritionFinance = $financeFinal | Where-Object { $_.reference_type -eq "nutrition_event" -and $_.reference_id -eq $nutritionEvent.id } | Select-Object -First 1

$healthVaccineTask = $tasksFinal | Where-Object { $_.source_type -eq "health_event" -and $_.source_id -eq $healthVaccine.id } | Select-Object -First 1
$healthDewormTask = $tasksFinal | Where-Object { $_.source_type -eq "health_event" -and $_.source_id -eq $healthDeworm.id } | Select-Object -First 1

Assert-Atlas ($lotsFinal.Count -ge 2) "Lotes disponíveis"
Assert-Atlas ($animalsFinal.Count -ge 3) "Animais disponíveis"
Assert-Atlas ($null -ne $healthVaccineStock) "Sanidade Vacinação -> Estoque"
Assert-Atlas ($null -ne $healthDewormStock) "Sanidade Vermifugação -> Estoque"
Assert-Atlas ($null -ne $healthVaccineFinance) "Sanidade Vacinação -> Financeiro"
Assert-Atlas ($null -ne $healthDewormFinance) "Sanidade Vermifugação -> Financeiro"
Assert-Atlas ($null -ne $healthVaccineTask) "Sanidade Vacinação -> Agenda operacional"
Assert-Atlas ($null -ne $healthDewormTask) "Sanidade Vermifugação -> Agenda operacional"
Assert-Atlas ($null -ne $nutritionStock) "Nutrição -> Estoque"
Assert-Atlas ($null -ne $nutritionFinance) "Nutrição -> Financeiro"
Assert-Atlas ($reproSummary.farm_id -eq $script:FarmId) "Reprodução -> indicadores"
Assert-Atlas ($reconciliation.farm_id -eq $script:FarmId) "Reconciliação entre módulos"
Assert-Atlas ($operationalSummary.farm_id -eq $script:FarmId) "Inteligência operacional"
Assert-Atlas ($null -ne $operationalAlerts) "Alertas operacionais"

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "ATLAS - HOMOLOGACAO V18 POPULADA" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Fazenda:        $($farm.name)"
Write-Host "Lotes:          $($lotsFinal.Count)"
Write-Host "Animais:        $($animalsFinal.Count)"
Write-Host "Sanidade:       $($healthFinal.Count)"
Write-Host "Nutrição:       $($nutritionFinal.Count)"
Write-Host "Financeiro:     $($financeFinal.Count)"
Write-Host "Estoque:        $($inventoryFinal.Count)"
Write-Host "Tarefas:        $($tasksFinal.Count)"
Write-Host "Score Atlas:    $($operationalSummary.score)"
Write-Host "Alertas:        $($operationalAlerts.Count)"
Write-Host "Falhas auditoria: $script:AuditFailures"
Write-Host ""

if ($script:AuditFailures -gt 0) {
    Write-Host "A carga foi executada, mas existem vínculos integrados com falha." -ForegroundColor Red
    Write-Host "Não considere a homologação aprovada antes de corrigirmos essas falhas." -ForegroundColor Red
    exit 2
}

Write-Host "CARGA E INTEGRACOES APROVADAS. Abra o Atlas e faça a conferência geral." -ForegroundColor Cyan
Write-Host ""
Write-Host "Conferir:"
Write-Host "1. Dashboard e Score operacional"
Write-Host "2. Fazendas/Piquetes"
Write-Host "3. Rebanho e Central do animal DEMO-101"
Write-Host "4. Pesagens e Timeline"
Write-Host "5. Reprodução"
Write-Host "6. Sanidade"
Write-Host "7. Nutrição"
Write-Host "8. Estoque"
Write-Host "9. Financeiro"
Write-Host "10. Agenda Lista/Semana/Mês"
Write-Host "11. Alertas"
Write-Host "12. Análises e decisões"
