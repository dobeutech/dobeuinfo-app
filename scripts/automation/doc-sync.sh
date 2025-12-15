#!/bin/bash
# doc-sync.sh - Synchronize documentation across the project
# Ensures README, architecture docs, and inline docs are consistent

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔄 Documentation Sync"
echo "===================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if docs directory exists
if [ ! -d "$PROJECT_ROOT/docs" ]; then
    echo -e "${YELLOW}⚠️  Creating docs directory${NC}"
    mkdir -p "$PROJECT_ROOT/docs"
fi

# Extract package.json info
PACKAGE_NAME=$(node -p "require('$PROJECT_ROOT/package.json').name" 2>/dev/null || echo "unknown")
PACKAGE_VERSION=$(node -p "require('$PROJECT_ROOT/package.json').version" 2>/dev/null || echo "0.0.0")
PACKAGE_DESC=$(node -p "require('$PROJECT_ROOT/package.json').description || ''" 2>/dev/null || echo "")

echo "📦 Project: $PACKAGE_NAME v$PACKAGE_VERSION"

# Sync version to docs
if [ -f "$PROJECT_ROOT/docs/architecture.md" ]; then
    echo "✅ Architecture documentation found"
else
    echo -e "${YELLOW}⚠️  Architecture documentation missing${NC}"
fi

# Check for component documentation
echo ""
echo "📝 Checking component documentation..."
COMPONENTS_DIR="$PROJECT_ROOT/src/components"
if [ -d "$COMPONENTS_DIR" ]; then
    COMPONENT_COUNT=$(find "$COMPONENTS_DIR" -name "*.jsx" -o -name "*.tsx" | wc -l)
    echo "   Found $COMPONENT_COUNT components"
    
    # List components without JSDoc
    echo "   Checking for JSDoc comments..."
    UNDOCUMENTED=0
    for file in "$COMPONENTS_DIR"/*.{jsx,tsx} 2>/dev/null; do
        [ -f "$file" ] || continue
        if ! grep -q "^/\*\*" "$file"; then
            echo -e "   ${YELLOW}⚠️  $(basename "$file") - Missing JSDoc${NC}"
            ((UNDOCUMENTED++))
        fi
    done
    
    if [ $UNDOCUMENTED -eq 0 ]; then
        echo -e "   ${GREEN}✅ All components documented${NC}"
    else
        echo -e "   ${YELLOW}⚠️  $UNDOCUMENTED components need documentation${NC}"
    fi
fi

# Check for README
echo ""
echo "📖 Checking README..."
if [ -f "$PROJECT_ROOT/README.md" ]; then
    README_LINES=$(wc -l < "$PROJECT_ROOT/README.md")
    echo -e "   ${GREEN}✅ README.md exists ($README_LINES lines)${NC}"
    
    # Check for key sections
    SECTIONS=("Installation" "Usage" "Development" "Contributing")
    for section in "${SECTIONS[@]}"; do
        if grep -qi "## $section" "$PROJECT_ROOT/README.md"; then
            echo "   ✅ Section: $section"
        else
            echo -e "   ${YELLOW}⚠️  Missing section: $section${NC}"
        fi
    done
else
    echo -e "   ${RED}❌ README.md not found${NC}"
fi

# Generate component index
echo ""
echo "📋 Generating component index..."
COMPONENT_INDEX="$PROJECT_ROOT/docs/components.md"
cat > "$COMPONENT_INDEX" << EOF
# Component Index

Generated: $(date +"%Y-%m-%d %H:%M:%S")

## Components

EOF

if [ -d "$COMPONENTS_DIR" ]; then
    for file in "$COMPONENTS_DIR"/*.{jsx,tsx} 2>/dev/null; do
        [ -f "$file" ] || continue
        COMPONENT_NAME=$(basename "$file" | sed 's/\.[^.]*$//')
        
        # Extract first JSDoc comment if exists
        DESCRIPTION=$(awk '/^\/\*\*/,/\*\// {if (!/^\/\*\*/ && !/\*\//) print}' "$file" | head -1 | sed 's/^ \* //' | sed 's/^[[:space:]]*//')
        
        if [ -z "$DESCRIPTION" ]; then
            DESCRIPTION="No description available"
        fi
        
        echo "### $COMPONENT_NAME" >> "$COMPONENT_INDEX"
        echo "" >> "$COMPONENT_INDEX"
        echo "$DESCRIPTION" >> "$COMPONENT_INDEX"
        echo "" >> "$COMPONENT_INDEX"
        echo "**File:** \`src/components/$COMPONENT_NAME.jsx\`" >> "$COMPONENT_INDEX"
        echo "" >> "$COMPONENT_INDEX"
    done
fi

echo -e "${GREEN}✅ Component index generated: docs/components.md${NC}"

# Check for API documentation
echo ""
echo "🔌 Checking API documentation..."
if [ -f "$PROJECT_ROOT/src/services/api.js" ]; then
    echo -e "   ${GREEN}✅ API service found${NC}"
    
    # Count API functions
    API_FUNCTIONS=$(grep -c "^export.*function\|^export const.*=" "$PROJECT_ROOT/src/services/api.js" 2>/dev/null || echo "0")
    echo "   Found $API_FUNCTIONS exported functions"
else
    echo -e "   ${YELLOW}⚠️  No API service found${NC}"
fi

# Summary
echo ""
echo "===================="
echo -e "${GREEN}✅ Documentation sync complete${NC}"
echo ""
echo "Next steps:"
echo "  1. Review docs/components.md"
echo "  2. Add missing JSDoc comments"
echo "  3. Update README sections as needed"
echo "  4. Keep architecture.md up to date"
