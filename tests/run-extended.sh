#!/usr/bin/env bash
# run-extended.sh — suites that exist in tests/ but were never wired into
# run-all.sh, and that pass today.
#
# WHY THIS IS SEPARATE AND NON-BLOCKING
# run-all.sh is a required status check. Promoting 74 never-CI-run suites
# straight into it would break the gate for everyone the moment one turns out
# to depend on a local tool or path. This repo already established the right
# pattern: test.yml's own comment describes the full suite as "promoted to a
# required status check on dev (then main after a soak)". This is that soak.
# Once it runs green for a while, fold these into run-all.sh and delete this.
#
# Audited 117 unreferenced suites on 2026-08-23:
#   74 pass        -> listed below
#   37 fail         -> NOT listed; genuinely broken, see the PR body
#   6 exceed 20s   -> NOT listed; need a timeout override, not exclusion
set -uo pipefail
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
run_ext() {
  local f="$1"
  printf "Running %s... " "$(basename "$f" .zsh)"
  if timeout 60 zsh "$f" </dev/null >/dev/null 2>&1; then
    echo "PASS"; PASS=$((PASS+1))
  else
    echo "FAIL"; FAIL=$((FAIL+1))
  fi
}

run_ext ./tests/test-ai-features.zsh
run_ext ./tests/test-alias-management.zsh
run_ext ./tests/test-atlas-e2e.zsh
run_ext ./tests/test-atlas-integration.zsh
run_ext ./tests/test-cache-analysis-unit.zsh
run_ext ./tests/test-cc-unified-grammar.zsh
run_ext ./tests/test-cc-wt.zsh
run_ext ./tests/test-cross-platform-helpers.zsh
run_ext ./tests/test-date-parser.zsh
run_ext ./tests/test-dispatcher-enhancements.zsh
run_ext ./tests/test-dot-secret-list.zsh
run_ext ./tests/test-em-delete.zsh
run_ext ./tests/test-em-flag.zsh
run_ext ./tests/test-em-v2-attachments.zsh
run_ext ./tests/test-em-v2-folders.zsh
run_ext ./tests/test-em-v2-ics.zsh
run_ext ./tests/test-em-v2-safety-gate.zsh
run_ext ./tests/test-em-v2-security.zsh
run_ext ./tests/test-em-v2-version.zsh
run_ext ./tests/test-em-v2-watch.zsh
run_ext ./tests/test-flat-worktree-detection.zsh
run_ext ./tests/test-framework.zsh
run_ext ./tests/test-help-browser-preview.zsh
run_ext ./tests/test-index-management-unit.zsh
run_ext ./tests/test-keychain-default.zsh
run_ext ./tests/test-lesson-plan-extraction.zsh
run_ext ./tests/test-lint-dogfood.zsh
run_ext ./tests/test-lint-integration.zsh
run_ext ./tests/test-lint-shared-unit.zsh
run_ext ./tests/test-macro-parser.zsh
run_ext ./tests/test-math-blanks-unit.zsh
run_ext ./tests/test-parallel-rendering-unit.zsh
run_ext ./tests/test-phase1-features.zsh
run_ext ./tests/test-phase2-features.zsh
run_ext ./tests/test-pick-command.zsh
run_ext ./tests/test-pick-format.zsh
run_ext ./tests/test-project-cache.zsh
run_ext ./tests/test-prompt-validation.zsh
run_ext ./tests/test-quick-wins.zsh
run_ext ./tests/test-render-queue-unit.zsh
run_ext ./tests/test-slides-optimize-integration.zsh
run_ext ./tests/test-sync.zsh
run_ext ./tests/test-teach-analyze-phase0-integration.zsh
run_ext ./tests/test-teach-analyze-phase0-unit.zsh
run_ext ./tests/test-teach-analyze-phase1-unit.zsh
run_ext ./tests/test-teach-analyze-phase2-integration.zsh
run_ext ./tests/test-teach-analyze-phase2-unit.zsh
run_ext ./tests/test-teach-analyze-phase3-unit.zsh
run_ext ./tests/test-teach-analyze-phase4-integration.zsh
run_ext ./tests/test-teach-analyze-phase5-final.zsh
run_ext ./tests/test-teach-backup-unit.zsh
run_ext ./tests/test-teach-cache-unit.zsh
run_ext ./tests/test-teach-dates-integration.zsh
run_ext ./tests/test-teach-dates-unit.zsh
run_ext ./tests/test-teach-deploy-dryrun-readonly.zsh
run_ext ./tests/test-teach-deploy-merge-topology.zsh
run_ext ./tests/test-teach-deploy.zsh
run_ext ./tests/test-teach-dispatcher-characterization.zsh
run_ext ./tests/test-teach-doctor-unit.zsh
run_ext ./tests/test-teach-flags-phase1-2.zsh
run_ext ./tests/test-teach-hooks-unit.zsh
run_ext ./tests/test-teach-integration-phases-1-6.zsh
run_ext ./tests/test-teach-map-unit.zsh
run_ext ./tests/test-teach-scholar-wrappers.zsh
run_ext ./tests/test-teach-templates.zsh
run_ext ./tests/test-teach-validate-unit.zsh
run_ext ./tests/test-teaching-workflow-increment-3.zsh
run_ext ./tests/test-tm-dispatcher.zsh
run_ext ./tests/test-token-automation-unit.zsh
run_ext ./tests/test-token-automation.zsh
run_ext ./tests/test-utils.zsh
run_ext ./tests/test-v5.1.0-features.zsh
run_ext ./tests/test-wt-enhancement-e2e.zsh
run_ext ./tests/test-wt-enhancement-unit.zsh

echo ""
echo "=== extended: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
