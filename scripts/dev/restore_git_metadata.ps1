param(
    [string]$RepositoryUrl = "https://github.com/gabrielbeserran-sketch/atlas.git",
    [string]$Branch = "master"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$gitDir = Join-Path $root ".git"

if (Test-Path $gitDir) {
    Write-Host "Git já está configurado." -ForegroundColor Green
    git -C $root remote -v
    git -C $root branch --show-current
    exit 0
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ("atlas_git_" + [Guid]::NewGuid().ToString("N"))

try {
    git clone --branch $Branch --single-branch --no-checkout $RepositoryUrl $temp
    if ($LASTEXITCODE -ne 0) { throw "Falha ao clonar os metadados Git." }

    Copy-Item -Path (Join-Path $temp ".git") -Destination $gitDir -Recurse -Force

    Write-Host "Metadados Git restaurados sem substituir o código." -ForegroundColor Green
    git -C $root status --short
}
finally {
    if (Test-Path $temp) {
        Remove-Item $temp -Recurse -Force
    }
}
