#!/bin/bash
# risk-scan.sh - Risk assessment and security scanning
# Identifies potential risks and security issues

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

echo -e "${CYAN}🔒 Risk Assessment & Security Scan${NC}"
echo "===================================="
echo ""

cd "$PROJECT_ROOT"

CRITICAL_RISKS=0
HIGH_RISKS=0
MEDIUM_RISKS=0
LOW_RISKS=0

# Security vulnerabilities
echo "🔐 Security Vulnerabilities"
echo "---------------------------"

if [ -f "package.json" ]; then
    echo "Running npm audit..."
    
    if npm audit --json > /tmp/risk-audit.json 2>&1; then
        echo -e "${GREEN}✅ No vulnerabilities found${NC}"
    else
        CRITICAL=$(node -p "require('/tmp/risk-audit.json').metadata?.vulnerabilities?.critical || 0" 2>/dev/null || echo "0")
        HIGH=$(node -p "require('/tmp/risk-audit.json').metadata?.vulnerabilities?.high || 0" 2>/dev/null || echo "0")
        MODERATE=$(node -p "require('/tmp/risk-audit.json').metadata?.vulnerabilities?.moderate || 0" 2>/dev/null || echo "0")
        LOW=$(node -p "require('/tmp/risk-audit.json').metadata?.vulnerabilities?.low || 0" 2>/dev/null || echo "0")
        
        [ "$CRITICAL" -gt 0 ] && echo -e "${RED}❌ Critical: $CRITICAL${NC}" && ((CRITICAL_RISKS+=CRITICAL))
        [ "$HIGH" -gt 0 ] && echo -e "${RED}❌ High: $HIGH${NC}" && ((HIGH_RISKS+=HIGH))
        [ "$MODERATE" -gt 0 ] && echo -e "${YELLOW}⚠️  Moderate: $MODERATE${NC}" && ((MEDIUM_RISKS+=MODERATE))
        [ "$LOW" -gt 0 ] && echo -e "${BLUE}ℹ️  Low: $LOW${NC}" && ((LOW_RISKS+=LOW))
        
        echo ""
        echo "Run 'npm audit' for details"
        echo "Run 'npm audit fix' to fix automatically"
    fi
    rm -f /tmp/risk-audit.json
else
    echo -e "${YELLOW}⚠️  No package.json found${NC}"
fi

# Sensitive data exposure
echo ""
echo "🔍 Sensitive Data Exposure"
echo "--------------------------"

# Check for .env files
if [ -f ".env" ]; then
    echo -e "${RED}❌ .env file exists${NC}"
    ((HIGH_RISKS++)) || true
    
    if grep -q "^\.env$" .gitignore 2>/dev/null; then
        echo -e "   ${GREEN}✅ .env is in .gitignore${NC}"
    else
        echo -e "   ${RED}❌ .env NOT in .gitignore - CRITICAL${NC}"
        ((CRITICAL_RISKS++)) || true
    fi
else
    echo -e "${GREEN}✅ No .env file in root${NC}"
fi

# Check for secrets in code
echo ""
echo "Scanning for hardcoded secrets..."

SENSITIVE_PATTERNS=(
    "password.*=.*['\"][^'\"]{8,}"
    "api[_-]?key.*=.*['\"][^'\"]{20,}"
    "secret.*=.*['\"][^'\"]{20,}"
    "token.*=.*['\"][^'\"]{20,}"
    "private[_-]?key"
    "BEGIN.*PRIVATE.*KEY"
    "aws[_-]?access"
    "AKIA[0-9A-Z]{16}"
)

SECRETS_FOUND=0
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if grep -rE "$pattern" src/ 2>/dev/null | grep -v "example\|test\|mock" | head -1 | grep -q .; then
        echo -e "${RED}❌ Potential secret pattern: $pattern${NC}"
        ((SECRETS_FOUND++)) || true
        ((HIGH_RISKS++)) || true
    fi
done

