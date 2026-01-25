# Teaching + Git Workflow Quick Reference

**Version:** v5.12.0
**Format:** Printable landscape (1-page)

---

## 🎯 The 5-Phase Git Workflow

```
┌───────────────────────────────────────────────────────────┐
│  Phase 1: Generate → Phase 2: Deploy → Phase 3: Status   │
│     ↓                    ↓                  ↓             │
│  Auto-commit         Create PR         Track Changes      │
│                          ↓                                │
│  Phase 4: Teaching Mode ─┴─ Phase 5: Initialize          │
└───────────────────────────────────────────────────────────┘
```

---

## Phase 1: Smart Post-Generation

**After generating content, choose:**

| Option | Action | When to use |
|--------|--------|-------------|
| **1** | Review in editor, then commit | Want to edit before committing |
| **2** | Commit now (auto-message) | Content is ready, commit immediately |
| **3** | Skip commit | Do it manually later |

**Example:**

```bash
teach exam "Midterm 1"
# → generates exams/midterm1.qmd
# → shows 3-option menu
# → auto-commit message: "teach: add exam for Midterm 1"
```

**Commit Format:**

```
teach: <action> <type> for <topic>

Generated via: teach <command>
Course: <name> (<semester> <year>)

Co-Authored-By: Scholar <scholar@example.com>
```

---

## Phase 2: Git Deployment

**Deploy from draft → production:**

```bash
teach deploy
```

**Pre-flight checks:**
- ✓ On draft branch
- ✓ No uncommitted changes
- ✓ No unpushed commits
- ✓ No production conflicts

**Result:**
- Creates PR: `draft` → `main`
- Auto-generated PR body with commit list
- Includes deploy checklist

**Configuration:**

```yaml
git:
  draft_branch: "draft"
  production_branch: "main"
  auto_pr: true
  require_clean: true
```

---

## Phase 3: Git-Aware Status

**See uncommitted teaching files:**

```bash
teach status
# → Shows course info
# → Lists uncommitted files
# → Interactive menu
```

**Interactive Options:**
1. Commit all teaching files
2. Stash changes
3. View diff
4. Skip

**What it shows:**
- Course name and semester
- Current week
- Uncommitted `.qmd` files in `exams/`, `slides/`, etc.

---

## Phase 4: Teaching Mode

**Streamlined auto-commit workflow:**

**Enable in `.flow/teach-config.yml`:**

```yaml
workflow:
  teaching_mode: true      # Enable streamlined workflow
  auto_commit: true        # Auto-commit after generation
  auto_push: false         # Safety: never auto-push
```

**Behavior:**

```bash
teach exam "Midterm"
# ✓ Generated exams/midterm.qmd
# 🎓 Teaching Mode: Auto-committing...
# ✓ Committed: teach: add exam for Midterm
# (no menu, no prompt - instant commit)
```

**Safety:**
- ✓ Auto-commit: Yes
- ✗ Auto-push: No (must push manually)

---

## Phase 5: Git Initialization

**Initialize repository in `teach init`:**

```bash
# Full git setup
teach init "STAT 545"
# → Initializes git
# → Copies teaching.gitignore (95 lines, 18 patterns)
# → Creates draft + main branches
# → Makes initial commit
# → Offers GitHub repo creation

# Skip git setup
teach init --no-git "TEST 101"
# → Only installs config + scripts
# → Manual git setup instructions
```

**What it does:**
1. `git init` (if not exists)
2. Copy `.gitignore` template
3. Create branches (`draft`, `main`)
4. Initial commit with project structure
5. Optional: Create GitHub repo

**`.gitignore` patterns (18 rules):**
- Build artifacts (`site/`, `*.html`, `*_cache/`)
- IDE files (`.vscode/`, `.idea/`, `.Rproj.user/`)
- System files (`.DS_Store`, `Thumbs.db`)
- Secrets (`.env`, `secrets.yml`)
- Sensitive data (`grades.csv`, `roster.xlsx`)

---

## Common Workflows

### Daily Teaching Workflow

```bash
# 1. Start session
work stat-545

# 2. Check week
teach week

# 3. Create content (auto-commit prompt)
teach exam "Midterm 1"
# → Choose: review / commit / skip

# 4. Check status
teach status
# → See uncommitted files

# 5. Deploy when ready
teach deploy
# → Creates PR to production
```

### Teaching Mode Workflow (Rapid Creation)

**Setup (once):**

```bash
teach config
# → Set teaching_mode: true
```

**Daily use:**

