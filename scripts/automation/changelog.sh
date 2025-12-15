#!/bin/bash
# changelog.sh - Changelog generator
# Generates changelog from git commits

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

echo -e "${CYAN}📝 Changelog Generator${NC}"
echo "======================"
echo ""

cd "$PROJECT_ROOT"

# Check if git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Not a git repository${NC}"
    exit 1
fi

# Get version from package.json
CURRENT_VERSION=$(node -p "require('./package.json').version" 2>/dev/null || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"
echo ""

# Options
echo "Select changelog type:"
echo "  1. Full changelog (all commits)"
echo "  2. Since last tag"
echo "  3. Since specific date"
echo "  4. Between two tags"
echo "  5. Update CHANGELOG.md"
echo ""
read -p "Select option (1-5): " OPTION

CHANGELOG_FILE="$PROJECT_ROOT/CHANGELOG.md"

case $OPTION in
    1)
        # Full changelog
        echo ""
        echo "Generating full changelog..."
        echo ""
        
        git log --pretty=format:"%h - %s (%an, %ar)" --abbrev-commit
        ;;
        
    2)
        # Since last tag
        LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
        
        if [ -z "$LAST_TAG" ]; then
            echo -e "${YELLOW}⚠️  No tags found${NC}"
            echo "Showing all commits..."
            git log --pretty=format:"%h - %s (%an, %ar)" --abbrev-commit
        else
            echo "Changes since $LAST_TAG:"
            echo ""
            git log $LAST_TAG..HEAD --pretty=format:"%h - %s (%an, %ar)" --abbrev-commit
        fi
        ;;
        
    3)
        # Since specific date
        read -p "Enter date (YYYY-MM-DD): " SINCE_DATE
        echo ""
        echo "Changes since $SINCE_DATE:"
        echo ""
        git log --since="$SINCE_DATE" --pretty=format:"%h - %s (%an, %ar)" --abbrev-commit
        ;;
        
    4)
        # Between two tags
        echo "Available tags:"
        git tag -l
        echo ""
        read -p "Enter start tag: " START_TAG
        read -p "Enter end tag: " END_TAG
        echo ""
        echo "Changes from $START_TAG to $END_TAG:"
        echo ""
        git log $START_TAG..$END_TAG --pretty=format:"%h - %s (%an, %ar)" --abbrev-commit
        ;;
        
    5)
        # Update CHANGELOG.md
        echo ""
        echo "Updating CHANGELOG.md..."
        
        # Get last tag or use beginning
        LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
        
        if [ -z "$LAST_TAG" ]; then
            echo "No previous tags found. Generating from all commits..."
            RANGE="HEAD"
        else
            echo "Generating changes since $LAST_TAG..."
            RANGE="$LAST_TAG..HEAD"
        fi
        
        # Create or backup existing changelog
        if [ -f "$CHANGELOG_FILE" ]; then
            cp "$CHANGELOG_FILE" "${CHANGELOG_FILE}.backup"
            echo "Backed up existing changelog"
        fi
        
        # Generate new changelog content
        TEMP_FILE=$(mktemp)
        
        cat > "$TEMP_FILE" << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

EOF
        
        # Categorize commits
        echo "### Added" >> "$TEMP_FILE"
        git log $RANGE --pretty=format:"- %s (%h)" --grep="^feat" >> "$TEMP_FILE" 2>/dev/null || true
        echo "" >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        
        echo "### Fixed" >> "$TEMP_FILE"
        git log $RANGE --pretty=format:"- %s (%h)" --grep="^fix" >> "$TEMP_FILE" 2>/dev/null || true
        echo "" >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        
        echo "### Changed" >> "$TEMP_FILE"
        git log $RANGE --pretty=format:"- %s (%h)" --grep="^refactor\|^perf" >> "$TEMP_FILE" 2>/dev/null || true
        echo "" >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        
        echo "### Documentation" >> "$TEMP_FILE"
        git log $RANGE --pretty=format:"- %s (%h)" --grep="^docs" >> "$TEMP_FILE" 2>/dev/null || true
        echo "" >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        
        # Add previous releases if changelog exists
        if [ -f "${CHANGELOG_FILE}.backup" ]; then
            # Skip header and unreleased section from backup
            sed -n '/^## \[/,$p' "${CHANGELOG_FILE}.backup" >> "$TEMP_FILE" 2>/dev/null || true
        fi
        
        # Move temp file to changelog
        mv "$TEMP_FILE" "$CHANGELOG_FILE"
        
        echo -e "${GREEN}✅ CHANGELOG.md updated${NC}"
        echo ""
        echo "Preview:"
        head -30 "$CHANGELOG_FILE"
        echo ""
        echo "Full changelog: $CHANGELOG_FILE"
        ;;
        
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

# Statistics
echo ""
echo "======================"
echo -e "${CYAN}Commit Statistics${NC}"
echo "======================"

# Get commit counts by type
FEAT_COUNT=$(git log --oneline --grep="^feat" | wc -l)
FIX_COUNT=$(git log --oneline --grep="^fix" | wc -l)
DOCS_COUNT=$(git log --oneline --grep="^docs" | wc -l)
REFACTOR_COUNT=$(git log --oneline --grep="^refactor" | wc -l)
TEST_COUNT=$(git log --oneline --grep="^test" | wc -l)
CHORE_COUNT=$(git log --oneline --grep="^chore" | wc -l)

echo "Commit types:"
echo "  Features: $FEAT_COUNT"
echo "  Fixes: $FIX_COUNT"
echo "  Documentation: $DOCS_COUNT"
echo "  Refactoring: $REFACTOR_COUNT"
echo "  Tests: $TEST_COUNT"
echo "  Chores: $CHORE_COUNT"

# Top contributors
echo ""
echo "Top contributors:"
git shortlog -sn --all | head -5

# Recent activity
echo ""
echo "Recent activity:"
COMMITS_LAST_WEEK=$(git log --since="1 week ago" --oneline | wc -l)
COMMITS_LAST_MONTH=$(git log --since="1 month ago" --oneline | wc -l)

echo "  Last week: $COMMITS_LAST_WEEK commits"
echo "  Last month: $COMMITS_LAST_MONTH commits"

# Tags
echo ""
echo "Tags:"
TAG_COUNT=$(git tag -l | wc -l)
echo "  Total tags: $TAG_COUNT"

if [ "$TAG_COUNT" -gt 0 ]; then
    echo "  Latest tags:"
    git tag -l --sort=-version:refname | head -5 | while read -r tag; do
        TAG_DATE=$(git log -1 --format=%ai "$tag" 2>/dev/null | cut -d' ' -f1)
        echo "    $tag ($TAG_DATE)"
    done
fi

echo ""
echo "======================"
echo "Changelog commands:"
echo "  git log                    - View commit history"
echo "  git tag                    - List tags"
echo "  git tag v1.0.0             - Create new tag"
echo "  git push --tags            - Push tags to remote"
echo ""
echo "Conventional Commits:"
echo "  feat: New feature"
echo "  fix: Bug fix"
echo "  docs: Documentation"
echo "  style: Formatting"
echo "  refactor: Code restructuring"
echo "  test: Tests"
echo "  chore: Maintenance"
