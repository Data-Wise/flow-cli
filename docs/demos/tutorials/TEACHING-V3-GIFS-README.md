# Teaching Workflow v3.0 - GIF Demos

This directory contains VHS tapes and generated GIF demos for Teaching Workflow v3.0 features.

## Generated GIFs

| GIF | Feature | Size | Description |
|-----|---------|------|-------------|
| `tutorial-teach-doctor.gif` | teach doctor | 1.5MB | Environment health check demo |
| `tutorial-backup-system.gif` | Backup System | 1.6MB | Automated content safety demo |
| `tutorial-teach-init.gif` | teach init | 336KB | Project initialization demo |
| `tutorial-teach-deploy.gif` | teach deploy | 1.2MB | Preview deployment workflow |
| `tutorial-teach-status.gif` | teach status | 1.1MB | Enhanced status display |
| `tutorial-scholar-integration.gif` | Scholar Integration | 288KB | Template and lesson plan demo |

## VHS Tapes

| Tape | Feature | Duration |
|------|---------|----------|
| `tutorial-teach-doctor.tape` | teach doctor | ~20 seconds |
| `tutorial-backup-system.tape` | Backup System | ~25 seconds |
| `tutorial-teach-init.tape` | teach init | ~20 seconds |
| `tutorial-teach-deploy.tape` | teach deploy | ~30 seconds |
| `tutorial-teach-status.tape` | teach status | ~25 seconds |
| `tutorial-scholar-integration.tape` | Scholar Integration | ~30 seconds |

---

## Quality Standards (v5.23.0+)

**All VHS tapes in this repository follow strict quality standards:**

- ✅ **Font Size:** Minimum 18px for optimal readability
- ✅ **Shell Directive:** `Set Shell zsh` for consistent behavior
- ✅ **Comment Syntax:** Use `Type "echo '...'"` (not `Type "#..."`)
- ✅ **Validation:** All tapes pass `scripts/validate-vhs-tapes.sh`
- ✅ **Optimization:** All GIFs optimized with `gifsicle -O3`

**Style Guide:** See [`docs/contributing/VHS-TAPE-STYLE-GUIDE.md`](../../contributing/VHS-TAPE-STYLE-GUIDE.md)

---

## Regenerating GIFs

### Prerequisites

- VHS installed: `brew install vhs`
- gifsicle installed: `brew install gifsicle` (for optimization)
- flow-cli v5.23.0+ (with Teaching Workflow v3.0)
- scholar-demo-course available at `~/projects/teaching/scholar-demo-course/`

### Quick Regeneration (Recommended)

```bash
# Run the enhanced generation script with validation + optimization
cd docs/demos/tutorials
./generate-teaching-v3-gifs.sh
```bash

**The script automatically:**
1. ✅ Validates all VHS tapes before generation
2. 🎬 Generates GIFs from tapes
3. 🗜️ Optimizes GIFs with gifsicle (-O3)
4. 📊 Reports size reductions

### Manual Generation

```bash
cd docs/demos/tutorials

# Generate all demos individually
vhs tutorial-teach-doctor.tape
vhs tutorial-backup-system.tape
vhs tutorial-teach-init.tape
vhs tutorial-teach-deploy.tape
vhs tutorial-teach-status.tape
vhs tutorial-scholar-integration.tape
```text

### Expected Output

```text
1/6 Generating teach doctor demo...
  ✅ tutorial-teach-doctor.gif (1.5M)

2/6 Generating backup system demo...
  ✅ tutorial-backup-system.gif (1.6M)

3/6 Generating teach init demo...
  ✅ tutorial-teach-init.gif (336K)

4/6 Generating teach deploy demo...
  ✅ tutorial-teach-deploy.gif (1.2M)

5/6 Generating teach status demo...
  ✅ tutorial-teach-status.gif (1.1M)

6/6 Generating scholar integration demo...
  ✅ tutorial-scholar-integration.gif (288K)

🎉 All GIFs generated successfully!
```yaml

---

## Features Demonstrated

### teach doctor (tutorial-teach-doctor.gif)

Shows:
- `teach doctor --help` - Help output
- `teach doctor` - Full health check with dependencies, config, git, Scholar
- `teach doctor --quiet` - Only warnings/failures

Demonstrates:
- Environment validation
- Dependency checking
- Config validation
- Git status verification

### Backup System (tutorial-backup-system.gif)

Shows:
- `teach status` - Enhanced status with backup summary
- Backup retention policies
- Backup directory structure explanation

