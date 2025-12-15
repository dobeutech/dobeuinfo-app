#!/bin/bash
# test-component.sh - Component testing helper
# Runs tests for specific components or all components

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

echo -e "${CYAN}🧪 Component Testing${NC}"
echo "===================="
echo ""

cd "$PROJECT_ROOT"

# Check if test framework is installed
if ! grep -q "vitest\|jest" package.json 2>/dev/null; then
    echo -e "${YELLOW}⚠️  No test framework detected${NC}"
    echo ""
    read -p "Install Vitest? (y/n): " INSTALL_VITEST
    
    if [ "$INSTALL_VITEST" = "y" ]; then
        echo "Installing Vitest and testing libraries..."
        npm install -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom
        
        # Add test script to package.json
        echo ""
        echo "Add this to your package.json scripts:"
        echo '  "test": "vitest",'
        echo '  "test:ui": "vitest --ui",'
        echo '  "test:coverage": "vitest --coverage"'
        echo ""
    else
        echo "Exiting..."
        exit 0
    fi
fi

# Get component name if provided
COMPONENT_NAME="$1"

if [ -z "$COMPONENT_NAME" ]; then
    echo "Available options:"
    echo "  1. Test all components"
    echo "  2. Test specific component"
    echo "  3. Run tests in watch mode"
    echo "  4. Generate coverage report"
    echo "  5. List test files"
    echo ""
    read -p "Select option (1-5): " OPTION
    
    case $OPTION in
        1)
            echo ""
            echo "Running all tests..."
            npm test
            ;;
        2)
            echo ""
            read -p "Enter component name: " COMPONENT_NAME
            if [ -n "$COMPONENT_NAME" ]; then
                echo "Testing $COMPONENT_NAME..."
                npm test -- "$COMPONENT_NAME"
            fi
            ;;
        3)
            echo ""
            echo "Running tests in watch mode..."
            npm test -- --watch
            ;;
        4)
            echo ""
            echo "Generating coverage report..."
            npm run test:coverage 2>/dev/null || npm test -- --coverage
            ;;
        5)
            echo ""
            echo "Test files:"
            find src -name "*.test.js" -o -name "*.test.jsx" -o -name "*.spec.js" -o -name "*.spec.jsx" | while read -r file; do
                echo "  • $file"
            done
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            exit 1
            ;;
    esac
else
    # Test specific component
    echo "Testing component: $COMPONENT_NAME"
    echo ""
    
    # Find test file
    TEST_FILE=$(find src -name "${COMPONENT_NAME}.test.jsx" -o -name "${COMPONENT_NAME}.test.js" | head -1)
    
    if [ -z "$TEST_FILE" ]; then
        echo -e "${YELLOW}⚠️  No test file found for $COMPONENT_NAME${NC}"
        echo ""
        read -p "Create test file? (y/n): " CREATE_TEST
        
        if [ "$CREATE_TEST" = "y" ]; then
            # Find component file
            COMPONENT_FILE=$(find src/components -name "${COMPONENT_NAME}.jsx" -o -name "${COMPONENT_NAME}.js" | head -1)
            
            if [ -z "$COMPONENT_FILE" ]; then
                echo -e "${RED}❌ Component file not found${NC}"
                exit 1
            fi
            
            # Create test directory
            COMPONENT_DIR=$(dirname "$COMPONENT_FILE")
            TEST_DIR="$COMPONENT_DIR/__tests__"
            mkdir -p "$TEST_DIR"
            
            TEST_FILE="$TEST_DIR/${COMPONENT_NAME}.test.jsx"
            
            # Generate test file
            cat > "$TEST_FILE" << EOF
/**
 * $COMPONENT_NAME Tests
 */

import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { $COMPONENT_NAME } from '../$COMPONENT_NAME';

describe('$COMPONENT_NAME', () => {
  it('renders without crashing', () => {
    render(<$COMPONENT_NAME />);
  });
  
  it('renders expected content', () => {
    render(<$COMPONENT_NAME />);
    // Add your assertions here
    // expect(screen.getByText('...')).toBeInTheDocument();
  });
  
  // Add more tests as needed
});
EOF
            
            echo -e "${GREEN}✅ Created test file: $TEST_FILE${NC}"
            echo ""
            echo "Edit the test file and add your test cases"
            echo "Then run: npm test $COMPONENT_NAME"
        fi
    else
        echo "Found test file: $TEST_FILE"
        echo ""
        npm test -- "$COMPONENT_NAME"
    fi
fi

# Test statistics
echo ""
echo "===================="
echo -e "${CYAN}Test Statistics${NC}"
echo "===================="

# Count test files
TEST_COUNT=$(find src -name "*.test.js" -o -name "*.test.jsx" -o -name "*.spec.js" -o -name "*.spec.jsx" | wc -l)
echo "Test files: $TEST_COUNT"

# Count components
COMPONENT_COUNT=$(find src/components -name "*.jsx" -o -name "*.js" | grep -v test | wc -l)
echo "Components: $COMPONENT_COUNT"

# Calculate coverage
if [ "$COMPONENT_COUNT" -gt 0 ]; then
    COVERAGE=$((TEST_COUNT * 100 / COMPONENT_COUNT))
    echo "Test coverage: ~${COVERAGE}%"
fi

# List untested components
echo ""
echo "Components without tests:"
UNTESTED=0
for component in src/components/*.jsx src/components/*.js; do
    [ -f "$component" ] || continue
    BASENAME=$(basename "$component" .jsx)
    BASENAME=$(basename "$BASENAME" .js)
    
    if ! find src -name "${BASENAME}.test.*" | grep -q .; then
        echo "  • $BASENAME"
        ((UNTESTED++))
    fi
done

if [ $UNTESTED -eq 0 ]; then
    echo -e "  ${GREEN}✅ All components have tests${NC}"
fi

echo ""
echo "===================="
echo "Testing commands:"
echo "  npm test                    - Run all tests"
echo "  npm test -- ComponentName   - Test specific component"
echo "  npm test -- --watch         - Watch mode"
echo "  npm test -- --coverage      - Coverage report"
echo "  npm test -- --ui            - UI mode (if installed)"
echo ""
echo "Create test:"
echo "  $0 ComponentName"
