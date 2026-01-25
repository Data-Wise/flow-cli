# 🧠 BRAINSTORM: Website Documentation Standardization

**Generated:** 2026-01-07
**Mode:** feature
**Depth:** deep
**Status:** Proposal

---

## 📋 Executive Summary

**Decision:** Standardize flow-cli documentation website templates and navigation to create consistent, ADHD-friendly user experience across all content types.

**Current State:**
- 21 documentation directories with mixed formats
- Template standards exist (`docs/conventions/adhd/`) but not universally applied
- Navigation structure varies by section
- No GIF/video guidelines
- Some reference cards follow template, others don't

**Goal:** Unified documentation experience with clear templates for:
1. Help documentation
2. Tutorials (step-by-step learning)
3. Live tutorials (interactive/video)
4. GIFs (visual demonstrations)
5. Reference cards (quick lookup)
6. Workflows (common patterns)

---

## 🎯 User Story

**As a flow-cli user,**
I want consistent documentation structure across all content types,
So that I can quickly find information without learning different navigation patterns for each section.

### Acceptance Criteria

✅ Every content type has a defined template
✅ Navigation menus follow consistent naming patterns
✅ GIF/video guidelines established
✅ All reference cards use standard format
✅ Tutorial structure is uniform
✅ Workflow documentation follows patterns
✅ Help pages have consistent layout

---

## 📊 Current State Analysis

### Existing Templates (Good Foundation!)

**Location:** `docs/conventions/adhd/`

1. **QUICK-START-TEMPLATE.md** ✅
   - Well-defined structure
   - 30-second setup focus
   - ADHD-friendly design

2. **REFCARD-TEMPLATE.md** ✅
   - Three format options (ASCII box, markdown table, compact grid)
   - Clear design principles (one page, scannable, no explanations)
   - Excellent examples

3. **GETTING-STARTED-TEMPLATE.md** (exists?)
4. **TUTORIAL-TEMPLATE.md** (missing)
5. **WORKFLOW-TEMPLATE.md** (missing)
6. **GIF-GUIDELINES.md** (missing)

### MkDocs Navigation Structure

**Current navigation categories:**

```yaml
nav:
  - Home: index.md
  - Getting Started: [6 items]
  - Tutorials: [11 items]
  - Guides: [7 items]
  - Reference: [multiple subsections]
  - Commands: [20 items]
  - Testing: [1 item]
  - Development: [2 items]
  - Planning: [1 item]
```

**Issues identified:**
- "Tutorials" vs "Guides" distinction unclear
- "Reference" has 4 subsections (Quick References, Dispatchers, Project Tools, Deep Dives)
- No "Workflows" section (workflows scattered in Guides)
- No "Videos/GIFs" section

### Content Type Inventory

| Type | Count | Location | Template? | Consistency |
|------|-------|----------|-----------|-------------|
| **Quick Start** | 3 | getting-started/, guides/ | ✅ Yes | 🟡 Partial |
| **Tutorials** | 11 | tutorials/ | ❌ No | 🔴 Varies |
| **Guides** | 10 | guides/ | ❌ No | 🟡 Partial |
| **Reference Cards** | 11 | reference/ | ✅ Yes | 🟢 Good |
| **Workflows** | 2 | guides/ | ❌ No | 🔴 Varies |
| **Dispatchers** | 9 | reference/ | 🟡 Partial | 🟢 Good |
| **Commands** | 20 | commands/ | ❌ No | 🟡 Partial |
| **GIFs** | 0 | — | ❌ No | — |

---

## ⚡ Quick Wins (< 30 min each)

### 1. Create Missing Templates

**Action:** Create standardized templates for content types lacking them

**Templates to create:**
- `TUTORIAL-TEMPLATE.md` - Step-by-step learning format
- `WORKFLOW-TEMPLATE.md` - Common pattern documentation
- `GIF-GUIDELINES.md` - Visual content creation standards
- `HELP-PAGE-TEMPLATE.md` - Help documentation structure

**Implementation:**

