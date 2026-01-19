# Teaching Workflow v3.0 - GIF Demos

This directory contains VHS tapes and generated GIF demos for Teaching Workflow v3.0 features.

## Generated GIFs

| GIF | Feature | Size | Description |
|-----|---------|------|-------------|
| `tutorial-teach-doctor.gif` | teach doctor | 128KB | Environment health check demo |
| `tutorial-backup-system.gif` | Backup System | 248KB | Automated content safety demo |

## VHS Tapes

| Tape | Feature | Duration |
|------|---------|----------|
| `tutorial-teach-doctor.tape` | teach doctor | ~20 seconds |
| `tutorial-backup-system.tape` | Backup System | ~25 seconds |

---

## Regenerating GIFs

### Prerequisites

- VHS installed: `brew install vhs`
- flow-cli v5.14.0+ (with Teaching Workflow v3.0)
- scholar-demo-course available at `~/projects/teaching/scholar-demo-course/`

### Quick Regeneration

```bash
# Run the generation script
cd docs/demos/tutorials
./generate-teaching-v3-gifs.sh
```

### Manual Generation

```bash
cd docs/demos/tutorials

# Generate teach doctor demo
vhs tutorial-teach-doctor.tape

# Generate backup system demo
vhs tutorial-backup-system.tape
```

### Expected Output

```
1/2 Generating teach doctor demo...
  ✅ tutorial-teach-doctor.gif (128K)

2/2 Generating backup system demo...
  ✅ tutorial-backup-system.gif (248K)

🎉 All GIFs generated successfully!
```

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
- `yq '.backups.retention' .flow/teach-config.yml` - Retention policies
- Backup directory structure explanation

Demonstrates:
- Automated backup creation
- Retention policies (archive vs semester)
- Backup summary in status
- Safe deletion workflow

---

## Technical Details

### VHS Configuration

All tapes use consistent settings:

```
Set Shell zsh
Set FontSize 18
Set Width 1400
Set Height 900
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8
```

### Important Setup Steps

Each tape:
1. Sources flow-cli: `source ~/projects/dev-tools/flow-cli/flow.plugin.zsh`
2. Changes to demo course: `cd ~/projects/teaching/scholar-demo-course`
3. Clears screen for clean recording
4. Executes commands
5. Shows completion message

---

## Optimization

If GIFs are too large, optimize with gifsicle:

```bash
# Install gifsicle
brew install gifsicle

# Optimize GIFs
gifsicle -O3 tutorial-teach-doctor.gif -o tutorial-teach-doctor.gif
gifsicle -O3 tutorial-backup-system.gif -o tutorial-backup-system.gif
```

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
```

### Commands not found

Make sure flow-cli is sourced:

```bash
source ~/projects/dev-tools/flow-cli/flow.plugin.zsh
```

### Demo course missing

Clone or ensure demo course exists:

```bash
ls ~/projects/teaching/scholar-demo-course/
```

---

**Generated:** 2026-01-18
**flow-cli Version:** v5.14.0
**VHS Version:** 0.7.0+
