$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $root ".env"
$configDirectory = Join-Path $root "config"
$ownerPath = Join-Path $configDirectory "owner.json"

if (-not (Test-Path -LiteralPath $envPath)) {
    throw "Missing .env. Create it locally or create config JSON files manually."
}

$values = @{}
foreach ($line in Get-Content -LiteralPath $envPath) {
    $trimmed = $line.Trim()
    if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#")) {
        continue
    }
    $parts = $trimmed.Split("=", 2)
    if ($parts.Length -eq 2) {
        $values[$parts[0].Trim()] = $parts[1].Trim().Trim('"').Trim("'")
    }
}

$supabaseKey = $values["SUPABASE_PUBLISHABLE_KEY"]
if ([string]::IsNullOrWhiteSpace($supabaseKey)) {
    $supabaseKey = $values["SUPABASE_ANON_KEY"]
}

$dev = [ordered]@{
    APP_ENV = "dev"
    SUPABASE_URL = ""
    SUPABASE_PUBLISHABLE_KEY = ""
    SESSION_TTL_DAYS = $values["SESSION_TTL_DAYS"]
}
$prod = [ordered]@{
    APP_ENV = "prod"
    SUPABASE_URL = $values["SUPABASE_URL"]
    SUPABASE_PUBLISHABLE_KEY = $supabaseKey
}
$owner = [ordered]@{
    OWNER_NAME = "Navaa Tailors"
    SHOP_NAME = "Digital Tailoring Studio"
    OWNER_PHONE = "9999999999"
    SHOP_ADDRESS = "Shop No. 12, Main Road, Near Landmark"
    OWNER_DEFAULT_PASSWORD = "ChangeMe@12345"
}

if (-not (Test-Path -LiteralPath $configDirectory)) {
    New-Item -ItemType Directory -Path $configDirectory | Out-Null
}

$dev | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $configDirectory "dev.json")
$prod | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $configDirectory "prod.json")
if (-not (Test-Path -LiteralPath $ownerPath)) {
    $owner | ConvertTo-Json | Set-Content -LiteralPath $ownerPath
}

Write-Host "Created local dev/prod configuration; created config\owner.json only when it did not already exist."
