# Teaching Workflow - Demo & GIF Guide

**Purpose:** Instructions for recording and creating visual demonstrations of teaching commands
**Last Updated:** 2026-01-13

---

## Quick Demo Setup

To demonstrate teaching workflows, you'll need:

1. A demo course repository (pre-created)
2. Terminal recording tool (asciinema, ttyrec, or screen recording)
3. GIF converter (if using screen recording)

---

## Demo Scenarios

### Demo 1: `teach init` - Course Setup (90 seconds)

**Objective:** Show the one-time setup process

**Pre-requisites:**
- Empty course repository
- Git initialized

**Commands to run:**
```bash
# Terminal title
cd ~/projects/teaching/demo-course-new
pwd  # Show directory

# Run initialization
teach init -y "STAT 545"

# Show what was created
ls -la .flow/
ls -la scripts/
git log --oneline | head -3
```

**Key points to highlight:**
1. Single command creates everything
2. `.flow/teach-config.yml` - configuration file
3. `scripts/quick-deploy.sh` - deployment script
4. Clean git history

**Expected time:** 30-60 seconds of actual command execution

---

### Demo 2: `teach status` - Course Dashboard (30 seconds)

**Objective:** Show real-time course status

**Commands:**
```bash
cd ~/projects/teaching/demo-course
teach status

# Also show:
teach week
```

**Key points:**
1. Course name and semester
2. Current week calculation
3. Branch safety indicator
4. Deployment status

**Expected time:** 15-20 seconds

---

### Demo 3: `work` + `teach deploy` - Daily Workflow (2 minutes)

**Objective:** Show complete edit-and-deploy cycle

**Setup:**
- Course already initialized
- Latest changes on production

**Commands:**
```bash
cd ~/projects/teaching/demo-course

# 1. Start work session
work demo-course

# 2. Make a simple edit
echo "## Updated lecture" >> lectures/week08.qmd

# 3. Check status
git status

# 4. Commit
git add .
git commit -m "refine: week 8 lecture notes"

# 5. Deploy
teach deploy

# 6. Verify
teach status
```

**Key points:**
1. `work` shows course context
2. Edit files (any editor)
3. Commit changes
4. Deploy in seconds
5. Students see updates immediately

**Expected time:** 90-120 seconds

---

### Demo 4: `teach archive` - Semester Wrap-up (60 seconds)

**Objective:** Show end-of-semester archival

**Setup:**
- Course at end of semester
- All materials final

**Commands:**
```bash
cd ~/projects/teaching/demo-course

# Check semester info
teach status

# Archive
teach archive
# → Respond: y

# Verify tag was created
git tag -l | grep final

# Show what comes next
cat << 'EOF'
Next steps for new semester:
1. teach config
2. Update: course.semester, course.year
3. git commit
4. teach deploy
EOF
```

**Key points:**
1. Creates immutable snapshot
2. Preserves semester state
3. Allows clean next-semester setup
4. 2-3 step process for new semester

**Expected time:** 45-60 seconds

---

## Recording Instructions

### Option 1: Using asciinema (Recommended)

**Install:**
```bash
brew install asciinema
```

**Record:**
```bash
# Start recording
asciinema rec teaching-demo-1.cast

# Run demo commands (as listed above)
# ...

# Stop recording (Ctrl-D)
```

**Play:**
```bash
asciinema play teaching-demo-1.cast
```

**Convert to GIF:**
```bash
# Using svg-term
npm install -g svg-term-cli

svg-term --cast teaching-demo-1.cast --out teaching-demo-1.svg

# Convert SVG to GIF (if needed)
# Use online converter or: cairosvg teaching-demo-1.svg -o teaching-demo-1.gif
```

---

### Option 2: Using ttyrec

**Install:**
```bash
brew install ttyrec
```

**Record:**
```bash
# Start recording
ttyrec teaching-demo-1.ttyrec

# Run commands
# ...

# Stop (Ctrl-D)
```

**Play:**
```bash
ttyplay teaching-demo-1.ttyrec
```

---

### Option 3: Using Screen Recording + GIF Converter

**Record with macOS QuickTime:**
1. Command-Shift-5
2. Select "Record Selected Portion"
3. Run demo commands
4. Stop recording

**Convert to GIF:**
```bash
# Using ffmpeg
brew install ffmpeg

ffmpeg -i recording.mov -vf "fps=10,scale=1280:-1:flags=lanczos" -c:v pngquant -f image2pipe - | ffmpeg -f image2pipe -i - output.gif
```

---

## Demo Scripts (Ready to Copy-Paste)

### Script 1: teach init

```bash
#!/bin/bash
set -e

clear
echo "Demo: teach init - Course Setup"
echo "================================="
echo ""
sleep 1

cd /tmp/demo-new-course
git init .

echo "$ teach init -y 'STAT 545'"
sleep 1
teach init -y "STAT 545"

echo ""
echo "$ ls -la .flow/"
ls -la .flow/

echo ""
echo "$ cat scripts/quick-deploy.sh | head -20"
head -20 scripts/quick-deploy.sh

echo ""
echo "✓ Course setup complete in seconds!"
```

### Script 2: teach status

```bash
#!/bin/bash

clear
echo "Demo: teach status - Course Dashboard"
echo "======================================"
echo ""

cd ~/projects/teaching/demo-course

echo "$ teach status"
teach status

echo ""
echo "$ teach week"
teach week
```

### Script 3: Full Workflow

