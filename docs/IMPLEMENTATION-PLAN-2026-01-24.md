# flow-cli Documentation Implementation Plan

**Date:** 2026-01-24
**Based On:** 24 user decisions across all planning documents
**Timeline:** This week (aggressive) for Phase 1
**Status:** Ready to execute

---

## Executive Summary

**Goal:** Transform flow-cli documentation from 66 scattered reference files into a cohesive, ADHD-friendly system with integrated plugin learning paths.

**Timeline:**
- **This Week:** Reference consolidation (7 master docs)
- **Weeks 2-3:** Plugin tutorials 24-31 (8 tutorials)
- **Weeks 4-6:** Update existing tutorials with plugin integration

**Total Effort:** 35-45 hours over 6 weeks

---

## User Decisions Summary (24 Total)

### Content & Structure Decisions

1. **Workflow Integration:** Collapsed inline tips (`<details>` tags)
2. **Old Files Handling:** Hybrid (archive most, deprecation notices for 5-10 key files)
3. **Plugin Tutorial Order:** Create all 8 new (24-31) before updating existing
4. **Learning Path Navigation:** Add to main navigation in mkdocs.yml
5. **Git Alias Coverage:** Top 50-80 only (not all 226)
6. **Writing Style:** Unified voice (rewrite for consistency)
7. **Dispatcher Docs:** Self-contained sections (can read independently)
8. **Plugin Depth:** What + When only (not internal How)
9. **Code Examples:** Always show command + expected output
10. **Quick Reference Format:** Web-optimized (searchable, linkable)
11. **Workflow Organization:** By use case (not by feature)
12. **Example Names:** Use real project names (flow-cli, aiterm, etc.)
13. **Stale Content:** Fix immediately during consolidation

### Automation & Tooling Decisions

1. **Feature Doc Checklist:** Checklist + automation scripts
2. **Doc Type Guide:** Yes - Create Mermaid decision tree diagram
3. **Visual Aids:** Code examples only (no GIFs)
4. **Documentation Dashboard:** Yes - Auto-generated script
5. **API Docs Generation:** Auto-generate from code
6. **API Script Timing:** After manual template (create template first)
7. **API Script Location:** In repo (scripts/generate-api-docs.sh)
8. **Dashboard Frequency:** Manual/weekly (not every commit)
9. **Doc Enforcement:** Warn only (not blocking)

### Quality & Process Decisions

1. **Update Ownership:** Code author (PRs must include doc updates)
2. **Review Checklist:** Embedded in meta-guide
3. **Tutorial Versioning:** Changelog only (no version labels)
4. **Redirects:** Break old links (no redirects, force new structure)
5. **Doc Length Limits:** Soft limits (3-4k dispatchers, 5-7k API)
6. **Common Mistakes:** Inline warnings (⚠️ where mistakes happen)

### Deployment Decisions

1. **First Master Doc:** 00-START-HERE.md (proof of concept)
2. **User Testing:** Deploy then test (real-world feedback)
3. **Announcement:** Changelog only (low-key)

---

## Phase 1: Reference Consolidation (This Week - 4.5-5.5 hours)

### Day 1: Setup + First Master Doc (2 hours)

**Morning (1 hour):**

1. **Create automation scripts (30 min):**

   ```bash
   # Create API doc generator skeleton
   touch scripts/generate-api-docs.sh
   chmod +x scripts/generate-api-docs.sh

   # Create doc dashboard generator skeleton
   touch scripts/generate-doc-dashboard.sh
   chmod +x scripts/generate-doc-dashboard.sh

   # Create feature doc checker skeleton
   touch scripts/check-doc-updates.sh
   chmod +x scripts/check-doc-updates.sh
   ```

2. **Update meta-guide with feature checklist (30 min):**
   - Add "Feature Documentation Update Checklist" section
   - Add Mermaid decision tree for doc types
   - Add automation script references

**Afternoon (1 hour):**

1. **Create docs/help/ directory structure:**

   ```bash
   mkdir -p docs/help
   ```

