#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# G - Git Commands Dispatcher
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/g-dispatcher.zsh
# Version:      1.0
# Date:         2025-12-17
# Pattern:      command + keyword + options
#
# Usage:        g <action> [args]
#
# Examples:
#   g                   # Status (short)
#   g status            # Full status
#   g add .             # Stage all
#   g commit "msg"      # Commit with message
#   g push              # Push to remote
#   g log               # Pretty log
#   g help              # Show all commands

# Unalias conflicting OMZ git plugin alias
# (Our dispatcher provides a smarter g command)
unalias g 2>/dev/null
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# COLOR DEFINITIONS
# ═══════════════════════════════════════════════════════════════════

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

# ═══════════════════════════════════════════════════════════════════
# MAIN G() DISPATCHER
# ═══════════════════════════════════════════════════════════════════

g() {
    # No arguments → git status (short)
    if [[ $# -eq 0 ]]; then
        git status -sb
        return
    fi

    case "$1" in
        # ─────────────────────────────────────────────────────────────
        # STATUS & INFO
        # ─────────────────────────────────────────────────────────────
        status|s)
            shift
            git status "$@"
            ;;

        diff|d)
            shift
            git diff "$@"
            ;;

        ds|staged)
            shift
            git diff --staged "$@"
            ;;

        log|l)
            shift
            git log --oneline --graph --decorate -20 "$@"
            ;;

        loga|la)
            shift
            git log --oneline --graph --decorate --all -20 "$@"
            ;;

        blame|bl)
            shift
            git blame "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # STAGING & COMMITS
        # ─────────────────────────────────────────────────────────────
        add|a)
            shift
            git add "$@"
            ;;

        aa)
            git add --all
            ;;

        commit|c)
            shift
            if [[ $# -eq 0 ]]; then
                git commit
            else
                git commit -m "$*"
            fi
            ;;

        amend)
            git commit --amend --no-edit
            ;;

        amendm)
            shift
            git commit --amend -m "$*"
            ;;

        # ─────────────────────────────────────────────────────────────
        # BRANCHES
        # ─────────────────────────────────────────────────────────────
        branch|b)
            shift
            git branch "$@"
            ;;

        ba)
            git branch -a
            ;;

        checkout|co)
            shift
            git checkout "$@"
            ;;

        cob)
            shift
            git checkout -b "$@"
            ;;

        switch|sw)
            shift
            git switch "$@"
            ;;

        swc)
            shift
            git switch -c "$@"
            ;;

        main|m)
            git checkout main 2>/dev/null || git checkout master
            ;;

        # ─────────────────────────────────────────────────────────────
        # REMOTE OPERATIONS
        # ─────────────────────────────────────────────────────────────
        push|p)
            shift
            git push "$@"
            ;;

        pushu|pu)
            git push -u origin HEAD
            ;;

        pull|pl)
            shift
            git pull "$@"
            ;;

        fetch|f)
            shift
            git fetch "$@"
            ;;

        fa)
            git fetch --all
            ;;

        # ─────────────────────────────────────────────────────────────
        # STASH
        # ─────────────────────────────────────────────────────────────
        stash|st)
            shift
            if [[ $# -eq 0 ]]; then
                git stash
            else
                git stash "$@"
            fi
            ;;

        pop|stp)
            git stash pop
            ;;

        stl)
            git stash list
            ;;

        # ─────────────────────────────────────────────────────────────
        # RESET & UNDO
        # ─────────────────────────────────────────────────────────────
        reset|rs)
            shift
            git reset "$@"
            ;;

        undo)
            echo "${_C_YELLOW}Undoing last commit (keeping changes)...${_C_NC}"
            git reset --soft HEAD~1
            ;;

        unstage)
            shift
            git reset HEAD "$@"
            ;;

        discard)
            shift
            git checkout -- "$@"
            ;;

        clean)
            echo "${_C_YELLOW}Removing untracked files...${_C_NC}"
            git clean -fd
            ;;

        # ─────────────────────────────────────────────────────────────
        # REBASE & MERGE
        # ─────────────────────────────────────────────────────────────
        rebase|rb)
            shift
            git rebase "$@"
            ;;

        rbc)
            git rebase --continue
            ;;

        rba)
            git rebase --abort
            ;;

        merge|mg)
            shift
            git merge "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # HELP
        # ─────────────────────────────────────────────────────────────
        help|h|--help|-h)
            _g_help
            ;;

        # ─────────────────────────────────────────────────────────────
        # PASSTHROUGH (anything else goes to git)
        # ─────────────────────────────────────────────────────────────
        *)
            git "$@"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# HELP SYSTEM
# ═══════════════════════════════════════════════════════════════════

