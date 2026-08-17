. "$PSScriptRoot\atlas_android_common.ps1"
$ip = Get-AtlasLanIPv4
$urls = @(
    "http://127.0.0.1:8000/docs",
    "http://${ip}:8000/docs",
    "http://127.0.0.1:8000/openapi.json"
)
foreach ($url in $urls) {
    Write-Host "Testando $url" -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -ne 200) { throw "HTTP $($response.StatusCode)" }
        Write-Host "OK: $url" -ForegroundColor Green
    } catch {
        if ($url -like "http://${ip}:*") {
            Write-Host "Aviso: acesso LAN falhou. O Atlas poderá usar túnel USB ADB para o primeiro teste." -ForegroundColor Yellow
        } else {
            throw "Backend local não respondeu em $url. Inicie 02_start_backend_lan.ps1 em outro terminal. Erro: $($_.Exception.Message)"
        }
    }
}
Write-Host "PASSOS 11-12 OK: backend local validado." -ForegroundColor Green
