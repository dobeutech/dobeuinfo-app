#!/bin/bash
# runbook.sh - Operational runbook generator and helper
# Provides operational procedures and troubleshooting guides

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}📖 Operational Runbook${NC}"
echo "======================"
echo ""

cd "$PROJECT_ROOT"

# Menu
echo "Select runbook section:"
echo "  1) Quick Start Guide"
echo "  2) Development Setup"
echo "  3) Build and Deploy"
echo "  4) Troubleshooting"
echo "  5) Common Tasks"
echo "  6) Emergency Procedures"
echo "  7) Generate Full Runbook"
echo "  0) Exit"
echo ""
read -p "Select option (0-7): " OPTION

case $OPTION in
    1)
        # Quick Start
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo -e "${CYAN}Quick Start Guide${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo ""
        echo "1. Clone the repository:"
        echo "   git clone $(git config --get remote.origin.url 2>/dev/null || echo '<repository-url>')"
        echo ""
        echo "2. Install dependencies:"
        echo "   npm install"
        echo ""
        echo "3. Start development server:"
        echo "   npm run dev"
        echo ""
        echo "4. Open browser:"
        echo "   http://localhost:5173"
        echo ""
        echo "5. Make changes and see live updates"
        echo ""
        ;;
        
    2)
        # Development Setup
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo -e "${CYAN}Development Setup${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo ""
        echo "Prerequisites:"
        echo "  • Node.js $(cat .nvmrc 2>/dev/null || echo '18+')"
        echo "  • npm or yarn"
        echo "  • Git"
        echo ""
        echo "Setup Steps:"
        echo ""
        echo "1. Install Node.js:"
        echo "   Download from https://nodejs.org/"
        echo "   Or use nvm: nvm install $(cat .nvmrc 2>/dev/null || echo '18')"
        echo ""
        echo "2. Clone repository:"
        echo "   git clone $(git config --get remote.origin.url 2>/dev/null || echo '<repository-url>')"
        echo "   cd $(basename "$PROJECT_ROOT")"
        echo ""
        echo "3. Install dependencies:"
        echo "   npm install"
        echo ""
        echo "4. Configure environment (if needed):"
        echo "   cp .env.example .env"
        echo "   # Edit .env with your values"
        echo ""
        echo "5. Start development:"
        echo "   npm run dev"
        echo ""
        echo "IDE Setup:"
        echo "  • VSCode: Install recommended extensions"
        echo "  • Enable format on save"
        echo "  • Install ESLint and Prettier extensions"
        echo ""
        ;;
        
    3)
        # Build and Deploy
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo -e "${CYAN}Build and Deploy${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo ""
        echo "Build for Production:"
        echo ""
        echo "1. Run build:"
        echo "   npm run build"
        echo ""
        echo "2. Test production build locally:"
        echo "   npm run preview"
        echo ""
        echo "3. Build output:"
        echo "   Location: dist/"
        echo "   Deploy this folder to your hosting service"
        echo ""
        echo "Deployment Options:"
        echo ""
        echo "Vercel:"
        echo "  1. Install Vercel CLI: npm i -g vercel"
        echo "  2. Deploy: vercel"
        echo "  3. Production: vercel --prod"
        echo ""
        echo "Netlify:"
        echo "  1. Install Netlify CLI: npm i -g netlify-cli"
        echo "  2. Deploy: netlify deploy"
        echo "  3. Production: netlify deploy --prod"
        echo ""
        echo "GitHub Pages:"
        echo "  1. Build: npm run build"
        echo "  2. Deploy: gh-pages -d dist"
        echo ""
        echo "Manual Deployment:"
        echo "  1. Build: npm run build"
        echo "  2. Upload dist/ folder to your server"
        echo "  3. Configure web server to serve index.html"
        echo ""
        ;;
        
    4)
        # Troubleshooting
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo -e "${CYAN}Troubleshooting Guide${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo ""
        echo "Common Issues and Solutions:"
        echo ""
        echo "1. npm install fails:"
        echo "   • Clear cache: npm cache clean --force"
        echo "   • Delete node_modules: rm -rf node_modules"
        echo "   • Delete package-lock.json: rm package-lock.json"
        echo "   • Reinstall: npm install"
        echo ""
        echo "2. Dev server won't start:"
        echo "   • Check port 5173 is available"
        echo "   • Kill process: lsof -ti:5173 | xargs kill -9"
        echo "   • Try different port: npm run dev -- --port 3000"
        echo ""
        echo "3. Build fails:"
        echo "   • Check for TypeScript errors"
        echo "   • Run: npm run build -- --debug"
        echo "   • Check dependencies are installed"
        echo ""
        echo "4. Module not found errors:"
        echo "   • Reinstall dependencies: npm install"
        echo "   • Check import paths are correct"
        echo "   • Restart dev server"
        echo ""
        echo "5. Hot reload not working:"
        echo "   • Restart dev server"
        echo "   • Clear browser cache"
        echo "   • Check file watcher limits (Linux)"
        echo ""
        echo "6. Git issues:"
        echo "   • Merge conflicts: git status, resolve conflicts"
        echo "   • Reset changes: git reset --hard HEAD"
        echo "   • Clean untracked: git clean -fd"
        echo ""
        echo "7. Performance issues:"
        echo "   • Clear node_modules: rm -rf node_modules && npm install"
        echo "   • Update dependencies: npm update"
        echo "   • Check bundle size: npm run build"
        echo ""
        ;;
        
    5)
        # Common Tasks
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo -e "${CYAN}Common Tasks${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo ""
        echo "Development Tasks:"
        echo ""
        echo "Create new page:"
        echo "  bash scripts/automation/page-create.sh PageName"
        echo ""
        echo "Create component test:"
        echo "  bash scripts/automation/test-component.sh ComponentName"
        echo ""
        echo "Run tests:"
        echo "  npm test"
        echo "  npm test -- --watch"
        echo "  npm test -- --coverage"
        echo ""
        echo "Code quality:"
        echo "  npm run lint"
        echo "  npm run format"
        echo "  bash scripts/automation/reviewer.sh"
        echo ""
        echo "Git workflow:"
        echo "  git checkout -b feature/new-feature"
        echo "  git add ."
        echo "  bash scripts/automation/commit-help.sh"
        echo "  git push origin feature/new-feature"
        echo ""
        echo "Update dependencies:"
        echo "  npm outdated"
        echo "  npm update"
        echo "  npm audit fix"
        echo ""
        echo "Generate changelog:"
        echo "  bash scripts/automation/changelog.sh"
        echo ""
        ;;
        
    6)
        # Emergency Procedures
        echo ""
        echo -e "${RED}═══════════════════════════════════════${NC}"
        echo -e "${RED}Emergency Procedures${NC}"
        echo -e "${RED}═══════════════════════════════════════${NC}"
        echo ""
        echo "Production Down:"
        echo ""
        echo "1. Check service status:"
        echo "   • Visit site in browser"
        echo "   • Check hosting provider dashboard"
        echo "   • Check DNS resolution: nslookup yourdomain.com"
        echo ""
        echo "2. Quick rollback:"
        echo "   • Revert to last known good commit"
        echo "   • git revert HEAD"
        echo "   • Redeploy immediately"
        echo ""
        echo "3. Emergency hotfix:"
        echo "   • Create hotfix branch: git checkout -b hotfix/issue"
        echo "   • Make minimal fix"
        echo "   • Test locally: npm run build && npm run preview"
        echo "   • Deploy immediately"
        echo "   • Merge to main after verification"
        echo ""
        echo "Security Incident:"
        echo ""
        echo "1. Immediate actions:"
        echo "   • Take site offline if necessary"
        echo "   • Rotate all credentials"
        echo "   • Check for unauthorized changes: git log"
        echo ""
        echo "2. Investigation:"
        echo "   • Review access logs"
        echo "   • Check for malicious code"
        echo "   • Run security audit: npm audit"
        echo ""
        echo "3. Recovery:"
        echo "   • Update all dependencies"
        echo "   • Apply security patches"
        echo "   • Redeploy from clean state"
        echo ""
        echo "Data Loss:"
        echo ""
        echo "1. Check backups:"
        echo "   • Git history: git reflog"
        echo "   • Local backups"
        echo "   • Hosting provider backups"
        echo ""
        echo "2. Recovery:"
        echo "   • Restore from git: git checkout <commit>"
        echo "   • Restore from backup"
        echo "   • Rebuild if necessary"
        echo ""
        ;;
        
    7)
        # Generate Full Runbook
        echo ""
        echo "Generating full runbook..."
        
        RUNBOOK_FILE="$PROJECT_ROOT/docs/RUNBOOK.md"
        mkdir -p "$PROJECT_ROOT/docs"
        
        cat > "$RUNBOOK_FILE" << 'EOF'
