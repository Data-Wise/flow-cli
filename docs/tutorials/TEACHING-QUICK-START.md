# 🚀 Teaching Workflow Quick Start (15 min)

**Estimated time:** 15 minutes | **Prerequisites:** flow-cli installed, `teach` dispatcher available

This tutorial walks you through creating and deploying your first course using the teaching workflow. Follow each step sequentially — each step builds on the previous one.

---

## Step 1: Environment Setup (3 min)

Before creating content, verify your system is ready.

### Run health checks

```bash
$ teach doctor
```

**Expected output:**

```
╔══════════════════════════════════════════════════════════════════╗
║                    🩺 Teaching Doctor                            ║
╠══════════════════════════════════════════════════════════════════╣
║ Dependencies:                                                    ║
║   ✓ yq       v4.35.2  (/opt/homebrew/bin/yq)                     ║
║   ✓ git      2.43.0   (/usr/bin/git)                            ║
║   ✓ quarto   1.4.554  (/Applications/quarto/bin/quarto)         ║
║   ✓ gh       2.49.0   (/opt/homebrew/bin/gh)                     ║
║   ✓ scholar  v3.0.0   (/opt/homebrew/bin/scholar)                ║
║                                                                  ║
║ Project Configuration:                                           ║
║   ✓ course.yml found                                            ║
║   ✓ lesson-plan.yml found                                       ║
║                                                                  ║
║ Git Setup:                                                       ║
║   ✓ On branch: dev                                               ║
║   ✓ Remote configured: origin                                    ║
║   ✓ Working tree clean                                           ║
╚══════════════════════════════════════════════════════════════════╝
```

**What was created:** No files created — this is a read-only diagnostic command.

### Auto-fix issues (if any)

```bash
$ teach doctor --fix
```

**Expected output:**

```
╔══════════════════════════════════════════════════════════════════╗
║                    🩺 Teaching Doctor                            ║
╠══════════════════════════════════════════════════════════════════╣
║ Missing Dependencies:                                            ║
║   Installing examark...                                          ║
║   ✓ examark v0.6.6 installed                                     ║
║                                                                  ║
║ All systems operational!                                         ║
╚══════════════════════════════════════════════════════════════════╝
```

**What was created:** Any missing dependencies are installed automatically.

**Next action:** Proceed to Step 2 to initialize your course.

---

## Step 2: Create Course (2 min)

Initialize a new teaching project with your course information.

### Initialize course

```bash
$ teach init "STAT 440"
```

**Expected output:**

```
╔══════════════════════════════════════════════════════════════════╗
║                    📚 Course Initialization                       ║
╠══════════════════════════════════════════════════════════════════╣
║ Course: STAT 440 - Regression Analysis                           ║
║ Semester: Spring 2026                                            ║
║ Department: Statistics                                           ║
║                                                                  ║
║ Created files:                                                   ║
║   ✓ course.yml                                                   ║
║   ✓ lesson-plan.yml                                              ║
║   ✓ .teach/config.yml                                            ║
║   ✓ .gitignore (teach artifacts)                                 ║
║                                                                  ║
║ Next: teach hooks install                                        ║
╚══════════════════════════════════════════════════════════════════╝
```

**What was created:**
- `course.yml` — Course metadata (title, semester, department)
- `lesson-plan.yml` — Week-by-week content plan template
- `.teach/config.yml` — Teaching workflow configuration
- `.gitignore` — Excludes rendered files from version control

**Next action:** Enable quality checks in Step 3.

---

## Step 3: Enable Quality (1 min)

Install git hooks to automatically validate content before commits.

### Install validation hooks

```bash
$ teach hooks install
```

**Expected output:**

```
╔══════════════════════════════════════════════════════════════════╗
║                    🪝 Hook Installation                          ║
╠══════════════════════════════════════════════════════════════════╣
║ Installing git hooks:                                            ║
║   ✓ pre-commit: YAML validation, syntax check, render check      ║
║   ✓ pre-push: Branch protection (main/dev)                       ║
║   ✓ prepare-commit-msg: Commit message formatting                ║
║                                                                  ║
║ Hooks installed at: .git/hooks/                                  ║
║ Upgrade available: Run 'teach hooks install' after updates       ║
╚══════════════════════════════════════════════════════════════════╝
```

