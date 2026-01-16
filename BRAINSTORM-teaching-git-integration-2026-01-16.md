# Brainstorm: Teaching + Git Integration Enhancement

**Generated:** 2026-01-16
**Mode:** Deep Feature Analysis
**Duration:** 8 expert questions
**Context:** flow-cli v5.10.0 - Teaching dispatcher + Git workflows

---

## Executive Summary

Enhance flow-cli's teaching dispatcher to provide seamless git integration with smart automation, safety checks, and PR-based deployment workflow. Target all instructor personas from git novices to experienced developers.

**Key Insight:** Teaching content creation has a natural "generate → review → commit → deploy" rhythm that maps perfectly to git workflows. Current disconnect forces manual context switching that breaks flow state.

---

## User Research Findings

### Pain Points Identified

1. **Primary:** Disconnect between teach commands and git workflow
   - teach commands don't automatically commit/push changes
   - Manual git operations break creative flow
   - Easy to forget to commit generated content

2. **All user types benefit:**
   - Course instructors managing multiple courses
   - TAs/collaborators on shared repos
   - Git novices need simplified workflows

3. **Desired automation (all selected):**
   - ✅ Auto-commit after content generation
   - ✅ Smart branch management (draft vs published)
   - ✅ Conflict detection before teach deploy
   - ✅ Automated pull requests for course updates

4. **Git awareness:** Offer to stash/commit before operations
   - Interactive cleanup, not forced
   - Preserve user control

5. **Ideal workflow:** Generate → Review in editor → Commit → Deploy
   - Manual review step critical
   - Not fully automated (quality matters)

6. **Deploy strategy:** teach deploy creates PR to production branch
   - Never push directly to production
   - PR-based review workflow

7. **Status enhancements:** Show warning + offer to commit/stash
   - Interactive prompts for cleanup
   - Not silent about dirty state

8. **Teaching mode:** Yes, but ask for confirmation on destructive operations
   - Balanced automation with safety
   - Streamlined but not reckless

---

## Current State Analysis

### What Exists (v5.10.0)

**Teaching Dispatcher:**

- 9 Scholar wrapper commands (exam, quiz, slides, lecture, assignment, syllabus, rubric, feedback, demo)
- Config validation with JSON Schema
- Flag validation before Scholar invocation
- Post-generation hooks (auto-stage teaching files)
- teach status, teach deploy, teach init

**Git Dispatcher:**

- g command for common git operations
- Short status (g), full status (g status)
- Commit, push, pull, log, branch management
- No teaching-specific integration

**Teaching Post-Generation Hook (line 281):**

```zsh
git add "$file" 2>/dev/null && \
    _flow_log_success "Staged: $file"
```

- Already auto-stages generated files!
- Silent on failure (2>/dev/null)
- No commit, just staging

**teach deploy:**

- Runs semester-specific deploy script
- No git branch awareness
- No PR creation
- Manual push required

### What's Missing

1. **No post-generation commit workflow**
   - Files staged, but not committed
   - No commit message generation
   - No push to remote

2. **No branch management**
   - No draft/production branch separation
   - teach deploy doesn't check current branch
   - No PR creation automation

3. **No dirty state handling**
   - teach status shows branch, but no git status
   - No interactive cleanup prompts
   - No conflict detection

4. **No teaching mode**
   - No streamlined workflow setting
   - No YOLO-style automation
   - Every operation manual

5. **No git safety checks**
   - teach commands work regardless of repo state
   - No detection of uncommitted changes
   - No remote sync verification

---

## Feature Design

### Phase 1: Smart Post-Generation Workflow (Quick Win - 2-3 hours)

**User Story:** As an instructor, after generating exam/quiz/slides, I want to review the content and commit it with one command.

**Implementation:**

1. **After content generation, show preview:**

   ```
   ✅ Generated: exams/exam01.qmd

   📝 Next steps:
      1. Review content (opens in $EDITOR)
      2. Commit to git

   AskUserQuestion:
     question: "Review and commit this content?"
     header: "Next"
     options:
       - "Review in editor first (Recommended)"
       - "Commit now with auto-generated message"
       - "Skip commit (I'll do it manually)"
   ```

2. **If "Review in editor":**
   - Open file in configured editor (blocking)
   - After editor closes, re-prompt: "Ready to commit?"
   - Generate commit message from content type + topic

