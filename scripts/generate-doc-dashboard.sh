#!/usr/bin/env bash
#
# generate-doc-dashboard.sh - Generate documentation coverage metrics dashboard
#
# Usage:
#   ./scripts/generate-doc-dashboard.sh
#
# Purpose:
#   Creates auto-generated dashboard showing:
#   - Documentation coverage by category
#   - Missing documentation warnings
#   - Stale documentation detection
#   - Function count vs documented functions
#
# Output:
#   Creates/updates docs/DOC-DASHBOARD.md

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly DASHBOARD_FILE="$PROJECT_ROOT/docs/DOC-DASHBOARD.md"
readonly LIB_DIR="$PROJECT_ROOT/lib"
readonly DOCS_DIR="$PROJECT_ROOT/docs"
readonly API_DOC="$PROJECT_ROOT/docs/reference/MASTER-API-REFERENCE.md"

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Count total functions in library
count_total_functions() {
    local count=0
    while IFS= read -r file; do
        local file_count
        file_count=$(grep -c "^[[:space:]]*\(function[[:space:]]\+\)\?[_a-zA-Z][_a-zA-Z0-9]*()[[:space:]]*{" "$file" 2>/dev/null || echo 0)
        count=$((count + file_count))
    done < <(find "$LIB_DIR" -name "*.zsh" -type f)
    echo "$count"
}

# Count documented functions
count_documented_functions() {
    local count=0
    if [[ -f "$API_DOC" ]]; then
        count=$(grep -c "^#### \`" "$API_DOC" 2>/dev/null || echo 0)
    fi
    echo "$count"
}

# Count functions by category
count_by_category() {
    echo "### Functions by Category"
    echo ""
    echo "| Category | Total | Documented | Coverage |"
    echo "|----------|-------|------------|----------|"

    # Core library
    local core_total core_doc
    core_total=$(grep -c "^[[:space:]]*\(function[[:space:]]\+\)\?[_a-zA-Z][_a-zA-Z0-9]*()[[:space:]]*{" "$LIB_DIR/core.zsh" 2>/dev/null || echo 0)
    core_doc=$(grep -c "^#### \`_flow_" "$API_DOC" 2>/dev/null || echo 0)
    local core_pct=$(awk "BEGIN {printf \"%.1f%%\", ($core_doc/$core_total)*100}")
    echo "| Core Library | $core_total | $core_doc | $core_pct |"

    # Dispatchers
    local disp_total=0
    while IFS= read -r file; do
        local file_count
        file_count=$(grep -c "^[[:space:]]*\(function[[:space:]]\+\)\?[_a-zA-Z][_a-zA-Z0-9]*()[[:space:]]*{" "$file" 2>/dev/null || echo 0)
        disp_total=$((disp_total + file_count))
    done < <(find "$LIB_DIR/dispatchers" -name "*.zsh" -type f 2>/dev/null)

    local disp_doc=$(grep -c "Dispatcher" "$PROJECT_ROOT/docs/reference/MASTER-DISPATCHER-GUIDE.md" 2>/dev/null || echo 12)
    local disp_pct=$(awk "BEGIN {printf \"%.1f%%\", ($disp_doc/12)*100}")
    echo "| Dispatchers | 12 | $disp_doc | $disp_pct |"

    # Git helpers
    if [[ -f "$LIB_DIR/git-helpers.zsh" ]]; then
        local git_total git_doc
        git_total=$(grep -c "^[[:space:]]*\(function[[:space:]]\+\)\?[_a-zA-Z][_a-zA-Z0-9]*()[[:space:]]*{" "$LIB_DIR/git-helpers.zsh" 2>/dev/null || echo 0)
        git_doc=$(grep -c "^#### \`_flow_git" "$API_DOC" 2>/dev/null || echo 0)
        local git_pct=$(awk "BEGIN {printf \"%.1f%%\", ($git_doc/$git_total)*100}")
        echo "| Git Helpers | $git_total | $git_doc | $git_pct |"
    fi

    # Keychain helpers
    if [[ -f "$LIB_DIR/keychain-helpers.zsh" ]]; then
        local keychain_total keychain_doc
        keychain_total=$(grep -c "^[[:space:]]*\(function[[:space:]]\+\)\?[_a-zA-Z][_a-zA-Z0-9]*()[[:space:]]*{" "$LIB_DIR/keychain-helpers.zsh" 2>/dev/null || echo 0)
        keychain_doc=$(grep -c "^#### \`_flow_keychain" "$API_DOC" 2>/dev/null || echo 0)
        local keychain_pct=$(awk "BEGIN {printf \"%.1f%%\", ($keychain_doc/$keychain_total)*100}")
        echo "| Keychain Helpers | $keychain_total | $keychain_doc | $keychain_pct |"
    fi

    # Teaching libraries
    local teach_total=0
    local teach_files=("concept-extraction.zsh" "prerequisite-checker.zsh" "analysis-cache.zsh" "report-generator.zsh" "ai-analysis.zsh" "slide-optimizer.zsh")
    for file in "${teach_files[@]}"; do
        if [[ -f "$LIB_DIR/$file" ]]; then
            local file_count
            file_count=$(grep -c "^[[:space:]]*\(function[[:space:]]\+\)\?[_a-zA-Z][_a-zA-Z0-9]*()[[:space:]]*{" "$LIB_DIR/$file" 2>/dev/null || echo 0)
            teach_total=$((teach_total + file_count))
        fi
    done
    local teach_doc=$(grep -c "^#### \`_teach" "$API_DOC" 2>/dev/null || echo 0)
    local teach_pct=$(awk "BEGIN {printf \"%.1f%%\", ($teach_doc/$teach_total)*100}")
    echo "| Teaching Libraries | $teach_total | $teach_doc | $teach_pct |"

    echo ""
}

