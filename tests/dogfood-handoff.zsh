#!/usr/bin/env zsh
# dogfood-handoff.zsh - Real-world usage check for `flow handoff`
#
# Unlike e2e-handoff.zsh (isolated temp repo), this runs the command against
# THIS actual repo and the actual feature/flow-handoff-command branch, to
# verify it behaves sensibly on real data before merge. Cleans up its own
# generated artifact - this is a test run, not a real handoff.
#
# Usage: zsh tests/dogfood-handoff.zsh

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

cd "$PROJECT_ROOT" || exit 1
source "$PROJECT_ROOT/lib/handoff-helpers.zsh"

DOGFOOD_SLUG="dogfood-self-test-$$"
DOGFOOD_FILE="$PROJECT_ROOT/docs/planning/HANDOFF-${DOGFOOD_SLUG}.md"

cleanup() {
    rm -f "$DOGFOOD_FILE"
}
trap cleanup EXIT

echo "${CYAN}Dogfooding: flow handoff against real repo, real branch${RESET}"
echo ""

current_branch=$(git branch --show-current)
echo "  Branch under test: $current_branch"

_flow_handoff "$DOGFOOD_SLUG" --base dev
rc=$?

if [[ $rc -ne 0 ]]; then
    echo "${RED}✗ Command exited non-zero ($rc) on real repo${RESET}"
    exit 1
fi

if [[ ! -f "$DOGFOOD_FILE" ]]; then
    echo "${RED}✗ Expected file not created: $DOGFOOD_FILE${RESET}"
    exit 1
fi

echo ""
echo "${CYAN}Generated Relevant Files section (real diff against dev):${RESET}"
sed -n '/## Relevant Files/,/## Open Work/p' "$DOGFOOD_FILE" | sed '$d' | sed 's/^/    /'

echo ""
actual_changed_files=$(git diff --name-only dev...HEAD -- 2>/dev/null | wc -l | tr -d ' ')
listed_files=$(grep -c '^- `' "$DOGFOOD_FILE")

if [[ "$actual_changed_files" -gt 0 && "$listed_files" -ne "$actual_changed_files" ]]; then
    echo "${YELLOW}⚠ Listed file count ($listed_files) doesn't match actual diff count ($actual_changed_files)${RESET}"
    echo "  ${YELLOW}(not a hard failure - review manually if this looks wrong)${RESET}"
fi

echo "${GREEN}✓ Dogfood run completed and artifact cleaned up${RESET}"
echo ""
echo "${CYAN}Reminder:${RESET} this test's generated file is deleted automatically on exit -"
echo "it is a test run, not a real handoff for this branch."
exit 0
