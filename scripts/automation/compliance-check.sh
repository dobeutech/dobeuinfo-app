#!/bin/bash
# compliance-check.sh - Compliance and standards checker
# Verifies project compliance with standards and best practices

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

echo -e "${CYAN}✓ Compliance Check${NC}"
echo "==================="
echo ""

cd "$PROJECT_ROOT"

COMPLIANCE_SCORE=0
MAX_SCORE=0
VIOLATIONS=0

# File structure compliance
echo "📁 File Structure Compliance"
echo "-----------------------------"

REQUIRED_FILES=(
    "package.json:Package configuration"
    "README.md:Project documentation"
    ".gitignore:Git ignore rules"
    "src:Source directory"
)

for entry in "${REQUIRED_FILES[@]}"; do
    FILE="${entry%%:*}"
    DESC="${entry##*:}"
    ((MAX_SCORE++))
    
    if [ -e "$FILE" ]; then
        echo -e "${GREEN}✅ $DESC ($FILE)${NC}"
        ((COMPLIANCE_SCORE++))
    else
        echo -e "${RED}❌ $DESC ($FILE) - MISSING${NC}"
        ((VIOLATIONS++))
    fi
done

# Code standards compliance
echo ""
echo "📝 Code Standards Compliance"
echo "-----------------------------"

CODE_STANDARDS=(
    ".editorconfig:EditorConfig for consistent formatting"
    ".prettierrc:Prettier configuration"
    ".eslintrc.json:ESLint configuration"
)

for entry in "${CODE_STANDARDS[@]}"; do
    FILE="${entry%%:*}"
    DESC="${entry##*:}"
    ((MAX_SCORE++))
    
    if [ -f "$FILE" ]; then
        echo -e "${GREEN}✅ $DESC${NC}"
        ((COMPLIANCE_SCORE++))
    else
        echo -e "${YELLOW}⚠️  $DESC - RECOMMENDED${NC}"
    fi
done

# Git compliance
echo ""
echo "🔧 Git Compliance"
echo "-----------------"

