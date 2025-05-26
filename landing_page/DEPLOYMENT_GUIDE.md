# 🚀 Agentic Operations Landing Page - Deployment Guide

This guide provides step-by-step instructions for deploying the Agentic Operations landing page to GitHub Pages.

## 📋 Prerequisites Checklist

- [x] Node.js 18+ installed
- [x] npm package manager
- [x] GitHub repository (https://github.com/paulasilvatech/Agentic-Ops-Dev)
- [ ] GitHub Pages enabled in repository settings
- [ ] Dependencies installed (`npm install`)

## 🛠️ Setup Instructions

### 1. Enable GitHub Pages

1. Go to https://github.com/paulasilvatech/Agentic-Ops-Dev/settings
2. Scroll down to the **Pages** section
3. Under **Build and deployment**:
   - Source: Select **GitHub Actions**
   - This enables the workflow to deploy automatically

### 2. Install Dependencies

```bash
cd landing_page
npm install
```

### 3. Test Locally

```bash
# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## 🚀 Deployment Process

### Automatic Deployment (Recommended)

The landing page will automatically deploy when:
- You push changes to the `main` branch
- Changes are made to files in the `landing_page/` directory
- The workflow file is modified

### Manual Deployment

1. Go to the [Actions tab](https://github.com/paulasilvatech/Agentic-Ops-Dev/actions)
2. Select "Deploy Landing Page to GitHub Pages"
3. Click "Run workflow"
4. Select the branch and click "Run workflow"

### First-Time Deployment

For the first deployment:

```bash
# Make sure you're in the repository root
git add .
git commit -m "Add landing page with GitHub Pages deployment"
git push origin main
```

## 📊 Monitoring Deployment

### Check Workflow Status

1. Go to [Actions](https://github.com/paulasilvatech/Agentic-Ops-Dev/actions)
2. Look for "Deploy Landing Page to GitHub Pages"
3. Click on the latest run to see details

### Deployment URL

Once deployed, your landing page will be available at:
```
https://paulasilvatech.github.io/Agentic-Ops-Dev/
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Workflow Not Running
- Ensure GitHub Actions is enabled in repository settings
- Check if the workflow file is in `.github/workflows/`
- Verify the branch name matches the workflow trigger

#### 2. Build Failures
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
```

#### 3. 404 Error After Deployment
- Wait 5-10 minutes for GitHub Pages to propagate
- Check the base path in `vite.config.ts` matches your repository name
- Ensure the workflow completed successfully

#### 4. Permission Errors
- Go to Settings → Actions → General
- Under "Workflow permissions", select "Read and write permissions"

### Verify Deployment

```bash
# Check if the site is accessible
curl -I https://paulasilvatech.github.io/Agentic-Ops-Dev/
```

## 📝 Configuration Details

### vite.config.ts
```typescript
base: '/Agentic-Ops-Dev/',  // Must match repository name
```

### package.json
```json
"homepage": "https://paulasilvatech.github.io/Agentic-Ops-Dev"
```

## 🔄 Updating Content

1. Edit files in `landing_page/src/`
2. Test locally with `npm run dev`
3. Commit and push changes
4. Workflow will automatically deploy

## 📊 Performance Optimization

The build process includes:
- Minification of JavaScript and CSS
- Tree-shaking for unused code
- Optimized asset loading
- Source maps for debugging

## 🔐 Security Considerations

- The workflow uses minimal permissions
- No secrets or sensitive data in the landing page
- All dependencies are from npm registry
- Regular dependency updates recommended

## 📞 Support

If you encounter issues:
1. Check the [Actions logs](https://github.com/paulasilvatech/Agentic-Ops-Dev/actions)
2. Review this guide's troubleshooting section
3. Ensure all prerequisites are met
4. Open an issue in the repository if needed

## ✅ Success Indicators

You'll know the deployment is successful when:
- ✅ GitHub Actions workflow shows green checkmark
- ✅ Site is accessible at the GitHub Pages URL
- ✅ All assets load correctly
- ✅ No console errors in browser

---

**Last Updated**: December 2024
**Maintained by**: Paula Silva (@paulasilvatech) 