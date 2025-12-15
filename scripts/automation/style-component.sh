#!/bin/bash
# style-component.sh - Component styling helper
# Creates and manages component styles

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

echo -e "${CYAN}🎨 Component Styling Helper${NC}"
echo "============================"
echo ""

cd "$PROJECT_ROOT"

# Menu
echo "Select option:"
echo "  1) Create CSS file for component"
echo "  2) Create CSS Module for component"
echo "  3) Analyze component styles"
echo "  4) Generate style guide"
echo "  5) Check style consistency"
echo "  0) Exit"
echo ""
read -p "Select option (0-5): " OPTION

case $OPTION in
    1)
        # Create CSS file
        echo ""
        read -p "Enter component name: " COMPONENT_NAME
        
        if [ -z "$COMPONENT_NAME" ]; then
            echo -e "${RED}❌ Component name required${NC}"
            exit 1
        fi
        
        # Convert to PascalCase
        COMPONENT_NAME_PASCAL=$(echo "$COMPONENT_NAME" | sed 's/\b\(.\)/\u\1/g' | sed 's/ //g')
        COMPONENT_NAME_LOWER=$(echo "$COMPONENT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
        
        # Check if component exists
        COMPONENT_FILE=$(find src/components -name "${COMPONENT_NAME_PASCAL}.jsx" -o -name "${COMPONENT_NAME_PASCAL}.tsx" | head -1)
        
        if [ -z "$COMPONENT_FILE" ]; then
            echo -e "${YELLOW}⚠️  Component file not found${NC}"
            read -p "Create anyway? (y/n): " CREATE_ANYWAY
            if [ "$CREATE_ANYWAY" != "y" ]; then
                exit 1
            fi
        fi
        
        # Create styles directory if needed
        STYLES_DIR="$PROJECT_ROOT/src/styles"
        mkdir -p "$STYLES_DIR"
        
        CSS_FILE="$STYLES_DIR/${COMPONENT_NAME_PASCAL}.css"
        
        if [ -f "$CSS_FILE" ]; then
            echo -e "${YELLOW}⚠️  CSS file already exists${NC}"
            read -p "Overwrite? (y/n): " OVERWRITE
            if [ "$OVERWRITE" != "y" ]; then
                exit 1
            fi
        fi
        
        # Create CSS file
        cat > "$CSS_FILE" << EOF
/* ${COMPONENT_NAME_PASCAL} Component Styles */

.${COMPONENT_NAME_LOWER} {
  /* Container styles */
  display: block;
  padding: 1rem;
}

.${COMPONENT_NAME_LOWER}__header {
  /* Header styles */
  margin-bottom: 1rem;
}

.${COMPONENT_NAME_LOWER}__title {
  /* Title styles */
  font-size: 1.5rem;
  font-weight: 600;
  color: #333;
}

.${COMPONENT_NAME_LOWER}__content {
  /* Content styles */
  line-height: 1.6;
}

.${COMPONENT_NAME_LOWER}__footer {
  /* Footer styles */
  margin-top: 1rem;
}

/* States */
.${COMPONENT_NAME_LOWER}--active {
  /* Active state */
}

.${COMPONENT_NAME_LOWER}--disabled {
  /* Disabled state */
  opacity: 0.5;
  pointer-events: none;
}

/* Responsive */
@media (max-width: 768px) {
  .${COMPONENT_NAME_LOWER} {
    padding: 0.5rem;
  }
  
  .${COMPONENT_NAME_LOWER}__title {
    font-size: 1.25rem;
  }
}

@media (max-width: 480px) {
  .${COMPONENT_NAME_LOWER}__title {
    font-size: 1rem;
  }
}
EOF
        
        echo -e "${GREEN}✅ Created: $CSS_FILE${NC}"
        echo ""
        echo "Import in component:"
        echo "  import '../styles/${COMPONENT_NAME_PASCAL}.css';"
        echo ""
        echo "Use BEM naming convention:"
        echo "  <div className=\"${COMPONENT_NAME_LOWER}\">"
        echo "    <div className=\"${COMPONENT_NAME_LOWER}__header\">"
        echo "      <h2 className=\"${COMPONENT_NAME_LOWER}__title\">Title</h2>"
        echo "    </div>"
        echo "  </div>"
        ;;
        
    2)
        # Create CSS Module
        echo ""
        read -p "Enter component name: " COMPONENT_NAME
        
        if [ -z "$COMPONENT_NAME" ]; then
            echo -e "${RED}❌ Component name required${NC}"
            exit 1
        fi
        
        COMPONENT_NAME_PASCAL=$(echo "$COMPONENT_NAME" | sed 's/\b\(.\)/\u\1/g' | sed 's/ //g')
        
        # Find component directory
        COMPONENT_FILE=$(find src/components -name "${COMPONENT_NAME_PASCAL}.jsx" -o -name "${COMPONENT_NAME_PASCAL}.tsx" | head -1)
        
        if [ -z "$COMPONENT_FILE" ]; then
            echo -e "${YELLOW}⚠️  Component file not found${NC}"
            COMPONENT_DIR="$PROJECT_ROOT/src/components"
        else
            COMPONENT_DIR=$(dirname "$COMPONENT_FILE")
        fi
        
        MODULE_FILE="$COMPONENT_DIR/${COMPONENT_NAME_PASCAL}.module.css"
        
        if [ -f "$MODULE_FILE" ]; then
            echo -e "${YELLOW}⚠️  CSS Module already exists${NC}"
            read -p "Overwrite? (y/n): " OVERWRITE
            if [ "$OVERWRITE" != "y" ]; then
                exit 1
            fi
        fi
        
        # Create CSS Module
        cat > "$MODULE_FILE" << EOF
