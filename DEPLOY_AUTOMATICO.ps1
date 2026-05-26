# 🚀 SCRIPT DE DEPLOY AUTOMÁTICO - +D10 Barbearia App
# PowerShell Version (sem WSL)
# Execute: ./DEPLOY_AUTOMATICO.ps1

Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🚀 DEPLOY AUTOMÁTICO - +D10 Barbearia              ║" -ForegroundColor Cyan
Write-Host "║     GitHub + Vercel (PowerShell)                    ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Validar variáveis de ambiente
if (-not $env:GITHUB_TOKEN) {
    Write-Host "❌ ERRO: GITHUB_TOKEN não está definido" -ForegroundColor Red
    Write-Host "Use: `$env:GITHUB_TOKEN = 'seu_token_aqui'" -ForegroundColor Yellow
    exit 1
}

if (-not $env:VERCEL_TOKEN) {
    Write-Host "❌ ERRO: VERCEL_TOKEN não está definido" -ForegroundColor Red
    Write-Host "Use: `$env:VERCEL_TOKEN = 'seu_token_aqui'" -ForegroundColor Yellow
    exit 1
}

if (-not $env:GITHUB_USERNAME) {
    Write-Host "❌ ERRO: GITHUB_USERNAME não está definido" -ForegroundColor Red
    Write-Host "Use: `$env:GITHUB_USERNAME = 'seu_usuario'" -ForegroundColor Yellow
    exit 1
}

if (-not $env:GITHUB_EMAIL) {
    Write-Host "❌ ERRO: GITHUB_EMAIL não está definido" -ForegroundColor Red
    Write-Host "Use: `$env:GITHUB_EMAIL = 'seu@email.com'" -ForegroundColor Yellow
    exit 1
}

$REPO_NAME = "d10-barbearia-app"
$GITHUB_TOKEN = $env:GITHUB_TOKEN
$GITHUB_USERNAME = $env:GITHUB_USERNAME
$GITHUB_EMAIL = $env:GITHUB_EMAIL
$VERCEL_TOKEN = $env:VERCEL_TOKEN

Write-Host "📋 Configuração:" -ForegroundColor Yellow
Write-Host "  • GitHub Username: $GITHUB_USERNAME" -ForegroundColor Gray
Write-Host "  • GitHub Email: $GITHUB_EMAIL" -ForegroundColor Gray
Write-Host "  • Repositório: $REPO_NAME" -ForegroundColor Gray
Write-Host ""

# ===== PASSO 1: Criar repositório no GitHub =====
Write-Host "[1/5] Criando repositório no GitHub..." -ForegroundColor Yellow

$headers = @{
    "Authorization" = "token $GITHUB_TOKEN"
    "Accept" = "application/vnd.github.v3+json"
}

$body = @{
    name = $REPO_NAME
    description = "App premium de agendamento para +D10 Barbearia"
    private = $false
    auto_init = $false
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" `
        -Method POST `
        -Headers $headers `
        -Body $body `
        -ErrorAction SilentlyContinue

    Write-Host "✅ Repositório criado (ou já existe)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Repositório pode já existir (continuando...)" -ForegroundColor Yellow
}

Write-Host ""

# ===== PASSO 2: Configurar Git =====
Write-Host "[2/5] Configurando Git..." -ForegroundColor Yellow

git config --global user.email $GITHUB_EMAIL
git config --global user.name $GITHUB_USERNAME

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Git configurado" -ForegroundColor Green
} else {
    Write-Host "⚠️  Erro ao configurar Git (Git instalado?)" -ForegroundColor Yellow
}

Write-Host ""

# ===== PASSO 3: Adicionar remote e fazer push =====
Write-Host "[3/5] Fazendo push para GitHub..." -ForegroundColor Yellow

# Remove remote se já existir
git remote remove origin 2>$null

# Cria URL com token
$REPO_URL = "https://$($GITHUB_TOKEN)@github.com/$GITHUB_USERNAME/$REPO_NAME.git"

# Adiciona novo remote
git remote add origin $REPO_URL

# Verifica branch
$branch = git rev-parse --abbrev-ref HEAD
Write-Host "  Branch atual: $branch" -ForegroundColor Gray

# Se for master, renomeia para main
if ($branch -eq "master") {
    Write-Host "  Renomeando branch master → main..." -ForegroundColor Gray
    git branch -M main 2>$null
}

# Faz push
Write-Host "  Enviando código..." -ForegroundColor Gray
git push -u origin main --force 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Código enviado para GitHub!" -ForegroundColor Green
} else {
    Write-Host "❌ Erro ao fazer push" -ForegroundColor Red
    Write-Host "Dica: Git instalado e configurado?" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# ===== PASSO 4: Instalar Vercel CLI =====
Write-Host "[4/5] Instalando Vercel CLI..." -ForegroundColor Yellow

$vercelExists = npm list -g vercel 2>$null | Select-String "vercel"

if (-not $vercelExists) {
    Write-Host "  Instalando Vercel CLI (primeira vez)..." -ForegroundColor Gray
    npm install -g vercel 2>$null
}

Write-Host "✅ Vercel CLI pronto" -ForegroundColor Green
Write-Host ""

# ===== PASSO 5: Deploy na Vercel =====
Write-Host "[5/5] Fazendo deploy na Vercel..." -ForegroundColor Yellow

# Seta token no arquivo de config
$vercelConfig = @{
    "token" = $VERCEL_TOKEN
} | ConvertTo-Json

Write-Host "  Iniciando deploy..." -ForegroundColor Gray

# Deploy com token
& vercel deploy --token=$VERCEL_TOKEN --prod --name=$REPO_NAME --confirm 2>$null

if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 139) {
    Write-Host "✅ Deploy iniciado na Vercel!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Deploy pode estar em progresso" -ForegroundColor Yellow
}

Write-Host ""

# ===== Resultado Final =====
Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ DEPLOY COMPLETO!                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📍 Seus links:" -ForegroundColor Yellow
Write-Host "  • GitHub: https://github.com/$GITHUB_USERNAME/$REPO_NAME" -ForegroundColor Cyan
Write-Host "  • Vercel: https://$REPO_NAME.vercel.app" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "  1. Aguarde ~1 minuto pelo link da Vercel" -ForegroundColor Gray
Write-Host "  2. Visite: https://$REPO_NAME.vercel.app" -ForegroundColor Gray
Write-Host "  3. Teste em seu navegador" -ForegroundColor Gray
Write-Host "  4. Compartilhe com seu cliente!" -ForegroundColor Gray
Write-Host ""

Write-Host "🔐 SEGURANÇA (Opcional):" -ForegroundColor Yellow
Write-Host "  Revogue os tokens depois:" -ForegroundColor Gray
Write-Host "  • GitHub: github.com → Settings → Developer settings → Tokens" -ForegroundColor Gray
Write-Host "  • Vercel: vercel.com → Settings → Tokens" -ForegroundColor Gray
Write-Host ""

Write-Host "🎉 Pronto! Seu app está no ar!" -ForegroundColor Green
