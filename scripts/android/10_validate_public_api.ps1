param(
    [Parameter(Mandatory=$true)]
    [string]$ApiUrl
)
. "$PSScriptRoot\atlas_android_common.ps1"

$api = Assert-ProductionApiUrl -ApiUrl $ApiUrl
try {
    $response = Invoke-RestMethod `
        -Uri "$api/health/ready" `
        -Method Get `
        -TimeoutSec 20
}
catch {
    throw "API HTTPS não respondeu: $($_.Exception.Message)"
}
if ($response.status -ne "ready") {
    throw "Readiness não retornou status=ready."
}
Write-Host "ATLAS PUBLIC HTTPS API: APROVADA" -ForegroundColor Green
