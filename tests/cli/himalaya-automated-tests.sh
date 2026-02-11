#!/bin/bash
# Automated CLI Test Suite: Himalaya Neovim Integration
# Generated: 2026-02-11
# Run: bash tests/cli/himalaya-automated-tests.sh
#
# Tests: himalaya CLI, himalaya-vim plugin spec, AI wrapper module,
#        keymaps, and Neovim headless loading.

set -e

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════

PASS=0
FAIL=0
SKIP=0
TOTAL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

NVIM_CONFIG="${HOME}/.config/nvim"
HIMALAYA_PLUGIN="${NVIM_CONFIG}/lua/plugins/himalaya.lua"
HIMALAYA_AI="${NVIM_CONFIG}/lua/himalaya-ai.lua"
KEYMAPS="${NVIM_CONFIG}/lua/config/keymaps.lua"

log_pass() { ((PASS++)) || true; ((TOTAL++)) || true; echo -e "  ${GREEN}PASS${NC}: $1"; }
log_fail() { ((FAIL++)) || true; ((TOTAL++)) || true; echo -e "  ${RED}FAIL${NC}: $1"; }
log_skip() { ((SKIP++)) || true; ((TOTAL++)) || true; echo -e "  ${YELLOW}SKIP${NC}: $1"; }

section() { echo -e "\n${BLUE}${BOLD}[$1]${NC}"; }

# ═══════════════════════════════════════════════════════════════
# PREREQUISITES
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════"
echo "  AUTOMATED TEST SUITE: Himalaya Neovim Integration"
echo "═══════════════════════════════════════════════════════════════"

section "Prerequisites"

# Test: himalaya CLI installed
if command -v himalaya &>/dev/null; then
    log_pass "himalaya CLI found: $(which himalaya)"
else
    log_fail "himalaya CLI not found in PATH"
fi

# Test: himalaya version is 1.x
if himalaya --version 2>/dev/null | grep -q "^himalaya v1\."; then
    log_pass "himalaya version is 1.x: $(himalaya --version 2>/dev/null | head -1)"
else
    log_fail "himalaya version not 1.x or unavailable"
fi

# Test: claude CLI installed
if command -v claude &>/dev/null; then
    log_pass "claude CLI found: $(which claude)"
else
    log_fail "claude CLI not found (AI wrapper will not work)"
fi

# Test: Neovim installed
if command -v nvim &>/dev/null; then
    log_pass "nvim found: $(nvim --version 2>/dev/null | head -1)"
else
    log_fail "nvim not found in PATH"
fi

# Test: LazyVim config exists
if [[ -f "${NVIM_CONFIG}/lua/config/lazy.lua" ]]; then
    log_pass "LazyVim config exists"
else
    log_fail "LazyVim config not found at ${NVIM_CONFIG}/lua/config/lazy.lua"
fi

# ═══════════════════════════════════════════════════════════════
# FILE EXISTENCE
# ═══════════════════════════════════════════════════════════════

section "File Existence"

# Test: Plugin spec exists
if [[ -f "${HIMALAYA_PLUGIN}" ]]; then
    log_pass "himalaya.lua plugin spec exists"
else
    log_fail "Missing: ${HIMALAYA_PLUGIN}"
fi

# Test: AI wrapper module exists
if [[ -f "${HIMALAYA_AI}" ]]; then
    log_pass "himalaya-ai.lua module exists"
else
    log_fail "Missing: ${HIMALAYA_AI}"
fi

# Test: Keymaps file exists
if [[ -f "${KEYMAPS}" ]]; then
    log_pass "keymaps.lua exists"
else
    log_fail "Missing: ${KEYMAPS}"
fi

# ═══════════════════════════════════════════════════════════════
# PLUGIN SPEC VALIDATION
# ═══════════════════════════════════════════════════════════════

section "Plugin Spec (himalaya.lua)"

