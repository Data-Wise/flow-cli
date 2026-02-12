#!/bin/bash
# Interactive CLI Test Suite: Himalaya Neovim Integration
# Generated: 2026-02-11
# Run: bash tests/cli/himalaya-interactive-tests.sh
#
# Guided step-by-step tests for verifying himalaya-vim,
# AI wrapper, and Neovim integration work end-to-end.

set -e

PASS=0
FAIL=0
SKIP=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

ask_result() {
    echo ""
    read -p "  Result? (p)ass / (f)ail / (s)kip: " -n 1 -r
    echo ""
    case "$REPLY" in
        p|P) ((PASS++)) || true; echo -e "  ${GREEN}PASS${NC}" ;;
        f|F) ((FAIL++)) || true; echo -e "  ${RED}FAIL${NC}" ;;
        *)   ((SKIP++)) || true; echo -e "  ${YELLOW}SKIP${NC}" ;;
    esac
}

run_test() {
    local num="$1" title="$2" cmd="$3" expected="$4"
    echo ""
    echo -e "${BLUE}${BOLD}TEST ${num}: ${title}${NC}"
    echo -e "  ${DIM}Command:${NC}  ${cmd}"
    echo -e "  ${DIM}Expected:${NC} ${expected}"
    echo ""
    read -p "  Run? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "  ${CYAN}--- output ---${NC}"
        eval "$cmd" 2>&1 | head -20 || true
        echo -e "  ${CYAN}--- end ---${NC}"
        ask_result
    else
        ((SKIP++)) || true
        echo -e "  ${YELLOW}SKIP${NC}"
    fi
}

echo "═══════════════════════════════════════════════════════════════"
echo "  INTERACTIVE TEST SUITE: Himalaya Neovim Integration"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  This walks you through testing the himalaya email setup."
echo "  Each test shows a command — you decide if it passed."
echo ""
read -p "Ready? (Enter to start) "

# ═══════════════════════════════════════════════════════════════
# SECTION 1: Prerequisites
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== PREREQUISITES ===${NC}"

run_test 1 \
    "himalaya CLI version" \
    "himalaya --version" \
    "Shows himalaya v1.x with +imap +smtp features"

run_test 2 \
    "himalaya account list" \
    "himalaya account list" \
    "Shows at least one configured email account"

run_test 3 \
    "claude CLI available" \
    "claude --version" \
    "Shows Claude Code version number"

run_test 4 \
    "Neovim version" \
    "nvim --version | head -3" \
    "Shows NVIM v0.10+ (required for floating windows)"

# ═══════════════════════════════════════════════════════════════
# SECTION 2: File Setup
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== FILE SETUP ===${NC}"

run_test 5 \
    "Plugin spec exists" \
    "ls -la ~/.config/nvim/lua/plugins/himalaya.lua" \
    "File exists and is non-empty"

run_test 6 \
    "AI wrapper module exists" \
    "ls -la ~/.config/nvim/lua/himalaya-ai.lua" \
    "File exists and is non-empty"

run_test 7 \
    "Keymaps file has AI bindings" \
    "grep 'himalaya-ai' ~/.config/nvim/lua/config/keymaps.lua" \
    "Shows keymaps referencing himalaya-ai module"

# ═══════════════════════════════════════════════════════════════
# SECTION 3: Neovim Plugin Loading
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== NEOVIM PLUGIN LOADING ===${NC}"

run_test 8 \
    "himalaya-ai module loads in Neovim" \
    "nvim --headless -c \"lua print(type(require('himalaya-ai')))\" -c 'qa!' 2>&1" \
    "Prints 'table' (module loaded successfully)"

echo ""
echo -e "${BLUE}${BOLD}TEST 9: Lazy.nvim sees himalaya-vim${NC}"
echo -e "  ${DIM}Action:${NC}   Open Neovim, run :Lazy, search for himalaya"
echo -e "  ${DIM}Expected:${NC} himalaya-vim appears in plugin list"
echo ""
echo "  Open Neovim in another terminal and check :Lazy"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 10: :Himalaya command available${NC}"
echo -e "  ${DIM}Action:${NC}   In Neovim, type :Himalaya and press Tab"
echo -e "  ${DIM}Expected:${NC} Command autocompletes (plugin loaded via cmd)"
echo ""
echo "  Try in your Neovim session"
ask_result

