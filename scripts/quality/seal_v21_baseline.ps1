param(
    [string]$Tag = "v21-baseline-ux-homologada",
    [string]$Message = "checkpoint: Atlas V21 baseline UX homologada"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git não encontrado no PATH."
}

$inside = git rev-parse --is-inside-work-tree
if ($LASTEXITCODE -ne 0 -or $inside -ne "true") {
    throw "A pasta atual não é um repositório Git válido."
}

$status = git status --porcelain
if ($status) {
    Write-Host "Existem alterações não commitadas:" -ForegroundColor Yellow
    $status | ForEach-Object { Write-Host $_ }
    throw "A baseline só pode ser selada com working tree limpa."
}

$existing = git tag --list $Tag
if ($existing -eq $Tag) {
    Write-Host "Tag $Tag já existe. Nenhuma alteração foi feita." -ForegroundColor Yellow
    exit 0
}

$head = git rev-parse HEAD
Write-Host "HEAD: $head" -ForegroundColor Cyan
Write-Host "Criando tag anotada $Tag..." -ForegroundColor Cyan
git tag -a $Tag -m $Message
if ($LASTEXITCODE -ne 0) {
    throw "Falha ao criar tag $Tag."
}

Write-Host ""
Write-Host "ATLAS V21 BASELINE SELADA LOCALMENTE" -ForegroundColor Green
Write-Host "Tag: $Tag" -ForegroundColor Green
Write-Host "Commit: $head" -ForegroundColor Green
Write-Host ""
Write-Host "Para publicar a tag no GitHub:" -ForegroundColor Cyan
Write-Host "git push origin $Tag"
