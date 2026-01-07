# GIF Creation Guidelines

> **Purpose:** Standards for creating visual demonstrations as GIFs for flow-cli documentation.

---

## Why GIFs?

**Benefits:**
- **Visual learning** — Show, don't just tell
- **Quick understanding** — 5 seconds > 5 paragraphs
- **No hosting needed** — Self-contained files
- **Accessible** — Works without video players

**Use cases:**
- Demonstrating interactive commands (`pick`, `dash -i`)
- Showing TUI interfaces
- Illustrating workflow patterns
- Highlighting new features

---

## Technical Standards

### File Specifications

| Property | Standard | Notes |
|----------|----------|-------|
| **Duration** | 5-15 seconds | Shorter is better |
| **File Size** | ≤ 2MB | Optimize with gifsicle |
| **FPS** | 10-15 | Smooth but efficient |
| **Resolution** | 1200px width max | Readable on all devices |
| **Format** | .gif | Not .mp4, .webm, etc. |
| **Colors** | ≤ 128 | Balance quality/size |

### Technical Requirements

```bash
# Minimum quality threshold
Width: 800-1200px
Height: Auto (maintain aspect ratio)
FPS: 10-15 (not 30+)
Colors: 64-128 palette
Loop: Infinite
```

---

## Naming Convention

### Format

```
<feature>-<action>-<variant>.gif
```

### Examples

**Good names:**
- `pick-basic-usage.gif`
- `cc-dispatcher-opus-mode.gif`
- `dash-interactive-tui.gif`
- `worktree-create-branch.gif`
- `win-tracking-streak.gif`

**Bad names:**
- `demo.gif` (not descriptive)
- `screen-recording-2026-01-07.gif` (includes date)
- `my-test.gif` (not professional)
- `PICK_DEMO_FINAL_V2.gif` (version in filename)

### Naming Components

| Component | Purpose | Examples |
|-----------|---------|----------|
| **Feature** | What tool/command | `pick`, `cc`, `dash`, `worktree` |
| **Action** | What it does | `usage`, `mode`, `tui`, `create` |
| **Variant** | Specific case | `opus`, `streak`, `branch` (optional) |

---

## Storage Location

### Directory Structure

```
docs/
├── assets/
│   └── gifs/
│       ├── commands/          # Command demos
│       │   ├── pick-*.gif
│       │   ├── dash-*.gif
│       │   └── work-*.gif
│       ├── dispatchers/       # Dispatcher demos
│       │   ├── cc-*.gif
│       │   ├── g-*.gif
│       │   └── r-*.gif
│       ├── features/          # Feature demos
│       │   ├── dopamine-*.gif
│       │   └── worktree-*.gif
│       └── tutorials/         # Tutorial companion GIFs
│           ├── 01-*.gif
│           └── 10-*.gif
```

### Linking in Docs

```markdown
<!-- Relative path from doc location -->
![Pick basic usage](../../assets/gifs/commands/pick-basic-usage.gif)

*Using `pick` to navigate between projects*
```

---

## Recording Workflow

### Tools

**Recommended:**
- **QuickTime Player** (Mac) — Built-in, simple
- **Kap** (Mac) — Lightweight, GIF-optimized
- **peek** (Linux) — Designed for GIFs

**Conversion:**
- **gifsicle** — Optimize existing GIFs
- **ffmpeg** — Convert video to GIF

### Recording Setup

```bash
# 1. Clean terminal environment
clear
export PS1="$ "  # Simple prompt

# 2. Set terminal size
# iTerm2: Preferences → Profiles → Window → Columns=100, Rows=30

# 3. Use readable font size
# iTerm2: Preferences → Profiles → Text → 14-16pt

# 4. Choose high-contrast theme
# Recommended: Solarized Light (better GIF compression)
```

### Recording Process

**Before recording:**
1. ✅ Practice the workflow 2-3 times
2. ✅ Clear terminal (`clear`)
3. ✅ Set simple PS1 prompt
4. ✅ Close unnecessary tabs/panes
5. ✅ Disable notifications

**During recording:**
1. **Count 2 seconds** before starting
2. **Type at normal pace** (not too fast)
3. **Pause 1 second** after important output
4. **Count 2 seconds** after completion

**After recording:**
1. Trim unnecessary frames
2. Optimize file size
3. Test on documentation page
4. Verify accessibility

---

## Optimization

### Using gifsicle

