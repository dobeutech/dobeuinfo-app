#!/bin/bash
# cli-workflow.sh - CLI workflow helper
# Interactive menu for common development tasks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

clear

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════╗
║     CLI Workflow Helper               ║
║     Development Automation            ║
╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"

# Get project info
cd "$PROJECT_ROOT"
PROJECT_NAME=$(node -p "require('./package.json').name" 2>/dev/null || echo "unknown")
PROJECT_VERSION=$(node -p "require('./package.json').version" 2>/dev/null || echo "0.0.0")

echo -e "${BLUE}Project:${NC} $PROJECT_NAME v$PROJECT_VERSION"
echo -e "${BLUE}Path:${NC} $PROJECT_ROOT"
echo ""

# Main menu
show_menu() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}Main Menu${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    echo "  ${GREEN}Development${NC}"
    echo "    1) Start dev server"
    echo "    2) Build for production"
    echo "    3) Preview production build"
    echo "    4) Install dependencies"
    echo ""
    echo "  ${YELLOW}Code Quality${NC}"
    echo "    5) Run linter"
    echo "    6) Format code"
    echo "    7) Run tests"
    echo "    8) Code review"
    echo ""
    echo "  ${BLUE}Automation Scripts${NC}"
    echo "    9) Documentation sync"
    echo "   10) Environment check"
    echo "   11) Dependency audit"
    echo "   12) Accessibility review"
    echo "   13) Pre-commit check"
    echo "   14) Observability check"
    echo ""
    echo "  ${MAGENTA}Generators${NC}"
    echo "   15) Create new page"
    echo "   16) Create component test"
    echo "   17) Generate changelog"
    echo ""
    echo "  ${CYAN}Git Operations${NC}"
    echo "   18) Commit helper"
    echo "   19) View git status"
    echo "   20) View git log"
    echo ""
    echo "  ${RED}Other${NC}"
    echo "   21) Infrastructure review"
    echo "   22) Log analysis"
    echo "   23) View all scripts"
    echo "    0) Exit"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
}

# Execute script
run_script() {
    local script="$1"
    local script_path="$SCRIPT_DIR/$script"
    
    if [ -f "$script_path" ]; then
        echo ""
        echo -e "${CYAN}Running: $script${NC}"
        echo "═══════════════════════════════════════"
        bash "$script_path" "${@:2}"
        echo ""
        echo -e "${GREEN}✅ Complete${NC}"
    else
        echo -e "${RED}❌ Script not found: $script${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main loop
while true; do
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     CLI Workflow Helper               ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    
    show_menu
    
    read -p "Select option: " choice
    
    case $choice in
        1)
            echo ""
            echo -e "${CYAN}Starting development server...${NC}"
            cd "$PROJECT_ROOT"
            npm run dev
            ;;
        2)
            echo ""
            echo -e "${CYAN}Building for production...${NC}"
            cd "$PROJECT_ROOT"
            npm run build
            echo ""
            read -p "Press Enter to continue..."
            ;;
        3)
            echo ""
            echo -e "${CYAN}Previewing production build...${NC}"
            cd "$PROJECT_ROOT"
            npm run preview
            ;;
        4)
            echo ""
            echo -e "${CYAN}Installing dependencies...${NC}"
            cd "$PROJECT_ROOT"
            npm install
            echo ""
            read -p "Press Enter to continue..."
            ;;
        5)
            echo ""
            echo -e "${CYAN}Running linter...${NC}"
            cd "$PROJECT_ROOT"
            if grep -q "\"lint\"" package.json; then
                npm run lint
            else
                echo -e "${YELLOW}⚠️  No lint script found in package.json${NC}"
            fi
            echo ""
            read -p "Press Enter to continue..."
            ;;
        6)
            echo ""
            echo -e "${CYAN}Formatting code...${NC}"
            cd "$PROJECT_ROOT"
            if grep -q "\"format\"" package.json; then
                npm run format
            else
                echo -e "${YELLOW}⚠️  No format script found in package.json${NC}"
                echo "Try: npx prettier --write ."
            fi
            echo ""
            read -p "Press Enter to continue..."
            ;;
        7)
            echo ""
            echo -e "${CYAN}Running tests...${NC}"
            cd "$PROJECT_ROOT"
            if grep -q "\"test\"" package.json; then
                npm test
            else
                echo -e "${YELLOW}⚠️  No test script found in package.json${NC}"
            fi
            echo ""
            read -p "Press Enter to continue..."
            ;;
        8)
            run_script "reviewer.sh"
            ;;
        9)
            run_script "doc-sync.sh"
            ;;
        10)
            run_script "env-check.sh"
            ;;
        11)
            run_script "deps-audit.sh"
            ;;
        12)
            run_script "a11y-review.sh"
            ;;
        13)
            run_script "pre-commit-check.sh"
            ;;
        14)
            run_script "observability.sh"
            ;;
        15)
            echo ""
            read -p "Enter page name: " page_name
            run_script "page-create.sh" "$page_name"
            ;;
        16)
            echo ""
            read -p "Enter component name: " component_name
            run_script "test-component.sh" "$component_name"
            ;;
        17)
            run_script "changelog.sh"
            ;;
        18)
            run_script "commit-help.sh"
            ;;
        19)
            echo ""
            echo -e "${CYAN}Git Status${NC}"
            echo "═══════════════════════════════════════"
            cd "$PROJECT_ROOT"
            git status
            echo ""
            read -p "Press Enter to continue..."
            ;;
        20)
            echo ""
            echo -e "${CYAN}Git Log (last 10 commits)${NC}"
            echo "═══════════════════════════════════════"
            cd "$PROJECT_ROOT"
            git log --oneline -10
            echo ""
            read -p "Press Enter to continue..."
            ;;
        21)
            run_script "iac-review.sh"
            ;;
        22)
            run_script "log-analyze.sh"
            ;;
        23)
            echo ""
            echo -e "${CYAN}Available Scripts${NC}"
            echo "═══════════════════════════════════════"
            echo ""
            ls -1 "$SCRIPT_DIR"/*.sh | while read -r script; do
                SCRIPT_NAME=$(basename "$script")
                DESCRIPTION=$(head -2 "$script" | tail -1 | sed 's/^# //')
                echo -e "${GREEN}$SCRIPT_NAME${NC}"
                echo "  $DESCRIPTION"
                echo ""
            done
            read -p "Press Enter to continue..."
            ;;
        0)
            echo ""
            echo -e "${CYAN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo ""
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
done
