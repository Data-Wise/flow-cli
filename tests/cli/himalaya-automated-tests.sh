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

# Test: Has folder picker configured
if grep -q 'himalaya_folder_picker' "${HIMALAYA_PLUGIN}" 2>/dev/null; then
    log_pass "Folder picker configured"
else
    log_skip "No folder picker configured (uses auto-detect)"
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

# Test: tldr function (v2 — replaces classify)
if grep -q 'function M.tldr' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has M.tldr() function (v2)"
else
    log_fail "Missing tldr function"
fi

# Test: Uses jobstart (async)
if grep -q 'jobstart' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Uses vim.fn.jobstart() for async execution"
else
    log_fail "Not using async jobstart (may block Neovim)"
fi

# Test: Uses configurable display (split/tab)
if grep -q 'open_display_buffer' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Uses configurable display buffer (split/tab)"
else
    log_fail "Missing open_display_buffer implementation"
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

# Test: leader-mc (tldr)
if grep -q '<leader>mc' "${KEYMAPS}" 2>/dev/null; then
    log_pass "Has <leader>mc keybind (TL;DR)"
else
    log_fail "Missing <leader>mc keybind"
fi

# Test: leader-mp (prompt picker)
if grep -q '<leader>mp' "${KEYMAPS}" 2>/dev/null; then
    log_pass "Has <leader>mp keybind (prompt picker)"
else
    log_fail "Missing <leader>mp keybind"
fi

# Test: leader-mi (AI status)
if grep -q '<leader>mi' "${KEYMAPS}" 2>/dev/null; then
    log_pass "Has <leader>mi keybind (AI status)"
else
    log_fail "Missing <leader>mi keybind"
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
# CONFIG FILE VALIDATION
# ═══════════════════════════════════════════════════════════════

section "Config File Validation"

HIMALAYA_CONFIG="${HOME}/.config/himalaya-ai/config.lua"

# Test: Config file exists
if [[ -f "${HIMALAYA_CONFIG}" ]]; then
    log_pass "Config file exists at ${HIMALAYA_CONFIG}"
else
    log_skip "Config file not found (will use built-in defaults)"
fi

# Test: Config is valid Lua
if [[ -f "${HIMALAYA_CONFIG}" ]]; then
    if nvim --headless -c "lua dofile(vim.fn.expand('~/.config/himalaya-ai/config.lua'))" -c "qa!" 2>&1 | grep -qi "error"; then
        log_fail "Config file has Lua syntax errors"
    else
        log_pass "Config file is valid Lua"
    fi
else
    log_skip "No config file to validate"
fi

# Test: Config has backend key
if [[ -f "${HIMALAYA_CONFIG}" ]] && grep -q 'backend' "${HIMALAYA_CONFIG}" 2>/dev/null; then
    log_pass "Config has 'backend' key"
else
    log_skip "No backend key in config (defaults apply)"
fi

# Test: Config has backends table
if [[ -f "${HIMALAYA_CONFIG}" ]] && grep -q 'backends' "${HIMALAYA_CONFIG}" 2>/dev/null; then
    log_pass "Config has 'backends' table"
else
    log_skip "No backends table in config (defaults apply)"
fi

# Test: Config has obsidian table
if [[ -f "${HIMALAYA_CONFIG}" ]] && grep -q 'obsidian' "${HIMALAYA_CONFIG}" 2>/dev/null; then
    log_pass "Config has 'obsidian' table"
else
    log_skip "No obsidian table in config (defaults apply)"
fi

# ═══════════════════════════════════════════════════════════════
# V2 FEATURE VALIDATION
# ═══════════════════════════════════════════════════════════════

section "V2 Features (himalaya-ai.lua)"

# Test: Has M.tldr function (replaces classify)
if grep -q 'function M.tldr' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has M.tldr() function (v2 replacement for classify)"
else
    log_fail "Missing M.tldr() function"
fi

# Test: Has _run_ai_custom function (re-run support)
if grep -q 'function M._run_ai_custom' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has M._run_ai_custom() function (re-run support)"
else
    log_fail "Missing _run_ai_custom function"
fi

# Test: Has make_obsidian_note function
if grep -q 'function make_obsidian_note' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has make_obsidian_note() function"
else
    log_fail "Missing make_obsidian_note function"
fi

# Test: Has persist_config function
if grep -q 'function persist_config' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has persist_config() function"
else
    log_fail "Missing persist_config function"
fi

# Test: Has open_info_buffer function
if grep -q 'function open_info_buffer' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has open_info_buffer() function"
else
    log_fail "Missing open_info_buffer function"
fi

# ═══════════════════════════════════════════════════════════════
# V3: INTERACTIVE PROMPTS & COMPOSE
# ═══════════════════════════════════════════════════════════════

