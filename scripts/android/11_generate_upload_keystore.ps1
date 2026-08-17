param([string]$Alias = "atlas-upload")

. "$PSScriptRoot\atlas_android_common.ps1"
$root = Get-AtlasRoot
$keytool = Get-KeytoolPath
$dir = Join-Path $root "android\keystore"
$keystore = Join-Path $dir "atlas-upload.jks"
$keyProperties = Join-Path $root "android\key.properties"

New-Item -ItemType Directory -Force -Path $dir | Out-Null
if (Test-Path $keystore) {
    throw "Keystore já existe. Não sobrescreva a upload key."
}

$password1 = Read-Host "Senha forte para o keystore" -AsSecureString
$password2 = Read-Host "Repita a senha" -AsSecureString
$plain1 = ConvertTo-PlainText $password1
$plain2 = ConvertTo-PlainText $password2

try {
    if ($plain1 -ne $plain2) { throw "As senhas não coincidem." }
    if ($plain1.Length -lt 12) { throw "Use pelo menos 12 caracteres." }

    & $keytool `
        -genkeypair -v `
        -keystore $keystore `
        -storepass $plain1 `
        -keypass $plain1 `
        -alias $Alias `
        -keyalg RSA `
        -keysize 4096 `
        -validity 10000 `
        -dname "CN=Atlas Upload, OU=Beserra, O=Beserra, L=Brasilia, ST=DF, C=BR"

    if ($LASTEXITCODE -ne 0) { throw "keytool falhou." }

    $content = "storePassword=$plain1`nkeyPassword=$plain1`nkeyAlias=$Alias`nstoreFile=../keystore/atlas-upload.jks`n"
    [IO.File]::WriteAllText(
        $keyProperties,
        $content,
        [Text.UTF8Encoding]::new($false)
    )
    Write-Host "ATLAS UPLOAD KEYSTORE: CRIADO" -ForegroundColor Green
    Write-Warning "Faça backup offline do JKS e da senha."
}
finally {
    $plain1 = $null
    $plain2 = $null
}