# ═══════════════════════════════════════════════════════════════
# SECTION 4: Email Operations (himalaya-vim)
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== EMAIL OPERATIONS ===${NC}"

echo ""
echo -e "${BLUE}${BOLD}TEST 11: List emails${NC}"
echo -e "  ${DIM}Action:${NC}   Run :Himalaya in Neovim"
echo -e "  ${DIM}Expected:${NC} Envelope list appears with subjects, dates, senders"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 12: Read an email${NC}"
echo -e "  ${DIM}Action:${NC}   Press Enter on an email in the list"
echo -e "  ${DIM}Expected:${NC} Email body displayed in buffer"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 13: Folder picker (telescope)${NC}"
echo -e "  ${DIM}Action:${NC}   Press gm in the envelope list"
echo -e "  ${DIM}Expected:${NC} Telescope picker shows email folders (INBOX, Sent, etc.)"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 14: Reply to email${NC}"
echo -e "  ${DIM}Action:${NC}   Open an email, press gr"
echo -e "  ${DIM}Expected:${NC} Reply compose buffer opens with quoted text"
echo -e "  ${DIM}Note:${NC}     Don't actually send — close with :q!"
echo ""
echo "  Try in Neovim"
ask_result

# ═══════════════════════════════════════════════════════════════
# SECTION 5: AI Wrapper
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== AI WRAPPER ===${NC}"

echo ""
echo -e "${BLUE}${BOLD}TEST 15: AI Summarize (<leader>ms)${NC}"
echo -e "  ${DIM}Action:${NC}   Open an email in Neovim, press <leader>ms"
echo -e "  ${DIM}Expected:${NC} Floating window appears with 2-3 bullet point summary"
echo -e "  ${DIM}Note:${NC}     May take 2-5s for Claude to respond"
echo ""
echo "  Try in Neovim with an open email"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 16: AI Extract Todos (<leader>mt)${NC}"
echo -e "  ${DIM}Action:${NC}   Open an email with action items, press <leader>mt"
echo -e "  ${DIM}Expected:${NC} Floating window with markdown checklist of action items"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 17: AI Draft Reply (<leader>mr)${NC}"
echo -e "  ${DIM}Action:${NC}   Open an email, press <leader>mr"
echo -e "  ${DIM}Expected:${NC} Floating window with a professional reply draft"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 18: AI TL;DR (<leader>mc)${NC}"
echo -e "  ${DIM}Action:${NC}   Open an email, press <leader>mc"
echo -e "  ${DIM}Expected:${NC} Split showing TL;DR, urgency table, action items, deadline"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 19: Float window close (q)${NC}"
echo -e "  ${DIM}Action:${NC}   With a float open, press q"
echo -e "  ${DIM}Expected:${NC} Float closes, back to email buffer"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 20: Float window close (Esc)${NC}"
echo -e "  ${DIM}Action:${NC}   Trigger an AI action, then press Esc"
echo -e "  ${DIM}Expected:${NC} Float closes cleanly"
echo ""
echo "  Try in Neovim"
ask_result

# ═══════════════════════════════════════════════════════════════
# SECTION 6: Which-key Integration
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== WHICH-KEY ===${NC}"

echo ""
echo -e "${BLUE}${BOLD}TEST 21: Which-key shows AI keybinds${NC}"
echo -e "  ${DIM}Action:${NC}   Press <leader>m and wait for which-key popup"
echo -e "  ${DIM}Expected:${NC} Shows s=Summarize, t=Todos, r=Reply, c=TL;DR"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 22: Which-key shows email launch${NC}"
echo -e "  ${DIM}Action:${NC}   Press <leader>e and wait for which-key popup"
echo -e "  ${DIM}Expected:${NC} Shows M=Open Himalaya (Email)"
echo ""
echo "  Try in Neovim"
ask_result

# ═══════════════════════════════════════════════════════════════
# SECTION 7: HimalayaAi Commands
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== HIMALAYAAI COMMANDS ===${NC}"

