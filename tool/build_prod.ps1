$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $root "config\prod.json"
$signingPath = Join-Path $root "android\key.properties"

if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Missing config\prod.json. Copy config\prod.example.json and provide Supabase production values."
}

if (-not (Test-Path -LiteralPath $signingPath)) {
    throw "Missing android\key.properties. Configure release signing before building production."
}

Push-Location $root
try {
    flutter build apk --release --flavor prod -t lib/main.dart --dart-define-from-file="$configPath"
}
finally {
    Pop-Location
}
