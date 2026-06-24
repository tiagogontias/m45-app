$body = @{
    identity = "tiagonrose2@gmail.com"
    password = "*2026Zepilintra4656032"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://127.0.0.1:8090/api/collections/_superusers/auth-with-password" -Method POST -ContentType "application/json" -Body $body

$token = $response.token
Write-Host "Token: $token"

# Salvar token em arquivo
$token | Out-File "C:\m45\flutter_app\.hermes\plans\pb_token.txt" -Encoding utf8

# Salvar response completa
$response | ConvertTo-Json -Depth 10 | Out-File "C:\m45\flutter_app\.hermes\plans\pb_token.json" -Encoding utf8

Write-Host "Token salvo com sucesso"
