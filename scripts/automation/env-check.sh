#!/bin/bash
# env-check.sh - Environment validation
# Checks development environment setup and dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔧 Environment Check"
echo "===================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

ISSUES_FOUND=0

# Check Node.js
echo ""
echo "📦 Node.js"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ Node.js installed: $NODE_VERSION${NC}"
    
    # Check version requirements
    REQUIRED_VERSION="18.0.0"
    CURRENT_VERSION=$(node --version | sed 's/v//')
    
    if [ -f "$PROJECT_ROOT/.nvmrc" ]; then
        NVMRC_VERSION=$(cat "$PROJECT_ROOT/.nvmrc")
        echo "   .nvmrc specifies: v$NVMRC_VERSION"
        
        if [ "$CURRENT_VERSION" != "$NVMRC_VERSION" ]; then
            echo -e "   ${YELLOW}⚠️  Version mismatch${NC}"
            echo "   Run: nvm use"
        fi
    fi
else
    echo -e "${RED}❌ Node.js not installed${NC}"
    echo "   Install from: https://nodejs.org/"
    ((ISSUES_FOUND++)) || true
fi

# Check npm
echo ""
echo "📦 npm"
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✅ npm installed: v$NPM_VERSION${NC}"
else
    echo -e "${RED}❌ npm not installed${NC}"
    ((ISSUES_FOUND++)) || true
fi

# Check package.json
echo ""
echo "📄 package.json"
if [ -f "$PROJECT_ROOT/package.json" ]; then
    echo -e "${GREEN}✅ package.json found${NC}"
    
    # Extract info
    PKG_NAME=$(node -p "require('$PROJECT_ROOT/package.json').name" 2>/dev/null || echo "unknown")
    PKG_VERSION=$(node -p "require('$PROJECT_ROOT/package.json').version" 2>/dev/null || echo "0.0.0")
    
    echo "   Name: $PKG_NAME"
    echo "   Version: $PKG_VERSION"
else
    echo -e "${RED}❌ package.json not found${NC}"
    ((ISSUES_FOUND++)) || true
fi

# Check node_modules
echo ""
echo "📦 Dependencies"
if [ -d "$PROJECT_ROOT/node_modules" ]; then
    MODULE_COUNT=$(find "$PROJECT_ROOT/node_modules" -maxdepth 1 -type d | wc -l)
    echo -e "${GREEN}✅ node_modules exists ($MODULE_COUNT packages)${NC}"
    
    # Check if package-lock.json exists
    if [ -f "$PROJECT_ROOT/package-lock.json" ]; then
        echo -e "   ${GREEN}✅ package-lock.json found${NC}"
    else
        echo -e "   ${YELLOW}⚠️  package-lock.json not found${NC}"
        echo "   Run: npm install"
    fi
else
    echo -e "${RED}❌ node_modules not found${NC}"
    echo "   Run: npm install"
    ((ISSUES_FOUND++)) || true
fi

# Check Git
echo ""
echo "🔧 Git"
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    echo -e "${GREEN}✅ Git installed: v$GIT_VERSION${NC}"
    
    # Check git config
    GIT_USER=$(git config user.name 2>/dev/null || echo "")
    GIT_EMAIL=$(git config user.email 2>/dev/null || echo "")
    
    if [ -n "$GIT_USER" ]; then
        echo "   User: $GIT_USER"
    else
        echo -e "   ${YELLOW}⚠️  Git user.name not set${NC}"
        echo "   Run: git config --global user.name 'Your Name'"
    fi
    
    if [ -n "$GIT_EMAIL" ]; then
        echo "   Email: $GIT_EMAIL"
    else
        echo -e "   ${YELLOW}⚠️  Git user.email not set${NC}"
        echo "   Run: git config --global user.email 'your@email.com'"
    fi
else
    echo -e "${RED}❌ Git not installed${NC}"
    ((ISSUES_FOUND++)) || true
fi

# Check for .gitignore
echo ""
echo "🚫 .gitignore"
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
    LINES=$(wc -l < "$PROJECT_ROOT/.gitignore")
    echo -e "${GREEN}✅ .gitignore exists ($LINES lines)${NC}"
else
    echo -e "${RED}❌ .gitignore not found${NC}"
    ((ISSUES_FOUND++)) || true
fi

