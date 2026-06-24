[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$baseUrl = "https://rrnoxicqxuubirucybph.supabase.co"
$anonKey = "sb_publishable_TR3I0nVwDhlTz8SM-H0YSg_C_nSs5m_"

$headers = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
}

Write-Host "=== Verificando Supabase Cloud ===" -ForegroundColor Cyan

# Verificar cada tabela
$tables = @("profiles", "eventos", "checkins", "mural_posts", "conexoes", "interesses", "materiais")

foreach ($table in $tables) {
    try {
        $url = "$baseUrl/rest/v1/$table`?select=*&limit=1"
        $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers -TimeoutSec 10
        Write-Host "[OK] $table : existe" -ForegroundColor Green
    } catch {
        $errMsg = $_.Exception.Message
        Write-Host "[FAIL] $table : $errMsg" -ForegroundColor Red
    }
}

# Criar usuario admin
Write-Host "" 
Write-Host "=== Criando usuario admin ===" -ForegroundColor Cyan
$signupBody = @{
    email = "tiagonrose2@gmail.com"
    password = "Zepilintra4656032"
    data = @{
        nome = "Tiago Gontias"
    }
} | ConvertTo-Json -Compress

try {
    $signupUrl = "$baseUrl/auth/v1/signup"
    $signupResponse = Invoke-RestMethod -Uri $signupUrl -Method POST -ContentType "application/json" -Body $signupBody -Headers $headers -TimeoutSec 15
    Write-Host "Usuario criado com sucesso!" -ForegroundColor Green
    Write-Host "User ID: $($signupResponse.user.id)"
} catch {
    $errMsg = $_.Exception.Message
    if ($errMsg -like "*already*registered*" -or $errMsg -like "*duplicate*") {
        Write-Host "Usuario ja existe (isso e ok)" -ForegroundColor Yellow
    } else {
        Write-Host "Erro ao criar: $errMsg" -ForegroundColor Red
    }
}
