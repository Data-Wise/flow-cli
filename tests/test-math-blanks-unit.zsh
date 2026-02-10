#!/usr/bin/env zsh
# test-math-blanks-unit.zsh - Unit tests for _check_math_blanks()
# Tests the pure-ZSH state machine that detects blank lines inside $$ blocks

# Test framework setup
PASS=0
FAIL=0
SKIP=0

_test_pass() { ((PASS++)); echo "  ✅ $1"; }
_test_fail() { ((FAIL++)); echo "  ❌ $1: $2"; }
_test_skip() { ((SKIP++)); echo "  ⏭️  $1 (skipped)"; }

# ============================================================================
# SETUP
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
TEST_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Source the function under test
source "$PROJECT_ROOT/lib/dispatchers/teach-deploy-enhanced.zsh" 2>/dev/null || true

# Minimal FLOW_COLORS for non-interactive tests
typeset -gA FLOW_COLORS
FLOW_COLORS[info]=""
FLOW_COLORS[success]=""
FLOW_COLORS[error]=""
FLOW_COLORS[warn]=""
FLOW_COLORS[dim]=""
FLOW_COLORS[bold]=""
FLOW_COLORS[reset]=""
FLOW_COLORS[prompt]=""
FLOW_COLORS[muted]=""

# Stub _teach_error if not loaded
if ! typeset -f _teach_error >/dev/null 2>&1; then
    _teach_error() { : ; }
fi

# Verify function exists
if ! typeset -f _check_math_blanks >/dev/null 2>&1; then
    echo "❌ FATAL: _check_math_blanks not found after sourcing"
    exit 1
fi

# ============================================================================
# TESTS
# ============================================================================

echo ""
echo "╭─────────────────────────────────────────────────╮"
echo "│  Math Blank-Line Detection Tests                │"
echo "╰─────────────────────────────────────────────────╯"
echo ""

# --- Test 1: Clean file (no math) ---
test_no_math() {
    local f="$TEST_DIR/no-math.qmd"
    cat > "$f" <<'EOF'
# Introduction

Some regular text here.

More text with no math at all.
EOF
    if _check_math_blanks "$f"; then
        _test_pass "No math blocks → clean"
    else
        _test_fail "No math blocks → clean" "returned 1 unexpectedly"
    fi
}

# --- Test 2: Clean math (no blank lines inside $$) ---
test_clean_math() {
    local f="$TEST_DIR/clean-math.qmd"
    cat > "$f" <<'EOF'
# Lecture

$$
\bar{X} = \frac{1}{n} \sum_{i=1}^{n} X_i
$$

Some text between blocks.

$$
\sigma^2 = E[(X - \mu)^2]
$$
EOF
    if _check_math_blanks "$f"; then
        _test_pass "Clean math blocks → clean"
    else
        _test_fail "Clean math blocks → clean" "returned 1 unexpectedly"
    fi
}

# --- Test 3: Blank line inside $$ block ---
test_blank_in_math() {
    local f="$TEST_DIR/blank-in-math.qmd"
    cat > "$f" <<'EOF'
# Lecture

$$
\bar{X} = \frac{1}{n}

\sum_{i=1}^{n} X_i
$$
EOF
    if _check_math_blanks "$f"; then
        _test_fail "Blank in math → detected" "returned 0 (missed blank line)"
    else
        _test_pass "Blank in math → detected"
    fi
}

# --- Test 4: Multiple $$ blocks, blank in second ---
test_blank_in_second_block() {
    local f="$TEST_DIR/second-block.qmd"
    cat > "$f" <<'EOF'
$$
x + y = z
$$

Some text.

$$
a = b

c = d
$$
EOF
    if _check_math_blanks "$f"; then
        _test_fail "Blank in second block → detected" "returned 0 (missed blank line)"
    else
        _test_pass "Blank in second block → detected"
    fi
}

# --- Test 5: Blank lines outside $$ are fine ---
test_blank_outside_math() {
    local f="$TEST_DIR/blank-outside.qmd"
    cat > "$f" <<'EOF'
# Title

Some text.

$$
x = 1
$$

More text.

Even more.
EOF
    if _check_math_blanks "$f"; then
        _test_pass "Blanks outside math → clean"
    else
        _test_fail "Blanks outside math → clean" "returned 1 unexpectedly"
    fi
}

