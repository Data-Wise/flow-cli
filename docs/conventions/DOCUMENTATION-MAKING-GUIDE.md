# Documentation Making Guide

> **Comprehensive guide for creating and standardizing ADHD-friendly documentation**

**Created:** 2026-01-07
**Version:** 1.0.0
**Status:** ✅ Production - Based on Phase 3 implementation

---

## Table of Contents

1. [Overview](#overview)
2. [Documentation Philosophy](#documentation-philosophy)
3. [Templates Reference](#templates-reference)
4. [Standardization Process](#standardization-process)
5. [Quality Standards](#quality-standards)
6. [Implementation Workflow](#implementation-workflow)
7. [Tools & Commands](#tools--commands)
8. [Examples](#examples)
9. [Troubleshooting](#troubleshooting)

---

## Overview

This guide documents the complete process for creating and standardizing documentation in the flow-cli project. It's based on the successful Phase 3 implementation that achieved 100% command documentation standardization.

### What This Guide Covers

- **ADHD-friendly design principles** - Progressive disclosure, visual hierarchy
- **Template application** - How to use the 6 standard templates
- **Standardization workflow** - Step-by-step process for updating existing docs
- **Quality assurance** - Checklists and validation steps
- **Batch processing** - Efficient approach to large-scale updates

### Who This Is For

- Contributors updating existing documentation
- Developers adding new commands or features
- Maintainers ensuring documentation consistency
- Future AI assistants working on documentation tasks

---

## Documentation Philosophy

### ADHD-Friendly Design Principles

All flow-cli documentation follows these core principles:

#### 1. Progressive Disclosure

**Don't overwhelm with details upfront.**

```markdown
✅ Good: Show what, then explain how
# command

> Brief one-line description

## Synopsis
Quick usage examples

## Description
Detailed explanation

✖️ Bad: Wall of text without structure
# command
Long paragraph explaining everything at once...
```

#### 2. Visual Hierarchy

**Use structure to guide the eye.**

- Headers create clear sections
- Blockquotes for callouts
- Tables for comparisons
- Code blocks for examples
- Emojis for status indicators (✅ ❌ 🎯 ⚡)

#### 3. Scannable Content

**Readers should find info without reading everything.**

- Synopsis sections with quick examples
- Tables of contents for long pages
- Consistent structure across similar pages
- Template markers that describe purpose
- Standard footers with version info

#### 4. Practical Examples First

**Show don't tell.**

```markdown
✅ Good: Example then explanation
```bash
# Quick example
flow work my-project
```

This starts a work session on `my-project`.

✖️ Bad: Theory then maybe example
The work command initializes a session context...
(3 paragraphs later) Here's an example maybe.
```

#### 5. Consistent Patterns

**Same types of content look the same.**

- All command docs have same structure
- All reference cards follow same format
- All tutorials have progression indicators
- All guides use same section headers

---

## Templates Reference

### Available Templates

Located in `docs/conventions/adhd/`:

1. **HELP-PAGE-TEMPLATE.md** - Command documentation
2. **REFCARD-TEMPLATE.md** - Quick reference cards
3. **QUICK-START-TEMPLATE.md** - Getting started guides
4. **TUTORIAL-TEMPLATE.md** - Step-by-step tutorials
5. **WORKFLOW-TEMPLATE.md** - Workflow guides
6. **GETTING-STARTED-TEMPLATE.md** - Installation/setup

### Template Selection Guide

| Content Type | Template | Example |
|-------------|----------|---------|
| Command docs | HELP-PAGE-TEMPLATE | `docs/commands/work.md` |
| Dispatcher reference | REFCARD-TEMPLATE | `docs/reference/CC-DISPATCHER-REFERENCE.md` |
| Quick reference | REFCARD-TEMPLATE | `docs/reference/ALIAS-REFERENCE-CARD.md` |
| Getting started | QUICK-START-TEMPLATE | `docs/getting-started/quick-start.md` |
| Step-by-step guide | TUTORIAL-TEMPLATE | `docs/tutorials/01-first-session.md` |
| Workflow pattern | WORKFLOW-TEMPLATE | `docs/guides/WORKFLOWS-QUICK-WINS.md` |

### Core Template Elements

Every template includes:

#### 1. Template Marker (Blockquote)

```markdown
> Brief description of what this document provides
```

**Purpose:** Immediate context for what reader will learn
**Location:** Top of document after title
**Length:** One sentence, under 15 words
**Style:** Clear, action-oriented, specific

**Examples:**
```markdown
✅ Good markers
> Interactive project picker with FZF interface for quick navigation
> Smart git dispatcher with feature branch workflow support
> Complete reference for all flow-cli commands and aliases

✖️ Bad markers
> This document describes the work command
> Information about commands
> Read this to learn about flow-cli
```

#### 2. Synopsis Section (Commands)

```markdown
## Synopsis

```bash
command [OPTIONS] [ARGUMENTS]
```

**Quick examples:**
```bash
# Most common usage
command arg

# With options
command --option arg
```
```

**Purpose:** Show usage before explaining
**Location:** After description, before detailed content
**Contents:**
- Command syntax with placeholders
- 2-3 most common usage patterns
- No explanations (that's for later)

#### 3. Standard Footer

```markdown
---

**Last Updated:** YYYY-MM-DD
**Command Version:** vX.Y.Z (component vA.B.C)
**Status:** ✅ Production ready with [key features]
```

**Purpose:** Version tracking and status indication
**Location:** End of document
**Format:**
- **Last Updated:** Date of last content change
- **Command Version:** Plugin version (component version if different)
- **Status:** Production status with 1-3 key feature highlights

**Status Format:**
```markdown
✅ Production ready with [feature1, feature2, feature3]
🚧 Beta - [known limitations]
📝 Draft - [completion status]
```

#### 4. See Also Section

```markdown
## See Also

- **Command:** [Related Command](../commands/related.md) - Why it's related
- **Tutorial:** [Tutorial Name](../tutorials/01-name.md) - What it teaches
- **Reference:** [Reference Name](../reference/NAME.md) - What it documents
```

**Purpose:** Improve discoverability and cross-referencing
**Location:** Before footer
**Format:** Category prefix, link, brief context

---

## Standardization Process

### Phase 3 Proven Workflow

This workflow standardized 32 files (100% of commands) in 4.5 hours across 3 sessions.

### Step 1: Inventory & Planning (30 min)

**Create audit document:**

```bash
# Create planning document
touch docs/planning/CONTENT-AUDIT.md
```

**Document structure:**
```markdown
# Content Audit

## Inventory
- Total files: X
- By category: commands (X), guides (X), reference (X)

## Current Status
| File | Template Marker | Synopsis | Footer | Status | Priority |
|------|----------------|----------|--------|--------|----------|
| cmd.md | ❌ | ❌ | ❌ | ❌ | High |

## Prioritization
1. High-traffic pages first
2. Commands second
3. Guides/tutorials last

## Batch Plan
- Batch 1: 4-5 high-priority files
- Batch 2: 4-9 similar files
- Batch 3: Remaining files
```

**Identify priorities:**
1. Most-viewed pages (index, quick-start, top commands)
2. Complete categories (all commands, all dispatchers)
3. Lower-traffic content

### Step 2: Batch Planning (15 min)

**Optimal batch sizes:**
- Small batch (4-5 files): High-priority or complex files
- Medium batch (6-9 files): Similar files with same pattern
- Large batch (10+ files): Simple updates (e.g., footer-only)

**Batch composition:**
```markdown
✅ Good batching
- Batch 1: Core workflow commands (work, finish, hop, dash, status) - 5 files
- Batch 2: Setup commands (install, upgrade, config, doctor) - 4 files
- Batch 3: Utility commands (remaining 11) - can split into 2 batches

✖️ Bad batching
- Batch 1: Random mix of 20 different file types
- Batch 2: Just 2 files (inefficient)
- Batch 3: 30 files at once (error-prone)
```

### Step 3: Template Application (Per File)

**For each file in batch:**

1. **Read current file** - Understand existing structure
2. **Identify template** - Select appropriate template
3. **Add template marker** - Top of file after title
4. **Add/enhance synopsis** - Commands only, show usage first
5. **Update footer** - Standard format with status
6. **Enhance cross-references** - Update "See Also" section
7. **Check formatting** - Consistent with template

**Time estimates:**
- Simple (footer only): 2-3 minutes
- Medium (synopsis + footer): 5-10 minutes
- Complex (full restructure): 15-20 minutes

### Step 4: Testing (Per Batch)

**After each batch, before committing:**

```bash
# Build documentation
mkdocs build

# Check for errors
# - Build should succeed
# - Only expected warnings
# - No broken internal links

# Manual spot-check
# - Open 2-3 random files from batch
# - Verify footer format
# - Check template marker
# - Test internal links
```

**Expected warnings:**
```
✅ Acceptable warnings
- External links to other repos
- Planning docs not in nav
- Archive docs not in nav

❌ Fix immediately
- Broken internal links
- Missing files
- Build failures
- Malformed markdown
```

### Step 5: Commit & Track (Per Batch)

**Commit message format:**

```bash
git commit -m "docs: standardize [category] batch X/Y - [N files]

Brief description of changes

Files updated (N):
- file1.md - what was changed
- file2.md - what was changed

Impact:
- Template compliance: X% → Y% (+Zpp)
- [Category] now N% complete

mkdocs build: ✅ [time]s ([warnings] expected)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Track progress:**
```markdown
## Progress Tracking

| Batch | Files | Status | Commit | Compliance |
|-------|-------|--------|--------|------------|
| 1 | 5 | ✅ | abc1234 | 25% → 35% |
| 2 | 4 | ✅ | def5678 | 35% → 45% |
| 3 | 9 | 🚧 | - | - |
```

### Step 6: Deploy (After All Batches)

**Final deployment:**

```bash
# Build one more time
mkdocs build

# Deploy to GitHub Pages
mkdocs gh-deploy --force

# Verify deployment
# Check: https://Data-Wise.github.io/flow-cli/
```

---

## Quality Standards

### Checklist for Standardized Documentation

#### Template Marker
- [ ] Present at top of document after title
- [ ] Uses blockquote format (`>`)
- [ ] One sentence, under 15 words
- [ ] Clear, specific, action-oriented
- [ ] Describes what reader will learn/do

#### Synopsis Section (Commands)
- [ ] Present after description
- [ ] Shows command syntax with placeholders
- [ ] Includes 2-3 quick examples
- [ ] Examples are practical and common
- [ ] No explanations in synopsis (save for later)

#### Standard Footer
- [ ] Present at end of document
- [ ] Horizontal rule separator (`---`)
- [ ] Last Updated date (YYYY-MM-DD)
- [ ] Command Version with component version
- [ ] Status line with key features (1-3 features max)
- [ ] Emoji status indicator (✅/🚧/📝)

#### Content Quality
- [ ] Headers create logical hierarchy
- [ ] Examples before explanations
- [ ] Tables for comparisons
- [ ] Code blocks for all commands
- [ ] Consistent terminology
- [ ] Active voice preferred
- [ ] No broken internal links

#### Cross-References
- [ ] "See Also" section present
- [ ] Links include context (not just link text)
- [ ] Category prefixes (Command:, Tutorial:, etc.)
- [ ] Links to related content
- [ ] All links work (tested in mkdocs)

---

## Implementation Workflow

### For AI Assistants / Future Work

When tasked with documentation standardization:

#### Step 1: Context Gathering

```markdown
**Read these files first:**
1. docs/conventions/DOCUMENTATION-MAKING-GUIDE.md (this file)
2. docs/planning/PHASE-3-CONTENT-AUDIT.md (example audit)
3. Relevant template from docs/conventions/adhd/

**Understand:**
- What category of files (commands, guides, tutorials)
- Current state (what's missing)
- Target state (which template to apply)
```

#### Step 2: Create Audit

```markdown
**Create:** docs/planning/[TASK-NAME]-AUDIT.md

**Include:**
- File inventory by category
- Current template compliance (%)
- Priority ranking
- Batch groupings
- Time estimates
```

#### Step 3: Execute Batches

```markdown
**For each batch:**
1. Read all files in batch
2. Apply template elements
3. Test with mkdocs build
4. Commit with detailed message
5. Update audit document
6. Proceed to next batch

**Don't:**
- Process too many files at once
- Commit without testing
- Skip audit updates
```

#### Step 4: Validation

```markdown
**After all batches:**
1. Run full mkdocs build
2. Check all updated files manually (spot-check)
3. Verify compliance improved
4. Deploy to GitHub Pages
5. Update project .STATUS file
```

#### Step 5: Documentation

```markdown
**Update:**
1. Audit document with completion summary
2. .STATUS file with results
3. CHANGELOG if preparing release
4. Any relevant roadmap documents
```

---

## Tools & Commands

### Documentation Tools

**MkDocs:**
```bash
# Build locally
mkdocs build

# Serve for testing (http://127.0.0.1:8000)
mkdocs serve

# Deploy to GitHub Pages
mkdocs gh-deploy --force
```

**File Management:**
```bash
# Count files by category
ls docs/commands/*.md | wc -l
ls docs/guides/*.md | wc -l
ls docs/reference/*.md | wc -l

# Find files without template markers
for file in docs/commands/*.md; do
  grep -q "^>" "$file" || echo "$file"
done

# Find files without footers
for file in docs/commands/*.md; do
  grep -q "**Last Updated:**" "$file" || echo "$file"
done
```

**Link Checking:**
```bash
# Check for broken links (CI does this)
# See: .github/workflows/ci.yml

# Manual check
mkdocs build 2>&1 | grep -i warning
```

### Quality Scripts

**Template Compliance Check:**
```bash
#!/bin/bash
# check-compliance.sh

total=0
compliant=0

for file in docs/commands/*.md; do
  total=$((total + 1))

  has_marker=$(grep -q "^>" "$file" && echo 1 || echo 0)
  has_footer=$(grep -q "**Status:**" "$file" && echo 1 || echo 0)

  if [ $has_marker -eq 1 ] && [ $has_footer -eq 1 ]; then
    compliant=$((compliant + 1))
    echo "✅ $file"
  else
    echo "❌ $file"
  fi
done

percentage=$((compliant * 100 / total))
echo ""
echo "Compliance: $compliant/$total ($percentage%)"
```

---

## Examples

### Before & After: Command Documentation

#### Before (Non-Compliant)
```markdown
# work

Start working on a project.

## Arguments

- `project` - Project name

## Usage

```bash
work my-project
```

Last updated: 2025-12-15
```

**Problems:**
- No template marker
- No synopsis section
- Examples buried in usage section
- Footer not in standard format
- No "See Also" section
- No status information

#### After (Compliant)
```markdown
# work

> **Start a focused work session on a project with full context setup**

---

## Synopsis

```bash
work [PROJECT] [EDITOR]
```

**Quick examples:**
```bash
# Interactive project selection
work

# Start working on specific project
work my-project

# With specific editor
work my-project cursor
```

---

## Description

The `work` command is the **primary entry point** for flow-cli. It sets up your entire development context...

## Arguments

| Argument  | Description          | Default                  |
| --------- | -------------------- | ------------------------ |
| `project` | Project name or path | Interactive picker       |
| `editor`  | Editor to open       | `$EDITOR` or `code`      |

## What It Does

1. Checks for existing sessions
2. Locates project directory
3. Changes to project directory
4. Records session start
5. Displays project context
6. Opens editor

## See Also

- **Tutorial:** [First Session Tutorial](../tutorials/01-first-session.md)
- **Command:** [finish](finish.md) - End work session
- **Command:** [hop](hop.md) - Quick project switch

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0
**Status:** ✅ Production ready with session tracking and editor integration
```

**Improvements:**
- ✅ Template marker at top
- ✅ Synopsis with quick examples first
- ✅ Standard footer with status
- ✅ Enhanced cross-references
- ✅ Table for arguments
- ✅ Clear section hierarchy

### Before & After: Reference Card

#### Before
```markdown
# CC Dispatcher Reference

Commands for Claude Code integration.

## Commands

- `cc` - Launch Claude Code
- `cc pick` - Pick project
- `cc yolo` - YOLO mode
```

**Problems:**
- No template marker
- Incomplete command listings
- No examples
- No footer
- Missing usage patterns

#### After
```markdown
# CC Dispatcher Reference

> **Claude Code dispatcher with unified grammar and smart project targeting**

**Quick Reference:**

| Pattern | Description | Example |
|---------|-------------|---------|
| `cc` | Launch HERE (current dir) | `cc` |
| `cc <project>` | Jump to project → launch | `cc flow` |
| `cc pick` | Interactive picker → launch | `cc pick` |
| `cc <mode>` | Launch HERE in mode | `cc yolo` |
| `cc <mode> pick` | Pick → launch in mode | `cc opus pick` |
| `cc <project> <mode>` | Jump → launch in mode | `cc flow yolo` |

## Core Patterns

### Default (HERE)
Launch Claude Code in current directory:
```bash
cc              # Current directory, acceptEdits mode
cc .            # Explicit HERE target
cc here         # Explicit HERE target
```

### Modes

| Mode | Shortcut | Effect |
|------|----------|--------|
| `yolo` | `y` | Skip all permission prompts |
| `plan` | `p` | Start in planning mode |
| `opus` | `o` | Use Opus 4.5 model |
| `haiku` | `h` | Use Haiku 3.5 model |

[... complete reference ...]

## See Also

- **Command:** [pick](../commands/pick.md) - Project picker
- **Tutorial:** [CC Dispatcher Tutorial](../tutorials/10-cc-dispatcher.md)
- **Reference:** [DISPATCHER-REFERENCE.md](DISPATCHER-REFERENCE.md) - All dispatchers

---

**Last Updated:** 2026-01-07
**Reference Version:** v4.8.0
**Status:** ✅ Complete with unified grammar and all pattern combinations
```

---

## Troubleshooting

### Common Issues

#### Issue: MkDocs Build Fails

**Symptoms:**
```
ERROR - Error building page 'file.md': ...
```

**Diagnosis:**
```bash
# Check syntax
mkdocs build 2>&1 | grep ERROR

# Common causes:
# - Malformed markdown
# - Missing closing tags
# - Invalid YAML frontmatter
# - Broken relative links
```

**Fix:**
- Check file for markdown syntax errors
- Validate links with mkdocs serve
- Check for missing closing code blocks
- Ensure tables are properly formatted

#### Issue: Too Many Warnings

**Symptoms:**
```
INFO - Doc file contains unrecognized link...
```

**Diagnosis:**
```bash
# Count warnings
mkdocs build 2>&1 | grep -c "WARNING\|INFO.*link"

# Expected warnings (acceptable):
# - External links to other repos
# - Planning docs not in navigation
# - Archive docs not in navigation

# Unexpected warnings (fix these):
# - Broken internal links
# - Missing referenced files
```

**Fix:**
- Update broken internal links
- Move planning docs to planning/ (excluded from nav)
- Archive old docs to .archive/

#### Issue: Template Compliance Not Improving

**Symptoms:**
- Files updated but compliance % unchanged

**Diagnosis:**
```bash
# Check if files have all required elements
for file in docs/commands/*.md; do
  echo "=== $file ==="
  grep -c "^>" "$file"  # Template marker
  grep -c "**Last Updated:**" "$file"  # Footer
  grep -c "**Status:**" "$file"  # Status line
done
```

**Fix:**
- Ensure ALL required elements present:
  1. Template marker (blockquote)
  2. Last Updated line
  3. Command Version line
  4. Status line
- Recalculate compliance after fixes

#### Issue: Batch Takes Too Long

**Symptoms:**
- Single batch taking >2 hours
- Complex files requiring research

**Solution:**
```markdown
**Split the batch:**
- If 10 files taking too long → split into 2 batches of 5
- Group similar files together
- Do complex files separately

**Reduce scope:**
- Phase 1: Just add footers
- Phase 2: Add template markers
- Phase 3: Add synopsis sections
```

---

## Process Improvements from Phase 3

### What Worked Well

1. **Batching approach** - Groups of 4-9 files manageable
2. **Test after each batch** - Caught issues early
3. **Progressive enhancement** - Started with highest-impact files
4. **Commit frequently** - Clear history, easy rollback
5. **Template compliance tracking** - Showed progress clearly

### What to Do Differently

1. **Batch size sweet spot:** 4-9 files per batch
2. **Always test mkdocs build** between batches
3. **Update footers last** - Quick wins for motivation
4. **Keep templates accessible** - In docs/conventions/ for reference
5. **Track percentage** - Motivating to see progress

### Technical Notes

- mkdocs-exclude plugin needed for planning/ directory
- 1 expected warning (external link) is acceptable
- Footer format: Date, Version, Status with feature highlight
- Synopsis format: Command syntax + quick examples section
- Template markers use blockquote (`>`) format

---

## Prompt Template for AI Assistants

When requesting documentation standardization work, use this prompt:

```markdown
## Task: Standardize [Category] Documentation

**Context:**
- Category: [commands/guides/tutorials/reference]
- Files: [list specific files or "all files in category"]
- Current compliance: [X%]
- Target compliance: [Y%]

**Required Reading:**
1. docs/conventions/DOCUMENTATION-MAKING-GUIDE.md
2. docs/conventions/adhd/[RELEVANT-TEMPLATE].md
3. docs/planning/PHASE-3-CONTENT-AUDIT.md (reference example)

**Deliverables:**
1. Create audit document: docs/planning/[TASK-NAME]-AUDIT.md
2. Standardize files in batches (4-9 files per batch)
3. Test mkdocs build after each batch
4. Commit each batch with detailed message
5. Deploy to GitHub Pages when complete
6. Update .STATUS file with results

**Success Criteria:**
- [ ] All files have template markers
- [ ] All files have standard footers
- [ ] Commands have synopsis sections
- [ ] mkdocs build succeeds
- [ ] Template compliance improved by [X]pp
- [ ] Documentation deployed successfully

**Workflow:**
1. Read context files
2. Create audit document
3. Identify batch groupings
4. Execute batch 1 → test → commit
5. Execute batch 2 → test → commit
6. [Repeat for all batches]
7. Deploy to GitHub Pages
8. Update project .STATUS
9. Update audit with completion summary

**Quality Standards:**
- Follow ADHD-friendly design principles
- Use progressive disclosure (show usage before explanation)
- Maintain consistent structure within categories
- Include practical examples first
- Test builds between batches
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-07 | Initial guide based on Phase 3 implementation |

---

**Last Updated:** 2026-01-07
**Guide Version:** 1.0.0
**Status:** ✅ Complete - Based on successful Phase 3 (100% command standardization)

**See Also:**
- [Phase 3 Content Audit](../planning/PHASE-3-CONTENT-AUDIT.md) - Implementation example
- [Template Directory](adhd/) - All available templates
- [Project Conventions](README.md) - All project standards