```bash
# Basic optimization (reduces file size)
gifsicle -O3 input.gif -o output.gif

# Optimize with color reduction
gifsicle -O3 --colors 128 input.gif -o output.gif

# Lossy optimization (smaller but slightly degraded)
gifsicle -O3 --lossy=80 --colors 128 input.gif -o output.gif

# Batch optimize all GIFs
for gif in docs/assets/gifs/**/*.gif; do
    gifsicle -O3 --colors 128 "$gif" -o "${gif%.gif}-optimized.gif"
done
```

### Using ffmpeg

```bash
# Convert video to GIF
ffmpeg -i input.mov -vf "fps=10,scale=1200:-1:flags=lanczos" \
  -c:v gif output.gif

# Add palette for better quality
ffmpeg -i input.mov -vf \
  "fps=10,scale=1200:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

### Optimization Targets

| Before | After | Method |
|--------|-------|--------|
| 5MB | < 2MB | Color reduction (256 → 128) |
| 3MB | < 1MB | FPS reduction (30 → 10) |
| 2MB | < 500KB | Lossy optimization |

---

## Content Guidelines

### What to Show

**Do show:**
- ✅ Complete workflows (start to finish)
- ✅ Interactive UI (fzf pickers, TUI dashboards)
- ✅ Successful outcomes
- ✅ Real project names (not fake data)
- ✅ Actual command output

**Don't show:**
- ❌ Error states (unless troubleshooting GIF)
- ❌ Personal information (API keys, paths with username)
- ❌ Incomplete workflows
- ❌ Multiple unrelated commands
- ❌ Long pauses or waiting

### Timing Guidelines

| Duration | Use For |
|----------|---------|
| **3-5 sec** | Single command demo |
| **5-10 sec** | Short workflow (2-3 commands) |
| **10-15 sec** | Complete workflow |
| **15+ sec** | Complex tutorial (split into multiple GIFs) |

**ADHD-Friendly:**
- Shorter is better
- One concept per GIF
- Loop should feel natural

---

## Accessibility

### Visual Clarity

**Terminal settings:**
- Font size: 14-16pt (readable in GIF)
- Contrast: High (Solarized Light/Dark)
- Colors: Limited palette (< 8 colors)
- Width: 80-100 columns (fits in docs)

**Recording settings:**
- No transparency effects
- No blinking cursors (distracting)
- No animations in PS1 prompt
- Clean, simple output

### Caption Requirements

Every GIF must have:

1. **Alt text** (for screen readers)
2. **Caption** (brief description)
3. **Text explanation** (in documentation)

```markdown
![Pick basic usage showing project selection](../../assets/gifs/pick-basic-usage.gif)

*Using `pick` to navigate between projects with fzf interface*

The GIF demonstrates:
1. Launching `pick` command
2. Filtering projects by typing
3. Selecting with Enter key
4. Changing directory to selected project
```

---

## GIF Types

### Demo GIF

**Purpose:** Show feature in action

**Structure:**
1. Start state (clear terminal)
2. Command execution
3. Expected output
4. End state

**Example:** `pick-basic-usage.gif`

### Tutorial GIF

**Purpose:** Accompany tutorial steps

**Structure:**
1. Step N from tutorial
2. Command from tutorial
3. Output from tutorial
4. Verification (checkpoint)

**Example:** `tutorial-01-first-session.gif`

### Feature Highlight GIF

**Purpose:** Showcase new feature

**Structure:**
1. Before state (old behavior)
2. New command/feature
3. After state (improvement)

**Example:** `cc-unified-grammar.gif` (shows both orders work)

### Comparison GIF

**Purpose:** Show differences between approaches

**Structure:**
1. Approach A
2. Split or fade transition
3. Approach B
4. Highlight difference

**Example:** `pick-vs-direct-jump.gif`

---

## Quality Checklist

Before adding GIF to documentation:

**Technical:**
- [ ] File size ≤ 2MB
- [ ] Resolution 800-1200px width
- [ ] FPS 10-15 (not 30+)
- [ ] Colors ≤ 128 palette
- [ ] Loops infinitely
- [ ] No audio track

**Content:**
- [ ] Shows complete workflow
- [ ] No sensitive information visible
- [ ] Output is readable
- [ ] Timing feels natural
- [ ] Demonstrates one clear concept

**Accessibility:**
- [ ] Alt text provided
- [ ] Caption written
- [ ] Text explanation in docs
- [ ] High contrast terminal
- [ ] Readable font size

**Naming & Organization:**
- [ ] Follows naming convention
- [ ] Stored in correct directory
- [ ] Referenced correctly in docs
- [ ] Markdown image syntax correct

---

## Examples

### Example 1: Pick Basic Usage

**File:** `docs/assets/gifs/commands/pick-basic-usage.gif`

**Recording:**
```bash
# Setup
clear
export PS1="$ "