```bash
cd /Users/dt/projects/dev-tools/flow-cli/docs/conventions/adhd

# Create tutorial template
cat > TUTORIAL-TEMPLATE.md <<'EOF'
# Tutorial Template

> **Use this template** for step-by-step learning tutorials

## Structure

1. **Prerequisites** (what you need first)
2. **Learning Objectives** (what you'll accomplish)
3. **Steps** (numbered, one action per step)
4. **Checkpoints** (verify progress)
5. **Next Steps** (where to go next)

## Example

See docs/tutorials/01-first-session.md
EOF

# Create workflow template
cat > WORKFLOW-TEMPLATE.md <<'EOF'
# Workflow Template

> **Use this template** for common workflow patterns

## Structure

1. **Scenario** (when to use this)
2. **Commands** (step-by-step)
3. **Expected Output** (what success looks like)
4. **Variations** (alternative approaches)
5. **Troubleshooting** (common issues)

## Example

See docs/guides/WORKFLOWS-QUICK-WINS.md
EOF

# Create GIF guidelines
cat > GIF-GUIDELINES.md <<'EOF'
# GIF Creation Guidelines

## Purpose

GIFs demonstrate visual workflows without requiring video hosting.

## Standards

- **Duration:** 5-15 seconds max
- **Size:** ≤ 2MB (optimize with gifsicle)
- **FPS:** 10-15 (smooth but small)
- **Resolution:** 1200px width max
- **Format:** .gif (not .mp4)
- **Location:** docs/assets/gifs/

## Naming Convention

`<feature>-<action>-<variant>.gif`

Examples:
- `pick-basic-usage.gif`
- `cc-dispatcher-opus-mode.gif`
- `dash-interactive-tui.gif`

## Tools

- **Record:** QuickTime Player → Export → GIF (via script)
- **Optimize:** `gifsicle -O3 --colors 128 input.gif -o output.gif`
- **Preview:** Finder Quick Look

## Embedding

\`\`\`markdown
![Description](../assets/gifs/feature-action.gif)

*Caption: Brief description of what's shown*
\`\`\`
EOF
```

**Benefit:** Clear standards for all content types

### 2. Add "Workflows" Top-Level Section

**Action:** Create dedicated Workflows section in navigation

**Current problem:** Workflows scattered across Guides section

**Solution:**

```yaml
# mkdocs.yml
nav:
  - Home: index.md
  - Getting Started: [...]
  - Tutorials: [...]
  - Workflows:  # NEW SECTION
      - Quick Wins: guides/WORKFLOWS-QUICK-WINS.md
      - R Package Development: workflows/r-package-workflow.md
      - Git Feature Flow: workflows/git-feature-workflow.md
      - Worktree Workflow: guides/WORKTREE-WORKFLOW.md
      - YOLO Mode: guides/YOLO-MODE-WORKFLOW.md
  - Guides: [...]
  - Reference: [...]
```

**Benefit:** Clear separation between learning (tutorials/guides) and reference (workflows)

### 3. Standardize Tutorial Numbering

**Action:** Ensure all tutorials follow `01-name.md` format

**Current state:** All tutorials already numbered ✅

**Enhancement:** Add clear progression indicators

```markdown
# Tutorial 1: First Session

> **Level:** Beginner | **Time:** 5 minutes | **Next:** [Tutorial 2: Multiple Projects](02-multiple-projects.md)

[Content...]

---

**✅ Completed Tutorial 1!**
**→ Next:** [Tutorial 2: Working with Multiple Projects](02-multiple-projects.md)
```

**Benefit:** Clear learning path, easy to track progress

---

## 🔧 Medium Effort (1-2 hours each)

### 4. Create Visual Content Section

**Task:** Add dedicated section for GIFs and visual demonstrations

**Implementation Plan:**

1. **Create assets directory:**

   ```bash
   mkdir -p docs/assets/gifs
   mkdir -p docs/assets/screenshots
   ```

2. **Create visual gallery page:**

   ```markdown
   # Visual Guides

   ## Common Workflows

   ### Project Picking
   ![Pick Basic Usage](../assets/gifs/pick-basic-usage.gif)
   *Using `pick` to navigate projects*

   ### CC Dispatcher
   ![CC Unified Grammar](../assets/gifs/cc-unified-grammar.gif)
   *Both `cc opus pick` and `cc pick opus` work!*
   ```

3. **Update navigation:**

   ```yaml
   nav:
     - Visuals:
         - Gallery: visuals/gallery.md
         - GIF Guidelines: conventions/adhd/GIF-GUIDELINES.md
   ```

