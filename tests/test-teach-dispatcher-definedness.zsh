#!/usr/bin/env zsh
# tests/test-teach-dispatcher-definedness.zsh
#
# Purpose: Guard against a `teach` dispatch case wired to a function that no
#          longer exists (or never existed) — the class of bug behind
#          `_teach_show_week` being called from teach-main.zsh's `week|w)`
#          case for ~8 months while the function itself was accidentally
#          deleted in 72f8e9717 (a later commit's diff clobbered it while
#          inserting the backup-command feature at the same file offset).
#
# Strategy: Extract every `_teach_*` token referenced in teach-main.zsh (the
#           dispatcher's case statement lives there), source the full plugin
#           in a clean shell, then assert each token is a defined function.
#           This does not care which module actually defines it — only that
#           it exists somewhere after loading — so it catches cross-module
#           wiring breaks the same way `test-teach-dispatcher-characterization.zsh`'s
#           mocked functions cannot (mocking a name papers over exactly this bug).

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

export FLOW_QUIET=1
export FLOW_ATLAS_ENABLED=no
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

test_suite_start "teach dispatcher definedness (regression guard)"

local main_file="$PROJECT_ROOT/lib/dispatchers/teach/teach-main.zsh"

test_case "teach-main.zsh exists and is readable"
assert_file_exists "$main_file"
test_case_end

local -a tokens
tokens=($(grep -oE '_teach_[A-Za-z0-9_]+' "$main_file" | sort -u))

test_case "extracted at least one _teach_* token from teach-main.zsh"
if (( ${#tokens[@]} == 0 )); then
    test_fail "No _teach_* tokens found — extraction pattern may be broken"
else
    test_pass
fi
test_case_end

local token
for token in "${tokens[@]}"; do
    test_case "defined after sourcing flow.plugin.zsh: $token"
    assert_function_exists "$token"
    test_case_end
done

test_suite_end