# --- Test 6: Nonexistent file returns clean ---
test_nonexistent_file() {
    if _check_math_blanks "$TEST_DIR/does-not-exist.qmd"; then
        _test_pass "Nonexistent file → clean (skipped)"
    else
        _test_fail "Nonexistent file → clean" "returned 1 unexpectedly"
    fi
}

# --- Test 7: Empty file returns clean ---
test_empty_file() {
    local f="$TEST_DIR/empty.qmd"
    : > "$f"
    if _check_math_blanks "$f"; then
        _test_pass "Empty file → clean"
    else
        _test_fail "Empty file → clean" "returned 1 unexpectedly"
    fi
}

# --- Test 8: Inline $$ on same line (not display math) ---
test_inline_dollar_signs() {
    local f="$TEST_DIR/inline.qmd"
    cat > "$f" <<'EOF'
We know that $$ x = 1 $$ is a constant.

And also $\alpha = 0.05$.
EOF
    if _check_math_blanks "$f"; then
        _test_pass "Inline \$\$ (not standalone) → clean"
    else
        _test_fail "Inline \$\$ (not standalone) → clean" "returned 1 unexpectedly"
    fi
}

# --- Test 9: $$ with leading/trailing spaces ---
test_padded_delimiters() {
    local f="$TEST_DIR/padded.qmd"
    cat > "$f" <<'EOF'
# Lecture

  $$
x = 1

y = 2
  $$
EOF
    if _check_math_blanks "$f"; then
        _test_fail "Padded \$\$ with blank → detected" "returned 0 (missed blank)"
    else
        _test_pass "Padded \$\$ with blank → detected"
    fi
}

# --- Test 10: Unclosed $$ block (odd count, no blanks inside) ---
test_unclosed_block() {
    local f="$TEST_DIR/unclosed.qmd"
    cat > "$f" <<'EOF'
# Lecture

$$
x = 1
y = 2
More text after forgotten closing delimiter.
EOF
    _check_math_blanks "$f"
    local rc=$?
    if [[ $rc -eq 2 ]]; then
        _test_pass "Unclosed \$\$ block → rc=2"
    else
        _test_fail "Unclosed \$\$ block → rc=2" "got rc=$rc"
    fi
}

# --- Test 10b: Unclosed + blank → blank detected first (rc=1) ---
test_unclosed_with_blank() {
    local f="$TEST_DIR/unclosed-blank.qmd"
    cat > "$f" <<'EOF'
$$
x = 1

y = 2
EOF
    _check_math_blanks "$f"
    local rc=$?
    if [[ $rc -eq 1 ]]; then
        _test_pass "Unclosed + blank → blank wins (rc=1)"
    else
        _test_fail "Unclosed + blank → blank wins (rc=1)" "got rc=$rc"
    fi
}

# --- Test 11: Properly closed blocks return 0 ---
test_closed_blocks() {
    local f="$TEST_DIR/closed.qmd"
    cat > "$f" <<'EOF'
$$
a = 1
$$

$$
b = 2
$$

$$
c = 3
$$
EOF
    _check_math_blanks "$f"
    local rc=$?
    if [[ $rc -eq 0 ]]; then
        _test_pass "Three closed blocks → rc=0"
    else
        _test_fail "Three closed blocks → rc=0" "got rc=$rc"
    fi
}

# --- Test 12: Unclosed block at end (no blank lines) ---
test_unclosed_no_blanks() {
    local f="$TEST_DIR/unclosed-no-blanks.qmd"
    cat > "$f" <<'EOF'
$$
x + y = z
$$

Text here.

$$
a = b
EOF
    _check_math_blanks "$f"
    local rc=$?
    if [[ $rc -eq 2 ]]; then
        _test_pass "Unclosed block (no blanks inside) → rc=2"
    else
        _test_fail "Unclosed block (no blanks inside) → rc=2" "got rc=$rc"
    fi
}

# ============================================================================
# RUN ALL
# ============================================================================

test_no_math
test_clean_math
test_blank_in_math
test_blank_in_second_block
test_blank_outside_math
test_nonexistent_file
test_empty_file
test_inline_dollar_signs
test_padded_delimiters
test_unclosed_block
test_unclosed_with_blank
test_closed_blocks
test_unclosed_no_blanks

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "─────────────────────────────────────────────────"
echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "─────────────────────────────────────────────────"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
