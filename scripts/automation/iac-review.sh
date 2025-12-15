#!/bin/bash
# iac-review.sh - Infrastructure as Code review
# Reviews infrastructure configuration files

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

echo -e "${CYAN}🏗️  Infrastructure as Code Review${NC}"
echo "==================================="
echo ""

cd "$PROJECT_ROOT"

ISSUES_FOUND=0

# Check for Dev Container configuration
echo "🐳 Dev Container Configuration"
echo "-------------------------------"

if [ -f ".devcontainer/devcontainer.json" ]; then
    echo -e "${GREEN}✅ devcontainer.json found${NC}"
    
    # Validate JSON
    if node -e "require('./.devcontainer/devcontainer.json')" 2>/dev/null; then
        echo -e "   ${GREEN}✅ Valid JSON${NC}"
    else
        echo -e "   ${RED}❌ Invalid JSON${NC}"
        ((ISSUES_FOUND++))
    fi
    
    # Check for Dockerfile
    if [ -f ".devcontainer/Dockerfile" ]; then
        echo -e "   ${GREEN}✅ Dockerfile found${NC}"
    else
        echo -e "   ${YELLOW}⚠️  No Dockerfile (using image)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No Dev Container configuration${NC}"
fi

# Check for Docker configuration
echo ""
echo "🐋 Docker Configuration"
echo "-----------------------"

if [ -f "Dockerfile" ]; then
    echo -e "${GREEN}✅ Dockerfile found${NC}"
    
    # Check Dockerfile best practices
    echo "   Checking best practices..."
    
    # Check for .dockerignore
    if [ -f ".dockerignore" ]; then
        echo -e "   ${GREEN}✅ .dockerignore exists${NC}"
    else
        echo -e "   ${YELLOW}⚠️  No .dockerignore file${NC}"
        echo "   Create .dockerignore to exclude unnecessary files"
        ((ISSUES_FOUND++))
    fi
    
    # Check for multi-stage builds
    if grep -q "^FROM.*AS" Dockerfile; then
        echo -e "   ${GREEN}✅ Multi-stage build detected${NC}"
    else
        echo -e "   ${BLUE}ℹ️  Consider multi-stage builds for smaller images${NC}"
    fi
    
    # Check for specific base image version
    if grep -q "^FROM.*:latest" Dockerfile; then
        echo -e "   ${YELLOW}⚠️  Using :latest tag${NC}"
        echo "   Pin specific versions for reproducibility"
    else
        echo -e "   ${GREEN}✅ Using pinned base image version${NC}"
    fi
    
    # Check for COPY vs ADD
    if grep -q "^ADD" Dockerfile; then
        echo -e "   ${YELLOW}⚠️  Using ADD command${NC}"
        echo "   Prefer COPY unless you need ADD's features"
    fi
    
    # Check for USER instruction
    if grep -q "^USER" Dockerfile; then
        echo -e "   ${GREEN}✅ Non-root user specified${NC}"
    else
        echo -e "   ${YELLOW}⚠️  No USER instruction${NC}"
        echo "   Consider running as non-root user"
    fi
else
    echo -e "${BLUE}ℹ️  No Dockerfile in root${NC}"
fi

# Check for docker-compose
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    echo -e "${GREEN}✅ docker-compose configuration found${NC}"
    
    COMPOSE_FILE="docker-compose.yml"
    [ -f "docker-compose.yaml" ] && COMPOSE_FILE="docker-compose.yaml"
    
    # Check for version
    if grep -q "^version:" "$COMPOSE_FILE"; then
        VERSION=$(grep "^version:" "$COMPOSE_FILE" | cut -d':' -f2 | tr -d ' "'"'"'')
        echo "   Version: $VERSION"
    fi
else
    echo -e "${BLUE}ℹ️  No docker-compose configuration${NC}"
fi

# Check for CI/CD configuration
echo ""
echo "🔄 CI/CD Configuration"
echo "----------------------"

