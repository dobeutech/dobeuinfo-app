#!/bin/bash
# log-analyze.sh - Log analysis tool
# Analyzes application logs for errors, warnings, and patterns

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "📊 Log Analysis"
echo "==============="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default log file locations
LOG_LOCATIONS=(
    "$PROJECT_ROOT/logs"
    "$PROJECT_ROOT/*.log"
    "$PROJECT_ROOT/npm-debug.log"
    "$PROJECT_ROOT/yarn-error.log"
    "/tmp/vite-*.log"
)

# Find log files
echo ""
echo "🔍 Searching for log files..."
LOG_FILES=()

for location in "${LOG_LOCATIONS[@]}"; do
    if [ -d "$location" ]; then
        while IFS= read -r -d '' file; do
            LOG_FILES+=("$file")
        done < <(find "$location" -name "*.log" -type f -print0 2>/dev/null)
    elif [ -f "$location" ]; then
        LOG_FILES+=("$location")
    else
        # Try glob expansion
        for file in $location; do
            [ -f "$file" ] && LOG_FILES+=("$file")
        done
    fi
done

if [ ${#LOG_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No log files found${NC}"
    echo ""
    echo "Checked locations:"
    for location in "${LOG_LOCATIONS[@]}"; do
        echo "  • $location"
    done
    echo ""
    echo "To analyze a specific log file:"
    echo "  $0 /path/to/logfile.log"
    exit 0
fi

echo -e "${GREEN}Found ${#LOG_FILES[@]} log file(s)${NC}"
for file in "${LOG_FILES[@]}"; do
    echo "  • $file"
done

# If argument provided, analyze that file specifically
if [ -n "$1" ]; then
    if [ -f "$1" ]; then
        LOG_FILES=("$1")
        echo ""
        echo -e "${CYAN}Analyzing specific file: $1${NC}"
    else
        echo -e "${RED}❌ File not found: $1${NC}"
        exit 1
    fi
fi

# Analyze each log file
for LOG_FILE in "${LOG_FILES[@]}"; do
    echo ""
    echo "========================================"
    echo -e "${CYAN}Analyzing: $(basename "$LOG_FILE")${NC}"
    echo "========================================"
    
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${YELLOW}⚠️  File not found or not readable${NC}"
        continue
    fi
    
    # File info
    FILE_SIZE=$(du -h "$LOG_FILE" | cut -f1)
    LINE_COUNT=$(wc -l < "$LOG_FILE")
    MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$LOG_FILE" 2>/dev/null || stat -c "%y" "$LOG_FILE" 2>/dev/null | cut -d'.' -f1)
    
    echo "Size: $FILE_SIZE"
    echo "Lines: $LINE_COUNT"
    echo "Modified: $MODIFIED"
    
    # Error analysis
    echo ""
    echo -e "${RED}🔴 Errors${NC}"
    ERROR_COUNT=$(grep -ci "error" "$LOG_FILE" 2>/dev/null || echo "0")
    echo "Total errors: $ERROR_COUNT"
    
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo ""
        echo "Recent errors (last 5):"
        grep -i "error" "$LOG_FILE" | tail -5 | while read -r line; do
            echo -e "  ${RED}•${NC} $line"
        done
        
        # Error types
        echo ""
        echo "Error types:"
        grep -i "error" "$LOG_FILE" | sed 's/.*\(Error[^:]*\).*/\1/' | sort | uniq -c | sort -rn | head -5 | while read -r count type; do
            echo "  $count × $type"
        done
    fi
    
    # Warning analysis
    echo ""
    echo -e "${YELLOW}⚠️  Warnings${NC}"
    WARNING_COUNT=$(grep -ci "warn\|warning" "$LOG_FILE" 2>/dev/null || echo "0")
    echo "Total warnings: $WARNING_COUNT"
    
    if [ "$WARNING_COUNT" -gt 0 ]; then
        echo ""
        echo "Recent warnings (last 5):"
        grep -i "warn\|warning" "$LOG_FILE" | tail -5 | while read -r line; do
            echo -e "  ${YELLOW}•${NC} $line"
        done
    fi
    
    # Critical issues
    echo ""
    echo -e "${RED}🚨 Critical Issues${NC}"
    CRITICAL_PATTERNS=("fatal" "critical" "panic" "segfault" "out of memory")
    CRITICAL_FOUND=0
    
    for pattern in "${CRITICAL_PATTERNS[@]}"; do
        COUNT=$(grep -ci "$pattern" "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$COUNT" -gt 0 ]; then
            echo -e "  ${RED}• $pattern: $COUNT occurrences${NC}"
            ((CRITICAL_FOUND++))
        fi
    done
    
    if [ $CRITICAL_FOUND -eq 0 ]; then
        echo -e "  ${GREEN}✅ No critical issues found${NC}"
    fi
    
    # Success/Info messages
    echo ""
    echo -e "${GREEN}✅ Success Messages${NC}"
    SUCCESS_COUNT=$(grep -ci "success\|complete\|done" "$LOG_FILE" 2>/dev/null || echo "0")
    echo "Total: $SUCCESS_COUNT"
    
    # Performance indicators
    echo ""
    echo -e "${BLUE}⚡ Performance Indicators${NC}"
    
    # Look for timing information
    TIMING_PATTERNS=("took [0-9]" "in [0-9].*ms" "duration" "elapsed")
    for pattern in "${TIMING_PATTERNS[@]}"; do
        COUNT=$(grep -ci "$pattern" "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$COUNT" -gt 0 ]; then
            echo "  • Timing entries: $COUNT"
            grep -i "$pattern" "$LOG_FILE" | tail -3 | while read -r line; do
                echo "    $line"
            done
            break
        fi
    done
    
    # HTTP status codes
    echo ""
    echo -e "${BLUE}🌐 HTTP Status Codes${NC}"
    STATUS_CODES=$(grep -oE "HTTP/[0-9.]+ [0-9]{3}" "$LOG_FILE" 2>/dev/null | awk '{print $2}' | sort | uniq -c | sort -rn || echo "")
    
    if [ -n "$STATUS_CODES" ]; then
        echo "$STATUS_CODES" | while read -r count code; do
            case $code in
                2*) echo -e "  ${GREEN}$code: $count${NC}" ;;
                3*) echo -e "  ${BLUE}$code: $count${NC}" ;;
                4*) echo -e "  ${YELLOW}$code: $count${NC}" ;;
                5*) echo -e "  ${RED}$code: $count${NC}" ;;
                *) echo "  $code: $count" ;;
            esac
        done
    else
        echo "  No HTTP status codes found"
    fi
    
    # Unique error messages
    echo ""
    echo -e "${CYAN}📋 Top Error Messages${NC}"
    if [ "$ERROR_COUNT" -gt 0 ]; then
        grep -i "error" "$LOG_FILE" | sed 's/^.*Error: //' | sed 's/ at .*//' | sort | uniq -c | sort -rn | head -5 | while read -r count msg; do
            echo "  $count × $msg"
        done
    else
        echo "  No errors to analyze"
    fi
    
    # Time-based analysis
    echo ""
    echo -e "${CYAN}⏰ Time-based Analysis${NC}"
    
    # Try to extract timestamps
    TIMESTAMPS=$(grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{2}:[0-9]{2}:[0-9]{2}" "$LOG_FILE" | head -1)
    if [ -n "$TIMESTAMPS" ]; then
        FIRST_ENTRY=$(grep -m1 -oE "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}|[0-9]{2}:[0-9]{2}:[0-9]{2}" "$LOG_FILE" || echo "Unknown")
        LAST_ENTRY=$(grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}|[0-9]{2}:[0-9]{2}:[0-9]{2}" "$LOG_FILE" | tail -1 || echo "Unknown")
        
        echo "  First entry: $FIRST_ENTRY"
        echo "  Last entry: $LAST_ENTRY"
    else
        echo "  No timestamps found in log"
    fi
    
    # Log size warning
    if [ "$LINE_COUNT" -gt 10000 ]; then
        echo ""
        echo -e "${YELLOW}⚠️  Large log file detected ($LINE_COUNT lines)${NC}"
        echo "  Consider log rotation or cleanup"
    fi
done

# Summary
echo ""
echo "========================================"
echo -e "${CYAN}Summary${NC}"
echo "========================================"

TOTAL_ERRORS=0
TOTAL_WARNINGS=0

for LOG_FILE in "${LOG_FILES[@]}"; do
    if [ -f "$LOG_FILE" ]; then
        ERRORS=$(grep -ci "error" "$LOG_FILE" 2>/dev/null || echo "0")
        WARNINGS=$(grep -ci "warn\|warning" "$LOG_FILE" 2>/dev/null || echo "0")
        TOTAL_ERRORS=$((TOTAL_ERRORS + ERRORS))
        TOTAL_WARNINGS=$((TOTAL_WARNINGS + WARNINGS))
    fi
done

echo "Total log files analyzed: ${#LOG_FILES[@]}"
echo -e "Total errors: ${RED}$TOTAL_ERRORS${NC}"
echo -e "Total warnings: ${YELLOW}$TOTAL_WARNINGS${NC}"

echo ""
echo "Recommendations:"
if [ $TOTAL_ERRORS -gt 0 ]; then
    echo "  • Review and fix errors"
    echo "  • Check application logs for root causes"
fi
if [ $TOTAL_WARNINGS -gt 10 ]; then
    echo "  • Address warnings to prevent future issues"
fi
echo "  • Implement log rotation for large files"
echo "  • Set up monitoring for critical errors"
echo "  • Consider structured logging (JSON format)"

echo ""
echo "To analyze a specific file:"
echo "  $0 /path/to/logfile.log"
