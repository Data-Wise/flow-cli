# 🧠 BRAINSTORM: Integrate Migration Workflow into teach-init

**Generated:** 2026-01-12
**Mode:** Deep (Feature Focus)
**Duration:** 8 minutes 32 seconds
**Context:** flow-cli teaching workflow v2.0

---

## 📋 Executive Summary

Add intelligent migration workflow to `teach-init` command that automatically detects existing Quarto course projects and guides users through conversion to teaching workflow with branch safety, quick deploy, and week calculation features.

**Key Insight:** Current `teach-init` assumes fresh repo or simple existing git repo. Real-world teaching projects (like STAT 545) are complex Quarto websites with renv, rendered content, and specific structure. Need smart detection + guided migration.

---

## 🎯 User Requirements (From 10 Questions)

| Requirement        | Decision                                      |
| ------------------ | --------------------------------------------- |
| **Detection**      | Auto-detect `_quarto.yml` → offer migration   |
| **Backup**         | Git tag only (lightweight, no directory copy) |
| **renv Handling**  | Ask user each time (interactive prompt)       |
| **Validation**     | Strict - check `_quarto.yml`, `index.qmd`     |
| **Semester Dates** | After git setup (infrastructure first)        |
| **GitHub Push**    | Prompt for remote URL (optional)              |
| **History**        | Preserve all existing commits                 |
| **Documentation**  | Auto-generate `MIGRATION-COMPLETE.md`         |
| **Error Handling** | Rollback automatically on ANY error           |
| **Dry Run**        | Support `teach-init --dry-run` flag           |

---

## ⚡ Quick Wins (< 30 min each)

### 1. Add Quarto Detection Function

**Benefit:** Enables smart migration path selection

```zsh
_teach_detect_project_type() {
  if [[ -f "_quarto.yml" ]]; then
    echo "quarto"
  elif [[ -f "mkdocs.yml" ]]; then
    echo "mkdocs"
  else
    echo "unknown"
  fi
}
```

**Impact:** Foundation for all migration logic

---

### 2. Add Strict Validation Function

**Benefit:** Prevents migration on invalid projects

```zsh
_teach_validate_quarto_project() {
  local errors=()

  [[ ! -f "_quarto.yml" ]] && errors+=("Missing _quarto.yml")
  [[ ! -f "index.qmd" ]] && errors+=("Missing index.qmd (homepage)")

  if (( ${#errors[@]} > 0 )); then
    _flow_log_error "Project validation failed:"
    printf '  %s\n' "${errors[@]}"
    return 1
  fi

  return 0
}
```

**Impact:** Clear error messages, prevents broken migrations

---

### 3. Add renv Detection and Prompt

**Benefit:** Handles R package management symlinks gracefully

```zsh
_teach_handle_renv() {
  if [[ -d "renv" ]]; then
    echo ""
    echo "  ${FLOW_COLORS[warning]}⚠️  Detected renv/ directory${FLOW_COLORS[reset]}"
    echo "  R package management with symlinks (not suitable for git)"
    echo ""
    read "?  Exclude renv/ from git? [Y/n]: " exclude_renv

    if [[ "$exclude_renv" != "n" ]]; then
      echo "renv/" >> .gitignore
      echo "  ✅ Added renv/ to .gitignore"
    fi
  fi
}
```

**Impact:** Prevents backup failures, cleaner git history

---

### 4. Add Rollback Function

**Benefit:** Safe recovery on migration failure

```zsh
_teach_rollback_migration() {
  local tag="$1"

  _flow_log_error "Migration failed - rolling back to $tag"

  # Reset to tag
  git reset --hard "$tag"

  # Remove created files
  rm -rf .flow scripts .github/workflows/deploy.yml

  # Delete tag
  git tag -d "$tag"

  echo "  ✅ Rolled back to pre-migration state"
}
```

**Impact:** User confidence, no broken states

---

### 5. Add Dry-Run Mode

**Benefit:** Test migration without changes

