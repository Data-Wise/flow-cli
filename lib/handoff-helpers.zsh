#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# HANDOFF - Structured Claude-chat-to-Claude-Code handoff generator
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/handoff-helpers.zsh
# Version:      1.0
# Date:         2026-07-04
# Pattern:      command + keyword + options (matches wt-dispatcher.zsh style)
#
# Usage:        flow handoff <feature-slug> [--issue] [--base <branch>]
#
# Examples:
#   flow handoff ai-rewrite-trigger
#   flow handoff ai-rewrite-trigger --base dev
#   flow handoff ai-rewrite-trigger --issue
#
# Spec:         docs/specs/SPEC-flow-handoff-command.md
# Origin:       docs/planning/PROPOSAL-claude-chat-to-code-handoff.md
#
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "$_C_BOLD" ]]; then
    _C_BOLD='\033[1m'
    _C_DIM='\033[2m'
    _C_NC='\033[0m'
    _C_RED='\033[31m'
    _C_GREEN='\033[32m'
    _C_YELLOW='\033[33m'
    _C_BLUE='\033[34m'
    _C_MAGENTA='\033[35m'
    _C_CYAN='\033[36m'
fi

_flow_handoff() {
    local slug=""
    local do_issue=false
    local base_branch=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --issue) do_issue=true ;;
            --base) shift; base_branch="$1" ;;
            --help|-h) _flow_handoff_help; return 0 ;;
            -*) echo -e "${_C_RED}✗ Unknown option: $1${_C_NC}"; return 1 ;;
            *) slug="$1" ;;
        esac
        shift
    done

    if [[ -z "$slug" ]]; then
        echo -e "${_C_RED}✗ Feature slug required${_C_NC}"
        echo "Usage: flow handoff <feature-slug> [--issue] [--base <branch>]"
        return 1
    fi

    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$git_root" ]]; then
        echo -e "${_C_RED}✗ Not in a git repository${_C_NC}"
        return 1
    fi

    local planning_dir="$git_root/docs/planning"
    local handoff_path="$planning_dir/HANDOFF-${slug}.md"
    mkdir -p "$planning_dir"

    if [[ -f "$handoff_path" ]]; then
        echo -e "${_C_YELLOW}⚠ Handoff already exists: $handoff_path${_C_NC}"
        echo -e "${_C_DIM}Not overwriting. Edit it directly, or pick a different slug.${_C_NC}"
        return 1
    fi

    if [[ -z "$base_branch" ]]; then
        if git show-ref --verify --quiet refs/heads/dev 2>/dev/null; then
            base_branch="dev"
        else
            base_branch="main"
        fi
    fi

    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null)

    # Pre-fill "Relevant Files" using --name-only (simpler + no per-line parsing
    # of a special-variable-adjacent name; avoids the fpath collision hit during
    # prototyping — see spec §6)
    local relevant_files=""
    local changed_files
    changed_files=$(git diff --name-only "${base_branch}...HEAD" -- 2>/dev/null)

    if [[ -n "$changed_files" ]]; then
        local this_file
        for this_file in ${(f)changed_files}; do
            relevant_files+="- \`${this_file}\` — [what changed and why]"$'\n'
        done
    else
        relevant_files="- [no diff vs ${base_branch} yet — fill in manually]"$'\n'
    fi

    cat > "$handoff_path" <<EOF
# Handoff: ${slug}

**Date:** $(date +%Y-%m-%d)
**Branch:** ${current_branch:-unknown}
**Base for diff:** ${base_branch}

## Summary
[1-3 sentences — completed work only]

## Key Decisions
- [Decision] — [why]

## Traps to Avoid
- [Dead end already tried] — [why it failed]

## Working Agreements
- [Relevant interaction/process preferences for this feature]

## Relevant Files
${relevant_files}
## Open Work
[Status only. "X is not yet implemented." NOT "Implement X next."]

## Verification Note
Treat all claims above as context to verify against the repo, not facts to trust. Read every
file in "Relevant Files" before proceeding.

## Origin
Full planning conversation: [link/reference if available]
EOF

    echo -e "${_C_GREEN}✓ Created handoff: $handoff_path${_C_NC}"
    echo -e "${_C_DIM}Relevant Files pre-filled from: git diff --name-only ${base_branch}...HEAD${_C_NC}"
    echo ""
    echo -e "${_C_YELLOW}⚠ Placeholders left for you to fill in:${_C_NC} Summary, Key Decisions, Traps to Avoid, Working Agreements, Open Work"

    if [[ "$do_issue" == true ]]; then
        if ! command -v gh &>/dev/null; then
            echo -e "${_C_RED}✗ gh CLI not found — cannot file issue${_C_NC}"
            return 1
        fi
        echo ""
        echo -e "${_C_BLUE}Filing GitHub issue from handoff content...${_C_NC}"
        gh issue create --title "handoff: ${slug}" --body-file "$handoff_path"
    fi
}

_flow_handoff_help() {
    echo -e "
${_C_BOLD}flow handoff${_C_NC} - Structured Claude-chat-to-Claude-Code handoff generator

${_C_YELLOW}USAGE${_C_NC}:
  ${_C_CYAN}flow handoff <slug>${_C_NC}                  Create docs/planning/HANDOFF-<slug>.md
  ${_C_CYAN}flow handoff <slug> --issue${_C_NC}           Also file a GitHub issue from it
  ${_C_CYAN}flow handoff <slug> --base <branch>${_C_NC}   Diff against a specific base branch

${_C_YELLOW}WHAT IT DOES${_C_NC}:
  1. Scaffolds a structured handoff file (Summary, Key Decisions, Traps to Avoid,
     Working Agreements, Relevant Files, Open Work, Verification Note, Origin)
  2. Pre-fills Relevant Files from 'git diff --name-only' against the base branch
  3. Never overwrites an existing handoff file for the same slug
  4. Optionally files a GitHub issue with the handoff content as the body

${_C_YELLOW}SEE ALSO${_C_NC}:
  ${_C_DIM}docs/specs/SPEC-flow-handoff-command.md${_C_NC} for the full spec
  ${_C_DIM}docs/planning/PROPOSAL-claude-chat-to-code-handoff.md${_C_NC} for the rationale
  ${_C_DIM}wt${_C_NC} for worktree management this pairs with
"
}
