# SPEC: Intelligent Migration Workflow for teach-init

**Status:** Completed (Implemented in v5.4.1)
**Created:** 2026-01-12
**Updated:** 2026-01-13 (Documentation cleanup)
**Target Release:** v5.4.0 (Delivered in v5.4.1)
**Estimated Effort:** 10-12 hours over 2 weeks

---

## Overview

Add intelligent Quarto project detection and guided migration workflow to `teach-init` command. Enable safe, automated conversion of existing course websites (like STAT 545, STAT 440, causal-inference) to teaching workflow with branch safety, quick deploy, and week calculation features.

**Key Value:** Unlocks teaching workflow adoption for all existing teaching projects, not just new courses.

---

## Primary User Story

**As a** course instructor (DT) with existing Quarto course websites,
**I want** to convert them to the teaching workflow with branch safety and quick deployment,
**So that** I can safely edit course materials on draft branch while students see stable production content.

### Acceptance Criteria

1. ✅ `teach-init` auto-detects existing Quarto projects via `_quarto.yml`
2. ✅ Strict validation prevents migration on invalid projects (missing required files)
3. ✅ Interactive prompt handles renv/ directories (R package management)
4. ✅ Git tag backup created before migration (lightweight, no directory copy)
5. ✅ Automatic rollback on ANY migration error
6. ✅ All existing git history preserved during migration
7. ✅ Auto-generated `MIGRATION-COMPLETE.md` documentation
8. ✅ Semester date prompts appear after git setup (not before)
9. ✅ Optional GitHub remote push integration (prompt for URL)
10. ✅ `--dry-run` flag shows migration plan without changes
11. ✅ Unit tests validate detection, validation, rollback functions
12. ✅ Integration tests validate end-to-end Quarto migration
13. ✅ Real-world migrations succeed: STAT 545, STAT 440, causal-inference

---

## Secondary User Stories

### Story 2: Safe Migration with Rollback

**As a** course instructor,
**I want** automatic rollback if migration fails,
**So that** I never end up with a broken course repository mid-semester.

**Acceptance Criteria:**
- Error detection at every migration step
- Automatic git reset to pre-migration tag
- Cleanup of created files (.flow/, scripts/)
- Clear error message showing what failed

---

### Story 3: Dry-Run Validation

**As a** course instructor,
**I want** to preview migration changes before committing,
**So that** I can verify the plan matches my expectations.

**Acceptance Criteria:**
- `teach-init --dry-run "Course"` shows plan
- No git changes made
- Shows detected project type, validation results
- Shows what branches would be created
- Shows what files would be added

---

## Technical Requirements

### Architecture

#### Current Flow (v5.3.0)

```
teach-init "Course"
  ↓
Check git
  ├→ No git: Error "Initialize git first"
  └→ Has git: _teach_migrate_existing_repo
       ↓
     Strategy menu (2 options)
       ├→ In-place conversion
       └→ Two-branch setup
```

#### Proposed Flow (v5.4.0)

```
teach-init [--dry-run] "Course"
  ↓
Parse flags
  ↓
Check git
  ├→ No git: Offer to initialize
  │    ↓
  │  git init → Continue
  │
  └→ Has git: Detect project type
       ├→ Quarto: _teach_migrate_quarto_project
       │    ↓
       │  Validate (_teach_validate_quarto_project)
       │    ├→ FAIL: Show errors, exit
       │    └→ PASS: Continue
       │         ↓
       │  Handle renv (_teach_handle_renv)
       │         ↓
       │  Create rollback tag
       │         ↓
       │  Execute migration (with error trap)
       │    ├→ SUCCESS: Continue
       │    └→ FAIL: Rollback
       │         ↓
       │  Install templates
       │         ↓
       │  GitHub push? (optional)
       │         ↓
       │  Generate docs
       │         ↓
       │  Done
       │
       └→ Generic: _teach_migrate_generic_repo (existing)
```

---

### API Design

#### New Functions

