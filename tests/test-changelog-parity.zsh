#!/usr/bin/env zsh
# test-changelog-parity.zsh
#
# This repo keeps two changelogs — CHANGELOG.md and docs/CHANGELOG.md — and
# they are supposed to mirror. Nothing checked that. As of 2026-08-23 they had
# drifted badly and BIDIRECTIONALLY:
#
#   23 version sections only in CHANGELOG.md
#   41 version sections only in docs/CHANGELOG.md
#   33 shared, of which only 12 have identical bodies
#
# Neither file is a superset, so this cannot be repaired by copying one over
# the other — 21 shared versions would need a human to decide which body is
# correct. That reconciliation is deliberately NOT attempted here; silently
# picking a winner 21 times would destroy release history.
#
# What this test does instead: stop the bleeding. The [Unreleased] section is
# the part that matters for the next release, and it is identical today. Gate
# on that, so new entries cannot land in one file and not the other. Historical
# drift is reported for visibility but does not fail.
#
# Exit 0 = [Unreleased] agrees. Exit 1 = someone edited one file only.

set -uo pipefail
cd "${0:A:h}/.."

PASS=0
FAIL=0
_ok()  { PASS=$((PASS+1)); echo "  ✅ $1"; }
_bad() { FAIL=$((FAIL+1)); echo "  ❌ $1"; [[ -n "${2:-}" ]] && echo "     $2"; }

echo "=== changelog parity ==="

for f in CHANGELOG.md docs/CHANGELOG.md; do
  if [[ -f "$f" ]]; then
    _ok "$f exists"
  else
    _bad "$f is missing" "both changelogs must exist for the mirror to mean anything"
    echo ""
    echo "=== $PASS passed, $FAIL failed ==="
    exit 1
  fi
done

# Extract [Unreleased] from each: everything from the heading up to the next
# version heading. `## [7.16.0]` and `## [v7.6.0]` both appear in these files,
# so the terminator matches an optional v.
_unreleased() {
  awk '/^## \[Unreleased\]/{f=1; next} /^## \[?v?[0-9]+\.[0-9]+\.[0-9]+/{f=0} f' "$1"
}

root_u="$(_unreleased CHANGELOG.md)"
docs_u="$(_unreleased docs/CHANGELOG.md)"

if [[ -z "${root_u// }" && -z "${docs_u// }" ]]; then
  _ok "[Unreleased] is empty in both (nothing pending — parity trivially holds)"
elif [[ "$root_u" == "$docs_u" ]]; then
  _ok "[Unreleased] is identical in both changelogs"
else
  _bad "[Unreleased] differs between CHANGELOG.md and docs/CHANGELOG.md" \
       "an entry landed in one file only — add it to both, they are meant to mirror"
  echo ""
  echo "     --- lines only in CHANGELOG.md ---"
  comm -23 <(printf '%s\n' "$root_u" | sort) <(printf '%s\n' "$docs_u" | sort) | grep -v '^[[:space:]]*$' | head -5 | sed 's/^/     /'
  echo "     --- lines only in docs/CHANGELOG.md ---"
  comm -13 <(printf '%s\n' "$root_u" | sort) <(printf '%s\n' "$docs_u" | sort) | grep -v '^[[:space:]]*$' | head -5 | sed 's/^/     /'
fi

# Advisory only. This count is large and pre-existing; failing on it would mean
# the gate never goes green and therefore never protects anything.
root_v="$(grep -cE '^## \[?v?[0-9]+\.[0-9]+\.[0-9]+' CHANGELOG.md 2>/dev/null || echo 0)"
docs_v="$(grep -cE '^## \[?v?[0-9]+\.[0-9]+\.[0-9]+' docs/CHANGELOG.md 2>/dev/null || echo 0)"
echo ""
echo "  ℹ️  historical drift (advisory, not gated): CHANGELOG.md has ${root_v} version"
echo "      sections, docs/CHANGELOG.md has ${docs_v}. Reconciling those needs a human."

echo ""
echo "=== $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]]
