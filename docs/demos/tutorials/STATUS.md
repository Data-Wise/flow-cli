# Scholar Enhancement Tutorial GIFs - Status

**Last Updated:** 2026-01-17 20:20
**Method:** asciinema + agg (real Claude Code sessions)

---

## Recording Method Change

**Previous:** VHS tapes with simulated output ❌
**Current:** asciinema recordings of real Claude Code sessions ✅

**Why the change?**
- ✅ Real command output (authentic Scholar Enhancement demos)
- ✅ Natural timing (no need to simulate pauses)
- ✅ Easy to maintain (just re-record if features change)
- ✅ Better compression (smaller file sizes)

---

## Prerequisites

```bash
# Install recording tools
brew install asciinema agg gifsicle

# Verify installation
which asciinema agg gifsicle
```

---

## Current Status

### 📋 Recording Needed (8 demos)

All demos use the new asciinema workflow:

| Demo | Topic | Est. Size | Recording Time |
|------|-------|-----------|----------------|
| scholar-01-help | Help system | ~150 KB | 2 min |
| scholar-02-generate | Basic generation | ~250 KB | 3 min |
| scholar-03-customize | Style presets | ~250 KB | 3 min |
| scholar-04-lesson | Lesson plans | ~350 KB | 4 min |
| scholar-05-interactive | Interactive mode | ~400 KB | 5 min |
| scholar-06-revision | Revision workflow | ~350 KB | 4 min |
| scholar-07-week | Week-based gen | ~250 KB | 3 min |
| scholar-08-context | Context integration | ~300 KB | 4 min |

**Total Recording Time:** ~30 minutes
**Total Size (estimated):** ~2.3 MB optimized

---

## Quick Start

### Record Demo 1 (Help System)

```bash
cd ~/projects/dev-tools/flow-cli/docs/demos/tutorials

# Start recording
asciinema rec scholar-01-help.cast

# In the recording terminal:
claude
teach slides --help
teach quiz --help
teach lecture --help
exit

# Recording stops automatically
# Convert to GIF
agg \
  --cols 100 \
  --rows 30 \
  --font-size 16 \
  --theme dracula \
  --fps 10 \
  scholar-01-help.cast scholar-01-help.gif

# Optimize
gifsicle -O3 --colors 128 --lossy=80 \
  scholar-01-help.gif -o scholar-01-help.gif

# Check size
ls -lh scholar-01-help.gif
```

---

## Batch Recording Workflow

### 1. Record All Sessions

Follow the guide in `RECORDING-GUIDE.md`:

```bash
# Demo 1: Help system
asciinema rec scholar-01-help.cast
# ... run commands in Claude Code

# Demo 2: Basic generation
asciinema rec scholar-02-generate.cast
# ... run commands

# Continue for all 8 demos
```

### 2. Convert All at Once

```bash
# Use the batch conversion script
./convert-all.sh
```

The script will:
- Convert all `.cast` files to GIFs
- Apply dracula theme with optimal settings
- Optimize with gifsicle
- Show file sizes

### 3. Verify Quality

```bash
# Check sizes
ls -lh scholar-*.gif

# View in browser
open scholar-01-help.gif

# Verify all 8 exist
ls -1 scholar-*.gif | wc -l
# Should show: 8
```

---

## Recording Guidelines

### Terminal Setup

**Before recording:**
- Clear terminal: `clear`
- Set consistent size: Terminal → Window → 100x30
- Use clean shell (no custom prompt distractions)

### During Recording

**Do:**
- ✅ Wait 2-3 seconds before starting commands
- ✅ Let commands complete fully
- ✅ Pause 2 seconds after output
- ✅ Exit cleanly

