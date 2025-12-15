#!/bin/bash
# reviewer.sh - Code review automation
# Performs static analysis, linting, and code quality checks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔍 Code Review Automation"
echo "========================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

ISSUES_FOUND=0

# Check for uncommitted changes
echo ""
echo "📊 Git Status Check"
if [ -d "$PROJECT_ROOT/.git" ]; then
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}⚠️  Uncommitted changes detected${NC}"
        git status --short
    else
        echo -e "${GREEN}✅ Working directory clean${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Not a git repository${NC}"
fi

# Check package.json for issues
echo ""
echo "📦 Package.json Review"
if [ -f "$PROJECT_ROOT/package.json" ]; then
    echo -e "${GREEN}✅ package.json found${NC}"
    
    # Check for dependencies
    DEP_COUNT=$(node -p "Object.keys(require('$PROJECT_ROOT/package.json').dependencies || {}).length" 2>/dev/null || echo "0")
    DEV_DEP_COUNT=$(node -p "Object.keys(require('$PROJECT_ROOT/package.json').devDependencies || {}).length" 2>/dev/null || echo "0")
    
    echo "   Dependencies: $DEP_COUNT"
    echo "   Dev Dependencies: $DEV_DEP_COUNT"
    
    # Check for scripts
    if node -p "require('$PROJECT_ROOT/package.json').scripts" &>/dev/null; then
        echo -e "   ${GREEN}✅ Scripts defined${NC}"
    else
        echo -e "   ${YELLOW}⚠️  No scripts defined${NC}"
        ((ISSUES_FOUND++))
    fi
else
    echo -e "${RED}❌ package.json not found${NC}"
    ((ISSUES_FOUND++))
fi

# Check for security vulnerabilities
echo ""
echo "🔒 Security Audit"
if command -v npm &> /dev/null; then
    if [ -f "$PROJECT_ROOT/package-lock.json" ]; then
        echo "   Running npm audit..."
        if npm audit --audit-level=moderate 2>&1 | grep -q "found 0 vulnerabilities"; then
            echo -e "   ${GREEN}✅ No vulnerabilities found${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Vulnerabilities detected - run 'npm audit' for details${NC}"
            ((ISSUES_FOUND++))
        fi
    else
        echo -e "   ${YELLOW}⚠️  package-lock.json not found - run 'npm install'${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  npm not available${NC}"
fi

# Check code structure
echo ""
echo "🏗️  Code Structure Review"

# Check for src directory
if [ -d "$PROJECT_ROOT/src" ]; then
    echo -e "${GREEN}✅ src/ directory exists${NC}"
    
    # Count files by type
    JS_FILES=$(find "$PROJECT_ROOT/src" -name "*.js" | wc -l)
    JSX_FILES=$(find "$PROJECT_ROOT/src" -name "*.jsx" | wc -l)
    TS_FILES=$(find "$PROJECT_ROOT/src" -name "*.ts" | wc -l)
    TSX_FILES=$(find "$PROJECT_ROOT/src" -name "*.tsx" | wc -l)
    
    echo "   JavaScript files: $JS_FILES"
    echo "   JSX files: $JSX_FILES"
    echo "   TypeScript files: $TS_FILES"
    echo "   TSX files: $TSX_FILES"
    
    TOTAL_FILES=$((JS_FILES + JSX_FILES + TS_FILES + TSX_FILES))
    echo "   Total source files: $TOTAL_FILES"
else
    echo -e "${RED}❌ src/ directory not found${NC}"
    ((ISSUES_FOUND++))
fi

# Check for common directories
echo ""
echo "📁 Directory Structure"
EXPECTED_DIRS=("src/components" "src/pages" "src/utils" "src/styles")
for dir in "${EXPECTED_DIRS[@]}"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        FILE_COUNT=$(find "$PROJECT_ROOT/$dir" -type f | wc -l)
        echo -e "   ${GREEN}✅ $dir ($FILE_COUNT files)${NC}"
    else
        echo -e "   ${YELLOW}⚠️  $dir not found${NC}"
    fi
done

# Check for large files
echo ""
echo "📏 File Size Check"
LARGE_FILES=$(find "$PROJECT_ROOT/src" -type f -size +100k 2>/dev/null || true)
if [ -z "$LARGE_FILES" ]; then
    echo -e "${GREEN}✅ No large files (>100KB) in src/${NC}"
else
    echo -e "${YELLOW}⚠️  Large files detected:${NC}"
    echo "$LARGE_FILES" | while read -r file; do
        SIZE=$(du -h "$file" | cut -f1)
        echo "   $SIZE - $(basename "$file")"
    done
    ((ISSUES_FOUND++))