_g_help() {
    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ g - Git Commands                            │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} g [subcommand] [args]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}g${_C_NC}                 Status (short)
  ${_C_CYAN}g add .${_C_NC}           Stage all changes
  ${_C_CYAN}g commit \"msg\"${_C_NC}   Commit with message
  ${_C_CYAN}g push${_C_NC}            Push to remote
  ${_C_CYAN}g pull${_C_NC}            Pull from remote

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} g                      ${_C_DIM}# Quick status${_C_NC}
  ${_C_DIM}\$${_C_NC} g aa                   ${_C_DIM}# Add all${_C_NC}
  ${_C_DIM}\$${_C_NC} g commit \"fix bug\"    ${_C_DIM}# Commit${_C_NC}
  ${_C_DIM}\$${_C_NC} g push                 ${_C_DIM}# Push${_C_NC}
  ${_C_DIM}\$${_C_NC} g undo                 ${_C_DIM}# Undo last commit${_C_NC}

${_C_BLUE}📋 STATUS & INFO${_C_NC}:
  ${_C_CYAN}g${_C_NC} / ${_C_CYAN}g s${_C_NC}          Status
  ${_C_CYAN}g d${_C_NC} / ${_C_CYAN}g diff${_C_NC}     Show diff
  ${_C_CYAN}g ds${_C_NC}              Staged diff
  ${_C_CYAN}g l${_C_NC} / ${_C_CYAN}g log${_C_NC}      Pretty log (20)
  ${_C_CYAN}g la${_C_NC}              Log all branches
  ${_C_CYAN}g blame <file>${_C_NC}    Blame

${_C_BLUE}📝 STAGING & COMMITS${_C_NC}:
  ${_C_CYAN}g a${_C_NC} / ${_C_CYAN}g add${_C_NC}      Add files
  ${_C_CYAN}g aa${_C_NC}              Add all
  ${_C_CYAN}g c${_C_NC} / ${_C_CYAN}g commit${_C_NC}   Commit
  ${_C_CYAN}g commit \"msg\"${_C_NC}   Commit with message
  ${_C_CYAN}g amend${_C_NC}           Amend (no edit)
  ${_C_CYAN}g amendm \"msg\"${_C_NC}   Amend with message

${_C_BLUE}🌿 BRANCHES${_C_NC}:
  ${_C_CYAN}g b${_C_NC} / ${_C_CYAN}g branch${_C_NC}   List branches
  ${_C_CYAN}g ba${_C_NC}              All branches
  ${_C_CYAN}g co <b>${_C_NC}          Checkout branch
  ${_C_CYAN}g cob <b>${_C_NC}         Create & checkout
  ${_C_CYAN}g sw <b>${_C_NC}          Switch branch
  ${_C_CYAN}g swc <b>${_C_NC}         Switch create
  ${_C_CYAN}g main${_C_NC}            Checkout main/master

${_C_BLUE}🔄 REMOTE${_C_NC}:
  ${_C_CYAN}g p${_C_NC} / ${_C_CYAN}g push${_C_NC}     Push
  ${_C_CYAN}g pu${_C_NC}              Push -u origin HEAD
  ${_C_CYAN}g pl${_C_NC} / ${_C_CYAN}g pull${_C_NC}    Pull
  ${_C_CYAN}g f${_C_NC} / ${_C_CYAN}g fetch${_C_NC}    Fetch
  ${_C_CYAN}g fa${_C_NC}              Fetch all

${_C_BLUE}📦 STASH${_C_NC}:
  ${_C_CYAN}g st${_C_NC} / ${_C_CYAN}g stash${_C_NC}   Stash
  ${_C_CYAN}g pop${_C_NC}             Stash pop
  ${_C_CYAN}g stl${_C_NC}             Stash list

${_C_BLUE}⏪ RESET & UNDO${_C_NC}:
  ${_C_CYAN}g undo${_C_NC}            Undo last commit (soft)
  ${_C_CYAN}g unstage <f>${_C_NC}     Unstage file
  ${_C_CYAN}g discard <f>${_C_NC}     Discard changes
  ${_C_CYAN}g clean${_C_NC}           Remove untracked

${_C_BLUE}🔀 REBASE & MERGE${_C_NC}:
  ${_C_CYAN}g rb${_C_NC}              Rebase
  ${_C_CYAN}g rbc${_C_NC}             Rebase continue
  ${_C_CYAN}g rba${_C_NC}             Rebase abort
  ${_C_CYAN}g mg${_C_NC}              Merge

${_C_MAGENTA}💡 TIP${_C_NC}: Unknown commands pass through to git
  ${_C_DIM}g remote -v        → git remote -v${_C_NC}
  ${_C_DIM}g cherry-pick xxx  → git cherry-pick xxx${_C_NC}
"
}
