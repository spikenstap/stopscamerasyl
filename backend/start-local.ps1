param([string]$BindAddress = '192.168.123.34')
$ErrorActionPreference = 'Stop'
$dockerDirectory = Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\resources\bin'
if (Test-Path -LiteralPath $dockerDirectory) {
    $env:PATH = $dockerDirectory + ';' + $env:PATH
}
$env:BACKEND_BIND_IP = $BindAddress
Push-Location $PSScriptRoot
try {
    docker compose -p stopscam-local -f docker-compose.yml -f docker-compose.lan.yml up -d --build
    if ($LASTEXITCODE -ne 0) { throw 'Docker startup failed. Open Docker Desktop and retry.' }
    Write-Host "Backend: http://${BindAddress}:8000"
    Write-Host "Phone browser check: http://${BindAddress}:8000/healthz"
} finally {
    Pop-Location
}