```bash
#!/bin/bash
set -e

clear
echo "Demo: Complete Teaching Workflow"
echo "=================================="
echo ""

cd ~/projects/teaching/demo-course

echo "Step 1: Check course status"
echo "$ teach status"
sleep 2
teach status

echo ""
echo "Step 2: Start work session"
echo "$ work demo-course"
sleep 1
work demo-course

echo ""
echo "Step 3: Make edits"
echo "$ vim lectures/week08.qmd"
sleep 2
echo "# Adding new content to week 8"

echo ""
echo "Step 4: Commit changes"
echo "$ git add . && git commit -m 'add week 8 materials'"
git add .
git commit -m "refine: add week 8 course materials" 2>/dev/null || true

echo ""
echo "Step 5: Deploy to students"
echo "$ teach deploy"
sleep 1
teach deploy

echo ""
echo "✓ Materials live in < 2 minutes!"
```

---

## Visual Workflow Diagram

### Setup → Edit → Deploy → Students

```
┌─────────────────────────────────────────────────────────┐
│ teach init "STAT 545"                                   │
│ (One-time: creates config, scripts, branches)           │
└────────────────────┬────────────────────────────────────┘
                     ↓
        ┌────────────────────────────┐
        │ Teaching Project Ready     │
        │ ✓ .flow/teach-config.yml   │
        │ ✓ scripts/quick-deploy.sh  │
        │ ✓ draft branch             │
        │ ✓ production branch        │
        └────────────────────────────┘
                     ↓
    ┌────────────────────────────────────────┐
    │ DAILY WORKFLOW (repeats every day)     │
    ├────────────────────────────────────────┤
    │                                        │
    │ 1. work stat-545                       │
    │    (check branch, show context)        │
    │                                        │
    │ 2. Edit files in your editor           │
    │    lectures/, assignments/, etc        │
    │                                        │
    │ 3. git add . && git commit             │
    │    (save changes locally)              │
    │                                        │
    │ 4. teach deploy                        │
    │    (merge → production → publish)      │
    │                                        │
    │ 5. Students see updates in ~2 min      │
    │                                        │
    └────────────────────────────────────────┘
                     ↓
    ┌────────────────────────────────────────┐
    │ END OF SEMESTER                        │
    ├────────────────────────────────────────┤
    │ teach archive                          │
    │ (create spring-2026-final tag)         │
    │                                        │
    │ teach config                           │
    │ (update for next semester)             │
    │                                        │
    │ git commit                             │
    │ (commit next-semester config)          │
    │                                        │
    │ teach deploy                           │
    │ (ready for next semester)              │
    └────────────────────────────────────────┘
```

---

## Demo Course Pre-Setup

Create a demo course for recording:

```bash
# Create demo directory
mkdir -p ~/tmp/demo-course-teaching
cd ~/tmp/demo-course-teaching

# Initialize git
git init .
touch README.md
git add .
git commit -m "initial commit"

# Initialize teaching workflow
teach init -y "STAT 101 - Intro to Statistics"

# Create sample content
mkdir -p lectures assignments solutions
echo "# Week 1 Lecture" > lectures/week01.qmd
echo "# Assignment 1" > assignments/assignment-01.qmd
echo "# Solutions 1" > solutions/assignment-01.qmd

# Commit and deploy
git add .
git commit -m "add sample materials"
teach deploy

# Now ready for demos!
```

---

## Publishing GIFs to Documentation

**File naming convention:**
```
teaching-{command}-{action}.gif

Examples:
- teaching-init-setup.gif
- teaching-deploy-workflow.gif
- teaching-status-dashboard.gif
- teaching-full-workflow.gif
```

**Storage location:**
```
docs/assets/gifs/teaching/
├── teaching-init-setup.gif
├── teaching-deploy-workflow.gif
├── teaching-status-dashboard.gif
└── teaching-workflow-daily.gif
```

**Markdown embed:**
```markdown
### Deploy to Students

![Deploy workflow GIF](../../assets/gifs/teaching/teaching-deploy-workflow.gif)

The deploy command merges your changes to production in seconds.
```

---

## Recommended Demo Duration

| Demo | Duration | GIF Size | Use Case |
|------|----------|----------|----------|
| `teach init` | 60s | ~2MB | Setup guide |
| `teach status` | 30s | ~1MB | Quick reference |
| `teach deploy` | 90s | ~2.5MB | Daily workflow |
| `teach archive` | 60s | ~2MB | Semester wrap-up |
| Full workflow | 3-4m | ~4MB | Homepage showcase |

---

## Tips for Great Demos

1. **Use a clear font:** Increase terminal font size (14-16pt)
2. **Keep pace steady:** Pause between commands for readability
3. **Add comments:** Echo descriptions before commands
4. **Show results:** Let output display before next command
5. **Highlight key files:** Use `cat` or `ls -la` to show created files
6. **Terminal colors:** Ensure teaching course has colorful output
7. **Real-like pace:** Don't rush through - simulate realistic typing speed

---

## Troubleshooting

### GIF too large?

```bash
# Reduce quality/fps
ffmpeg -i recording.mov -vf "fps=5,scale=960:-1:flags=lanczos" -c:v pngquant -f image2pipe - | ffmpeg -f image2pipe -i - output.gif
```

### Asciinema cast won't convert?

```bash
# Check file format
file teaching-demo.cast

# Ensure it's valid
asciinema play teaching-demo.cast  # Should work
```

### Need to re-record part of demo?

- Use `asciinema rec --append` to continue
- Or use screen recording tools to capture specific sections
- Edit video before converting to GIF

---

## Next Steps

1. [ ] Create demo-course setup
2. [ ] Record `teach init` demo
3. [ ] Record `teach deploy` demo
4. [ ] Record `teach status` demo
5. [ ] Convert to GIFs
6. [ ] Add to documentation
7. [ ] Link from main guides