| Function | Purpose | Input | Output |
|----------|---------|-------|--------|
| `_teach_detect_project_type` | Detect project type | None (checks CWD) | "quarto" \| "mkdocs" \| "unknown" |
| `_teach_validate_quarto_project` | Validate Quarto structure | None | 0 (success) \| 1 (fail) |
| `_teach_handle_renv` | Handle renv/ directories | None | Modifies .gitignore if needed |
| `_teach_rollback_migration` | Rollback failed migration | tag_name | None (resets to tag) |
| `_teach_migrate_quarto_project` | Quarto-specific migration | course_name | 0 (success) \| 1 (fail) |
| `_teach_offer_github_push` | Optional GitHub integration | None | Pushes if user confirms |
| `_teach_generate_migration_docs` | Create MIGRATION-COMPLETE.md | course_name, dates | None (creates file) |
| `_teach_show_migration_plan` | Dry-run output | course_name | None (prints plan) |

---

#### Modified Functions

| Function | Changes | Rationale |
|----------|---------|-----------|
| `teach-init` | Add `--dry-run` flag parsing | Enable preview mode |
| `teach-init` | Offer `git init` if no .git/ | Smoother UX for fresh projects |
| `_teach_migrate_existing_repo` | Add project type detection | Route to Quarto vs generic flow |
| `_teach_install_templates` | Wrap in error trap | Enable rollback on template failure |

---

### Data Models

#### Project Detection Result

```zsh
# Returned by _teach_detect_project_type
"quarto"    # Has _quarto.yml
"mkdocs"    # Has mkdocs.yml (future)
"unknown"   # Generic git repo
```

#### Validation Result

```zsh
# _teach_validate_quarto_project returns:
0  # Valid: _quarto.yml + index.qmd present
1  # Invalid: missing required files

# Errors array populated on failure:
errors=(
  "Missing _quarto.yml"
  "Missing index.qmd (homepage)"
)
```

#### Migration Strategy

```zsh
# User selects one of three strategies:
1  # Convert existing → production (preserve history)
2  # Create parallel branches (keep existing + add draft/prod)
3  # Fresh start (tag current, start new structure)
```

---

### Dependencies

| Dependency | Required | Purpose | Installation |
|------------|----------|---------|--------------|
| **yq** | Yes | YAML config parsing | `brew install yq` |
| **git** | Yes | Version control | Built-in (macOS) |
| **gh CLI** | Optional | GitHub push integration | `brew install gh` |
| **rsync** | Optional | Future: directory backups | Built-in (macOS) |

---

## UI/UX Specifications

### User Flow: Quarto Migration

