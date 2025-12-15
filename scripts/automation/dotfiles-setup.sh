#!/bin/bash
# dotfiles-setup.sh - Setup and sync dotfiles for consistent development environment
# Configures editor settings, git config, and development tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "⚙️  Dotfiles Setup"
echo "=================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Create .editorconfig if it doesn't exist
echo ""
echo "📝 Setting up .editorconfig..."
if [ ! -f "$PROJECT_ROOT/.editorconfig" ]; then
    cat > "$PROJECT_ROOT/.editorconfig" << 'EOF'
# EditorConfig helps maintain consistent coding styles
# https://editorconfig.org

root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2

[*.{js,jsx,ts,tsx}]
indent_size = 2

[*.{json,yml,yaml}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
EOF
    echo -e "${GREEN}✅ Created .editorconfig${NC}"
else
    echo -e "${GREEN}✅ .editorconfig already exists${NC}"
fi

# Create .prettierrc if it doesn't exist
echo ""
echo "💅 Setting up Prettier config..."
if [ ! -f "$PROJECT_ROOT/.prettierrc" ]; then
    cat > "$PROJECT_ROOT/.prettierrc" << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "arrowParens": "avoid",
  "endOfLine": "lf"
}
EOF
    echo -e "${GREEN}✅ Created .prettierrc${NC}"
else
    echo -e "${GREEN}✅ .prettierrc already exists${NC}"
fi

# Create .prettierignore if it doesn't exist
echo ""
echo "🚫 Setting up .prettierignore..."
if [ ! -f "$PROJECT_ROOT/.prettierignore" ]; then
    cat > "$PROJECT_ROOT/.prettierignore" << 'EOF'
# Dependencies
node_modules
package-lock.json
yarn.lock
pnpm-lock.yaml

# Build outputs
dist
build
.next
.nuxt
out

# Cache
.cache
.parcel-cache
.vite

# Logs
*.log

# OS
.DS_Store
Thumbs.db

# IDE
.vscode
.idea

# Other
coverage
.env
.env.*
EOF
    echo -e "${GREEN}✅ Created .prettierignore${NC}"
else
    echo -e "${GREEN}✅ .prettierignore already exists${NC}"
fi

# Create .eslintrc if it doesn't exist (basic config)
echo ""
echo "🔍 Setting up ESLint config..."
if [ ! -f "$PROJECT_ROOT/.eslintrc.json" ] && [ ! -f "$PROJECT_ROOT/.eslintrc.js" ]; then
    cat > "$PROJECT_ROOT/.eslintrc.json" << 'EOF'
{
  "env": {
    "browser": true,
    "es2021": true,
    "node": true
  },
  "extends": [
    "eslint:recommended"
  ],
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "rules": {
    "no-console": "warn",
    "no-unused-vars": "warn",
    "no-undef": "error"
  }
}
EOF
    echo -e "${GREEN}✅ Created .eslintrc.json${NC}"
else
    echo -e "${GREEN}✅ ESLint config already exists${NC}"
fi

# Create .eslintignore if it doesn't exist
echo ""
echo "🚫 Setting up .eslintignore..."
if [ ! -f "$PROJECT_ROOT/.eslintignore" ]; then
    cat > "$PROJECT_ROOT/.eslintignore" << 'EOF'
node_modules
dist
build
.next
.nuxt
coverage
*.config.js
*.config.ts
EOF
    echo -e "${GREEN}✅ Created .eslintignore${NC}"
else
    echo -e "${GREEN}✅ .eslintignore already exists${NC}"
fi

# Setup VSCode settings
echo ""
echo "💻 Setting up VSCode settings..."
VSCODE_DIR="$PROJECT_ROOT/.vscode"
mkdir -p "$VSCODE_DIR"

if [ ! -f "$VSCODE_DIR/settings.json" ]; then
    cat > "$VSCODE_DIR/settings.json" << 'EOF'
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "files.eol": "\n",
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "javascript.updateImportsOnFileMove.enabled": "always",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ]
}
EOF
    echo -e "${GREEN}✅ Created .vscode/settings.json${NC}"
else
    echo -e "${GREEN}✅ .vscode/settings.json already exists${NC}"
fi

# Setup VSCode extensions recommendations
if [ ! -f "$VSCODE_DIR/extensions.json" ]; then
    cat > "$VSCODE_DIR/extensions.json" << 'EOF'
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "editorconfig.editorconfig",
    "dsznajder.es7-react-js-snippets",
    "christian-kohler.path-intellisense",
    "formulahendry.auto-rename-tag",
    "bradlc.vscode-tailwindcss"
  ]
}
EOF
    echo -e "${GREEN}✅ Created .vscode/extensions.json${NC}"
else
    echo -e "${GREEN}✅ .vscode/extensions.json already exists${NC}"
fi

# Check git config
echo ""
echo "🔧 Checking Git configuration..."
if [ -d "$PROJECT_ROOT/.git" ]; then
    # Check for user name and email
    GIT_USER=$(git config user.name 2>/dev/null || echo "")
    GIT_EMAIL=$(git config user.email 2>/dev/null || echo "")
    
    if [ -n "$GIT_USER" ]; then
        echo -e "   ${GREEN}✅ Git user.name: $GIT_USER${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Git user.name not set${NC}"
        echo "   Run: git config user.name 'Your Name'"
    fi
    
    if [ -n "$GIT_EMAIL" ]; then
        echo -e "   ${GREEN}✅ Git user.email: $GIT_EMAIL${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Git user.email not set${NC}"
        echo "   Run: git config user.email 'your.email@example.com'"
    fi
    
    # Setup git hooks directory
    HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
    if [ -d "$HOOKS_DIR" ]; then
        echo -e "   ${GREEN}✅ Git hooks directory exists${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  Not a git repository${NC}"
fi

# Create .nvmrc if Node.js is available
echo ""
echo "📦 Setting up Node version file..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version | sed 's/v//')
    if [ ! -f "$PROJECT_ROOT/.nvmrc" ]; then
        echo "$NODE_VERSION" > "$PROJECT_ROOT/.nvmrc"
        echo -e "${GREEN}✅ Created .nvmrc with Node $NODE_VERSION${NC}"
    else
        echo -e "${GREEN}✅ .nvmrc already exists${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Node.js not available${NC}"
fi

# Summary of created files
echo ""
echo "=================="
echo -e "${GREEN}✅ Dotfiles setup complete${NC}"
echo ""
echo "Created/verified files:"
echo "  • .editorconfig - Editor configuration"
echo "  • .prettierrc - Code formatting rules"
echo "  • .prettierignore - Prettier ignore patterns"
echo "  • .eslintrc.json - Linting rules"
echo "  • .eslintignore - ESLint ignore patterns"
echo "  • .vscode/settings.json - VSCode settings"
echo "  • .vscode/extensions.json - Recommended extensions"
echo "  • .nvmrc - Node version specification"
echo ""
echo "Next steps:"
echo "  1. Install recommended VSCode extensions"
echo "  2. Install Prettier and ESLint if not already installed:"
echo "     npm install -D prettier eslint"
echo "  3. Restart your editor to apply settings"
echo "  4. Run 'npm run format' or 'npm run lint' if configured"