4. **Create first 5 GIFs:**
   - `pick-basic-usage.gif` (core feature)
   - `cc-unified-grammar.gif` (v4.8.0 feature)
   - `dash-interactive-tui.gif` (dashboard)
   - `worktree-workflow.gif` (advanced feature)
   - `win-tracking.gif` (dopamine features)

**Outcome:** Visual learning path for users who prefer seeing vs reading

### 5. Audit and Apply Templates

**Task:** Review all existing docs, apply appropriate templates

**Process:**

1. **Inventory pass:**

   ```bash
   # Find docs without template compliance
   for file in docs/**/*.md; do
       if ! grep -q "^> \*\*" "$file"; then
           echo "Missing template: $file"
       fi
   done
   ```

2. **Categorize each file:**
   - Quick Start → Apply QUICK-START-TEMPLATE.md
   - Tutorial → Apply TUTORIAL-TEMPLATE.md
   - Workflow → Apply WORKFLOW-TEMPLATE.md
   - Reference → Apply REFCARD-TEMPLATE.md
   - Guide → Apply GUIDE-TEMPLATE.md (create if needed)

3. **Update iteratively:**
   - Start with most-viewed pages (index, quick-start, tutorials)
   - Use template checklist for each update
   - Commit per-section for reviewability

**Outcome:** Consistent structure across all 80+ documentation files

### 6. Standardize Reference Card Format

**Task:** Ensure all reference cards use REFCARD-TEMPLATE.md format

**Current reference cards:**

```
ALIAS-REFERENCE-CARD.md          ✅ Good (table format)
CC-DISPATCHER-REFERENCE.md       🟡 Partial (needs consistency)
G-DISPATCHER-REFERENCE.md        🟡 Partial
MCP-DISPATCHER-REFERENCE.md      🟡 Partial
OBS-DISPATCHER-REFERENCE.md      🟡 Partial
QU-DISPATCHER-REFERENCE.md       🟡 Partial
R-DISPATCHER-REFERENCE.md        🟡 Partial
TM-DISPATCHER-REFERENCE.md       🟡 Partial
WT-DISPATCHER-REFERENCE.md       🟡 Partial
DISPATCHER-REFERENCE.md          🟢 Good (master index)
COMMAND-QUICK-REFERENCE.md       🟢 Good
WORKFLOW-QUICK-REFERENCE.md      🟢 Good
```

**Standard format to apply:**

```markdown
# [Dispatcher] Reference Card

> **Version:** X.X | **Last Updated:** YYYY-MM-DD

---

## Essential Commands

| Command | Description |
|---------|-------------|
| `dispatcher action` | Primary action |
| `dispatcher help` | Show help |

---

## [Category 1]

| Command | Description |
|---------|-------------|
| `dispatcher cmd` | What it does |

---

## Common Patterns

\`\`\`bash
# [Pattern description]
dispatcher cmd1 && dispatcher cmd2
\`\`\`

---

## Quick Tips

- Tip 1
- Tip 2
- Tip 3
```

**Outcome:** All reference cards have identical structure

---

## 🏗️ Long-term (Future Sessions)

### 7. Interactive Documentation

**Goal:** Add live, interactive examples using asciinema or similar

**Why Later:** Requires recording infrastructure setup

**Future Design:**

```markdown
# Interactive Tutorial: CC Dispatcher

<asciinema-player src="../casts/cc-dispatcher-demo.cast"></asciinema-player>

Try it yourself:
\`\`\`bash
cc pick opus
\`\`\`
```

**Blocked By:**
- Decision on recording tool (asciinema vs custom)
- Hosting for .cast files
- Player integration with MkDocs Material

### 8. Search Optimization

**Goal:** Optimize documentation for MkDocs search

**Implementation:**
- Add search keywords to frontmatter
- Create search index optimization
- Add synonyms for common searches

**Why Later:** Need to gather user search patterns first

### 9. Documentation Analytics

**Goal:** Track which pages are most viewed, least viewed

**Implementation:**
- GitHub Pages analytics integration
- Heatmap of documentation navigation
- Identify gaps in coverage

**Why Later:** Requires analytics setup and data collection period

---

## 🎯 Recommended Implementation Path

### Phase 1: Templates (This Session - 1 hour)