3. **If "Commit now":**
   - Generate smart commit message:

     ```
     teach: add exam01 for Week 3 Hypothesis Testing

     Generated via: teach exam "Hypothesis Testing" --questions 20
     Course: STAT 545 (Fall 2024)

     Co-Authored-By: Scholar <scholar@example.com>
     ```

   - Run git commit
   - Ask: "Push to remote?" (yes/no)

4. **Commit message format:**
   - Conventional: `teach: add <content-type> for <topic>`
   - Include generation command for reproducibility
   - Include course context from teach-config.yml
   - Co-authored by Scholar (credit AI assistance)

**Files Modified:**

- `lib/dispatchers/teach-dispatcher.zsh` - Enhanced post-generation hook
- `lib/git-helpers.zsh` (new) - Commit message generation

**Success Criteria:**

- Generated content can be reviewed and committed in < 30 seconds
- Commit messages are descriptive and searchable
- Zero git commands typed manually

---

### Phase 2: Branch-Aware Deployment (Medium - 4-6 hours)

**User Story:** As an instructor, I want teach deploy to create a PR from draft to production, never pushing directly to main.

**Implementation:**

1. **Add branch configuration to teach-config.yml:**

   ```yaml
   git:
     draft_branch: draft # Where content is developed
     production_branch: main # Where site deploys from
     auto_pr: true # Create PR automatically
     require_clean: true # Abort if uncommitted changes
   ```

2. **teach deploy workflow:**

   ```
   ┌─────────────────────────────────────────────────────────┐
   │ teach deploy                                            │
   ├─────────────────────────────────────────────────────────┤
   │ Step 1: Pre-flight checks                               │
   │   ✓ On draft branch (draft)                             │
   │   ✓ No uncommitted changes                              │
   │   ✓ Remote is up-to-date                                │
   │                                                         │
   │ Step 2: Build site (quarto render / pkgdown)            │
   │   ✓ Build successful                                    │
   │                                                         │
   │ Step 3: Create Pull Request                             │
   │   Title: Deploy Week 3 Content                          │
   │   Body: [Auto-generated changelog from commits]         │
   │                                                         │
   │ AskUserQuestion: Create PR and push?                    │
   │   ○ Yes - Create PR (Recommended)                       │
   │   ○ Push to draft only (no PR)                          │
   │   ○ Cancel                                              │
   └─────────────────────────────────────────────────────────┘
   ```

3. **PR Creation:**
   - Use `gh pr create` (GitHub CLI)
   - Auto-generate title: "Deploy: Week N content updates"
   - Body includes:
     - List of new content (exams, quizzes, slides)
     - Commit log since last deploy
     - Build status
     - Preview link (if applicable)
   - Labels: `teaching`, `deploy`

4. **Conflict Detection:**
   - Before creating PR, check if production branch has new commits
   - If conflicts detected: "Production has been updated. Rebase first?"
   - Offer to run: `git fetch origin && git rebase origin/main`

**Files Modified:**

- `lib/dispatchers/teach-dispatcher.zsh` - Enhanced deploy command
- `lib/templates/teaching/teach-config.schema.json` - Add git section
- `lib/git-helpers.zsh` - PR creation, conflict detection

**Success Criteria:**

- teach deploy never pushes to production directly
- PR workflow is one command
- Conflicts detected before attempted merge

---

### Phase 3: Git-Aware teach status (Quick Win - 1-2 hours)

**User Story:** As an instructor, teach status should show me what content changes are uncommitted and offer to commit them.

**Implementation:**

1. **Enhanced teach status output:**

   ```
   ┌─────────────────────────────────────────────────────────┐
   │ 📚 Teaching Project Status                              │
   ├─────────────────────────────────────────────────────────┤
   │ Course:  STAT 545 - Data Science                        │
   │ Branch:  draft                                          │
   │ Remote:  ✓ Up-to-date with origin/draft                 │
   │                                                         │
   │ Git Status:                                             │
   │   ⚠️  3 uncommitted changes (teaching content)          │
   │      M  exams/exam01.qmd                                │
   │      A  slides/week03-slides.qmd                        │
   │      M  teach-config.yml                                │
   │                                                         │
   │ AskUserQuestion: Clean up uncommitted changes?         │
   │   ○ Commit teaching files (Recommended)                 │
   │   ○ Stash teaching files                                │
   │   ○ View diff first                                     │
   │   ○ Leave as-is                                         │
   └─────────────────────────────────────────────────────────┘
   ```

2. **Smart file filtering:**
   - Show only teaching-related files (based on project structure)
   - Detect common paths: `exams/`, `slides/`, `assignments/`, `lectures/`
   - Read paths from teach-config.yml if defined