# GitHub Actions
if [ -d ".github/workflows" ]; then
    WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" -o -name "*.yaml" | wc -l)
    echo -e "${GREEN}✅ GitHub Actions workflows: $WORKFLOW_COUNT${NC}"
    
    find .github/workflows -name "*.yml" -o -name "*.yaml" | while read -r workflow; do
        echo "   • $(basename "$workflow")"
    done
else
    echo -e "${YELLOW}⚠️  No GitHub Actions workflows${NC}"
fi

# GitLab CI
if [ -f ".gitlab-ci.yml" ]; then
    echo -e "${GREEN}✅ GitLab CI configuration found${NC}"
else
    echo -e "${BLUE}ℹ️  No GitLab CI configuration${NC}"
fi

# Check for Gitpod configuration
echo ""
echo "☁️  Gitpod Configuration"
echo "------------------------"

if [ -f ".gitpod.yml" ]; then
    echo -e "${YELLOW}⚠️  Legacy .gitpod.yml found${NC}"
    echo "   Consider migrating to Dev Containers"
    echo "   See: https://www.gitpod.io/docs/configure/dev-containers"
fi

# Check for environment variables
echo ""
echo "🔐 Environment Configuration"
echo "----------------------------"

if [ -f ".env.example" ]; then
    echo -e "${GREEN}✅ .env.example found${NC}"
    
    # Count variables
    VAR_COUNT=$(grep -c "^[A-Z_]" .env.example 2>/dev/null || echo "0")
    echo "   Variables documented: $VAR_COUNT"
else
    echo -e "${YELLOW}⚠️  No .env.example file${NC}"
    echo "   Create .env.example to document required environment variables"
fi

if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file exists${NC}"
    
    # Check if in .gitignore
    if grep -q "^\.env$" .gitignore 2>/dev/null; then
        echo -e "   ${GREEN}✅ .env is in .gitignore${NC}"
    else
        echo -e "   ${RED}❌ .env NOT in .gitignore${NC}"
        ((ISSUES_FOUND++))
    fi
fi

# Check for infrastructure directories
echo ""
echo "📁 Infrastructure Directories"
echo "------------------------------"

INFRA_DIRS=("terraform" "ansible" "kubernetes" "k8s" "helm" "infrastructure" "infra")

for dir in "${INFRA_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        FILE_COUNT=$(find "$dir" -type f | wc -l)
        echo -e "${GREEN}✅ $dir/ directory found ($FILE_COUNT files)${NC}"
    fi
done

# Check for Terraform
if [ -d "terraform" ] || find . -name "*.tf" -type f | grep -q .; then
    echo ""
    echo "🏗️  Terraform Configuration"
    TF_FILES=$(find . -name "*.tf" -type f | wc -l)
    echo "   Terraform files: $TF_FILES"
    
    # Check for terraform.tfvars
    if [ -f "terraform/terraform.tfvars" ]; then
        echo -e "   ${YELLOW}⚠️  terraform.tfvars found${NC}"
        echo "   Ensure sensitive values are not committed"
    fi
    
    # Check for .terraform directory
    if [ -d ".terraform" ]; then
        echo -e "   ${YELLOW}⚠️  .terraform directory exists${NC}"
        if grep -q "^\.terraform$" .gitignore 2>/dev/null; then
            echo -e "   ${GREEN}✅ .terraform is in .gitignore${NC}"
        else
            echo -e "   ${RED}❌ .terraform NOT in .gitignore${NC}"
            ((ISSUES_FOUND++))
        fi
    fi
fi

# Check for Kubernetes
if [ -d "kubernetes" ] || [ -d "k8s" ] || find . -name "*.yaml" -path "*/k8s/*" -type f | grep -q .; then
    echo ""
    echo "☸️  Kubernetes Configuration"
    K8S_FILES=$(find . -name "*.yaml" -path "*/k8s/*" -o -name "*.yaml" -path "*/kubernetes/*" | wc -l)
    echo "   Kubernetes manifests: $K8S_FILES"
