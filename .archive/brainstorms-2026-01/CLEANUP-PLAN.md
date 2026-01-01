# Flow-CLI Project Cleanup Plan

**Generated:** 2026-01-01
**Context:** Root-level organization and archive cleanup

## Overview

The flow-cli project has accumulated planning documents, proposals, and implementation summaries in the root directory. This plan reorganizes files into appropriate locations following the existing docs/ structure.

---

## Current Issues

1. **Root clutter** - 8+ planning/brainstorm files in project root
2. **Duplicate docs** - zsh/ directory contains old planning docs
3. **Completed work** - Implementation summaries still in root
4. **Mixed content** - Active docs mixed with historical artifacts

---

## File Organization Strategy

### A. Move to docs/planning/archive/ (Completed Work)

```
Root → docs/planning/archive/
├── BRAINSTORM-worktree-aware-pick-2025-12-30.md
├── BUG-FIX-git-status-math-error.md
├── OPTION-A-IMPLEMENTATION-COMPLETE.md
├── DOCUMENTATION-GENERATION-SUMMARY.md
├── PROPOSAL-dependency-management.md
├── PROPOSAL-flow-command-integration.md
└── PROPOSAL-flow-namespace.md
```

**Rationale:** These are completed proposals/implementations - valuable for history but not active docs.

### B. Move to .archive/ (Very Old Planning)

```
Root → .archive/
└── PRODUCTION-USE-PHASE.md  (2025-12-26, now superseded by v4.7.0)
```

**Rationale:** Project is well past "production use phase" planning stage.

### C. Keep in Root (Active/Reference)

```
Root (keep):
├── README.md             # Main entry point
├── CHANGELOG.md          # Active changelog
├── CLAUDE.md             # AI assistant context
├── CONTRIBUTING.md       # Contributor guide
├── LICENSE               # Legal requirement
├── TODO.md               # Active task tracking
├── IDEAS.md              # Future enhancements brainstorming
└── PROJECT-HUB.md        # Central navigation (decide: keep or archive?)
```

### D. Clean Up zsh/ Directory

```
zsh/ → docs/planning/archive/legacy-zsh/
├── ALIAS-REFERENCE-CARD.md
├── COMMAND-INTEGRATION-ANALYSIS.md
├── ENHANCEMENTS-QUICKSTART.md
├── FINAL-ADHD-FRIENDLY-COMMAND-PLAN.md
├── PHASE1-V-DISPATCHER-COMPLETE.md
├── PROJECT-HUB.md
├── PROPOSAL-ADHD-FRIENDLY-COMMANDS.md
├── SESSION-2025-12-16-SUMMARY.md
├── VERB-BRAINSTORM-COMPREHENSIVE.md
└── WORKFLOWS-QUICK-WINS.md
```

**Rationale:** These are legacy planning docs from when zsh/ was the main codebase. Now superseded by docs/ structure.

### E. Remove Files

```
Delete:
├── rename-bulk.sh                      # One-time utility, no longer needed
└── zsh-configuration.code-workspace    # Personal workspace config
```

---

## Decision Needed: PROJECT-HUB.md

**Current:** 53KB file in root, last updated 2025-12-26

**Options:**

1. **Archive it** → docs/planning/archive/PROJECT-HUB-2025-12.md
   - Pros: Cleans root, historical artifact
   - Cons: Loses central navigation

2. **Keep in root**
   - Pros: Central reference point
   - Cons: Outdated content (v4.3 era)

3. **Update and keep**
   - Pros: Useful navigation
   - Cons: Maintenance burden, duplicates CLAUDE.md

**Recommendation:** Archive it. CLAUDE.md now serves as the comprehensive project guide.

---

## Implementation Steps

### Step 1: Create Archive Directories

```bash
mkdir -p docs/planning/archive/legacy-zsh
mkdir -p docs/planning/archive/proposals
mkdir -p docs/planning/archive/implementations
```

### Step 2: Move Root Planning Files

