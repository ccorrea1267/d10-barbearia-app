# 🔍 DEBUG - Script de Diagnóstico
# Execute para ver exatamente onde está o problema

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  🔍 DIAGNÓSTICO DE DEPLOY                     ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Yellow

# 1. Verificar Git
Write-Host "[1/6] Verificando Git..." -ForegroundColor Cyan
git --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Git NÃO está instalado!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Git OK`n" -ForegroundColor Green

# 2. Verificar Node/npm
Write-Host "[2/6] Verificando Node.js..." -ForegroundColor Cyan
node --version
npm --version
Write-Host "✅ Node.js OK`n" -ForegroundColor Green

# 3. Verificar variáveis de ambiente
Write-Host "[3/6] Verificando variáveis de ambiente..." -ForegroundColor Cyan
if ($env:GITHUB_TOKEN) {
    Write-Host "✅ GITHUB_TOKEN: $($env:GITHUB_TOKEN.Substring(0,10))..." -ForegroundColor Green
} else {
    Write-Host "❌ GITHUB_TOKEN: NÃO definido" -ForegroundColor Red
}

if ($env:GITHUB_USERNAME) {
    Write-Host "✅ GITHUB_USERNAME: $env:GITHUB_USERNAME" -ForegroundColor Green
} else {
    Write-Host "❌ GITHUB_USERNAME: NÃO definido" -ForegroundColor Red
}

if ($env:GITHUB_EMAIL) {
    Write-Host "✅ GITHUB_EMAIL: $env:GITHUB_EMAIL" -ForegroundColor Green
} else {
    Write-Host "❌ GITHUB_EMAIL: NÃO definido" -ForegroundColor Red
}

if ($env:VERCEL_TOKEN) {
    Write-Host "✅ VERCEL_TOKEN: $($env:VERCEL_TOKEN.Substring(0,10))..." -ForegroundColor Green
} else {
    Write-Host "❌ VERCEL_TOKEN: NÃO definido" -ForegroundColor Red
}
Write-Host ""

# 4. Verificar repositório no GitHub
Write-Host "[4/6] Verificando repositório no GitHub..." -ForegroundColor Cyan

$headers = @{
    "Authorization" = "token $($env:GITHUB_TOKEN)"
    "Accept" = "application/vnd.github.v3+json"
}

try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$($env:GITHUB_USERNAME)/d10-barbearia-app" `
        -Headers $headers `
        -ErrorAction SilentlyContinue

    if ($response) {
        Write-Host "✅ Repositório encontrado em GitHub" -ForegroundColor Green
        Write-Host "   URL: $($response.html_url)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Repositório não encontrado" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Erro ao verificar: $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""

# 5. Verificar Git config local
Write-Host "[5/6] Verificando Git config local..." -ForegroundColor Cyan
git config user.name
git config user.email
Write-Host ""

# 6. Testar push
Write-Host "[6/6] Testando push (com detalhes)..." -ForegroundColor Cyan
Write-Host "  Remote atual:" -ForegroundColor Gray
git remote -v

Write-Host "  Tentando push..." -ForegroundColor Gray
git push -u origin main -v 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Push bem-sucedido!" -ForegroundColor Green
} else {
    Write-Host "❌ Erro no push" -ForegroundColor Red
    Write-Host "  Último código de erro: $LASTEXITCODE" -ForegroundColor Red
}

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  FIM DO DIAGNÓSTICO                           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
