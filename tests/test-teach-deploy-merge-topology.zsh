#!/usr/bin/env zsh
# test-teach-deploy-merge-topology.zsh
#
# A direct deploy must produce a MERGE COMMIT on production, never a
# fast-forward.
#
# Without --no-ff, deploying N draft commits fast-forwards production to
# draft's own tip. Production then has no single commit representing "this
# deploy", so `teach deploy --rollback` — which reverts the deploy's commit —
# can only undo the last of the N. The codebase already assumes merge commits
# exist: git-helpers.zsh:693 filters "merge commits from --no-ff deploys" when
# detecting production conflicts.
#
# Caveat for anyone reading a failure here: after a successful deploy, draft
# and production legitimately point at the SAME commit, because the deploy
# syncs draft from production afterwards (reflog shows "merge
# origin/production: Fast-forward" on draft). Ref equality is therefore NOT
# evidence of a fast-forwarded deploy. Parent count is.

PASS=0
FAIL=0
_ok()  { ((PASS++)); echo "  ✅ $1"; }
_bad() { ((FAIL++)); echo "  ❌ $1: $2"; }

ROOT="${0:A:h}/.."
SRC="$ROOT/lib/dispatchers/teach-deploy-enhanced.zsh"
[[ -f "$SRC" ]] || { echo "❌ cannot find $SRC"; exit 1; }
command -v yq >/dev/null 2>&1 || { echo "⏭️  yq not installed — skipping"; exit 0; }

BOOT="source '$ROOT/lib/core.zsh' 2>/dev/null || true
source '$ROOT/lib/git-helpers.zsh' 2>/dev/null || true
source '$ROOT/lib/deploy-history-helpers.zsh' 2>/dev/null || true
source '$ROOT/lib/deploy-rollback-helpers.zsh' 2>/dev/null || true
source '$SRC'
typeset -f _teach_error >/dev/null 2>&1 || _teach_error() { echo \"teach: \$1\"; return 1; }"

echo "=== teach deploy merge topology ==="

root="$(mktemp -d)"
git init -q --bare "$root/bare.git"
git init -q -b draft "$root/repo"
(
  cd "$root/repo" || exit 1
  git config user.email t@t.t
  git config user.name T
  mkdir -p .flow
  printf 'course:\n  name: Topology\nbranches:\n  draft: draft\n  production: production\n' \
    > .flow/teach-config.yml
  echo v1 > page.qmd
  git add -A && git commit -qm init
  git branch production
  git remote add origin "$root/bare.git"
  git push -q origin draft production
  git branch -q --set-upstream-to=origin/draft draft
  # Two commits, so a fast-forward would visibly collapse the deploy into
  # draft's own tip rather than producing one deploy commit.
  echo a >> page.qmd && git commit -qam "content: week 1"
  echo b >> page.qmd && git commit -qam "content: week 2"
)

( cd "$root/repo" && zsh -c "$BOOT
_teach_deploy_enhanced --direct" </dev/null >/dev/null 2>&1 )

parents="$( cd "$root/repo" && git rev-list --parents -n1 production | wc -w | tr -d ' ' )"
if [[ "$parents" == "3" ]]; then
  _ok "direct deploy creates a merge commit (2 parents)"
else
  _bad "direct deploy did not create a merge commit" "rev-list --parents printed $parents refs, expected 3"
fi

# The merge commit must actually contain both weeks, i.e. reverting it undoes
# the whole deploy rather than one commit of it.
second_parent="$( cd "$root/repo" && git log -1 --pretty=%P production | awk '{print $2}' )"
if [[ -n "$second_parent" ]]; then
  subj="$( cd "$root/repo" && git log -1 --pretty=%s "$second_parent" )"
  if [[ "$subj" == "content: week 2" ]]; then
    _ok "merge's second parent is draft's tip — one revert undoes the whole deploy"
  else
    _bad "unexpected second parent" "$subj"
  fi
else
  _bad "no second parent" "production tip is not a merge"
fi

rm -rf "$root"

echo ""
echo "=== $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]]