```bash
# Completed proposals
mv PROPOSAL-*.md docs/planning/archive/proposals/

# Completed implementations
mv OPTION-A-IMPLEMENTATION-COMPLETE.md docs/planning/archive/implementations/
mv DOCUMENTATION-GENERATION-SUMMARY.md docs/planning/archive/implementations/

# Bug fixes and brainstorms
mv BRAINSTORM-*.md docs/planning/archive/
mv BUG-FIX-*.md docs/planning/archive/

# Very old planning
mv PRODUCTION-USE-PHASE.md .archive/

# Decision: Archive PROJECT-HUB
mv PROJECT-HUB.md docs/planning/archive/PROJECT-HUB-2025-12.md
```

### Step 3: Clean Up zsh/ Directory

```bash
# Move legacy planning docs
mv zsh/ALIAS-REFERENCE-CARD.md docs/planning/archive/legacy-zsh/
mv zsh/COMMAND-INTEGRATION-ANALYSIS.md docs/planning/archive/legacy-zsh/
mv zsh/ENHANCEMENTS-QUICKSTART.md docs/planning/archive/legacy-zsh/
mv zsh/FINAL-ADHD-FRIENDLY-COMMAND-PLAN.md docs/planning/archive/legacy-zsh/
mv zsh/PHASE1-V-DISPATCHER-COMPLETE.md docs/planning/archive/legacy-zsh/
mv zsh/PROJECT-HUB.md docs/planning/archive/legacy-zsh/
mv zsh/PROPOSAL-ADHD-FRIENDLY-COMMANDS.md docs/planning/archive/legacy-zsh/
mv zsh/SESSION-2025-12-16-SUMMARY.md docs/planning/archive/legacy-zsh/
mv zsh/VERB-BRAINSTORM-COMPREHENSIVE.md docs/planning/archive/legacy-zsh/
mv zsh/WORKFLOWS-QUICK-WINS.md docs/planning/archive/legacy-zsh/
```

### Step 4: Remove Unnecessary Files

```bash
rm rename-bulk.sh
rm zsh-configuration.code-workspace
```

### Step 5: Update Documentation

- Add note to docs/planning/README.md about archive organization
- Update CLAUDE.md to reflect new structure (if needed)

---

## Post-Cleanup Root Directory

```
flow-cli/
├── .archive/                 # Historical artifacts
├── .claude/                  # Claude Code settings
├── .git/                     # Git metadata
├── .github/                  # GitHub workflows
├── .husky/                   # Git hooks
├── CHANGELOG.md              # ✅ Active changelog
├── CLAUDE.md                 # ✅ AI assistant guide
├── CONTRIBUTING.md           # ✅ Contributor guide
├── Formula/                  # Homebrew formula
├── IDEAS.md                  # ✅ Future enhancements
├── LICENSE                   # ✅ Legal
├── README.md                 # ✅ Main entry
├── TODO.md                   # ✅ Active tasks
├── commands/                 # Command implementations
├── completions/              # ZSH completions
├── config/                   # Configuration
├── data/                     # Data files
├── docs/                     # Documentation (organized)
├── flow.plugin.zsh           # Plugin entry point
├── hooks/                    # ZSH hooks
├── install.sh                # Installation script
├── lib/                      # Core libraries
├── man/                      # Man pages
├── mkdocs.yml                # Docs site config
├── node_modules/             # Dependencies
├── package.json              # NPM config
├── plugins/                  # Plugin integrations
├── r-ecosystem/              # R ecosystem support
├── scripts/                  # Utility scripts
├── setup/                    # Setup files
├── site/                     # Built docs
├── templates/                # Templates
├── tests/                    # Test suite
├── tui/                      # TUI components
├── uninstall.sh              # Uninstall script
└── zsh/                      # Legacy (functions only)
```

---

## Benefits

1. **Clean root** - Only active, essential files
2. **Organized history** - Archived planning docs preserved
3. **Clear structure** - docs/planning/archive/ for historical work
4. **Easier navigation** - Less clutter, clear purpose per directory
5. **Maintained history** - All files preserved, just organized

---

## Next Steps

1. Review this plan
2. Confirm PROJECT-HUB.md decision (archive or keep)
3. Execute file moves (can be done atomically)
4. Commit with message: "chore: organize project structure, archive completed planning docs"
5. Update any broken links in documentation