1. ✅ Create TUTORIAL-TEMPLATE.md
2. ✅ Create WORKFLOW-TEMPLATE.md
3. ✅ Create GIF-GUIDELINES.md
4. ✅ Create HELP-PAGE-TEMPLATE.md
5. ✅ Document template usage in conventions/adhd/README.md

### Phase 2: Navigation (This Week - 2 hours)

1. Add "Workflows" top-level section
2. Reorganize "Guides" vs "Tutorials" distinction
3. Add "Visuals" section placeholder
4. Update tutorial progression indicators
5. Deploy and test navigation changes

### Phase 3: Content Audit (Next Week - 3-4 hours)

1. Inventory all docs with template compliance check
2. Apply templates to top 10 most-viewed pages
3. Standardize all reference cards
4. Create first 5 GIFs
5. Deploy updated documentation

### Phase 4: GIF Creation (Ongoing)

1. Create GIF for each major feature (20+ total)
2. Add visual gallery page
3. Embed GIFs in relevant docs
4. Optimize all GIFs for size

---

## 📐 Template Standards Summary

| Content Type | Template | Purpose | Max Length | Key Features |
|--------------|----------|---------|------------|--------------|
| **Quick Start** | QUICK-START-TEMPLATE.md | Get running fast | 1 page | 30-second setup, common tasks |
| **Tutorial** | TUTORIAL-TEMPLATE.md | Learn step-by-step | 5-10 min read | Prerequisites, checkpoints, next steps |
| **Workflow** | WORKFLOW-TEMPLATE.md | Common patterns | 2-3 pages | Scenario, commands, variations |
| **Reference Card** | REFCARD-TEMPLATE.md | Quick lookup | 1 page | Tables, no prose, most-used first |
| **Guide** | GUIDE-TEMPLATE.md | Deep learning | 10+ pages | Conceptual, examples, best practices |
| **Help Page** | HELP-PAGE-TEMPLATE.md | Command help | 1-2 pages | Syntax, options, examples |
| **GIF** | GIF-GUIDELINES.md | Visual demo | 5-15 sec | ≤2MB, 1200px width, optimized |

---

## 🎨 Navigation Hierarchy (Proposed)

```yaml
nav:
  - Home: index.md

  - Getting Started:              # For brand new users
      - Installation
      - Quick Start (5 min)
      - Configuration
      - First Session

  - Tutorials:                    # Step-by-step learning
      - 01-07: Core workflow
      - 08-11: Advanced features
      - Progression indicators

  - Workflows:                    # Common patterns (NEW)
      - Quick Wins
      - R Package Development
      - Git Feature Flow
      - Worktree Workflow
      - YOLO Mode

  - Guides:                       # Deep dives
      - Dopamine Features
      - Project Scope
      - Monorepo Commands

  - Visuals:                      # GIFs and screenshots (NEW)
      - Gallery
      - GIF Creation Guide

  - Reference:                    # Quick lookup
      - Quick References:
          - Command Quick Reference
          - Workflow Quick Reference
          - Alias Reference Card
      - Dispatchers:
          - CC, G, R, QU, MCP, OBS, TM, WT
      - Project Tools:
          - Pick, Dash, Work, Finish
      - Deep Dives:
          - Project Detection
          - File Organization

  - Commands:                     # Individual command docs
      - [20 command pages]

  - Development:                  # For contributors
      - Contributing
      - Testing
      - Documentation Style
```

**Key Changes:**
1. **"Workflows" section** - Separate from guides
2. **"Visuals" section** - Dedicated GIF gallery
3. **Clearer hierarchy** - Getting Started → Tutorials → Workflows → Guides → Reference
4. **Progression** - Beginner → Intermediate → Advanced → Expert

---

## 🔍 Content Type Definitions

### Quick Start (Getting Started)

- **Purpose:** Get running in < 5 minutes
- **Audience:** Brand new users
- **Format:** Code-heavy, minimal prose
- **Example:** `docs/getting-started/quick-start.md`

### Tutorial (Step-by-Step Learning)

- **Purpose:** Learn one feature thoroughly
- **Audience:** Beginners learning flow-cli
- **Format:** Numbered steps, checkpoints, hands-on
- **Example:** `docs/tutorials/01-first-session.md`

### Workflow (Common Patterns)

