#!/usr/bin/env zsh
# Claude Code config sync helper
#
# Keeps ~/.claude/CLAUDE.md and per-project memory dirs in sync with the
# dotfiles repo (Data-Wise/dotfiles via chezmoi).
#
# Source: flow-cli zsh/functions/claude-sync.zsh (~/.config/zsh links to flow-cli/zsh)
#
# Usage:
#   claude-sync              # Re-add tracked files, commit, push (silent if nothing changed)
#   claude-sync --status     # Show drift between live ~ and chezmoi source
#   claude-sync --no-push    # Re-add + commit only, don't push
#   claude-sync --add <path> # Add a new ~/.claude/... path to tracking

# Commit what chezmoi staged for <target> (default ~/.claude). chezmoi commits by
# itself only when git.autoCommit is configured, which is not assumed here.
# Commits only that target's source path, so unrelated staged dotfile edits stay staged.
_claude_sync_commit() {
    local src="$1" target="${2:-$HOME/.claude}" target_src
    target_src=$(chezmoi source-path "$target" 2>/dev/null)
    [[ -n "$target_src" ]] || return 1
    # Also exclude test-sandbox memory already copied into the source dir by an
    # earlier run: skipping it at `chezmoi add` time alone would not stop it.
    local -a spec=( "$target_src" ':(exclude,glob)**/*-flow-test-sandbox-*/**' )
    git -C "$src" add -A -- "${spec[@]}" || return 1
    git -C "$src" diff --cached --quiet -- "${spec[@]}" && return 0
    git -C "$src" commit -q -m "chore(claude): claude-sync $(date +%Y-%m-%d)" -- "${spec[@]}"
}

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
            local add_src
            add_src=$(chezmoi source-path 2>/dev/null)
            chezmoi add "$extra_path" && \
                _claude_sync_commit "$add_src" "$extra_path" && \
                git -C "$add_src" push origin main
            return $?
            ;;
    esac

    # Default: sync tracked ~/.claude paths, commit (auto), push (unless --no-push)
    local file_targets=( ~/.claude/CLAUDE.md(N) )
    local dir_targets=( ~/.claude/projects/*/memory(N/) )
    # Skip flow-cli test sandboxes (run-all.sh: mktemp -d .../flow-test-sandbox.XXXXXX),
    # whose memory dirs are empty. Not every $TMPDIR-rooted project: a session whose
    # cwd was $TMPDIR itself (-private-var-folders-...-T) can hold real memory.
    dir_targets=( ${dir_targets:#*/projects/*-flow-test-sandbox-*} )

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

    # Use `git -C "$(chezmoi source-path)"` instead of `chezmoi cd &&` —
    # `chezmoi cd` is interactive-only and silently no-ops in a sourced
    # function, which previously caused git commands to run in the wrong
    # repo's CWD.
    local src
    src=$(chezmoi source-path 2>/dev/null)
    if [[ -z "$src" || ! -d "$src/.git" ]]; then
        echo "claude-sync: can't locate chezmoi source git repo" >&2
        return 1
    fi

    if ! _claude_sync_commit "$src"; then
        echo "claude-sync: commit failed in $src" >&2
        return 1
    fi

    # Push if commits were made
    if [[ "$action" != "no-push" ]]; then
        # Local-ahead check: covers this run's commit and any earlier
        # unpushed ones (e.g. from --no-push).
        if [[ -z "$(git -C "$src" log origin/main..HEAD --oneline 2>/dev/null)" ]]; then
            echo "claude-sync: nothing to push (already synced)"
            return 0
        fi

        # Capture push output to distinguish "Everything up-to-date" (no
        # remote change) from an actual transfer.
        local push_output
        if ! push_output=$(git -C "$src" push origin main 2>&1); then
            echo "claude-sync: push failed:" >&2
            printf '%s\n' "$push_output" >&2
            return 1
        fi

        if echo "$push_output" | grep -q "Everything up-to-date"; then
            echo "claude-sync: synced (no remote change — chezmoi auto-commit was empty)"
        else
            echo "claude-sync: pushed"
        fi
    fi
}
