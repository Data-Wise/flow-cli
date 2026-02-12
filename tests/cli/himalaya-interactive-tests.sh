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
CURRENT_TEST=""
FAILED_TESTS=()
SKIPPED_TESTS=()

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Platform detection
IS_MACOS=false
HAS_OBSIDIAN=false
HAS_REMINDERS=false

# Guard: check required Neovim config files exist
HIMALAYA_AI="${HOME}/.config/nvim/lua/himalaya-ai.lua"
if [[ ! -f "${HIMALAYA_AI}" ]]; then
    echo ""
    echo -e "${YELLOW}${BOLD}SKIP: himalaya-ai.lua not found${NC}"
    echo -e "  These interactive tests require Neovim config files at:"
    echo -e "    ${HIMALAYA_AI}"
    echo -e "  Install himalaya-ai.lua first, then re-run."
    echo ""
    exit 0
fi

if [[ "$(uname)" == "Darwin" ]]; then
    IS_MACOS=true
    # Check if Obsidian is installed
    if [[ -d "/Applications/Obsidian.app" ]] || mdfind "kMDItemCFBundleIdentifier == 'md.obsidian'" 2>/dev/null | head -1 | grep -q .; then
        HAS_OBSIDIAN=true
    fi
    # Reminders.app is always present on macOS
    HAS_REMINDERS=true
fi

ask_result() {
    echo ""
    read -p "  Result? (p)ass / (f)ail / (s)kip: " -n 1 -r
    echo ""
    case "$REPLY" in
        p|P) ((PASS++)) || true; echo -e "  ${GREEN}PASS${NC}" ;;
        f|F) ((FAIL++)) || true; echo -e "  ${RED}FAIL${NC}"; FAILED_TESTS+=("$CURRENT_TEST") ;;
        *)   ((SKIP++)) || true; echo -e "  ${YELLOW}SKIP${NC}"; SKIPPED_TESTS+=("$CURRENT_TEST") ;;
    esac
}

# Platform-guarded test: auto-skips if requirement not met
run_test_guarded() {
    local num="$1" title="$2" guard="$3" guard_msg="$4"
    shift 4
    CURRENT_TEST="TEST ${num}: ${title}"
    if [[ "$guard" != "true" ]]; then
        ((SKIP++)) || true
        echo ""
        echo -e "${BLUE}${BOLD}TEST ${num}: ${title}${NC}"
        echo -e "  ${YELLOW}AUTO-SKIP${NC}: ${guard_msg}"
        SKIPPED_TESTS+=("$CURRENT_TEST")
        return
    fi
}