**What was created:**
- `.git/hooks/pre-commit` — Runs 5 validation layers before each commit
- `.git/hooks/pre-push` — Prevents pushing to protected branches
- `.git/hooks/prepare-commit-msg` — Formats commit messages

**Next action:** Create your first lecture in Step 4.

---

## Step 4: First Lecture (3 min)

Generate a complete lecture using Scholar AI, then preview it.

### Generate lecture content

```bash
$ teach lecture "Introduction to Regression" --week 1
```

**Expected output:**

```
╔══════════════════════════════════════════════════════════════════╗
║                    📝 Lecture Generation                          ║
╠══════════════════════════════════════════════════════════════════╣
║ Topic: Introduction to Regression                                ║
║ Week: 1                                                          ║
║ Template: quarto                                                 ║
║                                                                  ║
║ Generating content with Scholar AI...                            ║
║                                                                  ║
║ Created: lectures/week-01-introduction-to-regression.qmd         ║
║ Backed up: lectures/week-01-introduction-to-regression.qmd.1     ║
║                                                                  ║
║ Next: quarto preview                                             ║
╚══════════════════════════════════════════════════════════════════╝
```

**What was created:**
- `lectures/week-01-introduction-to-regression.qmd` — Full Quarto lecture file
- `lectures/week-01-introduction-to-regression.qmd.1` — Auto-backup of previous version

### Preview the lecture

```bash
$ quarto preview lectures/week-01-introduction-to-regression.qmd
```

**Expected output:**

```
[✓] Quarto 1.4.554
[✓] Using pandoc 3.1.12 from /Applications/Quarto.app/Contents/Resources/bin
[✓] Rendering lectures/week-01-introduction-to-regression.qmd...
[✓] Output created: _site/lectures/week-01-introduction-to-regression.html
[✓] Serving at: http://localhost:4200
```

**What was created:**
- `_site/lectures/week-01-introduction-to-regression.html` — Rendered HTML preview
- `quarto preview` server running (Ctrl+C to stop)

**Next action:** Create an assessment in Step 5.

---

## Step 5: Assessment (2 min)

Generate a quiz or exam for your lecture topic.

### Generate quiz

```bash
$ teach quiz "Week 1 Regression Concepts" --questions 10 --week 1
```

**Expected output:**

```
╔══════════════════════════════════════════════════════════════════╗
║                    📋 Quiz Generation                             ║
╠══════════════════════════════════════════════════════════════════╣
║ Topic: Week 1 Regression Concepts                                ║
║ Week: 1                                                          ║
║ Questions: 10                                                    ║
║ Format: exam (with solutions)                                    ║
║                                                                  ║
║ Generating questions with Scholar AI...                          ║
║                                                                  ║
║ Created: assessments/quiz-week-01.qmd                            ║
║ Backed up: assessments/quiz-week-01.qmd.1                        ║
║                                                                  ║
║ Next: teach validate                                             ║
╚══════════════════════════════════════════════════════════════════╝
```

**What was created:**
- `assessments/quiz-week-01.qmd` — Complete quiz with 10 questions and solutions
- `assessments/quiz-week-01.qmd.1` — Auto-backup of previous version

**Next action:** Validate content in Step 6.

---

## Step 6: Validate (1 min)

Run comprehensive validation to catch issues before committing.

### Run validation

```bash
$ teach validate
```

**Expected output:**

```
╔══════════════════════════════════════════════════════════════════╗
║                    ✅ Content Validation                          ║
╠══════════════════════════════════════════════════════════════════╣
║ Files validated: 2                                               ║
║                                                                  ║
║ lectures/week-01-introduction-to-regression.qmd:                 ║
║   ✓ YAML frontmatter valid                                       ║
║   ✓ Syntax check passed                                          ║
║   ✓ Render check passed                                          ║
║   ✓ No empty code chunks                                         ║
║   ✓ All image references resolved                                ║
║                                                                  ║
║ assessments/quiz-week-01.qmd:                                    ║
║   ✓ YAML frontmatter valid                                       ║
║   ✓ Syntax check passed                                          ║
║   ✓ Render check passed                                          ║
║                                                                  ║
║ Validation: 2/2 files passed                                     ║
╚══════════════════════════════════════════════════════════════════╝
```

**What was created:** No files — this is a read-only check command.

**Next action:** Commit changes in Step 7.

---

## Step 7: Commit (1 min)

Commit your changes. The git hooks will auto-validate before the commit succeeds.

### Stage and commit

