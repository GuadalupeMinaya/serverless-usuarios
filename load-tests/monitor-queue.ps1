Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force results | Out-Null

$q   = aws sqs get-queue-url --queue-name usuarios-api-notifications --query QueueUrl --output text
$dlq = aws sqs get-queue-url --queue-name usuarios-api-notifications-dlq --query QueueUrl --output text

$log = "results\cola.csv"
if (-not (Test-Path $log)) {
    "hora_utc,visibles,en_proceso,dlq_visibles" | Out-File $log -Encoding ascii
}

Write-Host "Monitoreando la cola cada ~7 s. Ctrl+C para detener." -ForegroundColor Cyan

while ($true) {
    $a = aws sqs get-queue-attributes --queue-url $q --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible --output json | ConvertFrom-Json
    $b = aws sqs get-queue-attributes --queue-url $dlq --attribute-names ApproximateNumberOfMessages --output json | ConvertFrom-Json

    $hora = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $vis  = $a.Attributes.ApproximateNumberOfMessages
    $proc = $a.Attributes.ApproximateNumberOfMessagesNotVisible
    $dl   = $b.Attributes.ApproximateNumberOfMessages

    "$hora,$vis,$proc,$dl" | Out-File $log -Append -Encoding ascii
    Write-Host "$hora  visibles=$vis  en_proceso=$proc  dlq=$dl"

    Start-Sleep -Seconds 5
}