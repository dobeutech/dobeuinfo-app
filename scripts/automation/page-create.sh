#!/bin/bash
# page-create.sh - Page component generator
# Creates new page components with boilerplate code

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

echo -e "${CYAN}📄 Page Component Generator${NC}"
echo "==========================="
echo ""

# Get page name
if [ -n "$1" ]; then
    PAGE_NAME="$1"
else
    read -p "Enter page name (e.g., About, Contact, Dashboard): " PAGE_NAME
fi

if [ -z "$PAGE_NAME" ]; then
    echo -e "${RED}❌ Page name is required${NC}"
    exit 1
fi

# Convert to PascalCase
PAGE_NAME_PASCAL=$(echo "$PAGE_NAME" | sed 's/\b\(.\)/\u\1/g' | sed 's/ //g')
PAGE_NAME_LOWER=$(echo "$PAGE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

echo "Creating page: $PAGE_NAME_PASCAL"
echo "Route: /$PAGE_NAME_LOWER"
echo ""

# Check if pages directory exists
PAGES_DIR="$PROJECT_ROOT/src/pages"
if [ ! -d "$PAGES_DIR" ]; then
    echo -e "${YELLOW}⚠️  Creating pages directory${NC}"
    mkdir -p "$PAGES_DIR"
fi

# Check if page already exists
PAGE_FILE="$PAGES_DIR/${PAGE_NAME_PASCAL}Page.jsx"
if [ -f "$PAGE_FILE" ]; then
    echo -e "${RED}❌ Page already exists: $PAGE_FILE${NC}"
    read -p "Overwrite? (y/n): " OVERWRITE
    if [ "$OVERWRITE" != "y" ]; then
        exit 1
    fi
fi

# Get page description
read -p "Enter page description (optional): " PAGE_DESC
if [ -z "$PAGE_DESC" ]; then
    PAGE_DESC="$PAGE_NAME_PASCAL page component"
fi

# Get page title
read -p "Enter page title (default: $PAGE_NAME): " PAGE_TITLE
if [ -z "$PAGE_TITLE" ]; then
    PAGE_TITLE="$PAGE_NAME"
fi

# Create page component
echo ""
echo "Creating page component..."

cat > "$PAGE_FILE" << EOF
/**
 * ${PAGE_NAME_PASCAL}Page
 * $PAGE_DESC
 */

import { SEO } from '../components/SEO';
import { Layout } from '../components/Layout';

export function ${PAGE_NAME_PASCAL}Page() {
  return (
    <Layout>
      <SEO
        title="$PAGE_TITLE"
        description="$PAGE_DESC"
        path="/$PAGE_NAME_LOWER"
      />
      
      <div className="container">
        <h1>$PAGE_TITLE</h1>
        
        <section className="content">
          <p>Welcome to the $PAGE_NAME page.</p>
          {/* Add your content here */}
        </section>
      </div>
    </Layout>
  );
}
EOF

echo -e "${GREEN}✅ Created: $PAGE_FILE${NC}"

# Create corresponding CSS file
CSS_FILE="$PROJECT_ROOT/src/styles/${PAGE_NAME_PASCAL}Page.css"
read -p "Create CSS file? (y/n): " CREATE_CSS

if [ "$CREATE_CSS" = "y" ]; then
    if [ ! -d "$PROJECT_ROOT/src/styles" ]; then
        mkdir -p "$PROJECT_ROOT/src/styles"
    fi
    
    cat > "$CSS_FILE" << EOF
/* ${PAGE_NAME_PASCAL}Page Styles */

.${PAGE_NAME_LOWER}-page {
  padding: 2rem 0;
}

.${PAGE_NAME_LOWER}-page .container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
}

.${PAGE_NAME_LOWER}-page h1 {
  font-size: 2.5rem;
  margin-bottom: 1.5rem;
  color: #333;
}

.${PAGE_NAME_LOWER}-page .content {
  margin-top: 2rem;
}

