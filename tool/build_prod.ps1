$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $root "config\prod.json"
$ownerPath = Join-Path $root "config\owner.json"
$signingPath = Join-Path $root "android\key.properties"

if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Missing config\prod.json. Copy config\prod.example.json and provide Supabase production values."
}

if (-not (Test-Path -LiteralPath $ownerPath)) {
    throw "Missing config\owner.json. Copy config\owner.example.json and provide the predefined shop owner details."
}

if (-not (Test-Path -LiteralPath $signingPath)) {
    throw "Missing android\key.properties. Configure release signing before building production."
}

Push-Location $root
try {
    flutter build apk --release --flavor prod -t lib/main.dart --dart-define-from-file="$configPath" --dart-define-from-file="$ownerPath"
}
finally {
    Pop-Location
}
