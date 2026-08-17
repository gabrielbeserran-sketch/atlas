$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $root

Write-Host "=== ATLAS - AUDITORIA DE SEGREDOS NO GIT ===" -ForegroundColor Cyan

$secretPatterns = @(
    '(^|[\\/])\.env$',
    '\.jks$',
    '\.keystore$',
    '(^|[\\/])key\.properties$',
    'service[_-]?role',
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

$errors = New-Object System.Collections.Generic.List[string]

# ------------------------------------------------------------------
# 1. Segredos efetivamente rastreados no índice atual.
# ------------------------------------------------------------------
$trackedSecrets = @(
    git ls-files |
        Where-Object { Test-SecretPath $_ }
)

foreach ($path in $trackedSecrets) {
    $errors.Add("arquivo secreto rastreado pelo Git: $path")
}

# ------------------------------------------------------------------
# 2. Segredos sendo ADICIONADOS/COPIADOS/MODIFICADOS/RENOMEADOS no commit.
#    Deleções NÃO são erro: retirar um .env previamente rastreado é
#    justamente a correção de segurança desejada.
# ------------------------------------------------------------------
$stagedUnsafeSecrets = @(
    git diff --cached --name-only --diff-filter=ACMRT |
        Where-Object { Test-SecretPath $_ }
)

foreach ($path in $stagedUnsafeSecrets) {
    $errors.Add("arquivo secreto preparado para inclusão/alteração no commit: $path")
}

# Registra separadamente deleções seguras para não tratá-las como falha.
$stagedSecretDeletions = @(
    git diff --cached --name-only --diff-filter=D |
        Where-Object { Test-SecretPath $_ }
)

if ($stagedSecretDeletions.Count -gt 0) {
    Write-Host "Segredos sendo removidos do Git (ação segura):" -ForegroundColor Green
    $stagedSecretDeletions | ForEach-Object {
        Write-Host " - $_" -ForegroundColor Green
    }
}

# ------------------------------------------------------------------
# 3. Arquivos secretos visíveis no status.
#    Uma deleção staged de segredo é permitida.
#    Um arquivo local ignorado não aparece no status e também é seguro.
# ------------------------------------------------------------------
$statusLines = @(git status --porcelain=v1)

foreach ($line in $statusLines) {
    if ($line.Length -lt 4) {
        continue
    }

    $xy = $line.Substring(0, 2)
    $path = $line.Substring(3).Trim()

    if (-not $path -or -not (Test-SecretPath $path)) {
        continue
    }

    $isStagedDeletion = (
        $xy[0] -eq 'D' -and
        $stagedSecretDeletions -contains $path
    )

    if ($isStagedDeletion) {
        continue
    }

    # Se ainda está rastreado ou staged para inclusão/alteração,
    # já será reportado acima. Evita mensagem duplicada.
    if (
        $trackedSecrets -contains $path -or
        $stagedUnsafeSecrets -contains $path
    ) {
        continue
    }

    $errors.Add("arquivo secreto visível no status Git: $path")
}

# ------------------------------------------------------------------
# 4. backend/.env local, quando existir, precisa estar protegido.
#    O comando check-ignore pode retornar 1 enquanto a remoção do índice
#    ainda está staged em algumas combinações de Git/Windows. Por isso
#    validamos também a regra diretamente com --no-index.
# ------------------------------------------------------------------
if (Test-Path ".\backend\.env") {
    git check-ignore -q --no-index -- ".\backend\.env"

    if ($LASTEXITCODE -ne 0) {
        $errors.Add("backend/.env existe, mas não está protegido pelo .gitignore")
    }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "ATLAS GIT SECRET AUDIT: FAIL" -ForegroundColor Red

    $errors |
        Sort-Object -Unique |
        ForEach-Object {
            Write-Host " - $_" -ForegroundColor Red
        }

    exit 1
}

Write-Host ""
Write-Host "ATLAS GIT SECRET AUDIT: APROVADO" -ForegroundColor Green