# Test: References correct repo
if grep -q 'pimalaya/himalaya-vim' "${HIMALAYA_PLUGIN}" 2>/dev/null; then
    log_pass "References pimalaya/himalaya-vim repo"
else
    log_fail "Missing pimalaya/himalaya-vim repo reference"
fi

# Test: Configures himalaya_executable
if grep -q 'himalaya_executable' "${HIMALAYA_PLUGIN}" 2>/dev/null; then
    log_pass "Configures g:himalaya_executable"
else
    log_fail "Missing himalaya_executable config"
fi

# Test: Configures folder_picker
if grep -q 'himalaya_folder_picker' "${HIMALAYA_PLUGIN}" 2>/dev/null; then
    log_pass "Configures g:himalaya_folder_picker"
else
    log_fail "Missing folder_picker config"
fi

# Test: Uses telescope picker
if grep -q '"telescope"' "${HIMALAYA_PLUGIN}" 2>/dev/null; then
    log_pass "Folder picker set to telescope"
else
    log_skip "Folder picker not set to telescope (may use fzf)"
fi

# Test: Has lazy-load command
if grep -q 'cmd.*=.*Himalaya' "${HIMALAYA_PLUGIN}" 2>/dev/null; then
    log_pass "Lazy-loads via :Himalaya command"
else
    log_skip "No cmd lazy-loading (loads at startup)"
fi

# Test: Has leader keymap for launching
if grep -q '<leader>' "${HIMALAYA_PLUGIN}" 2>/dev/null; then
    log_pass "Has leader keymap to launch himalaya"
else
    log_skip "No leader keymap in plugin spec"
fi

# ═══════════════════════════════════════════════════════════════
# AI WRAPPER VALIDATION
# ═══════════════════════════════════════════════════════════════

section "AI Wrapper (himalaya-ai.lua)"

# Test: Module pattern
if grep -q 'local M = {}' "${HIMALAYA_AI}" 2>/dev/null && grep -q 'return M' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Uses Lua module pattern (local M = {} / return M)"
else
    log_fail "Missing standard Lua module pattern"
fi

# Test: summarize function
if grep -q 'function M.summarize' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has M.summarize() function"
else
    log_fail "Missing summarize function"
fi

# Test: extract_todos function
if grep -q 'function M.extract_todos' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has M.extract_todos() function"
else
    log_fail "Missing extract_todos function"
fi

# Test: draft_reply function
if grep -q 'function M.draft_reply' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has M.draft_reply() function"
else
    log_fail "Missing draft_reply function"
fi

# Test: classify function
if grep -q 'function M.classify' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has M.classify() function"
else
    log_fail "Missing classify function"
fi

# Test: Uses jobstart (async)
if grep -q 'jobstart' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Uses vim.fn.jobstart() for async execution"
else
    log_fail "Not using async jobstart (may block Neovim)"
fi

# Test: Has floating window
if grep -q 'nvim_open_win' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Uses floating window for output display"
else
    log_fail "Missing floating window implementation"
fi

# Test: Float is closeable
if grep -q 'close' "${HIMALAYA_AI}" 2>/dev/null && grep -q '<Esc>' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Floating window closeable with q/<Esc>"
else
    log_skip "Could not verify float close keybinds"
fi

# Test: Has setup function
if grep -q 'function M.setup' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has M.setup() for config overrides"
else
    log_skip "No setup function (hardcoded config)"
fi

# Test: References claude CLI
if grep -q 'claude' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "References claude CLI"
else
    log_fail "No reference to claude CLI"
fi

# ═══════════════════════════════════════════════════════════════
# KEYMAPS VALIDATION
# ═══════════════════════════════════════════════════════════════

section "Keymaps (keymaps.lua)"

# Test: Has himalaya AI keybinds
if grep -q 'himalaya-ai' "${KEYMAPS}" 2>/dev/null; then
    log_pass "Keymaps reference himalaya-ai module"
else
    log_fail "No himalaya-ai keymaps found"
fi

