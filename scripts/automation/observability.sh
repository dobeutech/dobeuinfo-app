#!/bin/bash
# observability.sh - Application observability and monitoring
# Checks application health, performance, and provides monitoring insights

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

echo -e "${CYAN}📊 Application Observability${NC}"
echo "============================="
echo ""

cd "$PROJECT_ROOT"

# Check if app is running
echo "🔍 Application Status"
echo "---------------------"

# Check common dev ports
PORTS=(3000 5173 8080 4173)
APP_RUNNING=false
APP_PORT=""

for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Application running on port $port${NC}"
        APP_RUNNING=true
        APP_PORT=$port
        break
    fi
done

if [ "$APP_RUNNING" = false ]; then
    echo -e "${YELLOW}⚠️  Application not running${NC}"
    echo "Start with: npm run dev"
    echo ""
fi

# Build information
echo ""
echo "📦 Build Information"
echo "--------------------"

if [ -d "dist" ]; then
    DIST_SIZE=$(du -sh dist 2>/dev/null | cut -f1)
    FILE_COUNT=$(find dist -type f | wc -l)
    echo -e "${GREEN}✅ Production build exists${NC}"
    echo "   Size: $DIST_SIZE"
    echo "   Files: $FILE_COUNT"
    
    # Check build age
    if [ -f "dist/index.html" ]; then
        BUILD_AGE=$(find dist/index.html -mtime +7 2>/dev/null | wc -l)
        if [ "$BUILD_AGE" -gt 0 ]; then
            echo -e "   ${YELLOW}⚠️  Build is older than 7 days${NC}"
            echo "   Consider rebuilding: npm run build"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  No production build found${NC}"
    echo "Build with: npm run build"
fi

# Performance metrics
echo ""
echo "⚡ Performance Metrics"
echo "---------------------"

if [ -d "dist" ]; then
    # Check bundle sizes
    echo "Bundle sizes:"
    
    JS_FILES=$(find dist -name "*.js" -type f)
    if [ -n "$JS_FILES" ]; then
        TOTAL_JS_SIZE=0
        while IFS= read -r file; do
            SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
            TOTAL_JS_SIZE=$((TOTAL_JS_SIZE + SIZE))
            SIZE_KB=$((SIZE / 1024))
            if [ $SIZE_KB -gt 500 ]; then
                echo -e "   ${YELLOW}⚠️  $(basename "$file"): ${SIZE_KB}KB (large)${NC}"
            else
                echo -e "   ${GREEN}✅ $(basename "$file"): ${SIZE_KB}KB${NC}"
            fi
        done <<< "$JS_FILES"
        
        TOTAL_JS_KB=$((TOTAL_JS_SIZE / 1024))
        echo "   Total JS: ${TOTAL_JS_KB}KB"
        
        if [ $TOTAL_JS_KB -gt 1000 ]; then
            echo -e "   ${YELLOW}⚠️  Large bundle size - consider code splitting${NC}"
        fi
    fi
    
    # Check CSS sizes
    CSS_FILES=$(find dist -name "*.css" -type f)
    if [ -n "$CSS_FILES" ]; then
        TOTAL_CSS_SIZE=0
        while IFS= read -r file; do
            SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
            TOTAL_CSS_SIZE=$((TOTAL_CSS_SIZE + SIZE))
        done <<< "$CSS_FILES"
        
        TOTAL_CSS_KB=$((TOTAL_CSS_SIZE / 1024))
        echo "   Total CSS: ${TOTAL_CSS_KB}KB"
    fi
else
    echo "Build the app first: npm run build"
fi

# Source code metrics
echo ""
echo "📊 Source Code Metrics"
echo "----------------------"

