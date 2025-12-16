#!/bin/bash
# deps-audit.sh - Dependency audit and security check
# Analyzes dependencies for security vulnerabilities and outdated packages

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔒 Dependency Audit"
echo "==================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

cd "$PROJECT_ROOT"

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json not found${NC}"
    exit 1
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠️  node_modules not found${NC}"
    echo "Run: npm install"
    exit 1
fi

# Package info
echo ""
echo "📦 Package Information"
PKG_NAME=$(node -p "require('./package.json').name" 2>/dev/null || echo "unknown")
PKG_VERSION=$(node -p "require('./package.json').version" 2>/dev/null || echo "0.0.0")
echo "Name: $PKG_NAME"
echo "Version: $PKG_VERSION"

# Count dependencies
DEP_COUNT=$(node -p "Object.keys(require('./package.json').dependencies || {}).length" 2>/dev/null || echo "0")
DEV_DEP_COUNT=$(node -p "Object.keys(require('./package.json').devDependencies || {}).length" 2>/dev/null || echo "0")
TOTAL_DEPS=$((DEP_COUNT + DEV_DEP_COUNT))

echo "Dependencies: $DEP_COUNT"
echo "Dev Dependencies: $DEV_DEP_COUNT"
echo "Total: $TOTAL_DEPS"

# Security audit
echo ""
echo "🔒 Security Audit"
echo "Running npm audit..."

if npm audit --json > /tmp/audit-result.json 2>&1; then
    echo -e "${GREEN}✅ No vulnerabilities found${NC}"
    VULN_COUNT=0
