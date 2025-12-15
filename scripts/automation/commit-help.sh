#!/bin/bash
# commit-help.sh - Interactive commit message helper
# Guides users to write better commit messages following conventions

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

echo -e "${CYAN}📝 Commit Message Helper${NC}"
echo "========================"
echo ""

# Check if we're in a git repository
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo -e "${RED}❌ Not a git repository${NC}"
    exit 1
fi

# Check for staged files
STAGED_FILES=$(git diff --cached --name-only)
if [ -z "$STAGED_FILES" ]; then
    echo -e "${YELLOW}⚠️  No files staged for commit${NC}"
    echo ""
    echo "Stage files first with: git add <files>"
    exit 1
fi

# Show staged files
echo -e "${BLUE}Staged files:${NC}"
echo "$STAGED_FILES" | while read -r file; do
    echo "  • $file"
done
echo ""

# Analyze recent commits to understand conventions
echo -e "${BLUE}Recent commit messages:${NC}"
git log --oneline -5 2>/dev/null || echo "No commit history"
echo ""

# Commit type selection
echo -e "${CYAN}Select commit type:${NC}"
echo "  1) feat     - New feature"
echo "  2) fix      - Bug fix"
echo "  3) docs     - Documentation changes"
echo "  4) style    - Code style changes (formatting, etc.)"
echo "  5) refactor - Code refactoring"
echo "  6) test     - Adding or updating tests"
echo "  7) chore    - Maintenance tasks"
echo "  8) perf     - Performance improvements"
echo "  9) ci       - CI/CD changes"
echo "  10) build   - Build system changes"
echo "  11) revert  - Revert previous commit"
echo ""
read -p "Enter number (1-11): " TYPE_NUM

case $TYPE_NUM in
    1) TYPE="feat" ;;
    2) TYPE="fix" ;;
    3) TYPE="docs" ;;
    4) TYPE="style" ;;
    5) TYPE="refactor" ;;
    6) TYPE="test" ;;
    7) TYPE="chore" ;;
    8) TYPE="perf" ;;
    9) TYPE="ci" ;;
    10) TYPE="build" ;;
    11) TYPE="revert" ;;
    *) 
        echo -e "${RED}Invalid selection${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Selected: $TYPE${NC}"
echo ""

# Optional scope
echo -e "${CYAN}Enter scope (optional, e.g., 'auth', 'ui', 'api'):${NC}"
read -p "Scope: " SCOPE

if [ -n "$SCOPE" ]; then
    TYPE_SCOPE="$TYPE($SCOPE)"
else
    TYPE_SCOPE="$TYPE"
fi

# Subject line
echo ""
echo -e "${CYAN}Enter commit subject (short description):${NC}"
echo "  • Use imperative mood (e.g., 'add' not 'added')"
echo "  • Keep under 50 characters"
echo "  • Don't end with a period"
echo ""
read -p "Subject: " SUBJECT

if [ -z "$SUBJECT" ]; then
    echo -e "${RED}❌ Subject is required${NC}"
    exit 1
fi

# Check subject length
SUBJECT_LENGTH=${#SUBJECT}
if [ $SUBJECT_LENGTH -gt 50 ]; then
    echo -e "${YELLOW}⚠️  Subject is $SUBJECT_LENGTH characters (recommended: <50)${NC}"
    read -p "Continue anyway? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        exit 1
    fi
fi

# Body (optional)
echo ""
echo -e "${CYAN}Enter commit body (optional, press Enter to skip):${NC}"
echo "  • Explain what and why, not how"
echo "  • Wrap at 72 characters"
echo "  • Press Ctrl+D when done (or Enter to skip)"
echo ""

BODY=""
if read -t 5 -p "Add body? (y/n): " ADD_BODY && [ "$ADD_BODY" = "y" ]; then
    echo "Enter body (Ctrl+D when done):"
    BODY=$(cat)
fi

# Breaking changes
echo ""
read -p "Does this include breaking changes? (y/n): " BREAKING
BREAKING_TEXT=""
if [ "$BREAKING" = "y" ]; then
    echo "Describe the breaking changes:"
    read -p "Breaking change: " BREAKING_DESC
    BREAKING_TEXT="\n\nBREAKING CHANGE: $BREAKING_DESC"
fi

# Issue reference
echo ""
read -p "Reference an issue? (e.g., #123, leave empty to skip): " ISSUE

# Build commit message
COMMIT_MSG="$TYPE_SCOPE: $SUBJECT"

if [ -n "$BODY" ]; then
    COMMIT_MSG="$COMMIT_MSG\n\n$BODY"
fi

if [ -n "$BREAKING_TEXT" ]; then
    COMMIT_MSG="$COMMIT_MSG$BREAKING_TEXT"
fi

if [ -n "$ISSUE" ]; then
    COMMIT_MSG="$COMMIT_MSG\n\nCloses: $ISSUE"
fi

# Add co-author
COMMIT_MSG="$COMMIT_MSG\n\nCo-authored-by: Ona <no-reply@ona.com>"

# Preview
echo ""
echo "========================"
echo -e "${CYAN}Commit message preview:${NC}"
echo "========================"
echo -e "$COMMIT_MSG"
echo "========================"
echo ""

# Confirm
read -p "Commit with this message? (y/n): " CONFIRM

if [ "$CONFIRM" = "y" ]; then
    # Create commit
    echo -e "$COMMIT_MSG" | git commit -F -
    
    echo ""
    echo -e "${GREEN}✅ Commit created successfully!${NC}"
    echo ""
    
    # Show the commit
    git log -1 --pretty=format:"%h - %s (%an, %ar)"
    echo ""
    echo ""
    
    # Push reminder
    read -p "Push to remote? (y/n): " PUSH
    if [ "$PUSH" = "y" ]; then
        CURRENT_BRANCH=$(git branch --show-current)
        echo "Pushing to origin/$CURRENT_BRANCH..."
        git push origin "$CURRENT_BRANCH"
        echo -e "${GREEN}✅ Pushed successfully!${NC}"
    else
        echo "Remember to push when ready: git push"
    fi
else
    echo -e "${YELLOW}Commit cancelled${NC}"
    exit 1
fi

echo ""
echo "========================"
echo -e "${CYAN}Commit Guidelines:${NC}"
echo ""
echo "Format: <type>(<scope>): <subject>"
echo ""
echo "Types:"
echo "  • feat: New feature"
echo "  • fix: Bug fix"
echo "  • docs: Documentation"
echo "  • style: Formatting"
echo "  • refactor: Code restructuring"
echo "  • test: Tests"
echo "  • chore: Maintenance"
echo ""
echo "Examples:"
echo "  feat(auth): add login functionality"
echo "  fix(ui): resolve button alignment issue"
echo "  docs: update README with setup instructions"
echo ""
echo "For more info: https://www.conventionalcommits.org/"
