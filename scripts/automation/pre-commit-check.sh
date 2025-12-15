#!/bin/bash
# pre-commit-check.sh - Pre-commit validation
# Runs before commits to ensure code quality

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔍 Pre-Commit Checks"
echo "===================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CHECKS_FAILED=0

# Check if we're in a git repository
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo -e "${RED}❌ Not a git repository${NC}"
    exit 1
fi

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    echo -e "${YELLOW}⚠️  No files staged for commit${NC}"
    exit 0
fi

echo "📝 Staged files:"
echo "$STAGED_FILES" | while read -r file; do
    echo "   • $file"
done

# Check for large files
echo ""
echo "📏 Checking file sizes..."
LARGE_FILES=""
while IFS= read -r file; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        SIZE=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file" 2>/dev/null || echo "0")
        if [ "$SIZE" -gt 1048576 ]; then  # 1MB
            SIZE_MB=$((SIZE / 1048576))
            LARGE_FILES="$LARGE_FILES\n   $file (${SIZE_MB}MB)"
            ((CHECKS_FAILED++))
        fi
    fi
done <<< "$STAGED_FILES"

if [ -n "$LARGE_FILES" ]; then
    echo -e "${RED}❌ Large files detected (>1MB):${NC}"
    echo -e "$LARGE_FILES"
    echo "   Consider using Git LFS or excluding from repository"
else
    echo -e "${GREEN}✅ No large files${NC}"
fi

# Check for sensitive data patterns
echo ""
echo "🔐 Checking for sensitive data..."
SENSITIVE_PATTERNS=(
    "password.*=.*['\"]"
    "api[_-]?key.*=.*['\"]"
    "secret.*=.*['\"]"
    "token.*=.*['\"]"
    "private[_-]?key"
    "aws[_-]?access"
    "BEGIN.*PRIVATE.*KEY"
)

SENSITIVE_FOUND=""
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    while IFS= read -r file; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            if grep -iE "$pattern" "$PROJECT_ROOT/$file" > /dev/null 2>&1; then
                SENSITIVE_FOUND="$SENSITIVE_FOUND\n   $file: matches '$pattern'"
                ((CHECKS_FAILED++))
            fi
        fi
    done <<< "$STAGED_FILES"
done

if [ -n "$SENSITIVE_FOUND" ]; then
    echo -e "${RED}❌ Potential sensitive data found:${NC}"
    echo -e "$SENSITIVE_FOUND"
    echo "   Review and remove sensitive data before committing"
else
    echo -e "${GREEN}✅ No sensitive data patterns detected${NC}"
fi

# Check for debug statements
echo ""
echo "🐛 Checking for debug statements..."
DEBUG_FOUND=""
while IFS= read -r file; do
    if [[ "$file" =~ \.(js|jsx|ts|tsx)$ ]]; then
        if [ -f "$PROJECT_ROOT/$file" ]; then
            if grep -n "console\.log\|debugger" "$PROJECT_ROOT/$file" > /dev/null 2>&1; then
                DEBUG_FOUND="$DEBUG_FOUND\n   $file"
            fi
        fi
    fi
done <<< "$STAGED_FILES"

if [ -n "$DEBUG_FOUND" ]; then
    echo -e "${YELLOW}⚠️  Debug statements found:${NC}"
    echo -e "$DEBUG_FOUND"
    echo "   Consider removing console.log and debugger statements"
else
    echo -e "${GREEN}✅ No debug statements${NC}"
fi

# Check for TODO/FIXME in staged files
echo ""
echo "📝 Checking for TODO/FIXME..."
TODO_FOUND=""
while IFS= read -r file; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        if grep -n "TODO\|FIXME" "$PROJECT_ROOT/$file" > /dev/null 2>&1; then
            TODO_FOUND="$TODO_FOUND\n   $file"
        fi
    fi
done <<< "$STAGED_FILES"

if [ -n "$TODO_FOUND" ]; then
    echo -e "${YELLOW}⚠️  TODO/FIXME comments found:${NC}"
    echo -e "$TODO_FOUND"
    echo "   Review and address before committing"
else
    echo -e "${GREEN}✅ No TODO/FIXME comments${NC}"
fi

# Check for merge conflict markers
echo ""
echo "⚔️  Checking for merge conflicts..."
CONFLICT_MARKERS=""
while IFS= read -r file; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        if grep -n "^<<<<<<< \|^=======$\|^>>>>>>> " "$PROJECT_ROOT/$file" > /dev/null 2>&1; then
            CONFLICT_MARKERS="$CONFLICT_MARKERS\n   $file"
            ((CHECKS_FAILED++))
        fi
    fi
