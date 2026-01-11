#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE DOT DOGFOODING TEST
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: ADHD-friendly interactive test that validates DOT dispatcher v5.1.1
#          features by showing expected output and asking user to confirm matches
#
# Theme: "Dotfile Chef" - Cook up your perfect configuration! 👨‍🍳
#
# Usage: ./interactive-dot-dogfooding.zsh
#
# What it tests:
#   - dot add (standalone add command)
#   - dot edit auto-add (add untracked files)
#   - dot edit create (create new files with mkdir -p)
#   - Template detection (Bitwarden templates)
#   - Summary with tips
#   - ZDOTDIR support
#   - Help text updates
#
# ══════════════════════════════════════════════════════════════════════════════

# Colors and emojis
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Theme emojis
CHEF='👨‍🍳'
POT='🍲'
FIRE='🔥'
STAR='⭐'
SPARKLE='✨'
RECIPE='📜'
INGREDIENT='🥬'
SALT='🧂'
DONE='✅'
FAIL='❌'
THINKING='🤔'
EYES='👀'
QUESTION='❓'
LOCK='🔐'
KEY='🔑'
FOLDER='📁'
FILE='📄'
TIP='💡'

# Game state
DISHES_PREPARED=0
TOTAL_DISHES=8
CHEF_RATING=50
KITCHEN_HEAT=100

# Test files (cleaned up at end)
TEST_PREFIX=".dotfood-test-$$"
declare -a CLEANUP_FILES

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

print_banner() {
  echo ""
  echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${MAGENTA}║${NC}  ${CHEF}  ${BOLD}DOTFILE CHEF - Interactive Testing${NC}  ${POT}                ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}║${NC}      ${DIM}Cook up your perfect configuration!${NC}                   ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

print_kitchen_status() {
  local mood
  if [[ $CHEF_RATING -gt 70 ]]; then
    mood="${GREEN}${STAR}${STAR}${STAR} Michelin Star Chef!${NC}"
  elif [[ $CHEF_RATING -gt 40 ]]; then
    mood="${YELLOW}${STAR}${STAR} Skilled Cook${NC}"
  else
    mood="${RED}${STAR} Apprentice${NC}"
  fi

  echo ""
  echo -e "${CYAN}╭─ Kitchen Status ─────────────────────────────────────────╮${NC}"
  echo -e "${CYAN}│${NC} Heat:     ${YELLOW}${FIRE} $KITCHEN_HEAT%${NC}"
  echo -e "${CYAN}│${NC} Rating:   $mood"
  echo -e "${CYAN}│${NC} Dishes:   ${GREEN}$DISHES_PREPARED${NC}/${TOTAL_DISHES} prepared"
  echo -e "${CYAN}╰──────────────────────────────────────────────────────────╯${NC}"
  echo ""
}

prepare_dish() {
  local points=$1
  KITCHEN_HEAT=$((KITCHEN_HEAT - 5))
  CHEF_RATING=$((CHEF_RATING + points / 2))

  [[ $KITCHEN_HEAT -lt 20 ]] && KITCHEN_HEAT=20
  [[ $CHEF_RATING -gt 100 ]] && CHEF_RATING=100

  echo -e "${GREEN}${DONE} Dish prepared! ${SPARKLE}${NC}"
  ((DISHES_PREPARED++))
}

burn_dish() {
  CHEF_RATING=$((CHEF_RATING - 10))
  [[ $CHEF_RATING -lt 0 ]] && CHEF_RATING=0
  echo -e "${RED}${FAIL} Dish burned! ${FIRE}${NC}"
}

press_any_key() {
  echo ""
  echo -e "${DIM}Press any key to continue...${NC}"
  read -k1 -s
}

ask_confirmation() {
  local prompt="$1"
  local default="${2:-y}"

  echo ""
  echo -e "${BOLD}${QUESTION} ${prompt}${NC}"
  echo -e "${DIM}(y/n, default: ${default})${NC}"
  echo -n "> "

  local response
  read -k1 response
  echo ""

  # Treat Enter (newline) as empty → use default
  [[ -z "$response" || "$response" == $'\n' ]] && response="$default"
  response="${response:l}"

  [[ "$response" == "y" ]]
}

show_recipe() {
  local title="$1"
  shift
  local -a ingredients=("$@")

  echo ""
  echo -e "${MAGENTA}╭─ Recipe: ${title} ─────────────────────────────────────╮${NC}"
  for ingredient in "${ingredients[@]}"; do
    echo -e "${MAGENTA}│${NC}  ${INGREDIENT} ${ingredient}"
  done
  echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────╯${NC}"
  echo ""
}