/* ${COMPONENT_NAME_PASCAL} Component Styles (CSS Module) */

.container {
  display: block;
  padding: 1rem;
}

.header {
  margin-bottom: 1rem;
}

.title {
  font-size: 1.5rem;
  font-weight: 600;
  color: #333;
}

.content {
  line-height: 1.6;
}

.footer {
  margin-top: 1rem;
}

/* States */
.active {
  /* Active state */
}

.disabled {
  opacity: 0.5;
  pointer-events: none;
}

/* Responsive */
@media (max-width: 768px) {
  .container {
    padding: 0.5rem;
  }
  
  .title {
    font-size: 1.25rem;
  }
}
EOF
        
        echo -e "${GREEN}✅ Created: $MODULE_FILE${NC}"
        echo ""
        echo "Import in component:"
        echo "  import styles from './${COMPONENT_NAME_PASCAL}.module.css';"
        echo ""
        echo "Usage:"
        echo "  <div className={styles.container}>"
        echo "    <div className={styles.header}>"
        echo "      <h2 className={styles.title}>Title</h2>"
        echo "    </div>"
        echo "  </div>"
        ;;
        
    3)
        # Analyze component styles
        echo ""
        echo "Analyzing component styles..."
        echo ""
        
        # Count CSS files
        CSS_COUNT=$(find src -name "*.css" | wc -l)
        MODULE_COUNT=$(find src -name "*.module.css" | wc -l)
        
        echo "CSS files: $CSS_COUNT"
        echo "CSS Modules: $MODULE_COUNT"
        echo ""
        
        # Check for unused styles
        echo "Checking for unused CSS files..."
        UNUSED=()
        
        for css_file in src/styles/*.css; do
            [ -f "$css_file" ] || continue
            BASENAME=$(basename "$css_file")
            
            if ! grep -r "import.*$BASENAME" src/ &>/dev/null; then
                UNUSED+=("$BASENAME")
            fi
        done
        
        if [ ${#UNUSED[@]} -gt 0 ]; then
            echo -e "${YELLOW}⚠️  Potentially unused CSS files:${NC}"
            for file in "${UNUSED[@]}"; do
                echo "  • $file"
            done
        else
            echo -e "${GREEN}✅ All CSS files appear to be used${NC}"
        fi
        echo ""
        
        # Check for inline styles
        INLINE_STYLES=$(grep -r 'style={{' src 2>/dev/null | wc -l || echo "0")
        echo "Inline styles: $INLINE_STYLES"
        
        if [ "$INLINE_STYLES" -gt 20 ]; then
            echo -e "${YELLOW}⚠️  Many inline styles - consider extracting to CSS${NC}"
        else
            echo -e "${GREEN}✅ Reasonable use of inline styles${NC}"
        fi
        echo ""
        
        # Check for color consistency
        echo "Checking color usage..."
        COLORS=$(grep -roh '#[0-9a-fA-F]\{3,6\}' src/styles 2>/dev/null | sort | uniq -c | sort -rn | head -10)
        
        if [ -n "$COLORS" ]; then
            echo "Top colors used:"
            echo "$COLORS"
        else
            echo "No hex colors found in CSS files"
        fi
        ;;
        
    4)
        # Generate style guide
        echo ""
        echo "Generating style guide..."
        
        STYLE_GUIDE="$PROJECT_ROOT/docs/STYLE_GUIDE.md"
        mkdir -p "$PROJECT_ROOT/docs"
        
        cat > "$STYLE_GUIDE" << 'EOF'
# Style Guide

## CSS Architecture

### File Organization

```
src/
├── styles/
│   ├── global.css          # Global styles
│   ├── variables.css       # CSS variables
│   ├── ComponentName.css   # Component styles
│   └── ...
└── components/
    ├── ComponentName.jsx
    ├── ComponentName.module.css  # CSS Module (optional)
    └── ...
```

### Naming Conventions

**BEM (Block Element Modifier):**
```css
.component {}
.component__element {}
.component--modifier {}
.component__element--modifier {}
```

**Example:**
```css
.card {}
.card__header {}
.card__title {}
.card__content {}
.card--featured {}
.card__title--large {}
```

**CSS Modules:**
```css
.container {}
.header {}
.title {}
.active {}
```

### CSS Variables

Define reusable values:

```css
:root {
  /* Colors */
  --color-primary: #007bff;
  --color-secondary: #6c757d;
  --color-success: #28a745;
  --color-danger: #dc3545;
  --color-warning: #ffc107;
  --color-info: #17a2b8;
  
  /* Typography */
  --font-family-base: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  --font-size-base: 1rem;
  --font-size-lg: 1.25rem;
  --font-size-sm: 0.875rem;
  --line-height-base: 1.5;
  
  /* Spacing */
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 1.5rem;
  --spacing-xl: 2rem;
  
  /* Breakpoints */
  --breakpoint-sm: 576px;
  --breakpoint-md: 768px;
  --breakpoint-lg: 992px;
  --breakpoint-xl: 1200px;
}
```

### Responsive Design

Mobile-first approach:

```css
/* Mobile styles (default) */
.component {
  padding: 0.5rem;
}

