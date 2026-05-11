#!/usr/bin/env zsh
# Claude Code config sync helper
#
# Keeps ~/.claude/CLAUDE.md and per-project memory dirs in sync with the
# dotfiles repo (Data-Wise/dotfiles via chezmoi).
#
# Source: managed by chezmoi at dot_config/zsh/functions/claude-sync.zsh
# Apply destination: ~/.config/zsh/functions/claude-sync.zsh
#
# Usage:
#   claude-sync              # Re-add tracked files + push (silent if nothing changed)
#   claude-sync --status     # Show drift between live ~ and chezmoi source
#   claude-sync --no-push    # Re-add + commit only, don't push
#   claude-sync --add <path> # Add a new ~/.claude/... path to tracking

claude-sync() {
    local action="default"
    local extra_path=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status)   action="status"; shift ;;
            --no-push)  action="no-push"; shift ;;
            --add)      action="add"; extra_path="$2"; shift 2 ;;
            -h|--help)
                grep -E '^# ' "${(%):-%x}" | sed 's/^# \?//' | head -15
                return 0 ;;
            *)
                echo "claude-sync: unknown arg '$1' (try --help)" >&2
                return 2 ;;
        esac
    done

    if ! command -v chezmoi >/dev/null; then
        echo "claude-sync: chezmoi not installed (brew install chezmoi)" >&2
        return 1
    fi

    case "$action" in
        status)
            chezmoi diff ~/.claude 2>/dev/null
            return 0
            ;;
        add)
            if [[ -z "$extra_path" || ! -e "$extra_path" ]]; then
                echo "claude-sync: --add needs an existing path" >&2
                return 2
            fi
            chezmoi add "$extra_path" && (chezmoi cd && git push origin main)
            return $?
            ;;
    esac

    # Default: sync tracked ~/.claude paths, commit (auto), push (unless --no-push)
    local file_targets=( ~/.claude/CLAUDE.md(N) )
    local dir_targets=( ~/.claude/projects/*/memory(N/) )

    # Skip if nothing tracked yet
    local tracked
    tracked=$(chezmoi managed 2>/dev/null | grep -c '^\.claude')
    if (( tracked == 0 )); then
        echo "claude-sync: nothing under ~/.claude is tracked by chezmoi yet."
        echo "  Bootstrap with:  chezmoi add ~/.claude/CLAUDE.md"
        return 1
    fi

    # Files: re-add (only updates known files, won't pick up unrelated new files)
    (( ${#file_targets[@]} > 0 )) && chezmoi re-add "${file_targets[@]}" 2>/dev/null

    # Directories: use `add` (recurses, picks up new files written this session)
    (( ${#dir_targets[@]} > 0 )) && chezmoi add "${dir_targets[@]}" 2>/dev/null

    # Push if commits were made
    if [[ "$action" != "no-push" ]]; then
        (chezmoi cd && {
            # Local-ahead check: chezmoi auto-commits even when content didn't
            # change, so this can be true with no actual remote-bound work.
            if [[ -z "$(git log origin/main..HEAD --oneline 2>/dev/null)" ]]; then
                echo "claude-sync: nothing to push (already synced)"
                return 0
            fi

            # Capture push output to distinguish "Everything up-to-date" (no
            # remote change) from an actual transfer.
            local push_output
            if ! push_output=$(git push origin main 2>&1); then
                echo "claude-sync: push failed:" >&2
                printf '%s\n' "$push_output" >&2
                return 1
            fi

            if echo "$push_output" | grep -q "Everything up-to-date"; then
                echo "claude-sync: synced (no remote change — chezmoi auto-commit was empty)"
            else
                echo "claude-sync: pushed"
            fi
        })
    fi
}