# Operational Runbook

## Table of Contents

1. [Quick Start](#quick-start)
2. [Development Setup](#development-setup)
3. [Build and Deploy](#build-and-deploy)
4. [Troubleshooting](#troubleshooting)
5. [Common Tasks](#common-tasks)
6. [Emergency Procedures](#emergency-procedures)
7. [Monitoring](#monitoring)
8. [Contacts](#contacts)

## Quick Start

### Prerequisites
- Node.js 18+
- npm or yarn
- Git

### Getting Started

```bash
# Clone repository
git clone <repository-url>
cd <project-name>

# Install dependencies
npm install

# Start development server
npm run dev

# Open browser
# http://localhost:5173
```

## Development Setup

### Environment Setup

1. **Install Node.js**
   - Download from https://nodejs.org/
   - Or use nvm: `nvm install 18`

2. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd <project-name>
   ```

3. **Install Dependencies**
   ```bash
   npm install
   ```

4. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Start Development**
   ```bash
   npm run dev
   ```

### IDE Configuration

**VSCode:**
- Install recommended extensions
- Enable format on save
- Install ESLint and Prettier extensions

**Settings:**
- Format on save: enabled
- Default formatter: Prettier
- ESLint: enabled

## Build and Deploy

### Production Build

```bash
# Build for production
npm run build

# Test production build
npm run preview

# Output location
# dist/
```

### Deployment

**Vercel:**
```bash
npm i -g vercel
vercel
vercel --prod
```

**Netlify:**
```bash
npm i -g netlify-cli
netlify deploy
netlify deploy --prod
```

**GitHub Pages:**
```bash
npm run build
gh-pages -d dist
```

**Manual:**
1. Build: `npm run build`
2. Upload `dist/` folder to server
3. Configure web server

## Troubleshooting

### Common Issues

**npm install fails:**
```bash
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

**Dev server won't start:**
```bash
# Check port availability
lsof -ti:5173 | xargs kill -9

# Use different port
npm run dev -- --port 3000
```

**Build fails:**
```bash
# Debug build
npm run build -- --debug

# Check dependencies
npm install
```

**Module not found:**
```bash
# Reinstall dependencies
npm install

# Restart dev server
npm run dev
```

**Hot reload not working:**
- Restart dev server
- Clear browser cache
- Check file watcher limits (Linux)

**Git issues:**
```bash
# View status
git status

# Reset changes
git reset --hard HEAD

# Clean untracked files
git clean -fd
```

## Common Tasks

### Create New Page
```bash
bash scripts/automation/page-create.sh PageName
```

### Create Component Test
```bash
bash scripts/automation/test-component.sh ComponentName
```

### Run Tests
```bash
npm test
npm test -- --watch
npm test -- --coverage
```

### Code Quality
```bash
npm run lint
npm run format
bash scripts/automation/reviewer.sh
```

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes
git add .
bash scripts/automation/commit-help.sh

# Push changes
git push origin feature/new-feature
```

### Update Dependencies
```bash
npm outdated
npm update
npm audit fix
```

### Generate Changelog
```bash
bash scripts/automation/changelog.sh
```

## Emergency Procedures

### Production Down

1. **Check Status**
   - Visit site in browser
   - Check hosting dashboard
   - Check DNS: `nslookup yourdomain.com`

2. **Quick Rollback**
   ```bash
   git revert HEAD
   # Redeploy immediately
   ```

3. **Emergency Hotfix**
   ```bash
   git checkout -b hotfix/issue
   # Make minimal fix
   npm run build && npm run preview
   # Deploy immediately
   ```

### Security Incident

1. **Immediate Actions**
   - Take site offline if necessary
   - Rotate all credentials
   - Check for unauthorized changes

2. **Investigation**
   - Review access logs
   - Check for malicious code
   - Run security audit: `npm audit`

3. **Recovery**
   - Update all dependencies
   - Apply security patches
   - Redeploy from clean state

### Data Loss

1. **Check Backups**
   ```bash
   git reflog
   git log --all
   ```

2. **Recovery**
   ```bash
   git checkout <commit>
   # Or restore from backup
   ```

## Monitoring

### Health Checks
- Application status
- Build status
- Dependency vulnerabilities
- Performance metrics

### Automation Scripts
```bash
# Environment check
bash scripts/automation/env-check.sh

# Dependency audit
bash scripts/automation/deps-audit.sh

# Observability
bash scripts/automation/observability.sh

# KPI impact
bash scripts/automation/kpi-impact.sh
```

### Logs
- Check browser console
- Check build logs
- Check deployment logs

## Contacts

### Team
- **Project Lead:** [Name] - [Email]
- **Tech Lead:** [Name] - [Email]
- **DevOps:** [Name] - [Email]

### Resources
- **Repository:** [GitHub URL]
- **Documentation:** [Docs URL]
- **Hosting:** [Hosting Provider]
- **Monitoring:** [Monitoring URL]

### Support
- **Issues:** [GitHub Issues URL]
- **Slack:** [Slack Channel]
- **Email:** [Support Email]

---

**Last Updated:** [Date]
**Version:** [Version]
EOF
        
        echo -e "${GREEN}✅ Runbook generated: $RUNBOOK_FILE${NC}"
        echo ""
        echo "Edit the file to add project-specific details"
        ;;
        
    0)
        echo "Exiting..."
        exit 0
        ;;
        
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo "For full runbook, run:"
echo "  bash scripts/automation/runbook.sh"
echo "  Select option 7 to generate RUNBOOK.md"