3. **Interactive cleanup:**
   - "Commit teaching files" → Generate commit message, commit, offer push
   - "Stash teaching files" → `git stash push -m "Teaching WIP" <files>`
   - "View diff" → Show `git diff <teaching-files>`, then re-prompt
   - "Leave as-is" → Exit, show reminder to commit later

**Files Modified:**

- `lib/dispatchers/teach-dispatcher.zsh` - Enhanced status command
- `lib/git-helpers.zsh` - Smart file filtering

**Success Criteria:**

- teach status always shows git state
- Interactive prompts guide cleanup
- Zero manual git commands needed

---

### Phase 4: Teaching Mode (Medium - 3-4 hours)

**User Story:** As an instructor in content-creation mode, I want a streamlined workflow that auto-commits after generation but asks before pushing.

**Implementation:**

1. **Enable teaching mode:**

   ```bash
   # Global setting
   export FLOW_TEACHING_MODE=true

   # Or per-project (teach-config.yml)
   workflow:
     teaching_mode: true
     auto_commit: true      # Commit after generation
     auto_push: false       # Ask before push
   ```

2. **Teaching mode behavior:**
   - **After content generation:**
     - Auto-stage generated file (already happens)
     - Auto-commit with generated message (NEW)
     - Show: "✅ Committed: teach: add exam01 for Week 3"
     - Prompt: "Push to draft branch? [y/N]"

   - **Before teach deploy:**
     - Check if draft branch has unpushed commits
     - If yes: "Push 3 commits to origin/draft first? [Y/n]"
     - Then proceed with normal PR workflow

   - **teach status:**
     - Streamlined output (less verbose)
     - Auto-commit any teaching files if teaching_mode=true

3. **Safety confirmations (even in teaching mode):**
   - Always ask before:
     - Creating PR
     - Pushing to remote
     - Rebasing
     - Force-push
   - Never destructive without confirmation

4. **Teaching mode indicator:**
   - Show in teach status header
   - Show in prompt (if using Powerlevel10k integration)
   - Color-coded: 🎓 Green = teaching mode active

**Files Modified:**

- `lib/dispatchers/teach-dispatcher.zsh` - Teaching mode logic
- `lib/config-validator.zsh` - Validate teaching mode config
- `lib/templates/teaching/teach-config.schema.json` - Add workflow section

**Success Criteria:**

- Teaching mode can be enabled globally or per-project
- Auto-commits happen without prompts
- Push/PR operations still require confirmation
- Easy to toggle on/off

---

### Phase 5: Git Integration in teach init (Quick Win - 1 hour)

**User Story:** As an instructor starting a new course, teach init should set up git with draft/production branches automatically.

**Implementation:**

1. **Enhanced teach init:**

   ```
   teach init "STAT 545"

   ┌─────────────────────────────────────────────────────────┐
   │ 🚀 Initialize Teaching Workflow                         │
   ├─────────────────────────────────────────────────────────┤
   │ Course: STAT 545                                        │
   │ Semester: Spring 2025                                   │
   │                                                         │
   │ Git Setup:                                              │
   │   ○ Initialize git repo                                 │
   │   ○ Create draft + main branches                        │
   │   ○ Set up remote (GitHub)                              │
   │   ○ Skip git setup (existing repo)                      │
   │                                                         │
   │ Teaching Mode:                                          │
   │   ☑ Enable teaching mode                                │
   │   ☑ Auto-commit after content generation               │
   │   ☐ Auto-push to remote (not recommended)              │
   └─────────────────────────────────────────────────────────┘
   ```

2. **Git initialization options:**
   - Detect if already a git repo
   - If not: Offer to `git init`
   - Create `draft` branch from `main`
   - Add .gitignore for teaching projects
   - Optionally create GitHub repo via `gh repo create`

3. **Branch structure:**

   ```
   main   ──────────●──────────●   (production, deploys to GitHub Pages)
                     \           \
   draft  ────●──●───●──●──●──●   (active development)
   ```

4. **Initial commit:**

   ```
   teach: initialize STAT 545 course

   - Add teach-config.yml
   - Add course structure (exams/, slides/, assignments/)
   - Add .gitignore
   - Configure draft/main workflow

   Generated via: teach init "STAT 545"
   ```

**Files Modified:**

- `commands/teach-init.zsh` - Enhanced init with git setup
- `lib/git-helpers.zsh` - Repo initialization helpers

**Success Criteria:**

- teach init creates ready-to-use git structure
- No manual git setup required
- Works for new and existing repos

---