```bash
$ git add lectures/ assessments/
$ git commit -m "feat: add week 1 lecture and quiz"
```

**Expected output:**

```
[pre-commit hook] Running validation...
[pre-commit hook] ✓ YAML validation passed
[pre-commit hook] ✓ Syntax check passed
[pre-commit hook] ✓ Render check passed
[dev e5f3a2c] feat: add week 1 lecture and quiz
 2 files changed, 847 insertions(+)
 create mode 100644 lectures/week-01-introduction-to-regression.qmd
 create mode 100644 assessments/quiz-week-01.qmd
```

**What was created:**
- Git commit with validated content
- History entry: `feat: add week 1 lecture and quiz`

**Next action:** Deploy to GitHub Pages in Step 8.

---

## Step 8: Deploy (2 min)

Deploy your content to GitHub Pages. Preview changes first, then create a PR.

### Preview deployment

```bash
$ teach deploy --preview
```

**Expected output:**

```
╔══════════════════════════════════════════════════════════════════╗
║                    🚀 Deploy Preview                              ║
╠══════════════════════════════════════════════════════════════════╣
║ Changes to deploy:                                               ║
║   A lectures/week-01-introduction-to-regression.qmd              ║
║   A assessments/quiz-week-01.qmd                                 ║
║   M _quarto.yml (index update)                                   ║
║                                                                  ║
║ Files to render: 2                                               ║
║ Estimated time: ~30s                                             ║
║                                                                  ║
║ [View full diff: teach deploy --preview --diff]                  ║
╚══════════════════════════════════════════════════════════════════╝
```

**What was created:** No files — preview shows what will be deployed.

### Deploy and create PR

```bash
$ teach deploy
```

**Expected output:**

```
╔══════════════════════════════════════════════════════════════════╗
║                    🚀 Deployment Complete                         ║
╠══════════════════════════════════════════════════════════════════╣
║ Rendering content:                                               ║
║   ✓ lectures/week-01-introduction-to-regression.qmd              ║
║   ✓ assessments/quiz-week-01.qmd                                 ║

║ Index║                                                                  ║ updated: _quarto.yml                                       ║
║                                                                  ║
║ Branch: deploy/spring-2026                                       ║
║ Commit: 8a2b4c1                                                  ║
║                                                                  ║
║ PR created: #47 - Deploy Spring 2026 Week 1                      ║
║ URL: https://github.com/yourname/stat-440/pull/47                ║
║                                                                  ║
║ Next: Review PR and merge to dev                                 ║
╚══════════════════════════════════════════════════════════════════╝
```

**What was created:**
- Rendered HTML files in `_site/`
- Branch: `deploy/spring-2026`
- GitHub PR with rendered preview link

---

## 🎉 Success

You've completed the teaching workflow quick start. Your course is now deployed and ready for review.

### What you created

| File | Purpose |
|------|---------|
| `course.yml` | Course metadata |
| `lesson-plan.yml` | Weekly content plan |
| `.teach/config.yml` | Workflow configuration |
| `lectures/week-01-*.qmd` | Lecture content |
| `assessments/quiz-*.qmd` | Quiz with solutions |
| GitHub PR | Deployment preview |

### Next steps

1. **Merge the PR** — Click the PR link to review and merge
2. **Continue content** — Add more lectures: `teach lecture "Topic" --week N`
3. **Explore features** — Try `teach slides`, `teach exam`, `teach backup`
4. **Get help** — Run `teach --help` for all commands

### Quick reference

| Command | Description |
|---------|-------------|
| `teach doctor` | System health check |
| `teach doctor --fix` | Auto-fix missing dependencies |
| `teach init "Course Name"` | Initialize new course |
| `teach hooks install` | Enable validation hooks |
| `teach lecture "Topic" --week N` | Generate lecture |
| `teach quiz "Topic" --week N` | Generate quiz |
| `teach validate` | Manual validation |
| `teach deploy` | Deploy to GitHub Pages |
| `teach --help` | Show all commands |

---

**See also:**
- [Teaching Workflow v3.0 Guide](../guides/TEACHING-WORKFLOW-V3-GUIDE.md) — Comprehensive documentation
- [Teach Dispatcher Reference](../reference/TEACH-DISPATCHER-REFERENCE-v3.0.md) — All commands
- [Backup System Guide](../guides/BACKUP-SYSTEM-GUIDE.md) — Automatic backups