if [ -d "src" ]; then
    # Count lines of code
    JS_LINES=$(find src -name "*.js" -o -name "*.jsx" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    TS_LINES=$(find src -name "*.ts" -o -name "*.tsx" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    CSS_LINES=$(find src -name "*.css" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    
    TOTAL_LINES=$((JS_LINES + TS_LINES + CSS_LINES))
    
    echo "Lines of code:"
    [ "$JS_LINES" -gt 0 ] && echo "   JavaScript/JSX: $JS_LINES"
    [ "$TS_LINES" -gt 0 ] && echo "   TypeScript/TSX: $TS_LINES"
    [ "$CSS_LINES" -gt 0 ] && echo "   CSS: $CSS_LINES"
    echo "   Total: $TOTAL_LINES"
    
    # Component count
    COMPONENT_COUNT=$(find src/components -name "*.jsx" -o -name "*.tsx" 2>/dev/null | wc -l)
    PAGE_COUNT=$(find src/pages -name "*.jsx" -o -name "*.tsx" 2>/dev/null | wc -l)
    
    echo ""
    echo "Components: $COMPONENT_COUNT"
    echo "Pages: $PAGE_COUNT"
fi

# Dependency health
echo ""
echo "📦 Dependency Health"
echo "--------------------"

if [ -f "package.json" ]; then
    DEP_COUNT=$(node -p "Object.keys(require('./package.json').dependencies || {}).length" 2>/dev/null || echo "0")
    DEV_DEP_COUNT=$(node -p "Object.keys(require('./package.json').devDependencies || {}).length" 2>/dev/null || echo "0")
    
    echo "Dependencies: $DEP_COUNT"
    echo "Dev Dependencies: $DEV_DEP_COUNT"
    
    # Check for vulnerabilities
    if npm audit --json > /tmp/audit-check.json 2>&1; then
        echo -e "${GREEN}✅ No known vulnerabilities${NC}"
    else
        VULN_COUNT=$(node -p "
            try {
                const audit = require('/tmp/audit-check.json');
                const meta = audit.metadata || {};
                const vulns = meta.vulnerabilities || {};
                (vulns.moderate || 0) + (vulns.high || 0) + (vulns.critical || 0);
            } catch(e) {
                0;
            }
        " 2>/dev/null || echo "0")
        
        if [ "$VULN_COUNT" -gt 0 ]; then
            echo -e "${RED}❌ $VULN_COUNT vulnerabilities found${NC}"
            echo "   Run: npm audit"
        fi
    fi
    rm -f /tmp/audit-check.json
fi

# Error tracking
echo ""
echo "🐛 Error Tracking"
echo "-----------------"

# Check for console.log statements
CONSOLE_LOGS=$(grep -r "console\.log" src 2>/dev/null | wc -l || echo "0")
CONSOLE_ERRORS=$(grep -r "console\.error" src 2>/dev/null | wc -l || echo "0")
CONSOLE_WARNS=$(grep -r "console\.warn" src 2>/dev/null | wc -l || echo "0")

echo "Console statements:"
echo "   console.log: $CONSOLE_LOGS"
echo "   console.error: $CONSOLE_ERRORS"
echo "   console.warn: $CONSOLE_WARNS"

if [ "$CONSOLE_LOGS" -gt 10 ]; then
    echo -e "   ${YELLOW}⚠️  Many console.log statements - consider removing for production${NC}"
fi

# Check for error boundaries
ERROR_BOUNDARY=$(find src -name "*ErrorBoundary*" | wc -l)
if [ "$ERROR_BOUNDARY" -gt 0 ]; then
    echo -e "${GREEN}✅ Error boundary implemented${NC}"
else
    echo -e "${YELLOW}⚠️  No error boundary found${NC}"
    echo "   Consider implementing error boundaries"
fi

# Monitoring recommendations
echo ""
echo "📈 Monitoring Recommendations"
echo "-----------------------------"

echo "Consider implementing:"
echo ""
echo "1. Performance Monitoring:"
echo "   • Web Vitals (Core Web Vitals)"
echo "   • Bundle size monitoring"
echo "   • Load time tracking"
echo ""
echo "2. Error Tracking:"
echo "   • Sentry, Rollbar, or similar"
echo "   • Error boundaries"
echo "   • Unhandled promise rejection tracking"
echo ""
echo "3. Analytics:"
echo "   • Google Analytics, Plausible, or similar"
echo "   • User behavior tracking"
echo "   • Conversion tracking"
echo ""
echo "4. Logging:"
echo "   • Structured logging"
echo "   • Log levels (debug, info, warn, error)"
echo "   • Log aggregation service"
echo ""
echo "5. Uptime Monitoring:"
echo "   • Pingdom, UptimeRobot, or similar"
echo "   • Health check endpoints"
echo "   • Status page"

# Health check endpoint suggestion
echo ""
echo "💡 Health Check Endpoint"
echo "------------------------"

if [ -d "src/pages" ]; then
    if [ ! -f "src/pages/HealthPage.jsx" ]; then
        echo -e "${YELLOW}⚠️  No health check endpoint found${NC}"
        echo ""
        read -p "Create health check endpoint? (y/n): " CREATE_HEALTH
        
        if [ "$CREATE_HEALTH" = "y" ]; then
            cat > "src/pages/HealthPage.jsx" << 'EOF'
/**
 * HealthPage - Health check endpoint
 * Returns application health status
 */

export function HealthPage() {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: import.meta.env.VITE_APP_VERSION || '0.0.0',
    uptime: performance.now(),
  };

  return (
    <div style={{ fontFamily: 'monospace', padding: '2rem' }}>
      <h1>Health Check</h1>
      <pre>{JSON.stringify(health, null, 2)}</pre>
    </div>
  );
}
EOF
            echo -e "${GREEN}✅ Created health check endpoint${NC}"
            echo "Add route: <Route path=\"/health\" element={<HealthPage />} />"
        fi
    else
        echo -e "${GREEN}✅ Health check endpoint exists${NC}"
    fi
fi

# Summary
echo ""
echo "============================="
echo -e "${CYAN}Observability Summary${NC}"
echo "============================="

SCORE=0
MAX_SCORE=10

[ "$APP_RUNNING" = true ] && ((SCORE++))
[ -d "dist" ] && ((SCORE++))
[ "$TOTAL_JS_KB" -lt 1000 ] 2>/dev/null && ((SCORE++))
[ "$CONSOLE_LOGS" -lt 10 ] && ((SCORE++))
[ "$ERROR_BOUNDARY" -gt 0 ] && ((SCORE++))
[ "$VULN_COUNT" -eq 0 ] 2>/dev/null && ((SCORE++))
[ "$COMPONENT_COUNT" -gt 0 ] 2>/dev/null && ((SCORE++))
[ "$PAGE_COUNT" -gt 0 ] 2>/dev/null && ((SCORE++))
[ -f ".gitignore" ] && ((SCORE++))
[ -f "README.md" ] && ((SCORE++))

PERCENTAGE=$((SCORE * 100 / MAX_SCORE))

echo "Observability Score: $SCORE/$MAX_SCORE ($PERCENTAGE%)"
echo ""

if [ $PERCENTAGE -ge 80 ]; then
    echo -e "${GREEN}✅ Good observability setup${NC}"
elif [ $PERCENTAGE -ge 60 ]; then
    echo -e "${YELLOW}⚠️  Moderate observability - room for improvement${NC}"
else
    echo -e "${RED}❌ Poor observability - needs attention${NC}"
fi

echo ""
echo "Next steps:"
echo "  1. Implement monitoring tools"
echo "  2. Set up error tracking"
echo "  3. Add performance monitoring"
echo "  4. Create health check endpoints"
echo "  5. Set up logging infrastructure"