```zsh
teach-init() {
  local course_name="$1"
  local dry_run=false

  # Parse flags
  if [[ "$1" == "--dry-run" ]]; then
    dry_run=true
    course_name="$2"
  fi

  # ... rest of logic

  if [[ "$dry_run" == "true" ]]; then
    echo "🔍 DRY RUN MODE - No changes will be made"
    _teach_show_migration_plan "$course_name"
    return 0
  fi
}
```

**Impact:** Confidence before execution, debugging tool

---

## 🔧 Medium Effort (1-2 hours)

### 6. Refactor Migration Strategy Menu

**Current:** Two simple options (in-place, two-branch)
**New:** Three intelligent options based on project state

```zsh
_teach_migrate_existing_repo() {
  local course_name="$1"
  local project_type=$(_teach_detect_project_type)

  if [[ "$project_type" == "quarto" ]]; then
    _teach_migrate_quarto_project "$course_name"
  else
    _teach_migrate_generic_repo "$course_name"
  fi
}

_teach_migrate_quarto_project() {
  local course_name="$1"

  # Validate first
  if ! _teach_validate_quarto_project; then
    return 1
  fi

  # Handle renv
  _teach_handle_renv

  # Show migration options
  echo "Choose migration strategy:"
  echo "  1. Convert existing branch → production (preserve history)"
  echo "  2. Create parallel branches (keep existing + add draft/production)"
  echo "  3. Fresh start (tag current, start new structure)"
  echo ""

  read "choice?Choice [1/2/3]: "

  case "$choice" in
    1) _teach_quarto_inplace_conversion "$course_name" ;;
    2) _teach_quarto_parallel_branches "$course_name" ;;
    3) _teach_quarto_fresh_start "$course_name" ;;
    *) echo "Invalid choice"; return 1 ;;
  esac
}
```

**Impact:** Handles complex Quarto projects correctly

---

### 7. Add GitHub Remote Integration

**Goal:** Optional push to remote during migration

```zsh
_teach_offer_github_push() {
  echo ""
  echo "GitHub Integration (Optional)"
  read "?  Push to GitHub remote? [y/N]: " push_github

  if [[ "$push_github" == "y" ]]; then
    read "remote_url?  GitHub remote URL: " remote_url

    if [[ -z "$remote_url" ]]; then
      _flow_log_warning "No URL provided - skipping push"
      return 0
    fi

    # Add remote
    git remote add origin "$remote_url"

    # Push branches
    git push -u origin production
    git push -u origin draft

    echo "  ✅ Pushed to $remote_url"
  else
    echo "  ℹ️  Push manually later: git remote add origin <url> && git push -u origin draft production"
  fi
}
```

**Impact:** Seamless GitHub Pages setup

---

### 8. Auto-Generate Migration Documentation

**Goal:** Create comprehensive migration report

```zsh
_teach_generate_migration_docs() {
  local course_name="$1"
  local start_date="$2"
  local end_date="$3"

  cat > MIGRATION-COMPLETE.md << EOF
# $course_name Teaching Workflow Migration - COMPLETE ✅

**Date:** $(date +%Y-%m-%d)
**Status:** Successfully migrated to flow-cli teaching workflow v2.0
**Branch:** draft (ready for editing)

---

## Migration Summary

### What Was Done

1. **Git Initialized** ✅
   - Pre-migration tag: $(git describe --tags --always HEAD~1)
   - Branch structure: $(git branch --show-current) + production

2. **Teaching Workflow Configured** ✅
   - Config: .flow/teach-config.yml
   - Course: $course_name
   - Semester: $start_date to $end_date

3. **Deployment Tools Created** ✅
   - scripts/quick-deploy.sh - Fast deployment
   - scripts/semester-archive.sh - End-of-semester archival
   - .github/workflows/deploy.yml - GitHub Actions

4. **Validation Passed** ✅
   - Project type: Quarto website
   - Required files: _quarto.yml, index.qmd
   - Structure: Valid

---

## Daily Workflow

\`\`\`bash
# Start work session (safe on draft branch)
work $course_name

# Edit course materials
# Commit changes

# Deploy to production (when ready)
./scripts/quick-deploy.sh
\`\`\`

---

## Branch Safety

The workflow uses two branches:
- **draft**: Safe for editing (current)
- **production**: What students see (deployed)

**Automatic warning when editing production branch.**

---

## Next Steps

1. Test workflow: \`work $course_name\`
2. Make edit, commit, deploy: \`./scripts/quick-deploy.sh\`
3. Set up GitHub Pages (optional)

EOF

  echo "  ✅ Created MIGRATION-COMPLETE.md"
}
```

