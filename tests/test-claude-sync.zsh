#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# UNIT TEST SUITE - CLAUDE-SYNC (zsh/functions/claude-sync.zsh)
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: claude-sync must commit what it adds. chezmoi commits by itself only
#          when git.autoCommit is configured; without it, `chezmoi add` only
#          stages into the source dir and the changes never reach the remote.
#
# `chezmoi` is replaced by a shell function that copies files into a throwaway
# source repo whose origin is a local bare repo, so real git commit/push runs
# without touching the user's dotfiles.
#
# Standalone: `zsh tests/test-claude-sync.zsh` exits 0 when green.
# ══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

export FLOW_QUIET=1
export FLOW_ATLAS_ENABLED=no

# ──────────────────────────────────────────────────────────────────────────────
# SETUP / CLEANUP
# ──────────────────────────────────────────────────────────────────────────────

REAL_HOME="$HOME"
SANDBOX=""
SRC=""
ORIGIN=""

setup() {
    source "$PROJECT_ROOT/zsh/functions/claude-sync.zsh" 2>/dev/null
}

# Fake chezmoi: source-path, managed, add/re-add (copy into $SRC/dot_claude).
chezmoi() {
    local sub="$1"; shift
    case "$sub" in
        source-path)
            if [[ -z "$1" ]]; then print -r -- "$SRC"
            elif [[ "$1" == "$HOME/.claude"* ]]; then print -r -- "$SRC/dot_claude${1#$HOME/.claude}"
            else print -r -- "$SRC/dot_${1#$HOME/.}"; fi ;;
        managed)
            print -r -- ".claude"; print -r -- ".claude/CLAUDE.md" ;;
        add|re-add)
            local p rel
            for p in "$@"; do
                rel="$(chezmoi source-path "$p")"
                if [[ -d "$p" ]]; then
                    mkdir -p "$rel" && cp -R "$p/." "$rel/"
                else
                    mkdir -p "${rel:h}" && cp "$p" "$rel"
                fi
            done ;;
        diff) ;;
    esac
}

make_sandbox() {
    SANDBOX="$(mktemp -d -t claude-sync-test.XXXXXX)"
    ORIGIN="$SANDBOX/origin.git"
    SRC="$SANDBOX/src"
    export HOME="$SANDBOX/home"
    mkdir -p "$HOME/.claude/projects/p1/memory"
    print -r -- "# global" > "$HOME/.claude/CLAUDE.md"
    print -r -- "fact one" > "$HOME/.claude/projects/p1/memory/one.md"

    git init -q --bare -b main "$ORIGIN"
    git init -q -b main "$SRC"
    git -C "$SRC" config user.email test@example.com
    git -C "$SRC" config user.name test
    print -r -- "unrelated" > "$SRC/dot_zshrc"
    git -C "$SRC" add -A && git -C "$SRC" commit -q -m init
    git -C "$SRC" remote add origin "$ORIGIN"
    git -C "$SRC" push -q -u origin main 2>/dev/null
}