run_test() {
    local num="$1" title="$2" cmd="$3" expected="$4"
    CURRENT_TEST="TEST ${num}: ${title}"
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
        SKIPPED_TESTS+=("$CURRENT_TEST")
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
CURRENT_TEST="TEST 9: Lazy.nvim sees himalaya-vim"
echo -e "${BLUE}${BOLD}TEST 9: Lazy.nvim sees himalaya-vim${NC}"
echo -e "  ${DIM}Action:${NC}   Open Neovim, run :Lazy, search for himalaya"
echo -e "  ${DIM}Expected:${NC} himalaya-vim appears in plugin list"
echo ""
echo "  Open Neovim in another terminal and check :Lazy"
ask_result

echo ""
CURRENT_TEST="TEST 10: :Himalaya command available"
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
CURRENT_TEST="TEST 11: List emails"
echo -e "${BLUE}${BOLD}TEST 11: List emails${NC}"
echo -e "  ${DIM}Action:${NC}   Run :Himalaya in Neovim"
echo -e "  ${DIM}Expected:${NC} Envelope list appears with subjects, dates, senders"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 12: Read an email"
echo -e "${BLUE}${BOLD}TEST 12: Read an email${NC}"
echo -e "  ${DIM}Action:${NC}   Press Enter on an email in the list"
echo -e "  ${DIM}Expected:${NC} Email body displayed in buffer"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 13: Folder picker"
echo -e "${BLUE}${BOLD}TEST 13: Folder picker${NC}"
echo -e "  ${DIM}Action:${NC}   Press gm in the envelope list"
echo -e "  ${DIM}Expected:${NC} Picker shows email folders (INBOX, Sent, etc.)"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 14: Reply to email"
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
CURRENT_TEST="TEST 15: AI Summarize (<leader>ms)"
echo -e "${BLUE}${BOLD}TEST 15: AI Summarize (<leader>ms)${NC}"
echo -e "  ${DIM}Action:${NC}   Open an email in Neovim, press <leader>ms"
echo -e "  ${DIM}Expected:${NC} Floating window appears with 2-3 bullet point summary"
echo -e "  ${DIM}Note:${NC}     May take 2-5s for Claude to respond"
echo ""
echo "  Try in Neovim with an open email"
ask_result

echo ""
CURRENT_TEST="TEST 16: AI Extract Todos (<leader>mt)"
echo -e "${BLUE}${BOLD}TEST 16: AI Extract Todos (<leader>mt)${NC}"
echo -e "  ${DIM}Action:${NC}   Open an email with action items, press <leader>mt"
echo -e "  ${DIM}Expected:${NC} Floating window with markdown checklist of action items"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 17: AI Draft Reply (<leader>mr)"
echo -e "${BLUE}${BOLD}TEST 17: AI Draft Reply (<leader>mr)${NC}"
echo -e "  ${DIM}Action:${NC}   Open an email, press <leader>mr"
echo -e "  ${DIM}Expected:${NC} Floating window with a professional reply draft"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 18: AI TL;DR (<leader>mc)"
echo -e "${BLUE}${BOLD}TEST 18: AI TL;DR (<leader>mc)${NC}"
echo -e "  ${DIM}Action:${NC}   Open an email, press <leader>mc"
echo -e "  ${DIM}Expected:${NC} Split showing TL;DR, urgency table, action items, deadline"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 19: Float window close (q)"
echo -e "${BLUE}${BOLD}TEST 19: Float window close (q)${NC}"
echo -e "  ${DIM}Action:${NC}   With a float open, press q"
echo -e "  ${DIM}Expected:${NC} Float closes, back to email buffer"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 20: Float window close (Esc)"
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
CURRENT_TEST="TEST 21: Which-key shows AI keybinds"
echo -e "${BLUE}${BOLD}TEST 21: Which-key shows AI keybinds${NC}"
echo -e "  ${DIM}Action:${NC}   Press <leader>m and wait for which-key popup"
echo -e "  ${DIM}Expected:${NC} Shows s=Summarize, t=Todos, r=Reply, c=TL;DR"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 22: Which-key shows email launch"
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
CURRENT_TEST="TEST 23: :HimalayaAi status"
echo -e "${BLUE}${BOLD}TEST 23: :HimalayaAi status${NC}"
echo -e "  ${DIM}Action:${NC}   Run :HimalayaAi status"
echo -e "  ${DIM}Expected:${NC} Dashboard split: backend [OK], vault path, prompts list, [q] close"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 24: :HimalayaAi prompts"
echo -e "${BLUE}${BOLD}TEST 24: :HimalayaAi prompts${NC}"
echo -e "  ${DIM}Action:${NC}   Run :HimalayaAi prompts"
echo -e "  ${DIM}Expected:${NC} Interactive buffer listing prompts with [e] edit  [v] validate  [q] close"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 25: :HimalayaAi edit"
echo -e "${BLUE}${BOLD}TEST 25: :HimalayaAi edit${NC}"
echo -e "  ${DIM}Action:${NC}   Run :HimalayaAi edit"
echo -e "  ${DIM}Expected:${NC} ~/.config/himalaya-ai/config.lua opens in vsplit"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 26: :HimalayaAi edit + save reload"
echo -e "${BLUE}${BOLD}TEST 26: :HimalayaAi edit + save reload${NC}"
echo -e "  ${DIM}Action:${NC}   In the config split from test 25, make a change and :w"
echo -e "  ${DIM}Expected:${NC} Notification: 'himalaya-ai: Config reloaded'"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 27: :HimalayaAi set backend claude"
echo -e "${BLUE}${BOLD}TEST 27: :HimalayaAi set backend claude${NC}"
echo -e "  ${DIM}Action:${NC}   Run :HimalayaAi set backend claude"
echo -e "  ${DIM}Expected:${NC} Notification: 'Backend → claude (persisted)'"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 28: :HimalayaAi set format simple"
echo -e "${BLUE}${BOLD}TEST 28: :HimalayaAi set format simple${NC}"
echo -e "  ${DIM}Action:${NC}   Run :HimalayaAi set format simple"
echo -e "  ${DIM}Expected:${NC} Notification: 'Format → simple (persisted)'"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 29: :HimalayaAi set result_display tab"
echo -e "${BLUE}${BOLD}TEST 29: :HimalayaAi set result_display tab${NC}"
echo -e "  ${DIM}Action:${NC}   Run :HimalayaAi set result_display tab"
echo -e "  ${DIM}Expected:${NC} Notification: 'Result display → tab (persisted)'"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 30: Verify tab display mode"
echo -e "${BLUE}${BOLD}TEST 30: Verify tab display mode${NC}"
echo -e "  ${DIM}Action:${NC}   Run an AI action (e.g. <leader>ms) after setting result_display to tab"
echo -e "  ${DIM}Expected:${NC} Result opens in a new tab instead of bottom split"
echo -e "  ${DIM}Restore:${NC}  Run :HimalayaAi set result_display split to reset"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 31: :HimalayaAi validate summarize"
echo -e "${BLUE}${BOLD}TEST 31: :HimalayaAi validate summarize${NC}"
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
CURRENT_TEST="TEST 32: 'o' — Save to Obsidian"
if [[ "$HAS_OBSIDIAN" != "true" ]]; then
    echo -e "${BLUE}${BOLD}TEST 32: 'o' — Save to Obsidian${NC}"
    echo -e "  ${YELLOW}AUTO-SKIP${NC}: Obsidian not installed"
    ((SKIP++)) || true
    SKIPPED_TESTS+=("$CURRENT_TEST")
else
    echo -e "${BLUE}${BOLD}TEST 32: 'o' — Save to Obsidian${NC}"
    echo -e "  ${DIM}Action:${NC}   Run an AI action (<leader>ms), then press 'o' in the result split"
    echo -e "  ${DIM}Expected:${NC} Notification with Obsidian note path, file created in vault/Inbox"
    echo ""
    echo "  Try in Neovim (open an email first, then <leader>ms → o)"
    ask_result
fi

echo ""
CURRENT_TEST="TEST 33: 'r' — Re-run with edited prompt"
echo -e "${BLUE}${BOLD}TEST 33: 'r' — Re-run with edited prompt${NC}"
echo -e "  ${DIM}Action:${NC}   In a result split, press 'r'"
echo -e "  ${DIM}Expected:${NC} vim.ui.input appears with editable prompt, submitting re-runs AI"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 34: 'a' — Append to file"
echo -e "${BLUE}${BOLD}TEST 34: 'a' — Append to file${NC}"
echo -e "  ${DIM}Action:${NC}   In a result split, press 'a'"
echo -e "  ${DIM}Expected:${NC} Prompted for file path (with completion), content appended on confirm"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 35: 'p' — Paste into reply"
echo -e "${BLUE}${BOLD}TEST 35: 'p' — Paste into reply${NC}"
echo -e "  ${DIM}Action:${NC}   In a result split (from draft_reply), press 'p'"
echo -e "  ${DIM}Expected:${NC} Content copied to register, reply compose opens, draft pasted"
echo -e "  ${DIM}Note:${NC}     Close reply with :q! to avoid sending"
echo ""
echo "  Try in Neovim"
ask_result

# ═══════════════════════════════════════════════════════════════
# SECTION 9: Interactive Prompts & Compose (v3)
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== INTERACTIVE PROMPTS & COMPOSE (v3) ===${NC}"

echo ""
CURRENT_TEST="TEST 36: Draft Reply asks for instructions"
echo -e "${BLUE}${BOLD}TEST 36: Draft Reply asks for instructions${NC}"
echo -e "  ${DIM}Action:${NC}   Open an email, press <leader>mr"
echo -e "  ${DIM}Expected:${NC} vim.ui.input prompt: 'Reply instructions (Enter=default):'"
echo -e "  ${DIM}Note:${NC}     Type instructions (e.g. 'be firm about deadline') or press Enter to skip"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 37: Draft Reply with custom instructions"
echo -e "${BLUE}${BOLD}TEST 37: Draft Reply with custom instructions${NC}"
echo -e "  ${DIM}Action:${NC}   Press <leader>mr, type 'decline politely, suggest next week'"
echo -e "  ${DIM}Expected:${NC} AI generates reply that follows your instructions"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 38: Draft Reply with Enter (default)"
echo -e "${BLUE}${BOLD}TEST 38: Draft Reply with Enter (default)${NC}"
echo -e "  ${DIM}Action:${NC}   Press <leader>mr, press Enter immediately (no instructions)"
echo -e "  ${DIM}Expected:${NC} AI generates reply with default prompt (same as before)"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 39: Compose email (<leader>mw)"
echo -e "${BLUE}${BOLD}TEST 39: Compose email (<leader>mw)${NC}"
echo -e "  ${DIM}Action:${NC}   Press <leader>mw"
echo -e "  ${DIM}Expected:${NC} vim.ui.input prompt: 'What to write about:'"
echo -e "  ${DIM}Note:${NC}     Type a topic (e.g. 'meeting reschedule to Friday')"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 40: Compose cancel (Esc)"
echo -e "${BLUE}${BOLD}TEST 40: Compose cancel (Esc)${NC}"
echo -e "  ${DIM}Action:${NC}   Press <leader>mw, then press Esc"
echo -e "  ${DIM}Expected:${NC} 'Compose cancelled' notification, no AI call"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 41: Summarize skips input by default"
echo -e "${BLUE}${BOLD}TEST 41: Summarize skips input by default${NC}"
echo -e "  ${DIM}Action:${NC}   Open an email, press <leader>ms"
echo -e "  ${DIM}Expected:${NC} AI runs immediately (no input prompt — ask_before=false)"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 42: Which-key shows compose keybind"
echo -e "${BLUE}${BOLD}TEST 42: Which-key shows compose keybind${NC}"
echo -e "  ${DIM}Action:${NC}   Press <leader>m and wait for which-key popup"
echo -e "  ${DIM}Expected:${NC} Shows w=Compose email (new keybind)"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 43: <leader>mp — Prompt picker"
echo -e "${BLUE}${BOLD}TEST 43: <leader>mp — Prompt picker${NC}"
echo -e "  ${DIM}Action:${NC}   Press <leader>mp"
echo -e "  ${DIM}Expected:${NC} vim.ui.select showing: Summarize / Extract Todos / Draft Reply / TL;DR / Compose"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 44: <leader>mi — AI Info/Status"
echo -e "${BLUE}${BOLD}TEST 44: <leader>mi — AI Info/Status${NC}"
echo -e "  ${DIM}Action:${NC}   Press <leader>mi"
echo -e "  ${DIM}Expected:${NC} Status dashboard split showing backend, vault, prompts (same as :HimalayaAi status)"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 45: Which-key shows p=Picker and i=Info"
echo -e "${BLUE}${BOLD}TEST 45: Which-key shows p=Picker and i=Info${NC}"
echo -e "  ${DIM}Action:${NC}   Press <leader>m and wait for which-key popup"
echo -e "  ${DIM}Expected:${NC} Shows p=Prompt picker and i=Status info alongside existing keybinds"
echo ""
echo "  Try in Neovim"
ask_result

# ═══════════════════════════════════════════════════════════════
# SECTION 10: Post-AI Keybinds v4 (e/c/n/t)
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== POST-AI KEYBINDS V4 (e/c/n/t) ===${NC}"

echo ""
CURRENT_TEST="TEST 46: 'e' — Edit result (toggle modifiable)"
echo -e "${BLUE}${BOLD}TEST 46: 'e' — Edit result (toggle modifiable)${NC}"
echo -e "  ${DIM}Action:${NC}   Run an AI action (<leader>ms), then press 'e' in the result split"
echo -e "  ${DIM}Expected:${NC} Notification: 'Editable (edits apply to y/s/a/o/p)'"
echo -e "  ${DIM}Note:${NC}     Edit some text, then press 'y' — clipboard should have edited version"
echo ""
echo "  Try in Neovim (open an email first, then <leader>ms → e → edit → y)"
ask_result

echo ""
CURRENT_TEST="TEST 47: 'e' — Toggle back to read-only"
echo -e "${BLUE}${BOLD}TEST 47: 'e' — Toggle back to read-only${NC}"
echo -e "  ${DIM}Action:${NC}   After making buffer editable with 'e', press 'e' again"
echo -e "  ${DIM}Expected:${NC} Notification: 'Read-only', buffer no longer editable"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 48: 'c' — Revise result"
echo -e "${BLUE}${BOLD}TEST 48: 'c' — Revise result${NC}"
echo -e "  ${DIM}Action:${NC}   In a result split, press 'c'"
echo -e "  ${DIM}Expected:${NC} vim.ui.input prompt: 'Revise:', type instruction (e.g. 'make it shorter')"
echo -e "  ${DIM}Note:${NC}     AI re-runs with revision instruction, new result split opens"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 49: 'c' — Revised title shows '(revised)'"
echo -e "${BLUE}${BOLD}TEST 49: 'c' — Revised title shows '(revised)'${NC}"
echo -e "  ${DIM}Action:${NC}   After pressing 'c' and submitting, check the result split title"
echo -e "  ${DIM}Expected:${NC} Statusline shows original title + '(revised)'"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 50: 'n' — Next action chain"
echo -e "${BLUE}${BOLD}TEST 50: 'n' — Next action chain${NC}"
echo -e "  ${DIM}Action:${NC}   In a result split, press 'n'"
echo -e "  ${DIM}Expected:${NC} vim.ui.select picker: Summarize / Extract Todos / Draft Reply / TL;DR"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 51: 'n' — Source selection"
echo -e "${BLUE}${BOLD}TEST 51: 'n' — Source selection${NC}"
echo -e "  ${DIM}Action:${NC}   After picking an action in 'n', check the source picker"
echo -e "  ${DIM}Expected:${NC} vim.ui.select: 'Original email' / 'Current AI result'"
echo -e "  ${DIM}Note:${NC}     'Original email' uses the email you started from; 'Current AI result' chains"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 52: 'n' — Chain TL;DR then Draft Reply"
echo -e "${BLUE}${BOLD}TEST 52: 'n' — Chain TL;DR then Draft Reply${NC}"
echo -e "  ${DIM}Action:${NC}   <leader>mc → get TL;DR → press 'n' → Draft Reply → Original email"
echo -e "  ${DIM}Expected:${NC} New result split with draft reply (chaining works)"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 53: 't' — Send to todo (content picker)"
echo -e "${BLUE}${BOLD}TEST 53: 't' — Send to todo (content picker)${NC}"
echo -e "  ${DIM}Action:${NC}   In a result split, press 't'"
echo -e "  ${DIM}Expected:${NC} vim.ui.select: 'Full text' / 'Action items only'"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 54: 't' — Send to Obsidian daily note"
if [[ "$HAS_OBSIDIAN" != "true" ]]; then
    echo -e "${BLUE}${BOLD}TEST 54: 't' — Send to Obsidian daily note${NC}"
    echo -e "  ${YELLOW}AUTO-SKIP${NC}: Obsidian not installed"
    ((SKIP++)) || true
    SKIPPED_TESTS+=("$CURRENT_TEST")
else
    echo -e "${BLUE}${BOLD}TEST 54: 't' — Send to Obsidian daily note${NC}"
    echo -e "  ${DIM}Action:${NC}   Press 't' → Full text → Obsidian daily note"
    echo -e "  ${DIM}Expected:${NC} Content appended to vault/Daily/YYYY-MM-DD.md with title + timestamp"
    echo ""
    echo "  Try in Neovim"
    ask_result
fi

echo ""
CURRENT_TEST="TEST 55: 't' — Send to macOS Reminders"
if [[ "$IS_MACOS" != "true" ]]; then
    echo -e "${BLUE}${BOLD}TEST 55: 't' — Send to macOS Reminders${NC}"
    echo -e "  ${YELLOW}AUTO-SKIP${NC}: Not on macOS (Reminders.app required)"
    ((SKIP++)) || true
    SKIPPED_TESTS+=("$CURRENT_TEST")
else
    echo -e "${BLUE}${BOLD}TEST 55: 't' — Send to macOS Reminders${NC}"
    echo -e "  ${DIM}Action:${NC}   Press 't' → Full text → macOS Reminders"
    echo -e "  ${DIM}Expected:${NC} Notification: 'Added to Reminders', new reminder appears in Reminders app"
    echo ""
    echo "  Try in Neovim"
    ask_result
fi

echo ""
CURRENT_TEST="TEST 56: Statusline shows new keybinds"
echo -e "${BLUE}${BOLD}TEST 56: Statusline shows new keybinds${NC}"
echo -e "  ${DIM}Action:${NC}   Open any AI result split, look at the statusline"
echo -e "  ${DIM}Expected:${NC} Shows e=edit  c=revise  n=next  t=todo alongside existing keybinds"
echo ""
echo "  Try in Neovim"
ask_result

# ═══════════════════════════════════════════════════════════════
# SECTION 11: Tab Completion
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== TAB COMPLETION ===${NC}"

echo ""
CURRENT_TEST="TEST 57: :HimalayaAi + Tab"
echo -e "${BLUE}${BOLD}TEST 57: :HimalayaAi + Tab${NC}"
echo -e "  ${DIM}Action:${NC}   Type :HimalayaAi (space) then press Tab"
echo -e "  ${DIM}Expected:${NC} Completion menu: status, prompts, edit, validate, set"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 58: :HimalayaAi set + Tab"
echo -e "${BLUE}${BOLD}TEST 58: :HimalayaAi set + Tab${NC}"
echo -e "  ${DIM}Action:${NC}   Type :HimalayaAi set (space) then press Tab"
echo -e "  ${DIM}Expected:${NC} Completion menu: backend, vault, save_dir, format, result_display, todo_target"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 59: :HimalayaAi set result_display + Tab"
echo -e "${BLUE}${BOLD}TEST 59: :HimalayaAi set result_display + Tab${NC}"
echo -e "  ${DIM}Action:${NC}   Type :HimalayaAi set result_display (space) then press Tab"
echo -e "  ${DIM}Expected:${NC} Completion menu: split, tab"
echo ""
echo "  Try in Neovim"
ask_result

echo ""
CURRENT_TEST="TEST 60: :HimalayaAi set todo_target + Tab"
echo -e "${BLUE}${BOLD}TEST 60: :HimalayaAi set todo_target + Tab${NC}"
echo -e "  ${DIM}Action:${NC}   Type :HimalayaAi set todo_target (space) then press Tab"
echo -e "  ${DIM}Expected:${NC} Completion menu: obsidian, reminders, ask"
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

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo ""
    echo -e "  ${RED}${BOLD}Failed:${NC}"
    for t in "${FAILED_TESTS[@]}"; do
        echo -e "    ${RED}✗${NC} $t"
    done
fi

if [[ ${#SKIPPED_TESTS[@]} -gt 0 ]]; then
    echo ""
    echo -e "  ${YELLOW}${BOLD}Skipped:${NC}"
    for t in "${SKIPPED_TESTS[@]}"; do
        echo -e "    ${YELLOW}–${NC} $t"
    done
fi

echo ""
echo "  Test log: $(date '+%Y-%m-%d %H:%M')"
echo ""