echo ""
echo -e "${BLUE}${BOLD}TEST 23: :HimalayaAi status${NC}"
echo -e "  ${DIM}Action:${NC}   Run :HimalayaAi status"
echo -e "  ${DIM}Expected:${NC} Dashboard split: backend [OK], vault path, prompts list, [q] close"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 24: :HimalayaAi prompts${NC}"
echo -e "  ${DIM}Action:${NC}   Run :HimalayaAi prompts"
echo -e "  ${DIM}Expected:${NC} Interactive buffer listing prompts with [e] edit  [v] validate  [q] close"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 25: :HimalayaAi edit${NC}"
echo -e "  ${DIM}Action:${NC}   Run :HimalayaAi edit"
echo -e "  ${DIM}Expected:${NC} ~/.config/himalaya-ai/config.lua opens in vsplit"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 26: :HimalayaAi edit + save reload${NC}"
echo -e "  ${DIM}Action:${NC}   In the config split from test 25, make a change and :w"
echo -e "  ${DIM}Expected:${NC} Notification: 'himalaya-ai: Config reloaded'"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 27: :HimalayaAi set backend claude${NC}"
echo -e "  ${DIM}Action:${NC}   Run :HimalayaAi set backend claude"
echo -e "  ${DIM}Expected:${NC} Notification: 'Backend → claude (persisted)'"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 28: :HimalayaAi set format simple${NC}"
echo -e "  ${DIM}Action:${NC}   Run :HimalayaAi set format simple"
echo -e "  ${DIM}Expected:${NC} Notification: 'Format → simple (persisted)'"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 29: :HimalayaAi validate summarize${NC}"
echo -e "  ${DIM}Action:${NC}   Run :HimalayaAi validate summarize (with or without email open)"
echo -e "  ${DIM}Expected:${NC} AI runs on sample/buffer email, result split appears with summary"
echo -e "  ${DIM}Note:${NC}     May take 2-5s for backend to respond"
echo ""
echo "  Try in Neovim"
ask_result

# ═══════════════════════════════════════════════════════════════
# SECTION 8: Result Split Keybinds (v2)
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== RESULT SPLIT KEYBINDS (v2) ===${NC}"

echo ""
echo -e "${BLUE}${BOLD}TEST 30: 'o' — Save to Obsidian${NC}"
echo -e "  ${DIM}Action:${NC}   Run an AI action (<leader>ms), then press 'o' in the result split"
echo -e "  ${DIM}Expected:${NC} Notification with Obsidian note path, file created in vault/Inbox"
echo ""
echo "  Try in Neovim (open an email first, then <leader>ms → o)"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 31: 'r' — Re-run with edited prompt${NC}"
echo -e "  ${DIM}Action:${NC}   In a result split, press 'r'"
echo -e "  ${DIM}Expected:${NC} vim.ui.input appears with editable prompt, submitting re-runs AI"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 32: 'a' — Append to file${NC}"
echo -e "  ${DIM}Action:${NC}   In a result split, press 'a'"
echo -e "  ${DIM}Expected:${NC} Prompted for file path (with completion), content appended on confirm"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 33: 'p' — Paste into reply${NC}"
echo -e "  ${DIM}Action:${NC}   In a result split (from draft_reply), press 'p'"
echo -e "  ${DIM}Expected:${NC} Content copied to register, reply compose opens, draft pasted"
echo -e "  ${DIM}Note:${NC}     Close reply with :q! to avoid sending"
echo ""
echo "  Try in Neovim"
ask_result

# ═══════════════════════════════════════════════════════════════
# SECTION 9: Tab Completion
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== TAB COMPLETION ===${NC}"

echo ""
echo -e "${BLUE}${BOLD}TEST 34: :HimalayaAi + Tab${NC}"
echo -e "  ${DIM}Action:${NC}   Type :HimalayaAi (space) then press Tab"
echo -e "  ${DIM}Expected:${NC} Completion menu: status, prompts, edit, validate, set"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
echo -e "${BLUE}${BOLD}TEST 35: :HimalayaAi set + Tab${NC}"
echo -e "  ${DIM}Action:${NC}   Type :HimalayaAi set (space) then press Tab"
echo -e "  ${DIM}Expected:${NC} Completion menu: backend, vault, save_dir, format"
echo ""
echo "  Try in Neovim"
ask_result

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

TOTAL=$((PASS + FAIL + SKIP))

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
elif [[ $FAIL -le 2 ]]; then
    echo -e "  ${YELLOW}${BOLD}MOSTLY PASSING — minor issues${NC}"
else
    echo -e "  ${RED}${BOLD}NEEDS ATTENTION — ${FAIL} failures${NC}"
fi
echo ""
echo "  Test log: $(date '+%Y-%m-%d %H:%M')"
echo ""