**Impact:** Self-documenting migrations, onboarding aid

---

### 9. Add Error Handling with Rollback

**Goal:** Safe execution with automatic recovery

```zsh
_teach_quarto_inplace_conversion() {
  local course_name="$1"
  local current_branch=$(git branch --show-current)

  # Create rollback tag
  local semester=$(date +"%B" | sed 's/.*/\L&/; s/jan.*/spring/; s/feb.*/spring/; ...')
  local year=$(date +%Y)
  local tag="$semester-$year-pre-migration"

  git tag -a "$tag" -m "Pre-migration snapshot" || {
    _flow_log_error "Failed to create rollback tag"
    return 1
  }

  # Execute migration with error trapping
  {
    git branch -m "$current_branch" production &&
    git checkout -b draft production &&
    _teach_install_templates "$course_name" &&
    _teach_offer_github_push &&
    _teach_generate_migration_docs "$course_name"
  } || {
    # ROLLBACK on any error
    _teach_rollback_migration "$tag"
    return 1
  }

  echo ""
  echo "✅ Migration complete"
  _teach_show_next_steps "$course_name"
}
```

**Impact:** Production-grade reliability

---

## 🏗️ Long-term (Future Sessions)

### 10. Migration Diagnostics Command

**Concept:** `teach-init --diagnose` to check project readiness

```zsh
teach-init --diagnose
→ Project type: Quarto website
→ Git status: 5 commits, clean working directory
→ Required files: ✅ All present
→ renv detected: ⚠️  Recommend exclusion
→ Remote: ✅ origin configured
→ Readiness: ✅ Ready for migration
```

**Benefit:** Pre-flight checks, reduce failures

---

### 11. Multi-Project Migration

**Concept:** Migrate multiple courses at once

```bash
teach-init --batch stat-440 stat-545 causal-inference
→ Validates all three
→ Migrates in sequence
→ Reports success/failure per project
```

**Benefit:** Semester transition automation

---

### 12. Migration Templates by Project Type

**Concept:** Smart templates for different course frameworks

```bash
teach-init stat-545
→ Detects: Quarto
→ Uses: quarto-teaching-template

teach-init machine-learning
→ Detects: Jupyter notebooks
→ Uses: jupyter-teaching-template

teach-init data-viz
→ Detects: R Markdown
→ Uses: rmarkdown-teaching-template
```

**Benefit:** Support diverse teaching tech stacks

---

### 13. Interactive Migration Wizard

**Concept:** Step-by-step UI with progress tracking

```
┌─────────────────────────────────────────────────────────────┐
│ 🎓 Teaching Workflow Migration Wizard                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Step 1/5: Project Validation             [████████] 100%   │
│   ✅ Detected: Quarto website                               │
│   ✅ Required files present                                 │
│                                                             │
│ Step 2/5: Backup & Safety                [ In Progress... ] │
│   ⏳ Creating pre-migration tag...                          │
│                                                             │
│ [Cancel]                                        [Continue]  │
└─────────────────────────────────────────────────────────────┘
```

**Benefit:** User confidence, clear progress

---

## 🔗 Dependencies

| Component        | Required     | Purpose                            |
| ---------------- | ------------ | ---------------------------------- |
| **yq**           | Yes          | YAML parsing for config            |
| **git**          | Yes          | Version control                    |
| **rsync**        | Optional     | Directory backups (if not git tag) |
| **gh CLI**       | Optional     | GitHub integration                 |
| **\_quarto.yml** | Yes (Quarto) | Project detection                  |

