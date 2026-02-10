#!/usr/bin/env zsh
# scripts/check-math.zsh — Standalone display-math validator
# Used by lint-staged (pre-commit) and callable standalone.
# Sources _check_math_blanks from teach-deploy-enhanced.zsh.
#
# Usage: zsh scripts/check-math.zsh file1.qmd file2.qmd ...
# Exit:  0 = all clean, 1 = issues found

setopt LOCAL_OPTIONS EXTENDED_GLOB

# Resolve script directory → project root
local script_dir="${0:A:h}"
local project_root="${script_dir:h}"

# Source the math-blanks checker
source "${project_root}/lib/dispatchers/teach-deploy-enhanced.zsh" 2>/dev/null

if ! typeset -f _check_math_blanks >/dev/null 2>&1; then
    print -P "%F{red}ERROR:%f Could not load _check_math_blanks from lib/dispatchers/teach-deploy-enhanced.zsh"
    exit 1
fi

# ── Validate arguments ──────────────────────────────────────────────
if (( $# == 0 )); then
    print -P "%F{yellow}Usage:%f zsh scripts/check-math.zsh <file.qmd> ..."
    exit 0
fi

# ── Check each file ─────────────────────────────────────────────────
local -i issues=0
local file rc

for file in "$@"; do
    [[ ! -f "$file" ]] && continue
    [[ "${file:e}" != "qmd" ]] && continue

    _check_math_blanks "$file"
    rc=$?

    case $rc in
        0) ;; # clean
        1)
            print -P "%F{red}FAIL%f  $file — blank line inside \$\$ block (breaks PDF)"
            (( issues++ ))
            ;;
        2)
            print -P "%F{red}FAIL%f  $file — unclosed \$\$ block (breaks render)"
            (( issues++ ))
            ;;
    esac
done

if (( issues > 0 )); then
    print -P "\n%F{red}${issues} file(s) with display-math issues.%f Fix before committing."
    exit 1
fi

exit 0
