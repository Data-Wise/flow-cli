# 🏛️ Prompt Storage Architecture

**Generated:** 2026-01-21
**Based on:** Brainstorm deep dive questions
**Status:** Design approved, ready for implementation

---

## 📁 Storage Locations

### Three-Tier Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Tier 1: Global (flow-cli installation)                    │
│  lib/templates/teaching/claude-prompts/                    │
│  - Shipped with flow-cli releases                          │
│  - Version controlled in flow-cli repo                     │
│  - Updated via flow-cli upgrades                           │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  Tier 2: User Home (personal customizations)               │
│  ~/.flow/prompts/                                          │
│  - Created on first use (hybrid approach)                  │
│  - User-wide customizations                                │
│  - Survives flow-cli updates                               │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  Tier 3: Course-Specific (project overrides)               │
│  .claude/prompts/*.local.md                                │
│  - Version controlled with course repo                     │
│  - Shared with TAs/co-instructors                          │
│  - Course-specific teaching style                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔍 Prompt Resolution (Precedence)

**Order:** Course → User → Global

```zsh
_resolve_prompt() {
    local prompt_name="$1"  # e.g., "lecture-notes"

    # 1. Check course-specific override
    if [[ -f ".claude/prompts/${prompt_name}.local.md" ]]; then
        echo ".claude/prompts/${prompt_name}.local.md"
        return 0
    fi

    # 2. Check user home override
    if [[ -f "$HOME/.flow/prompts/${prompt_name}.md" ]]; then
        echo "$HOME/.flow/prompts/${prompt_name}.md"
        return 0
    fi

    # 3. Fall back to global
    if [[ -f "$FLOW_ROOT/lib/templates/teaching/claude-prompts/${prompt_name}.md" ]]; then
        echo "$FLOW_ROOT/lib/templates/teaching/claude-prompts/${prompt_name}.md"
        return 0
    fi

    # 4. Prompt not found
    return 1
}
```

**Example Resolution:**

```bash
# Scenario 1: Course has customized lecture prompt
teach lecture "ANOVA"
→ Uses: .claude/prompts/lecture-notes.local.md ✅

# Scenario 2: Course uses default, but user has personal style
teach lecture "ANOVA"  (no .claude/prompts/)
→ Uses: ~/.flow/prompts/lecture-notes.md ✅

# Scenario 3: First-time user, no customizations
teach lecture "ANOVA"  (no .claude/, no ~/.flow/)
→ Uses: lib/templates/teaching/claude-prompts/lecture-notes.md ✅
```

---

## 📂 Directory Structure

### Tier 1: Global (flow-cli installation)

```
lib/templates/teaching/claude-prompts/
├── README.md                          # Usage documentation
├── CATALOG.yml                        # Prompt registry metadata
├── lecture-notes.md                   # Lecture prompt (v1.0.0)
├── revealjs-slides.md                 # Slides prompt (v1.0.0)
├── derivations-appendix.md            # Derivations prompt (v1.0.0)
├── assignment.md                      # Assignment prompt (Phase 3)
├── exam.md                            # Exam prompt (Phase 3)
├── syllabus.md                        # Syllabus prompt (Phase 3)
├── rubric.md                          # Rubric prompt (Phase 3)
├── examples/                          # Sample outputs
│   ├── sample-lecture-anova.md
│   ├── sample-slides-regression.md
│   └── sample-appendix-ems.md
├── schemas/                           # Validation schemas
│   ├── lecture-checklist.yml
│   ├── slides-checklist.yml
│   └── appendix-checklist.yml
└── catalog/                           # Built-in registry (Phase 3)
    ├── community/                     # Community-contributed
    │   ├── lecture-bayesian-stats.md
    │   ├── slides-causal-inference.md
    │   └── ...
    └── official/                      # Curated by flow-cli team
        ├── lecture-machine-learning.md
        └── ...
```

**CATALOG.yml Structure:**

```yaml
# Prompt registry metadata
version: 1.0.0
updated: 2026-01-21

prompts:
  - name: lecture-notes
    version: 1.0.0
    author: flow-cli team
    description: Comprehensive lecture notes (20-40 pages)
    category: official
    compatible_with: [5.14.0, 5.15.0]
    tags: [lecture, quarto, statistics]

  - name: revealjs-slides
    version: 1.0.0
    author: flow-cli team
    description: RevealJS presentations (25+ slides)
    category: official
    compatible_with: [5.14.0, 5.15.0]
    tags: [slides, presentation, revealjs]

  - name: lecture-bayesian-stats
    version: 1.2.0
    author: community
    description: Bayesian statistics lecture template
    category: community
    compatible_with: [5.14.0+]
    tags: [lecture, bayesian, mcmc]
    downloads: 45
    rating: 4.8
```

---

### Tier 2: User Home (~/.flow/prompts/)

```
~/.flow/
├── prompts/                           # User-wide customizations
│   ├── lecture-notes.md               # Personal lecture style
│   ├── revealjs-slides.md             # Personal slide style
│   └── custom-lab.md                  # User-created prompt
└── config.yml                         # User preferences
    ├── prompt_defaults:
    │   ├── r_packages: [emmeans, lme4, car]
    │   └── notation_style: "macros"
    └── ...
```

**Created on:** First use (hybrid approach)

```zsh
# On first teach prompt command:
if [[ ! -d "$HOME/.flow/prompts" ]]; then
    mkdir -p "$HOME/.flow/prompts"
    # Copy all global prompts to user home
    cp -r "$FLOW_ROOT/lib/templates/teaching/claude-prompts/"*.md \
          "$HOME/.flow/prompts/"
    echo "✅ Prompts initialized in ~/.flow/prompts/"
fi
```

---

### Tier 3: Course-Specific (.claude/prompts/)

```
course-project/
├── .claude/
│   ├── prompts/
│   │   ├── lecture-notes.local.md     # Course override
│   │   ├── revealjs-slides.local.md   # Course override
│   │   └── .gitkeep                   # Keep directory in git
│   ├── teaching-style.local.md        # Scholar integration
│   └── settings.local.json            # Claude Code settings
├── course.yml                         # Course config
├── lesson-plan.yml                    # Lesson plan
└── ...
```

**Version Control Strategy (User Choice: Commit to repo):**

```gitignore
# .gitignore (DO NOT ignore prompts - user wants version control)
# .claude/prompts/*.local.md  ← NOT ignored
.claude/settings.local.json   ← Ignored (personal)
```

**Rationale for version control:**
- TAs and co-instructors share same teaching style
- Consistent content across course sections
- Track evolution of teaching approach
- Reuse prompts across semesters

---

## 🔄 Initialization Workflow

### teach init (Create New Course)

**User Choice:** Copy all prompts to `.claude/prompts/`

```bash
teach init STAT-440

# Initialization steps:
1. Create directory structure
   mkdir -p .claude/prompts

2. Copy all global prompts
   cp ~/.flow/prompts/*.md .claude/prompts/
   # Rename to .local.md convention
   for f in .claude/prompts/*.md; do
       mv "$f" "${f%.md}.local.md"
   done

3. Add metadata headers
   # Add to each .local.md:
   <!--
   Customized for: STAT 440 - Regression Analysis
   Base version: 1.0.0
   Last modified: 2026-01-21
   Customizer: DT
   -->

4. Create .gitkeep (preserve directory)
   touch .claude/prompts/.gitkeep

5. Update .gitignore (DO NOT ignore .local.md)
   # User wants version control, so don't add ignore rules

6. Success message
   echo "✅ Prompts copied to .claude/prompts/"
   echo "   Customize: teach prompt customize <type>"
```

**Result:** Course has full local copy, ready to customize and share

---

## 🤝 Sharing Workflow

### Scenario: Share with TAs

**Approach:** Commit to course repo (version controlled)

```bash
# Instructor customizes prompts
teach prompt customize lecture
  → Modifies .claude/prompts/lecture-notes.local.md

# Commit changes
git add .claude/prompts/lecture-notes.local.md
git commit -m "docs: customize lecture prompt for STAT 440"
git push

# TAs pull changes
git pull
  → Automatically get customized prompts

# TA generates content
teach lecture "ANOVA"
  → Uses instructor's customized prompt ✅
```

**Benefits:**
- Zero setup for TAs (just git pull)
- Consistent teaching style across sections
- Track prompt evolution over semester
- Reuse customizations next year

---

## 📊 Metadata Tracking

### Prompt Frontmatter (All Four Metadata Fields)

```markdown
<!--
Version: 1.0.0
Last Modified: 2026-01-21
Author: flow-cli team
Customizer: DT (STAT 440)
Compatible with: flow-cli 5.14.0+, Scholar 2.x
Tags: lecture, statistics, regression
-->

# Comprehensive Lecture Notes Generator
...
```

**Metadata Fields:**

| Field | Purpose | Example |
|-------|---------|---------|
| Version | Semantic versioning | 1.0.0 (breaking.feature.patch) |
| Last Modified | Track updates | 2026-01-21 |
| Author | Original creator | flow-cli team |
| Customizer | Who modified this version | DT (STAT 440) |
| Compatible with | Version requirements | flow-cli 5.14.0+, Scholar 2.x |

**Usage:**

```bash
# Check prompt metadata
teach prompt info lecture

📋 Prompt: lecture-notes
Version: 1.0.0
Last Modified: 2026-01-21
Author: flow-cli team
Customizer: DT (STAT 440)
Compatible: flow-cli 5.14.0+, Scholar 2.x
Location: .claude/prompts/lecture-notes.local.md
Source: ~/.flow/prompts/lecture-notes.md (based on)
```

---

## 🏪 Built-in Catalog (Phase 3)

### Prompt Registry Design

**User Choice:** Built-in catalog with browse/install

```bash
teach prompt browse

📚 Available Teaching Prompts

Official (3):
  ✅ lecture-notes (v1.0.0) - Installed
  ✅ revealjs-slides (v1.0.0) - Installed
  ✅ derivations-appendix (v1.0.0) - Installed

Community (5):
  📦 lecture-bayesian-stats (v1.2.0) ⭐ 4.8 (45 downloads)
     Bayesian statistics with MCMC examples
  📦 slides-causal-inference (v1.0.0) ⭐ 4.6 (32 downloads)
     Causal diagrams and counterfactual reasoning
  📦 exam-applied-stats (v2.1.0) ⭐ 4.9 (67 downloads)
     Applied statistics exam generator
  📦 assignment-r-programming (v1.5.0) ⭐ 4.7 (53 downloads)
     R programming assignments with autograding
  📦 syllabus-online-course (v1.0.0) ⭐ 4.5 (28 downloads)
     Online course syllabus template

Commands:
  teach prompt install <name>     # Install from catalog
  teach prompt search <query>     # Search prompts
  teach prompt info <name>        # Show details
```

---

### Installation Workflow

```bash
# Install community prompt
teach prompt install lecture-bayesian-stats

📦 Installing: lecture-bayesian-stats (v1.2.0)

Source: lib/templates/teaching/claude-prompts/catalog/community/
Destination: ~/.flow/prompts/lecture-bayesian-stats.md

✅ Installed successfully!

Usage:
  teach prompt show lecture-bayesian-stats
  teach bayesian-lecture "Hierarchical Models"  # If registered as command
```

---

### Catalog Management

**Commands:**

```bash
teach prompt catalog update      # Fetch latest catalog
teach prompt catalog validate    # Check for updates
teach prompt catalog submit      # Submit community prompt (Phase 3+)
```

**Catalog Storage:**

```
lib/templates/teaching/claude-prompts/
├── CATALOG.yml                        # Metadata index
└── catalog/
    ├── official/                      # Curated by maintainers
    │   ├── lecture-machine-learning.md
    │   └── ...
    └── community/                     # User submissions
        ├── lecture-bayesian-stats.md
        └── ...
```

**Update Mechanism:**

```zsh
teach prompt catalog update

🔄 Updating prompt catalog...

Fetching: https://raw.githubusercontent.com/Data-Wise/flow-cli/main/lib/templates/teaching/claude-prompts/CATALOG.yml

✅ Catalog updated (12 prompts available)
   Official: 3 (no changes)
   Community: 9 (+2 new)

New prompts:
  📦 rubric-project-grading (v1.0.0)
  📦 slides-time-series (v1.3.0)

Run: teach prompt browse
```

---

## 🔧 Implementation Details

### Phase 1: Hybrid Storage Setup

**On flow-cli installation:**

```zsh
# In setup/install.sh or first run
_initialize_prompts() {
    # 1. Global prompts already in lib/templates/
    # (shipped with flow-cli)

    # 2. Create user home on first use
    if [[ ! -d "$HOME/.flow/prompts" ]]; then
        mkdir -p "$HOME/.flow/prompts"
        cp -r "$FLOW_ROOT/lib/templates/teaching/claude-prompts/"*.md \
              "$HOME/.flow/prompts/"
        echo "✅ User prompts initialized"
    fi
}
```

---

### teach init Integration

**Modified teach init:**

```zsh
_teach_init_prompts() {
    local course_name="$1"

    # Create .claude/prompts/
    mkdir -p .claude/prompts

    # Copy from user home (Tier 2) to course (Tier 3)
    for prompt in "$HOME/.flow/prompts/"*.md; do
        local basename=$(basename "$prompt" .md)
        cp "$prompt" ".claude/prompts/${basename}.local.md"

        # Add customization header
        {
            echo "<!--"
            echo "Customized for: $course_name"
            echo "Base version: $(grep -m1 'Version:' "$prompt" | awk '{print $2}')"
            echo "Last modified: $(date +%Y-%m-%d)"
            echo "Customizer: ${USER}"
            echo "-->"
            echo ""
            cat "$prompt"
        } > ".claude/prompts/${basename}.local.md.tmp"
        mv ".claude/prompts/${basename}.local.md.tmp" \
           ".claude/prompts/${basename}.local.md"
    done

    # Create .gitkeep
    touch .claude/prompts/.gitkeep

    echo "✅ Prompts copied to .claude/prompts/"
    echo "   Customize: teach prompt customize <type>"
}
```

---

## 📁 File Organization Summary

| Location | Purpose | Version Control | Updates |
|----------|---------|-----------------|---------|
| `lib/templates/teaching/claude-prompts/` | Global defaults (read-only) | flow-cli repo | flow-cli upgrades |
| `~/.flow/prompts/` | User customizations | Not in git | Manual edits |
| `.claude/prompts/*.local.md` | Course overrides | Course repo ✅ | Per-course edits |

---

## 🔄 Migration Path

### Existing Courses (Post-PR Merge)

**For courses created before PR #283:**

```bash
# Initialize prompts for existing course
cd ~/teaching/STAT-440
teach init --prompts-only

# Or manually:
teach prompt init

📦 Initializing prompts for existing course...

Detected: STAT 440 - Regression Analysis
Creating: .claude/prompts/

Copying 3 prompts:
  ✅ lecture-notes.local.md
  ✅ revealjs-slides.local.md
  ✅ derivations-appendix.local.md

✅ Prompts initialized!

Next steps:
  1. Customize: teach prompt customize lecture
  2. Commit: git add .claude/prompts/ && git commit
  3. Use: teach lecture "Topic"
```

---

## 🎯 Key Design Decisions

### Decision 1: Hybrid Storage (Tier 1 + Tier 2)
**Rationale:**
- Global prompts ship with flow-cli (easy distribution)
- User home copies allow personalization
- Best of both: defaults + flexibility

### Decision 2: .claude/prompts/*.local.md Convention
**Rationale:**
- Follows flow-cli pattern (.local.md for overrides)
- Explicit `.local` naming shows it's customized
- Consistent with .claude/settings.local.json

### Decision 3: Version Control Course Prompts
**Rationale:**
- TAs/co-instructors need shared teaching style
- Track evolution of course content
- Reuse across semesters

### Decision 4: Built-in Catalog (Not GitHub-only)
**Rationale:**
- `teach prompt browse` is more discoverable than external repo
- Curated catalog ensures quality
- Still allows community contributions

### Decision 5: Full Metadata Tracking
**Rationale:**
- Version (compatibility), Last Modified (freshness)
- Author (credit), Customizer (accountability)
- Compatible with (prevent breakage)

---

## 📊 Storage Footprint

**Estimate:**

| Location | Size per Prompt | Total (3 prompts) |
|----------|----------------|-------------------|
| Global (lib/) | ~5 KB | ~15 KB |
| User (~/.flow/) | ~5 KB | ~15 KB |
| Course (.claude/) | ~5 KB | ~15 KB |
| **Total per course** | | **~45 KB** |

**With 10 courses:** ~450 KB (negligible)

**Catalog (Phase 3):** +20 prompts × 5 KB = ~100 KB additional

**Total footprint:** < 1 MB (very manageable)

---

## 🚀 Implementation Checklist

### Phase 1: Hybrid Storage (20 min)

- [ ] Ensure lib/templates/ has all prompts (already done in PR #283)
- [ ] Add prompt initialization to first run
- [ ] Create `_initialize_prompts()` helper
- [ ] Test: New user → prompts in ~/.flow/ ✅

### Phase 1: teach init Integration (15 min)

- [ ] Add `_teach_init_prompts()` to teach-dispatcher
- [ ] Copy prompts to .claude/prompts/*.local.md
- [ ] Add metadata headers
- [ ] Test: teach init → prompts copied ✅

### Phase 1: Prompt Resolution (10 min)

- [ ] Implement `_resolve_prompt()` function
- [ ] Test precedence: Course → User → Global
- [ ] Add to teach-dispatcher helpers

### Phase 3: Catalog System (2-3 hours)

- [ ] Create CATALOG.yml schema
- [ ] Implement `teach prompt browse`
- [ ] Implement `teach prompt install`
- [ ] Add catalog update mechanism
- [ ] Curate initial community prompts

---

**Generated:** 2026-01-21
**Status:** ✅ Design complete, ready for Phase 1 implementation
**Next:** Integrate into BRAINSTORM.md Phase 1 tasks