## Quick Wins (< 2 hours each)

1. ⚡ **Smart commit after generation** (Phase 1)
   - Interactive: Review → Commit → Push?
   - Auto-generated commit messages
   - 80% of git friction eliminated

2. ⚡ **teach status shows git state** (Phase 3)
   - Uncommitted changes displayed
   - Offer to commit/stash
   - No more "oops I forgot to commit"

3. ⚡ **teach init with git setup** (Phase 5)
   - One command creates full structure
   - draft/main branches
   - teaching mode pre-configured

---

## Medium Effort (4-6 hours)

1. 🔧 **Branch-aware deployment** (Phase 2)
   - PR-based workflow
   - Conflict detection
   - Never push directly to production

2. 🔧 **Teaching mode** (Phase 4)
   - Streamlined auto-commit
   - Configurable per-project
   - Safety confirmations preserved

---

## Technical Design

### New Module: lib/git-helpers.zsh

```zsh
# Git helper functions for teaching workflow

# Generate commit message for teaching content
# Usage: _git_teaching_commit_message <type> <topic> <course>
_git_teaching_commit_message() {
    local type="$1"    # exam, quiz, slides, etc.
    local topic="$2"
    local course="$3"

    cat <<EOF
teach: add $type for $topic

Generated via: teach $type "$topic"
Course: $course

Co-Authored-By: Scholar <scholar@example.com>
EOF
}

# Check if current branch is clean
# Returns: 0 if clean, 1 if dirty
_git_is_clean() {
    [[ -z "$(git status --porcelain 2>/dev/null)" ]]
}

# Check if remote is up-to-date
# Returns: 0 if synced, 1 if behind/ahead
_git_is_synced() {
    git fetch --quiet
    local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    local behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    [[ $ahead -eq 0 && $behind -eq 0 ]]
}

# Get list of teaching-related files (uncommitted)
# Returns: List of files in teaching paths
_git_teaching_files() {
    local paths=("exams/" "slides/" "assignments/" "lectures/" "quizzes/")
    git status --porcelain 2>/dev/null | \
        grep -E "$(printf '%s|' "${paths[@]}" | sed 's/|$//')" | \
        awk '{print $2}'
}

# Create PR for deployment
# Usage: _git_create_deploy_pr <title> <body>
_git_create_deploy_pr() {
    local title="$1"
    local body="$2"
    gh pr create \
        --base main \
        --head draft \
        --title "$title" \
        --body "$body" \
        --label "teaching,deploy"
}
```

### Config Schema Updates

Add to `teach-config.schema.json`:

```json
{
  "git": {
    "type": "object",
    "properties": {
      "draft_branch": {
        "type": "string",
        "default": "draft",
        "description": "Branch for content development"
      },
      "production_branch": {
        "type": "string",
        "default": "main",
        "description": "Branch for site deployment"
      },
      "auto_pr": {
        "type": "boolean",
        "default": true,
        "description": "Auto-create PR on teach deploy"
      },
      "require_clean": {
        "type": "boolean",
        "default": true,
        "description": "Abort if uncommitted changes"
      }
    }
  },
  "workflow": {
    "type": "object",
    "properties": {
      "teaching_mode": {
        "type": "boolean",
        "default": false,
        "description": "Enable streamlined teaching workflow"
      },
      "auto_commit": {
        "type": "boolean",
        "default": false,
        "description": "Auto-commit after content generation"
      },
      "auto_push": {
        "type": "boolean",
        "default": false,
        "description": "Auto-push commits to remote"
      }
    }
  }
}
```

---

## Integration Points

### With Existing Commands

1. **teach exam/quiz/slides/etc:**
   - After generation: Call post-commit workflow
   - Interactive prompts for review/commit

2. **teach status:**
   - Add git status section
   - Interactive cleanup prompts

3. **teach deploy:**
   - Add pre-flight checks
   - Create PR instead of direct push

4. **teach init:**
   - Add git setup wizard
   - Configure teaching mode

5. **g dispatcher:**
   - No changes needed (orthogonal)
   - Users can still use g commands manually

### With work/finish Commands

- work command: Detect teaching projects, suggest teaching mode
- finish command: In teaching projects, suggest `teach deploy`

---

## Migration Path

### For Existing Users (v5.10.0 → v5.11.0)

1. **No breaking changes**
   - All existing teach commands work unchanged
   - Git integration is opt-in

2. **Enable teaching mode:**

   ```yaml
   # Add to teach-config.yml
   workflow:
     teaching_mode: true
   ```

