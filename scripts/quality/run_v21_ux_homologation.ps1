param(
    [string]$BaseUrl = "https://atlas-api-29y2.onrender.com/api/v1",
    [switch]$SkipProductionSmoke
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
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

function Assert-ExitCode {
    param([string]$Step)
    if ($LASTEXITCODE -ne 0) {
        throw "$Step falhou com código $LASTEXITCODE."
    }
}

function Assert-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name não foi encontrado no PATH."
    }
}

Write-Host "=== ATLAS V21 - HOMOLOGAÇÃO FINAL DA BASELINE UX ===" -ForegroundColor Cyan
Write-Host "Render/Supabase: produção remota. Este gate NÃO sobe Docker e NÃO executa migrations." -ForegroundColor DarkGray

Assert-Command "flutter"
Assert-Command "dart"

$Python = Get-Command python -ErrorAction SilentlyContinue
if (-not $Python) { $Python = Get-Command py -ErrorAction SilentlyContinue }
if (-not $Python) { throw "Python não encontrado para os gates estáticos." }
$Py = $Python.Source

Write-Host "[0/11] Conferência da árvore e higiene Dart" -ForegroundColor Yellow
$NutritionFile = Join-Path $ProjectRoot "lib\features\nutrition\presentation\screens\nutrition_overview_screen.dart"
if (-not (Test-Path $NutritionFile)) {
    throw "Arquivo de Nutrição não encontrado. A extração do pacote está incompleta."
}
$NutritionContent = Get-Content -Raw -Encoding UTF8 $NutritionFile
if ($NutritionContent -match "\bforestGreen\b") {
    throw "A árvore instalada ainda contém o campo obsoleto forestGreen em Nutrição. Substitua o projeto pelo pacote V21.2 completo."
}
& $Py tools\atlas_v21_2_dart_hygiene_gate.py
Assert-ExitCode "Higiene Dart V21.2"
& $Py tools\atlas_v21_3_test_contract_gate.py
Assert-ExitCode "Contrato de testes V21.3"
& $Py tools\atlas_v21_4_production_smoke_resilience_gate.py
Assert-ExitCode "Resiliência do smoke V21.4"
& $Py tools\atlas_v21_5_powershell_hygiene_gate.py
Assert-ExitCode "Higiene PowerShell V21.5"
& $Py tools\atlas_powershell_parameter_forwarding_gate.py
Assert-ExitCode "Encaminhamento de parâmetros PowerShell"
& $Py tools\atlas_v21_6_critical_flows_gate.py
Assert-ExitCode "Contratos dos 14 fluxos V21.6"
& $Py tools\atlas_v21_windows_build_lock_gate.py
Assert-ExitCode "Proteção contra lock do executável Windows"

Write-Host "[1/11] Dependências Flutter" -ForegroundColor Yellow
flutter pub get
Assert-ExitCode "flutter pub get"

Write-Host "[2/11] Formatação automática" -ForegroundColor Yellow
dart format lib test
Assert-ExitCode "dart format"

Write-Host "[3/11] Análise estática Flutter" -ForegroundColor Yellow
flutter analyze
Assert-ExitCode "flutter analyze"

Write-Host "[4/11] Testes Flutter" -ForegroundColor Yellow
flutter test
Assert-ExitCode "flutter test"

Write-Host "[5/11] Build Windows contra produção" -ForegroundColor Yellow

function Stop-AtlasWindowsProcess {
    $processes = @(Get-Process -Name "projeto_atlas" -ErrorAction SilentlyContinue)
    if ($processes.Count -gt 0) {
        Write-Host "      Fechando instância anterior do Projeto Atlas para liberar o executável..." -ForegroundColor DarkYellow
        $processes | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }

    $stillRunning = @(Get-Process -Name "projeto_atlas" -ErrorAction SilentlyContinue)
    if ($stillRunning.Count -gt 0) {
        throw "Não foi possível encerrar a instância anterior de projeto_atlas.exe."
    }
}

function Invoke-AtlasWindowsBuild {
    param([int]$Attempts = 2)

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        Stop-AtlasWindowsProcess

        flutter build windows --debug `
            --dart-define=ATLAS_ENV=production `
            --dart-define="ATLAS_API_BASE_URL=$BaseUrl"

        if ($LASTEXITCODE -eq 0) { return }

        if ($attempt -lt $Attempts) {
            Write-Host "      Build falhou. Limpando somente build\windows e tentando novamente..." -ForegroundColor DarkYellow
            Stop-AtlasWindowsProcess
            $WindowsBuild = Join-Path $ProjectRoot "build\windows"
            if (Test-Path $WindowsBuild) {
                Remove-Item $WindowsBuild -Recurse -Force -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 2
        }
    }

    throw "flutter build windows falhou após $Attempts tentativa(s)."
}

Invoke-AtlasWindowsBuild
if ($LASTEXITCODE -ne 0) { throw "flutter build windows falhou." }

Write-Host "[6/11] Gates UX V20.7-V20.10" -ForegroundColor Yellow
& $Py tools\atlas_v20_7_module_consistency_gate.py
Assert-ExitCode "V20.7"
& $Py tools\atlas_v20_8_animal_center_gate.py
Assert-ExitCode "V20.8"
& $Py tools\atlas_v20_9_accessibility_gate.py
Assert-ExitCode "V20.9"
& $Py tools\atlas_v20_10_integrated_ux_gate.py
Assert-ExitCode "V20.10"

Write-Host "[7/11] Auditoria estática da baseline" -ForegroundColor Yellow
& $Py scripts\quality\atlas_baseline_static_audit.py
Assert-ExitCode "Baseline static audit"

Write-Host "[8/11] Auditoria estrutural completa" -ForegroundColor Yellow
& $Py scripts\quality\atlas_full_project_audit.py
Assert-ExitCode "Full project audit"

Write-Host "[9/11] Compilação Python do backend" -ForegroundColor Yellow
& $Py -m compileall -q backend\app backend\alembic scripts tools
Assert-ExitCode "Python compileall"

Write-Host "[10/11] Smoke test Render/Supabase" -ForegroundColor Yellow
if ($SkipProductionSmoke) {
    Write-Host "Ignorado. A baseline NÃO deve ser congelada sem este teste." -ForegroundColor Yellow
} else {
    & "$ProjectRoot\scripts\quality\gate_v16_v17_production.ps1" -BaseUrl $BaseUrl
    Assert-ExitCode "Smoke test Render/Supabase"
}

Write-Host "[11/11] Executável Windows" -ForegroundColor Yellow
$Exe = Join-Path $ProjectRoot "build\windows\x64\runner\Debug\projeto_atlas.exe"
if (-not (Test-Path $Exe)) {
    throw "Executável Windows não encontrado em $Exe."
}

Write-Host ""
Write-Host "ATLAS V21: GATES AUTOMÁTICOS APROVADOS" -ForegroundColor Green
Write-Host "Executável: $Exe" -ForegroundColor Green
Write-Host "Agora valide visualmente os 14 fluxos do checklist V21." -ForegroundColor Cyan