else
    # Parse audit results
    if [ -f /tmp/audit-result.json ]; then
        VULN_COUNT=$(node -p "
            try {
                const audit = require('/tmp/audit-result.json');
                const meta = audit.metadata || {};
                const vulns = meta.vulnerabilities || {};
                (vulns.info || 0) + (vulns.low || 0) + (vulns.moderate || 0) + (vulns.high || 0) + (vulns.critical || 0);
            } catch(e) {
                0;
            }
        " 2>/dev/null || echo "0")
        
        if [ "$VULN_COUNT" -gt 0 ]; then
            echo -e "${RED}❌ Found $VULN_COUNT vulnerabilities${NC}"
            
            # Show vulnerability breakdown
            INFO=$(node -p "require('/tmp/audit-result.json').metadata?.vulnerabilities?.info || 0" 2>/dev/null || echo "0")
            LOW=$(node -p "require('/tmp/audit-result.json').metadata?.vulnerabilities?.low || 0" 2>/dev/null || echo "0")
            MODERATE=$(node -p "require('/tmp/audit-result.json').metadata?.vulnerabilities?.moderate || 0" 2>/dev/null || echo "0")
            HIGH=$(node -p "require('/tmp/audit-result.json').metadata?.vulnerabilities?.high || 0" 2>/dev/null || echo "0")
            CRITICAL=$(node -p "require('/tmp/audit-result.json').metadata?.vulnerabilities?.critical || 0" 2>/dev/null || echo "0")
            
            echo ""
            echo "Severity breakdown:"
            [ "$INFO" -gt 0 ] && echo -e "  ${BLUE}Info: $INFO${NC}"
            [ "$LOW" -gt 0 ] && echo -e "  ${GREEN}Low: $LOW${NC}"
            [ "$MODERATE" -gt 0 ] && echo -e "  ${YELLOW}Moderate: $MODERATE${NC}"
            [ "$HIGH" -gt 0 ] && echo -e "  ${RED}High: $HIGH${NC}"
            [ "$CRITICAL" -gt 0 ] && echo -e "  ${RED}Critical: $CRITICAL${NC}"
            
            echo ""
            echo "Run 'npm audit' for detailed report"
            echo "Run 'npm audit fix' to automatically fix issues"
        fi
    fi
fi

# Check for outdated packages
echo ""
echo "📊 Outdated Packages"
echo "Checking for updates..."

if npm outdated --json > /tmp/outdated-result.json 2>&1; then
    echo -e "${GREEN}✅ All packages up to date${NC}"
else
    if [ -f /tmp/outdated-result.json ]; then
        OUTDATED_COUNT=$(node -p "Object.keys(require('/tmp/outdated-result.json')).length" 2>/dev/null || echo "0")
        
        if [ "$OUTDATED_COUNT" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  $OUTDATED_COUNT packages outdated${NC}"
            echo ""
            echo "Package updates available:"
            
            node -p "
                try {
                    const outdated = require('/tmp/outdated-result.json');
                    Object.entries(outdated).slice(0, 10).map(([name, info]) => {
                        const current = info.current || 'N/A';
                        const latest = info.latest || 'N/A';
                        const type = info.type || 'dependencies';
                        return \`  • \${name}: \${current} → \${latest} (\${type})\`;
                    }).join('\n');
                } catch(e) {
                    'Unable to parse outdated packages';
                }
            " 2>/dev/null || echo "  Unable to parse results"
            
            if [ "$OUTDATED_COUNT" -gt 10 ]; then
                echo "  ... and $((OUTDATED_COUNT - 10)) more"
            fi
            
            echo ""
            echo "Run 'npm outdated' for full list"
            echo "Run 'npm update' to update packages"
        fi
    fi
fi

# Check for duplicate dependencies
echo ""
echo "🔄 Duplicate Dependencies"
if command -v npm &> /dev/null; then
    DUPLICATES=$(npm ls --all 2>/dev/null | grep -c "deduped" || echo "0")
    
    if [ "$DUPLICATES" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Found $DUPLICATES duplicate packages${NC}"
        echo "Run 'npm dedupe' to remove duplicates"
    else
        echo -e "${GREEN}✅ No duplicates found${NC}"
    fi
fi

# Check dependency sizes
echo ""
echo "💾 Dependency Sizes"
if [ -d "node_modules" ]; then
    NODE_MODULES_SIZE=$(du -sh node_modules 2>/dev/null | cut -f1)
    echo "node_modules size: $NODE_MODULES_SIZE"
    
    # Find largest packages
    echo ""
    echo "Largest packages (top 5):"
    du -sh node_modules/* 2>/dev/null | sort -rh | head -5 | while read -r size package; do
        echo "  $size - $(basename "$package")"
    done
fi

# Check for unused dependencies
echo ""
echo "🗑️  Unused Dependencies Check"
echo "Analyzing imports..."

# Simple check for unused dependencies
UNUSED=()
if [ -d "src" ]; then
    while IFS= read -r dep; do
        # Skip common packages that might not be directly imported
        if [[ "$dep" =~ ^(@types/|eslint-|prettier|vite) ]]; then
            continue
        fi
        
        # Check if dependency is imported anywhere
        if ! grep -r "from ['\"]$dep['\"]" src/ 2>/dev/null | grep -q .; then
            if ! grep -r "require(['\"]$dep['\"])" src/ 2>/dev/null | grep -q .; then
                UNUSED+=("$dep")
            fi
        fi
    done < <(node -p "Object.keys(require('./package.json').dependencies || {}).join('\n')" 2>/dev/null)
    
    if [ ${#UNUSED[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Potentially unused dependencies:${NC}"
        for dep in "${UNUSED[@]}"; do
            echo "  • $dep"
        done
        echo ""
        echo "Note: This is a basic check. Verify before removing."
    else
        echo -e "${GREEN}✅ All dependencies appear to be used${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  src/ directory not found - skipping check${NC}"
fi

# Check for peer dependency warnings
echo ""
echo "🔗 Peer Dependencies"
PEER_WARNINGS=$(npm ls 2>&1 | grep -c "UNMET PEER DEPENDENCY" || true)
PEER_WARNINGS=${PEER_WARNINGS:-0}

if [ "$PEER_WARNINGS" -gt 0 ] 2>/dev/null; then
    echo -e "${YELLOW}⚠️  $PEER_WARNINGS unmet peer dependencies${NC}"
    echo "Run 'npm ls' for details"
else
    echo -e "${GREEN}✅ All peer dependencies met${NC}"
fi

# Check package-lock.json
echo ""
echo "🔒 Lock File"
if [ -f "package-lock.json" ]; then
    LOCK_SIZE=$(du -h package-lock.json | cut -f1)
    echo -e "${GREEN}✅ package-lock.json exists ($LOCK_SIZE)${NC}"
    
    # Check if lock file is in sync
    if npm ls >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Lock file in sync${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Lock file may be out of sync${NC}"
        echo "   Run: npm install"
    fi
else
    echo -e "${RED}❌ package-lock.json not found${NC}"
    echo "Run: npm install"
fi

# Check for deprecated packages
echo ""
echo "⚠️  Deprecated Packages"
DEPRECATED=$(npm ls --depth=0 2>&1 | grep -c "DEPRECATED" || true)
DEPRECATED=${DEPRECATED:-0}

if [ "$DEPRECATED" -gt 0 ] 2>/dev/null; then
    echo -e "${YELLOW}⚠️  $DEPRECATED deprecated packages found${NC}"
    npm ls --depth=0 2>&1 | grep "DEPRECATED" | head -5
    echo ""
    echo "Consider updating or replacing deprecated packages"
else
    echo -e "${GREEN}✅ No deprecated packages${NC}"
fi

# License check
echo ""
echo "📜 License Check"
echo "Checking package licenses..."

# Count packages by license type
if command -v jq &> /dev/null; then
    echo "License distribution:"
    npm ls --json --depth=0 2>/dev/null | jq -r '.dependencies | to_entries[] | .value.license // "Unknown"' | sort | uniq -c | sort -rn | head -5 | while read -r count license; do
        echo "  $count packages: $license"
    done
else
    echo "Install 'jq' for detailed license analysis"
fi

# Summary and recommendations
echo ""
echo "==================="
echo -e "${CYAN}Summary${NC}"
echo "==================="

ISSUES=0
[ "$VULN_COUNT" -gt 0 ] && ((ISSUES++))
[ "$OUTDATED_COUNT" -gt 0 ] && ((ISSUES++))
[ "$DUPLICATES" -gt 0 ] && ((ISSUES++))
[ ${#UNUSED[@]} -gt 0 ] && ((ISSUES++))

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ All dependency checks passed${NC}"
else
    echo -e "${YELLOW}⚠️  Found issues in $ISSUES categories${NC}"
fi

echo ""
echo "Recommendations:"
[ "$VULN_COUNT" -gt 0 ] && echo "  • Run 'npm audit fix' to fix vulnerabilities"
[ "$OUTDATED_COUNT" -gt 0 ] && echo "  • Run 'npm update' to update packages"
[ "$DUPLICATES" -gt 0 ] && echo "  • Run 'npm dedupe' to remove duplicates"
[ ${#UNUSED[@]} -gt 0 ] && echo "  • Review and remove unused dependencies"
echo "  • Keep dependencies up to date regularly"
echo "  • Review security advisories for your packages"
echo "  • Consider using 'npm ci' in CI/CD for reproducible builds"

# Cleanup
rm -f /tmp/audit-result.json /tmp/outdated-result.json

echo ""
echo "For more details:"
echo "  npm audit          - Security vulnerabilities"
echo "  npm outdated       - Outdated packages"
echo "  npm ls             - Dependency tree"