# Record this workflow
pick
# [Type "flow"]
# [Press Enter]
pwd
# Shows: /Users/dt/projects/dev-tools/flow-cli
```

**In documentation:**
```markdown
### Using Pick to Navigate Projects

![Pick basic usage](../../assets/gifs/commands/pick-basic-usage.gif)

*Using `pick` to filter and navigate to flow-cli project*

The `pick` command provides an interactive FZF interface for navigating
between projects. Type to filter, use arrow keys to select, and press
Enter to navigate.
```

### Example 2: CC Unified Grammar

**File:** `docs/assets/gifs/dispatchers/cc-unified-grammar.gif`

**Recording:**
```bash
# Show both orders work
clear

# Mode-first (traditional)
echo "$ cc opus pick"
cc opus pick
# [Select project]
# [Close Claude window]

# Target-first (new!)
echo "$ cc pick opus"
cc pick opus
# [Select same project]
# [Shows identical behavior]
```

**In documentation:**
```markdown
### Unified Grammar (v4.8.0)

![CC unified grammar](../../assets/gifs/dispatchers/cc-unified-grammar.gif)

*Both `cc opus pick` and `cc pick opus` work identically*

The CC dispatcher now supports flexible command ordering. Whether you
specify the mode first or the target first, the result is the same.
```

---

## Maintenance

### Updating GIFs

**When to update:**
- UI changes significantly
- Command syntax changes
- Feature behavior changes
- Brand new feature added

**Update process:**
1. Create new GIF with updated workflow
2. Optimize new GIF
3. Replace old GIF (keep same filename)
4. Git commit with message: "docs: update GIF for [feature]"
5. Verify docs render correctly

### Archiving Old GIFs

```bash
# If replacing significantly different GIF
mv docs/assets/gifs/pick-old-ui.gif \
   docs/assets/gifs/archive/pick-old-ui-v1.0.gif

# Document in git commit
git add .
git commit -m "docs: update pick GIF for v4.8 UI changes

- New GIF reflects unified grammar
- Old GIF archived for reference"
```

---

## Future Enhancements

### Video Alternatives

**When GIFs aren't enough:**
- Complex workflows > 15 seconds
- Workflows requiring audio explanation
- Multi-pane terminal workflows

**Options:**
- **asciinema** — Terminal session recordings
- **YouTube** — Hosted video tutorials
- **Vimeo** — Higher quality, no ads

**Embedding asciinema:**
```markdown
<script id="asciicast-123456"
  src="https://asciinema.org/a/123456.js"
  async>
</script>
```

### Interactive Demos

**Future consideration:**
- **ttyrec/ttygif** — Terminal recordings
- **Carbon** — Beautiful code screenshots
- **termtosvg** — SVG terminal recordings (smaller than GIF)

---

## Tools Installation

### macOS

```bash
# Install gifsicle for optimization
brew install gifsicle

# Install ffmpeg for video conversion
brew install ffmpeg

# Install Kap for recording (optional)
brew install --cask kap

# Install peek alternative (optional)
brew install --cask licecap
```

### Linux

```bash
# Install gifsicle
sudo apt install gifsicle

# Install ffmpeg
sudo apt install ffmpeg

# Install peek
sudo apt install peek
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────┐
│  GIF CREATION QUICK REFERENCE                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  SPECIFICATIONS                                         │
│  Duration:      5-15 seconds                            │
│  Size:          ≤ 2MB                                   │
│  Resolution:    800-1200px width                        │
│  FPS:           10-15                                   │
│  Colors:        ≤ 128                                   │
│                                                         │
│  NAMING                                                 │
│  Format:        <feature>-<action>-<variant>.gif        │
│  Example:       pick-basic-usage.gif                    │
│                                                         │
│  OPTIMIZATION                                           │
│  gifsicle -O3 --colors 128 input.gif -o output.gif      │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  WORKFLOW: record → trim → optimize → embed → verify    │
└─────────────────────────────────────────────────────────┘
```

---

## Related Resources

- **QUICK-START-TEMPLATE.md** — For text-based quick starts
- **TUTORIAL-TEMPLATE.md** — For step-by-step tutorials with GIFs
- **WORKFLOW-TEMPLATE.md** — For workflow documentation with GIFs
- **REFCARD-TEMPLATE.md** — For reference cards (no GIFs)

---

**Last Updated:** 2026-01-07
**Guidelines Version:** 1.0
