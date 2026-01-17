# VHS Demo: Teaching + Git Workflow (5 Phases)
# Documentation: https://github.com/charmbracelet/vhs

# Terminal setup
Output docs/assets/gifs/teaching-git-workflow.gif
Set FontSize 14
Set Width 1200
Set Height 800
Set Theme "Dracula"
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8

# Title card
Type "Teaching + Git Workflow Demo (v5.12.0)" Sleep 1s Enter
Sleep 1s

# Phase 1: Smart Post-Generation
Type "# Phase 1: Smart Post-Generation" Enter
Sleep 500ms
Type "teach exam 'Midterm 1'" Enter
Sleep 2s

# Simulate interactive menu
Type "# Choose an option:" Sleep 500ms Enter
Type "#   1) Review in editor, then commit" Sleep 300ms Enter
Type "#   2) Commit now with auto-generated message" Sleep 300ms Enter
Type "#   3) Skip commit (do it manually later)" Sleep 300ms Enter
Sleep 1s
Type "2" Enter
Sleep 1s

# Show commit created
Type "git log -1 --oneline" Enter
Sleep 2s

# Phase 2: Git Deployment
Type "" Enter
Type "# Phase 2: Git Deployment" Enter
Sleep 500ms
Type "teach deploy" Enter
Sleep 2s

# Simulate pre-flight checks
Type "# Pre-flight checks:" Sleep 500ms Enter
Type "#   ✓ On draft branch" Sleep 300ms Enter
Type "#   ✓ No uncommitted changes" Sleep 300ms Enter
Type "#   ✓ No unpushed commits" Sleep 300ms Enter
Type "#   ✓ No production conflicts" Sleep 300ms Enter
Sleep 1s
Type "# Creating PR: draft → main" Sleep 500ms Enter
Sleep 1s

# Phase 3: Git-Aware Status
Type "" Enter
Type "# Phase 3: Git-Aware Status" Enter
Sleep 500ms
Type "teach status" Enter
Sleep 2s

# Simulate status output
Type "# Course: STAT 545 (Fall 2024)" Sleep 300ms Enter
Type "# Week: 8 of 15" Sleep 300ms Enter
Type "#" Sleep 100ms Enter
Type "# 📝 Uncommitted Teaching Files:" Sleep 300ms Enter
Type "#   • exams/exam02.qmd" Sleep 300ms Enter
Type "#   • slides/week08.qmd" Sleep 300ms Enter
Sleep 1s

# Phase 4: Teaching Mode
Type "" Enter
Type "# Phase 4: Teaching Mode (Auto-Commit)" Enter
Sleep 500ms
Type "# Edit config: workflow.teaching_mode: true" Enter
Sleep 1s
Type "teach quiz 'Chapter 5'" Enter
Sleep 2s
Type "# 🎓 Teaching Mode: Auto-committing..." Sleep 300ms Enter
Type "# ✓ Committed: teach: add quiz for Chapter 5" Sleep 300ms Enter
Sleep 1s

# Phase 5: Git Initialization
Type "" Enter
Type "# Phase 5: Git Initialization" Enter
Sleep 500ms
Type "teach init 'STAT 440'" Enter
Sleep 2s

# Simulate init wizard
Type "# → Initializing git repository" Sleep 300ms Enter
Type "# → Copying .gitignore template (95 lines)" Sleep 300ms Enter
Type "# → Creating draft branch" Sleep 300ms Enter
Type "# → Creating main branch" Sleep 300ms Enter
Type "# → Making initial commit" Sleep 300ms Enter
Type "# → GitHub repo creation? (y/N)" Sleep 500ms Enter
Type "n" Enter
Sleep 1s

# Final summary
Type "" Enter
Type "# ✅ All 5 Phases Complete!" Enter
Sleep 2s

# Show git log
Type "git log --oneline -5" Enter
Sleep 3s

# End
Type "" Enter
Sleep 2s
