param(
    [Parameter(Mandatory=$true)]
    [string]$ApiUrl
)
. "$PSScriptRoot\atlas_android_common.ps1"
$root = Get-AtlasRoot
Set-Location $root
$api = Assert-ProductionApiUrl -ApiUrl $ApiUrl

flutter build apk `
    --release `
    --dart-define=ATLAS_ENV=production `
    --dart-define="ATLAS_API_BASE_URL=$api"
if ($LASTEXITCODE -ne 0) { throw "Build APK falhou." }

$dist = "$root\dist\android"
New-Item -ItemType Directory -Force -Path $dist | Out-Null
Copy-Item `
    "$root\build\app\outputs\flutter-apk\app-release.apk" `
    "$dist\atlas-1.0.0+6-release.apk" `
    -Force

Write-Host "ATLAS RELEASE APK: APROVADO" -ForegroundColor Green
