# Teaching Material Generation - Quick Reference

**For:** ADHD-friendly content generation commands
**Version:** v5.12.0+

---

## Command Cheat Sheet

### Basic Pattern
```
teach <command> "Topic"           # Generate with topic
teach <command>                   # Auto-detect topic from schedule
teach <command> -i                # Interactive (guided) mode
teach <command> --revise FILE     # Improve existing file
```

### Slides & Lectures
```bash
teach slides "Regression"         # Generate slides
teach slides                      # Auto-detect week's topic
teach slides -i                   # Interactive wizard
teach slides --revise FILE        # Revise existing

teach lecture "Regression"        # Generate lecture notes
teach lecture --outline           # Quick outline only
teach lecture --notes             # Include speaker notes
```

### Quizzes & Exams
```bash
teach quiz "Chapter 5"            # 10 questions (default)
teach quiz "Ch 5" -n 15           # 15 questions
teach quiz "Ch 5" --types mc,tf   # Only MC & True/False

teach exam "Midterm"              # 25 questions, 90 min
teach exam "Final" -n 40          # 40 questions
teach exam "Midterm" --duration 120  # 2 hour exam
```

### Feedback & Assignments
```bash
teach feedback submission.pdf     # Analyze student work
teach feedback work/ --batch      # Batch process directory

teach assignment "HW 3"           # Create assignment
teach assignment "HW 3" --due 2026-01-24
teach assignment "Project" --parts 3
```

---

## Shortcuts

| Long | Short | Example |
|------|-------|---------|
| `slides` | `sl` | `teach sl "Topic"` |
| `lecture` | `lec` | `teach lec "Topic"` |
| `quiz` | `q` | `teach q "Topic"` |
| `exam` | `e` | `teach e "Topic"` |
| `feedback` | `fb` | `teach fb file.pdf` |
| `assignment` | `hw` | `teach hw "Topic"` |

---

## Universal Flags

| Flag | Short | Purpose |
|------|-------|---------|
| `--interactive` | `-i` | Step-by-step wizard |
| `--revise FILE` | | Improve existing file |
| `--format FMT` | | Output: qmd, md, latex |
| `--dry-run` | | Preview without saving |
| `--context` | | Include full course context |
| `--week N` | | Override week number |
| `--verbose` | | Show AI prompt |

---

## Progress Indicators

```
 Working...              Spinner (in progress)
 Done!                   Success
 Error message           Failure
 Warning message         Caution
```

**Time estimates:**
- Slides: ~30 seconds
- Lecture: ~45 seconds
- Quiz: ~20 seconds
- Exam: ~60 seconds
- Feedback: ~20 seconds
- Assignment: ~30 seconds

---

## Interactive Mode (-i)

When unsure about options, use `-i`:

```bash
teach slides -i
```

**Navigation:**
| Key | Action |
|-----|--------|
| Enter | Accept default |
| 1-9 | Select option |
| q | Quit/cancel |
| b | Go back |
| ? | Show help |

---

## Revise Workflow

```bash
# Start revision
teach slides --revise slides/week08.qmd

# Options presented:
# [1] Expand content
# [2] Add examples
# [3] Simplify language
# [4] Add visuals
# [5] Custom instructions
# [6] Full regenerate
```

---

## Smart Defaults

When you omit the topic, `teach` auto-detects:

```bash
teach slides        # Uses Week 8's topic from schedule
teach quiz          # Topics covered this week
teach exam          # All topics in current unit
```

**Auto-detection uses:**
1. Current date + semester start
2. `_schedule.yml` topic lookup
3. Falls back to interactive if not found

---

## Common Workflows

### Prepare Week's Lecture
```bash
teach lecture "Topic" --outline   # Draft outline first
teach lecture "Topic"             # Full content
teach slides "Topic" --from-lecture lectures/week08.qmd
```

### Create Assessment
```bash
teach quiz "Chapter 5" -i         # Guided quiz creation
teach exam "Midterm" --dry-run    # Preview before saving
```

### Improve Existing Content
```bash
teach slides --revise slides/old.qmd  # Interactive improvement
```

### Batch Student Feedback
```bash
teach feedback submissions/ --batch --rubric rubric.yml
```

---

## Output Locations

| Content | Default Path |
|---------|--------------|
| Slides | `slides/week{N}-{topic}.qmd` |
| Lectures | `lectures/week{N}-{topic}.qmd` |
| Quizzes | `quizzes/{topic}.qmd` |
| Exams | `exams/{name}.qmd` |
| Assignments | `assignments/{name}.qmd` |
| Feedback | `feedback/{student}.md` |

Override with `--output PATH`.

---

## Error Recovery

| Error | Recovery |
|-------|----------|
| "Topic not found" | Specify explicitly: `teach slides "Topic"` |
| "Config missing" | Run: `teach init "STAT 440"` |
| "AI failed" | Wait 60s, retry |
| "Rate limit" | Wait, or use `--dry-run` to test |

---

## Shell Aliases (Optional)

Add to `~/.zshrc` for faster access:

```zsh
alias tsl='teach slides'
alias tlec='teach lecture'
alias tq='teach quiz'
alias te='teach exam'
alias tfb='teach feedback'
alias thw='teach assignment'
alias ts='teach status'
```

---

## See Also

- `teach help` - Full command reference
- `teach <cmd> --help` - Command-specific help
- `teach status` - Project status
- `teach week` - Current week info

---

*Last updated: January 2026*