---

## 📊 Implementation Architecture

### Current Flow (v5.3.0)

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
           ↓
         Install templates
           ↓
         Done
```

### Proposed Flow (v5.4.0)

```
teach-init [--dry-run] "Course"
  ↓
Parse flags (--dry-run?)
  ↓
Check git
  ├→ No git: Offer to initialize
  │    ↓
  │  git init → Continue to detection
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
       │  Strategy menu (3 options)
       │    ├→ Convert existing → production
       │    ├→ Create parallel branches
       │    └→ Fresh start (tag + new)
       │         ↓
       │  Create rollback tag
       │         ↓
       │  Execute migration (with error trap)
       │    ├→ SUCCESS: Continue
       │    └→ FAIL: Rollback (_teach_rollback_migration)
       │         ↓
       │  Install templates
       │         ↓
       │  GitHub push? (_teach_offer_github_push)
       │         ↓
       │  Generate docs (_teach_generate_migration_docs)
       │         ↓
       │  Done
       │
       └→ Generic: _teach_migrate_generic_repo
            ↓
          Existing flow (unchanged)
```

---

## 🎯 Acceptance Criteria

### Must Have (v5.4.0)

- [x] Auto-detect Quarto projects via `_quarto.yml`
- [x] Strict validation before migration
- [x] Interactive renv/ handling
- [x] Git tag backup (no directory copy)
- [x] Automatic rollback on errors
- [x] Preserve git history
- [x] Auto-generate `MIGRATION-COMPLETE.md`
- [x] Semester date prompts after git setup
- [x] GitHub remote push prompt
- [x] `--dry-run` flag support

### Should Have (v5.5.0)

- [ ] `teach-init --diagnose` for readiness check
- [ ] Multi-project batch migration
- [ ] Migration progress UI
- [ ] Template detection for other frameworks (Jupyter, R Markdown)

### Nice to Have (Future)

- [ ] Migration undo command (`teach-init --undo`)
- [ ] Migration history log
- [ ] Cloud backup integration
- [ ] Video tutorial generation

---

## 🧪 Testing Strategy

### Unit Tests

```zsh
# Test detection
test_quarto_detection() {
  touch _quarto.yml
  assert_equals "$(_teach_detect_project_type)" "quarto"
}

# Test validation
test_quarto_validation_missing_index() {
  touch _quarto.yml
  # No index.qmd
  assert_fails _teach_validate_quarto_project
}

