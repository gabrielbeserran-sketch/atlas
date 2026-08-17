. "$PSScriptRoot\atlas_android_common.ps1"
$root = Get-AtlasRoot
$ip = Get-AtlasLanIPv4
$api = "http://${ip}:8000/api/v1"
Write-Host "Backend para o celular: $api" -ForegroundColor Cyan
Write-Host "Mantenha computador e celular na mesma rede Wi-Fi." -ForegroundColor Yellow
Set-Location "$root\backend"
if (-not (Test-Path ".\.venv\Scripts\python.exe")) {
    throw "A .venv do backend não foi encontrada."
}
& ".\.venv\Scripts\python.exe" -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