((MAX_SCORE++))
if [ -d ".git" ]; then
    echo -e "${GREEN}✅ Git repository initialized${NC}"
    ((COMPLIANCE_SCORE++))
    
    # Check git config
    GIT_USER=$(git config user.name 2>/dev/null || echo "")
    GIT_EMAIL=$(git config user.email 2>/dev/null || echo "")
    
    ((MAX_SCORE++))
    if [ -n "$GIT_USER" ] && [ -n "$GIT_EMAIL" ]; then
        echo -e "${GREEN}✅ Git user configured${NC}"
        ((COMPLIANCE_SCORE++))
    else
        echo -e "${YELLOW}⚠️  Git user not configured${NC}"
    fi
    
    # Check for .gitignore patterns
    ((MAX_SCORE++))
    if [ -f ".gitignore" ]; then
        REQUIRED_PATTERNS=("node_modules" "dist" ".env")
        MISSING_PATTERNS=()
        
        for pattern in "${REQUIRED_PATTERNS[@]}"; do
            if ! grep -q "$pattern" .gitignore; then
                MISSING_PATTERNS+=("$pattern")
            fi
        done
        
        if [ ${#MISSING_PATTERNS[@]} -eq 0 ]; then
            echo -e "${GREEN}✅ .gitignore has required patterns${NC}"
            ((COMPLIANCE_SCORE++))
        else
            echo -e "${YELLOW}⚠️  .gitignore missing patterns: ${MISSING_PATTERNS[*]}${NC}"
        fi
    fi
else
    echo -e "${RED}❌ Not a git repository${NC}"
    ((VIOLATIONS++))
fi

# Security compliance
echo ""
echo "🔒 Security Compliance"
echo "----------------------"

# Check for .env in .gitignore
((MAX_SCORE++))
if [ -f ".gitignore" ] && grep -q "^\.env$" .gitignore; then
    echo -e "${GREEN}✅ .env excluded from git${NC}"
    ((COMPLIANCE_SCORE++))
else
    echo -e "${YELLOW}⚠️  .env should be in .gitignore${NC}"
fi

# Check for committed secrets
((MAX_SCORE++))
SENSITIVE_PATTERNS=("password.*=" "api[_-]?key.*=" "secret.*=" "token.*=")
SECRETS_FOUND=0

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if git log --all -p 2>/dev/null | grep -iE "$pattern" | grep -v "example" | head -1 | grep -q .; then
        ((SECRETS_FOUND++))
    fi
done

if [ "$SECRETS_FOUND" -eq 0 ]; then
    echo -e "${GREEN}✅ No obvious secrets in git history${NC}"
    ((COMPLIANCE_SCORE++))
else
    echo -e "${RED}❌ Potential secrets found in git history${NC}"
    echo "   Run: git log --all -p | grep -i 'password\|api.key\|secret\|token'"
    ((VIOLATIONS++))
fi

# Check for security vulnerabilities
((MAX_SCORE++))
if [ -f "package.json" ]; then
    if npm audit --json > /tmp/compliance-audit.json 2>&1; then
        echo -e "${GREEN}✅ No known vulnerabilities${NC}"
        ((COMPLIANCE_SCORE++))
    else
        VULN_COUNT=$(node -p "
            try {
                const audit = require('/tmp/compliance-audit.json');
                const meta = audit.metadata || {};
                const vulns = meta.vulnerabilities || {};
                (vulns.high || 0) + (vulns.critical || 0);
            } catch(e) {
                0;
            }
        " 2>/dev/null || echo "0")
        
        if [ "$VULN_COUNT" -eq 0 ]; then
            echo -e "${YELLOW}⚠️  Low/moderate vulnerabilities found${NC}"
            ((COMPLIANCE_SCORE++))
        else
            echo -e "${RED}❌ High/critical vulnerabilities found${NC}"
            ((VIOLATIONS++))
        fi
    fi
    rm -f /tmp/compliance-audit.json
fi

# Accessibility compliance
echo ""
echo "♿ Accessibility Compliance"
echo "---------------------------"

if [ -d "src" ]; then
    # Check for semantic HTML
    ((MAX_SCORE++))
    SEMANTIC_COUNT=$(grep -rE "<(header|nav|main|section|article|footer)" src 2>/dev/null | wc -l || echo "0")
    if [ "$SEMANTIC_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Using semantic HTML${NC}"
        ((COMPLIANCE_SCORE++))
    else
        echo -e "${YELLOW}⚠️  No semantic HTML elements found${NC}"
    fi
    
    # Check for alt text
    ((MAX_SCORE++))
    IMG_TAGS=$(grep -r "<img" src 2>/dev/null | wc -l || echo "0")
    IMG_WITH_ALT=$(grep -r '<img[^>]*alt=' src 2>/dev/null | wc -l || echo "0")
    
    if [ "$IMG_TAGS" -eq 0 ] || [ "$IMG_TAGS" -eq "$IMG_WITH_ALT" ]; then
        echo -e "${GREEN}✅ Images have alt text${NC}"
        ((COMPLIANCE_SCORE++))
    else
        echo -e "${RED}❌ Some images missing alt text${NC}"
        ((VIOLATIONS++))
    fi
    
    # Check for ARIA attributes
    ((MAX_SCORE++))
    ARIA_COUNT=$(grep -r 'aria-' src 2>/dev/null | wc -l || echo "0")
    if [ "$ARIA_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Using ARIA attributes${NC}"
        ((COMPLIANCE_SCORE++))
    else
        echo -e "${YELLOW}⚠️  No ARIA attributes found${NC}"
    fi
fi

# Documentation compliance
echo ""
echo "📚 Documentation Compliance"
echo "---------------------------"

# Check README sections
((MAX_SCORE++))
if [ -f "README.md" ]; then
    REQUIRED_SECTIONS=("Installation" "Usage" "Development")
    MISSING_SECTIONS=()
    
    for section in "${REQUIRED_SECTIONS[@]}"; do
        if ! grep -qi "## $section" README.md; then
            MISSING_SECTIONS+=("$section")
        fi
    done
    
    if [ ${#MISSING_SECTIONS[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ README has required sections${NC}"
        ((COMPLIANCE_SCORE++))
    else
        echo -e "${YELLOW}⚠️  README missing sections: ${MISSING_SECTIONS[*]}${NC}"
    fi
fi

# Check for CHANGELOG
((MAX_SCORE++))
if [ -f "CHANGELOG.md" ]; then
    echo -e "${GREEN}✅ CHANGELOG.md exists${NC}"
    ((COMPLIANCE_SCORE++))
else
    echo -e "${YELLOW}⚠️  CHANGELOG.md recommended${NC}"
fi

# Check for LICENSE
((MAX_SCORE++))
if [ -f "LICENSE" ] || [ -f "LICENSE.md" ]; then
    echo -e "${GREEN}✅ LICENSE file exists${NC}"
    ((COMPLIANCE_SCORE++))
else
    echo -e "${YELLOW}⚠️  LICENSE file recommended${NC}"
fi

# Check for inline documentation
((MAX_SCORE++))
if [ -d "src/components" ]; then
    COMPONENTS=$(find src/components -name "*.jsx" -o -name "*.tsx" | wc -l)
    DOCUMENTED=$(grep -l "^/\*\*" src/components/*.{jsx,tsx} 2>/dev/null | wc -l || echo "0")
    
    if [ "$COMPONENTS" -gt 0 ]; then
        DOC_PERCENTAGE=$((DOCUMENTED * 100 / COMPONENTS))
        if [ "$DOC_PERCENTAGE" -ge 80 ]; then
            echo -e "${GREEN}✅ Components well documented ($DOC_PERCENTAGE%)${NC}"
            ((COMPLIANCE_SCORE++))
        elif [ "$DOC_PERCENTAGE" -ge 50 ]; then
            echo -e "${YELLOW}⚠️  Some components undocumented ($DOC_PERCENTAGE%)${NC}"
        else
            echo -e "${RED}❌ Poor component documentation ($DOC_PERCENTAGE%)${NC}"
        fi
    fi
fi

# Testing compliance
echo ""
echo "🧪 Testing Compliance"
echo "---------------------"

((MAX_SCORE++))
TEST_FILES=$(find . -name "*.test.js" -o -name "*.test.jsx" -o -name "*.spec.js" -o -name "*.spec.jsx" 2>/dev/null | wc -l)

if [ "$TEST_FILES" -gt 0 ]; then
    echo -e "${GREEN}✅ Test files present ($TEST_FILES files)${NC}"
    ((COMPLIANCE_SCORE++))
else
    echo -e "${YELLOW}⚠️  No test files found${NC}"
fi

# Check for test configuration
((MAX_SCORE++))
if grep -q "vitest\|jest" package.json 2>/dev/null; then
    echo -e "${GREEN}✅ Test framework configured${NC}"
    ((COMPLIANCE_SCORE++))
else
    echo -e "${YELLOW}⚠️  No test framework configured${NC}"
fi

# Build compliance
echo ""
echo "🏗️  Build Compliance"
echo "--------------------"

((MAX_SCORE++))
if [ -f "package.json" ]; then
    if node -p "require('./package.json').scripts.build" &>/dev/null; then
        echo -e "${GREEN}✅ Build script configured${NC}"
        ((COMPLIANCE_SCORE++))
    else
        echo -e "${RED}❌ No build script${NC}"
        ((VIOLATIONS++))
    fi
fi

((MAX_SCORE++))
if [ -d "dist" ] || [ -d "build" ]; then
    echo -e "${GREEN}✅ Build output exists${NC}"
    ((COMPLIANCE_SCORE++))
else
    echo -e "${YELLOW}⚠️  No build output (run: npm run build)${NC}"
fi

# Performance compliance
echo ""
echo "⚡ Performance Compliance"
echo "-------------------------"

if [ -d "dist" ]; then
    ((MAX_SCORE++))
    JS_SIZE_KB=$(find dist -name "*.js" -exec stat -f%z {} + 2>/dev/null | awk '{s+=$1} END {print s/1024}' || echo "0")
    
    if [ "${JS_SIZE_KB%.*}" -lt 500 ]; then
        echo -e "${GREEN}✅ Bundle size acceptable (<500KB)${NC}"
        ((COMPLIANCE_SCORE++))
    elif [ "${JS_SIZE_KB%.*}" -lt 1000 ]; then
        echo -e "${YELLOW}⚠️  Bundle size moderate (${JS_SIZE_KB%.*}KB)${NC}"
    else
        echo -e "${RED}❌ Bundle size large (${JS_SIZE_KB%.*}KB)${NC}"
    fi
fi

# Code quality compliance
echo ""
echo "✨ Code Quality Compliance"
echo "--------------------------"

if [ -d "src" ]; then
    # Check for console.log
    ((MAX_SCORE++))
    CONSOLE_LOGS=$(grep -r "console\.log" src 2>/dev/null | wc -l || echo "0")
    if [ "$CONSOLE_LOGS" -lt 5 ]; then
        echo -e "${GREEN}✅ Minimal debug statements${NC}"
        ((COMPLIANCE_SCORE++))
    else
        echo -e "${YELLOW}⚠️  Many console.log statements ($CONSOLE_LOGS)${NC}"
    fi
    
    # Check for TODO/FIXME
    ((MAX_SCORE++))
    TODO_COUNT=$(grep -r "TODO\|FIXME" src 2>/dev/null | wc -l || echo "0")
    if [ "$TODO_COUNT" -lt 10 ]; then
        echo -e "${GREEN}✅ Few TODO/FIXME comments${NC}"
        ((COMPLIANCE_SCORE++))
    else
        echo -e "${YELLOW}⚠️  Many TODO/FIXME comments ($TODO_COUNT)${NC}"
    fi
fi

# Calculate compliance percentage
COMPLIANCE_PERCENTAGE=$((COMPLIANCE_SCORE * 100 / MAX_SCORE))

# Summary
echo ""
echo "==================="
echo -e "${CYAN}Compliance Summary${NC}"
echo "==================="
echo ""
echo "Score: $COMPLIANCE_SCORE/$MAX_SCORE ($COMPLIANCE_PERCENTAGE%)"
echo "Violations: $VIOLATIONS"
echo ""

if [ "$COMPLIANCE_PERCENTAGE" -ge 90 ]; then
    echo -e "${GREEN}✅ EXCELLENT COMPLIANCE${NC}"
    echo "Project meets or exceeds standards"
elif [ "$COMPLIANCE_PERCENTAGE" -ge 75 ]; then
    echo -e "${GREEN}✅ GOOD COMPLIANCE${NC}"
    echo "Project meets most standards"
elif [ "$COMPLIANCE_PERCENTAGE" -ge 60 ]; then
    echo -e "${YELLOW}⚠️  MODERATE COMPLIANCE${NC}"
    echo "Some standards not met - improvement needed"
else
    echo -e "${RED}❌ POOR COMPLIANCE${NC}"
    echo "Many standards not met - significant improvement required"
fi

echo ""
echo "Standards checked:"
echo "  • File structure"
echo "  • Code standards"
echo "  • Git practices"
echo "  • Security"
echo "  • Accessibility"
echo "  • Documentation"
echo "  • Testing"
echo "  • Build process"
echo "  • Performance"
echo "  • Code quality"

echo ""
echo "Recommendations:"
[ "$VIOLATIONS" -gt 0 ] && echo "  • Address $VIOLATIONS critical violations"
[ "$COMPLIANCE_PERCENTAGE" -lt 90 ] && echo "  • Improve compliance to 90%+"
echo "  • Regular compliance checks"
echo "  • Automated compliance in CI/CD"
echo "  • Document compliance requirements"

exit 0
