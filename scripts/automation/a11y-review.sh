#!/bin/bash
# a11y-review.sh - Accessibility review automation
# Checks for common accessibility issues in React components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "♿ Accessibility Review"
echo "======================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

ISSUES_FOUND=0
WARNINGS_FOUND=0

# Check for semantic HTML
echo ""
echo "🏷️  Semantic HTML Check"
echo "Checking for proper semantic elements..."

SRC_DIR="$PROJECT_ROOT/src"
if [ ! -d "$SRC_DIR" ]; then
    echo -e "${RED}❌ src/ directory not found${NC}"
    exit 1
fi

# Check for div soup (excessive divs)
DIV_COUNT=$(grep -r "<div" "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
SEMANTIC_COUNT=$(grep -rE "<(header|nav|main|section|article|aside|footer)" "$SRC_DIR" 2>/dev/null | wc -l || echo "0")

echo "   <div> elements: $DIV_COUNT"
echo "   Semantic elements: $SEMANTIC_COUNT"

if [ "$SEMANTIC_COUNT" -gt 0 ]; then
    echo -e "   ${GREEN}✅ Using semantic HTML elements${NC}"
else
    echo -e "   ${YELLOW}⚠️  Consider using semantic HTML (header, nav, main, section, article, footer)${NC}"
    ((WARNINGS_FOUND++))
fi

# Check for alt text on images
echo ""
echo "🖼️  Image Alt Text Check"
IMG_TAGS=$(grep -r "<img" "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
IMG_WITH_ALT=$(grep -r '<img[^>]*alt=' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")

echo "   <img> tags found: $IMG_TAGS"
echo "   Images with alt: $IMG_WITH_ALT"

if [ "$IMG_TAGS" -eq 0 ]; then
    echo -e "   ${BLUE}ℹ️  No image tags found${NC}"
elif [ "$IMG_TAGS" -eq "$IMG_WITH_ALT" ]; then
    echo -e "   ${GREEN}✅ All images have alt attributes${NC}"
else
    MISSING=$((IMG_TAGS - IMG_WITH_ALT))
    echo -e "   ${RED}❌ $MISSING images missing alt text${NC}"
    echo "   Images without alt:"
    grep -rn "<img" "$SRC_DIR" 2>/dev/null | grep -v "alt=" | head -5
    ((ISSUES_FOUND++)) || true
fi

# Check for button accessibility
echo ""
echo "🔘 Button Accessibility Check"
BUTTON_TAGS=$(grep -r "<button" "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
DIV_ONCLICK=$(grep -r 'onClick.*<div' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")

echo "   <button> elements: $BUTTON_TAGS"
echo "   <div> with onClick: $DIV_ONCLICK"

if [ "$DIV_ONCLICK" -gt 0 ]; then
    echo -e "   ${YELLOW}⚠️  Found $DIV_ONCLICK divs with onClick - consider using <button>${NC}"
    grep -rn 'onClick.*<div\|<div.*onClick' "$SRC_DIR" 2>/dev/null | head -3
    ((WARNINGS_FOUND++))
else
    echo -e "   ${GREEN}✅ No divs used as buttons${NC}"
fi

# Check for form labels
echo ""
echo "📝 Form Label Check"
INPUT_TAGS=$(grep -r "<input" "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
LABEL_TAGS=$(grep -r "<label" "$SRC_DIR" 2>/dev/null | wc -l || echo "0")

echo "   <input> elements: $INPUT_TAGS"
echo "   <label> elements: $LABEL_TAGS"

if [ "$INPUT_TAGS" -gt 0 ]; then
    if [ "$LABEL_TAGS" -ge "$INPUT_TAGS" ]; then
        echo -e "   ${GREEN}✅ Sufficient labels for inputs${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Some inputs may be missing labels${NC}"
        echo "   Ensure all inputs have associated labels or aria-label"
        ((WARNINGS_FOUND++))
    fi
else
    echo -e "   ${BLUE}ℹ️  No input elements found${NC}"
fi

# Check for ARIA attributes
echo ""
echo "🎯 ARIA Attributes Check"
ARIA_LABEL=$(grep -r 'aria-label' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
ARIA_LABELLEDBY=$(grep -r 'aria-labelledby' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
ARIA_DESCRIBEDBY=$(grep -r 'aria-describedby' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
ARIA_HIDDEN=$(grep -r 'aria-hidden' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
ROLE_ATTR=$(grep -r 'role=' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")

echo "   aria-label: $ARIA_LABEL"
echo "   aria-labelledby: $ARIA_LABELLEDBY"
echo "   aria-describedby: $ARIA_DESCRIBEDBY"
echo "   aria-hidden: $ARIA_HIDDEN"
echo "   role attributes: $ROLE_ATTR"

TOTAL_ARIA=$((ARIA_LABEL + ARIA_LABELLEDBY + ARIA_DESCRIBEDBY + ROLE_ATTR))
if [ "$TOTAL_ARIA" -gt 0 ]; then
    echo -e "   ${GREEN}✅ Using ARIA attributes for accessibility${NC}"
else
    echo -e "   ${YELLOW}⚠️  No ARIA attributes found - consider adding for better accessibility${NC}"
    ((WARNINGS_FOUND++))
fi

# Check for heading hierarchy
echo ""
echo "📑 Heading Hierarchy Check"
H1_COUNT=$(grep -r "<h1" "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
H2_COUNT=$(grep -r "<h2" "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
H3_COUNT=$(grep -r "<h3" "$SRC_DIR" 2>/dev/null | wc -l || echo "0")

echo "   <h1> tags: $H1_COUNT"
echo "   <h2> tags: $H2_COUNT"
echo "   <h3> tags: $H3_COUNT"

if [ "$H1_COUNT" -eq 0 ]; then
    echo -e "   ${YELLOW}⚠️  No <h1> tags found - each page should have one${NC}"
    ((WARNINGS_FOUND++))
elif [ "$H1_COUNT" -gt 3 ]; then
    echo -e "   ${YELLOW}⚠️  Multiple <h1> tags found - typically one per page${NC}"
    ((WARNINGS_FOUND++))
else
    echo -e "   ${GREEN}✅ Appropriate <h1> usage${NC}"
fi

# Check for color contrast issues (basic check)
echo ""
echo "🎨 Color Contrast Check"
echo "Checking for potential contrast issues..."

# Look for inline styles with colors
INLINE_COLORS=$(grep -rE 'style=.*color:' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
if [ "$INLINE_COLORS" -gt 0 ]; then
    echo -e "   ${YELLOW}⚠️  Found $INLINE_COLORS inline color styles${NC}"
    echo "   Verify color contrast meets WCAG AA standards (4.5:1 for normal text)"
    ((WARNINGS_FOUND++))
else
    echo -e "   ${GREEN}✅ No inline color styles found${NC}"
fi

# Check for keyboard navigation
echo ""
echo "⌨️  Keyboard Navigation Check"
TABINDEX=$(grep -r 'tabIndex' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
ONKEYDOWN=$(grep -r 'onKeyDown' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")

echo "   tabIndex attributes: $TABINDEX"
echo "   onKeyDown handlers: $ONKEYDOWN"

if [ "$TABINDEX" -gt 0 ] || [ "$ONKEYDOWN" -gt 0 ]; then
    echo -e "   ${GREEN}✅ Keyboard navigation implemented${NC}"
else
    echo -e "   ${YELLOW}⚠️  Consider adding keyboard navigation support${NC}"
    ((WARNINGS_FOUND++))
fi

# Check for focus management
echo ""
echo "🎯 Focus Management Check"
AUTOFOCUS=$(grep -r 'autoFocus' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")
FOCUS_VISIBLE=$(grep -r ':focus-visible' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")

echo "   autoFocus usage: $AUTOFOCUS"
echo "   :focus-visible styles: $FOCUS_VISIBLE"

if [ "$FOCUS_VISIBLE" -gt 0 ]; then
    echo -e "   ${GREEN}✅ Focus styles implemented${NC}"
else
    echo -e "   ${YELLOW}⚠️  Consider adding :focus-visible styles for keyboard users${NC}"
    ((WARNINGS_FOUND++))
fi

# Check for skip links
echo ""
echo "⏭️  Skip Link Check"
SKIP_LINK=$(grep -ri 'skip.*content\|skip.*main' "$SRC_DIR" 2>/dev/null | wc -l || echo "0")

if [ "$SKIP_LINK" -gt 0 ]; then
    echo -e "${GREEN}✅ Skip link found${NC}"
else
    echo -e "${YELLOW}⚠️  No skip link found - consider adding for keyboard users${NC}"
    echo "   Add a 'Skip to main content' link at the top of the page"
    ((WARNINGS_FOUND++))
fi

# Check for language attribute
echo ""
echo "🌐 Language Attribute Check"
if [ -f "$PROJECT_ROOT/index.html" ]; then
    if grep -q '<html.*lang=' "$PROJECT_ROOT/index.html"; then
        LANG=$(grep -o 'lang="[^"]*"' "$PROJECT_ROOT/index.html" | head -1)
        echo -e "${GREEN}✅ Language attribute found: $LANG${NC}"
    else
        echo -e "${RED}❌ No lang attribute on <html> tag${NC}"
        echo "   Add lang='en' (or appropriate language) to <html> tag"
        ((ISSUES_FOUND++)) || true
    fi
else
    echo -e "${YELLOW}⚠️  index.html not found${NC}"
fi

# Check for viewport meta tag
echo ""
echo "📱 Viewport Meta Tag Check"
if [ -f "$PROJECT_ROOT/index.html" ]; then
    if grep -q 'name="viewport"' "$PROJECT_ROOT/index.html"; then
        echo -e "${GREEN}✅ Viewport meta tag found${NC}"
    else
        echo -e "${RED}❌ No viewport meta tag${NC}"
        echo "   Add: <meta name='viewport' content='width=device-width, initial-scale=1.0'>"
        ((ISSUES_FOUND++)) || true
    fi
fi

# Recommendations
echo ""
echo "💡 Recommendations"
echo "=================="
echo "1. Test with screen readers (NVDA, JAWS, VoiceOver)"
echo "2. Test keyboard navigation (Tab, Enter, Space, Arrow keys)"
echo "3. Use browser DevTools Lighthouse for automated testing"
echo "4. Verify color contrast with tools like WebAIM Contrast Checker"
echo "5. Test with browser zoom at 200%"
echo "6. Consider using eslint-plugin-jsx-a11y for automated checks"

# Summary
echo ""
echo "======================"
if [ $ISSUES_FOUND -eq 0 ] && [ $WARNINGS_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ Accessibility review complete - No issues found${NC}"
    exit 0
elif [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Accessibility review complete - $WARNINGS_FOUND warnings${NC}"
    echo "Review warnings above to improve accessibility"
    exit 0
else
    echo -e "${RED}❌ Accessibility review complete - $ISSUES_FOUND critical issues, $WARNINGS_FOUND warnings${NC}"
    echo "Address critical issues before deployment"
    exit 0
fi