# Find stale documentation (modified > 90 days ago)
find_stale_docs() {
    echo "### Stale Documentation (> 90 days)"
    echo ""

    local stale_count=0
    local cutoff_date=$(date -v-90d +%s 2>/dev/null || date -d "90 days ago" +%s)

    while IFS= read -r file; do
        local mod_time
        mod_time=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null)

        if [[ $mod_time -lt $cutoff_date ]]; then
            local days_old=$(( ($(date +%s) - mod_time) / 86400 ))
            echo "- ⚠️  \`$(basename "$file")\` (${days_old} days old)"
            stale_count=$((stale_count + 1))
        fi
    done < <(find "$DOCS_DIR" -name "*.md" -type f ! -path "*/.*")

    if [[ $stale_count -eq 0 ]]; then
        echo "✅ No stale documentation found"
    fi

    echo ""
}

# Generate missing documentation warnings
find_missing_docs() {
    echo "### Missing Documentation"
    echo ""

    # Check for undocumented dispatchers
    echo "**Dispatchers:**"
    echo ""
    local dispatcher_count=0
    while IFS= read -r file; do
        local dispatcher=$(basename "$file" .zsh | sed 's/-dispatcher//')
        if ! grep -q "## $dispatcher Dispatcher" "$PROJECT_ROOT/docs/reference/MASTER-DISPATCHER-GUIDE.md" 2>/dev/null; then
            echo "- ⚠️  Missing documentation: \`$dispatcher\` dispatcher"
            dispatcher_count=$((dispatcher_count + 1))
        fi
    done < <(find "$LIB_DIR/dispatchers" -name "*-dispatcher.zsh" -type f 2>/dev/null)

    if [[ $dispatcher_count -eq 0 ]]; then
        echo "✅ All dispatchers documented"
    fi
    echo ""

    # Check for commands without docs
    echo "**Commands:**"
    echo ""
    local command_count=0
    if [[ -d "$PROJECT_ROOT/commands" ]]; then
        while IFS= read -r file; do
            local cmd=$(basename "$file" .zsh)
            if [[ ! -f "$DOCS_DIR/commands/$cmd.md" ]] && [[ ! -f "$DOCS_DIR/reference/MASTER-API-REFERENCE.md" ]]; then
                echo "- ⚠️  Missing documentation: \`$cmd\` command"
                command_count=$((command_count + 1))
            fi
        done < <(find "$PROJECT_ROOT/commands" -name "*.zsh" -type f 2>/dev/null)
    fi

    if [[ $command_count -eq 0 ]]; then
        echo "✅ All commands documented"
    fi
    echo ""
}