- **Purpose:** Show how to accomplish real tasks
- **Audience:** Users who know basics, need patterns
- **Format:** Scenario → Commands → Variations
- **Example:** `docs/guides/WORKFLOWS-QUICK-WINS.md`

### Guide (Deep Dive)

- **Purpose:** Understand concepts and design
- **Audience:** Advanced users, contributors
- **Format:** Conceptual explanation + examples
- **Example:** `docs/guides/PROJECT-SCOPE.md`

### Reference Card (Quick Lookup)

- **Purpose:** Remind about syntax/options
- **Audience:** Users who already know the tool
- **Format:** Tables, no explanations, scannable
- **Example:** `docs/help/QUICK-REFERENCE.md`

### Help Page (Command Documentation)

- **Purpose:** Complete command reference
- **Audience:** All users needing command details
- **Format:** Syntax, options, examples, related commands
- **Example:** `docs/commands/*.md`

---

## 📝 Template Usage Guidelines

### When Creating New Documentation

**Decision tree:**

```
Is this for brand new users?
├─ Yes → Quick Start template
└─ No → Is this step-by-step learning?
    ├─ Yes → Tutorial template
    └─ No → Is this a common workflow?
        ├─ Yes → Workflow template
        └─ No → Is this quick lookup?
            ├─ Yes → Reference Card template
            └─ No → Guide template
```

### Template Selection Table

| User Need | Template | Location |
|-----------|----------|----------|
| "How do I install?" | Quick Start | getting-started/ |
| "Teach me feature X" | Tutorial | tutorials/ |
| "How do I do task Y?" | Workflow | workflows/ |
| "What does option Z do?" | Reference Card | reference/ |
| "Why does X work this way?" | Guide | guides/ |
| "Show me visually" | GIF | visuals/ |

---

## ⚠️ Open Questions

1. **Should "Tutorials" include videos/screencasts?**
   - Option A: Text-only tutorials, separate "Screencasts" section
   - Option B: Embed videos directly in tutorials
   - **Recommendation:** Option A (keeps tutorials accessible, videos optional)

2. **How to handle command docs vs reference cards?**
   - Option A: Merge into single reference section
   - Option B: Keep separate (commands/ detailed, reference/ quick)
   - **Recommendation:** Option B (serves different needs)

3. **Should we create a "Cookbook" section?**
   - Option A: Add "Cookbook" for recipes/snippets
   - Option B: Keep recipes in Workflows
   - **Recommendation:** Option B (avoid over-categorization)

4. **GIF hosting: docs/assets/ or external CDN?**
   - Option A: In-repo (docs/assets/gifs/)
   - Option B: External hosting (GitHub LFS, CDN)
   - **Recommendation:** Option A for now (< 10 GIFs), revisit at 20+

---

## 🔄 Migration Strategy

### Existing Content Updates

**Priority order:**

1. **High traffic pages first:**
   - index.md
   - getting-started/quick-start.md
   - guides/00-START-HERE.md
   - tutorials/01-first-session.md

2. **Reference cards:**
   - Apply REFCARD-TEMPLATE.md to all dispatcher refs
   - Ensure consistent format

3. **Tutorials:**
   - Add progression indicators
   - Add prerequisites/next-steps

4. **Workflows:**
   - Move to new Workflows section
   - Apply WORKFLOW-TEMPLATE.md

**Backward compatibility:**
- Keep old URLs working (MkDocs handles this)
- Add redirects if needed
- Update internal links

---

## 📊 Success Metrics

| Metric | Target | Measure |
|--------|--------|---------|
| Template compliance | 100% | All docs use appropriate template |
| Navigation clarity | High | User feedback: "Easy to find info" |
| Visual content | 20+ GIFs | One per major feature |
| Consistency score | > 90% | Automated template checker |
| Broken links | 0 | Link checker passes |
| Search effectiveness | > 80% | Users find info in < 3 clicks |

---

## 🎓 ADHD-Friendly Considerations

### Visual Hierarchy

- **Consistent structure** - Same layout across all docs
- **Clear headings** - Scannable, descriptive
- **Tables over prose** - Quick lookup, no reading walls of text
- **Icons and emojis** - Visual markers for sections

### Progressive Disclosure

