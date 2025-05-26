# Agentic DevOps Landing Page

Esta é a landing page oficial do workshop Agentic DevOps - Azure Observability, construída com React, TypeScript e Vite.

## 🚀 Deploy Automático

A página é automaticamente deployada no GitHub Pages através de GitHub Actions sempre que há mudanças no diretório `landing_page/` na branch `main`.

**URL da Página:** https://paulasilvatech.github.io/Agentic-Ops-Dev/

> Template atualizado para usar agentic-ops-landing-orange.tsx exato

## 🛠️ Tecnologias

- **React 18** - Framework UI
- **TypeScript** - Type safety
- **Vite** - Build tool e dev server
- **Lucide React** - Ícones
- **GitHub Actions** - CI/CD
- **GitHub Pages** - Hospedagem

## 📋 Pré-requisitos para Deploy

### ✅ Já Configurados:

1. **Estrutura do Projeto React**
   - ✅ `package.json` com dependências corretas
   - ✅ `index.html` como entry point
   - ✅ `src/main.tsx` bootstrapping React
   - ✅ `src/LandingPage.tsx` componente principal
   - ✅ `vite.config.ts` com configuração para GitHub Pages
   - ✅ TypeScript configurado

2. **GitHub Actions Workflow**
   - ✅ `.github/workflows/deploy-landing-page.yml`
   - ✅ Trigger automático em mudanças na pasta `landing_page/`
   - ✅ Build e deploy para GitHub Pages

3. **Configurações de Build**
   - ✅ Base path configurado para `/Agentic-Ops-Dev/`
   - ✅ Output configurado para `dist/`
   - ✅ Assets organizados corretamente

### 🔧 Configurações do Repositório GitHub

Para que o deploy funcione completamente, certifique-se de que:

1. **GitHub Pages está habilitado:**
   - Vá em Settings → Pages
   - Source: "GitHub Actions"

2. **Permissions do GITHUB_TOKEN:**
   - Settings → Actions → General
   - Workflow permissions: "Read and write permissions"

## 🏗️ Desenvolvimento Local

```bash
# Instalar dependências
npm install

# Desenvolvimento
npm run dev

# Build para produção
npm run build

# Preview do build
npm run preview
```

## 📁 Estrutura de Arquivos

```
landing_page/
├── public/
│   └── vite.svg
├── src/
│   ├── LandingPage.tsx    # Componente principal
│   ├── main.tsx           # Entry point
│   └── index.css          # Estilos globais
├── index.html             # HTML template
├── package.json           # Dependências
├── vite.config.ts         # Configuração do Vite
└── tsconfig.json          # Configuração TypeScript
```

## 🚨 Troubleshooting

### Build falha com erro TypeScript
- Verifique se todas as dependências estão instaladas
- Execute `npm run build` localmente para verificar erros

### Deploy não funciona
- Verifique se GitHub Pages está configurado corretamente
- Confirme se o workflow tem permissões adequadas
- Verifique logs do GitHub Actions

### Página em branco no GitHub Pages
- Confirme se o `base` está configurado corretamente no `vite.config.ts`
- Verifique se os assets estão sendo carregados com o path correto

## 📝 Como Fazer Deploy

1. **Fazer mudanças** no código da landing page
2. **Commit e push** para a branch `main`
3. **GitHub Actions** automaticamente:
   - Faz build do projeto
   - Deploy para GitHub Pages
4. **Verificar** se a página está disponível em: https://pauloasilva-ms.github.io/Agentic-Ops-Dev/

## ⚡ Performance

- Bundle size otimizado com Vite
- Assets são automaticamente otimizados
- CSS e JS são minificados no build
- SVG icons são tree-shaken automaticamente
