param(
    [string]$Levels = "50,100,250,500",
    [string]$Prefix = "paso",
    [int]$Ramp = 20,
    [int]$Hold = 100,
    [switch]$StopOnFail
)

Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force results | Out-Null

if (-not $env:LOAD_EMAIL -or -not $env:LOAD_PASSWORD) {
    Write-Host "Falta definir `$env:LOAD_EMAIL y `$env:LOAD_PASSWORD" -ForegroundColor Red
    exit 1
}

$log = "results\runs.csv"
if (-not (Test-Path $log)) {
    "label,usuarios,inicio_utc,fin_utc,exit_code" | Out-File $log -Encoding ascii
}

foreach ($item in ($Levels -split ",")) {
    $n = [int]$item.Trim()
    $label = "$Prefix$n"
    $inicio = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    Write-Host "=== $label : $n usuarios (inicio $inicio UTC) ===" -ForegroundColor Cyan

    $env:VUS = "$n"
    $env:RAMP = "$Ramp"
    $env:HOLD = "$Hold"
    $env:LABEL = $label
    $env:ABORT = if ($StopOnFail) { "1" } else { "0" }

    k6 run notifications.js
    $code = $LASTEXITCODE

    $fin = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    "$label,$n,$inicio,$fin,$code" | Out-File $log -Append -Encoding ascii

    if ($code -ne 0 -and $StopOnFail) {
        Write-Host "Umbral superado con $n usuarios: se detiene la prueba." -ForegroundColor Yellow
        break
    }
}
Write-Host "Terminado. Resultados en load-tests\results" -ForegroundColor Green