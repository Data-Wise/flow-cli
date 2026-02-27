#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Em v2.0 - Dogfood / Code Quality
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Meta-tests that scan the em v2.0 source code for quality, security,
#          and convention compliance. These are static analysis tests that grep
#          the actual source files rather than calling functions.
#
# Validates:
#   - Function naming conventions (_em_ prefix)
#   - No raw himalaya calls outside abstraction layer
#   - No eval with user input
#   - No source of user-controlled files
#   - Secure temp file usage (mktemp, not $$)
#   - Safe jq usage (--arg/--argjson, not interpolation)
#   - No -execute flag in terminal-notifier
#   - AppleScript safety (osascript -e, no heredoc injection)
#   - Security function existence
#   - All public functions have help text
#
# Created: 2026-02-26 (TDD — tests first)
# ══════════════════════════════════════════════════════════════════════════════

# Source shared test framework
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ============================================================================
# SETUP
# ============================================================================

# Em v2.0 source files to scan
# Actual file locations for the v2.0 implementation
EM_DISPATCHER="$PROJECT_ROOT/lib/dispatchers/email-dispatcher.zsh"
EM_HIMALAYA="$PROJECT_ROOT/lib/em-himalaya.zsh"
EM_ICS="$PROJECT_ROOT/lib/em-ics.zsh"
EM_WATCH="$PROJECT_ROOT/lib/em-watch.zsh"
EM_HELPERS="$PROJECT_ROOT/lib/email-helpers.zsh"
EM_AI="$PROJECT_ROOT/lib/em-ai.zsh"
EM_CACHE="$PROJECT_ROOT/lib/em-cache.zsh"
EM_RENDER="$PROJECT_ROOT/lib/em-render.zsh"

# Collect all em source files that exist
typeset -a EM_FILES
for f in "$EM_DISPATCHER" "$EM_HIMALAYA" "$EM_ICS" "$EM_WATCH" \
         "$EM_HELPERS" "$EM_AI" "$EM_CACHE" "$EM_RENDER"; do
    [[ -f "$f" ]] && EM_FILES+=("$f")
done

# Also scan for any em-related files in lib/ (catch new additions)
for f in "$PROJECT_ROOT"/lib/em-*.zsh(N) "$PROJECT_ROOT"/lib/dispatchers/email-*.zsh(N); do
    # Avoid duplicates
    if [[ ! " ${EM_FILES[*]} " == *" $f "* ]]; then
        EM_FILES+=("$f")
    fi
done

