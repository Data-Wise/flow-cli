#!/usr/bin/env bash
#
# check-doc-updates.sh - Detect code changes and suggest documentation updates
#
# Usage:
#   ./scripts/check-doc-updates.sh [--since COMMIT]
#
# Options:
#   --since COMMIT   Check changes since specific commit (default: HEAD~10)
#
# Purpose:
#   Analyzes recent code changes and warns about potentially outdated documentation
#   - Detects new functions (suggest adding to API reference)
#   - Detects modified functions (suggest reviewing docs)
#   - Detects removed functions (suggest removing from docs)
#   - Checks if related documentation was updated

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly API_DOC="$PROJECT_ROOT/docs/reference/MASTER-API-REFERENCE.md"
readonly DISPATCHER_DOC="$PROJECT_ROOT/docs/reference/MASTER-DISPATCHER-GUIDE.md"

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Parse command line options
SINCE_COMMIT="HEAD~10"

while [[ $# -gt 0 ]]; do
    case $1 in
        --since)
            SINCE_COMMIT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Extract function names from a file
extract_functions() {
    local file="$1"
    grep -oP '^\s*(function\s+)?[_a-zA-Z][_a-zA-Z0-9]*(?=\(\))' "$file" 2>/dev/null || true
}

# Check if function is documented
is_documented() {
    local func_name="$1"
    grep -q "^#### \`${func_name}\`" "$API_DOC" 2>/dev/null || \
    grep -q "^### \`${func_name}" "$DISPATCHER_DOC" 2>/dev/null
}

# Detect new functions
detect_new_functions() {
    echo -e "${BLUE}Checking for new functions...${NC}"
    echo ""

    local new_count=0

    # Get changed files
    while IFS= read -r file; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        # Get functions added in recent commits
        local added_functions
        added_functions=$(git diff "$SINCE_COMMIT" HEAD -- "$file" 2>/dev/null | \
            grep -oP '^\+\s*(function\s+)?[_a-zA-Z][_a-zA-Z0-9]*(?=\(\))' | \
            sed 's/^+\s*//' || true)

        if [[ -n "$added_functions" ]]; then
            while IFS= read -r func; do
                if [[ -n "$func" ]] && ! is_documented "$func"; then
                    echo -e "  ${YELLOW}⚠️  New function:${NC} \`$func\` in $(basename "$file")"
                    echo "     → Add to docs/reference/MASTER-API-REFERENCE.md"
                    echo ""
                    new_count=$((new_count + 1))
                fi
            done <<< "$added_functions"
        fi
    done < <(git diff --name-only "$SINCE_COMMIT" HEAD -- 'lib/*.zsh' 'lib/dispatchers/*.zsh' 'commands/*.zsh' 2>/dev/null)

    if [[ $new_count -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} No undocumented new functions"
    else
        echo -e "  ${YELLOW}Found $new_count new undocumented function(s)${NC}"
    fi
    echo ""
}

# Detect modified functions
detect_modified_functions() {
    echo -e "${BLUE}Checking for modified functions...${NC}"
    echo ""

    local modified_count=0

    # Get changed files
    while IFS= read -r file; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        # Get current functions
        local current_functions
        current_functions=$(extract_functions "$file")

        if [[ -z "$current_functions" ]]; then
            continue
        fi

        # Check if function bodies changed
        while IFS= read -r func; do
            if [[ -z "$func" ]]; then
                continue
            fi

            # Check if function was modified
            if git diff "$SINCE_COMMIT" HEAD -- "$file" 2>/dev/null | \
               grep -A5 "^[+-].*${func}()" | grep -q "^[+-]"; then

                if is_documented "$func"; then
                    echo -e "  ${YELLOW}⚠️  Modified function:${NC} \`$func\` in $(basename "$file")"
                    echo "     → Review documentation for accuracy"
                    echo ""
                    modified_count=$((modified_count + 1))
                fi
            fi
        done <<< "$current_functions"
    done < <(git diff --name-only "$SINCE_COMMIT" HEAD -- 'lib/*.zsh' 'lib/dispatchers/*.zsh' 'commands/*.zsh' 2>/dev/null)

    if [[ $modified_count -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} No documentation review needed for modified functions"
    else
        echo -e "  ${YELLOW}Found $modified_count modified documented function(s)${NC}"
    fi
    echo ""
}

# Detect removed functions
detect_removed_functions() {
    echo -e "${BLUE}Checking for removed functions...${NC}"
    echo ""

    local removed_count=0

    # Get changed files
    while IFS= read -r file; do
        # Get functions removed in recent commits
        local removed_functions
        removed_functions=$(git diff "$SINCE_COMMIT" HEAD -- "$file" 2>/dev/null | \
            grep -oP '^\-\s*(function\s+)?[_a-zA-Z][_a-zA-Z0-9]*(?=\(\))' | \
            sed 's/^-\s*//' || true)

        if [[ -n "$removed_functions" ]]; then
            while IFS= read -r func; do
                if [[ -n "$func" ]] && is_documented "$func"; then
                    echo -e "  ${RED}⚠️  Removed function:${NC} \`$func\` from $(basename "$file")"
                    echo "     → Remove from documentation"
                    echo ""
                    removed_count=$((removed_count + 1))
                fi
            done <<< "$removed_functions"
        fi
    done < <(git diff --name-only "$SINCE_COMMIT" HEAD -- 'lib/*.zsh' 'lib/dispatchers/*.zsh' 'commands/*.zsh' 2>/dev/null)

    if [[ $removed_count -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} No obsolete documentation detected"
    else
        echo -e "  ${RED}Found $removed_count removed function(s) still in docs${NC}"
    fi
    echo ""
}

# Check dispatcher changes
check_dispatcher_changes() {
    echo -e "${BLUE}Checking dispatcher changes...${NC}"
    echo ""

    local dispatcher_changes=0

    while IFS= read -r file; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        local dispatcher_name
        dispatcher_name=$(basename "$file" .zsh | sed 's/-dispatcher//')

        if git diff "$SINCE_COMMIT" HEAD --stat -- "$file" 2>/dev/null | grep -q .; then
            # Check if dispatcher help was updated
            if ! git diff "$SINCE_COMMIT" HEAD -- "$DISPATCHER_DOC" 2>/dev/null | \
               grep -q "## ${dispatcher_name} Dispatcher"; then
                echo -e "  ${YELLOW}⚠️  Dispatcher modified:${NC} \`$dispatcher_name\`"
                echo "     → Update docs/reference/MASTER-DISPATCHER-GUIDE.md"
                echo ""
                dispatcher_changes=$((dispatcher_changes + 1))
            fi
        fi
    done < <(git diff --name-only "$SINCE_COMMIT" HEAD -- 'lib/dispatchers/*.zsh' 2>/dev/null)

    if [[ $dispatcher_changes -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} No dispatcher documentation updates needed"
    else
        echo -e "  ${YELLOW}Found $dispatcher_changes dispatcher(s) needing doc review${NC}"
    fi
    echo ""
}

# Check command changes
check_command_changes() {
    echo -e "${BLUE}Checking command changes...${NC}"
    echo ""

    local command_changes=0

    while IFS= read -r file; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        local cmd_name
        cmd_name=$(basename "$file" .zsh)

        if git diff "$SINCE_COMMIT" HEAD --stat -- "$file" 2>/dev/null | grep -q .; then
            echo -e "  ${YELLOW}⚠️  Command modified:${NC} \`$cmd_name\`"
            echo "     → Review docs/commands/${cmd_name}.md or QUICK-REFERENCE.md"
            echo ""
            command_changes=$((command_changes + 1))
        fi
    done < <(git diff --name-only "$SINCE_COMMIT" HEAD -- 'commands/*.zsh' 2>/dev/null)

    if [[ $command_changes -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} No command documentation updates needed"
    else
        echo -e "  ${YELLOW}Found $command_changes command(s) needing doc review${NC}"
    fi
    echo ""
}

# Generate summary
generate_summary() {
    echo "---"
    echo ""
    echo -e "${BLUE}Summary${NC}"
    echo ""

    local total_warnings=0

    # Count warnings from each category
    local new_count=$(detect_new_functions 2>&1 | grep -c "⚠️" || echo 0)
    local modified_count=$(detect_modified_functions 2>&1 | grep -c "⚠️" || echo 0)
    local removed_count=$(detect_removed_functions 2>&1 | grep -c "⚠️" || echo 0)
    local dispatcher_count=$(check_dispatcher_changes 2>&1 | grep -c "⚠️" || echo 0)
    local command_count=$(check_command_changes 2>&1 | grep -c "⚠️" || echo 0)

    total_warnings=$((new_count + modified_count + removed_count + dispatcher_count + command_count))

    if [[ $total_warnings -eq 0 ]]; then
        echo -e "${GREEN}✅ All documentation is up to date${NC}"
        echo ""
        echo "No documentation updates needed based on recent code changes."
    else
        echo -e "${YELLOW}⚠️  $total_warnings documentation warning(s) found${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Review warnings above"
        echo "  2. Update affected documentation"
        echo "  3. Run: ./scripts/generate-api-docs.sh --dry-run"
        echo "  4. Run: ./scripts/generate-doc-dashboard.sh"
    fi
    echo ""
}

main() {
    echo -e "${GREEN}Documentation Update Checker${NC}"
    echo "============================"
    echo ""
    echo "Checking changes since: $SINCE_COMMIT"
    echo ""
    echo "---"
    echo ""

    # Run all checks
    detect_new_functions
    detect_modified_functions
    detect_removed_functions
    check_dispatcher_changes
    check_command_changes

    # Show summary
    generate_summary

    echo "---"
    echo ""
    echo "Tip: Run with --since <commit> to check specific range"
    echo "Example: ./scripts/check-doc-updates.sh --since v5.16.0"
}

main "$@"
