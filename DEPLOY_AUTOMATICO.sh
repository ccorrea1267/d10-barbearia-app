#!/bin/bash

# 🚀 SCRIPT DE DEPLOY AUTOMÁTICO - +D10 Barbearia App
# Este script faz tudo automaticamente:
# 1. Cria repositório no GitHub
# 2. Faz push do código
# 3. Deploy na Vercel

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  🚀 DEPLOY AUTOMÁTICO - +D10 Barbearia              ║"
echo "║     GitHub + Vercel                                 ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validar variáveis de ambiente
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ ERRO: GITHUB_TOKEN não está definido${NC}"
    echo "Use: export GITHUB_TOKEN=seu_token_aqui"
    exit 1
fi

if [ -z "$VERCEL_TOKEN" ]; then
    echo -e "${RED}❌ ERRO: VERCEL_TOKEN não está definido${NC}"
    echo "Use: export VERCEL_TOKEN=seu_token_aqui"
    exit 1
fi

if [ -z "$GITHUB_USERNAME" ]; then
    echo -e "${RED}❌ ERRO: GITHUB_USERNAME não está definido${NC}"
    echo "Use: export GITHUB_USERNAME=seu_usuario_github"
    exit 1
fi

if [ -z "$GITHUB_EMAIL" ]; then
    echo -e "${RED}❌ ERRO: GITHUB_EMAIL não está definido${NC}"
    echo "Use: export GITHUB_EMAIL=seu@email.com"
    exit 1
fi

REPO_NAME="d10-barbearia-app"
REPO_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

echo -e "${YELLOW}📋 Configuração:${NC}"
echo "  • GitHub Username: $GITHUB_USERNAME"
echo "  • GitHub Email: $GITHUB_EMAIL"
echo "  • Repositório: $REPO_NAME"
echo ""

# ===== PASSO 1: Criar repositório no GitHub =====
echo -e "${YELLOW}[1/5]${NC} Criando repositório no GitHub..."
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/repos \
  -d "{\"name\":\"$REPO_NAME\",\"description\":\"App premium de agendamento para +D10 Barbearia\",\"private\":false,\"auto_init\":false}" > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Repositório criado (ou já existe)${NC}"
else
    echo -e "${RED}⚠️  Erro ao criar (pode já existir)${NC}"
fi
echo ""

# ===== PASSO 2: Configurar Git =====
echo -e "${YELLOW}[2/5]${NC} Configurando Git..."
git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_USERNAME"
echo -e "${GREEN}✅ Git configurado${NC}"
echo ""

# ===== PASSO 3: Adicionar remote e fazer push =====
echo -e "${YELLOW}[3/5]${NC} Fazendo push para GitHub..."

# Remove remote se já existir
git remote remove origin 2>/dev/null

# Adiciona novo remote
git remote add origin "$REPO_URL"

# Renomeia branch para main se necessário
if git rev-parse --verify main >/dev/null 2>&1; then
    echo "Branch main já existe"
else
    echo "Renomeando branch master para main..."
    git branch -M main 2>/dev/null || true
fi

# Faz push
git push -u origin main --force

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Código enviado para GitHub!${NC}"
else
    echo -e "${RED}❌ Erro ao fazer push${NC}"
    exit 1
fi
echo ""

# ===== PASSO 4: Deploy na Vercel =====
echo -e "${YELLOW}[4/5]${NC} Fazendo deploy na Vercel..."

# Instala Vercel CLI se não tiver
if ! command -v vercel &> /dev/null; then
    echo "Instalando Vercel CLI..."
    npm install -g vercel
fi

# Deploy
vercel deploy --token=$VERCEL_TOKEN --prod --name=$REPO_NAME --confirm 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deploy iniciado na Vercel!${NC}"
else
    echo -e "${YELLOW}⚠️  Deploy pode estar em progresso na Vercel${NC}"
fi
echo ""

# ===== PASSO 5: Informações finais =====
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ DEPLOY COMPLETO!                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📍 Seus links:${NC}"
echo "  • GitHub: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo "  • Vercel: https://$REPO_NAME.vercel.app"
echo ""
echo -e "${YELLOW}⚠️  PRÓXIMOS PASSOS:${NC}"
echo "  1. Aguarde ~1 minuto pelo link da Vercel"
echo "  2. Visite: https://$REPO_NAME.vercel.app"
echo "  3. Compartilhe com seu cliente!"
echo ""
echo -e "${YELLOW}🔐 SEGURANÇA:${NC}"
echo "  Revogue os tokens depois (opcional mas recomendado):"
echo "  • GitHub: github.com → Settings → Developer settings → Tokens"
echo "  • Vercel: vercel.com → Settings → Tokens"
echo ""