Demonstrates:
- Automated backup creation
- Retention policies (archive vs semester)
- Backup summary in status
- Safe deletion workflow

### teach init (tutorial-teach-init.gif)

Shows:
- `teach init --help` - Help output and available options
- `teach init` - Initialize new teaching project
- `.flow/` directory structure
- Generated `teach-config.yml` configuration

Demonstrates:
- Project initialization workflow
- Configuration file generation
- Directory structure setup
- Course metadata configuration

### teach deploy (tutorial-teach-deploy.gif)

Shows:
- `teach deploy --help` - Deployment options
- `teach status` - Pre-deployment status check
- `teach deploy --preview` - Preview branch deployment
- Preview URL information

Demonstrates:
- Preview deployment workflow
- Safe deployment testing
- Branch-based deployment
- Deployment status tracking

### teach status (tutorial-teach-status.gif)

Shows:
- `teach status` - Comprehensive project overview
- Course configuration and dates
- Current week and schedule
- Git branch and deployment status
- Backup summary

Demonstrates:
- Enhanced status display
- All-in-one project overview
- Multiple information sources
- Quick project health check

### Scholar Integration (tutorial-scholar-integration.gif)

Shows:
- `teach exam --help` - Scholar command options
- `teach exam` with template and lesson plan
- Template selection workflow
- Automated backup confirmation

Demonstrates:
- Scholar MCP integration
- Template-based content generation
- Lesson plan auto-loading
- Integrated backup safety

---

## Technical Details

### VHS Configuration

All tapes use consistent settings:

```text
Set Shell zsh
Set FontSize 18
Set Width 1400
Set Height 900
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8
```zsh

### Important Setup Steps

Each tape:
1. Sources flow-cli: `source ~/projects/dev-tools/flow-cli/flow.plugin.zsh`
2. Changes to demo course: `cd ~/projects/teaching/scholar-demo-course`
3. Clears screen for clean recording
4. Executes commands
5. Shows completion message

### Critical Guidelines for VHS Tapes

**MUST follow these rules to prevent errors:**

1. **Use `echo` for all titles and comments**

   ```bash
   # ❌ WRONG - causes zsh errors:
   Type "# This is a comment" Enter

   # ✅ CORRECT - works in zsh:
   Type "echo 'This is a comment'" Enter
   ```

1. **Source flow-cli at start of EVERY tape**

   ```bash
   Hide
   Type "source ~/projects/dev-tools/flow-cli/flow.plugin.zsh" Enter
   Sleep 1s
   ```

   This ensures all `teach` commands are available.

2. **Avoid escaped quotes in Type commands**

   ```bash
   # ❌ WRONG - VHS parser error:
   Type "teach exam \"Topic\" --template foo" Enter

   # ✅ CORRECT - use single quotes:
   Type "teach exam 'Topic' --template foo" Enter
   ```

3. **Always optimize GIFs after generation**

   ```bash
   gifsicle -O3 tutorial-name.gif -o tutorial-name.gif
   ```

   Reduces file size by ~30-40% without quality loss.

4. **Test commands before recording**
   Verify all commands work in the demo course environment before creating the VHS tape.

---

## Optimization

If GIFs are too large, optimize with gifsicle:

```bash
# Install gifsicle
brew install gifsicle

# Optimize GIFs
gifsicle -O3 tutorial-teach-doctor.gif -o tutorial-teach-doctor.gif
gifsicle -O3 tutorial-backup-system.gif -o tutorial-backup-system.gif
```diff

---

## Integration

These GIFs are referenced in:

- `docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md`
- `docs/guides/BACKUP-SYSTEM-GUIDE.md`
- `docs/guides/TEACHING-V3-MIGRATION-GUIDE.md`
- Documentation website (MkDocs)

---

## Troubleshooting

### GIF not generated (0 bytes)

VHS is still running. Wait for completion or check for errors:

```bash
# Check if VHS is running
ps aux | grep vhs

# Monitor log output
tail -f /path/to/vhs/output.log
```zsh

### Commands not found

Make sure flow-cli is sourced:

```bash
source ~/projects/dev-tools/flow-cli/flow.plugin.zsh
```bash

### Demo course missing

Clone or ensure demo course exists:

```bash
ls ~/projects/teaching/scholar-demo-course/
```

---

**Generated:** 2026-01-18
**flow-cli Version:** v5.14.0
**VHS Version:** 0.7.0+
