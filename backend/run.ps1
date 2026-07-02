$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $root "src\main\java"
$out = Join-Path $root "out"
$driver = Join-Path $root "lib\kingbase8.jar"
$lib = Join-Path $root "lib"
$localEnv = Join-Path $root ".env.local.ps1"

if (Test-Path $localEnv) {
  . $localEnv
}

if (!(Test-Path $driver)) {
  Write-Host "Missing KingbaseES JDBC driver: $driver" -ForegroundColor Yellow
  Write-Host "Copy kingbase8.jar to backend\lib\kingbase8.jar, then run this script again."
  exit 1
}

if (!(Test-Path $out)) {
  New-Item -ItemType Directory -Path $out | Out-Null
}

$sources = Get-ChildItem -Path $src -Recurse -Filter *.java | ForEach-Object { $_.FullName }
$classpath = "$out;$lib\*"
javac -encoding UTF-8 -source 8 -target 8 -cp "$lib\*" -d $out $sources

$env:KINGBASE_URL = if ($env:KINGBASE_URL) { $env:KINGBASE_URL } else { "jdbc:kingbase8://101.42.99.139:54321/smart_greenhouse" }
$env:KINGBASE_USERNAME = if ($env:KINGBASE_USERNAME) { $env:KINGBASE_USERNAME } else { "system" }
$env:KINGBASE_PASSWORD = if ($env:KINGBASE_PASSWORD) { $env:KINGBASE_PASSWORD } else { "123456" }
$env:DEEPSEEK_API_KEY = if ($env:DEEPSEEK_API_KEY) { $env:DEEPSEEK_API_KEY } else { "" }
$env:SERVER_PORT = if ($env:SERVER_PORT) { $env:SERVER_PORT } else { "8080" }

java -cp $classpath com.smartgreenhouse.backend.BackendApplication