fi

# Check for Helm
if [ -d "helm" ] || [ -f "Chart.yaml" ]; then
    echo ""
    echo "⎈ Helm Configuration"
    if [ -f "Chart.yaml" ]; then
        echo -e "${GREEN}✅ Chart.yaml found${NC}"
    fi
fi

# Check for configuration files
echo ""
echo "⚙️  Configuration Files"
echo "-----------------------"

CONFIG_FILES=(
    "package.json:Node.js"
    "tsconfig.json:TypeScript"
    "vite.config.js:Vite"
    "vite.config.ts:Vite"
    ".eslintrc.json:ESLint"
    ".prettierrc:Prettier"
    ".editorconfig:EditorConfig"
)

for entry in "${CONFIG_FILES[@]}"; do
    FILE="${entry%%:*}"
    NAME="${entry##*:}"
    
    if [ -f "$FILE" ]; then
        echo -e "${GREEN}✅ $NAME configuration${NC}"
    fi
done

# Security checks
echo ""
echo "🔒 Security Checks"
echo "------------------"

# Check for secrets in config files
echo "Checking for potential secrets..."

SENSITIVE_PATTERNS=(
    "password"
    "api[_-]?key"
    "secret"
    "token"
    "private[_-]?key"
)

SECRETS_FOUND=0
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if grep -ri "$pattern.*=" .devcontainer/ 2>/dev/null | grep -v "example" | grep -q .; then
        echo -e "${YELLOW}⚠️  Potential secret in .devcontainer/${NC}"
        ((SECRETS_FOUND++))
    fi
done

if [ $SECRETS_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ No obvious secrets in configuration${NC}"
else
    echo -e "${RED}❌ Found $SECRETS_FOUND potential secrets${NC}"
    echo "   Review configuration files for sensitive data"
    ((ISSUES_FOUND++))
fi

# Best practices
echo ""
echo "💡 Best Practices"
echo "-----------------"

SCORE=0
MAX_SCORE=10

[ -f ".devcontainer/devcontainer.json" ] && ((SCORE++))
[ -f ".dockerignore" ] && ((SCORE++))
[ -f ".env.example" ] && ((SCORE++))
[ -d ".github/workflows" ] && ((SCORE++))
[ -f "README.md" ] && ((SCORE++))
[ -f ".gitignore" ] && ((SCORE++))
[ -f "package.json" ] && ((SCORE++))
[ -f ".editorconfig" ] && ((SCORE++))
[ -f ".prettierrc" ] && ((SCORE++))
[ -f "tsconfig.json" ] && ((SCORE++))

PERCENTAGE=$((SCORE * 100 / MAX_SCORE))

echo "IaC Score: $SCORE/$MAX_SCORE ($PERCENTAGE%)"

# Summary
echo ""
echo "==================================="
echo -e "${CYAN}Summary${NC}"
echo "==================================="

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ Infrastructure configuration looks good${NC}"
else
    echo -e "${YELLOW}⚠️  Found $ISSUES_FOUND issues${NC}"
fi

echo ""
echo "Recommendations:"
echo "  1. Use Dev Containers for consistent development environments"
echo "  2. Pin specific versions in Dockerfiles"
echo "  3. Use .dockerignore to reduce image size"
echo "  4. Document environment variables in .env.example"
echo "  5. Set up CI/CD pipelines"
echo "  6. Use infrastructure as code (Terraform, etc.)"
echo "  7. Implement security scanning in CI/CD"
echo "  8. Keep configuration files in version control"
echo "  9. Use secrets management (not .env files in production)"
echo "  10. Regular security audits"

echo ""
echo "Resources:"
echo "  • Dev Containers: https://containers.dev/"
echo "  • Docker best practices: https://docs.docker.com/develop/dev-best-practices/"
echo "  • Gitpod: https://www.gitpod.io/docs"
