# Scholar Enhancement GIF Recording Guide

**Updated:** 2026-01-17
**Method:** asciinema + agg (real Claude Code sessions)

---

## Prerequisites

✅ **Installed:**
- asciinema (terminal recorder)
- agg (asciinema gif generator)
- gifsicle (GIF optimizer)

```bash
brew install asciinema agg gifsicle
```

---

## Recording Workflow

### 1. Start Recording

```bash
cd ~/projects/dev-tools/flow-cli/docs/demos/tutorials
asciinema rec scholar-01-help.cast
```

### 2. Run Commands in Claude Code

**In the recording terminal:**

```bash
# Start Claude Code
claude

# Now inside Claude Code, run Scholar commands:
teach slides --help
# Wait for output, then exit Claude Code
exit
```

### 3. Stop Recording

```bash
# Recording automatically stops when you exit
# Or press Ctrl+D
```

### 4. Convert to GIF

```bash
# Basic conversion
agg scholar-01-help.cast scholar-01-help.gif

# With customization (recommended)
agg \
  --cols 100 \
  --rows 30 \
  --font-size 16 \
  --theme dracula \
  --fps 10 \
  scholar-01-help.cast scholar-01-help.gif
```

### 5. Optimize GIF

```bash
# Optimize with gifsicle
gifsicle -O3 --colors 128 --lossy=80 \
  scholar-01-help.gif -o scholar-01-help.gif

# Check size
ls -lh scholar-01-help.gif
```

---

## Recording Scripts

### Demo 1: Help System

**File:** `scholar-01-help.cast`

```bash
asciinema rec scholar-01-help.cast

# In recording:
claude
teach slides --help
teach quiz --help
teach lecture --help
exit
```

**Convert:**
```bash
agg --cols 100 --rows 30 --font-size 16 --theme dracula --fps 10 \
  scholar-01-help.cast scholar-01-help.gif
gifsicle -O3 --colors 128 --lossy=80 \
  scholar-01-help.gif -o scholar-01-help.gif
```

---

### Demo 2: Basic Generation

**File:** `scholar-02-generate.cast`

```bash
asciinema rec scholar-02-generate.cast

# In recording:
claude
teach slides "Introduction to Statistics" --style conceptual
# Wait for output
exit
```

**Convert:**
```bash
agg --cols 100 --rows 30 --font-size 16 --theme dracula --fps 10 \
  scholar-02-generate.cast scholar-02-generate.gif
gifsicle -O3 --colors 128 --lossy=80 \
  scholar-02-generate.gif -o scholar-02-generate.gif
```

---

### Demo 3: Style Customization

**File:** `scholar-03-customize.cast`

```bash
asciinema rec scholar-03-customize.cast

# In recording:
claude
teach quiz "Hypothesis Testing" --style rigorous --technical-depth high
# Wait for output
exit
```

**Convert:**
```bash
agg --cols 100 --rows 30 --font-size 16 --theme dracula --fps 10 \
  scholar-03-customize.cast scholar-03-customize.gif
gifsicle -O3 --colors 128 --lossy=80 \
  scholar-03-customize.gif -o scholar-03-customize.gif
```

---

### Demo 4: Lesson Plans

**File:** `scholar-04-lesson.cast`

```bash
asciinema rec scholar-04-lesson.cast

# In recording:
claude
teach lecture "Regression Analysis" --lesson week3.yml
# Wait for output
exit
```

**Convert:**
```bash
agg --cols 100 --rows 30 --font-size 16 --theme dracula --fps 10 \
  scholar-04-lesson.cast scholar-04-lesson.gif
gifsicle -O3 --colors 128 --lossy=80 \
  scholar-04-lesson.gif -o scholar-04-lesson.gif
```

---

### Demo 5: Interactive Mode

**File:** `scholar-05-interactive.cast`

```bash
asciinema rec scholar-05-interactive.cast

# In recording:
claude
teach exam --interactive
# Answer prompts:
# - Topic: Statistical Inference
# - Style: applied
# - Questions: 20
# - Duration: 60
exit
```

