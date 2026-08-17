param(
    [Parameter(Mandatory=$true)]
    [string]$ApiUrl,
    [string]$DeviceId = ""
)
& "$PSScriptRoot\16_marco6_gate.ps1" -ApiUrl $ApiUrl -DeviceId $DeviceId
exit $LASTEXITCODE