done <<< "$STAGED_FILES"

if [ -n "$CONFLICT_MARKERS" ]; then
    echo -e "${RED}❌ Merge conflict markers found:${NC}"
    echo -e "$CONFLICT_MARKERS"
    echo "   Resolve conflicts before committing"
else
    echo -e "${GREEN}✅ No merge conflict markers${NC}"
fi

# Check for trailing whitespace
echo ""
echo "🔤 Checking for trailing whitespace..."
WHITESPACE_FOUND=""
while IFS= read -r file; do
    if [[ "$file" =~ \.(js|jsx|ts|tsx|css|html|md)$ ]]; then
        if [ -f "$PROJECT_ROOT/$file" ]; then
            if grep -n " $" "$PROJECT_ROOT/$file" > /dev/null 2>&1; then
                WHITESPACE_FOUND="$WHITESPACE_FOUND\n   $file"
            fi
        fi
    fi
done <<< "$STAGED_FILES"

if [ -n "$WHITESPACE_FOUND" ]; then
    echo -e "${YELLOW}⚠️  Trailing whitespace found:${NC}"
    echo -e "$WHITESPACE_FOUND"
    echo "   Run formatter to fix"
else
    echo -e "${GREEN}✅ No trailing whitespace${NC}"
fi

# Check for package.json changes
echo ""
echo "📦 Checking package.json..."
if echo "$STAGED_FILES" | grep -q "package.json"; then
    echo -e "${YELLOW}⚠️  package.json modified${NC}"
    
    # Check if package-lock.json is also staged
    if echo "$STAGED_FILES" | grep -q "package-lock.json"; then
        echo -e "   ${GREEN}✅ package-lock.json also staged${NC}"
    else
        echo -e "   ${YELLOW}⚠️  package-lock.json not staged${NC}"
        echo "   Consider staging package-lock.json if dependencies changed"
    fi
else
    echo -e "${GREEN}✅ package.json not modified${NC}"
fi

# Check for .env files
echo ""
echo "🔐 Checking for .env files..."
ENV_FILES=""
while IFS= read -r file; do
    if [[ "$file" =~ \.env ]]; then
        ENV_FILES="$ENV_FILES\n   $file"
        ((CHECKS_FAILED++))
    fi
done <<< "$STAGED_FILES"

if [ -n "$ENV_FILES" ]; then
    echo -e "${RED}❌ .env files staged:${NC}"
    echo -e "$ENV_FILES"
    echo "   Remove .env files from staging and add to .gitignore"
else
    echo -e "${GREEN}✅ No .env files staged${NC}"
fi

# Check for node_modules
echo ""
echo "📦 Checking for node_modules..."
if echo "$STAGED_FILES" | grep -q "node_modules"; then
    echo -e "${RED}❌ node_modules files staged${NC}"
    echo "   Remove node_modules from staging and ensure it's in .gitignore"
    ((CHECKS_FAILED++))
else
    echo -e "${GREEN}✅ No node_modules files staged${NC}"
fi

# Run syntax check for JavaScript/TypeScript files
echo ""
echo "✅ Syntax check..."
SYNTAX_ERRORS=""
while IFS= read -r file; do
    if [[ "$file" =~ \.(js|jsx)$ ]]; then
        if [ -f "$PROJECT_ROOT/$file" ]; then
            if ! node -c "$PROJECT_ROOT/$file" 2>/dev/null; then
                SYNTAX_ERRORS="$SYNTAX_ERRORS\n   $file"
                ((CHECKS_FAILED++))
            fi
        fi
    fi
done <<< "$STAGED_FILES"

if [ -n "$SYNTAX_ERRORS" ]; then
    echo -e "${RED}❌ Syntax errors found:${NC}"
    echo -e "$SYNTAX_ERRORS"
else
    echo -e "${GREEN}✅ No syntax errors${NC}"
fi

# Summary
echo ""
echo "===================="
if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All pre-commit checks passed${NC}"
    echo ""
    echo "Ready to commit!"
    exit 0
else
    echo -e "${RED}❌ Pre-commit checks failed: $CHECKS_FAILED issues${NC}"
    echo ""
    echo "Fix the issues above before committing."
    echo "To bypass these checks (not recommended), use: git commit --no-verify"
    exit 1
fi