run_dish_test() {
  local dish_name="$1"
  local command="$2"
  shift 2
  local reward="${@[-1]}"
  local success_msg="${@[-2]}"
  local num_checks=$(($# - 2))
  local -a expected_checks=("${@:1:$num_checks}")

  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${BLUE}${RECIPE} Dish: ${dish_name}${NC}"
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""

  echo -e "${CYAN}Command to execute:${NC}"
  echo -e "${BOLD}  $ ${command}${NC}"

  show_recipe "What to look for:" "${expected_checks[@]}"

  echo -e "${YELLOW}${EYES} Watch the output carefully...${NC}"
  press_any_key

  echo ""
  echo -e "${CYAN}╭─ Cooking... ─────────────────────────────────────────────╮${NC}"
  eval "$command" 2>&1
  echo -e "${CYAN}╰──────────────────────────────────────────────────────────╯${NC}"

  if ask_confirmation "Does the output match the recipe?"; then
    echo ""
    echo -e "${success_msg}"
    prepare_dish $reward
    return 0
  else
    echo ""
    echo -e "${YELLOW}Let's review:${NC}"
    echo -e "  ${DIM}1. Did the command complete without errors?${NC}"
    echo -e "  ${DIM}2. Did you see all the expected ingredients?${NC}"
    echo -e "  ${DIM}3. Check if there's a bug to report${NC}"
    burn_dish

    if ask_confirmation "Continue to next dish anyway?"; then
      return 0
    else
      return 1
    fi
  fi
}

cleanup() {
  echo ""
  echo -e "${DIM}${CHEF} Cleaning up the kitchen...${NC}"

  for file in "${CLEANUP_FILES[@]}"; do
    if [[ -f "$file" ]]; then
      chezmoi forget "$file" 2>/dev/null
      rm -f "$file" 2>/dev/null
    fi
  done

  # Clean any files matching test prefix (nullglob prevents error when no matches)
  setopt localoptions nullglob
  for file in $HOME/${TEST_PREFIX}*; do
    if [[ -f "$file" ]]; then
      chezmoi forget "$file" 2>/dev/null
      rm -f "$file"
    fi
  done

  rm -rf "$HOME/.config/dotfood-test-$$" 2>/dev/null

  echo -e "${GREEN}${DONE} Kitchen is clean!${NC}"
}

trap cleanup EXIT

# ══════════════════════════════════════════════════════════════════════════════
# PREREQUISITE CHECK
# ══════════════════════════════════════════════════════════════════════════════

check_prerequisites() {
  echo -e "${CHEF} Checking kitchen equipment..."
  echo ""

  # Check chezmoi
  if ! command -v chezmoi &>/dev/null; then
    echo -e "${RED}${FAIL} chezmoi not installed${NC}"
    echo -e "${DIM}Install with: brew install chezmoi${NC}"
    return 1
  fi
  echo -e "${GREEN}${DONE}${NC} chezmoi installed"

  # Check chezmoi initialized
  if [[ ! -d "$HOME/.local/share/chezmoi" ]]; then
    echo -e "${RED}${FAIL} chezmoi not initialized${NC}"
    echo -e "${DIM}Initialize with: chezmoi init${NC}"
    return 1
  fi
  echo -e "${GREEN}${DONE}${NC} chezmoi initialized"

  # Check flow-cli
  local script_dir
  if [[ -n "${0:A:h}" ]]; then
    script_dir="${0:A:h}"
  else
    script_dir="$(cd "$(dirname "$0")" && pwd)"
  fi
  export FLOW_CLI_ROOT="${script_dir:h}"

  # Verify the path exists
  if [[ ! -d "$FLOW_CLI_ROOT/lib" ]]; then
    FLOW_CLI_ROOT="/Users/dt/projects/dev-tools/flow-cli"
  fi

  if [[ ! -f "$FLOW_CLI_ROOT/lib/dispatchers/dot-dispatcher.zsh" ]]; then
    echo -e "${RED}${FAIL} dot-dispatcher.zsh not found${NC}"
    return 1
  fi
  echo -e "${GREEN}${DONE}${NC} flow-cli located"

  # Source files
  source "$FLOW_CLI_ROOT/lib/core.zsh" 2>/dev/null || true
  source "$FLOW_CLI_ROOT/lib/dotfile-helpers.zsh" 2>/dev/null
  source "$FLOW_CLI_ROOT/lib/dispatchers/dot-dispatcher.zsh" 2>/dev/null

  echo -e "${GREEN}${DONE}${NC} All equipment ready!"
  echo ""
  return 0
}

# ══════════════════════════════════════════════════════════════════════════════
# DISH 1: Help Menu
# ══════════════════════════════════════════════════════════════════════════════

dish_help_menu() {
  run_dish_test \
    "Help Menu - Check the Recipe Book" \
    "dot help" \
    "Shows 'dot add FILE' command" \
    "Shows 'auto-add/create' in edit description" \
    "Shows example with ~ path" \
    "${GREEN}${SPARKLE} The recipe book is updated!${NC}" \
    15
}

# ══════════════════════════════════════════════════════════════════════════════
# DISH 2: Add Command
# ══════════════════════════════════════════════════════════════════════════════

dish_add_command() {
  local test_file="$HOME/${TEST_PREFIX}-dish-add"
  CLEANUP_FILES+=("$test_file")

  echo "# Dish 2 - Add Command Test" > "$test_file"

  run_dish_test \
    "Add Ingredient - dot add" \
    "dot add $test_file" \
    "Shows '✓ Added' message" \
    "Shows 'Source:' path" \
    "Shows '💡 Tip: dot edit' suggestion" \
    "${GREEN}${SPARKLE} New ingredient added to the pantry!${NC}" \
    15
}

# ══════════════════════════════════════════════════════════════════════════════
# DISH 3: Add Already Tracked
# ══════════════════════════════════════════════════════════════════════════════

dish_add_already_tracked() {
  local test_file="$HOME/${TEST_PREFIX}-dish-tracked"
  CLEANUP_FILES+=("$test_file")

  echo "# Already tracked test" > "$test_file"
  chezmoi add "$test_file" 2>/dev/null

  run_dish_test \
    "Already in Pantry - dot add (duplicate)" \
    "dot add $test_file" \
    "Shows 'Already tracked' message" \
    "Does NOT show error" \
    "Returns gracefully" \
    "${GREEN}${SPARKLE} Smart - didn't add duplicate!${NC}" \
    10
}

# ══════════════════════════════════════════════════════════════════════════════
# DISH 4: Template Detection
# ══════════════════════════════════════════════════════════════════════════════

dish_template_detection() {
  local test_file="$HOME/${TEST_PREFIX}-secret.tmpl"
  CLEANUP_FILES+=("$test_file")

  echo 'export API_KEY="{{ bitwarden "myapp" "api_key" }}"' > "$test_file"

  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${BLUE}${RECIPE} Dish: Secret Recipe - Template Detection${NC}"
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""

  echo -e "${LOCK} Testing Bitwarden template detection..."
  echo ""
  echo -e "Created template file: ${BOLD}$test_file${NC}"
  echo -e "Contains: ${DIM}{{ bitwarden \"myapp\" \"api_key\" }}${NC}"
  echo ""

  if _dot_has_bitwarden_template "$test_file"; then
    echo -e "${GREEN}${DONE} Template detected correctly!${NC}"
    echo ""
    echo -e "${KEY} The chef knows this recipe needs the secret vault!"
    prepare_dish 15
  else
    echo -e "${RED}${FAIL} Template NOT detected!${NC}"
    echo -e "${DIM}The _dot_has_bitwarden_template function failed${NC}"
    burn_dish
  fi

  press_any_key
}

# ══════════════════════════════════════════════════════════════════════════════
# DISH 5: Summary Output
# ══════════════════════════════════════════════════════════════════════════════

dish_summary_output() {
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${BLUE}${RECIPE} Dish: Plating - Summary Output${NC}"
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""

  echo -e "Testing _dot_print_summary function..."
  echo ""

  echo -e "${CYAN}Test 1: Applied status${NC}"
  _dot_print_summary ".zshrc" "Edited" "Applied"
  echo ""

  if ask_confirmation "Does it show 'dot push' tip?"; then
    echo -e "${GREEN}${DONE} Push tip shown correctly${NC}"
  else
    burn_dish
    return
  fi

  echo ""
  echo -e "${CYAN}Test 2: Staging status${NC}"
  _dot_print_summary ".gitconfig" "Added" "Staging"
  echo ""

  if ask_confirmation "Does it show 'dot apply' tip?"; then
    echo -e "${GREEN}${DONE} Apply tip shown correctly${NC}"
    echo ""
    echo -e "${TIP} Perfect plating with helpful hints!"
    prepare_dish 15
  else
    burn_dish
  fi

  press_any_key
}

# ══════════════════════════════════════════════════════════════════════════════
# DISH 6: ZDOTDIR Check
# ══════════════════════════════════════════════════════════════════════════════

dish_zdotdir_check() {
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${BLUE}${RECIPE} Dish: Local Sourcing - ZDOTDIR Support${NC}"
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""

  local helpers_file="$FLOW_CLI_ROOT/lib/dotfile-helpers.zsh"

  echo -e "${FOLDER} Checking ${BOLD}dotfile-helpers.zsh${NC}..."
  echo ""

  if [[ -f "$helpers_file" ]]; then
    local source_code=$(< "$helpers_file")

    if [[ "$source_code" == *'${ZDOTDIR:-$HOME}'* ]]; then
      echo -e "${GREEN}${DONE} Uses \${ZDOTDIR:-\$HOME} pattern${NC}"
      echo ""
      echo -e "${DIM}This means it respects custom ZSH config locations!${NC}"
      echo -e "${DIM}Users with ZDOTDIR set will have correct paths.${NC}"
      echo ""
      echo -e "${SPARKLE} Chef respects local sourcing preferences!"
      prepare_dish 15
    else
      echo -e "${RED}${FAIL} ZDOTDIR pattern not found${NC}"
      echo -e "${DIM}Should use \${ZDOTDIR:-\$HOME} instead of \$HOME${NC}"
      burn_dish
    fi
  else
    echo -e "${RED}${FAIL} Helper file not found${NC}"
    burn_dish
  fi

  press_any_key
}

# ══════════════════════════════════════════════════════════════════════════════
# DISH 7: Add Non-existent File
# ══════════════════════════════════════════════════════════════════════════════

dish_add_nonexistent() {
  run_dish_test \
    "Missing Ingredient - dot add (non-existent)" \
    "dot add /this/file/does/not/exist.txt" \
    "Shows error message" \
    "Says 'does not exist'" \
    "Does NOT crash" \
    "${GREEN}${SPARKLE} Properly rejected missing ingredient!${NC}" \
    10
}

# ══════════════════════════════════════════════════════════════════════════════
# DISH 8: Final Status Check
# ══════════════════════════════════════════════════════════════════════════════

dish_final_status() {
  run_dish_test \
    "Final Inspection - dot status" \
    "dot status" \
    "Shows status without errors" \
    "Shows tracked files count" \
    "Shows sync status icon (🟢/🟡/🔴/🔵)" \
    "${GREEN}${SPARKLE} Kitchen passes inspection!${NC}" \
    15
}

# ══════════════════════════════════════════════════════════════════════════════
# FINAL RESULTS
# ══════════════════════════════════════════════════════════════════════════════

show_final_results() {
  echo ""
  echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${MAGENTA}║${NC}  ${CHEF}  ${BOLD}KITCHEN INSPECTION COMPLETE${NC}  ${SPARKLE}                     ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"

  print_kitchen_status

  local grade
  local message

  if [[ $DISHES_PREPARED -eq $TOTAL_DISHES ]]; then
    grade="${GREEN}${BOLD}★★★ MICHELIN STAR${NC}"
    message="Perfect score! All dishes prepared flawlessly!"
  elif [[ $DISHES_PREPARED -ge 6 ]]; then
    grade="${GREEN}★★☆ EXCELLENT${NC}"
    message="Great work! Minor issues to address."
  elif [[ $DISHES_PREPARED -ge 4 ]]; then
    grade="${YELLOW}★☆☆ GOOD${NC}"
    message="Solid effort. Some recipes need attention."
  else
    grade="${RED}☆☆☆ NEEDS WORK${NC}"
    message="Several dishes failed. Review the recipes!"
  fi

  echo -e "${BOLD}Final Grade:${NC} $grade"
  echo ""
  echo -e "${DIM}$message${NC}"
  echo ""

  if [[ $DISHES_PREPARED -eq $TOTAL_DISHES ]]; then
    echo -e "${SPARKLE}${SPARKLE}${SPARKLE} ${GREEN}All v5.1.1 features working perfectly!${NC} ${SPARKLE}${SPARKLE}${SPARKLE}"
  else
    echo -e "${YELLOW}Run the automated tests for more details:${NC}"
    echo -e "  ${DIM}zsh tests/test-dot-v5.1.1-unit.zsh${NC}"
    echo -e "  ${DIM}zsh tests/test-dot-v5.1.1-e2e.zsh${NC}"
  fi

  echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
  clear
  print_banner

  if ! check_prerequisites; then
    echo ""
    echo -e "${RED}${FAIL} Cannot start - prerequisites not met${NC}"
    exit 1
  fi

  press_any_key

  print_kitchen_status

  echo -e "${CHEF} Welcome to the Dotfile Kitchen!"
  echo -e "${DIM}We'll test the new DOT dispatcher v5.1.1 features${NC}"
  echo ""

  if ! ask_confirmation "Ready to start cooking?"; then
    echo -e "${DIM}Come back when you're ready!${NC}"
    exit 0
  fi

  # Run all dishes
  dish_help_menu || true
  dish_add_command || true
  dish_add_already_tracked || true
  dish_template_detection || true
  dish_summary_output || true
  dish_zdotdir_check || true
  dish_add_nonexistent || true
  dish_final_status || true

  show_final_results
}

main "$@"