- **Start simple** - Quick Start before Tutorials
- **Build complexity** - Tutorials before Workflows before Guides
- **Reference always available** - Quick lookup without learning

### Navigation

- **Breadcrumbs** - Always know where you are
- **Next/Previous** - Clear progression
- **Search** - Fast escape hatch
- **Quick links** - Jump to common pages

### Content Design

- **Short paragraphs** - 2-3 sentences max
- **Code examples** - Show, don't just tell
- **Visual demos** - GIFs for complex workflows
- **Checkpoints** - Verify progress frequently

---

## 🔗 Next Steps (Actionable)

### Immediate (This Session)

1. **Create missing templates:**

   ```bash
   cd /Users/dt/projects/dev-tools/flow-cli/docs/conventions/adhd
   # Create TUTORIAL-TEMPLATE.md
   # Create WORKFLOW-TEMPLATE.md
   # Create GIF-GUIDELINES.md
   # Create HELP-PAGE-TEMPLATE.md
   ```

2. **Document template usage:**

   ```bash
   # Update conventions/adhd/README.md with template selection guide
   ```

3. **Commit and document:**

   ```bash
   git add docs/conventions/adhd/
   git commit -m "docs: add missing ADHD-friendly templates

   - TUTORIAL-TEMPLATE.md for step-by-step learning
   - WORKFLOW-TEMPLATE.md for common patterns
   - GIF-GUIDELINES.md for visual content
   - HELP-PAGE-TEMPLATE.md for command docs

   Part of website standardization initiative"
   ```

### This Week

1. **Update mkdocs.yml:**
   - Add Workflows section
   - Add Visuals section
   - Reorganize navigation hierarchy

2. **Create assets directories:**

   ```bash
   mkdir -p docs/assets/gifs
   mkdir -p docs/assets/screenshots
   ```

3. **Apply templates to top 5 pages:**
   - index.md
   - getting-started/quick-start.md
   - guides/00-START-HERE.md
   - tutorials/01-first-session.md
   - help/QUICK-REFERENCE.md

### Next Week

1. **Create first 5 GIFs**
2. **Standardize all reference cards**
3. **Add visual gallery page**
4. **Deploy and test**

---

## 📚 Related Documents

1. **Templates:**
   - `docs/conventions/adhd/QUICK-START-TEMPLATE.md` ✅ Exists
   - `docs/conventions/adhd/REFCARD-TEMPLATE.md` ✅ Exists
   - `docs/conventions/adhd/TUTORIAL-TEMPLATE.md` → Create
   - `docs/conventions/adhd/WORKFLOW-TEMPLATE.md` → Create
   - `docs/conventions/adhd/GIF-GUIDELINES.md` → Create

2. **Current Documentation:**
   - `mkdocs.yml` - Navigation structure
   - `docs/guides/00-START-HERE.md` - Entry point
   - `docs/CONVENTIONS.md` - Code/doc standards

3. **Examples:**
   - `docs/tutorials/01-first-session.md` - Good tutorial structure
   - `docs/help/QUICK-REFERENCE.md` - Good reference format
   - `docs/guides/WORKFLOWS-QUICK-WINS.md` - Good workflow format

---

## 🏁 Completion Checklist

**Templates:**
- [ ] TUTORIAL-TEMPLATE.md created
- [ ] WORKFLOW-TEMPLATE.md created
- [ ] GIF-GUIDELINES.md created
- [ ] HELP-PAGE-TEMPLATE.md created
- [ ] Template usage guide added to conventions/adhd/README.md

**Navigation:**
- [ ] "Workflows" section added to mkdocs.yml
- [ ] "Visuals" section added to mkdocs.yml
- [ ] Navigation hierarchy reorganized
- [ ] Breadcrumbs verified working

**Content:**
- [ ] Top 5 pages updated with templates
- [ ] All reference cards standardized
- [ ] Tutorial progression indicators added
- [ ] First 5 GIFs created

**Validation:**
- [ ] All internal links checked (no 404s)
- [ ] Template compliance at 100%
- [ ] MkDocs builds without errors
- [ ] Navigation tested in browser

---

**✅ Ready for Implementation**
**Status:** Awaiting approval
**Estimated Effort:** Phase 1 (1 hour), Phase 2 (2 hours), Phase 3 (3-4 hours)
**Next Command:** Review and approve template creation