/* Tablet and up */
@media (min-width: 768px) {
  .component {
    padding: 1rem;
  }
}

/* Desktop and up */
@media (min-width: 1024px) {
  .component {
    padding: 1.5rem;
  }
}
```

### Component Structure

```css
/* Component container */
.component {
  /* Layout */
  display: flex;
  flex-direction: column;
  
  /* Spacing */
  padding: var(--spacing-md);
  margin-bottom: var(--spacing-lg);
  
  /* Visual */
  background-color: #fff;
  border-radius: 4px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

/* Component elements */
.component__header {
  margin-bottom: var(--spacing-md);
}

.component__title {
  font-size: var(--font-size-lg);
  font-weight: 600;
  color: var(--color-primary);
}

.component__content {
  flex: 1;
  line-height: var(--line-height-base);
}

/* Component states */
.component--active {
  border-color: var(--color-primary);
}

.component--disabled {
  opacity: 0.5;
  pointer-events: none;
}
```

### Best Practices

1. **Use CSS Variables** for consistent theming
2. **Follow BEM** or CSS Modules for naming
3. **Mobile-first** responsive design
4. **Avoid deep nesting** (max 3 levels)
5. **Group related properties** (layout, spacing, visual)
6. **Use shorthand** properties when possible
7. **Avoid !important** unless absolutely necessary
8. **Comment complex** or non-obvious styles
9. **Keep specificity low**
10. **Use semantic** class names

### Color Palette

```css
/* Primary Colors */
--color-primary: #007bff;
--color-primary-dark: #0056b3;
--color-primary-light: #66b3ff;

/* Neutral Colors */
--color-gray-100: #f8f9fa;
--color-gray-200: #e9ecef;
--color-gray-300: #dee2e6;
--color-gray-400: #ced4da;
--color-gray-500: #adb5bd;
--color-gray-600: #6c757d;
--color-gray-700: #495057;
--color-gray-800: #343a40;
--color-gray-900: #212529;

/* Semantic Colors */
--color-success: #28a745;
--color-warning: #ffc107;
--color-danger: #dc3545;
--color-info: #17a2b8;
```

### Typography

```css
/* Headings */
h1, .h1 { font-size: 2.5rem; }
h2, .h2 { font-size: 2rem; }
h3, .h3 { font-size: 1.75rem; }
h4, .h4 { font-size: 1.5rem; }
h5, .h5 { font-size: 1.25rem; }
h6, .h6 { font-size: 1rem; }

/* Body text */
body {
  font-family: var(--font-family-base);
  font-size: var(--font-size-base);
  line-height: var(--line-height-base);
  color: var(--color-gray-900);
}

/* Utilities */
.text-small { font-size: var(--font-size-sm); }
.text-large { font-size: var(--font-size-lg); }
.text-bold { font-weight: 600; }
.text-center { text-align: center; }
```

### Spacing

```css
/* Margin utilities */
.m-0 { margin: 0; }
.m-1 { margin: var(--spacing-xs); }
.m-2 { margin: var(--spacing-sm); }
.m-3 { margin: var(--spacing-md); }
.m-4 { margin: var(--spacing-lg); }
.m-5 { margin: var(--spacing-xl); }

/* Padding utilities */
.p-0 { padding: 0; }
.p-1 { padding: var(--spacing-xs); }
.p-2 { padding: var(--spacing-sm); }
.p-3 { padding: var(--spacing-md); }
.p-4 { padding: var(--spacing-lg); }
.p-5 { padding: var(--spacing-xl); }
```

### Accessibility

```css
/* Focus styles */
:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

/* Skip link */
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: var(--color-primary);
  color: white;
  padding: 8px;
  text-decoration: none;
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}

