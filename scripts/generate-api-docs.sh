#!/usr/bin/env bash
#
# generate-api-docs.sh - Auto-generate API reference from lib/*.zsh
#
# Usage:
#   ./scripts/generate-api-docs.sh [--dry-run] [--file FILE]
#
# Options:
#   --dry-run    Show what would be generated without modifying files
#   --file FILE  Process only specific file instead of all lib/*.zsh
#
# Purpose:
#   Extracts function signatures, parameters, and descriptions from ZSH library files
#   and generates API documentation entries
#
# Output:
#   Prints generated API documentation to stdout (use --dry-run to preview)
#   Updates docs/reference/MASTER-API-REFERENCE.md function index when run normally

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly LIB_DIR="$PROJECT_ROOT/lib"
readonly API_DOC="$PROJECT_ROOT/docs/reference/MASTER-API-REFERENCE.md"

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Parse command line options
DRY_RUN=0
SPECIFIC_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --file)
            SPECIFIC_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Extract function documentation from a ZSH file
# Args: $1 - file path
extract_function_docs() {
    local file="$1"
    local in_doc_block=0
    local current_function=""
    local doc_lines=()
    local func_name=""
    local func_purpose=""
    local func_args=()
    local func_returns=""
    local func_examples=()
    local func_notes=""

    echo -e "${BLUE}Processing: ${file}${NC}" >&2

    while IFS= read -r line; do
        # Detect start of documentation block
        if [[ "$line" =~ ^#[[:space:]]*=+$ ]]; then
            in_doc_block=1
            doc_lines=()
            func_name=""
            func_purpose=""
            func_args=()
            func_returns=""
            func_examples=()
            func_notes=""
            continue
        fi

        # Inside documentation block
        if [[ $in_doc_block -eq 1 ]]; then
            # End of doc block (next separator or function definition)
            if [[ "$line" =~ ^#[[:space:]]*=+$ ]]; then
                in_doc_block=2  # Ready for function
                continue
            fi

            # Parse documentation sections
            if [[ "$line" =~ ^#[[:space:]]*Function:[[:space:]]*(.+)$ ]]; then
                func_name="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^#[[:space:]]*Purpose:[[:space:]]*(.+)$ ]]; then
                func_purpose="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^#[[:space:]]*Arguments:[[:space:]]*$ ]]; then
                # Start collecting arguments
                local reading_args=1
                continue
            elif [[ "$line" =~ ^#[[:space:]]*\$[0-9@]+[[:space:]]*-[[:space:]]*(.+)$ ]]; then
                func_args+=("${BASH_REMATCH[0]#\# }")
            elif [[ "$line" =~ ^#[[:space:]]*Returns:[[:space:]]*$ ]]; then
                # Start collecting returns
                continue
            elif [[ "$line" =~ ^#[[:space:]]*[0-9]+[[:space:]]*-[[:space:]]*(.+)$ ]] && [[ ${#func_args[@]} -gt 0 ]]; then
                func_returns+="${BASH_REMATCH[0]#\# }"$'\n'
            elif [[ "$line" =~ ^#[[:space:]]*Example:[[:space:]]*$ ]]; then
                # Start collecting examples
                continue
            elif [[ "$line" =~ ^#[[:space:]]{2,}(.+)$ ]] && [[ ${#func_examples[@]} -eq 0 || -n "${func_examples[*]}" ]]; then
                func_examples+=("${BASH_REMATCH[1]}")
            elif [[ "$line" =~ ^#[[:space:]]*Notes:[[:space:]]*$ ]]; then
                continue
            elif [[ "$line" =~ ^#[[:space:]]*-[[:space:]]*(.+)$ ]] && [[ -n "$func_name" ]]; then
                func_notes+="${BASH_REMATCH[1]}"$'\n'
            fi
        fi

        # Function definition found
        if [[ $in_doc_block -eq 2 ]] && [[ "$line" =~ ^(function[[:space:]]+)?([_a-zA-Z][_a-zA-Z0-9]*)\(\) ]]; then
            current_function="${BASH_REMATCH[2]}"

            # Generate API documentation entry
            if [[ -n "$func_name" ]] && [[ "$func_name" == "$current_function" ]]; then
                generate_api_entry "$current_function" "$func_purpose" "${func_args[*]}" "$func_returns" "${func_examples[*]}" "$func_notes"
            fi

            # Reset for next function
            in_doc_block=0
            func_name=""
            func_purpose=""
            func_args=()
            func_returns=""
            func_examples=()
            func_notes=""
        fi

    done < "$file"
}

# Generate API documentation entry
# Args: $1=name, $2=purpose, $3=args, $4=returns, $5=examples, $6=notes
generate_api_entry() {
    local name="$1"
    local purpose="$2"
    local args="$3"
    local returns="$4"
    local examples="$5"
    local notes="$6"

    echo ""
    echo "#### \`${name}\`"
    echo ""
    echo "$purpose"
    echo ""
    echo "**Signature:**"
    echo '```zsh'
    echo "${name}"
    echo '```'
    echo ""

    if [[ -n "$args" ]]; then
        echo "**Parameters:**"
        echo "$args" | while IFS= read -r arg; do
            if [[ -n "$arg" ]]; then
                echo "- $arg"
            fi
        done
        echo ""
    fi

    if [[ -n "$returns" ]]; then
        echo "**Returns:**"
        echo "$returns" | while IFS= read -r ret; do
            if [[ -n "$ret" ]]; then
                echo "- $ret"
            fi
        done
        echo ""
    fi

    if [[ -n "$examples" ]]; then
        echo "**Example:**"
        echo '```zsh'
        echo "$examples"
        echo '```'
        echo ""
    fi

    if [[ -n "$notes" ]]; then
        echo "**Notes:**"
        echo "$notes" | while IFS= read -r note; do
            if [[ -n "$note" ]]; then
                echo "- $note"
            fi
        done
        echo ""
    fi

    echo "---"
}

# Count functions in library files
count_functions() {
    local count=0

    if [[ -n "$SPECIFIC_FILE" ]]; then
        count=$(grep -c "^[[:space:]]*\(function[[:space:]]\+\)\?[_a-zA-Z][_a-zA-Z0-9]*()[[:space:]]*{" "$SPECIFIC_FILE" 2>/dev/null || echo 0)
    else
        while IFS= read -r file; do
            local file_count
            file_count=$(grep -c "^[[:space:]]*\(function[[:space:]]\+\)\?[_a-zA-Z][_a-zA-Z0-9]*()[[:space:]]*{" "$file" 2>/dev/null || echo 0)
            count=$((count + file_count))
        done < <(find "$LIB_DIR" -name "*.zsh" -type f)
    fi

    echo "$count"
}

# Count documented functions
count_documented() {
    local count=0

    if [[ -f "$API_DOC" ]]; then
        count=$(grep -c "^#### \`" "$API_DOC" 2>/dev/null || echo 0)
    fi

    echo "$count"
}

main() {
    echo -e "${GREEN}API Documentation Generator${NC}"
    echo "==========================="
    echo ""

    # Count functions
    local total_functions
    local documented_functions
    total_functions=$(count_functions)
    documented_functions=$(count_documented)

    echo -e "${BLUE}Statistics:${NC}"
    echo "  Total functions: $total_functions"
    echo "  Documented: $documented_functions"
    echo "  Coverage: $(awk "BEGIN {printf \"%.1f\", ($documented_functions/$total_functions)*100}")%"
    echo ""

    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "${YELLOW}DRY RUN MODE - No files will be modified${NC}"
        echo ""
    fi

    # Process files
    if [[ -n "$SPECIFIC_FILE" ]]; then
        if [[ ! -f "$SPECIFIC_FILE" ]]; then
            echo "Error: File not found: $SPECIFIC_FILE" >&2
            exit 1
        fi
        extract_function_docs "$SPECIFIC_FILE"
    else
        while IFS= read -r file; do
            extract_function_docs "$file"
        done < <(find "$LIB_DIR" -name "*.zsh" -type f | sort)
    fi

    echo ""
    echo -e "${GREEN}✓ Generation complete${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review generated documentation above"
    echo "  2. Copy relevant entries to $API_DOC"
    echo "  3. Update function index alphabetically"
    echo "  4. Run: mkdocs build (to test)"
}

main "$@"