**Convert:**
```bash
agg --cols 100 --rows 30 --font-size 16 --theme dracula --fps 10 \
  scholar-05-interactive.cast scholar-05-interactive.gif
gifsicle -O3 --colors 128 --lossy=80 \
  scholar-05-interactive.gif -o scholar-05-interactive.gif
```

---

### Demo 6: Revision Workflow

**File:** `scholar-06-revision.cast`

```bash
asciinema rec scholar-06-revision.cast

# In recording:
claude
teach slides "ANOVA" --output slides-v1.md
# Edit slides-v1.md with feedback
teach slides --revise slides-v1.md --feedback "Add more examples"
exit
```

**Convert:**
```bash
agg --cols 100 --rows 30 --font-size 16 --theme dracula --fps 10 \
  scholar-06-revision.cast scholar-06-revision.gif
gifsicle -O3 --colors 128 --lossy=80 \
  scholar-06-revision.gif -o scholar-06-revision.gif
```

---

### Demo 7: Week-Based Generation

**File:** `scholar-07-week.cast`

```bash
asciinema rec scholar-07-week.cast

# In recording:
claude
teach quiz --week 5
# Shows: Auto-detected topic from teach-config.yml
exit
```

**Convert:**
```bash
agg --cols 100 --rows 30 --font-size 16 --theme dracula --fps 10 \
  scholar-07-week.cast scholar-07-week.gif
gifsicle -O3 --colors 128 --lossy=80 \
  scholar-07-week.gif -o scholar-07-week.gif
```

---

### Demo 8: Context Integration

**File:** `scholar-08-context.cast`

```bash
asciinema rec scholar-08-context.cast

# In recording:
claude
teach assignment "Homework 3" --with-readings
# Shows: Integrated course materials
exit
```

**Convert:**
```bash
agg --cols 100 --rows 30 --font-size 16 --theme dracula --fps 10 \
  scholar-08-context.cast scholar-08-context.gif
gifsicle -O3 --colors 128 --lossy=80 \
  scholar-08-context.gif -o scholar-08-context.gif
```

---

## Batch Conversion Script

Save as `convert-all.sh`:

```bash
#!/bin/bash

# Convert all .cast files to GIFs
for cast in scholar-*.cast; do
    gif="${cast%.cast}.gif"
    echo "Converting $cast → $gif"

    # Convert with agg
    agg \
      --cols 100 \
      --rows 30 \
      --font-size 16 \
      --theme dracula \
      --fps 10 \
      "$cast" "$gif"

    # Optimize with gifsicle
    gifsicle -O3 --colors 128 --lossy=80 \
      "$gif" -o "$gif"

    # Show size
    ls -lh "$gif"
done

echo "✅ All GIFs generated"
```

**Usage:**
```bash
chmod +x convert-all.sh
./convert-all.sh
```

---

## Tips

### Terminal Size
- Use `--cols 100 --rows 30` for consistent dimensions
- Matches documentation site width

### Theme
- `dracula` theme has good contrast
- Alternatives: `monokai`, `solarized-dark`

### Frame Rate
- `--fps 10` = smooth but large files
- `--fps 5` = smaller files, slightly choppy
- `--fps 15` = very smooth but very large

### Optimization
- `--lossy=80` reduces size by ~40%
- `--colors 128` vs `--colors 256` saves ~20%
- `-O3` is maximum optimization

### File Sizes
Target: 100-500 KB per GIF
- Help screens: ~100-200 KB
- Command output: ~200-400 KB
- Interactive sessions: ~300-500 KB

---

## Quality Check

Before committing GIFs:

```bash
# Check sizes
ls -lh scholar-*.gif

# View in browser
open scholar-01-help.gif

# Verify quality
gifsicle --info scholar-01-help.gif
```

---

## Why asciinema + agg?

**Advantages over VHS:**
1. ✅ **Real output** - No simulation needed
2. ✅ **Timing preserved** - Natural command execution
3. ✅ **Easy editing** - Can edit .cast JSON file
4. ✅ **Small files** - Better compression
5. ✅ **Theme support** - Dracula, Monokai, etc.

**VHS Issues:**
- ❌ Requires simulating output (fragile)
- ❌ Timing feels artificial
- ❌ Hard to maintain (rewrite tapes for changes)

---

**Ready to record!** Start with Demo 1 (help system) and work through the list.