# Test rollback
test_rollback_on_error() {
  # Setup: create tag
  git tag test-rollback

  # Trigger error in migration
  # (simulate sed failure)

  # Assert: back to tag state
  assert_equals "$(git describe --tags)" "test-rollback"
}
```

### Integration Tests

```zsh
# End-to-end migration test
test_full_quarto_migration() {
  # 1. Create test Quarto project
  mkdir -p test-course
  cd test-course
  echo "project: { type: website }" > _quarto.yml
  echo "# Home" > index.qmd
  git init && git add . && git commit -m "Initial"

  # 2. Run teach-init
  teach-init "Test Course" <<< "1\ny\n2025-01-13\nn\nn"

  # 3. Verify structure
  assert_file_exists .flow/teach-config.yml
  assert_file_exists scripts/quick-deploy.sh
  assert_branch_exists draft
  assert_branch_exists production

  # 4. Verify docs
  assert_file_exists MIGRATION-COMPLETE.md
}
```

### Manual Tests

1. **STAT 545 Migration** (Real Project)
   - Quarto website with renv
   - Test dry-run first
   - Run migration
   - Verify all features work

2. **Fresh Course** (New Project)
   - No git
   - Run teach-init
   - Verify fresh repo flow works

3. **Generic Repo** (Non-Quarto)
   - Simple git repo without \_quarto.yml
   - Verify fallback to existing flow

---

## 🚀 Recommended Implementation Order

### Phase 1: Foundation (Week 1)

1. ✅ Add detection function (`_teach_detect_project_type`)
2. ✅ Add validation function (`_teach_validate_quarto_project`)
3. ✅ Add renv handling (`_teach_handle_renv`)
4. ✅ Add rollback function (`_teach_rollback_migration`)

**Deliverable:** Core safety features in place

---

### Phase 2: Migration Logic (Week 2)

5. ✅ Refactor `_teach_migrate_existing_repo` with detection
6. ✅ Create `_teach_migrate_quarto_project` function
7. ✅ Add three migration strategies for Quarto
8. ✅ Integrate error handling with rollback

**Deliverable:** Smart Quarto migration works end-to-end

---

### Phase 3: Polish (Week 3)

9. ✅ Add GitHub push integration
10. ✅ Add auto-doc generation (`_teach_generate_migration_docs`)
11. ✅ Add `--dry-run` flag support
12. ✅ Write comprehensive tests

**Deliverable:** Production-ready v5.4.0

---

### Phase 4: Advanced Features (Future)

13. [ ] Add `--diagnose` command
14. [ ] Add batch migration
15. [ ] Add interactive wizard
16. [ ] Add template system for other frameworks

**Deliverable:** Enhanced user experience

---

## 📐 Design Trade-offs

| Decision              | Pro                              | Con                           | Rationale                         |
| --------------------- | -------------------------------- | ----------------------------- | --------------------------------- |
| **Git tag backup**    | Lightweight, fast, in-repo       | Requires git tag -d to clean  | User preference, fits workflow    |
| **Strict validation** | Prevents broken migrations       | Blocks non-standard projects  | Safety first, clear errors        |
| **Auto-rollback**     | Safe recovery, no manual cleanup | Can't inspect failed state    | User confidence > debugging       |
| **Dry-run flag**      | Test before commit               | Requires extra implementation | Essential for complex migrations  |
| **Ask about renv**    | User control, transparent        | Extra prompt (friction)       | R-specific issue, needs awareness |

---

## 🔍 Open Questions

1. **How to handle semester date errors?**
   - Current: Validation stops on invalid format
   - Alternative: Allow any format, warn if unparseable
   - **Decision needed:** Strict or permissive?

2. **Should we support migration from other branches (not main)?**
   - Current: Assumes migration from current branch
   - Alternative: Allow `teach-init --from feature/spring-2025`
   - **Decision needed:** Common enough to support?

3. **What if GitHub remote already exists?**
   - Current: `git remote add` will fail
   - Alternative: Detect existing remote, use `git remote set-url`
   - **Decision needed:** How to handle?

4. **Should dry-run show actual file contents?**
   - Current spec: Show plan only
   - Alternative: Generate all files in `/tmp`, show diffs
   - **Decision needed:** How detailed?

---

## 💡 Key Insights

### 1. Migration != Fresh Setup

Real-world teaching projects have:

- Complex directory structures (Quarto, R, LaTeX)
- Generated content (\_site/, renv/)
- Existing git history
- Platform-specific quirks (macOS symlinks, Windows CRLF)

**Insight:** Need project-type-specific migration paths, not one-size-fits-all.

---

### 2. Safety is Paramount

Failed migrations are costly:

- Lost work
- Broken courses mid-semester
- User trust destroyed

**Insight:** Rollback on ANY error. Git tags are cheap, user time is expensive.

---

### 3. Documentation is Implementation

Auto-generated docs:

- Prove migration worked
- Aid future debugging
- Serve as onboarding guide

**Insight:** MIGRATION-COMPLETE.md is not "nice to have" - it's essential artifact.

---

### 4. Dry-run is Must-have

Teaching projects are high-stakes:

- Students depend on uptime
- Semester schedule is inflexible
- Can't "just try again"

**Insight:** Dry-run isn't optional - it's risk management.

---

## 🎯 Success Metrics

| Metric                     | Target  | Measurement                   |
| -------------------------- | ------- | ----------------------------- |
| **Migration success rate** | > 95%   | Rollbacks / Total migrations  |
| **Time to migrate**        | < 5 min | User time (excluding input)   |
| **User confidence**        | High    | Qualitative feedback          |
| **Error recovery**         | 100%    | Successful rollbacks / Errors |
| **Dry-run adoption**       | > 50%   | Dry-runs / Total migrations   |

---

## 📚 Documentation Needs

### User Docs

1. **Migration Guide** (existing)
   - Update with new `teach-init` flow
   - Add dry-run examples
   - Add troubleshooting section

2. **teach-init Reference** (new)
   - Flags: `--dry-run`, `--diagnose`
   - Project type detection table
   - Migration strategies explained

3. **Video Tutorial** (future)
   - 5-minute walkthrough
   - STAT 545 as example
   - Common pitfalls

### Developer Docs

1. **Architecture Decision Record**
   - Why rollback over partial recovery
   - Why strict validation
   - Why git tags over directory backups

2. **Testing Guide**
   - How to test migrations safely
   - Mock project creation
   - Rollback testing

3. **Project Type Detection**
   - How to add new types
   - Validation requirements
   - Template system

---

## 🔗 Related Commands

| Command                         | Relationship                           |
| ------------------------------- | -------------------------------------- |
| `work <project>`                | Triggers branch safety after migration |
| `dash teach`                    | Shows migrated teaching projects       |
| `./scripts/quick-deploy.sh`     | Primary daily workflow after migration |
| `./scripts/semester-archive.sh` | End-of-life for migrated courses       |
| `flow doctor`                   | Dependency checking (yq, git)          |

---

## 📅 Timeline Estimate

| Phase                        | Duration   | Complexity                    |
| ---------------------------- | ---------- | ----------------------------- |
| **Phase 1: Foundation**      | 2-3 hours  | Medium (safety critical)      |
| **Phase 2: Migration Logic** | 3-4 hours  | High (error handling complex) |
| **Phase 3: Polish**          | 2-3 hours  | Medium (GitHub API, docs)     |
| **Testing**                  | 2-3 hours  | Medium (need real projects)   |
| **Total**                    | 9-13 hours | High (but high value)         |

**Recommended:** Break into 4 PRs (one per phase)

---

## ✅ Next Steps

### Immediate (Today)

1. **Create feature branch**

   ```bash
   cd ~/projects/dev-tools/flow-cli
   git checkout dev
   git checkout -b feature/teach-init-migration
   ```

2. **Implement Quick Wins #1-5**
   - Detection function
   - Validation function
   - renv handling
   - Rollback function
   - Dry-run mode

3. **Write unit tests**
   - Test each new function in isolation
   - Use mocking for git commands

### This Week

4. **Implement Phase 2**
   - Refactor migration strategy menu
   - Add Quarto-specific logic
   - Integrate error handling

5. **Manual testing with STAT 545**
   - Use dry-run first
   - Run full migration
   - Verify all features

6. **Create PR to dev**
   - Include tests
   - Update documentation
   - Request review

### Next Sprint

7. **Implement Phase 3**
   - GitHub integration
   - Auto-documentation
   - Final polish

8. **User testing**
   - Migrate STAT 440
   - Migrate causal-inference
   - Gather feedback

9. **Release v5.4.0**
   - Merge to main
   - Tag release
   - Update website docs

---

## 🎓 Summary

**What:** Add intelligent Quarto project migration to `teach-init`

**Why:** Real teaching projects need guided, safe conversion to teaching workflow

**How:** Detection → Validation → Guided Migration → Error Recovery → Documentation

**Value:** Enables adoption of teaching workflow for existing courses, not just new ones

**Risk:** Migration complexity - mitigated by strict validation, dry-run, and auto-rollback

**Effort:** ~10-12 hours over 2 weeks

**Impact:** Unlocks teaching workflow for all DT's courses (STAT 440, 545, causal-inference)

---

**Ready to implement?** Start with Phase 1 (Foundation) - 5 quick wins, 2-3 hours total.