/* Screen reader only */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

## Tools

- **Prettier**: Code formatting
- **Stylelint**: CSS linting
- **PostCSS**: CSS processing
- **Autoprefixer**: Vendor prefixes

## Resources

- [BEM Methodology](http://getbem.com/)
- [CSS Guidelines](https://cssguidelin.es/)
- [MDN CSS Reference](https://developer.mozilla.org/en-US/docs/Web/CSS)
EOF
        
        echo -e "${GREEN}✅ Style guide generated: $STYLE_GUIDE${NC}"
        ;;
        
    5)
        # Check style consistency
        echo ""
        echo "Checking style consistency..."
        echo ""
        
        # Check for CSS variables usage
        VAR_USAGE=$(grep -r 'var(--' src/styles 2>/dev/null | wc -l || echo "0")
        echo "CSS variable usage: $VAR_USAGE"
        
        if [ "$VAR_USAGE" -gt 10 ]; then
            echo -e "${GREEN}✅ Good use of CSS variables${NC}"
        else
            echo -e "${YELLOW}⚠️  Consider using CSS variables for consistency${NC}"
        fi
        echo ""
        
        # Check for hardcoded colors
        HARDCODED_COLORS=$(grep -roh '#[0-9a-fA-F]\{3,6\}' src/components 2>/dev/null | wc -l || echo "0")
        echo "Hardcoded colors in components: $HARDCODED_COLORS"
        
        if [ "$HARDCODED_COLORS" -gt 20 ]; then
            echo -e "${YELLOW}⚠️  Many hardcoded colors - consider using CSS variables${NC}"
        else
            echo -e "${GREEN}✅ Reasonable color usage${NC}"
        fi
        echo ""
        
        # Check for !important
        IMPORTANT_COUNT=$(grep -r '!important' src/styles 2>/dev/null | wc -l || echo "0")
        echo "!important usage: $IMPORTANT_COUNT"
        
        if [ "$IMPORTANT_COUNT" -gt 5 ]; then
            echo -e "${YELLOW}⚠️  Excessive !important usage${NC}"
        else
            echo -e "${GREEN}✅ Minimal !important usage${NC}"
        fi
        ;;
        
    0)
        echo "Exiting..."
        exit 0
        ;;
        
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo "Style guide: docs/STYLE_GUIDE.md"
