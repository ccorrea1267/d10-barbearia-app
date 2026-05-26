# 🚀 Como Rodar o Deploy Automático

Siga **EXATAMENTE** esses passos:

---

## 📋 Requisitos

- ✅ Git instalado ([baixar](https://git-scm.com))
- ✅ Node.js instalado ([baixar](https://nodejs.org))
- ✅ Seus tokens GitHub e Vercel

---

## 🎯 Passo a Passo

### 1️⃣ Abra PowerShell (ou Terminal)

**Windows:**
- Pressione `WIN + R`
- Digite: `powershell`
- Pressione `ENTER`

**Mac/Linux:**
- Abra Terminal normalmente

---

### 2️⃣ Vá para a pasta do projeto

```bash
cd C:\Users\Carlos\Downloads\d10-barbearia-app
```

(Copie e cole exatamente)

---

### 3️⃣ Defina suas variáveis de ambiente

**Windows (PowerShell):**

```powershell
$env:GITHUB_TOKEN = "ghp_sua_chave_aqui"
$env:GITHUB_USERNAME = "seu_usuario_github"
$env:GITHUB_EMAIL = "seu@email.com"
$env:VERCEL_TOKEN = "vercel_sua_chave_aqui"
```

**Mac/Linux:**

```bash
export GITHUB_TOKEN="ghp_sua_chave_aqui"
export GITHUB_USERNAME="seu_usuario_github"
export GITHUB_EMAIL="seu@email.com"
export VERCEL_TOKEN="vercel_sua_chave_aqui"
```

---

### 4️⃣ Execute o script

**Windows (PowerShell):**

```powershell
bash DEPLOY_AUTOMATICO.sh
```

**Mac/Linux:**

```bash
bash DEPLOY_AUTOMATICO.sh
```

ou

```bash
./DEPLOY_AUTOMATICO.sh
```

---

## ✅ O script vai fazer:

1. ✅ Criar repositório no GitHub
2. ✅ Fazer push do seu código
3. ✅ Deploy automático na Vercel
4. ✅ Gerar seu link público

---

## 🎉 Resultado

Ao final, você terá:

```
GitHub: https://github.com/seu_usuario/d10-barbearia-app
Vercel: https://d10-barbearia-app.vercel.app
```

---

## ❓ Se der erro...

**Erro: "git not found"**
- Git não está instalado
- Baixe em: https://git-scm.com

**Erro: "GITHUB_TOKEN not defined"**
- Você não preencheu as variáveis no Passo 3
- Copie e cole EXATAMENTE como mostrado

**Erro: "Repositório já existe"**
- Tudo bem! O script continua e faz push mesmo assim
- Se quiser, delete no GitHub e rode de novo

**Repositório criado mas Vercel não fez deploy**
- Espere 2-3 minutos
- Acesse: https://d10-barbearia-app.vercel.app
- Se não funcionar, vá em vercel.com e faça import manual

---

## 🎬 Vídeo rápido dos passos

1. Abrir PowerShell
2. `cd C:\Users\Carlos\Downloads\d10-barbearia-app`
3. Colar as 4 linhas de variáveis ($env:...)
4. `bash DEPLOY_AUTOMATICO.sh`
5. Aguardar ~1 minuto
6. Copiar link e compartilhar com cliente! 🚀

---

## 💡 Dica final

Se tiver dúvidas, rode cada comando separadamente para ver se algo dá erro:

```bash
# Teste Git
git --version

# Teste Node
node --version

# Teste Vercel CLI
npm install -g vercel
vercel --version

# Depois rode o deploy
bash DEPLOY_AUTOMATICO.sh
```

---

**Sucesso! 🎉**