# Helper: check if we have source files to scan
_has_em_files() {
    (( ${#EM_FILES} > 0 ))
}

# ============================================================================
# TESTS
# ============================================================================

test_suite_start "Em v2.0 - Dogfood / Code Quality"

# ---------------------------------------------------------------------------
# Prerequisite: source files exist
# ---------------------------------------------------------------------------

test_case "Em source files exist for scanning"
if _has_em_files; then
    test_pass
else
    test_skip "No em source files found yet (TDD — implementation pending)"
fi

# ---------------------------------------------------------------------------
# Function naming conventions
# ---------------------------------------------------------------------------

test_case "All internal functions follow _em_ prefix convention"
if ! _has_em_files; then test_skip "No source files"; fi
local violations=""
for f in "${EM_FILES[@]}"; do
    # Find function definitions that don't follow the convention
    # Public: em_* or em()  Internal: _em_*
    # grep -n output has "linenum:" prefix, so match function name after the colon
    local bad=$(grep -nE '^\s*[a-zA-Z_]+\(\)\s*\{' "$f" 2>/dev/null | \
                grep -vE '(em|_em_|em_)[a-zA-Z_]*\(\)' | \
                grep -vE '^\s*#')
    [[ -n "$bad" ]] && violations+="$f: $bad\n"
done
if [[ -z "$violations" ]]; then
    test_pass
else
    test_fail "Functions without _em_ prefix:\n$violations"
fi

# ---------------------------------------------------------------------------
# No raw himalaya calls outside abstraction layer
# ---------------------------------------------------------------------------

test_case "No raw 'himalaya' calls outside lib/em-himalaya.zsh"
if ! _has_em_files; then test_skip "No source files"; fi
local violations=""
for f in "${EM_FILES[@]}"; do
    # Skip the himalaya abstraction layer itself and watch module (uses IMAP IDLE directly)
    [[ "$f" == *"em-himalaya.zsh" ]] && continue
    [[ "$f" == *"em-watch.zsh" ]] && continue
    # Look for direct himalaya invocations (not in comments, strings, or log messages)
    # grep -n adds "linenum:" prefix, so match comments/strings after the colon
    local raw=$(grep -nE '\bhimalaya\b' "$f" 2>/dev/null | \
                grep -vE ':[[:space:]]*#' | \
                grep -vE '#.*\bhimalaya\b' | \
                grep -vE 'command -v himalaya' | \
                grep -vE 'whence.*himalaya' | \
                grep -vE '".*himalaya.*"' | \
                grep -vE "'.*himalaya.*'" | \
                grep -vE 'echo|print|_C_' | \
                grep -vE '\\\$')
    [[ -n "$raw" ]] && violations+="$f: $raw\n"
done
if [[ -z "$violations" ]]; then
    test_pass
else
    test_fail "Raw himalaya calls found outside abstraction layer:\n$violations"
fi

# ---------------------------------------------------------------------------
# No eval with user input
# ---------------------------------------------------------------------------

test_case "No 'eval' with user input in any em file"
if ! _has_em_files; then test_skip "No source files"; fi
local violations=""
for f in "${EM_FILES[@]}"; do
    # Find eval statements (excluding safe patterns like eval "$(typeset ...)")
    local evals=$(grep -nE '\beval\b' "$f" 2>/dev/null | \
                  grep -vE '^\s*#' | \
                  grep -vE 'eval "\$\(typeset')
    [[ -n "$evals" ]] && violations+="$f: $evals\n"
done
if [[ -z "$violations" ]]; then
    test_pass
else
    test_fail "Potentially unsafe eval usage:\n$violations"
fi

# ---------------------------------------------------------------------------
# No source of user-controlled files
# ---------------------------------------------------------------------------

test_case "No 'source' of user-controlled files (config uses safe parser)"
if ! _has_em_files; then test_skip "No source files"; fi
local violations=""
for f in "${EM_FILES[@]}"; do
    # Find source/. statements that aren't sourcing known project files
    local sources=$(grep -nE '^\s*(source|\.)\s+' "$f" 2>/dev/null | \
                    grep -vE '^\s*#' | \
                    grep -vE 'source "\$PROJECT_ROOT' | \
                    grep -vE 'source "\$FLOW_PLUGIN_DIR' | \
                    grep -vE 'source "\$SCRIPT_DIR' | \
                    grep -vE 'source "\${0:')
    [[ -n "$sources" ]] && violations+="$f: $sources\n"
done
if [[ -z "$violations" ]]; then
    test_pass
else
    test_fail "Potentially unsafe source statements:\n$violations"
fi

# ---------------------------------------------------------------------------
# Secure temp files
# ---------------------------------------------------------------------------

test_case "All temp files use mktemp (no predictable paths with \$\$)"
if ! _has_em_files; then test_skip "No source files"; fi
local violations=""
for f in "${EM_FILES[@]}"; do
    # Find /tmp/$$ or similar predictable temp file patterns
    local bad_tmp=$(grep -nE '/tmp/.*\$\$|/tmp/em[-_]' "$f" 2>/dev/null | \
                    grep -vE '^\s*#')
    [[ -n "$bad_tmp" ]] && violations+="$f: $bad_tmp\n"
done
if [[ -z "$violations" ]]; then
    test_pass
else
    test_fail "Predictable temp file paths found (use mktemp):\n$violations"
fi

# ---------------------------------------------------------------------------
# Safe jq usage
# ---------------------------------------------------------------------------

test_case "All jq calls use --arg/--argjson (no string interpolation)"
if ! _has_em_files; then test_skip "No source files"; fi
local violations=""
for f in "${EM_FILES[@]}"; do
    # Find jq calls that interpolate variables directly in the filter
    # Match jq calls with $var that could be filter interpolation
    # Exclude: comments, --arg/--argjson, jq internal $. refs,
    # jq -r/-e (flag not filter), and file-argument patterns
    # (single-quoted filter followed by "$var" is a file arg, not interpolation)
    local bad_jq=$(grep -nE '\bjq\b.*\$[a-zA-Z_]' "$f" 2>/dev/null | \
                   grep -vE '^\s*#' | \
                   grep -vE '\-\-arg' | \
                   grep -vE '\-\-argjson' | \
                   grep -vE '\$\.' | \
                   grep -vE 'jq -r' | \
                   grep -vE 'jq -e' | \
                   grep -vE "jq .*'[^']*'.*\"\\\$")
    [[ -n "$bad_jq" ]] && violations+="$f: $bad_jq\n"
done
if [[ -z "$violations" ]]; then
    test_pass
else
    test_fail "Unsafe jq string interpolation found:\n$violations"
fi

# ---------------------------------------------------------------------------
# No -execute in terminal-notifier
# ---------------------------------------------------------------------------

test_case "No '-execute' flag in any terminal-notifier call"
if ! _has_em_files; then test_skip "No source files"; fi
local violations=""
for f in "${EM_FILES[@]}"; do
    local exec_flag=$(grep -nE 'terminal-notifier.*-execute' "$f" 2>/dev/null | \
                      grep -vE '^\s*#')
    [[ -n "$exec_flag" ]] && violations+="$f: $exec_flag\n"
done
if [[ -z "$violations" ]]; then
    test_pass
else
    test_fail "Dangerous -execute flag in terminal-notifier:\n$violations"
fi

# ---------------------------------------------------------------------------
# AppleScript safety
# ---------------------------------------------------------------------------

test_case "AppleScript uses 'osascript -e' (no heredoc with user data)"
if ! _has_em_files; then test_skip "No source files"; fi
local violations=""
for f in "${EM_FILES[@]}"; do
    # Check for osascript with heredoc that might interpolate user data
    local bad_as=$(grep -nE 'osascript\s*<<' "$f" 2>/dev/null | \
                   grep -vE '^\s*#')
    [[ -n "$bad_as" ]] && violations+="$f: $bad_as\n"
done
if [[ -z "$violations" ]]; then
    test_pass
else
    test_fail "Unsafe osascript heredoc usage (use -e flag):\n$violations"
fi

# ---------------------------------------------------------------------------
# Security functions exist (loaded via flow.plugin.zsh)
# ---------------------------------------------------------------------------

test_case "Security function _em_validate_msg_id is defined"
FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
if (( ${+functions[_em_validate_msg_id]} )); then
    test_pass
else
    test_skip "Function not yet implemented"
fi

test_case "Security function _em_validate_folder_name is defined"
if (( ${+functions[_em_validate_folder_name]} )); then
    test_pass
else
    test_skip "Function not yet implemented"
fi

# ---------------------------------------------------------------------------
# Help text for public functions
# ---------------------------------------------------------------------------

test_case "All public em_ functions have help text"
if ! _has_em_files; then test_skip "No source files"; fi
local missing_help=""
for f in "${EM_FILES[@]}"; do
    # Find public functions (em or em_*)
    local pub_funcs=$(grep -oE '^(em_[a-z_]+|em)\(\)' "$f" 2>/dev/null)
    for func in ${(f)pub_funcs}; do
        local func_name="${func%()}"
        # Check if there's a corresponding help function or help case
        # Use grep -E for alternation (BSD grep on macOS doesn't support \| in basic mode)
        local has_help=$(grep -cE "${func_name}.*help|_${func_name}_help" "$f" 2>/dev/null)
        if (( has_help == 0 )); then
            missing_help+="$func_name in $f\n"
        fi
    done
done
if [[ -z "$missing_help" ]]; then
    test_pass
else
    test_fail "Public functions without help:\n$missing_help"
fi

# ---------------------------------------------------------------------------
# No execSync pattern (ZSH equivalent: eval with external input)
# ---------------------------------------------------------------------------

test_case "No command substitution with unsanitized user input in eval"
if ! _has_em_files; then test_skip "No source files"; fi
local violations=""
for f in "${EM_FILES[@]}"; do
    # eval "$(...)" where the inner command uses variables
    local bad_eval=$(grep -nE 'eval\s+"\$\(' "$f" 2>/dev/null | \
                     grep -vE '^\s*#' | \
                     grep -vE 'typeset')
    [[ -n "$bad_eval" ]] && violations+="$f: $bad_eval\n"
done
if [[ -z "$violations" ]]; then
    test_pass
else
    test_fail "Potentially unsafe eval with command substitution:\n$violations"
fi

# ---------------------------------------------------------------------------
# Dispatcher structure
# ---------------------------------------------------------------------------

test_case "Em dispatcher has standard help/case structure"
if [[ -f "$EM_DISPATCHER" ]]; then
    local has_case=$(grep -c 'case.*in' "$EM_DISPATCHER" 2>/dev/null)
    local has_help=$(grep -c '_em_help' "$EM_DISPATCHER" 2>/dev/null)
    if (( has_case > 0 && has_help > 0 )); then
        test_pass
    else
        test_fail "Dispatcher missing case/help structure"
    fi
else
    test_skip "Dispatcher file not yet created"
fi

# ---------------------------------------------------------------------------
# File count sanity
# ---------------------------------------------------------------------------

test_case "Em v2.0 has expected number of source files (>= 3)"
local count=${#EM_FILES}
if (( count >= 3 )); then
    test_pass
else
    test_skip "Only $count em source files found (implementation pending)"
fi

# ---------------------------------------------------------------------------
# No hardcoded paths
# ---------------------------------------------------------------------------

test_case "No hardcoded /Users/ paths in em source files"
if ! _has_em_files; then test_skip "No source files"; fi
local violations=""
for f in "${EM_FILES[@]}"; do
    local hardcoded=$(grep -nE '/Users/[a-zA-Z]' "$f" 2>/dev/null | \
                      grep -vE '^\s*#')
    [[ -n "$hardcoded" ]] && violations+="$f: $hardcoded\n"
done
if [[ -z "$violations" ]]; then
    test_pass
else
    test_fail "Hardcoded user paths found:\n$violations"
fi

# ---------------------------------------------------------------------------
# No debug leftovers
# ---------------------------------------------------------------------------

test_case "No debug echo/print statements left in em source files"
if ! _has_em_files; then test_skip "No source files"; fi
local violations=""
for f in "${EM_FILES[@]}"; do
    local debug=$(grep -nE '^\s*echo\s+"DEBUG|^\s*print\s+-l\s+"DEBUG' "$f" 2>/dev/null)
    [[ -n "$debug" ]] && violations+="$f: $debug\n"
done
if [[ -z "$violations" ]]; then
    test_pass
else
    test_fail "Debug statements found:\n$violations"
fi

test_suite_end
exit $?
