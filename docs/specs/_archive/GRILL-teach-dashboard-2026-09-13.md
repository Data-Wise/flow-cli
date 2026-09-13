# GRILL: `teach dashboard` — Decision Ledger

Spec: `docs/specs/SPEC-teach-dashboard-2026-09-12.md` (issue #275).

## Resolved Decisions

### 1. Announcement storage: separate file, not `teach-config.yml`

**Decision:** `teach dashboard announce` writes to `.teach/announcements.json`, not
into `teach-config.yml` directly. `teach dashboard generate` merges it in when
building `semester-data.json`.

**Why:** No existing flow-cli code has ever done an automated `yq -i` write into
`teach-config.yml` itself (checked: the only precedent, `dispatchers/teach-deploy-enhanced.zsh:512`,
writes to a separate status file). Making `teach-config.yml` writable by automation
for the first time risks silently dropping hand-written comments/formatting on
rewrite, and mixes generated state into what's otherwise a human-edited source of
truth — breaking the `.flow` (config) / `.teach` (generated) convention this same
spec already leans on for `semester-data.json`'s own output path.

**Rejected alternative:** write directly into `teach-config.yml` (the issue's
original proposal). Simpler (one file), but first-mover risk on an untested write
path into a file users hand-edit.

### 2. Semester length: confirmed 16 weeks

**Decision:** STAT 545 is a 16-week semester — `_calculate_current_week`'s hardcoded
cap is a non-issue for this course. No cap-parametrization work needed before
implementing `teach dashboard generate`.

**Why:** Directly confirmed by the user. Closes the open question the spec raised
after finding the cap in `lib/teaching-utils.zsh:44`.

## Handoff

Both branches were the spec's only open questions — SPEC-teach-dashboard-2026-09-12.md
updated to mark them resolved. Ready for `/craft:plan` → worktree → implementation.
