Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-AtlasRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Assert-Command {
    param([Parameter(Mandatory=$true)][string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Comando '$Name' não encontrado no PATH."
    }
}

function Get-AtlasAndroidSdkRoot {
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($env:ANDROID_SDK_ROOT) { $candidates.Add($env:ANDROID_SDK_ROOT) }
    if ($env:ANDROID_HOME) { $candidates.Add($env:ANDROID_HOME) }
    if ($env:LOCALAPPDATA) {
        $candidates.Add((Join-Path $env:LOCALAPPDATA "Android\Sdk"))
    }

    $root = Get-AtlasRoot
    $localProperties = Join-Path $root "android\local.properties"
    if (Test-Path $localProperties) {
        $line = Get-Content $localProperties |
            Where-Object { $_ -match '^sdk\.dir=' } |
            Select-Object -First 1
        if ($line) {
            $value = ($line -replace '^sdk\.dir=', '').Trim()
            $value = $value -replace '\\\\', '\'
            if ($value) { $candidates.Add($value) }
        }
    }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if ($candidate -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }
    throw "Android SDK não encontrado."
}

function Get-AtlasAdbPath {
    $command = Get-Command adb -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $sdk = Get-AtlasAndroidSdkRoot
    $candidate = Join-Path $sdk "platform-tools\adb.exe"
    if (Test-Path $candidate) { return $candidate }
    throw "ADB não encontrado."
}

function Get-AtlasAuthorizedAndroidDeviceId {
    $adb = Get-AtlasAdbPath
    $devices = @()
    foreach ($line in (& $adb devices)) {
        if ($line -match '^([^\s]+)\s+device$') { $devices += $Matches[1] }
    }
    if ($devices.Count -eq 0) {
        throw "Nenhum Android autorizado encontrado via ADB."
    }
    return $devices[0]
}

function Assert-ProductionApiUrl {
    param([Parameter(Mandatory=$true)][string]$ApiUrl)

    $value = $ApiUrl.Trim().TrimEnd('/')
    if (-not $value.StartsWith("https://", [StringComparison]::OrdinalIgnoreCase)) {
        throw "Release exige ATLAS_API_BASE_URL HTTPS."
    }

    $uri = [Uri]$value
    $hostName = $uri.Host.ToLowerInvariant()
    if ($hostName -in @("localhost", "127.0.0.1", "::1") -or
        $hostName.EndsWith(".local") -or
        $hostName.Contains("example")) {
        throw "Release recusa host local/placeholder: $hostName"
    }

    if (-not $value.EndsWith("/api/v1")) { $value = "$value/api/v1" }
    return $value
}

function Assert-Java17 {
    Assert-Command java
    $versionText = (& java -version 2>&1 | Select-Object -First 1).ToString()
    if ($versionText -notmatch '"(1\.)?([0-9]+)') {
        throw "Não foi possível identificar Java: $versionText"
    }
    if ([int]$Matches[2] -lt 17) {
        throw "Android release exige JDK 17+."
    }
}

function Assert-AndroidApi36 {
    $sdk = Get-AtlasAndroidSdkRoot
    if (-not (Test-Path (Join-Path $sdk "platforms\android-36\android.jar"))) {
        throw "Android SDK Platform 36 não está instalado."
    }
}

function Get-KeytoolPath {
    $command = Get-Command keytool -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    if ($env:JAVA_HOME) {
        $candidate = Join-Path $env:JAVA_HOME "bin\keytool.exe"
        if (Test-Path $candidate) { return $candidate }
    }
    throw "keytool não encontrado."
}

function ConvertTo-PlainText {
    param([Parameter(Mandatory=$true)][Security.SecureString]$SecureString)
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}