teardown_sandbox() {
    export HOME="$REAL_HOME"
    [[ -n "$SANDBOX" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"
    SANDBOX="" SRC="" ORIGIN=""
}

# ──────────────────────────────────────────────────────────────────────────────
# TESTS
# ──────────────────────────────────────────────────────────────────────────────

test_function_exists() {
    test_case "claude-sync function exists"
    assert_function_exists "claude-sync" || return
    test_pass
}

test_default_commits_and_pushes_new_memory() {
    test_case "default run commits new memory files and pushes them"
    make_sandbox
    local out; out=$(claude-sync 2>&1)
    local remote_files; remote_files=$(git -C "$ORIGIN" ls-tree -r --name-only main)
    local dirty; dirty=$(git -C "$SRC" status --porcelain)
    teardown_sandbox
    assert_contains "$remote_files" "dot_claude/projects/p1/memory/one.md" || return
    assert_empty "$dirty" "source repo should be clean after sync" || return
    assert_contains "$out" "pushed" || return
    test_pass
}

test_no_push_commits_locally_only() {
    test_case "--no-push commits but leaves origin untouched"
    make_sandbox
    claude-sync --no-push >/dev/null 2>&1
    local ahead; ahead=$(git -C "$SRC" rev-list --count origin/main..HEAD)
    local remote_files; remote_files=$(git -C "$ORIGIN" ls-tree -r --name-only main)
    teardown_sandbox
    assert_equals "$ahead" "1" || return
    assert_not_contains "$remote_files" "one.md" || return
    test_pass
}

test_second_run_reports_already_synced() {
    test_case "second run with no changes makes no commit"
    make_sandbox
    claude-sync >/dev/null 2>&1
    local before; before=$(git -C "$SRC" rev-parse HEAD)
    local out; out=$(claude-sync 2>&1)
    local after; after=$(git -C "$SRC" rev-parse HEAD)
    teardown_sandbox
    assert_equals "$after" "$before" || return
    assert_contains "$out" "nothing to push" || return
    test_pass
}

test_does_not_commit_unrelated_dotfiles() {
    test_case "unrelated staged dotfile changes are not swept into the commit"
    make_sandbox
    print -r -- "edited" > "$SRC/dot_zshrc"
    git -C "$SRC" add dot_zshrc
    claude-sync --no-push >/dev/null 2>&1
    local committed; committed=$(git -C "$SRC" log --name-only --format= origin/main..HEAD)
    local still_staged; still_staged=$(git -C "$SRC" diff --cached --name-only)
    teardown_sandbox
    assert_contains "$committed" "one.md" || return
    assert_not_contains "$committed" "dot_zshrc" || return
    assert_contains "$still_staged" "dot_zshrc" || return
    test_pass
}

test_add_commits_before_push() {
    test_case "--add commits the new path before pushing"
    make_sandbox
    print -r -- "{}" > "$HOME/.claude/extra.json"
    claude-sync --add "$HOME/.claude/extra.json" >/dev/null 2>&1
    local remote_files; remote_files=$(git -C "$ORIGIN" ls-tree -r --name-only main)
    teardown_sandbox
    assert_contains "$remote_files" "dot_claude/extra.json" || return
    test_pass
}

test_add_outside_claude_commits_that_path() {
    test_case "--add of a path outside ~/.claude still commits it"
    make_sandbox
    print -r -- "set -o vi" > "$HOME/.inputrc"
    claude-sync --add "$HOME/.inputrc" >/dev/null 2>&1
    local remote_files; remote_files=$(git -C "$ORIGIN" ls-tree -r --name-only main)
    teardown_sandbox
    assert_contains "$remote_files" "dot_inputrc" || return
    test_pass
}

test_skips_tmpdir_project_memory() {
    test_case "memory dirs of flow-cli test sandboxes (*-flow-test-sandbox-*) are not synced"
    make_sandbox
    local tmp_proj="$HOME/.claude/projects/-private-var-folders-xn-abc-T-flow-test-sandbox-1a2b3c"
    mkdir -p "$tmp_proj/memory" && : > "$tmp_proj/memory/.keep"
    claude-sync >/dev/null 2>&1
    local remote_files; remote_files=$(git -C "$ORIGIN" ls-tree -r --name-only main)
    teardown_sandbox
    assert_contains "$remote_files" "dot_claude/projects/p1/memory/one.md" || return
    assert_not_contains "$remote_files" "private-var-folders" || return
    test_pass
}

test_does_not_commit_stale_tmpdir_copies_in_source() {
    test_case "copies of test-sandbox memory already in the source dir are not committed"
    make_sandbox
    local stale="$SRC/dot_claude/projects/private_-private-var-folders-xn-abc-T-flow-test-sandbox-9z8y7x/memory"
    mkdir -p "$stale" && : > "$stale/.keep"
    claude-sync >/dev/null 2>&1
    local remote_files; remote_files=$(git -C "$ORIGIN" ls-tree -r --name-only main)
    teardown_sandbox
    assert_contains "$remote_files" "dot_claude/projects/p1/memory/one.md" || return
    assert_not_contains "$remote_files" "private-var-folders" || return
    test_pass
}

test_syncs_real_memory_of_tmpdir_rooted_project() {
    test_case "a \$TMPDIR-rooted project that is not a test sandbox still syncs"
    make_sandbox
    local tmp_root="$HOME/.claude/projects/-private-var-folders-xn-abc-T"
    mkdir -p "$tmp_root/memory" && print -r -- "real" > "$tmp_root/memory/note.md"
    claude-sync >/dev/null 2>&1
    local remote_files; remote_files=$(git -C "$ORIGIN" ls-tree -r --name-only main)
    teardown_sandbox
    assert_contains "$remote_files" "dot_claude/projects/-private-var-folders-xn-abc-T/memory/note.md" || return
    test_pass
}

# ──────────────────────────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────────────────────────

main() {
    test_suite_start "claude-sync"
    setup

    test_function_exists
    test_default_commits_and_pushes_new_memory
    test_no_push_commits_locally_only
    test_second_run_reports_already_synced
    test_does_not_commit_unrelated_dotfiles
    test_add_commits_before_push
    test_add_outside_claude_commits_that_path
    test_skips_tmpdir_project_memory
    test_does_not_commit_stale_tmpdir_copies_in_source
    test_syncs_real_memory_of_tmpdir_rooted_project

    test_suite_end
    exit $?
}

main "$@"