fi

# Check for console.log statements
echo ""
echo "🐛 Debug Statement Check"
CONSOLE_LOGS=$(grep -r "console\.log" "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")
if [ "$CONSOLE_LOGS" -eq 0 ]; then
    echo -e "${GREEN}✅ No console.log statements found${NC}"
else
    echo -e "${YELLOW}⚠️  Found $CONSOLE_LOGS console.log statements${NC}"
    echo "   Consider removing debug statements before production"
    ((ISSUES_FOUND++))
fi

# Check for TODO/FIXME comments
echo ""
echo "📝 TODO/FIXME Check"
TODOS=$(grep -r "TODO\|FIXME" "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")
if [ "$TODOS" -eq 0 ]; then
    echo -e "${GREEN}✅ No TODO/FIXME comments${NC}"
else
    echo -e "${BLUE}ℹ️  Found $TODOS TODO/FIXME comments${NC}"
    grep -rn "TODO\|FIXME" "$PROJECT_ROOT/src" 2>/dev/null | head -5 | while read -r line; do
        echo "   $line"
    done
    if [ "$TODOS" -gt 5 ]; then
        echo "   ... and $((TODOS - 5)) more"
    fi
fi

# Check for proper error handling
echo ""
echo "⚠️  Error Handling Check"
TRY_CATCH=$(grep -r "try {" "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")
ERROR_BOUNDARY=$(find "$PROJECT_ROOT/src" -name "*ErrorBoundary*" | wc -l || echo "0")

echo "   try/catch blocks: $TRY_CATCH"
echo "   Error boundaries: $ERROR_BOUNDARY"

if [ "$ERROR_BOUNDARY" -gt 0 ]; then
    echo -e "   ${GREEN}✅ Error boundary implemented${NC}"
else
    echo -e "   ${YELLOW}⚠️  Consider implementing error boundaries${NC}"
fi

# Check for test files
echo ""
echo "🧪 Test Coverage Check"
TEST_FILES=$(find "$PROJECT_ROOT" -name "*.test.js" -o -name "*.test.jsx" -o -name "*.spec.js" -o -name "*.spec.jsx" | wc -l)
if [ "$TEST_FILES" -gt 0 ]; then
    echo -e "${GREEN}✅ Found $TEST_FILES test files${NC}"
else
    echo -e "${YELLOW}⚠️  No test files found${NC}"
    echo "   Consider adding tests for components and utilities"
    ((ISSUES_FOUND++))
fi

# Check for .env files
echo ""
echo "🔐 Environment Variables Check"
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${YELLOW}⚠️  .env file found${NC}"
    echo "   Ensure .env is in .gitignore"
    
    if grep -q "^\.env$" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
        echo -e "   ${GREEN}✅ .env is in .gitignore${NC}"
    else
        echo -e "   ${RED}❌ .env NOT in .gitignore${NC}"
        ((ISSUES_FOUND++))
    fi
else
    echo -e "${GREEN}✅ No .env file in root${NC}"
fi

# Check gitignore
echo ""
echo "🚫 .gitignore Check"
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
    echo -e "${GREEN}✅ .gitignore exists${NC}"
    
    REQUIRED_PATTERNS=("node_modules" "dist" "build" ".env")
    for pattern in "${REQUIRED_PATTERNS[@]}"; do
        if grep -q "$pattern" "$PROJECT_ROOT/.gitignore"; then
            echo "   ✅ Ignores: $pattern"
        else
            echo -e "   ${YELLOW}⚠️  Missing: $pattern${NC}"
            ((ISSUES_FOUND++))
        fi
    done
else
    echo -e "${RED}❌ .gitignore not found${NC}"
    ((ISSUES_FOUND++))
fi

# Check for documentation
echo ""
echo "📚 Documentation Check"
DOC_FILES=$(find "$PROJECT_ROOT/docs" -name "*.md" 2>/dev/null | wc -l || echo "0")
if [ "$DOC_FILES" -gt 0 ]; then
    echo -e "${GREEN}✅ Found $DOC_FILES documentation files${NC}"
else
    echo -e "${YELLOW}⚠️  No documentation in docs/ directory${NC}"
fi

# Summary
echo ""
echo "========================="
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ Code review complete - No critical issues found${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Code review complete - $ISSUES_FOUND issues found${NC}"
    echo ""
    echo "Review the warnings above and address as needed."
    exit 0
fi