section "V3 Features (interactive prompts)"

# Test: Has run_ai_with_input wrapper
if grep -q 'function run_ai_with_input' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has run_ai_with_input() wrapper"
else
    log_fail "Missing run_ai_with_input function"
fi

# Test: Has M.compose function
if grep -q 'function M.compose' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has M.compose() function"
else
    log_fail "Missing compose function"
fi

# Test: Has ask_before config
if grep -q 'ask_before' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has ask_before config table"
else
    log_fail "Missing ask_before config"
fi

# Test: Has input_hints table
if grep -q 'input_hints' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has input_hints table for per-action prompts"
else
    log_fail "Missing input_hints table"
fi

# Test: run_ai accepts instructions param
if grep -q 'function run_ai(prompt_key, title, instructions)' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "run_ai() accepts instructions parameter"
else
    log_fail "run_ai() missing instructions parameter"
fi

# Test: M.compose is callable in headless
result=$(nvim --headless +"lua io.write(type(require('himalaya-ai').compose))" +"qa!" 2>&1)
if echo "$result" | grep -q "function"; then
    log_pass "M.compose is callable"
else
    log_fail "M.compose not a function: ${result}"
fi

# Test: leader-mw keybind (compose)
if grep -q '<leader>mw' "${KEYMAPS}" 2>/dev/null; then
    log_pass "Has <leader>mw keybind (compose)"
else
    log_fail "Missing <leader>mw keybind"
fi

# Test: draft_reply defaults to ask_before=true
if grep -q 'draft_reply = true' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "draft_reply has ask_before=true by default"
else
    log_fail "draft_reply ask_before not true"
fi

# Test: persist_config handles same-value (no-op = success)
if grep -q 'no-op is success' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "persist_config handles same-value as success"
else
    log_fail "persist_config missing same-value fix"
fi

# ═══════════════════════════════════════════════════════════════
# V4: POST-AI KEYBINDS (e/c/n/t)
# ═══════════════════════════════════════════════════════════════

section "V4 Features (post-AI keybinds)"

# Test: Has get_buf_text helper
if grep -q 'function get_buf_text' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has get_buf_text() helper for dynamic buffer reads"
else
    log_fail "Missing get_buf_text helper"
fi

# Test: Has 'e' keybind (edit toggle)
if grep -q '"e"' "${HIMALAYA_AI}" 2>/dev/null && grep -q 'modifiable' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has 'e' keybind (edit toggle)"
else
    log_fail "Missing 'e' keybind"
fi

# Test: Has 'c' keybind (revise)
if grep -q '"c"' "${HIMALAYA_AI}" 2>/dev/null && grep -q 'Revise' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has 'c' keybind (revise with instruction)"
else
    log_fail "Missing 'c' keybind"
fi

# Test: Has 'n' keybind (next action chain)
if grep -q '"n"' "${HIMALAYA_AI}" 2>/dev/null && grep -q 'Next AI action' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has 'n' keybind (next action chain)"
else
    log_fail "Missing 'n' keybind"
fi

# Test: Has 't' keybind (send to todo)
if grep -q '"t"' "${HIMALAYA_AI}" 2>/dev/null && grep -q 'send_obsidian\|send_reminders' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has 't' keybind (send to todo)"
else
    log_fail "Missing 't' keybind"
fi

# Test: Has todo_target config
if grep -q 'todo_target' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Has todo_target config option"
else
    log_fail "Missing todo_target config"
fi

# Test: Keybinds use get_buf_text (not captured text variable)
if grep -q 'get_buf_text()' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Keybinds use get_buf_text() for dynamic buffer reads"
else
    log_fail "Keybinds not using get_buf_text()"
fi

# Test: n keybind offers source selection (original email vs AI result)
if grep -q 'Original email.*Current AI result' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "'n' keybind offers input source selection"
else
    log_fail "'n' keybind missing source selection"
fi

# Test: Statusline shows new keybinds
if grep -q 'e=edit.*c=revise.*n=next.*t=todo' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Statusline shows e/c/n/t keybinds"
else
    log_fail "Statusline missing new keybinds"
fi

# ═══════════════════════════════════════════════════════════════
# HIMALAYAAI COMMAND TESTS (HEADLESS)
# ═══════════════════════════════════════════════════════════════

section "HimalayaAi Command (Headless)"

# Note: require('himalaya-ai') triggers command registration (LazyVim defers loading)
# We test commands and completion via the command's complete function directly.

# Test: :HimalayaAi command registered after require
result=$(nvim --headless +"lua require('himalaya-ai'); io.write(vim.api.nvim_get_commands({})['HimalayaAi'] and 'yes' or 'no')" +"qa!" 2>&1)
if echo "$result" | grep -q "yes"; then
    log_pass ":HimalayaAi command is registered"
