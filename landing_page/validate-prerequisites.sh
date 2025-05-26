#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Validating prerequisites for Agentic Operations Landing Page..."
echo ""

# Check Node.js
echo -n "Checking Node.js... "
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1 | sed 's/v//')
    if [ $MAJOR_VERSION -ge 18 ]; then
        echo -e "${GREEN}✓${NC} Node.js $NODE_VERSION installed"
    else
        echo -e "${RED}✗${NC} Node.js version 18+ required (found $NODE_VERSION)"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Node.js not installed"
    echo "Please install Node.js 18+ from https://nodejs.org/"
    exit 1
fi

# Check npm
echo -n "Checking npm... "
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    echo -e "${GREEN}✓${NC} npm $NPM_VERSION installed"
else
    echo -e "${RED}✗${NC} npm not installed"
    exit 1
fi

# Check if package.json exists
echo -n "Checking package.json... "
if [ -f "package.json" ]; then
    echo -e "${GREEN}✓${NC} package.json found"
else
    echo -e "${RED}✗${NC} package.json not found"
    echo "Make sure you're in the landing_page directory"
    exit 1
fi

# Check GitHub repository
echo -n "Checking GitHub repository... "
if git remote -v | grep -q "github.com"; then
    REPO_URL=$(git remote get-url origin)
    echo -e "${GREEN}✓${NC} GitHub repository configured: $REPO_URL"
else
    echo -e "${YELLOW}⚠${NC} No GitHub remote found"
    echo "Make sure to push to a GitHub repository for GitHub Pages deployment"
fi

# Check if GitHub Pages is enabled (this is just a reminder)
echo ""
echo -e "${YELLOW}📝 GitHub Pages Setup Reminder:${NC}"
echo "1. Go to your repository settings on GitHub"
echo "2. Navigate to Pages section"
echo "3. Under 'Build and deployment', select 'GitHub Actions' as the source"
echo ""

# Check if dependencies are installed
echo -n "Checking node_modules... "
if [ -d "node_modules" ]; then
    echo -e "${GREEN}✓${NC} Dependencies installed"
else
    echo -e "${YELLOW}⚠${NC} Dependencies not installed"
    echo "Run 'npm install' to install dependencies"
fi

echo ""
echo -e "${GREEN}✅ Prerequisites validation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Run 'npm install' if you haven't already"
echo "2. Run 'npm run dev' to start development server"
echo "3. Push to main branch to trigger automatic deployment"
echo "" 