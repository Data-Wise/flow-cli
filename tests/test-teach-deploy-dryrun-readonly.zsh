#!/usr/bin/env zsh
# test-teach-deploy-dryrun-readonly.zsh
#
# `teach deploy --dry-run` must be READ-ONLY and must not be blocked by
# conditions it cannot affect.
#
# Two bugs motivated this suite:
#   1. CI mode (auto-detected whenever stdin is not a TTY, so always true for
#      an agent/automation caller) treated "production has new commits" and
#      "uncommitted changes" as fatal even under --dry-run, so a dry run could
#      not render a plan on the normal state of a working course repo.
#   2. Interactively, the uncommitted-changes handler PROMPTS to commit. Any
#      pty wrapper (`script -q /dev/null ...`) auto-answers the default Y and
#      silently creates a real commit — observed in a live course repo.
#
# Both are fixed by skipping the mutation-oriented gates when dry_run is true.
# The real-deploy paths must keep aborting, which is what the controls assert.

PASS=0
FAIL=0

_ok()   { ((PASS++)); echo "  ✅ $1"; }
_bad()  { ((FAIL++)); echo "  ❌ $1: $2"; }

ROOT="${0:A:h}/.."
SRC="$ROOT/lib/dispatchers/teach-deploy-enhanced.zsh"
[[ -f "$SRC" ]] || { echo "❌ cannot find $SRC"; exit 1; }

# Same bootstrap order as test-teach-deploy-v2-unit.zsh: the dispatcher relies
# on helpers (_git_in_repo, _teach_error, FLOW_COLORS) that live in these libs.
BOOT="source '$ROOT/lib/core.zsh' 2>/dev/null || true
source '$ROOT/lib/git-helpers.zsh' 2>/dev/null || true
source '$ROOT/lib/deploy-history-helpers.zsh' 2>/dev/null || true
source '$ROOT/lib/deploy-rollback-helpers.zsh' 2>/dev/null || true
source '$SRC'
typeset -f _teach_error >/dev/null 2>&1 || _teach_error() { echo \"teach: \$1\"; [[ -n \"\$2\" ]] && echo \"   \$2\"; return 1; }"

if ! command -v yq >/dev/null 2>&1; then
  echo "⏭️  yq not installed — skipping (config parsing requires it)"
  exit 0
fi

# ---------------------------------------------------------------------------
# Fixture: a course repo on draft, with a production branch, a remote so the
# conflict probe can resolve, and one uncommitted change.
# `synced` = production in sync (conflict check passes)
# `diverged` = production carries a commit draft does not
# ---------------------------------------------------------------------------
_mk_fixture() {
  local mode="$1"                      # synced | diverged
  local root; root="$(mktemp -d)"
  git init -q --bare "$root/bare.git"
  git init -q -b draft "$root/repo"
  (
    cd "$root/repo" || exit 1
    git config user.email t@t.t
    git config user.name T
    mkdir -p .flow
    printf 'course:\n  name: Fixture\nbranches:\n  draft: draft\n  production: production\n' \
      > .flow/teach-config.yml
    echo v1 > page.qmd
    git add -A && git commit -qm init
    git branch production
    git remote add origin "$root/bare.git"
    git push -q origin draft production
    git branch -q --set-upstream-to=origin/draft draft

    if [[ "$mode" == "diverged" ]]; then
      git checkout -q production
      echo prod-only >> page.qmd
      git commit -qam "production-only change"
      git push -q origin production
      git checkout -q draft
      echo draft-only >> notes.md
      git add notes.md && git commit -qm "draft-only change"
    fi

    echo "uncommitted" >> page.qmd     # the dirty tree every case needs
  )
  echo "$root/repo"
}

# Run the deploy entrypoint with stdin closed, so ci_mode auto-detects true —
# the mode any non-interactive caller actually gets.
_run() {
  local repo="$1"; shift
  ( cd "$repo" && zsh -c "$BOOT
_teach_deploy_enhanced $*" </dev/null 2>&1 )
}

_state() { ( cd "$1" && git rev-parse HEAD && git status --porcelain && git rev-parse production ); }

_assert_readonly() {
  local repo="$1" label="$2" before="$3"
  if [[ "$before" == "$(_state "$repo")" ]]; then
    _ok "$label — no writes"
  else
    _bad "$label" "repository state changed"
  fi
}

echo "=== teach deploy --dry-run read-only ==="

# --- 1. dry run, dirty tree, diverged production: renders the plan ----------
repo="$(_mk_fixture diverged)"; before="$(_state "$repo")"
out="$(_run "$repo" --direct --dry-run)"
if [[ "$out" == *"DRY RUN"* ]]; then
  _ok "dry run renders the plan despite dirty tree + diverged production"
else
  _bad "dry run blocked" "$(echo "$out" | tail -2)"
fi
_assert_readonly "$repo" "dry run (diverged)" "$before"
[[ "$out" == *"a real deploy would need this resolved first"* ]] \
  && _ok "divergence is reported as a warning, not a stop" \
  || _bad "missing divergence hint" "expected the dry-run hint line"
rm -rf "${repo:h}"

# --- 2. dry run, dirty tree, production synced ------------------------------
repo="$(_mk_fixture synced)"; before="$(_state "$repo")"
out="$(_run "$repo" --direct --dry-run)"
[[ "$out" == *"DRY RUN"* ]] \
  && _ok "dry run renders the plan on a dirty tree" \
  || _bad "dry run blocked by dirty tree" "$(echo "$out" | tail -2)"
_assert_readonly "$repo" "dry run (synced)" "$before"
[[ "$out" != *"Commit and continue"* ]] \
  && _ok "dry run never offers to commit" \
  || _bad "dry run prompted to commit" "the pty auto-accept hazard is back"
# Skipping the handler means the file list is committed work only, so a dirty
# tree is silently under-reported unless the report says so.
[[ "$out" == *"uncommitted file(s) are NOT included"* ]] \
  && _ok "dry run says which files are excluded" \
  || _bad "no uncommitted-exclusion note" "the 'Would deploy N files' count understates silently"
rm -rf "${repo:h}"

# --- 3. CONTROL: a real deploy still refuses a dirty tree -------------------
repo="$(_mk_fixture synced)"; before="$(_state "$repo")"
out="$(_run "$repo" --direct)"
[[ "$out" == *"Uncommitted changes detected"* ]] \
  && _ok "control: real deploy still aborts on a dirty tree" \
  || _bad "real deploy did not abort" "$(echo "$out" | tail -2)"
_assert_readonly "$repo" "control: real deploy (dirty)" "$before"
rm -rf "${repo:h}"

# --- 4. CONTROL: a real deploy still refuses a diverged production ----------
repo="$(_mk_fixture diverged)"; before="$(_state "$repo")"
out="$(_run "$repo" --direct)"
[[ "$out" == *"production conflicts detected"* ]] \
  && _ok "control: real deploy still aborts on diverged production" \
  || _bad "real deploy did not abort" "$(echo "$out" | tail -2)"
_assert_readonly "$repo" "control: real deploy (diverged)" "$before"
rm -rf "${repo:h}"

echo ""
echo "=== $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]]