```
┌────────────────────────────────────────────────────────────┐
│ Step 1: Detection                                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ $ teach-init "STAT 545"                                    │
│                                                            │
│ 🎓 Initializing teaching workflow for: STAT 545           │
│                                                            │
│ 📋 Detected existing git repository                        │
│ 📚 Detected: Quarto website                                │
│ Current branch: main                                       │
│                                                            │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ Step 2: Validation                                         │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ ✅ _quarto.yml found                                       │
│ ✅ index.qmd found                                         │
│ ✅ Project structure valid                                 │
│                                                            │
│ ⚠️  Detected renv/ directory                               │
│   R package management with symlinks (not suitable for git)│
│                                                            │
│   Exclude renv/ from git? [Y/n]: █                         │
│                                                            │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ Step 3: Strategy Selection                                 │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ Choose migration strategy:                                 │
│   1. Convert existing branch → production (preserve history)│
│   2. Create parallel branches (keep existing + add draft)  │
│   3. Fresh start (tag current, start new structure)        │
│                                                            │
│ Choice [1/2/3]: █                                          │
│                                                            │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ Step 4: Confirmation                                       │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ ⚠️  This will:                                             │
│   1. Create rollback tag: spring-2026-pre-migration        │
│   2. Rename main → production                              │
│   3. Create new draft branch from production               │
│   4. Add .flow/teach-config.yml and scripts/               │
│                                                            │
│ Continue? [y/N]: █                                         │
│                                                            │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ Step 5: Migration Execution                                │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ 🏷️  Creating rollback tag...                              │
│ ✅ Tag created: spring-2026-pre-migration                  │
│                                                            │
│ 🔀 Renaming branch...                                      │
│ ✅ Renamed main → production                               │
│                                                            │
│ 🌿 Creating draft branch...                                │
│ ✅ Created draft from production                           │
│                                                            │
│ 📝 Installing templates...                                 │
│ ✅ Created .flow/teach-config.yml                          │
│ ✅ Created scripts/quick-deploy.sh                         │
│ ✅ Created scripts/semester-archive.sh                     │
│ ✅ Created .github/workflows/deploy.yml                    │
│                                                            │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ Step 6: Semester Configuration                             │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ Semester Schedule                                          │
│   Configure semester start/end dates for week calculation  │
│                                                            │
│   Start date (YYYY-MM-DD) [2026-01-13]: █                  │
│                                                            │
│   Calculated end date: 2026-05-06 (16 weeks)               │
│                                                            │
│   Add spring/fall break? [y/N]: y                          │
│                                                            │
│   Break name [Spring Break]: █                             │
│   Break start [2026-03-10]: █                              │
│   Break end [2026-03-17]: █                                │
│                                                            │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ Step 7: GitHub Integration (Optional)                      │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ GitHub Integration (Optional)                              │
│   Push to GitHub remote? [y/N]: y                          │
│                                                            │
│   GitHub remote URL: https://github.com/dtofighi/stat-545  │
│                                                            │
│ 📤 Pushing to remote...                                    │
│ ✅ Pushed draft → origin/draft                             │
│ ✅ Pushed production → origin/production                   │
│                                                            │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ Step 8: Documentation Generation                           │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ 📄 Generating migration documentation...                   │
│ ✅ Created MIGRATION-COMPLETE.md                           │
│                                                            │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ Step 9: Success                                            │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│ 🎉 Teaching workflow initialized!                          │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                                            │
│ Next steps:                                                │
│                                                            │
│   1. Review config:                                        │
│      $EDITOR .flow/teach-config.yml                        │
│                                                            │
│   2. Test deployment:                                      │
│      ./scripts/quick-deploy.sh                             │
│                                                            │
│   3. Start working:                                        │
│      work STAT 545                                         │
│                                                            │
│ 📚 Documentation:                                          │
│    https://data-wise.github.io/flow-cli/                  │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

### Wireframes (ASCII)

#### Dry-Run Output

```
$ teach-init --dry-run "STAT 545"

┌────────────────────────────────────────────────────────────┐
│ 🔍 DRY RUN MODE - No changes will be made                 │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ Migration Plan for: STAT 545                               │
│                                                            │
│ Detection:                                                 │
│   ✅ Git repository found                                  │
│   ✅ Project type: Quarto website                          │
│   ✅ Current branch: main                                  │
│                                                            │
│ Validation:                                                │
│   ✅ _quarto.yml found                                     │
│   ✅ index.qmd found                                       │
│   ⚠️  renv/ detected (will prompt to exclude)             │
│                                                            │
│ Actions that would be taken:                               │
│   1. Create rollback tag: spring-2026-pre-migration        │
│   2. Rename main → production                              │
│   3. Create draft branch from production                   │
│   4. Add .flow/teach-config.yml                            │
│   5. Add scripts/quick-deploy.sh                           │
│   6. Add scripts/semester-archive.sh                       │
│   7. Add .github/workflows/deploy.yml                      │
│   8. Prompt for semester dates                             │
│   9. Prompt for GitHub push (optional)                     │
│  10. Generate MIGRATION-COMPLETE.md                        │
│                                                            │
│ Estimated time: ~3 minutes                                 │
│                                                            │
│ To execute for real:                                       │
│   teach-init "STAT 545"                                    │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

#### Error with Rollback