3. **Configure git branches:**

   ```yaml
   # Add to teach-config.yml (optional)
   git:
     draft_branch: draft
     production_branch: main
     auto_pr: true
   ```

4. **Update deploy script:**
   - teach deploy will prompt to create PR
   - Old behavior: Push directly (still works if no git config)

---

## Success Metrics

### Quantitative

1. **Reduce git commands per content generation:** 5 → 0
   - Before: generate, review, add, commit, push (5 steps)
   - After: generate, review (2 steps, rest automated)

2. **Time to deploy:** 3 min → 30 sec
   - Before: Manual commit, manual push, manual PR
   - After: teach deploy → one PR command

3. **Forgotten commits:** 30% → 0%
   - Before: Easy to generate content and forget to commit
   - After: Interactive prompts prevent skipping

### Qualitative

1. **Flow state preserved**
   - No context switch from content creation to git
   - Interactive prompts feel natural

2. **Git novices enabled**
   - No need to learn git commands
   - teach commands handle everything

3. **Git experts happy**
   - Can override with g commands
   - Teaching mode is opt-in
   - No magic, just automation

---

## Open Questions

1. **Should teaching mode be enabled by default?**
   - Pro: Best UX for most users
   - Con: Unexpected auto-commits
   - **Recommendation:** Default off, prompt during teach init

2. **How to handle merge conflicts?**
   - If PR has conflicts, how to guide user?
   - **Recommendation:** teach deploy detects conflicts, shows instructions for rebase

3. **Should teach commands work in non-git repos?**
   - Currently: Yes (no git requirement)
   - With integration: Still yes (detect git, offer to init)
   - **Recommendation:** Git is optional enhancement, not requirement

4. **Co-authored-by tag for Scholar?**
   - Should all teach commands credit Scholar?
   - **Recommendation:** Yes, for transparency and AI credit

---

## Recommended Implementation Order

### Sprint 1 (Week 1)

1. Phase 1: Smart post-generation workflow (Quick Win)
2. Phase 3: Git-aware teach status (Quick Win)
3. Phase 5: Git integration in teach init (Quick Win)

**Why:** Quick wins demonstrate value, no breaking changes

### Sprint 2 (Week 2)

4. Phase 2: Branch-aware deployment (Medium)
5. Phase 4: Teaching mode (Medium)

**Why:** Build on foundation, add power user features

---

## Files to Create/Modify

### New Files

- `lib/git-helpers.zsh` - Git integration functions
- `tests/test-teaching-git-integration.zsh` - Test suite

### Modified Files

- `lib/dispatchers/teach-dispatcher.zsh` - Enhanced commands
- `commands/teach-init.zsh` - Git setup wizard
- `lib/config-validator.zsh` - Validate git/workflow config
- `lib/templates/teaching/teach-config.schema.json` - Add git/workflow schemas
- `docs/guides/TEACHING-GIT-WORKFLOW.md` - New guide

### Documentation Updates

- `docs/tutorials/14-teach-dispatcher.md` - Add git integration section
- `docs/reference/DISPATCHER-REFERENCE.md` - Update teach commands
- `CHANGELOG.md` - v5.11.0 features

---

## Related Work

### Inspiration from Other Tools

1. **Homebrew's git automation:**
   - Auto-commits formula changes
   - Creates PRs for version bumps
   - Lesson: Users trust automation if it's predictable

2. **Vale (prose linter):**
   - Integrates with git pre-commit hooks
   - Teaching content could have quality checks
   - Future: teach commands could run spell check

3. **Quarto publish:**
   - `quarto publish gh-pages` handles git + deployment
   - Similar to our teach deploy vision
   - Lesson: Single command for complex workflow

---

## Conclusion

Teaching + git integration is a high-leverage enhancement that:

1. **Eliminates friction** - Reduces 5 manual steps to 0
2. **Preserves control** - Interactive prompts, not silent automation
3. **Enables novices** - No git knowledge required
4. **Empowers experts** - Teaching mode is opt-in
5. **No breaking changes** - All v5.10.0 commands work unchanged

**Recommended:** Implement Phases 1, 3, 5 first (Quick Wins), then Phases 2, 4 (Power Features).

**Total Effort:** 11-16 hours across 5 phases
**Impact:** Transforms teaching workflow from manual to seamless
**Risk:** Low - git integration is optional, well-tested patterns

---

**Generated by:** Claude Code - Deep Feature Brainstorm
**Duration:** 8 expert questions + comprehensive analysis
**Next Step:** Capture as implementation spec for v5.11.0
