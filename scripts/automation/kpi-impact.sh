#!/bin/bash
# kpi-impact.sh - KPI impact analysis
# Analyzes key performance indicators and their impact

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

echo -e "${CYAN}📈 KPI Impact Analysis${NC}"
echo "======================"
echo ""

cd "$PROJECT_ROOT"

# Project metrics
echo "📊 Project Metrics"
echo "------------------"

# Code metrics
if [ -d "src" ]; then
    TOTAL_FILES=$(find src -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" \) | wc -l)
    TOTAL_LINES=$(find src -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" \) -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    COMPONENT_COUNT=$(find src/components -type f \( -name "*.jsx" -o -name "*.tsx" \) 2>/dev/null | wc -l || echo "0")
    PAGE_COUNT=$(find src/pages -type f \( -name "*.jsx" -o -name "*.tsx" \) 2>/dev/null | wc -l || echo "0")
    
    echo "Source files: $TOTAL_FILES"
    echo "Lines of code: $TOTAL_LINES"
    echo "Components: $COMPONENT_COUNT"
    echo "Pages: $PAGE_COUNT"
    
    # Calculate average file size
    if [ "$TOTAL_FILES" -gt 0 ]; then
        AVG_LINES=$((TOTAL_LINES / TOTAL_FILES))
        echo "Average file size: $AVG_LINES lines"
        
        if [ "$AVG_LINES" -gt 300 ]; then
            echo -e "${YELLOW}⚠️  Large average file size - consider splitting${NC}"
        else
            echo -e "${GREEN}✅ Good file size${NC}"
        fi
    fi
fi

# Build metrics
echo ""
echo "🏗️  Build Metrics"
echo "-----------------"

if [ -d "dist" ]; then
    DIST_SIZE=$(du -sh dist 2>/dev/null | cut -f1)
    DIST_FILES=$(find dist -type f | wc -l)
    
    echo "Build size: $DIST_SIZE"
    echo "Build files: $DIST_FILES"
    
    # JavaScript bundle size
    JS_SIZE=$(find dist -name "*.js" -exec du -ch {} + 2>/dev/null | tail -1 | cut -f1 || echo "0")
    CSS_SIZE=$(find dist -name "*.css" -exec du -ch {} + 2>/dev/null | tail -1 | cut -f1 || echo "0")
    
    echo "JavaScript: $JS_SIZE"
    echo "CSS: $CSS_SIZE"
    
    # Check bundle size impact
    JS_SIZE_KB=$(find dist -name "*.js" -exec stat -f%z {} + 2>/dev/null | awk '{s+=$1} END {print s/1024}' || echo "0")
    if [ "${JS_SIZE_KB%.*}" -gt 500 ]; then
        echo -e "${YELLOW}⚠️  Large JavaScript bundle - impacts load time${NC}"
    else
        echo -e "${GREEN}✅ Good bundle size${NC}"
    fi
else
    echo "No build found - run: npm run build"
fi

# Dependency metrics
echo ""
echo "📦 Dependency Metrics"
echo "---------------------"

if [ -f "package.json" ]; then
    DEP_COUNT=$(node -p "Object.keys(require('./package.json').dependencies || {}).length" 2>/dev/null || echo "0")
    DEV_DEP_COUNT=$(node -p "Object.keys(require('./package.json').devDependencies || {}).length" 2>/dev/null || echo "0")
    TOTAL_DEPS=$((DEP_COUNT + DEV_DEP_COUNT))
    
    echo "Production dependencies: $DEP_COUNT"
    echo "Dev dependencies: $DEV_DEP_COUNT"
    echo "Total: $TOTAL_DEPS"
    
    # node_modules size
    if [ -d "node_modules" ]; then
        NODE_MODULES_SIZE=$(du -sh node_modules 2>/dev/null | cut -f1)
        echo "node_modules size: $NODE_MODULES_SIZE"
    fi
    
    # Dependency impact
    if [ "$DEP_COUNT" -gt 50 ]; then
        echo -e "${YELLOW}⚠️  Many dependencies - increases bundle size and security risk${NC}"
    else
        echo -e "${GREEN}✅ Reasonable dependency count${NC}"
    fi
fi

# Git metrics
echo ""
echo "📝 Development Velocity"
echo "-----------------------"

if [ -d ".git" ]; then
    # Commits
    TOTAL_COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    COMMITS_LAST_WEEK=$(git log --since="1 week ago" --oneline | wc -l)
    COMMITS_LAST_MONTH=$(git log --since="1 month ago" --oneline | wc -l)
    
    echo "Total commits: $TOTAL_COMMITS"
    echo "Last week: $COMMITS_LAST_WEEK commits"
    echo "Last month: $COMMITS_LAST_MONTH commits"
    
    # Calculate velocity
    if [ "$COMMITS_LAST_WEEK" -gt 0 ]; then
        echo -e "${GREEN}✅ Active development${NC}"
    else
        echo -e "${YELLOW}⚠️  Low activity${NC}"
    fi
    
    # Contributors
    CONTRIBUTOR_COUNT=$(git shortlog -sn --all | wc -l)
    echo "Contributors: $CONTRIBUTOR_COUNT"
    
    # Files changed
    FILES_CHANGED_WEEK=$(git diff --name-only HEAD@{1.week.ago} HEAD 2>/dev/null | wc -l || echo "0")
    echo "Files changed (last week): $FILES_CHANGED_WEEK"
fi

# Quality metrics
echo ""
echo "✅ Quality Metrics"
echo "------------------"

# Test coverage
TEST_FILES=$(find . -name "*.test.js" -o -name "*.test.jsx" -o -name "*.spec.js" -o -name "*.spec.jsx" 2>/dev/null | wc -l)
echo "Test files: $TEST_FILES"

if [ "$COMPONENT_COUNT" -gt 0 ]; then
    TEST_COVERAGE=$((TEST_FILES * 100 / COMPONENT_COUNT))
    echo "Test coverage: ~${TEST_COVERAGE}%"
    
    if [ "$TEST_COVERAGE" -lt 50 ]; then
        echo -e "${RED}❌ Low test coverage - impacts quality${NC}"
    elif [ "$TEST_COVERAGE" -lt 80 ]; then
        echo -e "${YELLOW}⚠️  Moderate test coverage${NC}"
    else
        echo -e "${GREEN}✅ Good test coverage${NC}"
    fi
fi

# Documentation
DOC_FILES=$(find . -name "*.md" | wc -l)
echo "Documentation files: $DOC_FILES"

# Code quality indicators
CONSOLE_LOGS=$(grep -r "console\.log" src 2>/dev/null | wc -l || echo "0")
TODO_COUNT=$(grep -r "TODO\|FIXME" src 2>/dev/null | wc -l || echo "0")

echo "console.log statements: $CONSOLE_LOGS"
echo "TODO/FIXME comments: $TODO_COUNT"

if [ "$CONSOLE_LOGS" -gt 10 ]; then
    echo -e "${YELLOW}⚠️  Many debug statements - clean up before production${NC}"
fi

# Performance KPIs
echo ""
echo "⚡ Performance KPIs"
echo "-------------------"

if [ -d "dist" ]; then
    # Estimate load time (rough calculation)
    JS_SIZE_BYTES=$(find dist -name "*.js" -exec stat -f%z {} + 2>/dev/null | awk '{s+=$1} END {print s}' || echo "0")
    
    # Assume 3G connection (750 KB/s)
    if [ "$JS_SIZE_BYTES" -gt 0 ]; then
        LOAD_TIME_3G=$(echo "scale=2; $JS_SIZE_BYTES / 750000" | bc 2>/dev/null || echo "0")
        echo "Estimated load time (3G): ${LOAD_TIME_3G}s"
        
        # Check against targets
        if [ "${LOAD_TIME_3G%.*}" -gt 3 ]; then
            echo -e "${RED}❌ Slow load time - impacts user experience${NC}"
        elif [ "${LOAD_TIME_3G%.*}" -gt 2 ]; then
            echo -e "${YELLOW}⚠️  Moderate load time${NC}"
        else
            echo -e "${GREEN}✅ Fast load time${NC}"
        fi
    fi
    
    # Count images
    IMAGE_COUNT=$(find dist -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" -o -name "*.svg" -o -name "*.webp" \) | wc -l)
    echo "Images: $IMAGE_COUNT"
    
    if [ "$IMAGE_COUNT" -gt 0 ]; then
        IMAGE_SIZE=$(find dist -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" -o -name "*.webp" \) -exec du -ch {} + 2>/dev/null | tail -1 | cut -f1 || echo "0")
        echo "Total image size: $IMAGE_SIZE"
    fi
fi

# Business impact KPIs
echo ""
echo "💼 Business Impact"
echo "------------------"

# Calculate development cost (rough estimate)
if [ "$TOTAL_COMMITS" -gt 0 ]; then
    # Assume 2 hours per commit on average
    DEV_HOURS=$((TOTAL_COMMITS * 2))
    echo "Estimated development hours: $DEV_HOURS"
fi

# Maintenance burden
MAINTENANCE_SCORE=0
[ "$DEP_COUNT" -lt 30 ] && ((MAINTENANCE_SCORE++))
[ "$TODO_COUNT" -lt 10 ] && ((MAINTENANCE_SCORE++))
[ "$TEST_COVERAGE" -gt 70 ] 2>/dev/null && ((MAINTENANCE_SCORE++))
[ "$CONSOLE_LOGS" -lt 5 ] && ((MAINTENANCE_SCORE++))
[ "$DOC_FILES" -gt 3 ] && ((MAINTENANCE_SCORE++))

echo "Maintenance score: $MAINTENANCE_SCORE/5"

if [ "$MAINTENANCE_SCORE" -ge 4 ]; then
    echo -e "${GREEN}✅ Low maintenance burden${NC}"
elif [ "$MAINTENANCE_SCORE" -ge 2 ]; then
    echo -e "${YELLOW}⚠️  Moderate maintenance burden${NC}"
else
    echo -e "${RED}❌ High maintenance burden${NC}"
fi

# KPI Summary
echo ""
echo "======================"
echo -e "${CYAN}KPI Summary${NC}"
echo "======================"

# Calculate overall health score
HEALTH_SCORE=0
MAX_HEALTH=10

[ "$AVG_LINES" -lt 300 ] 2>/dev/null && ((HEALTH_SCORE++))
[ "$JS_SIZE_KB" -lt 500 ] 2>/dev/null && ((HEALTH_SCORE++))
[ "$DEP_COUNT" -lt 30 ] && ((HEALTH_SCORE++))
[ "$TEST_COVERAGE" -gt 50 ] 2>/dev/null && ((HEALTH_SCORE++))
[ "$COMMITS_LAST_WEEK" -gt 0 ] && ((HEALTH_SCORE++))
[ "$CONSOLE_LOGS" -lt 10 ] && ((HEALTH_SCORE++))
[ "$TODO_COUNT" -lt 20 ] && ((HEALTH_SCORE++))
[ "$DOC_FILES" -gt 2 ] && ((HEALTH_SCORE++))
[ -d "dist" ] && ((HEALTH_SCORE++))
[ -d ".git" ] && ((HEALTH_SCORE++))

HEALTH_PERCENTAGE=$((HEALTH_SCORE * 100 / MAX_HEALTH))

echo "Overall Health: $HEALTH_SCORE/$MAX_HEALTH ($HEALTH_PERCENTAGE%)"
echo ""

if [ "$HEALTH_PERCENTAGE" -ge 80 ]; then
    echo -e "${GREEN}✅ Excellent project health${NC}"
    echo "Impact: Positive - Low risk, high maintainability"
elif [ "$HEALTH_PERCENTAGE" -ge 60 ]; then
    echo -e "${YELLOW}⚠️  Good project health${NC}"
    echo "Impact: Neutral - Some areas need attention"
else
    echo -e "${RED}❌ Poor project health${NC}"
    echo "Impact: Negative - High risk, needs improvement"
fi

# Key recommendations
echo ""
echo "🎯 Key Recommendations"
echo "----------------------"

RECOMMENDATIONS=()

[ "$JS_SIZE_KB" -gt 500 ] 2>/dev/null && RECOMMENDATIONS+=("Reduce bundle size through code splitting")
[ "$DEP_COUNT" -gt 50 ] && RECOMMENDATIONS+=("Audit and reduce dependencies")
[ "$TEST_COVERAGE" -lt 70 ] 2>/dev/null && RECOMMENDATIONS+=("Increase test coverage")
[ "$CONSOLE_LOGS" -gt 10 ] && RECOMMENDATIONS+=("Remove debug statements")
[ "$TODO_COUNT" -gt 20 ] && RECOMMENDATIONS+=("Address TODO/FIXME comments")
[ "$AVG_LINES" -gt 300 ] 2>/dev/null && RECOMMENDATIONS+=("Split large files")
[ "$COMMITS_LAST_WEEK" -eq 0 ] && RECOMMENDATIONS+=("Increase development velocity")
[ "$DOC_FILES" -lt 3 ] && RECOMMENDATIONS+=("Improve documentation")

if [ ${#RECOMMENDATIONS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ No critical recommendations${NC}"
else
    for rec in "${RECOMMENDATIONS[@]}"; do
        echo "  • $rec"
    done
fi

echo ""
echo "Impact areas:"
echo "  • User Experience: Load time, bundle size"
echo "  • Developer Experience: Code quality, documentation"
echo "  • Business: Maintenance cost, development velocity"
echo "  • Security: Dependency count, vulnerabilities"
echo "  • Quality: Test coverage, code standards"