```bash
work stat-545
teach exam "Quiz 1"     # → auto-commits
teach slides "Week 3"   # → auto-commits
teach quiz "Chapter 5"  # → auto-commits
git push                # → push all commits
teach deploy            # → create PR
```

### Fresh Course Setup

```bash
# 1. Initialize with git
teach init "STAT 545"
# → Full git setup
# → teaching.gitignore
# → draft + main branches

# 2. Configure
teach config
# → Edit course info
# → Set git preferences

# 3. Create GitHub repo (optional)
gh repo create stat-545 --public
git remote add origin https://github.com/user/stat-545.git
git push -u origin draft
git push origin main

# 4. Start creating
teach exam "Syllabus Review"
```

---

## Configuration Schema

**Complete git + workflow config:**

```yaml
# Git Settings (v5.12.0)
git:
  draft_branch: "draft"          # Development branch
  production_branch: "main"      # Deployment branch
  auto_pr: true                  # Auto-create PRs on deploy
  require_clean: true            # Block deploy if uncommitted changes

# Workflow Settings (v5.12.0)
workflow:
  teaching_mode: false           # Streamlined auto-commit workflow
  auto_commit: false             # Auto-commit after generation
  auto_push: false               # Auto-push after commit (NOT RECOMMENDED)

# Scholar Integration (v5.10.0)
scholar:
  enabled: true                  # Enable Scholar skills
  check_on_start: false          # Check Scholar CLI on teach init
```

---

## Git Helper Functions

**New module: `lib/git-helpers.zsh` (311 lines, 20+ functions)**

**Core Functions:**

| Function | Purpose |
|----------|---------|
| `_git_is_clean` | Check if working tree is clean |
| `_git_has_unpushed_commits` | Check for unpushed commits |
| `_git_current_branch` | Get current branch name |
| `_git_teaching_commit_message` | Generate commit message |
| `_git_commit_teaching_file` | Commit single teaching file |
| `_git_create_deployment_pr` | Create PR with template |
| `_git_ensure_branch` | Create branch if missing |
| `_git_switch_branch` | Switch to branch safely |

**Usage (internal):**

```bash
# Check if clean
if _git_is_clean; then
    echo "Clean working tree"
fi

# Generate commit message
msg=$(_git_teaching_commit_message "exam" "Midterm 1" "teach exam 'Midterm 1'" "STAT 545")
git commit -m "$msg"
```

---

## Troubleshooting

### "Not a git repository"

**Problem:** Running teach commands in non-git folder

**Solution:**

```bash
# Initialize git
teach init --no-git "Course Name"  # Skip git (manual setup)
# OR
git init
teach config  # Just configure
```

### "Uncommitted changes" blocking deploy

**Problem:** `teach deploy` fails due to uncommitted files

**Solutions:**

```bash
# Option 1: Commit changes
teach status  # → Choose "Commit all"

# Option 2: Stash changes
git stash

# Option 3: Disable check (not recommended)
# Edit .flow/teach-config.yml:
git:
  require_clean: false
```

### Teaching mode not auto-committing

**Problem:** `teaching_mode: true` but still showing menu

**Check config:**

```bash
teach config
# Ensure:
workflow:
  teaching_mode: true
  auto_commit: true    # Must be true!
```

### PR creation fails

**Problem:** `teach deploy` can't create PR

**Check:**
1. `gh` CLI installed: `gh --version`
2. Authenticated: `gh auth status`
3. Remote exists: `git remote -v`

**Fix:**

```bash
# Install gh
brew install gh

# Login
gh auth login

# Add remote if missing
gh repo create stat-545 --public
git remote add origin https://github.com/user/stat-545.git
```

---

## Testing

**Test suites for git integration:**

```bash
# Phase 4 (Teaching Mode)
./tests/test-teaching-mode.zsh
# → 5 tests (100% passing)

# Phase 5 (Git Init)
./tests/test-teach-init-git.zsh
# → 7 tests (100% passing)

# Full workflow
./tests/integration-test-suite.zsh
# → Comprehensive integration tests
```

---

## See Also

- **Full Guide:** `docs/commands/teach.md`
- **Dispatcher Reference:** `docs/reference/MASTER-DISPATCHER-GUIDE.md`
- **Schema:** `lib/templates/teaching/teach-config.schema.json`
- **Git Helpers Source:** `lib/git-helpers.zsh`
- **Tests:** `tests/test-teaching-mode.zsh`, `tests/test-teach-init-git.zsh`

---

**Last Updated:** 2026-01-17 (v5.12.0)
