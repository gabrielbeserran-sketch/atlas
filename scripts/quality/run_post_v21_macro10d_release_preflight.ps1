$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
Write-Host "=== ATLAS POS-V21 MACROPACOTE 10D - PREFLIGHT ===" -ForegroundColor Cyan

$releaseScripts = @(
    '.\scripts\quality\run_post_v21_macro10d_v1_rc_homologation.ps1',
    '.\scripts\quality\run_post_v21_macro10d_release_preflight.ps1',
    '.\scripts\quality\stage_post_v21_macro10d_release.ps1',
    '.\scripts\quality\check_post_v21_macro10d_staged_release.ps1',
    '.\scripts\quality\check_post_v21_macro10d_deployed.ps1'
)

foreach ($script in $releaseScripts) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path $script),
        [ref]$tokens,
        [ref]$errors
    ) | Out-Null
    if ($errors.Count -gt 0) {
        $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        throw "Sintaxe PowerShell reprovada: $script"
    }
}

python .\tools\atlas_post_v21_macro10d_v1_rc_gate.py
if ($LASTEXITCODE -ne 0) {
    throw "Gate 10D reprovado no preflight."
}

python .\scripts\quality\atlas_powershell_static_audit.py
if ($LASTEXITCODE -ne 0) {
    throw "Auditoria PowerShell reprovada."
}

git diff --check
if ($LASTEXITCODE -ne 0) {
    throw "git diff --check encontrou inconsistencias."
}

Write-Host "ATLAS POS-V21 MACROPACOTE 10D: PREFLIGHT APROVADO" -ForegroundColor Green