/* Responsive */
@media (max-width: 768px) {
  .${PAGE_NAME_LOWER}-page h1 {
    font-size: 2rem;
  }
}
EOF
    
    echo -e "${GREEN}✅ Created: $CSS_FILE${NC}"
    
    # Update page component to import CSS
    sed -i '' "1i\\
import './../styles/${PAGE_NAME_PASCAL}Page.css';\\
" "$PAGE_FILE" 2>/dev/null || sed -i "1i import './../styles/${PAGE_NAME_PASCAL}Page.css';" "$PAGE_FILE"
fi

# Update App.jsx to add route
echo ""
read -p "Add route to App.jsx? (y/n): " ADD_ROUTE

if [ "$ADD_ROUTE" = "y" ]; then
    APP_FILE="$PROJECT_ROOT/src/App.jsx"
    
    if [ -f "$APP_FILE" ]; then
        # Check if route already exists
        if grep -q "${PAGE_NAME_PASCAL}Page" "$APP_FILE"; then
            echo -e "${YELLOW}⚠️  Route may already exist in App.jsx${NC}"
        else
            echo ""
            echo "Add this route to your App.jsx:"
            echo ""
            echo -e "${BLUE}Import:${NC}"
            echo "import { ${PAGE_NAME_PASCAL}Page } from './pages/${PAGE_NAME_PASCAL}Page';"
            echo ""
            echo -e "${BLUE}Route:${NC}"
            echo "<Route path=\"/$PAGE_NAME_LOWER\" element={<${PAGE_NAME_PASCAL}Page />} />"
            echo ""
            echo -e "${YELLOW}Note: Manual update required${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  App.jsx not found${NC}"
    fi
fi

# Create test file
echo ""
read -p "Create test file? (y/n): " CREATE_TEST

if [ "$CREATE_TEST" = "y" ]; then
    TEST_DIR="$PROJECT_ROOT/src/pages/__tests__"
    mkdir -p "$TEST_DIR"
    
    TEST_FILE="$TEST_DIR/${PAGE_NAME_PASCAL}Page.test.jsx"
    
    cat > "$TEST_FILE" << EOF
/**
 * ${PAGE_NAME_PASCAL}Page Tests
 */

import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { ${PAGE_NAME_PASCAL}Page } from '../${PAGE_NAME_PASCAL}Page';

describe('${PAGE_NAME_PASCAL}Page', () => {
  it('renders page title', () => {
    render(
      <BrowserRouter>
        <${PAGE_NAME_PASCAL}Page />
      </BrowserRouter>
    );
    
    expect(screen.getByText('$PAGE_TITLE')).toBeInTheDocument();
  });
  
  it('renders page content', () => {
    render(
      <BrowserRouter>
        <${PAGE_NAME_PASCAL}Page />
      </BrowserRouter>
    );
    
    expect(screen.getByText(/Welcome to the $PAGE_NAME page/i)).toBeInTheDocument();
  });
});
EOF
    
    echo -e "${GREEN}✅ Created: $TEST_FILE${NC}"
fi

# Summary
echo ""
echo "==========================="
echo -e "${GREEN}✅ Page created successfully!${NC}"
echo ""
echo "Files created:"
echo "  • $PAGE_FILE"
[ "$CREATE_CSS" = "y" ] && echo "  • $CSS_FILE"
[ "$CREATE_TEST" = "y" ] && echo "  • $TEST_FILE"
echo ""
echo "Next steps:"
echo "  1. Add route to App.jsx:"
echo "     import { ${PAGE_NAME_PASCAL}Page } from './pages/${PAGE_NAME_PASCAL}Page';"
echo "     <Route path=\"/$PAGE_NAME_LOWER\" element={<${PAGE_NAME_PASCAL}Page />} />"
echo "  2. Customize the page content"
echo "  3. Add styles as needed"
echo "  4. Test the page: npm run dev"
echo ""
echo "View at: http://localhost:5173/$PAGE_NAME_LOWER"