if [ $SECRETS_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ No obvious secrets in source code${NC}"
fi

# Check git history for secrets
if [ -d ".git" ]; then
    echo ""
    echo "Checking git history for secrets..."
    
    HISTORY_SECRETS=0
    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        if git log --all -p 2>/dev/null | grep -E "$pattern" | grep -v "example\|test" | head -1 | grep -q .; then
            ((HISTORY_SECRETS++)) || true
        fi
    done
    
    if [ $HISTORY_SECRETS -gt 0 ]; then
        echo -e "${RED}❌ Potential secrets in git history${NC}"
        echo "   Consider using git-filter-branch or BFG Repo-Cleaner"
        ((HIGH_RISKS++)) || true
    else
        echo -e "${GREEN}✅ No obvious secrets in git history${NC}"
    fi
fi

# Dependency risks
echo ""
echo "📦 Dependency Risks"
echo "-------------------"

if [ -f "package.json" ]; then
    DEP_COUNT=$(node -p "Object.keys(require('./package.json').dependencies || {}).length" 2>/dev/null || echo "0")
    DEV_DEP_COUNT=$(node -p "Object.keys(require('./package.json').devDependencies || {}).length" 2>/dev/null || echo "0")
    TOTAL_DEPS=$((DEP_COUNT + DEV_DEP_COUNT))
    
    echo "Total dependencies: $TOTAL_DEPS"
    
    if [ "$TOTAL_DEPS" -gt 100 ]; then
        echo -e "${RED}❌ Very high dependency count - increased attack surface${NC}"
        ((HIGH_RISKS++)) || true
    elif [ "$TOTAL_DEPS" -gt 50 ]; then
        echo -e "${YELLOW}⚠️  High dependency count${NC}"
        ((MEDIUM_RISKS++)) || true
    else
        echo -e "${GREEN}✅ Reasonable dependency count${NC}"
    fi
    
    # Check for outdated dependencies
    echo ""
    echo "Checking for outdated dependencies..."
    
    if npm outdated --json > /tmp/outdated.json 2>&1; then
        echo -e "${GREEN}✅ All dependencies up to date${NC}"
    else
        OUTDATED_COUNT=$(node -p "Object.keys(require('/tmp/outdated.json')).length" 2>/dev/null || echo "0")
        if [ "$OUTDATED_COUNT" -gt 20 ]; then
            echo -e "${YELLOW}⚠️  Many outdated dependencies ($OUTDATED_COUNT)${NC}"
            ((MEDIUM_RISKS++)) || true
        elif [ "$OUTDATED_COUNT" -gt 0 ]; then
            echo -e "${BLUE}ℹ️  Some outdated dependencies ($OUTDATED_COUNT)${NC}"
            ((LOW_RISKS++)) || true
        fi
    fi
    rm -f /tmp/outdated.json
fi

# Code quality risks
echo ""
echo "💻 Code Quality Risks"
echo "---------------------"

if [ -d "src" ]; then
    # Check for eval usage
    EVAL_COUNT=$(grep -r "eval(" src 2>/dev/null | wc -l || echo "0")
    if [ "$EVAL_COUNT" -gt 0 ]; then
        echo -e "${RED}❌ eval() usage detected ($EVAL_COUNT) - security risk${NC}"
        ((HIGH_RISKS++)) || true
    else
        echo -e "${GREEN}✅ No eval() usage${NC}"
    fi
    
    # Check for dangerouslySetInnerHTML
    DANGEROUS_HTML=$(grep -r "dangerouslySetInnerHTML" src 2>/dev/null | wc -l || echo "0")
    if [ "$DANGEROUS_HTML" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  dangerouslySetInnerHTML usage ($DANGEROUS_HTML) - XSS risk${NC}"
        ((MEDIUM_RISKS++)) || true
    else
        echo -e "${GREEN}✅ No dangerouslySetInnerHTML usage${NC}"
    fi
    
    # Check for TODO/FIXME
    TODO_COUNT=$(grep -r "TODO\|FIXME" src 2>/dev/null | wc -l || echo "0")
    if [ "$TODO_COUNT" -gt 50 ]; then
        echo -e "${YELLOW}⚠️  Many TODO/FIXME comments ($TODO_COUNT) - technical debt${NC}"
        ((MEDIUM_RISKS++)) || true
    elif [ "$TODO_COUNT" -gt 20 ]; then
        echo -e "${BLUE}ℹ️  Some TODO/FIXME comments ($TODO_COUNT)${NC}"
        ((LOW_RISKS++)) || true
    else
        echo -e "${GREEN}✅ Few TODO/FIXME comments${NC}"
    fi
    
    # Check for console.log
    CONSOLE_LOGS=$(grep -r "console\.log" src 2>/dev/null | wc -l || echo "0")
    if [ "$CONSOLE_LOGS" -gt 20 ]; then
        echo -e "${YELLOW}⚠️  Many console.log statements ($CONSOLE_LOGS) - info leakage risk${NC}"
        ((MEDIUM_RISKS++)) || true
    elif [ "$CONSOLE_LOGS" -gt 10 ]; then
        echo -e "${BLUE}ℹ️  Some console.log statements ($CONSOLE_LOGS)${NC}"
        ((LOW_RISKS++)) || true
    else
        echo -e "${GREEN}✅ Minimal console.log usage${NC}"
    fi
fi

# Configuration risks
echo ""
echo "⚙️  Configuration Risks"
echo "-----------------------"

# Check for CORS configuration
if grep -r "cors" src 2>/dev/null | grep -q .; then
    echo -e "${BLUE}ℹ️  CORS configuration detected - verify settings${NC}"
    ((LOW_RISKS++)) || true
fi

# Check for authentication
AUTH_PATTERNS=("auth" "login" "password" "jwt" "token")
AUTH_FOUND=0

for pattern in "${AUTH_PATTERNS[@]}"; do
    if grep -ri "$pattern" src 2>/dev/null | head -1 | grep -q .; then
        ((AUTH_FOUND++)) || true
    fi
done

if [ $AUTH_FOUND -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Authentication code detected - ensure secure implementation${NC}"
    echo "   • Use HTTPS only"
    echo "   • Implement rate limiting"
    echo "   • Use secure password hashing"
    echo "   • Implement CSRF protection"
    ((MEDIUM_RISKS++)) || true
fi

# Build and deployment risks
echo ""
echo "🏗️  Build & Deployment Risks"
echo "-----------------------------"

# Check for source maps in production
if [ -d "dist" ]; then
    SOURCE_MAPS=$(find dist -name "*.map" | wc -l)
    if [ "$SOURCE_MAPS" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Source maps in build ($SOURCE_MAPS) - exposes source code${NC}"
        ((MEDIUM_RISKS++)) || true
    else
        echo -e "${GREEN}✅ No source maps in build${NC}"
    fi
fi

# Check for .git in deployment
if [ -d "dist/.git" ]; then
    echo -e "${RED}❌ .git directory in build - exposes repository${NC}"
    ((HIGH_RISKS++)) || true
else
    echo -e "${GREEN}✅ No .git in build${NC}"
fi

# Infrastructure risks
echo ""
echo "🏢 Infrastructure Risks"
echo "-----------------------"

# Check for Docker security
if [ -f "Dockerfile" ]; then
    echo "Checking Dockerfile..."
    
    if grep -q "^FROM.*:latest" Dockerfile; then
        echo -e "${YELLOW}⚠️  Using :latest tag - unpredictable builds${NC}"
        ((MEDIUM_RISKS++)) || true
    fi
    
    if ! grep -q "^USER" Dockerfile; then
        echo -e "${YELLOW}⚠️  No USER instruction - running as root${NC}"
        ((MEDIUM_RISKS++)) || true
    fi
    
    if grep -q "^ADD" Dockerfile; then
        echo -e "${BLUE}ℹ️  Using ADD instead of COPY${NC}"
        ((LOW_RISKS++)) || true
    fi
fi

# Check for CI/CD configuration
if [ -d ".github/workflows" ]; then
    echo -e "${GREEN}✅ CI/CD configured${NC}"
else
    echo -e "${YELLOW}⚠️  No CI/CD configuration - manual deployment risk${NC}"
    ((MEDIUM_RISKS++)) || true
fi

# Data handling risks
echo ""
echo "💾 Data Handling Risks"
echo "----------------------"

# Check for localStorage usage
LOCALSTORAGE=$(grep -r "localStorage" src 2>/dev/null | wc -l || echo "0")
if [ "$LOCALSTORAGE" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  localStorage usage ($LOCALSTORAGE) - XSS can access data${NC}"
    echo "   Consider using httpOnly cookies for sensitive data"
    ((MEDIUM_RISKS++)) || true
fi

# Check for sessionStorage usage
SESSIONSTORAGE=$(grep -r "sessionStorage" src 2>/dev/null | wc -l || echo "0")
if [ "$SESSIONSTORAGE" -gt 0 ]; then
    echo -e "${BLUE}ℹ️  sessionStorage usage ($SESSIONSTORAGE)${NC}"
    ((LOW_RISKS++)) || true
fi

# Third-party risks
echo ""
echo "🔌 Third-Party Risks"
echo "--------------------"

# Check for external scripts
EXTERNAL_SCRIPTS=$(grep -r "script.*src=.*http" public 2>/dev/null | wc -l || echo "0")
if [ "$EXTERNAL_SCRIPTS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  External scripts ($EXTERNAL_SCRIPTS) - supply chain risk${NC}"
    echo "   Use Subresource Integrity (SRI) for external scripts"
    ((MEDIUM_RISKS++)) || true
else
    echo -e "${GREEN}✅ No external scripts detected${NC}"
fi

# Calculate risk score
TOTAL_RISKS=$((CRITICAL_RISKS + HIGH_RISKS + MEDIUM_RISKS + LOW_RISKS))
RISK_SCORE=$((CRITICAL_RISKS * 10 + HIGH_RISKS * 5 + MEDIUM_RISKS * 2 + LOW_RISKS))

# Risk summary
echo ""
echo "===================================="
echo -e "${CYAN}Risk Assessment Summary${NC}"
echo "===================================="
echo ""
echo "Risk Levels:"
echo -e "  ${RED}Critical: $CRITICAL_RISKS${NC}"
echo -e "  ${RED}High: $HIGH_RISKS${NC}"
echo -e "  ${YELLOW}Medium: $MEDIUM_RISKS${NC}"
echo -e "  ${BLUE}Low: $LOW_RISKS${NC}"
echo ""
echo "Total Risks: $TOTAL_RISKS"
echo "Risk Score: $RISK_SCORE"
echo ""

# Overall risk rating
if [ "$CRITICAL_RISKS" -gt 0 ]; then
    echo -e "${RED}🚨 CRITICAL RISK LEVEL${NC}"
    echo "Immediate action required"
elif [ "$RISK_SCORE" -gt 20 ]; then
    echo -e "${RED}❌ HIGH RISK LEVEL${NC}"
    echo "Address high-priority risks immediately"
elif [ "$RISK_SCORE" -gt 10 ]; then
    echo -e "${YELLOW}⚠️  MODERATE RISK LEVEL${NC}"
    echo "Review and address medium-priority risks"
elif [ "$RISK_SCORE" -gt 0 ]; then
    echo -e "${BLUE}ℹ️  LOW RISK LEVEL${NC}"
    echo "Monitor and address low-priority risks"
else
    echo -e "${GREEN}✅ MINIMAL RISK LEVEL${NC}"
    echo "Good security posture"
fi

echo ""
echo "Recommendations:"
[ "$CRITICAL_RISKS" -gt 0 ] && echo "  • Address critical risks immediately"
[ "$HIGH_RISKS" -gt 0 ] && echo "  • Fix high-priority security issues"
[ "$MEDIUM_RISKS" -gt 5 ] && echo "  • Review and address medium-priority risks"
echo "  • Regular security audits"
echo "  • Keep dependencies updated"
echo "  • Implement security headers"
echo "  • Use HTTPS in production"
echo "  • Enable Content Security Policy (CSP)"
echo "  • Implement rate limiting"
echo "  • Regular penetration testing"
echo "  • Security training for team"

echo ""
echo "Security Resources:"
echo "  • OWASP Top 10: https://owasp.org/www-project-top-ten/"
echo "  • npm audit: npm audit"
echo "  • Snyk: https://snyk.io/"
echo "  • GitHub Security: https://github.com/security"

exit 0
