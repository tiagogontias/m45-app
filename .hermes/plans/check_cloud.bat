@echo off
echo === Verificando Supabase Cloud ===

curl -s -w "\nHTTP_CODE: %{http_code}\n" "https://rrnoxicqxuubirucybph.supabase.co/rest/v1/profiles?select=*" -H "apikey: <_REDACTED> -H "Authorization: Bearer <_REDACTED>"

echo.
echo === Verificando eventos ===
curl -s -w "\nHTTP_CODE: %{http_code}\n" "https://rrnoxicqxuubirucybph.supabase.co/rest/v1/eventos?select=*" -H "apikey: <_REDACTED> -H "Authorization: Bearer <_REDACTED>"

echo.
echo === Verificando mural_posts ===
curl -s -w "\nHTTP_CODE: %{http_code}\n" "https://rrnoxicqxuubirucybph.supabase.co/rest/v1/mural_posts?select=*" -H "apikey: <_REDACTED> -H "Authorization: Bearer <_REDACTED>"

echo.
echo === Criando usuario admin ===
curl -s -w "\nHTTP_CODE: %{http_code}\n" -X POST "https://rrnoxicqxuubirucybph.supabase.co/auth/v1/signup" -H "apikey: <_REDACTED> -H "Authorization: Bearer <_REDACTED> -H "Content-Type: application/json" -d "{\"email\":\"tiagonrose2@gmail.com\",\"password\":\"Zepilintra4656032\",\"data\":{\"nome\":\"Tiago Gontias\"}}"