# Test: leader-ms (summarize)
if grep -q '<leader>ms' "${KEYMAPS}" 2>/dev/null; then
    log_pass "Has <leader>ms keybind (summarize)"
else
    log_fail "Missing <leader>ms keybind"
fi

# Test: leader-mt (todos)
if grep -q '<leader>mt' "${KEYMAPS}" 2>/dev/null; then
    log_pass "Has <leader>mt keybind (extract todos)"
else
    log_fail "Missing <leader>mt keybind"
fi

# Test: leader-mr (draft reply)
if grep -q '<leader>mr' "${KEYMAPS}" 2>/dev/null; then
    log_pass "Has <leader>mr keybind (draft reply)"
else
    log_fail "Missing <leader>mr keybind"
fi

# Test: leader-mc (classify)
if grep -q '<leader>mc' "${KEYMAPS}" 2>/dev/null; then
    log_pass "Has <leader>mc keybind (classify)"
else
    log_fail "Missing <leader>mc keybind"
fi

# Test: Uses lazy require pattern
if grep -q 'function() require("himalaya-ai")' "${KEYMAPS}" 2>/dev/null; then
    log_pass "Uses lazy require pattern (no eager loading)"
else
    log_skip "Could not verify lazy require pattern"
fi

# Test: Has desc fields for which-key
if grep -q 'desc = ' "${KEYMAPS}" 2>/dev/null; then
    log_pass "Keybinds have desc fields for which-key"
else
    log_fail "Missing desc fields on keybinds"
fi

# ═══════════════════════════════════════════════════════════════
# NEOVIM HEADLESS LOADING
# ═══════════════════════════════════════════════════════════════

section "Neovim Headless Tests"

# Test: himalaya-ai module parses without syntax errors
if nvim --headless -c "lua require('himalaya-ai')" -c "qa!" 2>&1 | grep -qi "error"; then
    log_fail "himalaya-ai.lua has Lua syntax/load errors"
else
    log_pass "himalaya-ai.lua loads without errors in Neovim"
fi

# Test: Luacheck syntax (if available)
if command -v luacheck &>/dev/null; then
    if luacheck "${HIMALAYA_AI}" --no-config --globals vim --quiet 2>/dev/null; then
        log_pass "luacheck passes on himalaya-ai.lua"
    else
        log_fail "luacheck found issues in himalaya-ai.lua"
    fi
else
    log_skip "luacheck not installed (optional Lua linter)"
fi

# ═══════════════════════════════════════════════════════════════
# DOCUMENTATION
# ═══════════════════════════════════════════════════════════════

section "Documentation"

DOCS_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SETUP_GUIDE="${DOCS_DIR}/docs/guides/HIMALAYA-SETUP.md"

if [[ -f "${SETUP_GUIDE}" ]]; then
    log_pass "HIMALAYA-SETUP.md guide exists"
else
    log_fail "Missing HIMALAYA-SETUP.md in docs/guides/"
fi

# Test: Guide has quick reference table
if grep -q 'Quick Reference' "${SETUP_GUIDE}" 2>/dev/null; then
    log_pass "Guide has Quick Reference section"
else
    log_skip "No Quick Reference section found"
fi

# Test: Guide has troubleshooting
if grep -q 'Troubleshooting' "${SETUP_GUIDE}" 2>/dev/null; then
    log_pass "Guide has Troubleshooting section"
else
    log_skip "No Troubleshooting section found"
fi

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  RESULTS"
echo "═══════════════════════════════════════════════════════════════"
echo -e "  Passed:  ${GREEN}${PASS}${NC}"
echo -e "  Failed:  ${RED}${FAIL}${NC}"
echo -e "  Skipped: ${YELLOW}${SKIP}${NC}"
echo -e "  Total:   ${BOLD}${TOTAL}${NC}"
echo ""

if [[ $FAIL -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}ALL TESTS PASSED${NC}"
else
    echo -e "  ${RED}${BOLD}${FAIL} TEST(S) FAILED${NC}"
fi
echo ""

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