# Generate the dashboard
generate_dashboard() {
    local total_functions documented_functions coverage_pct
    total_functions=$(count_total_functions)
    documented_functions=$(count_documented_functions)
    coverage_pct=$(awk "BEGIN {printf \"%.1f%%\", ($documented_functions/$total_functions)*100}")

    cat > "$DASHBOARD_FILE" << EOF
# Documentation Dashboard

**Auto-generated:** $(date +"%Y-%m-%d %H:%M")
**Status:** Tracking documentation coverage and health

---

## Overview

| Metric | Value |
|--------|-------|
| **Total Functions** | $total_functions |
| **Documented Functions** | $documented_functions |
| **Coverage** | $coverage_pct |
| **Target Coverage** | 80% |

**Coverage Progress:**
\`\`\`
[$( printf '%-50s' | tr ' ' '█' | head -c $(awk "BEGIN {print int(($documented_functions/$total_functions)*50)}"))]  $coverage_pct
\`\`\`

---

$(count_by_category)

---

$(find_stale_docs)

---

$(find_missing_docs)

---

## Quick Links

- [MASTER-API-REFERENCE.md](reference/MASTER-API-REFERENCE.md) - Complete API documentation
- [MASTER-DISPATCHER-GUIDE.md](reference/MASTER-DISPATCHER-GUIDE.md) - All 12 dispatchers
- [MASTER-ARCHITECTURE.md](reference/MASTER-ARCHITECTURE.md) - System architecture
- [QUICK-REFERENCE.md](help/QUICK-REFERENCE.md) - Command quick reference
- [TROUBLESHOOTING.md](help/TROUBLESHOOTING.md) - Common issues

---

## Improvement Priorities

EOF

    # Add priorities based on coverage
    if [[ $(echo "$coverage_pct < 50" | bc -l) -eq 1 ]]; then
        echo "1. 🔴 **CRITICAL:** Documentation coverage below 50%" >> "$DASHBOARD_FILE"
        echo "   - Focus on documenting core functions" >> "$DASHBOARD_FILE"
        echo "   - Run: \`./scripts/generate-api-docs.sh --dry-run\`" >> "$DASHBOARD_FILE"
    elif [[ $(echo "$coverage_pct < 80" | bc -l) -eq 1 ]]; then
        echo "1. 🟡 **MODERATE:** Documentation coverage below target (80%)" >> "$DASHBOARD_FILE"
        echo "   - Document high-use functions first" >> "$DASHBOARD_FILE"
        echo "   - Run: \`./scripts/generate-api-docs.sh --dry-run\`" >> "$DASHBOARD_FILE"
    else
        echo "1. 🟢 **GOOD:** Documentation coverage meets target" >> "$DASHBOARD_FILE"
        echo "   - Maintain current coverage level" >> "$DASHBOARD_FILE"
        echo "   - Keep documentation updated with code changes" >> "$DASHBOARD_FILE"
    fi

    echo "" >> "$DASHBOARD_FILE"
    echo "---" >> "$DASHBOARD_FILE"
    echo "" >> "$DASHBOARD_FILE"
    echo "**Last Updated:** $(date +"%Y-%m-%d %H:%M")" >> "$DASHBOARD_FILE"
    echo "**Generated by:** \`scripts/generate-doc-dashboard.sh\`" >> "$DASHBOARD_FILE"
}

main() {
    echo -e "${GREEN}Documentation Dashboard Generator${NC}"
    echo "==================================="
    echo ""

    echo -e "${BLUE}Analyzing documentation...${NC}"
    generate_dashboard

    echo -e "${GREEN}✓ Dashboard generated${NC}"
    echo ""
    echo "Output: $DASHBOARD_FILE"
    echo ""
    echo "Next steps:"
    echo "  1. Review dashboard: cat $DASHBOARD_FILE"
    echo "  2. Address missing documentation"
    echo "  3. Update stale files"
    echo "  4. Re-run weekly to track progress"
}

main "$@"
