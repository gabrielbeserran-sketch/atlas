param(
    [Parameter(Mandatory=$true)]
    [string]$DuckDnsSubdomain,

    [string]$DeviceId = ""
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

& "$PSScriptRoot\09_validate_free_duckdns_api.ps1" -DuckDnsSubdomain $name
if ($LASTEXITCODE -ne 0) {
    throw "API gratuita DuckDNS não foi homologada."
}

& "$PSScriptRoot\16_marco6_gate.ps1" -ApiUrl $api -DeviceId $DeviceId
exit $LASTEXITCODE