2. **Create first master doc: `docs/help/00-START-HERE.md` (600 lines)**

   **Content:**
   - Main documentation hub
   - 5 entry points (I'm New, Learning Path, Quick Help, Deep Dive, Plugins)
   - Popular topics
   - Visual navigation flowchart
   - Links to all doc types

   **Sources to consolidate:**
   - `reference/INDEX.md`
   - `reference/LEARNING-PATH-NAVIGATION.md`
   - `reference/FILE-REORGANIZATION-VISUAL.md`

   **Quality checks:**
   - ✅ Unified voice (ADHD-friendly, concise)
   - ✅ Fix any stale content immediately
   - ✅ Lint: `./scripts/lint-docs.sh --fix`
   - ✅ Test: `mkdocs serve`

---

### Day 2: Quick Reference + Workflows (2.5 hours)

**Morning (1.5 hours):**

1. **Create `docs/help/QUICK-REFERENCE.md` (800-1,000 lines)**

   **Content:**
   - Core commands (1 line per command)
   - All 12 dispatchers (grouped by category)
   - Top 50-80 git aliases (not all 226)
   - Keyboard shortcuts
   - Environment variables
   - Plugin commands (22 plugins - what/when only)

   **Web-optimized structure:**

   ```markdown
   # flow-cli Quick Reference

   ## Navigation
   - [Core Commands](#core-commands)
   - [Dispatchers](#dispatchers)
   - [Git Aliases](#git-aliases)
   - [Plugins](#plugins)

   ## Core Commands

   ### Session Management
   | Command | Description |
   |---------|-------------|
   | `work <project>` | Start session |
   ...

   ## Dispatchers

   ### Git (g)
   <details>
   <summary>Git Commands (Click to expand)</summary>
   ...
   </details>
   ```

   **Sources to consolidate:**
   - `COMMAND-QUICK-REFERENCE.md`
   - `ALIAS-REFERENCE-CARD.md`
   - `DASHBOARD-QUICK-REF.md`
   - All `REFCARD-*.md` files (15 files)

   **Quality checks:**
   - ✅ All examples use real projects (flow-cli, aiterm)
   - ✅ Searchable (good anchor links)
   - ✅ Fix stale content

**Afternoon (1 hour):**

1. **Create `docs/help/WORKFLOWS.md` (600-800 lines)**

   **Content - Organized by use case:**
   - Daily workflows (start day, end day)
   - Project workflows (feature dev, bug fix)
   - Git workflows (feature flow, hotfix)
   - Teaching workflows (quick start, full workflow)
   - Plugin workflows (with inline plugin tips)

   **Structure:**

   ```markdown
   # Common Workflows

   ## Quick Links

   ### Daily Workflows
   - [Start Your Day](../tutorials/01-first-session.md#daily-workflow)
   - [End Your Day](../tutorials/01-first-session.md#finish-workflow)

   ### Project Workflows

   #### Workflow: Feature Development
   **When to use:** Starting new feature

   **Steps:**
   1. Create worktree: `wt create feature/new-feature`
   2. Work in isolation
   3. Push: `g push`
   4. PR: `g pr create`
   5. Cleanup: `wt prune`

   **Real example:**
   ```bash
   # In flow-cli repo
   wt create feature/plugin-integration
   cd ~/.git-worktrees/flow-cli/feature-plugin-integration
   work plugin-integration
   # ... make changes ...
   finish "Add plugin integration"
   g push
   g pr create
   ```

   💡 **Plugin Tip:** Use `git` plugin aliases (ga, gco, gst) to speed up

   ```

   **Sources:**
   - `WORKFLOW-QUICK-REFERENCE.md`
   - `zsh/help/workflows.md`
   - `ZSH-CLEAN-WORKFLOW.md`
   - `TEACHING-GIT-WORKFLOW-REFCARD.md`

---

### Day 3: Troubleshooting + Start Dispatcher Guide (2 hours)

**Morning (1 hour):**

1. **Create `docs/help/TROUBLESHOOTING.md` (400-600 lines)**

   **Content - Organized by issue type:**
   - Installation issues
   - Command issues (command not found)
   - Git integration issues (token expiration)
   - Teaching workflow issues
   - Plugin issues (zoxide "no match found")
   - Performance issues
   - Known limitations

   **Sources:**
   - `getting-started/troubleshooting.md`
   - `getting-started/faq.md`
   - `getting-started/faq-dependencies.md`
   - Error handling sections from guides

**Afternoon (1 hour):**

1. **Start `docs/reference/MASTER-DISPATCHER-GUIDE.md`**

   **Complete today: Overview + g dispatcher (~500 lines)**

   **Structure:**

   ```markdown
   # Master Dispatcher Guide

   ## Table of Contents
   - [Overview](#overview)
   - [g - Git Workflows](#g-dispatcher)
   - [cc - Claude Code](#cc-dispatcher)
   ...

   ## Overview

   ### What Are Dispatchers?
   [Explanation]

   ### Common Patterns
   [How they work]

   ### Progressive Disclosure

   <details>
   <summary>Beginner: Essential Commands (Click to expand)</summary>

   | Dispatcher | Command | What It Does |
   |------------|---------|--------------|
   | g | g status | Show git status |
   ...

   </details>

   ---

   ## g Dispatcher

   ### Overview
   [Self-contained - can be read standalone]

   ### Quick Start (Beginners)
   ```bash
   g status          # See what's changed
   g push            # Push to remote
   g commit "msg"    # Quick commit
   ```

   **Expected output:**

   ```
   [Command + output shown]
   ```

   ⚠️ **Common Mistake:** Don't use `g commit` without message - use `g commit "message"`

   ### Common Workflows (Intermediate)

   [Workflow patterns with real examples]

   ### Complete Reference (Advanced)

   <details>
   <summary>All g Commands (Click to expand)</summary>
   [Full reference]
   </details>

   ### Related Plugins

   - git plugin (226 aliases) - see Tutorial 24
   - git-extras

   💡 **Plugin Integration:** The git plugin provides 226 aliases. Learn top 50 in Tutorial 24.

   ```

---

### Day 4: Complete Dispatcher Guide (3+ hours - LONG DAY)

**All Day:**

1. **Complete `docs/reference/MASTER-DISPATCHER-GUIDE.md` (3,000-4,000 lines total)**

   **Complete remaining 11 dispatchers:**
   - cc (Claude Code)
   - dot (Dotfiles & Secrets)
   - mcp (MCP Servers)
   - obs (Obsidian)
   - qu (Quarto)
   - r (R Packages)
   - teach (Teaching) - longest section
   - tm (Terminal Manager)
   - wt (Worktrees)
   - prompt (Prompt Engine)
   - v (Vibe Coding)

   **Each dispatcher section (~250-400 lines):**
   - Self-contained overview
   - Quick start (beginner)
   - Common workflows (intermediate)
   - Complete reference (advanced, collapsed)
   - Examples with real projects
   - Related plugins
   - Inline warnings for common mistakes

   **Sources:**
   - `DISPATCHER-REFERENCE.md`
   - `CC-DISPATCHER-REFERENCE.md`
   - `DOT-DISPATCHER-REFERENCE.md`
   - `G-DISPATCHER-REFERENCE.md`
   - `MCP-DISPATCHER-REFERENCE.md`
   - `OBS-DISPATCHER-REFERENCE.md`
   - `PROMPT-DISPATCHER-REFERENCE.md`
   - `QU-DISPATCHER-REFERENCE.md`
   - `R-DISPATCHER-REFERENCE.md`
   - `TEACH-DISPATCHER-REFERENCE-v4.6.0.md` (latest)
   - `TM-DISPATCHER-REFERENCE.md`
   - `V-DISPATCHER-REFERENCE.md`
   - `WT-DISPATCHER-REFERENCE.md`

   **Quality gates:**
   - ✅ Each section self-contained
   - ✅ Unified voice throughout
   - ✅ Real project examples (flow-cli, aiterm, rmediation)
   - ✅ Command + output for all examples
   - ✅ Soft limit ~4,000 lines (stop if approaching 5,000)

---

### Day 5: API Reference (Manual Template) + Architecture (2+ hours)

**Morning (1.5 hours):**

1. **Create manual template section for `docs/reference/MASTER-API-REFERENCE.md`**

    **Today: Core library only (~1,000 lines) as template**

    **Structure:**

    ```markdown
    # Master API Reference

    ## Table of Contents
    - [Core Libraries](#core-libraries)
    - [Teaching Libraries](#teaching-libraries)
    - [Integration Libraries](#integration-libraries)
    - [Specialized Libraries](#specialized-libraries)

    ## How to Use This Reference

    ### For Users
    [When to refer to this doc]

    ### For Developers
    [How to maintain this doc]

    ---

    ## Core Libraries

    ### lib/core.zsh

    #### Logging Functions

    ##### `_flow_log_success()`

    **Purpose:** Log success message

    **Signature:**
    ```zsh
    _flow_log_success(message)
    ```

    **Parameters:**
    - `message` (string) - Message to log

    **Returns:** 0 on success

    **Example:**

    ```bash
    _flow_log_success "Build completed"
    ```

    **Expected output:**

    ```
    ✓ Build completed
    ```

    ⚠️ **Common Mistake:** Don't forget to quote messages with spaces

    ---

    [Continue for ~20-30 key functions from core.zsh]

    ```

    **This template will guide script generation**

**Afternoon (1 hour):**

1. **Create `docs/reference/MASTER-ARCHITECTURE.md` (2,000-3,000 lines)**

    **Content:**
    - System overview (high-level Mermaid diagram)
    - Architecture principles (Pure ZSH, ADHD-friendly, Dispatcher pattern)
    - Layer architecture (flow-cli, aiterm, craft)
    - Component design (dispatchers, libraries, commands)
    - Data flow (session tracking, project detection, teaching workflow)
    - Performance optimization (caching, load guards, display layer)
    - Documentation coverage metrics
    - Testing strategy

    **Sources:**
    - `ARCHITECTURE-OVERVIEW.md`
    - `ARCHITECTURE.md`
    - `DOCUMENTATION-COVERAGE.md`
    - `CLI-COMMAND-PATTERNS-RESEARCH.md`
    - `EXISTING-SYSTEM-SUMMARY.md`
    - `REFCARD-OPTIMIZATION.md`
    - `TESTING-QUICK-REF.md`
    - `diagrams/ARCHITECTURE-DIAGRAMS.md`
    - `diagrams/LIBRARY-ARCHITECTURE.md`
    - `diagrams/TEACHING-V3-WORKFLOWS.md`

---

### Day 6: Automation Scripts (2-3 hours)

**All Day:**

1. **Create `scripts/generate-api-docs.sh` (auto-generate API reference)**

    **Functionality:**
    - Parse all `lib/*.zsh` files
    - Extract function signatures (functions starting with `_flow_`, `_teach_`, etc.)
    - Extract doc comments (if present)
    - Generate markdown in format matching manual template
    - Organize by library (core, teaching, integration, specialized)
    - Create function index (alphabetical)

    **Usage:**

    ```bash
    ./scripts/generate-api-docs.sh
    # Generates docs/reference/MASTER-API-REFERENCE.md
    # Appends to manual template from Day 5
    ```

2. **Create `scripts/generate-doc-dashboard.sh`**

    **Functionality:**
    - Count total functions in lib/*.zsh
    - Count documented functions (have entries in API reference)
    - Calculate coverage %
    - List functions by library
    - Show tutorials complete/total
    - Show guides complete/total
    - Generate markdown dashboard

    **Output:** `docs/DOC-DASHBOARD.md`

    **Run:** Manually or weekly

3. **Create `scripts/check-doc-updates.sh`**

    **Functionality:**
    - Detect changes in code (git diff)
    - Identify new commands, dispatchers, libraries
    - Suggest which docs need updating
    - Warn (not block) if docs missing

    **Integration:** Can be called manually or in PR workflow

    **Example output:**

    ```
    📝 Code changes detected. Consider updating:

    New command found: commands/feature.zsh
      → Update: docs/commands/feature.md
      → Update: help/QUICK-REFERENCE.md
      → Update: CHANGELOG.md

    New library: lib/feature-helpers.zsh
      → Update: MASTER-API-REFERENCE.md
      → Run: ./scripts/generate-api-docs.sh
    ```

---

### Day 7: Polish + Deploy (1-2 hours)

**Morning (1 hour):**

1. **Run auto-generation:**

    ```bash
    ./scripts/generate-api-docs.sh
    # Completes MASTER-API-REFERENCE.md

    ./scripts/generate-doc-dashboard.sh
    # Creates DOC-DASHBOARD.md
    ```

2. **Archive old files:**

    ```bash
    mkdir -p docs/reference/.archive

    # Archive most files
    cd docs/reference
    mv ADHD-HELPERS-FUNCTION-MAP.md .archive/
    mv ALIAS-REFERENCE-CARD.md .archive/
    # ... continue for ~50 files

    # Keep 5-10 key files with deprecation notices
    # (high-traffic files like PICK-COMMAND-REFERENCE.md)
    ```

3. **Create archive README:**

    ```markdown
    # Archived Reference Documentation

    Consolidated into master documents on 2026-01-24.

    ## Mapping
    - ALIAS-REFERENCE-CARD.md → docs/help/QUICK-REFERENCE.md
    - CC-DISPATCHER-REFERENCE.md → MASTER-DISPATCHER-GUIDE.md#cc-dispatcher
    ...
    ```

4. **Update navigation in `mkdocs.yml`:**

    ```yaml
    nav:
      - Home: index.md
      - Help:  # NEW top-level section
          - 🎯 Start Here: help/00-START-HERE.md
          - ⚡ Quick Reference: help/QUICK-REFERENCE.md
          - 📋 Common Workflows: help/WORKFLOWS.md
          - 🔧 Troubleshooting: help/TROUBLESHOOTING.md
      - Learning Paths:  # NEW top-level section
          - 🎓 Learning Path Index: tutorials/LEARNING-PATH-INDEX.md
          - 🔌 Plugin Learning Map: reference/PLUGIN-LEARNING-MAP.md
          - 🧭 Navigation Guide: reference/LEARNING-PATH-NAVIGATION.md
          - ⚡ Quick Start: getting-started/LEARNING-QUICK-START.md
      - Reference:
          - 🎛️ Master Dispatcher Guide: reference/MASTER-DISPATCHER-GUIDE.md
          - 📚 Master API Reference: reference/MASTER-API-REFERENCE.md
          - 🏗️ Master Architecture: reference/MASTER-ARCHITECTURE.md
          - 📊 Documentation Dashboard: DOC-DASHBOARD.md
          - Archived Docs: reference/.archive/README.md
    ```

**Afternoon (1 hour):**

1. **Final quality checks:**

    ```bash
    # Lint all new docs
    ./scripts/lint-docs.sh --fix
    git diff  # Review auto-fixes

    # Build locally
    mkdocs build

    # Test navigation
    mkdocs serve
    # Click through all new sections
    # Verify all links work
    # Check mobile view
    ```

2. **Update CHANGELOG.md:**

    ```markdown
    ## v5.18.0 (Unreleased)

    ### Documentation
    - **MAJOR:** Consolidated 66 reference files into 7 master documents
    - Added Learning Path System (4 new navigation docs)
    - Created automated doc generation scripts
    - Added documentation dashboard showing coverage metrics
    - Archived old reference docs with mapping file
    - Improved navigation structure (new Help + Learning Paths sections)

    ### New Documentation
    - docs/help/00-START-HERE.md - Main documentation hub
    - docs/help/QUICK-REFERENCE.md - Complete command reference
    - docs/help/WORKFLOWS.md - Common workflow patterns
    - docs/help/TROUBLESHOOTING.md - Issue resolution guide
    - docs/reference/MASTER-DISPATCHER-GUIDE.md - All 12 dispatchers
    - docs/reference/MASTER-API-REFERENCE.md - Complete API reference
    - docs/reference/MASTER-ARCHITECTURE.md - System architecture
    - docs/tutorials/LEARNING-PATH-INDEX.md - Learning curriculum hub
    - docs/reference/PLUGIN-LEARNING-MAP.md - Plugin discovery
    - docs/reference/LEARNING-PATH-NAVIGATION.md - Navigation help
    - docs/getting-started/LEARNING-QUICK-START.md - ADHD-optimized entry

    ### Scripts
    - scripts/generate-api-docs.sh - Auto-generate API docs from code
    - scripts/generate-doc-dashboard.sh - Generate coverage dashboard
    - scripts/check-doc-updates.sh - Detect missing doc updates

    ### Updated
    - Updated meta-guide with feature documentation checklist
    - Added Mermaid decision tree for document types
    - Updated PR template with documentation checklist
    ```

3. **Deploy:**

    ```bash
    # Build and deploy to GitHub Pages
    mkdocs gh-deploy --force

    # Verify live site
    open https://Data-Wise.github.io/flow-cli/
    ```

4. **Commit and push:**

    ```bash
    git add -A
    git commit -m "$(cat <<'EOF'
    docs: consolidate reference docs + add learning path system

    Major documentation overhaul:

    Reference Consolidation:
    - Consolidated 66 reference files → 7 master documents
    - Created docs/help/ with 4 core help documents
    - Archived old reference docs with mapping
    - Improved navigation structure

    Learning Path System:
    - Added 4 learning path documents (10k words)
    - Created ADHD-optimized entry points
    - Integrated plugin learning timeline
    - Added role-based learning paths

    Automation:
    - Auto-generate API docs from code
    - Auto-generate doc coverage dashboard
    - Auto-detect missing doc updates (warn-only)

    Quality:
    - Unified voice across all docs
    - Fixed stale content during consolidation
    - Real project examples throughout
    - Inline warnings for common mistakes

    Files changed: 17 new docs, 66 archived, 4 scripts
    Total new documentation: ~25,000 words

    Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
    EOF
    )"

    git push origin dev
    ```

---

## Phase 2: Plugin Tutorials (Weeks 2-3 - 12-16 hours)

### Week 2: High-Priority Tutorials (8 hours)

**Tutorial 24: Git Workflow (226 aliases)** (3 hours)
- Top 50-80 aliases organized by category
- Real examples from flow-cli repo
- Command + expected output for each
- Collapsed sections for advanced aliases
- Plugin integration tips

**Tutorial 25: Clipboard Magic** (2 hours)
- copybuffer, copypath, copyfile plugins
- Integration with Claude Code workflows
- Real examples (sharing context)

**Tutorial 26: Smart Suggestions** (2 hours)
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-you-should-use
- Error prevention for beginners

**Tutorial 27: Directory Navigation** (1 hour)
- dirhistory plugin
- zoxide integration
- Real navigation workflows

### Week 3: Remaining Tutorials (4-6 hours)

**Tutorial 28: Command Discovery** (1.5 hours)
- alias-finder
- aliases plugin
- Discovering forgotten commands

**Tutorial 29: Docker & Dev Tools** (1.5 hours)
- docker plugin
- brew plugin
- extract plugin

**Tutorial 30: History & Search** (1.5 hours)
- fzf integration
- history search
- Command recall

**Tutorial 31: Quality of Life** (1.5 hours)
- Remaining plugins
- Hidden gems
- Customization tips

---

## Phase 3: Tutorial Updates (Weeks 4-6 - 6-10 hours)

### Update Priority Order

**High Priority (Week 4 - 4 hours):**
1. Tutorial 08: Git Feature Workflow (2 hours)
   - Integrate git plugin extensively
   - Replace all raw git commands with aliases

2. Tutorial 01: First Session (1 hour)
   - Add autosuggestions/syntax highlighting
   - Beginner error prevention

3. Tutorial 10: CC Dispatcher (1 hour)
   - Clipboard integration for sharing context

**Medium Priority (Week 5 - 3 hours):**
4. Tutorial 06: Dopamine Features (1 hour)
- Alias discovery integration

1. Tutorial 02: Multiple Projects (1 hour)
   - Navigation plugins

2. Tutorial 09: Worktrees (1 hour)
   - Directory navigation plugins

**Low Priority (Week 6 - 2-3 hours):**
7. Tutorial 12: DOT Dispatcher
8. Tutorial 14: Teach Dispatcher
9. Tutorial 22: Plugin Optimization

### Update Pattern (All Updates)

```markdown
# Tutorial X: [Title]

[Existing content...]

## [At Natural Break Point]

💡 **Plugin Power-Up: [Plugin Name]**

<details>
<summary>Click to learn about [plugin] (Optional enhancement)</summary>

The [plugin] plugin makes this workflow even faster by [benefit].

**What it does:** [1 sentence]

**Try it:**
```bash
[Example command]
```

**Expected output:**

```
[Output]
```

**Learn more:** [Tutorial 24-31](link)

</details>

[Continue existing content...]

```

---

## Automation Scripts

### 1. `scripts/generate-api-docs.sh`

**Purpose:** Auto-generate API reference from ZSH code

**Algorithm:**
```bash
#!/usr/bin/env bash
# Generate API documentation from ZSH code

# 1. Find all lib/*.zsh files
# 2. Extract functions (pattern: ^function _[a-z]+_[a-z_]+)
# 3. Extract doc comments above function (## comments)
# 4. Extract signature (params, etc.)
# 5. Generate markdown
# 6. Organize by library
# 7. Create function index
# 8. Append to manual template
```

### 2. `scripts/generate-doc-dashboard.sh`

**Purpose:** Generate documentation coverage dashboard

**Output Format:**

```markdown
# Documentation Dashboard

**Last Updated:** 2026-01-24
**Auto-Generated:** Yes (weekly)

## Coverage Summary

| Metric | Count | Coverage |
|--------|-------|----------|
| Total Functions | 853 | 100% |
| Documented Functions | 421 | 49.4% |
| Tutorials Complete | 23 | 100% |
| Guides Complete | 25 | 100% |
| Reference Docs | 7 master + 12 standalone | Complete |

## Functions by Library

### Core (lib/core.zsh)
- Total: 45 functions
- Documented: 30 (66.7%)
- Missing: _flow_detect_foo, _flow_bar, ...

[Continue for all libraries...]

## Recent Changes

- 2026-01-24: Consolidated 66 reference files → 7 master docs
- 2026-01-23: Added 4 learning path documents

## Next Steps

- [ ] Document remaining 432 functions
- [ ] Create Tutorial 24-31 (plugin tutorials)
- [ ] Update Tutorial 08 with git plugin integration
```

### 3. `scripts/check-doc-updates.sh`

**Purpose:** Detect code changes and suggest doc updates

**Algorithm:**

```bash
#!/usr/bin/env bash
# Check if doc updates are needed based on code changes

# 1. Get changed files: git diff --name-only origin/main...HEAD
# 2. Categorize changes:
#    - New commands/*.zsh → Need command doc
#    - New lib/*.zsh → Need API reference update
#    - Modified dispatchers/*.zsh → Need dispatcher guide update
# 3. Generate suggestions
# 4. Warn (not block)
```

**Integration:**

```yaml
# .github/workflows/docs-check.yml (optional)
name: Documentation Check
on: [pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check docs
        run: ./scripts/check-doc-updates.sh
      - name: Comment on PR
        uses: actions/github-script@v6
        # Post suggestions as PR comment
```

---

## Quality Gates

### Before Merging Any Doc

- [ ] Linting passes: `./scripts/lint-docs.sh`
- [ ] Builds without warnings: `mkdocs build`
- [ ] All links work (manual click-through)
- [ ] Examples tested in terminal
- [ ] Expected outputs verified
- [ ] Unified voice (ADHD-friendly, concise)
- [ ] Real project examples used
- [ ] Inline warnings for common mistakes
- [ ] Soft length limits respected

### Before Deploying

- [ ] All 7 master docs complete
- [ ] All 4 learning path docs integrated
- [ ] Automation scripts working
- [ ] Old files archived with mapping
- [ ] Navigation updated in mkdocs.yml
- [ ] CHANGELOG.md updated
- [ ] Builds and deploys successfully
- [ ] Live site tested (links, mobile)

---

## Success Metrics

### Quantitative

- ✅ 66 reference files → 7 master documents (90% reduction)
- ✅ 0 → 4 learning path documents
- ✅ 0 → 3 automation scripts
- ✅ ~25,000 words of new documentation
- ✅ ~10,000 words auto-generated (API reference)
- ✅ 100% of functions documented (via automation)

### Qualitative

- ✅ Unified voice across all documentation
- ✅ ADHD-friendly design (progressive disclosure, clear hierarchy)
- ✅ Improved discoverability (5 entry points)
- ✅ Better navigation (Help + Learning Paths sections)
- ✅ Automated maintenance (scripts catch missing updates)

### User Impact

- ⏱️ Time to find command: 5 min → 30 sec (Quick Reference)
- 🎓 Time to learn basics: 2 hours → 90 min (Learning Path)
- 🔌 Plugin discovery: Hidden → Integrated naturally
- ❓ "I'm lost" scenarios: Many → Resolved (Navigation Guide)

---

## Risks & Mitigation

### Risk 1: Aggressive Timeline

**Risk:** 4.5 hours this week might not be enough

**Mitigation:**
- Start with proof of concept (00-START-HERE.md Day 1)
- If behind, prioritize help/*docs over reference/*
- Can extend to 2 weeks if needed

### Risk 2: Auto-Generated API Docs Quality

**Risk:** Generated docs might be incomplete/wrong

**Mitigation:**
- Create manual template first (Day 5)
- Script matches template format
- Manual review of generated content
- Can supplement with manual additions

### Risk 3: Breaking Old Links

**Risk:** Users with bookmarks to old docs get 404s

**Mitigation:**
- Keep 5-10 high-traffic files with deprecation notices
- Archive README has complete mapping
- Changelog clearly documents change
- Consider stub pages if complaints arise

---

## Rollback Plan

If consolidation fails:

1. **Before archiving:** Branch point to revert
2. **After archiving:** Restore files from .archive/
3. **After deploying:** Revert mkdocs.yml, restore old docs
4. **Nuclear option:** Revert entire commit

**Recommendation:** Don't rollback - iterate forward with fixes

---

## Next Steps After Phase 1

1. **Immediate (Day 8):**
   - Gather user feedback on consolidated docs
   - Fix any broken links reported
   - Adjust based on real usage

2. **Week 2-3: Plugin Tutorials**
   - Create Tutorials 24-31 (8 new tutorials)
   - Use same quality gates
   - Deploy incrementally (1-2 per day)

3. **Week 4-6: Tutorial Updates**
   - Update existing tutorials with plugin integration
   - Use collapsed inline tips pattern
   - Deploy as ready

4. **Ongoing:**
   - Run doc dashboard weekly
   - Update automation scripts as needed
   - Maintain master docs as code changes

---

## Appendix: File Mappings

### Master Docs ← Source Files

**`docs/help/00-START-HERE.md`** ←
- reference/INDEX.md
- reference/LEARNING-PATH-NAVIGATION.md
- reference/FILE-REORGANIZATION-VISUAL.md
- reference/PLUGIN-LEARNING-MAP.md
- reference/PLUGIN-TUTORIAL-MAP.md

**`docs/help/QUICK-REFERENCE.md`** ←
- COMMAND-QUICK-REFERENCE.md
- ALIAS-REFERENCE-CARD.md
- DASHBOARD-QUICK-REF.md
- zsh/help/quick-reference.md
- REFCARD-DOT.md
- REFCARD-HELP-SYSTEM.md
- REFCARD-OPTIMIZATION.md
- REFCARD-QUARTO-PHASE2.md
- REFCARD-TEACH-ANALYZE.md
- REFCARD-TEACHING-V3.md
- REFCARD-TEACHING.md
- REFCARD-TOKEN.md
- PROMPT-DISPATCHER-REFCARD.md
- TEACH-DATES-QUICK-REFERENCE.md
- TEACHING-GIT-WORKFLOW-REFCARD.md

**`docs/help/WORKFLOWS.md`** ←
- WORKFLOW-QUICK-REFERENCE.md
- zsh/help/workflows.md
- ZSH-CLEAN-WORKFLOW.md
- TEACHING-GIT-WORKFLOW-REFCARD.md

**`docs/help/TROUBLESHOOTING.md`** ←
- getting-started/troubleshooting.md
- getting-started/faq.md
- getting-started/faq-dependencies.md

**`docs/reference/MASTER-DISPATCHER-GUIDE.md`** ←
- DISPATCHER-REFERENCE.md
- CC-DISPATCHER-REFERENCE.md
- DOT-DISPATCHER-REFERENCE.md
- G-DISPATCHER-REFERENCE.md
- MCP-DISPATCHER-REFERENCE.md
- OBS-DISPATCHER-REFERENCE.md
- PROMPT-DISPATCHER-REFERENCE.md
- QU-DISPATCHER-REFERENCE.md
- R-DISPATCHER-REFERENCE.md
- TEACH-DISPATCHER-REFERENCE-v4.6.0.md
- TM-DISPATCHER-REFERENCE.md
- V-DISPATCHER-REFERENCE.md
- WT-DISPATCHER-REFERENCE.md

**`docs/reference/MASTER-API-REFERENCE.md`** ←
- API-COMPLETE.md
- API-REFERENCE.md
- CORE-API-REFERENCE.md
- TEACHING-API-REFERENCE.md
- INTEGRATION-API-REFERENCE.md
- SPECIALIZED-API-REFERENCE.md
- SCHOLAR-ENHANCEMENT-API.md
- TEACH-ANALYZE-API-REFERENCE.md
- DOCTOR-TOKEN-API-REFERENCE.md
- WT-ENHANCEMENT-API.md
- DATE-PARSER-API-REFERENCE.md
- ADHD-HELPERS-FUNCTION-MAP.md
- - Auto-generated from lib/*.zsh

**`docs/reference/MASTER-ARCHITECTURE.md`** ←
- ARCHITECTURE-OVERVIEW.md
- ARCHITECTURE.md
- DOCUMENTATION-COVERAGE.md
- CLI-COMMAND-PATTERNS-RESEARCH.md
- EXISTING-SYSTEM-SUMMARY.md
- REFCARD-OPTIMIZATION.md
- TESTING-QUICK-REF.md
- diagrams/ARCHITECTURE-DIAGRAMS.md
- diagrams/LIBRARY-ARCHITECTURE.md
- diagrams/TEACHING-V3-WORKFLOWS.md

---

**Author:** DT + Claude Sonnet 4.5
**Date:** 2026-01-24
**Status:** Ready to execute
**Timeline:** This week (aggressive)