```
$ teach-init "STAT 545"

[... migration steps ...]

📝 Installing templates...
✅ Created .flow/teach-config.yml
❌ ERROR: Failed to copy quick-deploy.sh

┌────────────────────────────────────────────────────────────┐
│ ❌ Migration Failed - Rolling Back                         │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ Error: Failed to copy quick-deploy.sh                      │
│ Location: _teach_install_templates                         │
│                                                            │
│ 🔄 Automatic Rollback:                                     │
│   ✅ Reset to tag: spring-2026-pre-migration               │
│   ✅ Removed .flow/ directory                              │
│   ✅ Removed scripts/ directory                            │
│   ✅ Removed .github/workflows/deploy.yml                  │
│   ✅ Deleted rollback tag                                  │
│                                                            │
│ Your repository is back to its original state.             │
│                                                            │
│ 💡 Troubleshooting:                                        │
│   - Check file permissions                                 │
│   - Verify FLOW_PLUGIN_DIR is set                          │
│   - Run: flow doctor                                       │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

### Accessibility Checklist

- [x] Color-blind friendly (use icons + text, not just color)
- [x] Clear progress indicators (emoji + text)
- [x] Keyboard-only navigation (no mouse required)
- [x] Error messages actionable (tell user HOW to fix)
- [x] Success criteria explicit (what does "done" mean?)
- [x] Dry-run available (preview before commit)
- [x] Rollback automatic (no manual recovery steps)
- [x] Documentation auto-generated (no separate docs task)

---

## Open Questions

### Q1: How to handle semester date errors?

**Current:** Validation stops on invalid format (e.g., "Jan 13" instead of "2025-01-13")

**Options:**
1. Strict: Reject any format except YYYY-MM-DD
2. Permissive: Allow any format, warn if unparseable, fallback to manual edit
3. Smart: Try to parse various formats (dateutil-style), convert to YYYY-MM-DD

**Decision:** Strict (Option 1) - Least ambiguity, clearest UX

**Rationale:** Semester dates are critical for week calculation. Better to error early with clear message than accept ambiguous input.

---

### Q2: Should we support migration from non-current branches?

**Current:** Assumes migration from current branch

**Options:**
1. Current branch only (simplest)
2. Add `--from <branch>` flag to specify
3. Auto-detect if branch name suggests semester (e.g., feature/spring-2025)
4. Interactive: "Migrate from current (main) or different branch?"

**Decision:** Current branch only (Option 1) for v5.4.0

**Rationale:** YAGNI principle. If needed, add `--from` flag in future version.

---

### Q3: What if GitHub remote already exists?

**Current:** `git remote add origin <url>` will fail if origin exists

**Options:**
1. Error: "Remote already exists - push manually"
2. Detect: Use `git remote set-url origin <url>`
3. Ask: "Remote exists. Update URL or skip?"
4. Smart: If URL matches, just push. If different, ask.

**Decision:** Smart detection (Option 4)

**Implementation:**

```zsh
if git remote get-url origin &>/dev/null; then
  current_url=$(git remote get-url origin)
  if [[ "$current_url" == "$remote_url" ]]; then
    # Same URL, just push
    git push -u origin draft production
  else
    # Different URL, ask user
    echo "Remote origin exists: $current_url"
    read "?Update to $remote_url? [y/N]: " update
    if [[ "$update" == "y" ]]; then
      git remote set-url origin "$remote_url"
      git push -u origin draft production
    fi
  fi
else
  # No remote, add it
  git remote add origin "$remote_url"
  git push -u origin draft production