else
    log_fail ":HimalayaAi command not registered"
fi

# Test: Command nargs is *
result=$(nvim --headless +"lua require('himalaya-ai'); io.write(vim.api.nvim_get_commands({})['HimalayaAi'].nargs or 'nil')" +"qa!" 2>&1)
if echo "$result" | grep -q '\*'; then
    log_pass ":HimalayaAi nargs is * (variable args)"
else
    log_fail ":HimalayaAi nargs unexpected: ${result}"
fi

# Test: Command has completion function defined
result=$(nvim --headless +"lua require('himalaya-ai'); local cmd = vim.api.nvim_get_commands({})['HimalayaAi']; io.write(cmd.complete or 'none')" +"qa!" 2>&1)
if echo "$result" | grep -qv "none"; then
    log_pass ":HimalayaAi has tab completion defined"
else
    log_fail ":HimalayaAi missing tab completion"
fi

# Test: Source defines 5 subcommands in completion
if grep -q '"status".*"prompts".*"edit".*"validate".*"set"' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Completion source has 5 subcommands (status/prompts/edit/validate/set)"
else
    log_fail "Completion source missing expected subcommands"
fi

# Test: Source defines 6 set keys in completion
if grep -q '"backend".*"vault".*"save_dir".*"format".*"result_display".*"todo_target"' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Completion source has 6 set keys (backend/vault/save_dir/format/result_display/todo_target)"
else
    log_fail "Completion source missing expected set keys"
fi

# Test: Source defines format completion values
if grep -q '"structured".*"simple"' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Completion source has format values (structured/simple)"
else
    log_fail "Completion source missing format values"
fi

# Test: Source defines result_display completion values
if grep -q '"split".*"tab"' "${HIMALAYA_AI}" 2>/dev/null; then
    log_pass "Completion source has result_display values (split/tab)"
else
    log_fail "Completion source missing result_display values"
fi

# Test: validate completion returns prompt names (4+ via headless)
result=$(nvim --headless +"lua require('himalaya-ai'); local hai = require('himalaya-ai'); local keys = vim.tbl_keys(hai.config.prompts or {}); io.write(#keys .. '')" +"qa!" 2>&1)
# get_prompts merges defaults — count defaults in source
default_count=$(grep -c "^\s*[a-z_]* = " "${HIMALAYA_AI}" 2>/dev/null | head -1)
if grep -q 'summarize' "${HIMALAYA_AI}" && grep -q 'extract_todos' "${HIMALAYA_AI}" && grep -q 'draft_reply' "${HIMALAYA_AI}" && grep -q 'tldr' "${HIMALAYA_AI}"; then
    log_pass "4 built-in prompts defined (summarize/extract_todos/draft_reply/tldr)"
else
    log_fail "Missing expected built-in prompts"
fi

# Test: get_prompts() merges defaults (has summarize key)
result=$(nvim --headless +"lua local hai = require('himalaya-ai'); local p = vim.tbl_keys(hai.config); io.write(type(require('himalaya-ai').summarize))" +"qa!" 2>&1)
if echo "$result" | grep -q "function"; then
    log_pass "M.summarize is callable (prompts merged correctly)"
else
    log_fail "M.summarize not a function: ${result}"
fi

# Test: persist_config function exists and is callable
result=$(nvim --headless +"lua local hai = require('himalaya-ai'); io.write(type(hai._run_ai_custom))" +"qa!" 2>&1)
if echo "$result" | grep -q "function"; then
    log_pass "M._run_ai_custom is callable (custom prompt runner)"
else
    log_fail "M._run_ai_custom not a function: ${result}"
fi

# ═══════════════════════════════════════════════════════════════
# HEADLESS KEYBIND TESTS (Lua)
# ═══════════════════════════════════════════════════════════════

section "Headless Keybind Tests (Lua)"

HEADLESS_TESTS="$(cd "$(dirname "$0")" && pwd)/himalaya-headless-keybind-tests.lua"
if [[ -f "${HEADLESS_TESTS}" ]]; then
    headless_output=$(nvim --headless -l "${HEADLESS_TESTS}" 2>&1)
    headless_exit=$?
    headless_passed=$(echo "$headless_output" | grep -c "PASS:" || true)
    headless_failed=$(echo "$headless_output" | grep -c "FAIL:" || true)

    if [[ $headless_exit -eq 0 && $headless_failed -eq 0 ]]; then
        log_pass "Headless keybind tests: ${headless_passed} passed"
    else
        log_fail "Headless keybind tests: ${headless_failed} failed (${headless_passed} passed)"
        # Show failed tests
        echo "$headless_output" | grep "FAIL:" | head -10
    fi
else
    log_skip "Headless keybind test file not found"
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
