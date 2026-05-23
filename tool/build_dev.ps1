param(
    [ValidateSet("debug", "release")]
    [string]$BuildMode = "debug"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $root "config\dev.json"
$ownerPath = Join-Path $root "config\owner.json"

if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Missing config\dev.json. Copy config\dev.example.json and provide local development values."
}

if (-not (Test-Path -LiteralPath $ownerPath)) {
    throw "Missing config\owner.json. Copy config\owner.example.json and provide the predefined shop owner details."
}

Push-Location $root
try {
    flutter build apk "--$BuildMode" --flavor dev -t lib/main.dart --dart-define-from-file="$configPath" --dart-define-from-file="$ownerPath"
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter dev APK build failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