fi
```

---

### Q4: Should dry-run show actual file contents?

**Current spec:** Dry-run shows plan only (what WOULD happen)

**Options:**
1. Plan only (current spec)
2. Plan + file previews (show generated .flow/teach-config.yml)
3. Plan + full simulation (generate all files in /tmp, show diffs)
4. Interactive: "Show details? [y/N]" after plan

**Decision:** Plan only (Option 1) for v5.4.0, add `--verbose` flag later

**Rationale:** Dry-run should be fast (< 1 second). Generating files defeats purpose.

**Future enhancement:** Add `teach-init --dry-run --verbose` to show file previews

---

## Review Checklist

### Completeness

- [x] All 10 user requirements addressed
- [x] All functions defined with signatures
- [x] All user flows documented with wireframes
- [x] Error handling specified
- [x] Rollback mechanism detailed
- [x] Testing strategy included
- [x] Open questions resolved

### Clarity

- [x] Primary user story clear
- [x] Acceptance criteria measurable
- [x] Architecture diagrams present
- [x] Code examples provided
- [x] UX flows illustrated

### Feasibility

- [x] Implementation phases defined (4 phases)
- [x] Effort estimated (10-12 hours)
- [x] Dependencies identified (yq, git)
- [x] Test strategy comprehensive
- [x] Rollback safety proven (git tags)

### Alignment

- [x] Matches brainstorm decisions
- [x] Follows flow-cli conventions
- [x] Integrates with existing commands
- [x] Compatible with teaching workflow v2.0

---

## Implementation Notes

### Phase 1: Foundation (2-3 hours)

**Goal:** Core safety features

**Tasks:**
1. Add `_teach_detect_project_type()` function
2. Add `_teach_validate_quarto_project()` function
3. Add `_teach_handle_renv()` function
4. Add `_teach_rollback_migration()` function
5. Add `--dry-run` flag parsing to `teach-init`

**Tests:**
- Unit test each function in isolation
- Mock git commands for testing

**Deliverable:** Safety infrastructure in place

---

### Phase 2: Migration Logic (3-4 hours)

**Goal:** Smart Quarto migration

**Tasks:**
1. Refactor `_teach_migrate_existing_repo()` with detection
2. Create `_teach_migrate_quarto_project()` function
3. Add three migration strategies (convert, parallel, fresh)
4. Integrate error handling with rollback
5. Add semester date prompts after git setup

**Tests:**
- Integration test: full Quarto migration
- Integration test: rollback on error
- Integration test: dry-run shows plan

**Deliverable:** End-to-end Quarto migration works

---

### Phase 3: Polish (2-3 hours)

**Goal:** Production features

**Tasks:**
1. Add `_teach_offer_github_push()` function
2. Add `_teach_generate_migration_docs()` function
3. Handle existing GitHub remotes (smart detection)
4. Polish UX messages and progress indicators
5. Update `_teach_show_next_steps()` with migration context

**Tests:**
- Manual test: GitHub push integration
- Manual test: MIGRATION-COMPLETE.md generation
- Manual test: Existing remote handling

**Deliverable:** Production-ready v5.4.0

---

### Phase 4: Real-World Testing (2-3 hours)

**Goal:** Validate with actual courses

**Tasks:**
1. Dry-run on STAT 545
2. Full migration on STAT 545
3. Full migration on STAT 440
4. Full migration on causal-inference
5. Gather feedback, iterate

**Tests:**
- Real project validation
- User acceptance testing

**Deliverable:** Confidence for release

---

## History

| Date | Event | Notes |
|------|-------|-------|
| 2026-01-12 | Brainstorm session | 10 questions, deep mode, feature focus |
| 2026-01-12 | Spec created | From BRAINSTORM-teach-init-migration-2026-01-12.md |
| TBD | Implementation start | Phase 1: Foundation |
| TBD | PR to dev | Phase 1-3 complete |
| TBD | Release v5.4.0 | After real-world testing |

---

## Success Criteria

### Must Have (v5.4.0 Release)

- [x] All 10 user requirements implemented
- [x] Unit tests pass (detection, validation, rollback)
- [x] Integration tests pass (full migration, error rollback)
- [x] Real migration succeeds: STAT 545, STAT 440, causal-inference
- [x] Documentation updated (teach-init reference, migration guide)
- [x] Zero data loss (rollback works 100%)

### Should Have (v5.5.0)

- [ ] `teach-init --diagnose` for readiness check
- [ ] Batch migration support
- [ ] Migration progress UI
- [ ] Video tutorial created

### Nice to Have (Future)

- [ ] Migration undo command
- [ ] Migration history log
- [ ] Template system for other frameworks (Jupyter, R Markdown)

---

## Related Documentation

- [Teaching Workflow v2.0 Spec](SPEC-teaching-workflow-v2.md)
- [TEACH Dispatcher Reference](../reference/TEACH-DISPATCHER-REFERENCE.md)
- [DOT Dispatcher Tutorial](../tutorials/12-dot-dispatcher.md)
- [Architecture Reference](../reference/ARCHITECTURE.md)
- [Testing Guide](../guides/TESTING.md)

---

**Implementation Complete:** v5.4.1 - See [TEACH Dispatcher Reference](../reference/TEACH-DISPATCHER-REFERENCE.md) for current documentation.
