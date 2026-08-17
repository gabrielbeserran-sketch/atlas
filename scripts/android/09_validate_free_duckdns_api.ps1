param(
    [Parameter(Mandatory=$true)]
    [string]$DuckDnsSubdomain
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$name = $DuckDnsSubdomain.Trim().ToLowerInvariant()

if ($name.EndsWith(".duckdns.org")) {
    $name = $name.Substring(0, $name.Length - ".duckdns.org".Length)
}

if ($name -notmatch '^[a-z0-9-]{1,63}$') {
    throw "Subdomínio DuckDNS inválido."
}

$api = "https://$name.duckdns.org/api/v1"
$ready = "$api/health/ready"

try {
    $response = Invoke-RestMethod -Uri $ready -Method Get -TimeoutSec 20
}
catch {
    throw "API gratuita HTTPS não respondeu: $($_.Exception.Message)"
}

if ($response.status -ne "ready") {
    throw "Readiness não retornou status=ready."
}

Write-Host "ATLAS FREE PUBLIC API: APROVADA" -ForegroundColor Green
Write-Host $api -ForegroundColor Green