**Don't:**
- ❌ Rush through commands
- ❌ Make typos (can't edit easily)
- ❌ Include sensitive information
- ❌ Show errors (unless demonstrating error handling)

### Conversion Settings

**Recommended:**
```bash
agg \
  --cols 100 \          # Consistent width
  --rows 30 \           # Consistent height
  --font-size 16 \      # Readable on docs site
  --theme dracula \     # Good contrast
  --fps 10 \            # Smooth playback
  input.cast output.gif
```

**Alternative themes:**
- `monokai` - Popular dark theme
- `solarized-dark` - Lower contrast
- `nord` - Cool blue tones

**FPS trade-offs:**
- `fps 5` - Smaller files, slightly choppy
- `fps 10` - Good balance (recommended)
- `fps 15` - Very smooth, larger files

---

## Demo Specifications

### Demo 1: Help System
**File:** `scholar-01-help.cast`

**Commands:**
```bash
teach slides --help
teach quiz --help
teach lecture --help
```

**Purpose:** Show flag discovery and usage patterns

---

### Demo 2: Basic Generation
**File:** `scholar-02-generate.cast`

**Commands:**
```bash
teach slides "Introduction to Statistics" --style conceptual
```

**Purpose:** Demonstrate basic content generation

---

### Demo 3: Style Customization
**File:** `scholar-03-customize.cast`

**Commands:**
```bash
teach quiz "Hypothesis Testing" \
  --style rigorous \
  --technical-depth high
```

**Purpose:** Show style preset customization

---

### Demo 4: Lesson Plans
**File:** `scholar-04-lesson.cast`

**Commands:**
```bash
# Assumes week3.yml exists
teach lecture "Regression Analysis" --lesson week3.yml
```

**Purpose:** YAML-driven content generation

---

### Demo 5: Interactive Mode
**File:** `scholar-05-interactive.cast`

**Commands:**
```bash
teach exam --interactive
# Answer prompts:
# Topic: Statistical Inference
# Style: applied
# Questions: 20
# Duration: 60
```

**Purpose:** Interactive wizard workflow

---

### Demo 6: Revision Workflow
**File:** `scholar-06-revision.cast`

**Commands:**
```bash
teach slides "ANOVA" --output slides-v1.md
# Edit slides-v1.md
teach slides --revise slides-v1.md \
  --feedback "Add more practical examples"
```

**Purpose:** Iterative refinement

---

### Demo 7: Week-Based Generation
**File:** `scholar-07-week.cast`

**Commands:**
```bash
teach quiz --week 5
# Shows auto-detected topic from teach-config.yml
```

**Purpose:** Config-driven automation

---

### Demo 8: Context Integration
**File:** `scholar-08-context.cast`

**Commands:**
```bash
teach assignment "Homework 3" --with-readings
# Shows integration with course materials
```

**Purpose:** Advanced context awareness

---

## Optimization Targets

### File Size Goals

| Demo | Target | Acceptable | Too Large |
|------|--------|------------|-----------|
| Help screens | < 200 KB | 200-300 KB | > 300 KB |
| Simple output | < 300 KB | 300-400 KB | > 400 KB |
| Interactive | < 500 KB | 500-600 KB | > 600 KB |

**If too large:**
1. Reduce FPS: `--fps 5` instead of `--fps 10`
2. Increase lossy compression: `--lossy=90` instead of `--lossy=80`
3. Reduce colors: `--colors 64` instead of `--colors 128`
4. Trim recording duration (remove pauses)

### Quality Checks

```bash
# Check GIF metadata
gifsicle --info scholar-01-help.gif

# Verify frame rate
# Verify color count
# Verify dimensions

# Play in terminal (optional)
gif-for-cli scholar-01-help.gif
```

---

## Integration with Tutorials

### Linking GIFs in Markdown

**Pattern:**
```markdown
![Demo: Help System](../../demos/tutorials/scholar-01-help.gif)

*Figure 1: Discovering Scholar Enhancement flags with --help*
```

**Placement:**
- After introducing a feature
- Before detailed explanation
- In "Quick Start" sections

### Tutorial Updates Needed

Once GIFs are generated, update:

- `docs/tutorials/scholar-enhancement/01-getting-started.md`
- `docs/tutorials/scholar-enhancement/02-intermediate.md`
- `docs/tutorials/scholar-enhancement/03-advanced.md`

Add `![...]()` references at appropriate points.

---

## Troubleshooting

### "command not found: teach"

**Solution:** Record in a project directory with Scholar Enhancement configured:

```bash
cd ~/projects/teaching/stat-440  # Or any teaching project
asciinema rec scholar-XX.cast
```

### GIF too large (> 500 KB)

**Solution 1:** Increase compression
```bash
gifsicle -O3 --colors 64 --lossy=90 \
  input.gif -o output.gif
```

**Solution 2:** Reduce FPS
```bash
agg --fps 5 input.cast output.gif
```

**Solution 3:** Trim duration
```bash
# Edit .cast file (it's JSON)
# Remove frames at beginning/end
```

### Poor quality after optimization

**Solution:** Reduce lossy compression
```bash
gifsicle -O3 --colors 256 --lossy=60 \
  input.gif -o output.gif
```

---

## When to Re-record

Re-record demos if:

1. ✅ **Feature changes** - Commands or output format changes
2. ✅ **Errors in demo** - Typos or incorrect steps
3. ✅ **Quality issues** - Text unreadable or poor contrast
4. ❌ **Minor tweaks** - Don't re-record for tiny changes

---

## Next Steps

### Phase 1: Record (Est. 30 min)

```bash
cd docs/demos/tutorials

# Record all 8 demos following RECORDING-GUIDE.md
asciinema rec scholar-01-help.cast
# ... continue for all 8

# Verify recordings exist
ls -1 scholar-*.cast
# Should show 8 files
```

### Phase 2: Convert (Est. 5 min)

```bash
# Batch convert
./convert-all.sh

# Verify GIFs
ls -lh scholar-*.gif
```

### Phase 3: Integrate (Est. 10 min)

```bash
# Update tutorial markdown files with GIF links
# Test in mkdocs preview
mkdocs serve

# Commit
git add scholar-*.{cast,gif}
git add docs/tutorials/scholar-enhancement/*.md
git commit -m "docs: add Scholar Enhancement tutorial GIF demos"
```

---

## References

- **Recording Guide:** `RECORDING-GUIDE.md` (complete workflow)
- **Conversion Script:** `convert-all.sh` (batch processing)
- **asciinema docs:** https://docs.asciinema.org/
- **agg docs:** https://github.com/asciinema/agg
- **gifsicle docs:** https://www.lcdf.org/gifsicle/

---

**Status:** Ready to record! Follow RECORDING-GUIDE.md to start.
