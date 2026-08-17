$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $root

Write-Host "=== ATLAS - CORRECAO DE SEGREDOS RASTREADOS PELO GIT ===" -ForegroundColor Cyan

$secretPatterns = @(
    '(^|[\\/])\.env$',
    '\.jks$',
    '\.keystore$',
    '(^|[\\/])key\.properties$',
    'credentials?\.json$',
    'service[-_]?account\.json$'
)

function Test-SecretPath {
    param([Parameter(Mandatory=$true)][string]$Path)

    foreach ($pattern in $secretPatterns) {
        if ($Path -match $pattern) {
            return $true
        }
    }

    return $false
}

$trackedSecrets = @(
    git ls-files |
        Where-Object { Test-SecretPath $_ }
)

if (-not $trackedSecrets -or $trackedSecrets.Count -eq 0) {
    Write-Host "Nenhum arquivo secreto está rastreado pelo Git." -ForegroundColor Green
}
else {
    Write-Host "Arquivos secretos rastreados encontrados:" -ForegroundColor Yellow

    $trackedSecrets | ForEach-Object {
        Write-Host " - $_" -ForegroundColor Yellow
    }

    foreach ($path in $trackedSecrets) {
        git rm --cached --ignore-unmatch -- "$path"

        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao retirar '$path' do índice Git."
        }
    }

    Write-Host ""
    Write-Host "Os arquivos locais foram preservados; apenas deixaram de ser rastreados." -ForegroundColor Green
}

Write-Host ""
Write-Host "Validando backend/.env..." -ForegroundColor Cyan

if (Test-Path ".\backend\.env") {
    $ignoreResult = git check-ignore -v -- ".\backend\.env"

    if ($LASTEXITCODE -ne 0 -or -not $ignoreResult) {
        throw "backend/.env existe, mas ainda não está protegido pelo .gitignore."
    }

    $ignoreResult | Write-Host
}

Write-Host ""
Write-Host "ATLAS GIT TRACKED-SECRETS FIX: APROVADO" -ForegroundColor Green