# Check environment variables
echo ""
echo "🔐 Environment Variables"
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${YELLOW}⚠️  .env file found${NC}"
    echo "   Ensure sensitive data is not committed"
    
    # Check if .env is in .gitignore
    if grep -q "^\.env$" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
        echo -e "   ${GREEN}✅ .env is in .gitignore${NC}"
    else
        echo -e "   ${RED}❌ .env NOT in .gitignore${NC}"
        ((ISSUES_FOUND++)) || true
    fi
else
    echo -e "${GREEN}✅ No .env file (or properly ignored)${NC}"
fi

# Check for .env.example
if [ -f "$PROJECT_ROOT/.env.example" ]; then
    echo -e "   ${GREEN}✅ .env.example found${NC}"
else
    echo -e "   ${BLUE}ℹ️  Consider creating .env.example for documentation${NC}"
fi

# Check build tools
echo ""
echo "🛠️  Build Tools"

# Check for Vite
if [ -f "$PROJECT_ROOT/vite.config.js" ] || [ -f "$PROJECT_ROOT/vite.config.ts" ]; then
    echo -e "${GREEN}✅ Vite config found${NC}"
else
    echo -e "${YELLOW}⚠️  No Vite config${NC}"
fi

# Check TypeScript
if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
    echo -e "${GREEN}✅ TypeScript config found${NC}"
else
    echo -e "${BLUE}ℹ️  No TypeScript config${NC}"
fi

# Check for dev container
echo ""
echo "🐳 Dev Container"
if [ -f "$PROJECT_ROOT/.devcontainer/devcontainer.json" ]; then
    echo -e "${GREEN}✅ Dev Container config found${NC}"
else
    echo -e "${BLUE}ℹ️  No Dev Container config${NC}"
fi

# Check ports
echo ""
echo "🌐 Port Availability"
PORTS_TO_CHECK=(3000 5173 8080)
for port in "${PORTS_TO_CHECK[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "   ${YELLOW}⚠️  Port $port is in use${NC}"
    else
        echo -e "   ${GREEN}✅ Port $port available${NC}"
    fi
done

# Check disk space
echo ""
echo "💾 Disk Space"
if command -v df &> /dev/null; then
    DISK_USAGE=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')
    DISK_AVAIL=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $4}')
    
    echo "   Available: $DISK_AVAIL"
    
    if [ "$DISK_USAGE" -gt 90 ]; then
        echo -e "   ${RED}❌ Disk usage critical: ${DISK_USAGE}%${NC}"
        ((ISSUES_FOUND++)) || true
    elif [ "$DISK_USAGE" -gt 80 ]; then
        echo -e "   ${YELLOW}⚠️  Disk usage high: ${DISK_USAGE}%${NC}"
    else
        echo -e "   ${GREEN}✅ Disk usage: ${DISK_USAGE}%${NC}"
    fi
fi

# Check memory
echo ""
echo "💻 Memory"
if command -v free &> /dev/null; then
    MEM_TOTAL=$(free -h | awk 'NR==2 {print $2}')
    MEM_AVAIL=$(free -h | awk 'NR==2 {print $7}')
    echo "   Total: $MEM_TOTAL"
    echo "   Available: $MEM_AVAIL"
elif command -v vm_stat &> /dev/null; then
    # macOS
    echo "   System: macOS"
    echo "   Use Activity Monitor for detailed memory info"
fi

# Check for common dev tools
echo ""
echo "🔧 Optional Tools"

OPTIONAL_TOOLS=("curl" "wget" "jq" "gh")
for tool in "${OPTIONAL_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        VERSION=$($tool --version 2>&1 | head -1)
        echo -e "   ${GREEN}✅ $tool${NC}"
    else
        echo -e "   ${BLUE}ℹ️  $tool not installed (optional)${NC}"
    fi
done

# Check scripts in package.json
echo ""
echo "📜 Available Scripts"
if [ -f "$PROJECT_ROOT/package.json" ]; then
    SCRIPTS=$(node -p "Object.keys(require('$PROJECT_ROOT/package.json').scripts || {}).join(', ')" 2>/dev/null || echo "none")
    echo "   $SCRIPTS"
fi

# Summary
echo ""
echo "===================="
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ Environment check complete - All good!${NC}"
    echo ""
    echo "Ready to develop! Try:"
    echo "  npm run dev"
    exit 0
else
    echo -e "${RED}❌ Environment check complete - $ISSUES_FOUND issues found${NC}"
    echo ""
    echo "Fix the issues above before continuing."
    exit 1
fi
