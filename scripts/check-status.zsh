#!/usr/bin/env zsh
# scripts/check-status.zsh — Standalone .STATUS schema validator (WARN-ONLY)
# Used by lint-staged (pre-commit) and callable standalone. Model:
# scripts/check-math.zsh — same shape, different exit-code contract.
#
# SPEC-planning-coordination-2026-07-01 §3.6 (D9/D11): flow-cli-scoped only
# (not an ecosystem-wide standard). Validates required header fields,
# Progress (integer 0-100), Status (allowed set), and ## Schedule: grammar.
#
# D11 — HARD CONSTRAINT: this script ALWAYS exits 0. It prints violations,
# it never blocks a commit. Flip to blocking only in a future follow-up once
# flow-cli's own .STATUS + the template are confirmed compliant across the
# ecosystem — not this cycle.
#
# Usage: zsh scripts/check-status.zsh file1/.STATUS file2/.STATUS ...
# Exit:  ALWAYS 0

setopt LOCAL_OPTIONS EXTENDED_GLOB

local script_dir="${0:A:h}"
local project_root="${script_dir:h}"

# Only need _flow_status_field — lib/core.zsh is self-contained (no module
# guard, no dependency on other lib/*.zsh files), same lightweight-source
# pattern check-math.zsh uses for teach-deploy-enhanced.zsh.
source "${project_root}/lib/core.zsh" 2>/dev/null

if ! typeset -f _flow_status_field >/dev/null 2>&1; then
    print -P "%F{red}ERROR:%f Could not load _flow_status_field from lib/core.zsh"
    print -P "%F{yellow}(warn-only: not blocking despite the internal error)%f"
    exit 0
fi

if (( $# == 0 )); then
    print -P "%F{yellow}Usage:%f zsh scripts/check-status.zsh <.STATUS file> ..."
    exit 0
fi

typeset -a REQUIRED_FIELDS=(Project Type Status Focus Phase Priority Progress)
typeset -a ALLOWED_STATUS=(active paused archived blocked)
typeset -gi TOTAL_ISSUES=0

# Normalize a Status value the same way _flow_status_field does internally,
# so a synonym it already accepts ("In Progress", "WIP", ...) is not flagged
# as a violation here.
_check_status_normalize() {
    local v="${1:l}"
    v="${v// /}"
    case "$v" in
        underreview|inprogress|wip) v="active" ;;
        onhold) v="paused" ;;
    esac
    print -r -- "$v"
}

_check_status_file() {
    local file="$1"
    local root="${file:h}"
    local tmp_status_dir=""

    # _flow_status_field expects a ROOT dir and always reads "<root>/.STATUS"
    # (lib/core.zsh's established contract — do not special-case it here,
    # that would risk the Phase 1 parity guard for every other caller).
    # Real .STATUS files satisfy this directly. But this script is also
    # asked to validate templates/.STATUS.template — a file that documents
    # the shape without being named ".STATUS" itself. For any file NOT
    # literally named ".STATUS", stage a throwaway copy under that exact
    # name so _flow_status_field's contract is met without duplicating its
    # parsing logic here.
    if [[ "${file:t}" != ".STATUS" ]]; then
        tmp_status_dir=$(mktemp -d)
        cp "$file" "$tmp_status_dir/.STATUS"
        root="$tmp_status_dir"
    fi

    # NOTE: all locals used inside the loops below are declared ONCE here,
    # not redeclared per iteration — redeclaring `local` on an already-local
    # variable inside a loop is a reproducible zsh quirk that echoes the
    # previous iteration's value to stdout (see lib/core.zsh's
    # _flow_suggest_project for the first discovery of this). `status` is
    # additionally a zsh READ-ONLY special variable (even function-local —
    # see lib/atlas-bridge.zsh's _flow_where_fallback fix in Phase 1), hence
    # `proj_status` instead.
    local field val progress pnum proj_status norm

    # ---- Required fields present ----
    for field in "${REQUIRED_FIELDS[@]}"; do
        val=$(_flow_status_field "$root" "$field")
        if [[ -z "$val" ]]; then
            print -P "%F{yellow}WARN%f  $file — missing required field: ## ${field}:"
            (( TOTAL_ISSUES++ ))
        fi
    done

    # ---- Progress: integer 0-100 ----
    progress=$(_flow_status_field "$root" "Progress")
    if [[ -n "$progress" ]]; then
        pnum="${progress//%/}"
        if [[ ! "$pnum" == <-> ]] || (( pnum < 0 || pnum > 100 )); then
            print -P "%F{yellow}WARN%f  $file — Progress not an integer 0-100: '$progress'"
            (( TOTAL_ISSUES++ ))
        fi
    fi

    # ---- Status: allowed set (synonym-tolerant) ----
    proj_status=$(_flow_status_field "$root" "Status")
    if [[ -n "$proj_status" ]]; then
        norm=$(_check_status_normalize "$proj_status")
        if (( ! ${ALLOWED_STATUS[(Ie)$norm]} )); then
            print -P "%F{yellow}WARN%f  $file — Status '$proj_status' not in allowed set (active|paused|archived|blocked, or a recognized synonym)"
            (( TOTAL_ISSUES++ ))
        fi
    fi

    # ---- ## Schedule: grammar ----
    # Mirrors _schedule_parse_status's grammar (lib/schedule.zsh): a line the
    # real parser can't match is silently skipped there (invisible, not
    # fatal) — this is exactly the class of mistake worth flagging here.
    local in_section=0 line body when label
    local -a parts
    local -i lineno=0
    while IFS= read -r line; do
        (( lineno++ ))
        if [[ "$line" == "## Schedule:"* ]]; then
            in_section=1
            continue
        fi
        if (( in_section )) && [[ "$line" == "## "* ]]; then
            in_section=0
            continue
        fi
        (( in_section )) || continue

        [[ "$line" == "-"* ]] || continue
        body="${line#-}"
        body="${body#"${body%%[![:space:]]*}"}"
        [[ -z "$body" ]] && continue

        parts=("${(@s:|:)body}")
        when="${parts[1]//[[:space:]]/}"
        label="${parts[2]:-}"
        label="${label#"${label%%[![:space:]]*}"}"

        if [[ -z "$when" || -z "$label" ]] \
           || { [[ "$when" != [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] ]] && [[ "$when" != weekly:* ]] ; }; then
            print -P "%F{yellow}WARN%f  $file:$lineno — Schedule line doesn't match grammar (expected '- YYYY-MM-DD | label | type' or '- weekly:<dow> | label | type'): '$line'"
            (( TOTAL_ISSUES++ ))
        fi
    done < "$file"

    [[ -n "$tmp_status_dir" ]] && rm -rf "$tmp_status_dir"
}

local file
for file in "$@"; do
    [[ -f "$file" ]] || continue
    _check_status_file "$file"
done

if (( TOTAL_ISSUES > 0 )); then
    print -P "\n%F{yellow}${TOTAL_ISSUES} .STATUS schema issue(s) found (warn-only — not blocking, D11).%f"
fi

exit 0
